import XCTest
@testable import UnityAds
// swiftlint:disable type_body_length
// swiftlint:disable file_length
final class SDKInitializerParallelFlowIntegrationTests: SDKInitializerLegacyIntegrationTestsBase {

    override var defaultExperiments: [String: Bool] {
        var dictionary = super.defaultExperiments
        dictionary["s_pte"] = true
        dictionary["s_din"] = true
        return dictionary
    }

    func test_init_finishes_with_success_when_config_and_web_view_are_available() throws {
        let returnedConfigData = try configMockFactory.defaultConfigData(experiments: defaultExperiments)
        let privacyData = returnedConfigData
        let expectedConfig = try configMockFactory.defaultUnityAdsConfig(experiments: defaultExperiments)
        let responses: [URLProtocolResponseStub] = [
            .init(data: privacyData),
            .init(data: returnedConfigData),
            .init(data: configMockFactory.webViewFakeData, url: expectedConfig.network.webView.url)
        ]

        let testConfig = TestConfig(responses: responses,
                                    sdkConfig: expectedConfig,
                                    expectedNumberOfRequests: responses.count,
                                    multithreadCount: 1,
                                    metrics: ExpectedMetrics.ParallelFlow.HappyPath,
                                    expectDiagnostic: true)
        try executeTest(with: testConfig,
                        resultValidation: { XCTAssertSuccess($0) },
                        final: {

            XCTAssertEqual(self.tester.sdkState, .initialized)
            self.verifyWebExposedGetTrrData(expectedConfig)
        })

    }

    func test_init_fails_when_privacy_fails_with_defined_codes() throws {
        let expectedFailureCode = 423
        let expectedConfig = try configMockFactory.defaultUnityAdsConfig(experiments: defaultExperiments)
        let privacyResponseError = NSError(domain: "network", code: expectedFailureCode)
        let responses: [URLProtocolResponseStub] = [
            .init(error: privacyResponseError)
        ]

        var sdkMetrics: [SDKMetricType] =  [
            .legacy(.initStarted)
        ]

        let sdkPerformanceMetrics: [SDKMetricType] = [
            .requestPerformance(.failure(.privacy)),
            .taskPerformance(.failure(.initializer)),
            .taskPerformance(.success(.loadLocalConfig)),
            .taskPerformance(.failure(.privacyFetch)),
            .taskPerformance(.success(.initModules)),
            .taskPerformance(.success(.reset))
        ]

        sdkMetrics += sdkPerformanceMetrics
        let testConfig = TestConfig(responses: responses,
                                    sdkConfig: expectedConfig,
                                    expectedNumberOfRequests: responses.count,
                                    multithreadCount: 1,
                                    metrics: sdkMetrics,
                                    expectDiagnostic: true)
        try executeTest(with: testConfig,
                        resultValidation: { XCTAssertFailure($0) },
                        final: {

            let error = self.extractErrorFromState(self.tester.sdkState)

            XCTAssertEqual(error as? PrivacyError, .gameIdDisabled)
        })
    }

    func test_init_fails_with_error_when_config_has_corrupted_data() throws {

        let corruptedConfig = try ["key": "value"].serializedData()
        let expectedConfig = try configMockFactory.defaultUnityAdsConfig(experiments: defaultExperiments)
        let privacyResponsesData = try configMockFactory.defaultConfigData(experiments: defaultExperiments)

        let responses: [URLProtocolResponseStub] = [
            .init(data: privacyResponsesData),
            .init(data: corruptedConfig),
            .init(data: configMockFactory.webViewFakeData, url: expectedConfig.network.webView.url) // web view request is in parallel to config
        ]
        var sdkMetrics: [SDKMetricType] =  [ .legacy(.initStarted) ]

        let configRequestMetrics: [SDKMetricType] = [
            .systemPerformance(.success(.compression)),
            .systemPerformance(.success(.infoCollection)),
            .requestPerformance(.failure(.config))

        ]

        let sdkPerformanceMetrics: [SDKMetricType] = [
            .requestPerformance(.success(.privacy)),
            .taskPerformance(.success(.webViewDownload)),
            .taskPerformance(.success(.loadLocalConfig)),
            .taskPerformance(.success(.privacyFetch)),
            .taskPerformance(.failure(.configFetch)),
            .taskPerformance(.success(.initModules)),
            .taskPerformance(.success(.reset)),
            .taskPerformance(.failure(.initializer))
        ]

        sdkMetrics += sdkPerformanceMetrics
        sdkMetrics += configRequestMetrics

        let testConfig = TestConfig(responses: responses,
                                    sdkConfig: expectedConfig,
                                    expectedNumberOfRequests: responses.count,
                                    multithreadCount: 1,
                                    metrics: sdkMetrics,
                                    expectDiagnostic: true)

        try executeTest(with: testConfig,
                        resultValidation: {
            XCTAssertFailure($0, expectedError: "Could not parse configuration response")
        })
    }

