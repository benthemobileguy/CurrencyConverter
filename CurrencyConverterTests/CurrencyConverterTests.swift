import XCTest
import Combine
@testable import CurrencyConverter

final class CurrencyConverterTests: XCTestCase {
    
    var viewModel: CurrencyConverterViewModel!
    var mockService: MockCurrencyService!
    var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        mockService = MockCurrencyService()
        viewModel = CurrencyConverterViewModel(currencyService: mockService)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDownWithError() throws {
        viewModel = nil
        mockService = nil
        cancellables = nil
    }
    
    // MARK: - ViewModel Tests
    
    func testDefaultCurrencies() {
        XCTAssertEqual(viewModel.fromCurrency.code, "EUR")
        XCTAssertEqual(viewModel.toCurrency.code, "PLN")
    }
    
    func testSwapCurrencies() {
        let originalFromCurrency = viewModel.fromCurrency
        let originalToCurrency = viewModel.toCurrency
        
        viewModel.swapCurrencies()
        
        XCTAssertEqual(viewModel.fromCurrency.code, originalToCurrency.code)
        XCTAssertEqual(viewModel.toCurrency.code, originalFromCurrency.code)
    }
    
    func testSetFromCurrency() {
        let newCurrency = Currency(code: "USD", name: "US Dollar", flag: "🇺🇸")
        viewModel.setFromCurrency(newCurrency)
        
        XCTAssertEqual(viewModel.fromCurrency.code, "USD")
    }
    
    func testSetToCurrency() {
        let newCurrency = Currency(code: "GBP", name: "British Pound", flag: "🇬🇧")
        viewModel.setToCurrency(newCurrency)
        
        XCTAssertEqual(viewModel.toCurrency.code, "GBP")
    }
    
