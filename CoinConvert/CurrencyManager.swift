import Foundation
import CoreLocation

class CurrencyManager: ObservableObject {
    @Published var sourceCurrency: Currency
    @Published var destinationCurrency: Currency
    /// What prices get converted into. Set in onboarding; defaults to the phone's region.
    @Published var homeCurrency: Currency
    /// Last country the phone was found in (ISO code), shown in Settings.
    @Published private(set) var detectedCountry: String?

    private let sourceKey = "com.coinconvert.sourcecurrency"
    private let destinationKey = "com.coinconvert.destinationcurrency"
    private let homeKey = "com.coinconvert.homecurrency"
    private let lastCountryKey = "com.coinconvert.lastcountry"
    private let userDefaults = UserDefaults.standard

    init() {
        detectedCountry = UserDefaults.standard.string(forKey: "com.coinconvert.lastcountry")
        if let homeCode = userDefaults.string(forKey: homeKey), let home = Currency.currency(for: homeCode) {
            self.homeCurrency = home
        } else {
            self.homeCurrency = Locale.current.currency.flatMap { Currency.currency(for: $0.identifier) }
                ?? Currency.currency(for: "USD") ?? Currency.supportedCurrencies[0]
        }

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

    /// Sets home and converts into it. If "from" was the same currency, it moves
    /// to something useful so the pair isn't X -> X.
    func setHomeCurrency(_ currency: Currency) {
        homeCurrency = currency
        userDefaults.set(currency.code, forKey: homeKey)
        setDestinationCurrency(currency)
        if sourceCurrency == currency,
           let other = Currency.currency(for: currency.code == "EUR" ? "USD" : "EUR") {
            setSourceCurrency(other)
        }
    }

    /// Called with the country the phone is in. When you arrive somewhere new, the
    /// local currency becomes "from" and home becomes "to". Only acts on a change
    /// of country, so it never overrides a pair you picked yourself.
    func applyDetectedCountry(_ countryCode: String) {
        guard countryCode != userDefaults.string(forKey: lastCountryKey) else { return }
        userDefaults.set(countryCode, forKey: lastCountryKey)
        detectedCountry = countryCode

        guard let local = Self.currency(forCountry: countryCode), local != homeCurrency else { return }
        setSourceCurrency(local)
        setDestinationCurrency(homeCurrency)
    }

    static func currency(forCountry countryCode: String) -> Currency? {
        Locale(identifier: "en_\(countryCode)").currency.flatMap { Currency.currency(for: $0.identifier) }
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

// MARK: - Location

/// Finds which country the phone is in (city-level accuracy is plenty) so the
/// local currency can be picked automatically. Only the country code is used.
final class LocationCurrencyDetector: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var status: CLAuthorizationStatus

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var onCountry: ((String) -> Void)?
    private var onPermissionResolved: (() -> Void)?

    override init() {
        status = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyReduced
    }

    var isAuthorized: Bool {
        status == .authorizedWhenInUse || status == .authorizedAlways
    }

    /// Shows the system prompt if it hasn't been answered; `completion` runs once it is.
    func requestPermission(completion: @escaping () -> Void) {
        guard status == .notDetermined else {
            completion()
            return
        }
        onPermissionResolved = completion
        manager.requestWhenInUseAuthorization()
    }

    /// One-shot lookup; does nothing without permission.
    func detectCountry(_ handler: @escaping (String) -> Void) {
        guard isAuthorized else { return }
        onCountry = handler
        manager.requestLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        status = manager.authorizationStatus
        if status != .notDetermined, let resolved = onPermissionResolved {
            onPermissionResolved = nil
            DispatchQueue.main.async(execute: resolved)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last, let handler = onCountry else { return }
        onCountry = nil
        geocoder.reverseGeocodeLocation(location) { placemarks, _ in
            guard let code = placemarks?.first?.isoCountryCode else { return }
            DispatchQueue.main.async { handler(code) }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        onCountry = nil
    }
}
