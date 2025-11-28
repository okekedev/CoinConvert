import Foundation

class CurrencyManager: ObservableObject {
    @Published var sourceCurrency: Currency
    @Published var destinationCurrency: Currency

    private let sourceKey = "com.coinconvert.sourcecurrency"
    private let destinationKey = "com.coinconvert.destinationcurrency"
    private let userDefaults = UserDefaults.standard

    init() {
        if let sourceCode = userDefaults.string(forKey: sourceKey),
           let source = Currency.currency(for: sourceCode) {
            self.sourceCurrency = source
        } else {
            self.sourceCurrency = Currency.currency(for: "USD") ?? Currency.supportedCurrencies[0]
        }

        if let destCode = userDefaults.string(forKey: destinationKey),
           let dest = Currency.currency(for: destCode) {
            self.destinationCurrency = dest
        } else {
            self.destinationCurrency = Currency.currency(for: "EUR") ?? Currency.supportedCurrencies[1]
        }
    }

    func setSourceCurrency(_ currency: Currency) {
        sourceCurrency = currency
        userDefaults.set(currency.code, forKey: sourceKey)
    }

    func setDestinationCurrency(_ currency: Currency) {
        destinationCurrency = currency
        userDefaults.set(currency.code, forKey: destinationKey)
    }

    func swapCurrencies() {
        let temp = sourceCurrency
        sourceCurrency = destinationCurrency
        destinationCurrency = temp
        userDefaults.set(sourceCurrency.code, forKey: sourceKey)
        userDefaults.set(destinationCurrency.code, forKey: destinationKey)
    }

    func detectCurrency(from symbol: String) -> Currency? {
        let matches = Currency.currencyBySymbol(symbol)
        if matches.count == 1 {
            return matches.first
        }
        if matches.contains(sourceCurrency) {
            return sourceCurrency
        }
        return matches.first
    }
}