    func testConversionSuccess() async {
        let expectation = XCTestExpectation(description: "Conversion completed")
        
        viewModel.$convertedAmount
            .dropFirst()
            .sink { amount in
                if amount != nil {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        await viewModel.convert(amount: 100.0)
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        XCTAssertNotNil(viewModel.convertedAmount)
        XCTAssertNotNil(viewModel.exchangeRate)
        XCTAssertEqual(viewModel.convertedAmount, 456.78, accuracy: 0.01)
    }
    
    func testConversionError() async {
        mockService.shouldReturnError = true
        
        let expectation = XCTestExpectation(description: "Error received")
        
        viewModel.$errorMessage
            .dropFirst()
            .sink { errorMessage in
                if errorMessage != nil {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        await viewModel.convert(amount: 100.0)
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertNil(viewModel.convertedAmount)
    }
    
    func testLoadingState() async {
        let expectation = XCTestExpectation(description: "Loading state changed")
        
        var loadingStates: [Bool] = []
        
        viewModel.$isLoading
            .sink { isLoading in
                loadingStates.append(isLoading)
                if loadingStates.count >= 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        await viewModel.convert(amount: 100.0)
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        XCTAssertTrue(loadingStates.contains(true))
        XCTAssertTrue(loadingStates.contains(false))
    }
    
    func testAmountValidation() {
        XCTAssertTrue(viewModel.validateAmount("100.50").isValid)
        XCTAssertTrue(viewModel.validateAmount("0.01").isValid)
        XCTAssertTrue(viewModel.validateAmount("1000000").isValid)
        
        XCTAssertFalse(viewModel.validateAmount("").isValid)
        XCTAssertFalse(viewModel.validateAmount("0").isValid)
        XCTAssertFalse(viewModel.validateAmount("-10").isValid)
        XCTAssertFalse(viewModel.validateAmount("abc").isValid)
        XCTAssertFalse(viewModel.validateAmount("1000000001").isValid)
    }
    
    func testFormatAmount() {
        let usdCurrency = Currency(code: "USD", name: "US Dollar", flag: "🇺🇸")
        let formatted = viewModel.formatAmount(1234.56, for: usdCurrency)
        
        XCTAssertTrue(formatted.contains("1234.56") || formatted.contains("1,234.56"))
    }
    
    func testFormatRate() {
        XCTAssertEqual(viewModel.formatRate(1234.56), "1234.56")
        XCTAssertEqual(viewModel.formatRate(123.456), "123.456")
        XCTAssertEqual(viewModel.formatRate(12.3456), "12.3456")
        XCTAssertEqual(viewModel.formatRate(1.234567), "1.234567")
    }
    
    // MARK: - Model Tests
    
    func testCurrencyEquality() {
        let currency1 = Currency(code: "USD", name: "US Dollar", flag: "🇺🇸")
        let currency2 = Currency(code: "USD", name: "US Dollar", flag: "🇺🇸")
        let currency3 = Currency(code: "EUR", name: "Euro", flag: "🇪🇺")
        
        XCTAssertEqual(currency1, currency2)
        XCTAssertNotEqual(currency1, currency3)
    }
    
    func testConversionHistoryCreation() {
        let history = ConversionHistory(
            fromCurrencyCode: "EUR",
            toCurrencyCode: "USD",
            fromAmount: 100.0,
            toAmount: 112.34,
            rate: 1.1234
        )
        
        XCTAssertEqual(history.fromCurrencyCode, "EUR")
        XCTAssertEqual(history.toCurrencyCode, "USD")
        XCTAssertEqual(history.fromAmount, 100.0)
        XCTAssertEqual(history.toAmount, 112.34)
        XCTAssertEqual(history.rate, 1.1234)
        XCTAssertNotNil(history.id)
        XCTAssertNotNil(history.timestamp)
    }
    
    func testUserPreferences() {
        let preferences = UserPreferences.default
        
        XCTAssertEqual(preferences.defaultFromCurrency, "EUR")
        XCTAssertEqual(preferences.defaultToCurrency, "PLN")
        XCTAssertEqual(preferences.decimalPlaces, 2)
        XCTAssertEqual(preferences.autoRefreshInterval, 300)
    }
    
    // MARK: - Service Tests
    
    func testCurrencyServiceGetSupportedCurrencies() {
        let currencies = mockService.getSupportedCurrencies()
        
        XCTAssertFalse(currencies.isEmpty)
        XCTAssertTrue(currencies.contains { $0.code == "USD" })
        XCTAssertTrue(currencies.contains { $0.code == "EUR" })
        XCTAssertTrue(currencies.contains { $0.code == "GBP" })
    }
    
    func testMockServiceConversion() async {
        let fromCurrency = Currency(code: "EUR", name: "Euro", flag: "🇪🇺")
        let toCurrency = Currency(code: "USD", name: "US Dollar", flag: "🇺🇸")
        
        do {
            let result = try await mockService.convertCurrency(
                from: fromCurrency,
                to: toCurrency,
                amount: 100.0
            ).async()
            
            XCTAssertEqual(result.fromCurrency.code, "EUR")
            XCTAssertEqual(result.toCurrency.code, "USD")
            XCTAssertEqual(result.fromAmount, 100.0)
            XCTAssertGreaterThan(result.toAmount, 0)
            XCTAssertGreaterThan(result.rate, 0)
        } catch {
            XCTFail("Conversion should succeed: \(error)")
        }
    }
    
    func testMockServiceError() async {
        mockService.shouldReturnError = true
        
        let fromCurrency = Currency(code: "EUR", name: "Euro", flag: "🇪🇺")
        let toCurrency = Currency(code: "USD", name: "US Dollar", flag: "🇺🇸")
        
        do {
            _ = try await mockService.convertCurrency(
                from: fromCurrency,
                to: toCurrency,
                amount: 100.0
            ).async()
            
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error is CurrencyError)
        }
    }
    
    // MARK: - Data Tests
    
    func testCurrencyDataAllCurrencies() {
        let currencies = CurrencyData.allCurrencies
        
        XCTAssertFalse(currencies.isEmpty)
        XCTAssertGreaterThanOrEqual(currencies.count, 50)
        
        // Test major currencies are present
        XCTAssertTrue(currencies.contains { $0.code == "USD" })
        XCTAssertTrue(currencies.contains { $0.code == "EUR" })
        XCTAssertTrue(currencies.contains { $0.code == "GBP" })
        XCTAssertTrue(currencies.contains { $0.code == "JPY" })
        XCTAssertTrue(currencies.contains { $0.code == "PLN" })
    }
    
    func testCurrencyDataSearch() {
        let searchResults = CurrencyData.searchCurrencies(query: "dollar")
        
        XCTAssertFalse(searchResults.isEmpty)
        XCTAssertTrue(searchResults.contains { $0.code == "USD" })
        XCTAssertTrue(searchResults.contains { $0.name.lowercased().contains("dollar") })
    }
    
    func testCurrencyDataPopular() {
        let popularCurrencies = CurrencyData.popularCurrencies()
        
        XCTAssertFalse(popularCurrencies.isEmpty)
        XCTAssertTrue(popularCurrencies.contains { $0.code == "USD" })
        XCTAssertTrue(popularCurrencies.contains { $0.code == "EUR" })
        XCTAssertTrue(popularCurrencies.contains { $0.code == "GBP" })
    }
    
    func testCurrencyDataFindByCode() {
        let currency = CurrencyData.currency(for: "USD")
        
        XCTAssertNotNil(currency)
        XCTAssertEqual(currency?.code, "USD")
        XCTAssertEqual(currency?.name, "United States Dollar")
        XCTAssertEqual(currency?.flag, "🇺🇸")
        
        let invalidCurrency = CurrencyData.currency(for: "INVALID")
        XCTAssertNil(invalidCurrency)
    }
    
    // MARK: - Integration Tests
    
    func testFullConversionFlow() async {
        // Set up currencies
        let fromCurrency = Currency(code: "EUR", name: "Euro", flag: "🇪🇺")
        let toCurrency = Currency(code: "USD", name: "US Dollar", flag: "🇺🇸")
        
        viewModel.setFromCurrency(fromCurrency)
        viewModel.setToCurrency(toCurrency)
        
        XCTAssertEqual(viewModel.fromCurrency.code, "EUR")
        XCTAssertEqual(viewModel.toCurrency.code, "USD")
        
        // Perform conversion
        let expectation = XCTestExpectation(description: "Full conversion flow")
        
        viewModel.$convertedAmount
            .dropFirst()
            .sink { amount in
                if amount != nil {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        await viewModel.convert(amount: 250.0)
        
        await fulfillment(of: [expectation], timeout: 3.0)
        
        XCTAssertNotNil(viewModel.convertedAmount)
        XCTAssertNotNil(viewModel.exchangeRate)
        XCTAssertNotNil(viewModel.lastUpdated)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
}