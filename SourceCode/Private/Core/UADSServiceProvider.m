#import "UADSServiceProvider.h"
#import "UADSTools.h"
#import "UADSHeaderBiddingTokenReaderBuilder.h"
#import "UADSConfigurationSaverWithTokenStorage.h"
#import "UADSMetricSenderWithBatch.h"
#import "USRVDeviceLog.h"
#import "UADSConfigurationLoaderBuilder.h"
#import "USRVStorageManager.h"
#import "UADSCurrentTimestampBase.h"
#import "UADSGameSessionIdReader.h"
#import "UADSWebRequestFactorySwiftAdapter.h"
#import "UADSDeviceInfoReaderBuilder.h"
#import "UADSSharedSessionIdReader.h"
#import "USRVJsonStorageAggregator.h"

@interface UADSServiceProvider ()
@property (nonatomic, strong) id<UADSPerformanceLogger>performanceLogger;
@property (nonatomic, strong) UADSPerformanceMeasurer *performanceMeasurer;
@property (nonatomic, strong) id<UADSGameSessionIdReader> gameSessionIdReader;
@property (nonatomic, strong) id<UADSSharedSessionIdReader> sharedSessionIdReader;
@end

@implementation UADSServiceProvider

- (instancetype)init {
    SUPER_INIT
    UADSConfigurationCRUDBase *crudBase = [UADSConfigurationCRUDBase new];
    self.configurationStorage = crudBase;
    self.privacyStorage = [UADSPrivacyStorage new];
    self.performanceMeasurer = [UADSPerformanceMeasurer newWithTimestampReader: [UADSCurrentTimestampBase new]];
    self.logger = [UADSConsoleLogger newWithSystemList: @[]];
    self.performanceLogger = [UADSPerformanceLoggerBase newWithLogger: self.logger];
    /**
        this is done as a quick workaround to be able to call internal functions from swift without exposing too much to public
        we need device info only when its created and the builder needs to be created at request as well in order to use the lates config
     */
    self.objBridge = [UADSServiceProviderProxy newWithDeviceInfoProvider: self];
    
    crudBase.serviceProviderBridge = self.objBridge;
    self.gameSessionIdReader = [UADSGameSessionIdReaderBase new];
    self.sharedSessionIdReader = [UADSSharedSessionIdReaderBase new];
    return self;
}

- (BOOL)newInitFlowEnabled {
    return [self.experiments isSwiftInitFlowEnabled];
}

- (BOOL)isOrientationSafeguardEnabled {
    return [self.experiments isOrientationSafeguardEnabled];
}

-(NSDictionary *)getDeviceInfoWithExtended: (BOOL)extended {
    
    return [[self deviceInfoBuilderWithMetrics: true] getDeviceInfoWithExtended: extended];
}

- (NSString *)sharedSessionId {
    return self.sharedSessionIdReader.sessionId;
}

-(void)didCompleteInit: (NSDictionary *)config {
    [_configurationStorage triggerSaved: [USRVConfiguration newFromJSON: config]];
}

- (void)didReceivePrivacy: (NSDictionary *) privacy {
    [_privacyStorage saveResponse: [UADSInitializationResponse newFromDictionary:privacy]];
}

- (id)getValueFromJSONStorageFor: (NSString *)key {
    return [USRVJsonStorageAggregator.defaultAggregator getValueForKey: key];
}

- (id)storageContent {
    return [USRVJsonStorageAggregator.defaultAggregator getContents];
}

- (void)deleteKeyFromJSONStorageFor: (NSString *)key {
    [[USRVStorageManager getStorage: kUnityServicesStorageTypePrivate] deleteKey:key];
}
-(void)setValueToJSONStorage:(id)value for: (NSString *)key {
    [[USRVStorageManager getStorage: kUnityServicesStorageTypePrivate] set:key value: value];
}

- (id<UADSHeaderBiddingAsyncTokenReader, UADSHeaderBiddingTokenCRUD>)hbTokenReader {
    @synchronized (self) {
        if (!_hbTokenReader) {
            UADSHeaderBiddingTokenReaderBuilder *tokenReaderBuilder = self.tokenBuilder;
            tokenReaderBuilder.metricsSender = self.metricSender;
            _hbTokenReader = tokenReaderBuilder.defaultReader;
        }
    }
    return _hbTokenReader;
}

- (id<UADSWebViewEventSender>)webViewEventSender {
    if (_webViewEventSender) {
        return _webViewEventSender;
    }

    return [UADSWebViewEventSenderBase new];
}

- (id<UADSHeaderBiddingAsyncTokenReader>)nativeTokenGenerator {
    UADSHeaderBiddingTokenReaderBuilder *tokenReaderBuilder = self.tokenBuilder;

    tokenReaderBuilder.nativeTokenPrefix = @"";
    return tokenReaderBuilder.tokenGenerator;
}

