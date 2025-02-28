/* Copyright Airship and Contributors */

#import <CoreData/CoreData.h>

#import "UAInboxStore+Internal.h"
#import "UAMessageCenterResources.h"

#import "UAAirshipMessageCenterCoreImport.h"

@interface UAInboxStore()
@property (nonatomic, copy) NSString *storeName;
@property (strong, nonatomic) NSManagedObjectContext *managedContext;
@property (nonatomic, assign) BOOL inMemory;
@property (atomic, assign) BOOL finished;
@end

@implementation UAInboxStore

- (instancetype)initWithName:(NSString *)storeName inMemory:(BOOL)inMemory {
    self = [super init];


    if (self) {
        self.storeName = storeName;
        self.inMemory = inMemory;
        self.finished = NO;

        NSURL *modelURL = [[UAMessageCenterResources bundle] URLForResource:@"UAInbox" withExtension:@"momd"];
        self.managedContext = [NSManagedObjectContext managedObjectContextForModelURL:modelURL
                                                                      concurrencyType:NSPrivateQueueConcurrencyType];

        
        UA_WEAKIFY(self);
        [self.managedContext performBlock:^{
            UA_STRONGIFY(self)
            [self moveDatabase];
        }];

        [self addStores];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(protectedDataAvailable)
                                                     name:UIApplicationProtectedDataDidBecomeAvailable
                                                   object:nil];
    }

    return self;
}

+ (instancetype)storeWithName:(NSString *)storeName inMemory:(BOOL)inMemory {
    return [[UAInboxStore alloc] initWithName:storeName inMemory:inMemory];
}

+ (instancetype)storeWithName:(NSString *)storeName {
    return [UAInboxStore storeWithName:storeName inMemory:NO];
}

- (void)addStores {
    void (^completion)(NSPersistentStore *, NSError*) = ^void(NSPersistentStore *store, NSError *error) {
        if (!store) {
            UA_LERR(@"Failed to create inbox message persistent store: %@", error);
        }
    };

    if (self.inMemory) {
        [self.managedContext addPersistentInMemoryStore:self.storeName completionHandler:completion];
    } else {
        [self.managedContext addPersistentSqlStore:self.storeName completionHandler:completion];
    }
}

- (void)protectedDataAvailable {
    if (!self.managedContext.persistentStoreCoordinator.persistentStores.count) {
        [self addStores];
    }
}

- (NSArray<UAInboxMessage *> *)fetchMessagesWithPredicate:(NSPredicate *)predicate {
    __block NSMutableArray<UAInboxMessage *> *messages = [NSMutableArray array];

    [self safePerformSync:^{
        NSArray<UAInboxMessageData *> *result = [self fetchMessageDataWithPredicate:predicate];

        for (UAInboxMessageData *data in result) {
            [messages addObject:[self messageFromMessageData:data]];
        }
    }];

    return messages;
}

- (void)fetchMessagesWithPredicate:(nullable NSPredicate *)predicate completionHandler:(void (^)(NSArray<UAInboxMessage *> *))completionHandler {
    [self safePerformAsync:^{
        NSArray<UAInboxMessageData *> *result = [self fetchMessageDataWithPredicate:predicate];

        NSMutableArray *messages = [NSMutableArray array];

        for (UAInboxMessageData *data in result) {
            [messages addObject:[self messageFromMessageData:data]];
        }

        completionHandler(messages);
    }];
}


- (NSArray<UAInboxMessageData *> *)fetchMessageDataWithPredicate:(NSPredicate *)predicate {
    __block NSArray<UAInboxMessageData *> *data = @[];
    [self safePerformSync:^{
        NSError *error = nil;

        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        request.entity = [NSEntityDescription entityForName:kUAInboxDBEntityName
                                     inManagedObjectContext:self.managedContext];

        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"messageSent" ascending:NO];
        request.sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
        request.predicate = predicate;

        data = [self.managedContext executeFetchRequest:request error:&error];

        if (error) {
            UA_LERR(@"Error executing fetch request: %@ with error: %@", request, error);
        }

        [self.managedContext safeSave];
    }];

    return data;
}


- (void)markMessagesLocallyReadWithIDs:(NSArray<NSString *> *)messageIDs completionHandler:(void (^)(void))completionHandler {
    [self safePerformAsync:^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kUAInboxDBEntityName];
        request.predicate = [NSPredicate predicateWithFormat:@"messageID IN %@", messageIDs];

        NSError *error;
        NSArray *result = [self.managedContext executeFetchRequest:request error:&error];

        if (error) {
            UA_LERR(@"Error marking messages read %@", error);
            return;
        }

        for (UAInboxMessageData *data in result) {
            data.unreadClient = NO;
        }

        [self.managedContext safeSave];

        completionHandler();
    }];
}

