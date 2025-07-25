import Foundation
import Combine

@MainActor
class CurrencyConverterViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var fromCurrency: Currency
    @Published var toCurrency: Currency
    @Published var convertedAmount: Double?
    @Published var exchangeRate: Double?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastUpdated: Date?
    
    // MARK: - Properties
    let currencyService: CurrencyServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private var conversionHistory: [ConversionHistory] = []
    private var debounceTimer: Timer?
    
    // MARK: - Initialization
    init(currencyService: CurrencyServiceProtocol) {
        self.currencyService = currencyService
        
        // Set default currencies
        self.fromCurrency = CurrencyData.currency(for: "EUR") ?? Currency(code: "EUR", name: "Euro", flag: "🇪🇺")
        self.toCurrency = CurrencyData.currency(for: "PLN") ?? Currency(code: "PLN", name: "Polish Zloty", flag: "🇵🇱")
        
        setupBindings()
        loadUserPreferences()
    }
    
    // MARK: - Public Methods
    func convert(amount: Double) {
        // Debounce rapid conversions
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
            Task { @MainActor in
                await self?.performConversion(amount: amount)
            }
        }
    }
    
    func setFromCurrency(_ currency: Currency) {
        fromCurrency = currency
        saveUserPreferences()
        
        // Auto-convert if we have a previous amount
        if let lastAmount = convertedAmount, lastAmount > 0 {
            convert(amount: 1.0) // Use 1.0 as default for rate display
        }
    }
    
    func setToCurrency(_ currency: Currency) {
        toCurrency = currency
        saveUserPreferences()
        
        // Auto-convert if we have a previous amount
        if let lastAmount = convertedAmount, lastAmount > 0 {
            convert(amount: 1.0) // Use 1.0 as default for rate display
        }
    }
    
    func swapCurrencies() {
        let temp = fromCurrency
        fromCurrency = toCurrency
        toCurrency = temp
        
        saveUserPreferences()
        
        // Auto-convert after swap
        convert(amount: 1.0)
    }
    
    func refreshRates() {
        convert(amount: 1.0)
    }
    
    func getConversionHistory() -> [ConversionHistory] {
        return conversionHistory.sorted { $0.timestamp > $1.timestamp }
    }
    
    func clearHistory() {
        conversionHistory.removeAll()
        saveConversionHistory()
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        // Auto-convert when currencies change
        Publishers.CombineLatest($fromCurrency, $toCurrency)
            .dropFirst() // Skip initial values
            .sink { [weak self] _, _ in
                self?.convert(amount: 1.0)
            }
            .store(in: &cancellables)
    }
    
    private func performConversion(amount: Double) async {
        guard amount > 0 else {
            convertedAmount = 0
            exchangeRate = nil
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await currencyService.convertCurrency(
                from: fromCurrency,
                to: toCurrency,
                amount: amount
            ).async()
            
            convertedAmount = result.toAmount
            exchangeRate = result.rate
            lastUpdated = result.timestamp
            
            // Save to history if it's a significant conversion (not just rate checking)
            if amount >= 0.01 {
                addToHistory(result)
            }
            
        } catch let error as CurrencyError {
            errorMessage = error.localizedDescription
            convertedAmount = nil
            exchangeRate = nil
        } catch {
            errorMessage = "An unexpected error occurred"
            convertedAmount = nil
            exchangeRate = nil
        }
        
        isLoading = false
    }
    
    private func addToHistory(_ result: ConversionResult) {
        let historyItem = ConversionHistory(
            fromCurrencyCode: result.fromCurrency.code,
            toCurrencyCode: result.toCurrency.code,
            fromAmount: result.fromAmount,
            toAmount: result.toAmount,
            rate: result.rate
        )
        
        conversionHistory.append(historyItem)
        
        // Keep only last 50 conversions
        if conversionHistory.count > 50 {
            conversionHistory.removeFirst(conversionHistory.count - 50)
        }
        
        saveConversionHistory()
    }
    
    // MARK: - Persistence
    private func loadUserPreferences() {
        // Clear old preferences and always start with EUR base for Fixer.io free plan compatibility
        UserDefaults.standard.removeObject(forKey: "UserPreferences")
        
        // Always use EUR as base currency for Fixer.io free plan
        self.fromCurrency = CurrencyData.currency(for: "EUR") ?? Currency(code: "EUR", name: "Euro", flag: "🇪🇺")
        self.toCurrency = CurrencyData.currency(for: "PLN") ?? Currency(code: "PLN", name: "Polish Zloty", flag: "🇵🇱")
        
        loadConversionHistory()
    }
    
    private func saveUserPreferences() {
        let preferences = UserPreferences(
            defaultFromCurrency: fromCurrency.code,
            defaultToCurrency: toCurrency.code,
            decimalPlaces: 2,
            autoRefreshInterval: 300
        )
        
        if let data = try? JSONEncoder().encode(preferences) {
            UserDefaults.standard.set(data, forKey: "UserPreferences")
        }
    }
    
    private func loadConversionHistory() {
        if let data = UserDefaults.standard.data(forKey: "ConversionHistory"),
           let history = try? JSONDecoder().decode([ConversionHistory].self, from: data) {
            conversionHistory = history
        }
    }
    
    private func saveConversionHistory() {
        if let data = try? JSONEncoder().encode(conversionHistory) {
            UserDefaults.standard.set(data, forKey: "ConversionHistory")
        }
    }
    
    // MARK: - Validation
    func validateAmount(_ amount: String) -> ValidationResult {
        guard !amount.isEmpty else {
            return .invalid("Amount cannot be empty")
        }
        
        guard let doubleAmount = Double(amount) else {
            return .invalid("Please enter a valid number")
        }
        
        guard doubleAmount > 0 else {
            return .invalid("Amount must be greater than zero")
        }
        
        guard doubleAmount <= 1_000_000_000 else {
            return .invalid("Amount is too large")
        }
        
        return .valid
    }
    
    func formatAmount(_ amount: Double, for currency: Currency) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency.code
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: NSNumber(value: amount)) ?? String(format: "%.2f", amount)
    }
    
    func formatRate(_ rate: Double) -> String {
        if rate >= 1000 {
            return String(format: "%.2f", rate)
        } else if rate >= 100 {
            return String(format: "%.3f", rate)
        } else if rate >= 10 {
            return String(format: "%.4f", rate)
        } else {
            return String(format: "%.6f", rate)
        }
    }
}

