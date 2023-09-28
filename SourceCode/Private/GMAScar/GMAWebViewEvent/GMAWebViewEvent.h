#import <Foundation/Foundation.h>
#import "UADSWebViewEvent.h"
#import "GADBaseAd.h"
#import "GMAAdMetaData.h"
NS_ASSUME_NONNULL_BEGIN

@interface GMAWebViewEvent : UADSWebViewEventBase

+ (instancetype)newWithEventName: (NSString *)event
                       andParams: (NSArray *_Nullable)params;
+ (instancetype)newWithEventName: (NSString *)event
                         andMeta: (GMAAdMetaData *)meta;
+ (instancetype)newAdEarnRewardWithMeta: (GMAAdMetaData *)meta;
+ (instancetype)newAdStartedWithMeta: (GMAAdMetaData *)meta;
+ (instancetype)newFirstQuartileWithMeta: (GMAAdMetaData *)meta;
+ (instancetype)newMidPointWithMeta: (GMAAdMetaData *)meta;
+ (instancetype)newThirdQuartileWithMeta: (GMAAdMetaData *)meta;
+ (instancetype)newLastQuartileWithMeta: (GMAAdMetaData *)meta;
+ (instancetype)newAdSkippedWithMeta: (GMAAdMetaData *)meta;
+ (instancetype)newAdClosedWithMeta: (GMAAdMetaData *)meta;
+ (instancetype)newAdClickedWithMeta: (GMAAdMetaData *)meta;
+ (instancetype)newImpressionRecordedWithMeta: (GMAAdMetaData *)meta;
+ (instancetype)newSignalsEvent: (NSString *)signals;
+ (instancetype)newAdLoadedWithMeta: (GMAAdMetaData *)meta
                        andLoadedAd: (GADBaseAd *_Nullable)ad;
+ (instancetype)newScarPresent;
+ (instancetype)newScarNotPresent;
+ (instancetype)newScarUnsupported;
@end

NS_ASSUME_NONNULL_END
