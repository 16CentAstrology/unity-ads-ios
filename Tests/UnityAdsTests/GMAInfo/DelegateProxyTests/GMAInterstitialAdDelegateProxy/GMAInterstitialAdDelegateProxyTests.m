#import <XCTest/XCTest.h>
#import "GMABaseAdDelegateProxyTests.h"
#import "GMAInterstitialAdDelegateProxy.h"
#import "XCTestCase+Convenience.h"
#import "NSError+UADSError.h"
#import "UADSWebViewErrorHandler.h"
#import "GMAError.h"
#import "GMATestCommonConstants.h"

@interface GMAInterstitialAdDelegateProxyTests : GMABaseAdDelegateProxyTests
@end

@implementation GMAInterstitialAdDelegateProxyTests

- (void)test_will_present_for_the_first_time_triggers_events {
    GMAInterstitialAdDelegateProxy *delegateToTest = self.defaultProxyToTest;

    [delegateToTest interstitialWillPresentScreen:  self.fakeAdObject];
    [self simulateQuartilesPlayed: 4];
    GMAAdMetaData *meta = self.defaultMeta;
    NSArray<GMAWebViewEvent *> *expectedEvents = @[
        [GMAWebViewEvent newAdStartedWithMeta: meta],
        [GMAWebViewEvent newFirstQuartileWithMeta: meta],
        [GMAWebViewEvent newMidPointWithMeta: meta],
        [GMAWebViewEvent newThirdQuartileWithMeta: meta],
        [GMAWebViewEvent newLastQuartileWithMeta: meta],
    ];

    [self validateExpectedEvents: expectedEvents];
    [self validateExpectedDefaultParamsInEvents: expectedEvents];
}

- (void)test_did_present_full_screen_for_the_first_time_triggers_events {
    GMAInterstitialAdDelegateProxy *delegateToTest = self.defaultProxyToTest;

    [delegateToTest adDidPresentFullScreenContent:  self.fakeAdObject];
    [self simulateQuartilesPlayed: 4];
    GMAAdMetaData *meta = self.defaultMeta;
    NSArray<GMAWebViewEvent *> *expectedEvents = @[
        [GMAWebViewEvent newAdStartedWithMeta: meta],
        [GMAWebViewEvent newFirstQuartileWithMeta: meta],
        [GMAWebViewEvent newMidPointWithMeta: meta],
        [GMAWebViewEvent newThirdQuartileWithMeta: meta],
        [GMAWebViewEvent newLastQuartileWithMeta: meta],
    ];

    [self validateExpectedEvents: expectedEvents];
    [self validateExpectedDefaultParamsInEvents: expectedEvents];
}

- (void)test_did_present_full_screen_triggers_events_only_once {
    GMAInterstitialAdDelegateProxy *delegateToTest = self.defaultProxyToTest;

    [delegateToTest adDidPresentFullScreenContent:  self.fakeAdObject];
    [delegateToTest adDidPresentFullScreenContent:  self.fakeAdObject];
    [self simulateQuartilesPlayed: 4];
    GMAAdMetaData *meta = self.defaultMeta;
    NSArray<GMAWebViewEvent *> *expectedEvents = @[
        [GMAWebViewEvent newAdStartedWithMeta: meta],
        [GMAWebViewEvent newAdStartedWithMeta: meta],
        [GMAWebViewEvent newFirstQuartileWithMeta: meta],
        [GMAWebViewEvent newMidPointWithMeta: meta],
        [GMAWebViewEvent newThirdQuartileWithMeta: meta],
        [GMAWebViewEvent newLastQuartileWithMeta: meta],
    ];

    [self validateExpectedEvents: expectedEvents];
    [self validateExpectedDefaultParamsInEvents: expectedEvents];
}

- (void)test_will_present_triggers_events_only_once {
    GMAInterstitialAdDelegateProxy *delegateToTest = self.defaultProxyToTest;

    [delegateToTest interstitialWillPresentScreen:  self.fakeAdObject];
    [delegateToTest interstitialWillPresentScreen:  self.fakeAdObject];
    [self simulateQuartilesPlayed: 4];
    GMAAdMetaData *meta = self.defaultMeta;
    NSArray<GMAWebViewEvent *> *expectedEvents = @[
        [GMAWebViewEvent newAdStartedWithMeta: meta],
        [GMAWebViewEvent newAdStartedWithMeta: meta],
        [GMAWebViewEvent newFirstQuartileWithMeta: meta],
        [GMAWebViewEvent newMidPointWithMeta: meta],
        [GMAWebViewEvent newThirdQuartileWithMeta: meta],
        [GMAWebViewEvent newLastQuartileWithMeta: meta],
    ];

    [self validateExpectedEvents: expectedEvents];
    [self validateExpectedDefaultParamsInEvents: expectedEvents];
}

