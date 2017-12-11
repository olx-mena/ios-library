/* Copyright 2017 Urban Airship and Contributors */

#import <UIKit/UIKit.h>
#import "UAInAppMessageButtonInfo.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Represents the possible in-app message button rounding options.
 */
typedef NS_OPTIONS(NSUInteger, UAInAppMessageButtonRounding) {
    /**
     * Top left corner only.
     */
    UAInAppMessageButtonRoundingTopLeftCorner = 1 << 0,
    /**
     * Top right corner only.
     */
    UAInAppMessageButtonRoundingTopRightCorner  = 1 << 1,
    /**
     * Bottom left corner only.
     */
    UAInAppMessageButtonRoundingBottomLeftCorner  = 1 << 2,
    /**
     * Bottom right corner only.
     */
    UAInAppMessageButtonRoundingBottomRightCorner = 1 << 3,

    /**
     * All corners.
     */
    UAInAppMessageButtonRoundingOptionAllCorners  = ~0UL
};

@interface UAInAppMessageButton : UIButton

/**
 * The button info for the button.
 */
@property(nonatomic, strong, readonly) UAInAppMessageButtonInfo *buttonInfo;

/**
 * Factory method for creating an in-app message button.
 *
 * @param buttonInfo The button info.
 * @param rounding The edges to round.
 */
+ (instancetype)buttonWithButtonInfo:(UAInAppMessageButtonInfo *)buttonInfo
                            rounding:(UAInAppMessageButtonRounding)rounding;

@end

NS_ASSUME_NONNULL_END