- (void)markMessagesLocallyDeletedWithIDs:(NSArray<NSString *> *)messageIDs completionHandler:(void (^)(void))completionHandler {
    [self safePerformAsync:^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kUAInboxDBEntityName];
        request.predicate = [NSPredicate predicateWithFormat:@"messageID IN %@", messageIDs];

        NSError *error;
        NSArray *result = [self.managedContext executeFetchRequest:request error:&error];

        if (error) {
            UA_LERR(@"Error marking messages deleted %@", error);
            return;
        }

        for (UAInboxMessageData *data in result) {
            data.deletedClient = YES;
        }

        [self.managedContext safeSave];

        completionHandler();
    }];
}

- (void)markMessagesGloballyReadWithIDs:(NSArray<NSString *> *)messageIDs {
    [self safePerformSync:^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kUAInboxDBEntityName];
        request.predicate = [NSPredicate predicateWithFormat:@"messageID IN %@", messageIDs];

        NSError *error;
        NSArray *result = [self.managedContext executeFetchRequest:request error:&error];

        if (error) {
            UA_LERR(@"Error marking messages read %@", error);
            return;
        }

        for (UAInboxMessageData *data in result) {
            data.unread = NO;
        }

        [self.managedContext safeSave];
    }];
}

- (void)deleteMessagesWithIDs:(NSArray<NSString *> *)messageIDs {
    [self safePerformSync:^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kUAInboxDBEntityName];
        request.predicate = [NSPredicate predicateWithFormat:@"messageID IN %@", messageIDs];

        NSError *error;
        NSBatchDeleteRequest *deleteRequest = [[NSBatchDeleteRequest alloc] initWithFetchRequest:request];
        [self.managedContext executeRequest:deleteRequest error:&error];

        if (error) {
            UA_LERR(@"Error deleting messages %@", error);
            return;
        }

        [self.managedContext safeSave];
    }];
}

- (BOOL)syncMessagesWithResponse:(NSArray *)messages {
    __block BOOL result;

    [self safePerformSync:^{
        // Track the response messageIDs so we can remove any messages that are
        // no longer in the response.
        NSMutableSet *newMessageIDs = [NSMutableSet set];

        for (NSDictionary *messagePayload in messages) {
            NSString *messageID = messagePayload[@"message_id"];

            if (!messageID) {
                UA_LDEBUG(@"Missing message ID: %@", messagePayload);
                continue;
            }

            if (![self updateMessageWithDictionary:messagePayload]) {
                [self addMessageFromDictionary:messagePayload];
            }

            [newMessageIDs addObject:messageID];
        }

        // Delete any messages that are no longer in the array
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kUAInboxDBEntityName];
        request.predicate = [NSPredicate predicateWithFormat:@"NOT (messageID IN %@)", newMessageIDs];

        NSError *error;
        if (self.inMemory) {
            request.includesPropertyValues = NO;
            NSArray *events = [self.managedContext executeFetchRequest:request error:&error];
            for (NSManagedObject *event in events) {
                [self.managedContext deleteObject:event];
            }
        } else {
            NSBatchDeleteRequest *deleteRequest = [[NSBatchDeleteRequest alloc] initWithFetchRequest:request];
            [self.managedContext executeRequest:deleteRequest error:&error];
        }

        result = [self.managedContext safeSave];
    }];

    return result;
}

- (NSDictionary<NSString *, NSDictionary *> *)locallyReadMessageReporting {
    __block NSMutableDictionary<NSString *, NSDictionary *> *result = [NSMutableDictionary dictionary];

    [self safePerformSync:^{
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"unreadClient == NO && unread == YES"];
        NSArray<UAInboxMessageData *> *messages = [self fetchMessageDataWithPredicate:predicate];

        for (UAInboxMessageData *data in messages) {
            if (data.messageReporting) {
                result[data.messageID] = data.messageReporting;
            }
        }
    }];

    return result;
}

- (NSDictionary<NSString *, NSDictionary *> *)locallyDeletedMessageReporting {
    __block NSMutableDictionary<NSString *, NSDictionary *> *result = [NSMutableDictionary dictionary];

    [self safePerformSync:^{
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"deletedClient == YES"];
        NSArray<UAInboxMessageData *> *messages = [self fetchMessageDataWithPredicate:predicate];

        for (UAInboxMessageData *data in messages) {
            if (data.messageReporting) {
                result[data.messageID] = data.messageReporting;
            }
        }
    }];

    return result;
}

- (void)updateMessageData:(UAInboxMessageData *)data withDictionary:(NSDictionary *)dict {

    dict = [dict dictionaryWithValuesForKeys:[[dict keysOfEntriesPassingTest:^BOOL(id key, id obj, BOOL *stop) {
        return ![obj isEqual:[NSNull null]];
    }] allObjects]];

    if (!data.isGone) {
        data.messageID = dict[@"message_id"];
        data.contentType = dict[@"content_type"];
        data.title = dict[@"title"];
        data.extra = dict[@"extra"];
        data.messageBodyURL = [NSURL URLWithString:dict[@"message_body_url"]];
        data.messageURL = [NSURL URLWithString:dict[@"message_url"]];
        data.unread = [dict[@"unread"] boolValue];
        data.messageSent = [UAUtils parseISO8601DateFromString:dict[@"message_sent"]];
        data.rawMessageObject = dict;
        data.messageReporting = dict[@"message_reporting"];

        NSString *messageExpiration = dict[@"message_expiry"];
        if (messageExpiration) {
            data.messageExpiration = [UAUtils parseISO8601DateFromString:messageExpiration];
        } else {
            data.messageExpiration = nil;
        }
    }
}


