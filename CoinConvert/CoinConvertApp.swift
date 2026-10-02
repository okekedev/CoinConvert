import SwiftUI

@main
struct CoinConvertApp: App {
    @StateObject private var exchangeRateManager = ExchangeRateManager()
    @StateObject private var currencyManager = CurrencyManager()
    @StateObject private var storeManager = StoreManager()
    @StateObject private var locationDetector = LocationCurrencyDetector()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        OnboardingState.skipForExistingUsers()
        // Navigation titles in the app's typeface.
        if let titleFont = UIFont(name: "ChakraPetch-SemiBold", size: 17) {
            UINavigationBar.appearance().titleTextAttributes = [.font: titleFont]
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(exchangeRateManager)
                .environmentObject(currencyManager)
                .environmentObject(storeManager)
                .environmentObject(locationDetector)
                .task {
                    // Update rates once per day on app launch
                    await exchangeRateManager.updateRatesIfNeeded()
                }
                .onChange(of: scenePhase) { _, phase in
                    // Each time the app comes forward, check which country we're in.
                    if phase == .active, UserDefaults.standard.bool(forKey: OnboardingState.key) {
                        locationDetector.detectCountry { currencyManager.applyDetectedCountry($0) }
                    }
                }
        }
    }
}