    func test_init_fails_with_error_when_config_fetch_fails_server_side_with_retry() throws {
        let expectedConfig = try configMockFactory.defaultUnityAdsConfig(experiments: defaultExperiments)
        let expectedNumberOfRequests = expectedConfig.network.request.retry.maxCount + 1
        let privacyResponsesData = try configMockFactory.defaultConfigData(experiments: defaultExperiments)
        let configResponses = createSimilarRequests(numberOfRequests: expectedNumberOfRequests, status: 500)
        let responses = [
            .init(data: privacyResponsesData),
            .init(data: configMockFactory.webViewFakeData, url: expectedConfig.network.webView.url)
        ] + configResponses

        let sdkMetrics: [SDKMetricType] =  [
            .legacy(.initStarted),
            .systemPerformance(.success(.compression)),
            .systemPerformance(.success(.infoCollection)),
            .requestPerformance(.failure(.config)),
            .requestPerformance(.success(.privacy)),
            .taskPerformance(.success(.webViewDownload)),
            .taskPerformance(.success(.loadLocalConfig)),
            .taskPerformance(.success(.privacyFetch)),
            .taskPerformance(.failure(.configFetch)),
            .taskPerformance(.success(.initModules)),
            .taskPerformance(.success(.reset)),
            .taskPerformance(.failure(.initializer))
        ]

        let testConfig = TestConfig(responses: responses,
                                    sdkConfig: expectedConfig,
                                    expectedNumberOfRequests: responses.count,
                                    multithreadCount: 1,
                                    metrics: sdkMetrics,
                                    configRetried: expectedConfig.network.request.retry.maxCount,
                                    expectDiagnostic: true)

        try executeTest(with: testConfig,
                        resultValidation: { XCTAssertFailure($0) })
    }

    func test_init_fails_with_web_view_fetch_returns_invalid_file() throws {
        let returnedConfigData = try configMockFactory.defaultConfigData(experiments: defaultExperiments)
        let expectedConfig = try configMockFactory.defaultUnityAdsConfig(experiments: defaultExperiments)

        let privacyResponsesData = try configMockFactory.defaultConfigData(experiments: defaultExperiments)
        let responses: [URLProtocolResponseStub] = [
            .init(data: privacyResponsesData),
            .init(data: returnedConfigData),
            .init(data: returnedConfigData, url: expectedConfig.network.webView.url) // broken webview request
        ]

        let expectedNumberOfRequests = responses.count

        let sdkMetrics: [SDKMetricType] = [
            .legacy(.initStarted),
            .legacy(.missed(.token)),
            .legacy(.missed(.stateID)),
            .systemPerformance(.success(.compression)),
            .systemPerformance(.success(.infoCollection)),
            .requestPerformance(.success(.privacy)),
            .requestPerformance(.success(.config)),
            .taskPerformance(.success(.loadLocalConfig)),
            .taskPerformance(.success(.configFetch)),
            .taskPerformance(.success(.privacyFetch)),
            .taskPerformance(.success(.initModules)),
            .taskPerformance(.success(.reset)),
            .taskPerformance(.failure(.webViewDownload)),
            .taskPerformance(.failure(.initializer))
        ]

        let testConfig = TestConfig(responses: responses,
                                    sdkConfig: expectedConfig,
                                    expectedNumberOfRequests: expectedNumberOfRequests,
                                    multithreadCount: 1,
                                    metrics: sdkMetrics,
                                    expectDiagnostic: true)

        try executeTest(with: testConfig,
                        resultValidation: {
            XCTAssertFailure($0, expectedError: "Downloaded file is invalid. Request: https://webview.source.com")
        })
    }