- (void)test_did_dismiss_sends_ad_skipped_and_closed {
    GMAInterstitialAdDelegateProxy *delegateToTest = self.defaultProxyToTest;

    [delegateToTest interstitialWillPresentScreen:  self.fakeAdObject];
    [delegateToTest interstitialDidDismissScreen: self.fakeAdObject];
    GMAAdMetaData *meta = self.defaultMeta;
    NSArray<GMAWebViewEvent *> *expectedEvents = @[
        [GMAWebViewEvent newAdStartedWithMeta: meta],
        [GMAWebViewEvent newAdSkippedWithMeta: meta],
        [GMAWebViewEvent newAdClosedWithMeta: meta],
    ];

    [self validateExpectedEvents: expectedEvents];
    [self validateExpectedDefaultParamsInEvents: expectedEvents];
}

- (void)test_did_dismiss_sends_ad_skipped_and_closed_if_only_3_quartiles_reached {
    GMAInterstitialAdDelegateProxy *delegateToTest = self.defaultProxyToTest;

    [delegateToTest interstitialWillPresentScreen:  self.fakeAdObject];
    [self simulateQuartilesPlayed: 3];
    [delegateToTest interstitialDidDismissScreen: self.fakeAdObject];
    GMAAdMetaData *meta = self.defaultMeta;
    NSArray<GMAWebViewEvent *> *expectedEvents = @[
        [GMAWebViewEvent newAdStartedWithMeta: meta],
        [GMAWebViewEvent newFirstQuartileWithMeta: meta],
        [GMAWebViewEvent newMidPointWithMeta: meta],
        [GMAWebViewEvent newThirdQuartileWithMeta: meta],
        [GMAWebViewEvent newAdSkippedWithMeta: meta],
        [GMAWebViewEvent newAdClosedWithMeta: meta],
    ];

    [self validateExpectedEvents: expectedEvents];
    [self validateExpectedDefaultParamsInEvents: expectedEvents];
}

- (void)test_no_quarlites_events_after_did_dismiss {
    GMAInterstitialAdDelegateProxy *delegateToTest = self.defaultProxyToTest;

    [delegateToTest interstitialWillPresentScreen:  self.fakeAdObject];
    [self simulateQuartilesPlayed: 2];
    [delegateToTest interstitialDidDismissScreen: self.fakeAdObject];
    XCTAssertTrue(self.timerFactoryMock.lastTimerMock.invalidateCalled);
    GMAAdMetaData *meta = self.defaultMeta;
    NSArray<GMAWebViewEvent *> *expectedEvents = @[
        [GMAWebViewEvent newAdStartedWithMeta: meta],
        [GMAWebViewEvent newFirstQuartileWithMeta: meta],
        [GMAWebViewEvent newMidPointWithMeta: meta],
        [GMAWebViewEvent newAdSkippedWithMeta: meta],
        [GMAWebViewEvent newAdClosedWithMeta: meta],
    ];

    [self validateExpectedEvents: expectedEvents];
    [self validateExpectedDefaultParamsInEvents: expectedEvents];
}

- (void)test_did_dismiss_doesnt_send_ad_skipped_when_finished {
    GMAInterstitialAdDelegateProxy *delegateToTest = self.defaultProxyToTest;

    [delegateToTest interstitialWillPresentScreen:  self.fakeAdObject];
    [self simulateQuartilesPlayed: 4];
    [delegateToTest interstitialDidDismissScreen: self.fakeAdObject];

    GMAAdMetaData *meta = self.defaultMeta;
    NSArray<GMAWebViewEvent *> *expectedEvents = @[
        [GMAWebViewEvent newAdStartedWithMeta: meta],
        [GMAWebViewEvent newFirstQuartileWithMeta: meta],
        [GMAWebViewEvent newMidPointWithMeta: meta],
        [GMAWebViewEvent newThirdQuartileWithMeta: meta],
        [GMAWebViewEvent newLastQuartileWithMeta: meta],
        [GMAWebViewEvent newAdClosedWithMeta: meta],
    ];

    [self validateExpectedEvents: expectedEvents];
    [self validateExpectedDefaultParamsInEvents: expectedEvents];
}

- (void)test_ad_did_dismiss_full_screen_sends_ad_skipped_and_closed {
    GMAInterstitialAdDelegateProxy *delegateToTest = self.defaultProxyToTest;

    [delegateToTest interstitialWillPresentScreen:  self.fakeAdObject];
    [delegateToTest adDidDismissFullScreenContent: self.fakeAdObject];
    GMAAdMetaData *meta = self.defaultMeta;
    NSArray<GMAWebViewEvent *> *expectedEvents = @[
        [GMAWebViewEvent newAdStartedWithMeta: meta],
        [GMAWebViewEvent newAdSkippedWithMeta: meta],
        [GMAWebViewEvent newAdClosedWithMeta: meta],
    ];

    [self validateExpectedEvents: expectedEvents];
    [self validateExpectedDefaultParamsInEvents: expectedEvents];
}

