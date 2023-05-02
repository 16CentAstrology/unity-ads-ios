#import "UnityServices.h"
#import "USRVSdkProperties.h"
#import "USRVEnvironmentProperties.h"
#import "USRVClientProperties.h"
#import "USRVInitialize.h"
#import "USRVDevice.h"
#import "UADSServiceProviderContainer.h"

@implementation UnityServices

+ (void)        initialize: (NSString *)gameId
                  testMode: (BOOL)testMode
    initializationDelegate: (nullable id<UnityAdsInitializationDelegate>)initializationDelegate {
    if (UADSServiceProviderContainer.sharedInstance.serviceProvider.newInitFlowEnabled) {
        [self newStart: gameId testMode: testMode delegate: initializationDelegate];
    } else {
        [self legacyStart: gameId testMode: testMode delegate: initializationDelegate];
    }
} /* initialize */

+ (void)legacyStart: (NSString *)gameId
           testMode: (BOOL)testMode
           delegate: (nullable id<UnityAdsInitializationDelegate>)initializationDelegate  {
    @synchronized (self) {
        if ([USRVSdkProperties getCurrentInitializationState] != NOT_INITIALIZED) {
            NSString *differingParams = @"";

            NSString *previousGameId = [USRVClientProperties getGameId];

            if (![previousGameId isEqualToString: gameId]) {
                differingParams = [NSString stringWithFormat: @"%@%@", differingParams, [self createExpectedParametersString: @"Game ID"
                                                                                                                     current: previousGameId
                                                                                                                    received: gameId]];
            }

            bool previousTestMode = [USRVSdkProperties isTestMode];

            if (previousTestMode != testMode) {
                differingParams = [NSString stringWithFormat: @"%@%@", differingParams, [self createExpectedParametersString: @"Test Mode"
                                                                                                                     current: [NSString stringWithFormat: @"%d", previousTestMode]
                                                                                                                    received: [NSString stringWithFormat: @"%d", testMode]]];
            }

            if ([differingParams length] > 0) {
                NSString *errorMessage = [NSString stringWithFormat: @"Unity Ads SDK failed to initialize due to already being initialized with separate options %@", differingParams];

                if (initializationDelegate != nil && [initializationDelegate respondsToSelector: @selector(initializationFailed:withMessage:)]) {
                    [initializationDelegate initializationFailed: kUnityInitializationErrorInvalidArgument
                                                     withMessage: errorMessage];
                }

                return;
            }
        }

        [USRVSdkProperties addInitializationDelegate: initializationDelegate];

        if ([USRVSdkProperties getCurrentInitializationState] == INITIALIZED_SUCCESSFULLY) {
            [USRVSdkProperties notifyInitializationComplete];
            return;
        }

        if ([USRVSdkProperties getCurrentInitializationState] == INITIALIZED_FAILED) {
            [USRVSdkProperties notifyInitializationFailed: kUnityInitializationErrorInternalError
                                         withErrorMessage: @"Unity Ads SDK failed to initialize due to previous failed reason."];
            return;
        }

        if ([USRVSdkProperties getCurrentInitializationState] == INITIALIZING) {
            return;
        }

        [USRVSdkProperties setInitializationState: INITIALIZING];

        // Bad game id or nil delegate
        if (!gameId || [gameId length] == 0) {
            USRVLogError(@"Unity ads init: invalid argument, halting init");
            NSString *errorMessage = @"Unity Ads SDK failed to initialize due to empty game ID";
            [USRVSdkProperties notifyInitializationFailed: kUnityInitializationErrorInvalidArgument
                                         withErrorMessage: errorMessage];

            if (initializationDelegate != nil && [initializationDelegate respondsToSelector: @selector(initializationFailed:withMessage:)]) {
                [initializationDelegate initializationFailed: kUnityInitializationErrorInvalidArgument
                                                 withMessage: errorMessage];
            }

            return;
        }

        [USRVSdkProperties setInitializationTime: [[USRVDevice getElapsedRealtime] longLongValue]];

        if (testMode) {
            USRVLogInfo(@"Initializing Unity Ads %@ (%d) with game id %@ in test mode, session %@", [USRVSdkProperties getVersionName], [USRVSdkProperties getVersionCode], gameId, UADSServiceProviderContainer.sharedInstance.serviceProvider.sharedSessionId);
        } else {
            USRVLogInfo(@"Initializing Unity Ads %@ (%d) with game id %@ in production mode, session %@", [USRVSdkProperties getVersionName], [USRVSdkProperties getVersionCode], gameId, UADSServiceProviderContainer.sharedInstance.serviceProvider.sharedSessionId);
        }

        if ([USRVEnvironmentProperties isEnvironmentOk]) {
            // TODO: Log environment OK
        } else {
            // TODO: Log environment not OK and send init sanity check fail to delegate
            [USRVSdkProperties notifyInitializationFailed: kUnityInitializationErrorInternalError
                                         withErrorMessage: @"Unity Ads SDK failed to initialize due to environment check failed."];
            return;
        }

        [UnityServices setDebugMode: [USRVSdkProperties getDebugMode]];
        [USRVClientProperties setGameId: gameId];
        [USRVSdkProperties setTestMode: testMode];
        USRVConfiguration *configuration = [[USRVConfiguration alloc] init];
        [USRVInitialize initialize: configuration];
    }
}

