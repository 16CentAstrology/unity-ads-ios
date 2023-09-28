#import <XCTest/XCTest.h>
#import "GMABaseAdDelegateProxyTests.h"
#import "GMARewardedAdDelegateProxy.h"
#import "NSError+UADSError.h"
#import "UADSWebViewErrorHandler.h"
#import "GMAError.h"
#import "GMATestCommonConstants.h"
#import "XCTestCase+Convenience.h"

@interface GMARewardedAdDelegateProxyTests : GMABaseAdDelegateProxyTests
@end

@implementation GMARewardedAdDelegateProxyTests

- (void)test_will_present_for_the_first_time_triggers_only_ad_started_event {
    GMARewardedAdDelegateProxy *delegateToTest = self.defaultProxyToTest;

    [delegateToTest rewardedAdDidPresent:  self.fakeAdObject];
    GMAAdMetaData *meta = self.defaultMeta;
    NSArray<GMAWebViewEvent *> *expectedEvents = @[
        [GMAWebViewEvent newAdStartedWithMeta: meta]
    ];

    [self validateExpectedEvents: expectedEvents];
}

- (void)test_did_present_full_screen_for_the_first_time_triggers_events {
    GMARewardedAdDelegateProxy *delegateToTest = self.defaultProxyToTest;

    [delegateToTest adDidPresentFullScreenContent:  self.fakeAdObject];
    GMAAdMetaData *meta = self.defaultMeta;
    NSArray<GMAWebViewEvent *> *expectedEvents = @[
        [GMAWebViewEvent newAdStartedWithMeta: meta]
    ];

    [self validateExpectedEvents: expectedEvents];
}

- (void)test_did_present_full_screen_triggers_events_only_once {
    GMARewardedAdDelegateProxy *delegateToTest = self.defaultProxyToTest;

    [delegateToTest adDidPresentFullScreenContent:  self.fakeAdObject];
    [delegateToTest adDidPresentFullScreenContent:  self.fakeAdObject];
    GMAAdMetaData *meta = self.defaultMeta;
    NSArray<GMAWebViewEvent *> *expectedEvents = @[
        [GMAWebViewEvent newAdStartedWithMeta: meta],
        [GMAWebViewEvent newAdStartedWithMeta: meta],
        [GMAWebViewEvent newFirstQuartileWithMeta: meta],
        [GMAWebViewEvent newMidPointWithMeta: meta],
        [GMAWebViewEvent newThirdQuartileWithMeta: meta],
        [GMAWebViewEvent newLastQuartileWithMeta: meta]
    ];

    [self simulateQuartilesPlayed: 4];
    [self validateExpectedEvents: expectedEvents];
}

- (void)test_will_present_triggers_events_only_once {
    GMARewardedAdDelegateProxy *delegateToTest = self.defaultProxyToTest;

    [delegateToTest rewardedAdDidPresent:  self.fakeAdObject];
    [delegateToTest rewardedAdDidPresent:  self.fakeAdObject];
    GMAAdMetaData *meta = self.defaultMeta;
    NSArray<GMAWebViewEvent *> *expectedEvents = @[
        [GMAWebViewEvent newAdStartedWithMeta: meta],
        [GMAWebViewEvent newAdStartedWithMeta: meta],
        [GMAWebViewEvent newFirstQuartileWithMeta: meta],
        [GMAWebViewEvent newMidPointWithMeta: meta],
        [GMAWebViewEvent newThirdQuartileWithMeta: meta],
        [GMAWebViewEvent newLastQuartileWithMeta: meta]
    ];

    [self simulateQuartilesPlayed: 4];
    [self validateExpectedEvents: expectedEvents];
}

- (void)test_did_dismiss_sends_ad_skipped_and_closed {
    GMARewardedAdDelegateProxy *delegateToTest = self.defaultProxyToTest;

    [delegateToTest rewardedAdDidPresent:  self.fakeAdObject];
    [delegateToTest rewardedAdDidDismiss: self.fakeAdObject];
    GMAAdMetaData *meta = self.defaultMeta;
    NSArray<GMAWebViewEvent *> *expectedEvents = @[
        [GMAWebViewEvent newAdStartedWithMeta: meta],
        [GMAWebViewEvent newAdSkippedWithMeta: meta],
        [GMAWebViewEvent newAdClosedWithMeta: meta],
    ];

    [self validateExpectedEvents: expectedEvents];
}

