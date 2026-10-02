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
                    guard phase == .active, UserDefaults.standard.bool(forKey: OnboardingState.key),
                          !ScreenshotDemo.isPro else { return }  // screenshots keep the currencies they're given
                    let detect = { locationDetector.detectCountry { currencyManager.applyDetectedCountry($0) } }
                    // People who updated skipped the onboarding step that asks, so ask once here.
                    let askedKey = "locationAskedAfterUpdate"
                    if locationDetector.status == .notDetermined, !UserDefaults.standard.bool(forKey: askedKey) {
                        UserDefaults.standard.set(true, forKey: askedKey)
                        locationDetector.requestPermission(completion: detect)
                    } else {
                        detect()
                    }
                }
        }
    }
}
