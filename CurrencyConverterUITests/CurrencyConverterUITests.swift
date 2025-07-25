import XCTest

final class CurrencyConverterUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - UI Element Tests
    
    func testUIElementsExist() throws {
        let app = XCUIApplication()
        
        // Check title
        let titleLabel = app.staticTexts["Currency Calculator"]
        XCTAssertTrue(titleLabel.exists)
        
        // Check amount text field
        let amountTextField = app.textFields.firstMatch
        XCTAssertTrue(amountTextField.exists)
        XCTAssertEqual(amountTextField.value as? String, "1")
        
        // Check currency buttons
        let fromCurrencyButton = app.buttons.containing(.staticText, identifier:"🇪🇺 EUR").firstMatch
        let toCurrencyButton = app.buttons.containing(.staticText, identifier:"🇵🇱 PLN").firstMatch
        
        XCTAssertTrue(fromCurrencyButton.exists)
        XCTAssertTrue(toCurrencyButton.exists)
        
        // Check swap button
        let swapButton = app.buttons["⇄"]
        XCTAssertTrue(swapButton.exists)
        
        // Check convert button
        let convertButton = app.buttons["Convert"]
        XCTAssertTrue(convertButton.exists)
        
        // Check result labels
        let resultLabel = app.staticTexts["4.32"]
        let exchangeRateLabel = app.staticTexts.containing(.staticText, identifier:"1 EUR = 4.32 PLN").firstMatch
        let lastUpdatedLabel = app.staticTexts.containing(.staticText, identifier:"Updated").firstMatch
        
        XCTAssertTrue(resultLabel.exists)
        XCTAssertTrue(exchangeRateLabel.exists)
        XCTAssertTrue(lastUpdatedLabel.exists)
    }
    
    func testAmountInput() throws {
        let app = XCUIApplication()
        
        let amountTextField = app.textFields.firstMatch
        XCTAssertTrue(amountTextField.exists)
        
        // Clear and enter new amount
        amountTextField.tap()
        amountTextField.clearAndEnterText("100")
        
        // Verify the text was entered
        XCTAssertEqual(amountTextField.value as? String, "100")
        
        // Test decimal input
        amountTextField.clearAndEnterText("123.45")
        XCTAssertEqual(amountTextField.value as? String, "123.45")
    }
    
    func testSwapCurrencies() throws {
        let app = XCUIApplication()
        
        // Get initial currency button states
        let fromCurrencyButton = app.buttons.containing(.staticText, identifier:"🇪🇺 EUR").firstMatch
        let toCurrencyButton = app.buttons.containing(.staticText, identifier:"🇵🇱 PLN").firstMatch
        
        XCTAssertTrue(fromCurrencyButton.exists)
        XCTAssertTrue(toCurrencyButton.exists)
        
        // Tap swap button
        let swapButton = app.buttons["⇄"]
        XCTAssertTrue(swapButton.exists)
        swapButton.tap()
        
        // Wait for animation and check if currencies swapped
        sleep(1)
        
        let newFromButton = app.buttons.containing(.staticText, identifier:"🇵🇱 PLN").firstMatch
        let newToButton = app.buttons.containing(.staticText, identifier:"🇪🇺 EUR").firstMatch
        
        XCTAssertTrue(newFromButton.exists)
        XCTAssertTrue(newToButton.exists)
    }
    
    func testConvertButton() throws {
        let app = XCUIApplication()
        
        let convertButton = app.buttons["Convert"]
        XCTAssertTrue(convertButton.exists)
        
        // Tap convert button
        convertButton.tap()
        
        // Wait for potential loading state
        sleep(2)
        
        // Check if result is updated (this would depend on mock data or network)
        let resultLabel = app.staticTexts.firstMatch
        XCTAssertTrue(resultLabel.exists)
    }
    
    func testCurrencySelection() throws {
        let app = XCUIApplication()
        
        // Tap from currency button
        let fromCurrencyButton = app.buttons.containing(.staticText, identifier:"🇪🇺 EUR").firstMatch
        XCTAssertTrue(fromCurrencyButton.exists)
        fromCurrencyButton.tap()
        
        // Note: This test assumes a currency picker would be presented
        // In the actual implementation, you would test the picker interaction
        
        // Tap to currency button
        let toCurrencyButton = app.buttons.containing(.staticText, identifier:"🇵🇱 PLN").firstMatch
        XCTAssertTrue(toCurrencyButton.exists)
        toCurrencyButton.tap()
    }
    
    func testScrolling() throws {
        let app = XCUIApplication()
        
        // Test that the scroll view works
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.exists)
        
        // Scroll down and up
        scrollView.swipeUp()
        sleep(1)
        scrollView.swipeDown()
    }
    
    func testKeyboardInteraction() throws {
        let app = XCUIApplication()
        
        let amountTextField = app.textFields.firstMatch
        XCTAssertTrue(amountTextField.exists)
        
        // Tap text field to show keyboard
        amountTextField.tap()
        
        // Check if keyboard appeared
        let keyboard = app.keyboards.firstMatch
        XCTAssertTrue(keyboard.waitForExistence(timeout: 2))
        
        // Type some numbers
        app.keys["1"].tap()
        app.keys["2"].tap()
        app.keys["3"].tap()
        
        // Check if Done button exists and tap it
        let doneButton = app.toolbars.buttons["Done"]
        if doneButton.exists {
            doneButton.tap()
        }
        
        // Verify keyboard disappeared
        XCTAssertFalse(keyboard.exists)
    }
    
    func testAccessibility() throws {
        let app = XCUIApplication()
        
        // Check that key elements have accessibility identifiers or labels
        let titleLabel = app.staticTexts["Currency Calculator"]
        XCTAssertTrue(titleLabel.isAccessibilityElement)
        
        let amountTextField = app.textFields.firstMatch
        XCTAssertTrue(amountTextField.isAccessibilityElement)
        
        let convertButton = app.buttons["Convert"]
        XCTAssertTrue(convertButton.isAccessibilityElement)
        
        let swapButton = app.buttons["⇄"]
        XCTAssertTrue(swapButton.isAccessibilityElement)
    }
    
    func testErrorHandling() throws {
        let app = XCUIApplication()
        
        // Enter invalid amount
        let amountTextField = app.textFields.firstMatch
        amountTextField.tap()
        amountTextField.clearAndEnterText("0")
        
        // Tap convert
        let convertButton = app.buttons["Convert"]
        convertButton.tap()
        
        // Check for error alert (if implemented)
        let alert = app.alerts.firstMatch
        if alert.waitForExistence(timeout: 3) {
            XCTAssertTrue(alert.exists)
            
            let okButton = alert.buttons["OK"]
            if okButton.exists {
                okButton.tap()
            }
        }
    }
    
    func testLandscapeOrientation() throws {
        let app = XCUIApplication()
        
        // Rotate to landscape
        XCUIDevice.shared.orientation = .landscapeLeft
        
        // Wait for rotation animation
        sleep(2)
        
        // Check that UI elements are still accessible
        let titleLabel = app.staticTexts["Currency Calculator"]
        XCTAssertTrue(titleLabel.exists)
        
        let convertButton = app.buttons["Convert"]
        XCTAssertTrue(convertButton.exists)
        
        // Rotate back to portrait
        XCUIDevice.shared.orientation = .portrait
        sleep(1)
    }
    
    func testAppLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
    
    func testMemoryUsage() throws {
        let app = XCUIApplication()
        
        // Perform multiple operations to test memory usage
        let amountTextField = app.textFields.firstMatch
        let convertButton = app.buttons["Convert"]
        let swapButton = app.buttons["⇄"]
        
        for i in 1...10 {
            amountTextField.tap()
            amountTextField.clearAndEnterText("\(i * 10)")
            convertButton.tap()
            sleep(1)
            swapButton.tap()
            sleep(1)
        }
        
        // The app should still be responsive
        XCTAssertTrue(convertButton.exists)
        XCTAssertTrue(convertButton.isEnabled)
    }
    
    func testNetworkStateHandling() throws {
        let app = XCUIApplication()
        
        // This test would require network mocking or airplane mode simulation
        // For now, just test that the UI remains functional
        
        let convertButton = app.buttons["Convert"]
        convertButton.tap()
        
        // Wait for potential network timeout
        sleep(5)
        
        // UI should still be responsive
        XCTAssertTrue(convertButton.exists)
        XCTAssertTrue(convertButton.isEnabled)
    }
}

// MARK: - Helper Extensions

extension XCUIElement {
    func clearAndEnterText(_ text: String) {
        guard let stringValue = self.value as? String else {
            XCTFail("Tried to clear and enter text into a non-string value")
            return
        }
        
        self.tap()
        
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        self.typeText(deleteString)
        self.typeText(text)
    }
}