- (void)test_ad_did_dismiss_full_screen_doesnt_send_ad_skipped_when_finished  {
    GMAInterstitialAdDelegateProxy *delegateToTest = self.defaultProxyToTest;

    [delegateToTest interstitialWillPresentScreen:  self.fakeAdObject];
    [self simulateQuartilesPlayed: 4];
    [delegateToTest adDidDismissFullScreenContent: self.fakeAdObject];
    GMAAdMetaData *meta = self.defaultMeta;
    NSArray<GMAWebViewEvent *> *expectedEvents = @[
        [GMAWebViewEvent newAdStartedWithMeta: meta],
        [GMAWebViewEvent newFirstQuartileWithMeta: meta],
        [GMAWebViewEvent newMidPointWithMeta: meta],
        [GMAWebViewEvent newThirdQuartileWithMeta: meta],
        [GMAWebViewEvent newLastQuartileWithMeta: meta],
        [GMAWebViewEvent newAdClosedWithMeta: meta],
    ];

    [self validateExpectedEvents: expectedEvents];
    [self validateExpectedDefaultParamsInEvents: expectedEvents];
}

- (void)test_will_leave_app_triggers_click {
    GMAInterstitialAdDelegateProxy *delegateToTest = self.defaultProxyToTest;

    [delegateToTest interstitialWillLeaveApplication: self.fakeAdObject];

    GMAAdMetaData *meta = self.defaultMeta;
    NSArray<GMAWebViewEvent *> *expectedEvents = @[
        [GMAWebViewEvent newAdClickedWithMeta: meta],
    ];

    [self validateExpectedEvents: expectedEvents];
    [self validateExpectedDefaultParamsInEvents: expectedEvents];
}

- (void)test_ad_did_record_click_sends_ad_click_event {
    GMAInterstitialAdDelegateProxy *delegateToTest = self.defaultProxyToTest;

    [delegateToTest adDidRecordClick: self.fakeAdObject];

    GMAAdMetaData *meta = self.defaultMeta;
    NSArray<GMAWebViewEvent *> *expectedEvents = @[
        [GMAWebViewEvent newAdClickedWithMeta: meta],
    ];

    [self validateExpectedEvents: expectedEvents];
    [self validateExpectedDefaultParamsInEvents: expectedEvents];
}

- (void)test_did_fail_sends_id_error_and_code {
    NSError *fakeError = [[NSError alloc] initWithDomain: @"domain "
                                                    code: 100
                                                userInfo: nil];

    GMAInterstitialAdDelegateProxy *delegateToTest = self.defaultProxyToTest;

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

- (void)simulateQuartilesPlayed: (NSInteger)count {
    [self.timerFactoryMock.lastTimerMock fire: count];
}

- (GMAInterstitialAdDelegateProxy *)defaultProxyToTest {
    return [self.delegatesFactory interstitialDelegate: self.defaultMeta
                                         andCompletion: [UADSAnyCompletion new]];
}

- (GMAAdMetaData *)defaultMeta {
    GMAAdMetaData *meta = [GMAAdMetaData new];

    meta.adString = @"adString ";
    meta.placementID = kFakePlacementID;
    meta.videoLength = @1;
    meta.queryID = kGMAQueryID;
    meta.type = GADQueryInfoAdTypeInterstitial;
    return meta;
}

- (NSArray *)expectedParams {
    return @[kFakePlacementID, kGMAQueryID];
}

- (void)test_factory_not_crash_if_ad_not_started_before_background {
    id<UADSWebViewEventSender>eventSender = [UADSWebViewEventSenderBase new];
    id<UADSErrorHandler>errorHandler = [UADSWebViewErrorHandler newWithEventSender: eventSender];

    [GMADelegatesBaseFactory newWithEventSender: eventSender
                                   errorHandler: errorHandler];

    [self postDidEnterBackground];
    [self postDidBecomeActive];
}

- (void)test_interstitial_delegate_not_crash_if_ad_not_started_before_background {
    id<UADSWebViewEventSender>eventSender = [UADSWebViewEventSenderBase new];
    id<UADSErrorHandler>errorHandler = [UADSWebViewErrorHandler newWithEventSender: eventSender];

    GMADelegatesBaseFactory *factory = [GMADelegatesBaseFactory newWithEventSender: eventSender
                                                                      errorHandler: errorHandler];

    [factory interstitialDelegate: self.defaultMeta
                    andCompletion: [UADSAnyCompletion new]];

    [self postDidEnterBackground];
    [self postDidBecomeActive];
}

- (void)test_no_quartile_events_sent_after_dismiss_ad {
    id<UADSWebViewEventSender>eventSender = [UADSWebViewEventSenderBase new];
    id<UADSErrorHandler>errorHandler = [UADSWebViewErrorHandler newWithEventSender: eventSender];

    GMADelegatesBaseFactory *factory = [GMADelegatesBaseFactory newWithEventSender: eventSender
                                                                      errorHandler: errorHandler];

    @autoreleasepool {
        GMAInterstitialAdDelegateProxy *delegateToTest = [factory interstitialDelegate: self.defaultMeta
                                                                         andCompletion: [UADSAnyCompletion new]];

        [delegateToTest interstitialWillPresentScreen:  self.fakeAdObject];
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

@end
