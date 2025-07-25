import Foundation
import Combine

protocol CurrencyServiceProtocol {
    func getExchangeRates(base: String) -> AnyPublisher<ExchangeRateResponse, CurrencyError>
    func convertCurrency(from: Currency, to: Currency, amount: Double) -> AnyPublisher<ConversionResult, CurrencyError>
    func getSupportedCurrencies() -> [Currency]
}

class CurrencyService: CurrencyServiceProtocol {
    private let apiKey = "cd648d156cf07c5e0e55d275da65fc70"
    private let baseURL = "https://data.fixer.io/api"
    private let session = URLSession.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Cache for exchange rates
    private var rateCache: [String: ExchangeRateResponse] = [:]
    private var cacheTimestamp: [String: Date] = [:]
    private let cacheValidityDuration: TimeInterval = 300 // 5 minutes
    
    func getExchangeRates(base: String) -> AnyPublisher<ExchangeRateResponse, CurrencyError> {
        // Fixer.io free plan only supports EUR as base currency
        let actualBase = "EUR"
        
        // Check cache first
        if let cachedResponse = getCachedRates(for: actualBase) {
            return Just(cachedResponse)
                .setFailureType(to: CurrencyError.self)
                .eraseToAnyPublisher()
        }
        
        guard let url = buildURL(endpoint: "latest", base: actualBase) else {
            return Fail(error: CurrencyError.networkError("Invalid URL"))
                .eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: ExchangeRateResponse.self, decoder: JSONDecoder())
            .tryMap { response in
                if !response.success {
                    let errorMessage = response.error?.type ?? "Unknown API error"
                    throw CurrencyError.apiError("API Error: \(errorMessage)")
                }
                
                guard let rates = response.rates else {
                    throw CurrencyError.apiError("No exchange rates in response")
                }
                
                return ExchangeRateResponse(
                    success: true,
                    timestamp: response.timestamp,
                    base: response.base,
                    date: response.date,
                    rates: rates,
                    error: nil
                )
            }
            .mapError { error in
                if let currencyError = error as? CurrencyError {
                    return currencyError
                } else if let decodingError = error as? DecodingError {
                    return CurrencyError.apiError("Failed to parse response: \(decodingError.localizedDescription)")
                } else {
                    return CurrencyError.networkError(error.localizedDescription)
                }
            }
            .handleEvents(receiveOutput: { [weak self] response in
                self?.cacheRates(response, for: actualBase)
            })
            .eraseToAnyPublisher()
    }
    
    func convertCurrency(from: Currency, to: Currency, amount: Double) -> AnyPublisher<ConversionResult, CurrencyError> {
        guard amount > 0 else {
            return Fail(error: CurrencyError.invalidAmount)
                .eraseToAnyPublisher()
        }
        
        return getExchangeRates(base: "EUR")
            .tryMap { response in
                guard response.success else {
                    throw CurrencyError.apiError("API request failed")
                }
                
                guard let rates = response.rates else {
                    throw CurrencyError.apiError("No rates available")
                }
                
                // Handle EUR as from/to currency specially
                let fromRate = from.code == "EUR" ? 1.0 : rates[from.code]
                let toRate = to.code == "EUR" ? 1.0 : rates[to.code]
                
                guard let fromEurRate = fromRate, let toEurRate = toRate else {
                    throw CurrencyError.rateNotFound
                }
                
                // Convert: amount in fromCurrency -> EUR -> toCurrency
                let amountInEur = amount / fromEurRate
                let convertedAmount = amountInEur * toEurRate
                let directRate = toEurRate / fromEurRate
                
                return ConversionResult(
                    fromCurrency: from,
                    toCurrency: to,
                    fromAmount: amount,
                    toAmount: convertedAmount,
                    rate: directRate,
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
            rates: mockExchangeRates,
            error: nil
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