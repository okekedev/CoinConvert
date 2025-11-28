import SwiftUI

@main
struct CoinConvertApp: App {
    @StateObject private var exchangeRateManager = ExchangeRateManager()
    @StateObject private var currencyManager = CurrencyManager()
    @StateObject private var storeManager = StoreManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(exchangeRateManager)
                .environmentObject(currencyManager)
                .environmentObject(storeManager)
                .task {
                    // Update rates once per day on app launch
                    await exchangeRateManager.updateRatesIfNeeded()
                }
        }
    }
}