    func test_init_fails_with_web_view_fetch_fails() throws {
        let returnedConfigData = try configMockFactory.defaultConfigData(experiments: defaultExperiments)
        let expectedConfig = try configMockFactory.defaultUnityAdsConfig(experiments: defaultExperiments)
        let webViewRetries = expectedConfig.network.webView.retry.maxCount
        let webViewResponseError = NSError(domain: "network", code: 500)
        let brokenRetriedRequests = createSimilarRequests(numberOfRequests: webViewRetries,
                                                          error: webViewResponseError,
                                                          url: expectedConfig.network.webView.url)
        let privacyResponsesData = try configMockFactory.defaultConfigData(experiments: defaultExperiments)
        var responses: [URLProtocolResponseStub] = [
            .init(data: privacyResponsesData),
            .init(data: returnedConfigData),
            .init(error: webViewResponseError, url: expectedConfig.network.webView.url) // broken webview request
        ]

        responses = [responses, brokenRetriedRequests].flatMap { $0 }

        let expectedNumberOfRequests = responses.count

        let sdkMetrics: [SDKMetricType] = [
            .legacy(.initStarted),
            .legacy(.missed(.token)),
            .legacy(.missed(.stateID)),
            .systemPerformance(.success(.compression)),
            .systemPerformance(.success(.infoCollection)),
            .requestPerformance(.success(.privacy)),
            .requestPerformance(.success(.config)),
            .taskPerformance(.success(.loadLocalConfig)),
            .taskPerformance(.success(.configFetch)),
            .taskPerformance(.success(.privacyFetch)),
            .taskPerformance(.success(.initModules)),
            .taskPerformance(.success(.reset)),
            .taskPerformance(.failure(.webViewDownload)),
            .taskPerformance(.failure(.initializer))
        ]

        let testConfig = TestConfig(responses: responses,
                                    sdkConfig: expectedConfig,
                                    expectedNumberOfRequests: expectedNumberOfRequests,
                                    multithreadCount: 1,
                                    metrics: sdkMetrics,
                                    webviewRetried: webViewRetries,
                                    expectDiagnostic: true)

        try executeTest(with: testConfig,
                        resultValidation: {
            XCTAssertFailure($0, expectedError:
                                "The operation couldn’t be completed. (network error 500.) Error code: 500. Request: https://webview.source.com")
        })
    }

    func test_init_fails_with_web_view_create_fails() throws {
        let returnedConfigData = try configMockFactory.defaultConfigData(experiments: defaultExperiments)
        let expectedConfig = try configMockFactory.defaultUnityAdsConfig(experiments: defaultExperiments)
        let privacyData = returnedConfigData
        let responses: [URLProtocolResponseStub] = [
            .init(data: privacyData),
            .init(data: returnedConfigData),
            .init(data: configMockFactory.webViewFakeData, url: expectedConfig.network.webView.url)
        ]

        let sdkMetrics: [SDKMetricType] = [
            .legacy(.initStarted),
            .legacy(.missed(.token)),
            .legacy(.missed(.stateID)),
            .systemPerformance(.success(.compression)),
            .systemPerformance(.success(.infoCollection)),
            .taskPerformance(.success(.loadLocalConfig)),
            .requestPerformance(.success(.privacy)),
            .requestPerformance(.success(.config)),
            .taskPerformance(.success(.configFetch)),
            .taskPerformance(.success(.privacyFetch)),
            .taskPerformance(.success(.initModules)),
            .taskPerformance(.success(.reset)),
            .taskPerformance(.success(.webViewDownload)),
            .taskPerformance(.failure(.webViewCreate)),
            .taskPerformance(.failure(.initializer))
        ]

        tester.initStateFactoryMock.webViewCreateError = MockedError()

        let testConfig = TestConfig(responses: responses,
                                    sdkConfig: expectedConfig,
                                    expectedNumberOfRequests: responses.count,
                                    multithreadCount: 1,
                                    metrics: sdkMetrics,
                                    expectDiagnostic: true)

        try  executeTest(with: testConfig,
                         resultValidation: {
            XCTAssertFailure($0, expectedError: "The operation couldn’t be completed. (UnityAdsTests.MockedError error 1.)")
        })
    }