- (void)test_did_dismiss_doesnt_send_ad_skipped_when_got_rewarded_callback_and_finished {
    GMARewardedAdDelegateProxy *delegateToTest = self.defaultProxyToTest;

    [delegateToTest rewardedAdDidPresent:  self.fakeAdObject];
    [self simulateQuartilesPlayed: 4];
    [delegateToTest didEarnReward: self.fakeAdObject];
    [delegateToTest rewardedAdDidDismiss: self.fakeAdObject];

    GMAAdMetaData *meta = self.defaultMeta;
    NSArray<GMAWebViewEvent *> *expectedEvents = @[
        [GMAWebViewEvent newAdStartedWithMeta: meta],
        [GMAWebViewEvent newFirstQuartileWithMeta: meta],
        [GMAWebViewEvent newMidPointWithMeta: meta],
        [GMAWebViewEvent newThirdQuartileWithMeta: meta],
        [GMAWebViewEvent newLastQuartileWithMeta: meta],
        [GMAWebViewEvent newAdEarnRewardWithMeta: meta],
        [GMAWebViewEvent newAdClosedWithMeta: meta],
    ];

    [self validateExpectedEvents: expectedEvents];
}

- (void)test_did_dismiss_sends_quartile_and_ad_skipped_and_closed {
    GMARewardedAdDelegateProxy *delegateToTest = self.defaultProxyToTest;

    [delegateToTest rewardedAdDidPresent:  self.fakeAdObject];
    [self simulateQuartilesPlayed: 4];
    [delegateToTest rewardedAdDidDismiss: self.fakeAdObject];

    GMAAdMetaData *meta = self.defaultMeta;
    NSArray<GMAWebViewEvent *> *expectedEvents = @[
        [GMAWebViewEvent newAdStartedWithMeta: meta],
        [GMAWebViewEvent newFirstQuartileWithMeta: meta],
        [GMAWebViewEvent newMidPointWithMeta: meta],
        [GMAWebViewEvent newThirdQuartileWithMeta: meta],
        [GMAWebViewEvent newLastQuartileWithMeta: meta],
        [GMAWebViewEvent newAdSkippedWithMeta: meta],
        [GMAWebViewEvent newAdClosedWithMeta: meta],
    ];

    [self validateExpectedEvents: expectedEvents];
}

- (void)test_ad_did_dismiss_full_screen_sends_ad_skipped_and_closed {
    GMARewardedAdDelegateProxy *delegateToTest = self.defaultProxyToTest;

    [delegateToTest rewardedAdDidPresent:  self.fakeAdObject];
    [self simulateQuartilesPlayed: 4];
    [delegateToTest adDidDismissFullScreenContent: self.fakeAdObject];
    GMAAdMetaData *meta = self.defaultMeta;
    NSArray<GMAWebViewEvent *> *expectedEvents = @[
        [GMAWebViewEvent newAdStartedWithMeta: meta],
        [GMAWebViewEvent newFirstQuartileWithMeta: meta],
        [GMAWebViewEvent newMidPointWithMeta: meta],
        [GMAWebViewEvent newThirdQuartileWithMeta: meta],
        [GMAWebViewEvent newLastQuartileWithMeta: meta],
        [GMAWebViewEvent newAdSkippedWithMeta: meta],
        [GMAWebViewEvent newAdClosedWithMeta: meta],
    ];

    [self validateExpectedEvents: expectedEvents];
}

- (void)test_ad_did_dismiss_full_screen_doesnt_send_ad_skipped_after_rewarded  {
    GMARewardedAdDelegateProxy *delegateToTest = self.defaultProxyToTest;

    [delegateToTest rewardedAdDidPresent:  self.fakeAdObject];
    [self simulateQuartilesPlayed: 4];
    [delegateToTest didEarnReward: self.fakeAdObject];
    [delegateToTest adDidDismissFullScreenContent: self.fakeAdObject];
    GMAAdMetaData *meta = self.defaultMeta;
    NSArray<GMAWebViewEvent *> *expectedEvents = @[
        [GMAWebViewEvent newAdStartedWithMeta: meta],
        [GMAWebViewEvent newFirstQuartileWithMeta: meta],
        [GMAWebViewEvent newMidPointWithMeta: meta],
        [GMAWebViewEvent newThirdQuartileWithMeta: meta],
        [GMAWebViewEvent newLastQuartileWithMeta: meta],
        [GMAWebViewEvent newAdEarnRewardWithMeta: meta],
        [GMAWebViewEvent newAdClosedWithMeta: meta],
    ];

    [self validateExpectedEvents: expectedEvents];
}