- (UADSHeaderBiddingTokenReaderBuilder *)tokenBuilder {
    if (_tokenBuilder) {
        return _tokenBuilder;
    }

    UADSHeaderBiddingTokenReaderBuilder *tokenReaderBuilder = [UADSHeaderBiddingTokenReaderBuilder new];

    tokenReaderBuilder.privacyStorage = self.privacyStorage;
    tokenReaderBuilder.sdkConfigReader = self.configurationStorage;
    tokenReaderBuilder.tokenCRUD =  [UADSTokenStorage sharedInstance];
    tokenReaderBuilder.gameSessionIdReader = self.gameSessionIdReader;
    tokenReaderBuilder.scar = [UADSGMAScar sharedInstance];
    tokenReaderBuilder.requestFactory = self.webViewRequestFactory;
    tokenReaderBuilder.sharedSessionIdReader = self.sharedSessionIdReader;
    return tokenReaderBuilder;
}

- (id<UADSConfigurationSaver>)configurationSaver {
    return [UADSConfigurationSaverWithTokenStorage newWithTokenCRUD: self.hbTokenReader
                                                        andOriginal: self.configurationStorage];
}

- (id<ISDKMetrics>)metricSender {
    @synchronized (self) {
        if (!_metricSender) {
            _metricSender = [UADSMetricSender newWithConfigurationReader: self.configurationStorage
                                                       andRequestFactory: self.metricsRequestFactory
                                                           storageReader: [USRVStorageManager getStorage: kUnityServicesStorageTypePublic]
                                                           privacyReader: self.privacyStorage
                                                   sharedSessionIdReader: self.sharedSessionIdReader];
            _metricSender = [UADSMetricSenderWithBatch decorateWithMetricSender: self.metricSender
                                                        andConfigurationSubject: self.configurationStorage
                                                                      andLogger: self.logger];
        }
    }

    return _metricSender;
}


- (id<IUSRVWebRequestFactory>)metricsRequestFactory {
    if (_metricsRequestFactory) {
        return _metricsRequestFactory;
    }
    
    if ([self.experiments isSwiftNativeRequestsEnabled]) {
        return [UADSWebRequestFactorySwiftAdapter newWithMetricSender: nil
                                                      andNetworkLayer: self.objBridge.nativeMetricsNetworkLayer];
    } else {
        return [USRVWebRequestFactory new];
    }
}

- (id<IUSRVWebRequestFactory>)webViewRequestFactory {
    if (_webViewRequestFactory) {
        return _webViewRequestFactory;
    }
    if ([self.experiments isSwiftWebViewRequestsEnabled]) {
        return [UADSWebRequestFactorySwiftAdapter newWithMetricSender: self.metricSender
                                                      andNetworkLayer: self.objBridge.nativeNetworkLayer];
    } else {
        return [USRVWebRequestFactory new];
    }
}

- (id<UADSDeviceInfoProvider>)deviceInfoBuilderWithMetrics: (BOOL)includeMetrics {
    UADSDeviceInfoReaderBuilder *builder = [UADSDeviceInfoReaderBuilder new];

    builder.metricsSender = includeMetrics ? self.metricSender : nil;
    builder.clientConfig = [UADSCClientConfigBase defaultWithExperiments: self.experiments];;
    builder.privacyReader = self.privacyStorage;
    builder.logger = self.logger;
    builder.currentTimeStampReader = [UADSCurrentTimestampBase new];
    builder.gameSessionIdReader = self.gameSessionIdReader;
    builder.sharedSessionIdReader = self.sharedSessionIdReader;
    return builder;
}

- (id<UADSConfigurationLoader>)configurationLoader {
    UADSCClientConfigBase *config = [UADSCClientConfigBase defaultWithExperiments: self.experiments];
    
    
    UADSConfigurationLoaderBuilder *builder = [UADSConfigurationLoaderBuilder newWithConfig: config
                                                                       andWebRequestFactory: self.webViewRequestFactory
                                                                               metricSender: self.metricSender];
    
    builder.privacyStorage = self.privacyStorage;
    builder.logger = self.logger;
    builder.configurationSaver = self.configurationSaver;
    builder.currentTimeStampReader = [UADSCurrentTimestampBase new];
    builder.retryInfoReader = self.retryReader;
    builder.gameSessionIdReader = self.gameSessionIdReader;
    builder.metricsSender = self.metricSender;
    builder.sharedSessionIdReader = self.sharedSessionIdReader;
    return builder.configurationLoader;
 }

- (UADSConfigurationExperiments *)experiments {
    return self.configurationStorage.currentSessionExperiments;
}

- (USRVInitializeStateFactory *)stateFactory {
    if (_stateFactory) {
        return _stateFactory;
    }
    return [USRVInitializeStateFactory newWithBuilder: self
                                      andConfigReader: self.configurationStorage];
}

- (UADSSDKInitializerProxy *)sdkInitializer {
    return [self.objBridge sdkInitializerWithFactory: self.stateFactory];
}

- (UADSCommonNetworkProxy *)nativeNetworkLayer {
    return self.objBridge.nativeNetworkLayer;
}

@end
