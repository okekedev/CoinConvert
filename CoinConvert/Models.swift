import Foundation

// MARK: - Currency Model

struct Currency: Identifiable, Codable, Hashable {
    let id: String // ISO 4217 code (e.g., "USD", "EUR", "MXN")
    let name: String
    let symbol: String
    let flag: String // Emoji flag

    var code: String { id }

    static let supportedCurrencies: [Currency] = [
        Currency(id: "USD", name: "US Dollar", symbol: "$", flag: "🇺🇸"),
        Currency(id: "EUR", name: "Euro", symbol: "€", flag: "🇪🇺"),
        Currency(id: "GBP", name: "British Pound", symbol: "£", flag: "🇬🇧"),
        Currency(id: "JPY", name: "Japanese Yen", symbol: "¥", flag: "🇯🇵"),
        Currency(id: "CNY", name: "Chinese Yuan", symbol: "¥", flag: "🇨🇳"),
        Currency(id: "MXN", name: "Mexican Peso", symbol: "$", flag: "🇲🇽"),
        Currency(id: "CAD", name: "Canadian Dollar", symbol: "$", flag: "🇨🇦"),
        Currency(id: "AUD", name: "Australian Dollar", symbol: "$", flag: "🇦🇺"),
        Currency(id: "CHF", name: "Swiss Franc", symbol: "Fr", flag: "🇨🇭"),
        Currency(id: "KRW", name: "South Korean Won", symbol: "₩", flag: "🇰🇷"),
        Currency(id: "INR", name: "Indian Rupee", symbol: "₹", flag: "🇮🇳"),
        Currency(id: "BRL", name: "Brazilian Real", symbol: "R$", flag: "🇧🇷"),
        Currency(id: "RUB", name: "Russian Ruble", symbol: "₽", flag: "🇷🇺"),
        Currency(id: "ZAR", name: "South African Rand", symbol: "R", flag: "🇿🇦"),
        Currency(id: "SGD", name: "Singapore Dollar", symbol: "$", flag: "🇸🇬"),
        Currency(id: "HKD", name: "Hong Kong Dollar", symbol: "$", flag: "🇭🇰"),
        Currency(id: "NOK", name: "Norwegian Krone", symbol: "kr", flag: "🇳🇴"),
        Currency(id: "SEK", name: "Swedish Krona", symbol: "kr", flag: "🇸🇪"),
        Currency(id: "DKK", name: "Danish Krone", symbol: "kr", flag: "🇩🇰"),
        Currency(id: "NZD", name: "New Zealand Dollar", symbol: "$", flag: "🇳🇿"),
        Currency(id: "THB", name: "Thai Baht", symbol: "฿", flag: "🇹🇭"),
        Currency(id: "PHP", name: "Philippine Peso", symbol: "₱", flag: "🇵🇭"),
        Currency(id: "TWD", name: "Taiwan Dollar", symbol: "NT$", flag: "🇹🇼"),
        Currency(id: "PLN", name: "Polish Zloty", symbol: "zł", flag: "🇵🇱"),
        Currency(id: "TRY", name: "Turkish Lira", symbol: "₺", flag: "🇹🇷"),
        Currency(id: "AED", name: "UAE Dirham", symbol: "د.إ", flag: "🇦🇪"),
        Currency(id: "SAR", name: "Saudi Riyal", symbol: "﷼", flag: "🇸🇦"),
        Currency(id: "MYR", name: "Malaysian Ringgit", symbol: "RM", flag: "🇲🇾"),
        Currency(id: "IDR", name: "Indonesian Rupiah", symbol: "Rp", flag: "🇮🇩"),
        Currency(id: "VND", name: "Vietnamese Dong", symbol: "₫", flag: "🇻🇳"),
        Currency(id: "COP", name: "Colombian Peso", symbol: "$", flag: "🇨🇴"),
        Currency(id: "ARS", name: "Argentine Peso", symbol: "$", flag: "🇦🇷"),
        Currency(id: "CLP", name: "Chilean Peso", symbol: "$", flag: "🇨🇱"),
        Currency(id: "PEN", name: "Peruvian Sol", symbol: "S/", flag: "🇵🇪"),
        Currency(id: "EGP", name: "Egyptian Pound", symbol: "£", flag: "🇪🇬"),
        Currency(id: "ILS", name: "Israeli Shekel", symbol: "₪", flag: "🇮🇱"),
        Currency(id: "CZK", name: "Czech Koruna", symbol: "Kč", flag: "🇨🇿"),
        Currency(id: "HUF", name: "Hungarian Forint", symbol: "Ft", flag: "🇭🇺"),
        Currency(id: "RON", name: "Romanian Leu", symbol: "lei", flag: "🇷🇴"),
        Currency(id: "BGN", name: "Bulgarian Lev", symbol: "лв", flag: "🇧🇬")
    ]

    static func currency(for code: String) -> Currency? {
        supportedCurrencies.first { $0.id == code.uppercased() }
    }

    static func currencyBySymbol(_ symbol: String) -> [Currency] {
        supportedCurrencies.filter { $0.symbol == symbol }
    }
}

// MARK: - Exchange Rate Model

struct ExchangeRates: Codable {
    let baseCurrency: String
    let rates: [String: Double]
    let lastUpdated: Date

    func convert(amount: Double, from source: String, to destination: String) -> Double? {
        guard let sourceRate = rates[source],
              let destRate = rates[destination] else {
            return nil
        }
        let amountInBase = amount / sourceRate
        return amountInBase * destRate
    }

    var formattedLastUpdated: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: lastUpdated)
    }

    var isOutdated: Bool {
        let calendar = Calendar.current
        let daysSinceUpdate = calendar.dateComponents([.day], from: lastUpdated, to: Date()).day ?? 0
        return daysSinceUpdate > 7
    }

    static let defaultRates = ExchangeRates(
        baseCurrency: "USD",
        rates: [
            "USD": 1.0, "EUR": 0.92, "GBP": 0.79, "JPY": 149.50, "CNY": 7.24,
            "MXN": 17.15, "CAD": 1.36, "AUD": 1.53, "CHF": 0.88, "KRW": 1298.0,
            "INR": 83.12, "BRL": 4.97, "RUB": 89.50, "ZAR": 18.65, "SGD": 1.34,
            "HKD": 7.82, "NOK": 10.85, "SEK": 10.45, "DKK": 6.88, "NZD": 1.64,
            "THB": 35.20, "PHP": 55.80, "TWD": 31.50, "PLN": 4.02, "TRY": 28.90,
            "AED": 3.67, "SAR": 3.75, "MYR": 4.68, "IDR": 15650.0, "VND": 24350.0,
            "COP": 4050.0, "ARS": 350.0, "CLP": 880.0, "PEN": 3.72, "EGP": 30.90,
            "ILS": 3.68, "CZK": 22.50, "HUF": 355.0, "RON": 4.58, "BGN": 1.80
        ],
        lastUpdated: Date()
    )
}

struct ExchangeRateAPIResponse: Codable {
    let result: String?
    let base_code: String?
    let conversion_rates: [String: Double]?
    let base: String?
    let rates: [String: Double]?
}

// MARK: - OCR Result Model

struct OCRResult {
    let amount: Double
    let currencySymbol: String?
    let rawText: String
    let confidence: Float
}

// MARK: - Calculator Operation

enum CalculatorOperation {
    case add, subtract, multiply, divide

    var symbol: String {
        switch self {
        case .add: return "+"
        case .subtract: return "-"
        case .multiply: return "×"
        case .divide: return "÷"
        }
    }
}
