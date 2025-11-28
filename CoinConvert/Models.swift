import Foundation

// MARK: - Currency Model

struct Currency: Identifiable, Codable, Hashable {
    let id: String // ISO 4217 code (e.g., "USD", "EUR", "MXN")
    let name: String
    let symbol: String
    let flag: String // Emoji flag

    var code: String { id }

    static let supportedCurrencies: [Currency] = [
        // Major World Currencies
        Currency(id: "USD", name: "US Dollar", symbol: "$", flag: "🇺🇸"),
        Currency(id: "EUR", name: "Euro", symbol: "€", flag: "🇪🇺"),
        Currency(id: "GBP", name: "British Pound", symbol: "£", flag: "🇬🇧"),
        Currency(id: "JPY", name: "Japanese Yen", symbol: "¥", flag: "🇯🇵"),
        Currency(id: "CNY", name: "Chinese Yuan", symbol: "¥", flag: "🇨🇳"),
        Currency(id: "CHF", name: "Swiss Franc", symbol: "Fr", flag: "🇨🇭"),

        // North America
        Currency(id: "CAD", name: "Canadian Dollar", symbol: "$", flag: "🇨🇦"),
        Currency(id: "MXN", name: "Mexican Peso", symbol: "$", flag: "🇲🇽"),

        // Central America & Caribbean
        Currency(id: "GTQ", name: "Guatemalan Quetzal", symbol: "Q", flag: "🇬🇹"),
        Currency(id: "HNL", name: "Honduran Lempira", symbol: "L", flag: "🇭🇳"),
        Currency(id: "NIO", name: "Nicaraguan Córdoba", symbol: "C$", flag: "🇳🇮"),
        Currency(id: "CRC", name: "Costa Rican Colón", symbol: "₡", flag: "🇨🇷"),
        Currency(id: "PAB", name: "Panamanian Balboa", symbol: "B/.", flag: "🇵🇦"),
        Currency(id: "BZD", name: "Belize Dollar", symbol: "$", flag: "🇧🇿"),
        Currency(id: "JMD", name: "Jamaican Dollar", symbol: "$", flag: "🇯🇲"),
        Currency(id: "TTD", name: "Trinidad Dollar", symbol: "$", flag: "🇹🇹"),
        Currency(id: "BBD", name: "Barbadian Dollar", symbol: "$", flag: "🇧🇧"),
        Currency(id: "BSD", name: "Bahamian Dollar", symbol: "$", flag: "🇧🇸"),
        Currency(id: "KYD", name: "Cayman Islands Dollar", symbol: "$", flag: "🇰🇾"),
        Currency(id: "XCD", name: "East Caribbean Dollar", symbol: "$", flag: "🇦🇬"),
        Currency(id: "DOP", name: "Dominican Peso", symbol: "$", flag: "🇩🇴"),
        Currency(id: "HTG", name: "Haitian Gourde", symbol: "G", flag: "🇭🇹"),
        Currency(id: "CUP", name: "Cuban Peso", symbol: "$", flag: "🇨🇺"),
        Currency(id: "AWG", name: "Aruban Florin", symbol: "ƒ", flag: "🇦🇼"),
        Currency(id: "ANG", name: "Netherlands Antillean Guilder", symbol: "ƒ", flag: "🇨🇼"),

        // South America
        Currency(id: "BRL", name: "Brazilian Real", symbol: "R$", flag: "🇧🇷"),
        Currency(id: "ARS", name: "Argentine Peso", symbol: "$", flag: "🇦🇷"),
        Currency(id: "CLP", name: "Chilean Peso", symbol: "$", flag: "🇨🇱"),
        Currency(id: "COP", name: "Colombian Peso", symbol: "$", flag: "🇨🇴"),
        Currency(id: "PEN", name: "Peruvian Sol", symbol: "S/", flag: "🇵🇪"),
        Currency(id: "UYU", name: "Uruguayan Peso", symbol: "$", flag: "🇺🇾"),
        Currency(id: "PYG", name: "Paraguayan Guarani", symbol: "₲", flag: "🇵🇾"),
        Currency(id: "BOB", name: "Bolivian Boliviano", symbol: "Bs", flag: "🇧🇴"),
        Currency(id: "VES", name: "Venezuelan Bolívar", symbol: "Bs", flag: "🇻🇪"),
        Currency(id: "GYD", name: "Guyanese Dollar", symbol: "$", flag: "🇬🇾"),
        Currency(id: "SRD", name: "Surinamese Dollar", symbol: "$", flag: "🇸🇷"),
        Currency(id: "FKP", name: "Falkland Islands Pound", symbol: "£", flag: "🇫🇰"),

        // Western Europe
        Currency(id: "NOK", name: "Norwegian Krone", symbol: "kr", flag: "🇳🇴"),
        Currency(id: "SEK", name: "Swedish Krona", symbol: "kr", flag: "🇸🇪"),
        Currency(id: "DKK", name: "Danish Krone", symbol: "kr", flag: "🇩🇰"),
        Currency(id: "ISK", name: "Icelandic Króna", symbol: "kr", flag: "🇮🇸"),

        // Eastern Europe
        Currency(id: "PLN", name: "Polish Zloty", symbol: "zł", flag: "🇵🇱"),
        Currency(id: "CZK", name: "Czech Koruna", symbol: "Kč", flag: "🇨🇿"),
        Currency(id: "HUF", name: "Hungarian Forint", symbol: "Ft", flag: "🇭🇺"),
        Currency(id: "RON", name: "Romanian Leu", symbol: "lei", flag: "🇷🇴"),
        Currency(id: "BGN", name: "Bulgarian Lev", symbol: "лв", flag: "🇧🇬"),
        Currency(id: "UAH", name: "Ukrainian Hryvnia", symbol: "₴", flag: "🇺🇦"),
        Currency(id: "RUB", name: "Russian Ruble", symbol: "₽", flag: "🇷🇺"),
        Currency(id: "BYN", name: "Belarusian Ruble", symbol: "Br", flag: "🇧🇾"),
        Currency(id: "MDL", name: "Moldovan Leu", symbol: "L", flag: "🇲🇩"),
        Currency(id: "RSD", name: "Serbian Dinar", symbol: "дин", flag: "🇷🇸"),
        Currency(id: "BAM", name: "Bosnia-Herzegovina Mark", symbol: "KM", flag: "🇧🇦"),
        Currency(id: "HRK", name: "Croatian Kuna", symbol: "kn", flag: "🇭🇷"),
        Currency(id: "MKD", name: "Macedonian Denar", symbol: "ден", flag: "🇲🇰"),
        Currency(id: "ALL", name: "Albanian Lek", symbol: "L", flag: "🇦🇱"),
        Currency(id: "GEL", name: "Georgian Lari", symbol: "₾", flag: "🇬🇪"),
        Currency(id: "AMD", name: "Armenian Dram", symbol: "֏", flag: "🇦🇲"),
        Currency(id: "AZN", name: "Azerbaijani Manat", symbol: "₼", flag: "🇦🇿"),

        // Middle East
        Currency(id: "TRY", name: "Turkish Lira", symbol: "₺", flag: "🇹🇷"),
        Currency(id: "ILS", name: "Israeli Shekel", symbol: "₪", flag: "🇮🇱"),
        Currency(id: "AED", name: "UAE Dirham", symbol: "د.إ", flag: "🇦🇪"),
        Currency(id: "SAR", name: "Saudi Riyal", symbol: "﷼", flag: "🇸🇦"),
        Currency(id: "QAR", name: "Qatari Riyal", symbol: "﷼", flag: "🇶🇦"),
        Currency(id: "KWD", name: "Kuwaiti Dinar", symbol: "د.ك", flag: "🇰🇼"),
        Currency(id: "BHD", name: "Bahraini Dinar", symbol: "د.ب", flag: "🇧🇭"),
        Currency(id: "OMR", name: "Omani Rial", symbol: "ر.ع.", flag: "🇴🇲"),
        Currency(id: "JOD", name: "Jordanian Dinar", symbol: "د.ا", flag: "🇯🇴"),
        Currency(id: "LBP", name: "Lebanese Pound", symbol: "ل.ل", flag: "🇱🇧"),
        Currency(id: "SYP", name: "Syrian Pound", symbol: "£", flag: "🇸🇾"),
        Currency(id: "IQD", name: "Iraqi Dinar", symbol: "ع.د", flag: "🇮🇶"),
        Currency(id: "IRR", name: "Iranian Rial", symbol: "﷼", flag: "🇮🇷"),
        Currency(id: "YER", name: "Yemeni Rial", symbol: "﷼", flag: "🇾🇪"),

        // South Asia
        Currency(id: "INR", name: "Indian Rupee", symbol: "₹", flag: "🇮🇳"),
        Currency(id: "PKR", name: "Pakistani Rupee", symbol: "₨", flag: "🇵🇰"),
        Currency(id: "BDT", name: "Bangladeshi Taka", symbol: "৳", flag: "🇧🇩"),
        Currency(id: "LKR", name: "Sri Lankan Rupee", symbol: "Rs", flag: "🇱🇰"),
        Currency(id: "NPR", name: "Nepalese Rupee", symbol: "₨", flag: "🇳🇵"),
        Currency(id: "BTN", name: "Bhutanese Ngultrum", symbol: "Nu.", flag: "🇧🇹"),
        Currency(id: "MVR", name: "Maldivian Rufiyaa", symbol: "Rf", flag: "🇲🇻"),
        Currency(id: "AFN", name: "Afghan Afghani", symbol: "؋", flag: "🇦🇫"),

        // Southeast Asia
        Currency(id: "THB", name: "Thai Baht", symbol: "฿", flag: "🇹🇭"),
        Currency(id: "SGD", name: "Singapore Dollar", symbol: "$", flag: "🇸🇬"),
        Currency(id: "MYR", name: "Malaysian Ringgit", symbol: "RM", flag: "🇲🇾"),
        Currency(id: "IDR", name: "Indonesian Rupiah", symbol: "Rp", flag: "🇮🇩"),
        Currency(id: "PHP", name: "Philippine Peso", symbol: "₱", flag: "🇵🇭"),
        Currency(id: "VND", name: "Vietnamese Dong", symbol: "₫", flag: "🇻🇳"),
        Currency(id: "MMK", name: "Myanmar Kyat", symbol: "K", flag: "🇲🇲"),
        Currency(id: "KHR", name: "Cambodian Riel", symbol: "៛", flag: "🇰🇭"),
        Currency(id: "LAK", name: "Lao Kip", symbol: "₭", flag: "🇱🇦"),
        Currency(id: "BND", name: "Brunei Dollar", symbol: "$", flag: "🇧🇳"),

        // East Asia
        Currency(id: "KRW", name: "South Korean Won", symbol: "₩", flag: "🇰🇷"),
        Currency(id: "TWD", name: "Taiwan Dollar", symbol: "NT$", flag: "🇹🇼"),
        Currency(id: "HKD", name: "Hong Kong Dollar", symbol: "$", flag: "🇭🇰"),
        Currency(id: "MOP", name: "Macanese Pataca", symbol: "MOP$", flag: "🇲🇴"),
        Currency(id: "MNT", name: "Mongolian Tugrik", symbol: "₮", flag: "🇲🇳"),
        Currency(id: "KPW", name: "North Korean Won", symbol: "₩", flag: "🇰🇵"),

        // Central Asia
        Currency(id: "KZT", name: "Kazakhstani Tenge", symbol: "₸", flag: "🇰🇿"),
        Currency(id: "UZS", name: "Uzbekistani Som", symbol: "so'm", flag: "🇺🇿"),
        Currency(id: "TJS", name: "Tajikistani Somoni", symbol: "ЅМ", flag: "🇹🇯"),
        Currency(id: "KGS", name: "Kyrgyzstani Som", symbol: "с", flag: "🇰🇬"),
        Currency(id: "TMT", name: "Turkmenistani Manat", symbol: "m", flag: "🇹🇲"),

        // Oceania
        Currency(id: "AUD", name: "Australian Dollar", symbol: "$", flag: "🇦🇺"),
        Currency(id: "NZD", name: "New Zealand Dollar", symbol: "$", flag: "🇳🇿"),
        Currency(id: "FJD", name: "Fijian Dollar", symbol: "$", flag: "🇫🇯"),
        Currency(id: "PGK", name: "Papua New Guinean Kina", symbol: "K", flag: "🇵🇬"),
        Currency(id: "SBD", name: "Solomon Islands Dollar", symbol: "$", flag: "🇸🇧"),
        Currency(id: "VUV", name: "Vanuatu Vatu", symbol: "Vt", flag: "🇻🇺"),
        Currency(id: "WST", name: "Samoan Tala", symbol: "T", flag: "🇼🇸"),
        Currency(id: "TOP", name: "Tongan Paʻanga", symbol: "T$", flag: "🇹🇴"),
        Currency(id: "XPF", name: "CFP Franc", symbol: "₣", flag: "🇵🇫"),

        // North Africa
        Currency(id: "EGP", name: "Egyptian Pound", symbol: "£", flag: "🇪🇬"),
        Currency(id: "MAD", name: "Moroccan Dirham", symbol: "د.م.", flag: "🇲🇦"),
        Currency(id: "DZD", name: "Algerian Dinar", symbol: "د.ج", flag: "🇩🇿"),
        Currency(id: "TND", name: "Tunisian Dinar", symbol: "د.ت", flag: "🇹🇳"),
        Currency(id: "LYD", name: "Libyan Dinar", symbol: "ل.د", flag: "🇱🇾"),
        Currency(id: "SDG", name: "Sudanese Pound", symbol: "ج.س.", flag: "🇸🇩"),

        // West Africa
        Currency(id: "NGN", name: "Nigerian Naira", symbol: "₦", flag: "🇳🇬"),
        Currency(id: "GHS", name: "Ghanaian Cedi", symbol: "₵", flag: "🇬🇭"),
        Currency(id: "XOF", name: "West African CFA Franc", symbol: "CFA", flag: "🇸🇳"),
        Currency(id: "GMD", name: "Gambian Dalasi", symbol: "D", flag: "🇬🇲"),
        Currency(id: "GNF", name: "Guinean Franc", symbol: "FG", flag: "🇬🇳"),
        Currency(id: "SLL", name: "Sierra Leonean Leone", symbol: "Le", flag: "🇸🇱"),
        Currency(id: "LRD", name: "Liberian Dollar", symbol: "$", flag: "🇱🇷"),
        Currency(id: "CVE", name: "Cape Verdean Escudo", symbol: "$", flag: "🇨🇻"),
        Currency(id: "MRU", name: "Mauritanian Ouguiya", symbol: "UM", flag: "🇲🇷"),

        // Central Africa
        Currency(id: "XAF", name: "Central African CFA Franc", symbol: "FCFA", flag: "🇨🇲"),
        Currency(id: "CDF", name: "Congolese Franc", symbol: "FC", flag: "🇨🇩"),
        Currency(id: "AOA", name: "Angolan Kwanza", symbol: "Kz", flag: "🇦🇴"),
        Currency(id: "STN", name: "São Tomé Dobra", symbol: "Db", flag: "🇸🇹"),

        // East Africa
        Currency(id: "KES", name: "Kenyan Shilling", symbol: "KSh", flag: "🇰🇪"),
        Currency(id: "TZS", name: "Tanzanian Shilling", symbol: "TSh", flag: "🇹🇿"),
        Currency(id: "UGX", name: "Ugandan Shilling", symbol: "USh", flag: "🇺🇬"),
        Currency(id: "RWF", name: "Rwandan Franc", symbol: "FRw", flag: "🇷🇼"),
        Currency(id: "BIF", name: "Burundian Franc", symbol: "FBu", flag: "🇧🇮"),
        Currency(id: "ETB", name: "Ethiopian Birr", symbol: "Br", flag: "🇪🇹"),
        Currency(id: "DJF", name: "Djiboutian Franc", symbol: "Fdj", flag: "🇩🇯"),
        Currency(id: "ERN", name: "Eritrean Nakfa", symbol: "Nfk", flag: "🇪🇷"),
        Currency(id: "SOS", name: "Somali Shilling", symbol: "S", flag: "🇸🇴"),
        Currency(id: "SSP", name: "South Sudanese Pound", symbol: "£", flag: "🇸🇸"),

        // Southern Africa
        Currency(id: "ZAR", name: "South African Rand", symbol: "R", flag: "🇿🇦"),
        Currency(id: "BWP", name: "Botswana Pula", symbol: "P", flag: "🇧🇼"),
        Currency(id: "NAD", name: "Namibian Dollar", symbol: "$", flag: "🇳🇦"),
        Currency(id: "SZL", name: "Swazi Lilangeni", symbol: "L", flag: "🇸🇿"),
        Currency(id: "LSL", name: "Lesotho Loti", symbol: "L", flag: "🇱🇸"),
        Currency(id: "ZMW", name: "Zambian Kwacha", symbol: "ZK", flag: "🇿🇲"),
        Currency(id: "MWK", name: "Malawian Kwacha", symbol: "MK", flag: "🇲🇼"),
        Currency(id: "ZWL", name: "Zimbabwean Dollar", symbol: "$", flag: "🇿🇼"),
        Currency(id: "MZN", name: "Mozambican Metical", symbol: "MT", flag: "🇲🇿"),
        Currency(id: "MGA", name: "Malagasy Ariary", symbol: "Ar", flag: "🇲🇬"),
        Currency(id: "MUR", name: "Mauritian Rupee", symbol: "₨", flag: "🇲🇺"),
        Currency(id: "SCR", name: "Seychellois Rupee", symbol: "₨", flag: "🇸🇨"),
        Currency(id: "KMF", name: "Comorian Franc", symbol: "CF", flag: "🇰🇲"),

        // Special Territories
        Currency(id: "GIP", name: "Gibraltar Pound", symbol: "£", flag: "🇬🇮"),
        Currency(id: "SHP", name: "Saint Helena Pound", symbol: "£", flag: "🇸🇭"),
        Currency(id: "BMD", name: "Bermudian Dollar", symbol: "$", flag: "🇧🇲"),
        Currency(id: "FOK", name: "Faroese Króna", symbol: "kr", flag: "🇫🇴"),
        Currency(id: "IMP", name: "Isle of Man Pound", symbol: "£", flag: "🇮🇲"),
        Currency(id: "JEP", name: "Jersey Pound", symbol: "£", flag: "🇯🇪"),
        Currency(id: "GGP", name: "Guernsey Pound", symbol: "£", flag: "🇬🇬")
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
            // Major World Currencies
            "USD": 1.0, "EUR": 0.92, "GBP": 0.79, "JPY": 149.50, "CNY": 7.24, "CHF": 0.88,

            // North America
            "CAD": 1.36, "MXN": 17.15,

            // Central America & Caribbean
            "GTQ": 7.82, "HNL": 24.70, "NIO": 36.50, "CRC": 530.0, "PAB": 1.0,
            "BZD": 2.0, "JMD": 155.0, "TTD": 6.78, "BBD": 2.0, "BSD": 1.0,
            "KYD": 0.83, "XCD": 2.70, "DOP": 57.0, "HTG": 132.0, "CUP": 24.0,
            "AWG": 1.79, "ANG": 1.79,

            // South America
            "BRL": 4.97, "ARS": 350.0, "CLP": 880.0, "COP": 4050.0, "PEN": 3.72,
            "UYU": 39.0, "PYG": 7280.0, "BOB": 6.91, "VES": 36.0, "GYD": 209.0,
            "SRD": 38.0, "FKP": 0.79,

            // Western Europe
            "NOK": 10.85, "SEK": 10.45, "DKK": 6.88, "ISK": 138.0,

            // Eastern Europe
            "PLN": 4.02, "CZK": 22.50, "HUF": 355.0, "RON": 4.58, "BGN": 1.80,
            "UAH": 37.0, "RUB": 89.50, "BYN": 3.27, "MDL": 17.80, "RSD": 108.0,
            "BAM": 1.80, "HRK": 6.95, "MKD": 57.0, "ALL": 95.0, "GEL": 2.70,
            "AMD": 405.0, "AZN": 1.70,

            // Middle East
            "TRY": 28.90, "ILS": 3.68, "AED": 3.67, "SAR": 3.75, "QAR": 3.64,
            "KWD": 0.31, "BHD": 0.38, "OMR": 0.39, "JOD": 0.71, "LBP": 89500.0,
            "SYP": 13000.0, "IQD": 1310.0, "IRR": 42000.0, "YER": 250.0,

            // South Asia
            "INR": 83.12, "PKR": 278.0, "BDT": 110.0, "LKR": 325.0, "NPR": 133.0,
            "BTN": 83.0, "MVR": 15.40, "AFN": 70.0,

            // Southeast Asia
            "THB": 35.20, "SGD": 1.34, "MYR": 4.68, "IDR": 15650.0, "PHP": 55.80,
            "VND": 24350.0, "MMK": 2100.0, "KHR": 4100.0, "LAK": 20500.0, "BND": 1.34,

            // East Asia
            "KRW": 1298.0, "TWD": 31.50, "HKD": 7.82, "MOP": 8.05, "MNT": 3450.0,
            "KPW": 900.0,

            // Central Asia
            "KZT": 450.0, "UZS": 12300.0, "TJS": 10.95, "KGS": 89.0, "TMT": 3.50,

            // Oceania
            "AUD": 1.53, "NZD": 1.64, "FJD": 2.25, "PGK": 3.75, "SBD": 8.45,
            "VUV": 119.0, "WST": 2.75, "TOP": 2.36, "XPF": 110.0,

            // North Africa
            "EGP": 30.90, "MAD": 10.0, "DZD": 135.0, "TND": 3.10, "LYD": 4.85,
            "SDG": 600.0,

            // West Africa
            "NGN": 800.0, "GHS": 12.0, "XOF": 605.0, "GMD": 67.0, "GNF": 8600.0,
            "SLL": 22500.0, "LRD": 188.0, "CVE": 102.0, "MRU": 39.5,

            // Central Africa
            "XAF": 605.0, "CDF": 2750.0, "AOA": 830.0, "STN": 22.5,

            // East Africa
            "KES": 155.0, "TZS": 2500.0, "UGX": 3800.0, "RWF": 1250.0, "BIF": 2850.0,
            "ETB": 56.0, "DJF": 178.0, "ERN": 15.0, "SOS": 570.0, "SSP": 950.0,

            // Southern Africa
            "ZAR": 18.65, "BWP": 13.60, "NAD": 18.65, "SZL": 18.65, "LSL": 18.65,
            "ZMW": 25.0, "MWK": 1680.0, "ZWL": 6500.0, "MZN": 63.5, "MGA": 4500.0,
            "MUR": 45.0, "SCR": 13.50, "KMF": 455.0,

            // Special Territories
            "GIP": 0.79, "SHP": 0.79, "BMD": 1.0, "FOK": 6.88, "IMP": 0.79,
            "JEP": 0.79, "GGP": 0.79
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