- (void)addMessageFromDictionary:(NSDictionary *)dictionary {
    UAInboxMessageData *data = (UAInboxMessageData *)[NSEntityDescription insertNewObjectForEntityForName:kUAInboxDBEntityName
                                                                                   inManagedObjectContext:self.managedContext];

    [self updateMessageData:data withDictionary:dictionary];
}

- (BOOL)updateMessageWithDictionary:(NSDictionary *)dictionary {
    NSString *messageID = dictionary[@"message_id"];
    NSError *error = nil;

    if (!messageID) {
        UA_LDEBUG(@"Missing message ID: %@", dictionary);
        return NO;
    }

    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    request.entity = [NSEntityDescription entityForName:kUAInboxDBEntityName
                                 inManagedObjectContext:self.managedContext];
    request.predicate = [NSPredicate predicateWithFormat:@"messageID == %@", messageID];
    request.fetchLimit = 1;

    NSArray *resultData = [self.managedContext executeFetchRequest:request error:&error];

    if (error) {
        UA_LERR(@"Fetch request %@ failed with with error: %@", request, error);
    }

    UAInboxMessageData *data;
    if (resultData.count) {
        data = [resultData lastObject];
        [self updateMessageData:data withDictionary:dictionary];
        return YES;
    }
    
    return NO;
}

- (UAInboxMessage *)messageFromMessageData:(UAInboxMessageData *)data {
    return [UAInboxMessage messageWithBuilderBlock:^(UAInboxMessageBuilder *builder) {
        builder.messageURL = data.messageURL;
        builder.messageID = data.messageID;
        builder.messageSent = data.messageSent;
        builder.messageBodyURL = data.messageBodyURL;
        builder.messageExpiration = data.messageExpiration;
        builder.unread = data.unreadClient & data.unread;
        builder.rawMessageObject = data.rawMessageObject;
        builder.extra = data.extra;
        builder.title = data.title;
        builder.contentType = data.contentType;
        builder.messageList = self.messageList;
    }];
}

- (void)moveDatabase {
    NSFileManager *fm = [NSFileManager defaultManager];

    NSURL *libraryDirectoryURL = [[fm URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *targetDirectory = [libraryDirectoryURL URLByAppendingPathComponent:@"com.urbanairship.no-backup"];

    NSArray *legacyURLs = @[[libraryDirectoryURL URLByAppendingPathComponent:kUACoreDataStoreName],
                            [libraryDirectoryURL URLByAppendingPathComponent:self.storeName]];

    for (NSURL *legacyURL in legacyURLs) {
        if (![fm fileExistsAtPath:[legacyURL path]]) {
            continue;
        }

        [self moveFilesFromDirectory:legacyURL toDirectory:targetDirectory];

        NSError *error = nil;
        [fm removeItemAtURL:legacyURL error:&error];
        if (error) {
            UA_LERR(@"Unable to delete directory: %@ error: %@", legacyURL, error);
        }
    }
}

- (void)moveFilesFromDirectory:(NSURL *)directoryURL toDirectory:(NSURL *)targetDirectoryURL {
    NSFileManager *fm = [NSFileManager defaultManager];

    if ([fm fileExistsAtPath:[directoryURL path]]) {
        NSError *error = nil;
        NSArray *files = [fm contentsOfDirectoryAtURL:directoryURL
                           includingPropertiesForKeys:nil
                                              options:NSDirectoryEnumerationSkipsHiddenFiles
                                                error:&error];

        if (error) {
            UA_LERR(@"Unable to move files, error: %@", error);
            return;
        }

        for (NSURL *file in files) {
            [fm moveItemAtURL:file
                        toURL:[targetDirectoryURL URLByAppendingPathComponent:[file lastPathComponent]]
                        error:&error];

            if (error) {
                UA_LERR(@"Unable to move file: %@ error: %@", file, error);
            }
        }
    }
}

- (void)safePerformSync:(void (^)(void))block {
    @synchronized (self) {
        if (!self.finished) {
            [self.managedContext safePerformBlockAndWait:^(BOOL safe){
                if (safe && !self.finished) {
                    block();
                }
            }];
        }
    }
}

- (void)safePerformAsync:(void (^)(void))block {
    @synchronized(self) {
        if (!self.finished) {
            [self.managedContext safePerformBlock:^(BOOL safe){
                if (safe && !self.finished) {
                    block();
                }
            }];
        }
    }
}

- (void)waitForIdle {
    [self.managedContext performBlockAndWait:^{}];
}

- (void)shutDown {
    @synchronized(self) {
        self.finished = YES;
    }
}


@end
