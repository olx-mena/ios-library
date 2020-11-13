/* Copyright Airship and Contributors */

#import <Foundation/Foundation.h>

#import "UAAirshipMessageCenterCoreImport.h"

@class UAUser;
@class UARuntimeConfig;
@class UAUserData;

NS_ASSUME_NONNULL_BEGIN

/**
 * Represents possible channel API client errors.
 */
typedef NS_ENUM(NSInteger, UAUserAPIClientError) {
    /**
     * Indicates an error that should be retried.
     */
    UAUserAPIClientErrorRecoverable,

    /**
     * Indicates an error that should not be retried.
     */
    UAUserAPIClientErrorUnrecoverable
};

/**
 * The domain for NSErrors generated by the channel API client.
 */
extern NSString * const UAUserAPIClientErrorDomain;

/**
 * High level abstraction for the User API.
 */
@interface UAUserAPIClient : NSObject

///---------------------------------------------------------------------------------------
/// @name User API Client Internal Methods
///---------------------------------------------------------------------------------------

/**
 * Factory method to create a UAUserAPIClient.
 * @param config The Airship config.
 * @return UAUserAPIClient instance.
 */
+ (instancetype)clientWithConfig:(UARuntimeConfig *)config;

/**
 * Factory method to create a UAUserAPIClient.
 * @param config The Airship config.
 * @param session The request session.
 * @return UAUserAPIClient instance.
 */
+ (instancetype)clientWithConfig:(UARuntimeConfig *)config session:(UARequestSession *)session;

/**
 * Create a user.
 *
 * @param channelID The user's channel ID.
 * @param completionHandler The completion handler. If an error is present the the data will be nil. All errors are in the `UAUserAPIClientErrorDomain` domain.
 * @return A disposable to cancel the request. The completion handler will still be called with a recoverable error.
 */
- (UADisposable *)createUserWithChannelID:(NSString *)channelID
                        completionHandler:(void (^)(UAUserData * _Nullable data, NSError * _Nullable error))completionHandler;

/**
 * Update a user.
 *
 * @param userData The user data to update.
 * @param channelID The user's channel ID.
 * @param completionHandler The completion handler. If an error is present the user failed to update. All errors are in the `UAUserAPIClientErrorDomain` domain.
 * @return A disposable to cancel the request. The completion handler will  be called with a recoverable error.
 */
- (UADisposable *)updateUserWithData:(UAUserData *)userData
                           channelID:(NSString *)channelID
                   completionHandler:(void (^)(NSError * _Nullable error))completionHandler;


@end

NS_ASSUME_NONNULL_END