    func test_init_succeed_no_web_view_download_when_the_same_in_cache() throws {
        let expectedNumberOfRequests = 2

        try tester.saveDefaultFakeWebViewDataToFile()

        let returnedConfigData = try configMockFactory.defaultConfigData(experiments: defaultExperiments)
        let expectedConfig = try configMockFactory.defaultUnityAdsConfig(experiments: defaultExperiments)
        let privacyData = returnedConfigData
        let responses: [URLProtocolResponseStub] = [
            .init(data: privacyData),
            .init(data: returnedConfigData),
            .init(data: configMockFactory.webViewFakeData, url: expectedConfig.network.webView.url)
        ]

        let sdkMetrics: [SDKMetricType] = [
            .legacy(.initStarted),
            .legacy(.missed(.token)),
            .legacy(.missed(.stateID)),
            .systemPerformance(.success(.compression)),
            .systemPerformance(.success(.infoCollection)),
            .requestPerformance(.success(.privacy)),
            .requestPerformance(.success(.config)),
            .taskPerformance(.success(.loadLocalConfig)),
            .taskPerformance(.success(.configFetch)),
            .taskPerformance(.success(.privacyFetch)),
            .taskPerformance(.success(.webViewDownload)),
            .taskPerformance(.success(.webViewCreate)),
            .taskPerformance(.success(.initModules)),
            .taskPerformance(.success(.reset)),
            .taskPerformance(.success(.complete)),
            .taskPerformance(.success(.initializer))
        ]

        let testConfig = TestConfig(responses: responses,
                                    sdkConfig: expectedConfig,
                                    expectedNumberOfRequests: expectedNumberOfRequests,
                                    multithreadCount: 1,
                                    metrics: sdkMetrics,
                                    expectDiagnostic: true)

        try executeTest(with: testConfig,
                        resultValidation: { XCTAssertSuccess($0) })

    }

    func test_multithread_should_not_crash_and_return_success() throws {
        let returnedConfigData = try configMockFactory.defaultConfigData(experiments: defaultExperiments)
        let expectedConfig = try configMockFactory.defaultUnityAdsConfig(experiments: defaultExperiments)
        let privacyData = returnedConfigData
        let responses: [URLProtocolResponseStub] = [
            .init(data: privacyData),
            .init(data: returnedConfigData),
            .init(data: configMockFactory.webViewFakeData, url: expectedConfig.network.webView.url)
        ]

        var sdkMetrics: [SDKMetricType] =  [
            .legacy(.initStarted),
            .legacy(.missed(.token)),
            .legacy(.missed(.stateID))
        ]

        let sdkPerformanceMetrics: [SDKMetricType] = [
            .systemPerformance(.success(.compression)),
            .systemPerformance(.success(.infoCollection)),
            .requestPerformance(.success(.privacy)),
            .requestPerformance(.success(.config)),
            .taskPerformance(.success(.loadLocalConfig)),
            .taskPerformance(.success(.privacyFetch)),
            .taskPerformance(.success(.configFetch)),
            .taskPerformance(.success(.webViewDownload)),
            .taskPerformance(.success(.webViewCreate)),
            .taskPerformance(.success(.initModules)),
            .taskPerformance(.success(.reset)),
            .taskPerformance(.success(.complete)),
            .taskPerformance(.success(.initializer))
        ]

        sdkMetrics += sdkPerformanceMetrics

        let testConfig = TestConfig(responses: responses,
                                    sdkConfig: expectedConfig,
                                    expectedNumberOfRequests: responses.count,
                                    multithreadCount: stressCount,
                                    metrics: sdkMetrics,
                                    expectDiagnostic: true)

        try executeTest(with: testConfig,
                        resultValidation: { XCTAssertSuccess($0) })

    }

    func test_state_initialized_should_return_success_without_calling_infrastructure() throws {
        tester.sdkState = .initialized
        let expectedConfig = try configMockFactory.defaultUnityAdsConfig(experiments: defaultExperiments)

        let testConfig = TestConfig(responses: [],
                                    sdkConfig: expectedConfig,
                                    expectedNumberOfRequests: 0,
                                    multithreadCount: stressCount,
                                    metrics: [],
                                    expectDiagnostic: true,
                                    validateStartTimeStamp: false)

        try executeTest(with: testConfig,
                        resultValidation: { XCTAssertSuccess($0) })

    }

    func test_state_failed_should_return_failed_without_calling_infrastructure() throws {
        tester.sdkState = .failed(MockedError())
        let expectedConfig = try configMockFactory.defaultUnityAdsConfig(experiments: defaultExperiments)
        let testConfig = TestConfig(responses: [],
                                    sdkConfig: expectedConfig,
                                    expectedNumberOfRequests: 0,
                                    multithreadCount: stressCount,
                                    metrics: [],
                                    expectDiagnostic: true,
                                    validateStartTimeStamp: false)
        try executeTest(with: testConfig,
                        resultValidation: {
            XCTAssertFailure($0, expectedError: "The operation couldn’t be completed. (UnityAdsTests.MockedError error 1.)")
        })
    }