+ (void)newStart: (NSString *)gameId
        testMode: (BOOL)testMode
        delegate: (nullable id<UnityAdsInitializationDelegate>)initializationDelegate  {
    @synchronized (self) {

        [USRVSdkProperties addInitializationDelegate: initializationDelegate];
      
        [USRVSdkProperties setInitializationTime: [[USRVDevice getElapsedRealtime] longLongValue]];
        
        [UnityServices setDebugMode: [USRVSdkProperties getDebugMode]];
        [USRVClientProperties setGameId: gameId];
        [USRVSdkProperties setTestMode: testMode];
        
        [UADSServiceProviderContainer.sharedInstance.serviceProvider.sdkInitializer initializeWithGameID: gameId
                                                                                                testMode:testMode
                                                                                              completion:^{
            [USRVSdkProperties setInitializationState: INITIALIZED_SUCCESSFULLY];
            
        } error:^(NSError * _Nonnull error) {
            [self onInitError:error];
        }];
    }
}

+ (void)onInitError: (NSError *)error {
    [UADSServiceProviderContainer.sharedInstance.serviceProvider.hbTokenReader setInitToken: nil];
    [UADSServiceProviderContainer.sharedInstance.serviceProvider.hbTokenReader deleteTokens];
    
    [USRVSdkProperties setInitializationState: INITIALIZED_FAILED];
    
    [[USRVInitializationNotificationCenter sharedInstance] triggerSdkInitializeDidFail: @"Unity Ads SDK failed to initialize"
                                                                                  code: error.code];

    dispatch_async(dispatch_get_main_queue(), ^{
        [USRVSdkProperties notifyInitializationFailed: kUnityInitializationErrorInternalError
                                     withErrorMessage: error.localizedDescription];
    });

}

+ (BOOL)getDebugMode {
    return [USRVSdkProperties getDebugMode];
}

+ (void)setDebugMode: (BOOL)enableDebugMode {
    [USRVSdkProperties setDebugMode: enableDebugMode];
}

+ (BOOL)isSupported {
    if (NSFoundationVersionNumber >= NSFoundationVersionNumber_iOS_7_0) {
        return true;
    }

    return false;
}

+ (NSString *)getVersion {
    return [USRVSdkProperties getVersionName];
}

+ (BOOL)isInitialized {
    return [USRVSdkProperties isInitialized];
}

+ (NSString *)createExpectedParametersString: (NSString *)fieldName
                                     current: (NSString *)current
                                    received: (NSString *)received {
    return [NSString stringWithFormat: @"\r - %@ Current: %@ | Received: %@", fieldName, current, received];
}

@end