- (void)test_did_fail_sends_id_error_and_code {
    NSError *fakeError = [[NSError alloc] initWithDomain: @"domain"
                                                    code: 100
                                                userInfo: nil];

    GMARewardedAdDelegateProxy *delegateToTest = self.defaultProxyToTest;

    [delegateToTest ad: kFakePlacementID
           didFailToPresentFullScreenContentWithError: fakeError];

    NSArray<GMAWebViewEvent *> *expectedEvents = @[
        [[GMAError newShowErrorWithMeta: self.defaultMeta
                              withError: fakeError] convertToEvent]

    ];

    [self validateExpectedEvents: expectedEvents];


    NSArray *receivedParams = self.webAppMock.params[0];

    XCTAssertEqualObjects(receivedParams[0], kFakePlacementID);
    XCTAssertEqualObjects(receivedParams[1], kGMAQueryID);
    XCTAssertEqualObjects(receivedParams[2], fakeError.errorString);
    XCTAssertEqualObjects(receivedParams[3], fakeError.errorCode);
}

- (void)test_ad_did_record_click_sends_ad_click_event {
    GMARewardedAdDelegateProxy *delegateToTest = self.defaultProxyToTest;

    [delegateToTest adDidRecordClick: self.fakeAdObject];

    GMAAdMetaData *meta = self.defaultMeta;
    NSArray<GMAWebViewEvent *> *expectedEvents = @[
        [GMAWebViewEvent newAdClickedWithMeta: meta],
    ];

    [self validateExpectedEvents: expectedEvents];
}

- (void)simulateQuartilesPlayed: (NSInteger)count {
    [self.timerFactoryMock.lastTimerMock fire: count];
}


- (GMARewardedAdDelegateProxy *)defaultProxyToTest {
    return [self.delegatesFactory rewardedDelegate: self.defaultMeta];
}

- (GMAAdMetaData *)defaultMeta {
    GMAAdMetaData *meta = [GMAAdMetaData new];

    meta.adString = @"adString";
    meta.placementID = kFakePlacementID;
    meta.videoLength = @1;
    meta.queryID = kGMAQueryID;
    meta.type = GADQueryInfoAdTypeRewarded;
    return meta;
}

- (void)test_rewarded_delegate_not_crash_if_ad_not_started_before_background {
    id<UADSWebViewEventSender>eventSender = [UADSWebViewEventSenderBase new];
    id<UADSErrorHandler>errorHandler = [UADSWebViewErrorHandler newWithEventSender: eventSender];

    GMADelegatesBaseFactory *factory = [GMADelegatesBaseFactory newWithEventSender: eventSender
                                                                      errorHandler: errorHandler];

    [factory rewardedDelegate: self.defaultMeta];

    [self postDidEnterBackground];
    [self postDidBecomeActive];
}

- (void)test_no_quartile_events_sent_after_dismiss_ad {
    id<UADSWebViewEventSender>eventSender = [UADSWebViewEventSenderBase new];
    id<UADSErrorHandler>errorHandler = [UADSWebViewErrorHandler newWithEventSender: eventSender];

    GMADelegatesBaseFactory *factory = [GMADelegatesBaseFactory newWithEventSender: eventSender
                                                                      errorHandler: errorHandler];

    @autoreleasepool {
        GMARewardedAdDelegateProxy *delegateToTest = [factory rewardedDelegate: self.defaultMeta];

        [delegateToTest rewardedAdDidPresent:  self.fakeAdObject];
        [delegateToTest adDidDismissFullScreenContent: self.fakeAdObject];
    }

    [self postDidEnterBackground];
    [self postDidBecomeActive];
    GMAAdMetaData *meta = self.defaultMeta;
    NSArray<GMAWebViewEvent *> *expectedEvents = @[
        [GMAWebViewEvent newAdStartedWithMeta: meta],
        [GMAWebViewEvent newAdSkippedWithMeta: meta],
        [GMAWebViewEvent newAdClosedWithMeta: meta],
    ];

    [self waitForTimeInterval: 0.5];
    [self validateExpectedEvents: expectedEvents];
}

- (NSArray *)expectedParams {
    return @[kFakePlacementID, kGMAQueryID];
}

@end
