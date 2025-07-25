import Foundation

struct Currency: Codable, Equatable, Hashable {
    let code: String
    let name: String
    let flag: String
    
    init(code: String, name: String, flag: String) {
        self.code = code
        self.name = name
        self.flag = flag
    }
}

struct ExchangeRateResponse: Codable {
    let success: Bool
    let timestamp: Int?
    let base: String?
    let date: String?
    let rates: [String: Double]?
    let error: APIError?
    
    enum CodingKeys: String, CodingKey {
        case success, timestamp, base, date, rates, error
    }
}

struct APIError: Codable {
    let code: Int
    let type: String
    let info: String?
}

struct ConversionResult {
    let fromCurrency: Currency
    let toCurrency: Currency
    let fromAmount: Double
    let toAmount: Double
    let rate: Double
    let timestamp: Date
}

struct ConversionHistory: Codable {
    let id: UUID
    let fromCurrencyCode: String
    let toCurrencyCode: String
    let fromAmount: Double
    let toAmount: Double
    let rate: Double
    let timestamp: Date
    
    init(fromCurrencyCode: String, toCurrencyCode: String, fromAmount: Double, toAmount: Double, rate: Double) {
        self.id = UUID()
        self.fromCurrencyCode = fromCurrencyCode
        self.toCurrencyCode = toCurrencyCode
        self.fromAmount = fromAmount
        self.toAmount = toAmount
        self.rate = rate
        self.timestamp = Date()
    }
}

struct UserPreferences: Codable {
    var defaultFromCurrency: String
    var defaultToCurrency: String
    var decimalPlaces: Int
    var autoRefreshInterval: TimeInterval
    
    static let `default` = UserPreferences(
        defaultFromCurrency: "EUR",
        defaultToCurrency: "PLN",
        decimalPlaces: 2,
        autoRefreshInterval: 300 // 5 minutes
    )
}

enum CurrencyError: Error, LocalizedError {
    case invalidCurrencyCode
    case networkError(String)
    case apiError(String)
    case invalidAmount
    case noDataAvailable
    case rateNotFound
    
    var errorDescription: String? {
        switch self {
        case .invalidCurrencyCode:
            return "Invalid currency code provided"
        case .networkError(let message):
            return "Network error: \(message)"
        case .apiError(let message):
            return "API error: \(message)"
        case .invalidAmount:
            return "Invalid amount entered"
        case .noDataAvailable:
            return "No exchange rate data available"
        case .rateNotFound:
            return "Exchange rate not found for the selected currencies"
        }
    }
}