    func test_uses_privacy_response_url_if_there_is_no_cached_config() throws {
        let expectedConfig = try configMockFactory.defaultUnityAdsConfig(experiments: defaultExperiments)
        let returnedConfigData = try configMockFactory.defaultConfigData(experiments: defaultExperiments)
        var privacyDictionary = try expectedConfig.legacy.convertIntoDictionary()
        let expectedURL = "https://webviewURLFromPrivacy"
        privacyDictionary["url"] = expectedURL
        privacyDictionary["hash"] = configMockFactory.webViewFakeDataPrivacyHash

        let privacyData = try privacyDictionary.serializedData()

        let responses: [URLProtocolResponseStub] = [
            .init(data: privacyData),
            .init(data: returnedConfigData),
            .init(data: configMockFactory.webViewFakeDataPrivacy, url: expectedURL)
        ]

        var sdkMetrics: [SDKMetricType] =  [
            .legacy(.initStarted),
            .legacy(.missed(.token)),
            .legacy(.missed(.stateID))
        ]

        let sdkPerformanceMetrics: [SDKMetricType] = [
            .systemPerformance(.success(.compression)),
            .systemPerformance(.success(.infoCollection)),
            .requestPerformance(.success(.privacy)),
            .requestPerformance(.success(.config)),
            .taskPerformance(.success(.loadLocalConfig)),
            .taskPerformance(.success(.privacyFetch)),
            .taskPerformance(.success(.configFetch)),
            .taskPerformance(.success(.webViewDownload)),
            .taskPerformance(.success(.webViewCreate)),
            .taskPerformance(.success(.initModules)),
            .taskPerformance(.success(.reset)),
            .taskPerformance(.success(.complete)),
            .taskPerformance(.success(.initializer))
        ]

        sdkMetrics += sdkPerformanceMetrics
        let testConfig = TestConfig(responses: responses,
                                    sdkConfig: expectedConfig,
                                    expectedNumberOfRequests: responses.count,
                                    multithreadCount: 1,
                                    metrics: sdkMetrics,
                                    expectDiagnostic: true)
        try executeTest(with: testConfig,
                        resultValidation: { XCTAssertSuccess($0) },
                        final: {
            let requestURL = self.tester.networkRequests.compactMap({ $0.url?.absoluteString })
                                                        .first(where: { $0 == expectedURL })

            XCTAssertNotNil(requestURL)
            XCTAssertEqual(self.tester.sdkState, .initialized)
        })
    }

    func test_init_fails_with_error_when_config_and_privacy_have_empty_webview_url() throws {
        var expectedConfigDict = configMockFactory.defaultConfigJSON(experiments: defaultExperiments)
        expectedConfigDict["url"] = "not_valid"
        let expectedConfigData = try expectedConfigDict.serializedData()
        let expectedConfig = UnityAdsConfig(from: try LegacySDKConfig(dictionary: expectedConfigDict))
        tester.updateInMemorySwiftConfig(expectedConfig)
        let responses: [URLProtocolResponseStub] = [.init(data: expectedConfigData), .init(data: expectedConfigData)]
        var sdkMetrics: [SDKMetricType] =  [ .legacy(.initStarted) ]

        let configRequestMetrics: [SDKMetricType] = [
            .systemPerformance(.success(.compression)),
            .systemPerformance(.success(.infoCollection)),
            .requestPerformance(.success(.config)),
            .legacy(.missed(.token)),
            .legacy(.missed(.stateID))
        ]

        let sdkPerformanceMetrics: [SDKMetricType] = [
            .requestPerformance(.success(.privacy)),
            .taskPerformance(.success(.loadLocalConfig)),
            .taskPerformance(.success(.configFetch)),
            .taskPerformance(.success(.privacyFetch)),
            .taskPerformance(.failure(.webViewDownload)),
            .taskPerformance(.success(.initModules)),
            .taskPerformance(.success(.reset)),
            .taskPerformance(.failure(.initializer))
        ]

        sdkMetrics += sdkPerformanceMetrics
        sdkMetrics += configRequestMetrics

        let testConfig = TestConfig(responses: responses,
                                    sdkConfig: expectedConfig,
                                    expectedNumberOfRequests: responses.count,
                                    multithreadCount: 1,
                                    metrics: sdkMetrics,
                                    expectDiagnostic: true)

        try executeTest(with: testConfig,
                        resultValidation: { XCTAssertFailure($0) })

    }