// MARK: - Supporting Types

enum ValidationResult {
    case valid
    case invalid(String)
    
    var isValid: Bool {
        if case .valid = self {
            return true
        }
        return false
    }
    
    var errorMessage: String? {
        if case .invalid(let message) = self {
            return message
        }
        return nil
    }
}

// MARK: - Combine Extensions

extension Publisher {
    func async() async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            
            cancellable = self
                .first()
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            break
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                        cancellable?.cancel()
                    },
                    receiveValue: { value in
                        continuation.resume(returning: value)
                        cancellable?.cancel()
                    }
                )
        }
    }
}

// MARK: - Mock ViewModel for Testing

class MockCurrencyConverterViewModel: CurrencyConverterViewModel {
    var shouldSimulateError = false
    var simulatedDelay: TimeInterval = 0.0
    
    override init(currencyService: CurrencyServiceProtocol) {
        super.init(currencyService: currencyService)
    }
    
    override func convert(amount: Double) {
        if shouldSimulateError {
            Task { @MainActor in
                self.isLoading = true
                try? await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
                self.errorMessage = "Mock error for testing"
                self.isLoading = false
            }
            return
        }
        
        // Simulate conversion with mock data
        Task { @MainActor in
            self.isLoading = true
            try? await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
            
            let mockRate = 4.32 // EUR to PLN mock rate
            self.convertedAmount = amount * mockRate
            self.exchangeRate = mockRate
            self.lastUpdated = Date()
            self.isLoading = false
        }
    }
}