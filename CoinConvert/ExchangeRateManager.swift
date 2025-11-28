import Foundation
import Combine

class ExchangeRateManager: ObservableObject {
    @Published var exchangeRates: ExchangeRates
    @Published var isUpdating: Bool = false
    @Published var lastError: String?
    @Published var updateSuccess: Bool = false

    private let storageKey = "com.coinconvert.exchangerates"
    private let userDefaults = UserDefaults.standard

    init() {
        if let data = userDefaults.data(forKey: storageKey),
           let rates = try? JSONDecoder().decode(ExchangeRates.self, from: data) {
            self.exchangeRates = rates
        } else {
            self.exchangeRates = ExchangeRates.defaultRates
        }
    }

    func convert(amount: Double, from source: Currency, to destination: Currency) -> Double? {
        return exchangeRates.convert(amount: amount, from: source.code, to: destination.code)
    }

    func saveRates() {
        if let data = try? JSONEncoder().encode(exchangeRates) {
            userDefaults.set(data, forKey: storageKey)
        }
    }

    func updateRates() async {
        await MainActor.run {
            isUpdating = true
            lastError = nil
            updateSuccess = false
        }

        do {
            let rates = try await fetchRatesFromAPI()
            await MainActor.run {
                self.exchangeRates = rates
                self.saveRates()
                self.isUpdating = false
                self.updateSuccess = true
            }
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.isUpdating = false
            }
        }
    }

    private func fetchRatesFromAPI() async throws -> ExchangeRates {
        let urlString = "https://open.er-api.com/v6/latest/USD"

        guard let url = URL(string: urlString) else {
            throw ExchangeRateError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ExchangeRateError.networkError
        }

        let apiResponse = try JSONDecoder().decode(ExchangeRateAPIResponse.self, from: data)

        let rates: [String: Double]
        let baseCurrency: String

        if let conversionRates = apiResponse.conversion_rates,
           let baseCode = apiResponse.base_code {
            rates = conversionRates
            baseCurrency = baseCode
        } else if let apiRates = apiResponse.rates,
                  let base = apiResponse.base {
            rates = apiRates
            baseCurrency = base
        } else {
            throw ExchangeRateError.invalidData
        }

        return ExchangeRates(
            baseCurrency: baseCurrency,
            rates: rates,
            lastUpdated: Date()
        )
    }

    var ratesAge: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: exchangeRates.lastUpdated, relativeTo: Date())
    }
}

enum ExchangeRateError: LocalizedError {
    case invalidURL
    case networkError
    case invalidData

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid API URL"
        case .networkError: return "Network connection failed"
        case .invalidData: return "Unable to parse exchange rate data"
        }
    }
}
