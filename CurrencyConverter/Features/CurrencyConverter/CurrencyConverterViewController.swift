import UIKit
import Combine

class CurrencyConverterViewController: UIViewController {
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let currencyCard = UIView()
    private let amountTextField = UITextField()
    private let fromCurrencyButton = UIButton(type: .system)
    private let toCurrencyButton = UIButton(type: .system)
    private let swapButton = UIButton(type: .system)
    private let convertButton = UIButton(type: .system)
    private let resultLabel = UILabel()
    private let exchangeRateLabel = UILabel()
    private let lastUpdatedLabel = UILabel()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    
    // MARK: - Properties
    private var viewModel: CurrencyConverterViewModel!
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewModel()
        setupUI()
        setupConstraints()
        setupBindings()
        setupActions()
    }
    
    // MARK: - Setup Methods
    private func setupViewModel() {
        let currencyService = CurrencyService()
        viewModel = CurrencyConverterViewModel(currencyService: currencyService)
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.primaryBlue
        setupGradientBackground()
        setupScrollView()
        setupTitleLabel()
        setupCurrencyCard()
        setupAmountTextField()
        setupCurrencyButtons()
        setupSwapButton()
        setupConvertButton()
        setupResultLabels()
        setupLoadingIndicator()
    }
    
    private func setupGradientBackground() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor.primaryBlue.cgColor,
            UIColor.primaryBlueDark.cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.frame = view.bounds
        view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    private func setupScrollView() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupTitleLabel() {
        contentView.addSubview(titleLabel)
        titleLabel.text = "Currency Calculator"
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupCurrencyCard() {
        contentView.addSubview(currencyCard)
        currencyCard.backgroundColor = .white
        currencyCard.layer.cornerRadius = 16
        currencyCard.layer.shadowColor = UIColor.black.cgColor
        currencyCard.layer.shadowOffset = CGSize(width: 0, height: 4)
        currencyCard.layer.shadowRadius = 12
        currencyCard.layer.shadowOpacity = 0.1
        currencyCard.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupAmountTextField() {
        currencyCard.addSubview(amountTextField)
        amountTextField.text = "1"
        amountTextField.font = UIFont.systemFont(ofSize: 48, weight: .light)
        amountTextField.textColor = UIColor.primaryBlue
        amountTextField.textAlignment = .center
        amountTextField.keyboardType = .decimalPad
        amountTextField.borderStyle = .none
        amountTextField.translatesAutoresizingMaskIntoConstraints = false
        
        // Add toolbar with Done button
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissKeyboard))
        toolbar.setItems([UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), doneButton], animated: false)
        amountTextField.inputAccessoryView = toolbar
    }
    
    private func setupCurrencyButtons() {
        // From Currency Button
        currencyCard.addSubview(fromCurrencyButton)
        fromCurrencyButton.setTitle("🇪🇺 EUR", for: .normal)
        fromCurrencyButton.setTitleColor(UIColor.primaryBlue, for: .normal)
        fromCurrencyButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        fromCurrencyButton.backgroundColor = UIColor.lightGray.withAlphaComponent(0.1)
        fromCurrencyButton.layer.cornerRadius = 8
        fromCurrencyButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        fromCurrencyButton.translatesAutoresizingMaskIntoConstraints = false
        
        // To Currency Button
        currencyCard.addSubview(toCurrencyButton)
        toCurrencyButton.setTitle("🇵🇱 PLN", for: .normal)
        toCurrencyButton.setTitleColor(UIColor.primaryBlue, for: .normal)
        toCurrencyButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        toCurrencyButton.backgroundColor = UIColor.lightGray.withAlphaComponent(0.1)
        toCurrencyButton.layer.cornerRadius = 8
        toCurrencyButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        toCurrencyButton.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupSwapButton() {
        currencyCard.addSubview(swapButton)
        swapButton.setTitle("⇄", for: .normal)
        swapButton.setTitleColor(UIColor.primaryBlue, for: .normal)
        swapButton.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        swapButton.backgroundColor = UIColor.lightGray.withAlphaComponent(0.1)
        swapButton.layer.cornerRadius = 20
        swapButton.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupConvertButton() {
        currencyCard.addSubview(convertButton)
        convertButton.setTitle("Convert", for: .normal)
        convertButton.setTitleColor(.white, for: .normal)
        convertButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        convertButton.backgroundColor = UIColor.accentGreen
        convertButton.layer.cornerRadius = 12
        convertButton.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupResultLabels() {
        // Result Label
        currencyCard.addSubview(resultLabel)
        resultLabel.text = "4.32"
        resultLabel.font = UIFont.systemFont(ofSize: 48, weight: .light)
        resultLabel.textColor = UIColor.primaryBlue
        resultLabel.textAlignment = .center
        resultLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Exchange Rate Label
        currencyCard.addSubview(exchangeRateLabel)
        exchangeRateLabel.text = "1 EUR = 4.32 PLN"
        exchangeRateLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        exchangeRateLabel.textColor = UIColor.systemGray
        exchangeRateLabel.textAlignment = .center
        exchangeRateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Last Updated Label
        currencyCard.addSubview(lastUpdatedLabel)
        lastUpdatedLabel.text = "Updated 2 minutes ago"
        lastUpdatedLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        lastUpdatedLabel.textColor = UIColor.systemGray2
        lastUpdatedLabel.textAlignment = .center
        lastUpdatedLabel.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupLoadingIndicator() {
        currencyCard.addSubview(loadingIndicator)
        loadingIndicator.color = UIColor.primaryBlue
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content View
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Title Label
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            // Currency Card
            currencyCard.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            currencyCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            currencyCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            currencyCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),
            
            // Amount TextField
            amountTextField.topAnchor.constraint(equalTo: currencyCard.topAnchor, constant: 40),
            amountTextField.leadingAnchor.constraint(equalTo: currencyCard.leadingAnchor, constant: 20),
            amountTextField.trailingAnchor.constraint(equalTo: currencyCard.trailingAnchor, constant: -20),
            amountTextField.heightAnchor.constraint(equalToConstant: 60),
            
            // From Currency Button
            fromCurrencyButton.topAnchor.constraint(equalTo: amountTextField.bottomAnchor, constant: 30),
            fromCurrencyButton.leadingAnchor.constraint(equalTo: currencyCard.leadingAnchor, constant: 20),
            fromCurrencyButton.widthAnchor.constraint(equalToConstant: 120),
            fromCurrencyButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Swap Button
            swapButton.centerYAnchor.constraint(equalTo: fromCurrencyButton.centerYAnchor),
            swapButton.centerXAnchor.constraint(equalTo: currencyCard.centerXAnchor),
            swapButton.widthAnchor.constraint(equalToConstant: 40),
            swapButton.heightAnchor.constraint(equalToConstant: 40),
            
            // To Currency Button
            toCurrencyButton.topAnchor.constraint(equalTo: amountTextField.bottomAnchor, constant: 30),
            toCurrencyButton.trailingAnchor.constraint(equalTo: currencyCard.trailingAnchor, constant: -20),
            toCurrencyButton.widthAnchor.constraint(equalToConstant: 120),
            toCurrencyButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Convert Button
            convertButton.topAnchor.constraint(equalTo: fromCurrencyButton.bottomAnchor, constant: 30),
            convertButton.leadingAnchor.constraint(equalTo: currencyCard.leadingAnchor, constant: 20),
            convertButton.trailingAnchor.constraint(equalTo: currencyCard.trailingAnchor, constant: -20),
            convertButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Result Label
            resultLabel.topAnchor.constraint(equalTo: convertButton.bottomAnchor, constant: 40),
            resultLabel.leadingAnchor.constraint(equalTo: currencyCard.leadingAnchor, constant: 20),
            resultLabel.trailingAnchor.constraint(equalTo: currencyCard.trailingAnchor, constant: -20),
            resultLabel.heightAnchor.constraint(equalToConstant: 60),
            
            // Exchange Rate Label
            exchangeRateLabel.topAnchor.constraint(equalTo: resultLabel.bottomAnchor, constant: 10),
            exchangeRateLabel.leadingAnchor.constraint(equalTo: currencyCard.leadingAnchor, constant: 20),
            exchangeRateLabel.trailingAnchor.constraint(equalTo: currencyCard.trailingAnchor, constant: -20),
            
            // Last Updated Label
            lastUpdatedLabel.topAnchor.constraint(equalTo: exchangeRateLabel.bottomAnchor, constant: 8),
            lastUpdatedLabel.leadingAnchor.constraint(equalTo: currencyCard.leadingAnchor, constant: 20),
            lastUpdatedLabel.trailingAnchor.constraint(equalTo: currencyCard.trailingAnchor, constant: -20),
            lastUpdatedLabel.bottomAnchor.constraint(equalTo: currencyCard.bottomAnchor, constant: -30),
            
            // Loading Indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: convertButton.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: convertButton.centerYAnchor)
        ])
    }
    
    private func setupBindings() {
        // Bind ViewModel to UI
        viewModel.$fromCurrency
            .receive(on: DispatchQueue.main)
            .sink { [weak self] currency in
                self?.fromCurrencyButton.setTitle("\(currency.flag) \(currency.code)", for: .normal)
            }
            .store(in: &cancellables)
        
        viewModel.$toCurrency
            .receive(on: DispatchQueue.main)
            .sink { [weak self] currency in
                self?.toCurrencyButton.setTitle("\(currency.flag) \(currency.code)", for: .normal)
            }
            .store(in: &cancellables)
        
        viewModel.$convertedAmount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] amount in
                if let amount = amount {
                    self?.resultLabel.text = String(format: "%.2f", amount)
                } else {
                    self?.resultLabel.text = "0.00"
                }
            }
            .store(in: &cancellables)
        
        viewModel.$exchangeRate
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rate in
                guard let self = self, let rate = rate else { return }
                let fromCode = self.viewModel.fromCurrency.code
                let toCode = self.viewModel.toCurrency.code
                self.exchangeRateLabel.text = "1 \(fromCode) = \(String(format: "%.4f", rate)) \(toCode)"
            }
            .store(in: &cancellables)
        
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.loadingIndicator.startAnimating()
                    self?.convertButton.setTitle("", for: .normal)
                } else {
                    self?.loadingIndicator.stopAnimating()
                    self?.convertButton.setTitle("Convert", for: .normal)
                }
            }
            .store(in: &cancellables)
        
        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                if let error = error {
                    self?.showError(error)
                }
            }
            .store(in: &cancellables)
        
        viewModel.$lastUpdated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] date in
                if let date = date {
                    let formatter = RelativeDateTimeFormatter()
                    formatter.unitsStyle = .full
                    let timeString = formatter.localizedString(for: date, relativeTo: Date())
                    self?.lastUpdatedLabel.text = "Updated \(timeString)"
                } else {
                    self?.lastUpdatedLabel.text = ""
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupActions() {
        fromCurrencyButton.addTarget(self, action: #selector(fromCurrencyTapped), for: .touchUpInside)
        toCurrencyButton.addTarget(self, action: #selector(toCurrencyTapped), for: .touchUpInside)
        swapButton.addTarget(self, action: #selector(swapCurrencies), for: .touchUpInside)
        convertButton.addTarget(self, action: #selector(convert), for: .touchUpInside)
        amountTextField.addTarget(self, action: #selector(amountChanged), for: .editingChanged)
    }
    
    // MARK: - Actions
    @objc private func fromCurrencyTapped() {
        showCurrencyPicker(isFromCurrency: true)
    }
    
    @objc private func toCurrencyTapped() {
        showCurrencyPicker(isFromCurrency: false)
    }
    
    @objc private func swapCurrencies() {
        viewModel.swapCurrencies()
        
        // Add animation
        UIView.transition(with: fromCurrencyButton, duration: 0.3, options: .transitionFlipFromLeft, animations: nil)
        UIView.transition(with: toCurrencyButton, duration: 0.3, options: .transitionFlipFromRight, animations: nil)
    }
    
    @objc private func convert() {
        guard let amountText = amountTextField.text,
              let amount = Double(amountText) else {
            showError("Please enter a valid amount")
            return
        }
        
        viewModel.convert(amount: amount)
    }
    
    @objc private func amountChanged() {
        // Auto-convert as user types (with debouncing handled in ViewModel)
        guard let amountText = amountTextField.text,
              let amount = Double(amountText) else {
            return
        }
        
        viewModel.convert(amount: amount)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Helper Methods
    private func showCurrencyPicker(isFromCurrency: Bool) {
        let selectedCurrency = isFromCurrency ? viewModel.fromCurrency : viewModel.toCurrency
        
        let alert = UIAlertController(title: "Select Currency", message: nil, preferredStyle: .actionSheet)
        
        // Add popular currencies first
        let popularCurrencies = CurrencyData.popularCurrencies()
        for currency in popularCurrencies {
            let action = UIAlertAction(title: "\(currency.flag) \(currency.code) - \(currency.name)", style: .default) { [weak self] _ in
                if isFromCurrency {
                    self?.viewModel.setFromCurrency(currency)
                } else {
                    self?.viewModel.setToCurrency(currency)
                }
            }
            if currency.code == selectedCurrency.code {
                action.setValue(true, forKey: "checked")
            }
            alert.addAction(action)
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // For iPad
        if let popover = alert.popoverPresentationController {
            popover.sourceView = isFromCurrency ? fromCurrencyButton : toCurrencyButton
            popover.sourceRect = (isFromCurrency ? fromCurrencyButton : toCurrencyButton).bounds
        }
        
        present(alert, animated: true)
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Extensions

extension UIColor {
    static let primaryBlue = UIColor(red: 0x38/255.0, green: 0x70/255.0, blue: 0xB0/255.0, alpha: 1.0)
    static let primaryBlueDark = UIColor(red: 0x2A/255.0, green: 0x52/255.0, blue: 0x80/255.0, alpha: 1.0)
    static let accentGreen = UIColor(red: 0x40/255.0, green: 0xD1/255.0, blue: 0x9A/255.0, alpha: 1.0)
}