import Foundation
import Combine

protocol CurrencyServiceProtocol {
    func getExchangeRates(base: String) -> AnyPublisher<ExchangeRateResponse, CurrencyError>
    func convertCurrency(from: Currency, to: Currency, amount: Double) -> AnyPublisher<ConversionResult, CurrencyError>
    func getSupportedCurrencies() -> [Currency]
}

class CurrencyService: CurrencyServiceProtocol {
    private let apiKey = "cd648d156cf07c5e0e55d275da65fc70"
    private let baseURL = "https://api.fixer.io/v1"
    private let session = URLSession.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Cache for exchange rates
    private var rateCache: [String: ExchangeRateResponse] = [:]
    private var cacheTimestamp: [String: Date] = [:]
    private let cacheValidityDuration: TimeInterval = 300 // 5 minutes
    
    func getExchangeRates(base: String) -> AnyPublisher<ExchangeRateResponse, CurrencyError> {
        // Check cache first
        if let cachedResponse = getCachedRates(for: base) {
            return Just(cachedResponse)
                .setFailureType(to: CurrencyError.self)
                .eraseToAnyPublisher()
        }
        
        guard let url = buildURL(endpoint: "latest", base: base) else {
            return Fail(error: CurrencyError.networkError("Invalid URL"))
                .eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: ExchangeRateResponse.self, decoder: JSONDecoder())
            .mapError { error in
                if error is DecodingError {
                    return CurrencyError.apiError("Failed to parse response")
                } else {
                    return CurrencyError.networkError(error.localizedDescription)
                }
            }
            .handleEvents(receiveOutput: { [weak self] response in
                self?.cacheRates(response, for: base)
            })
            .eraseToAnyPublisher()
    }
    
    func convertCurrency(from: Currency, to: Currency, amount: Double) -> AnyPublisher<ConversionResult, CurrencyError> {
        guard amount > 0 else {
            return Fail(error: CurrencyError.invalidAmount)
                .eraseToAnyPublisher()
        }
        
        return getExchangeRates(base: from.code)
            .tryMap { response in
                guard response.success else {
                    throw CurrencyError.apiError("API request failed")
                }
                
                guard let rate = response.rates[to.code] else {
                    throw CurrencyError.rateNotFound
                }
                
                let convertedAmount = amount * rate
                
                return ConversionResult(
                    fromCurrency: from,
                    toCurrency: to,
                    fromAmount: amount,
                    toAmount: convertedAmount,
                    rate: rate,
                    timestamp: Date()
                )
            }
            .mapError { error in
                if let currencyError = error as? CurrencyError {
                    return currencyError
                } else {
                    return CurrencyError.networkError(error.localizedDescription)
                }
            }
            .eraseToAnyPublisher()
    }
    
    func getSupportedCurrencies() -> [Currency] {
        return CurrencyData.allCurrencies
    }
    
    // MARK: - Private Methods
    
    private func buildURL(endpoint: String, base: String) -> URL? {
        guard var components = URLComponents(string: "\(baseURL)/\(endpoint)") else {
            return nil
        }
        
        components.queryItems = [
            URLQueryItem(name: "access_key", value: apiKey),
            URLQueryItem(name: "base", value: base)
        ]
        
        return components.url
    }
    
    private func getCachedRates(for base: String) -> ExchangeRateResponse? {
        guard let cachedResponse = rateCache[base],
              let timestamp = cacheTimestamp[base],
              Date().timeIntervalSince(timestamp) < cacheValidityDuration else {
            return nil
        }
        
        return cachedResponse
    }
    
    private func cacheRates(_ response: ExchangeRateResponse, for base: String) {
        rateCache[base] = response
        cacheTimestamp[base] = Date()
    }
    
    // MARK: - Utility Methods
    
    func clearCache() {
        rateCache.removeAll()
        cacheTimestamp.removeAll()
    }
    
    func getCachedRatesInfo() -> [(base: String, timestamp: Date)] {
        return cacheTimestamp.map { (base: $0.key, timestamp: $0.value) }
    }
}

// MARK: - Mock Service for Testing

class MockCurrencyService: CurrencyServiceProtocol {
    var shouldReturnError = false
    var mockExchangeRates: [String: Double] = [
        "USD": 1.1234,
        "PLN": 4.5678,
        "GBP": 0.8765,
        "JPY": 130.45
    ]
    
    func getExchangeRates(base: String) -> AnyPublisher<ExchangeRateResponse, CurrencyError> {
        if shouldReturnError {
            return Fail(error: CurrencyError.networkError("Mock error"))
                .eraseToAnyPublisher()
        }
        
        let response = ExchangeRateResponse(
            success: true,
            timestamp: Int(Date().timeIntervalSince1970),
            base: base,
            date: DateFormatter.apiDateFormatter.string(from: Date()),
            rates: mockExchangeRates
        )
        
        return Just(response)
            .setFailureType(to: CurrencyError.self)
            .eraseToAnyPublisher()
    }
    
    func convertCurrency(from: Currency, to: Currency, amount: Double) -> AnyPublisher<ConversionResult, CurrencyError> {
        if shouldReturnError {
            return Fail(error: CurrencyError.networkError("Mock error"))
                .eraseToAnyPublisher()
        }
        
        let rate = mockExchangeRates[to.code] ?? 1.0
        let convertedAmount = amount * rate
        
        let result = ConversionResult(
            fromCurrency: from,
            toCurrency: to,
            fromAmount: amount,
            toAmount: convertedAmount,
            rate: rate,
            timestamp: Date()
        )
        
        return Just(result)
            .setFailureType(to: CurrencyError.self)
            .eraseToAnyPublisher()
    }
    
    func getSupportedCurrencies() -> [Currency] {
        return CurrencyData.allCurrencies
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let apiDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}