    func test_init_fails_with_error_when_privacy_fails_and_config_has_empty_webview_url() throws {
        var expectedConfigDict = configMockFactory.defaultConfigJSON(experiments: defaultExperiments)
        expectedConfigDict["url"] = "not_valid"
        let expectedConfigData = try expectedConfigDict.serializedData()
        let expectedConfig = UnityAdsConfig(from: try LegacySDKConfig(dictionary: expectedConfigDict))
        tester.updateInMemorySwiftConfig(expectedConfig)
        let privacyResponseError = NSError(domain: "network", code: 500)
        let responses: [URLProtocolResponseStub] = [.init(error: privacyResponseError), .init(data: expectedConfigData)]
        var sdkMetrics: [SDKMetricType] =  [ .legacy(.initStarted) ]

        let configRequestMetrics: [SDKMetricType] = [
            .systemPerformance(.success(.compression)),
            .systemPerformance(.success(.infoCollection)),
            .requestPerformance(.success(.config)),
            .legacy(.missed(.token)),
            .legacy(.missed(.stateID))
        ]

        let sdkPerformanceMetrics: [SDKMetricType] = [
            .requestPerformance(.failure(.privacy)),
            .taskPerformance(.success(.loadLocalConfig)),
            .taskPerformance(.success(.privacyFetch)),
            .taskPerformance(.success(.configFetch)),
            .taskPerformance(.failure(.webViewDownload)),
            .taskPerformance(.success(.initModules)),
            .taskPerformance(.success(.reset)),
            .taskPerformance(.failure(.initializer))
        ]

        sdkMetrics += sdkPerformanceMetrics
        sdkMetrics += configRequestMetrics

        let testConfig = TestConfig(responses: responses,
                                    sdkConfig: expectedConfig,
                                    expectedNumberOfRequests: responses.count,
                                    multithreadCount: 1,
                                    metrics: sdkMetrics,
                                    expectDiagnostic: true)

        try executeTest(with: testConfig,
                        resultValidation: { XCTAssertFailure($0) })
    }

    func test_init_finishes_with_success_when_config_has_webview_url_and_privacy_not() throws {
        let returnedConfigData = try configMockFactory.defaultConfigData(experiments: defaultExperiments)
        let expectedConfig = try configMockFactory.defaultUnityAdsConfig(experiments: defaultExperiments)
        try saveConfigToFile(expectedConfig)
        resetTester()
        var expectedPrivacyDict = configMockFactory.defaultConfigJSON(experiments: defaultExperiments)
        expectedPrivacyDict["url"] = ""
        let expectedPrivacyData = try expectedPrivacyDict.serializedData()
        let responses: [URLProtocolResponseStub] = [
            .init(data: expectedPrivacyData),
            .init(data: returnedConfigData),
            .init(data: configMockFactory.webViewFakeData, url: expectedConfig.network.webView.url)]

        var sdkMetrics: [SDKMetricType] =  [
            .legacy(.initStarted),
            .legacy(.missed(.token)),
            .legacy(.missed(.stateID))
        ]

        let sdkPerformanceMetrics: [SDKMetricType] = [
            .systemPerformance(.success(.compression)),
            .systemPerformance(.success(.infoCollection)),
            .requestPerformance(.success(.privacy)),
            .requestPerformance(.success(.config)),
            .taskPerformance(.success(.loadLocalConfig)),
            .taskPerformance(.success(.privacyFetch)),
            .taskPerformance(.success(.configFetch)),
            .taskPerformance(.success(.webViewDownload)),
            .taskPerformance(.success(.webViewCreate)),
            .taskPerformance(.success(.initModules)),
            .taskPerformance(.success(.reset)),
            .taskPerformance(.success(.complete)),
            .taskPerformance(.success(.initializer))
        ]

        sdkMetrics += sdkPerformanceMetrics
        let testConfig = TestConfig(responses: responses,
                                    sdkConfig: expectedConfig,
                                    expectedNumberOfRequests: responses.count,
                                    multithreadCount: 1,
                                    metrics: sdkMetrics,
                                    expectDiagnostic: true)
        try executeTest(with: testConfig,
                        resultValidation: { XCTAssertSuccess($0) },
                        final: {

            XCTAssertEqual(self.tester.sdkState, .initialized)
        })

    }

}
