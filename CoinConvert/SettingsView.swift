import SwiftUI
import StoreKit

struct SettingsView: View {
    @EnvironmentObject var exchangeRateManager: ExchangeRateManager
    @EnvironmentObject var storeManager: StoreManager
    @State private var showPaywall = false

    var body: some View {
        NavigationView {
            List {
                // Subscription Section
                Section {
                    if storeManager.isPro {
                        HStack {
                            Label("Pro", systemImage: "star.fill")
                                .foregroundColor(AppTheme.gold)
                            Spacer()
                            Text("Active")
                                .foregroundColor(.green)
                                .font(.subheadline.weight(.medium))
                        }

                        Button(action: {
                            Task {
                                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                                    try? await AppStore.showManageSubscriptions(in: windowScene)
                                }
                            }
                        }) {
                            Label("Manage Subscription", systemImage: "creditcard")
                        }
                    } else {
                        HStack {
                            Label("Free", systemImage: "star")
                            Spacer()
                            Text("Limited")
                                .foregroundColor(AppTheme.secondaryText)
                                .font(.subheadline)
                        }

                        Button(action: {
                            showPaywall = true
                        }) {
                            HStack {
                                Label("Upgrade to Pro", systemImage: "lock.open")
                                    .foregroundColor(AppTheme.gold)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                        }

                        Button(action: {
                            Task {
                                await storeManager.restorePurchases()
                            }
                        }) {
                            HStack {
                                Label("Restore Purchases", systemImage: "arrow.clockwise")
                                Spacer()
                                if storeManager.isLoading {
                                    ProgressView()
                                }
                            }
                        }
                        .disabled(storeManager.isLoading)
                    }
                } header: {
                    Text("Subscription")
                }

                // Exchange Rate Section
                Section {
                    HStack {
                        Label("Last Updated", systemImage: "clock")
                        Spacer()
                        Text(exchangeRateManager.exchangeRates.formattedLastUpdated)
                            .foregroundColor(AppTheme.secondaryText)
                    }

                    Button(action: {
                        Task {
                            await exchangeRateManager.updateRates()
                        }
                    }) {
                        HStack {
                            Label("Update Rates Now", systemImage: "arrow.clockwise")
                            Spacer()
                            if exchangeRateManager.isUpdating {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(exchangeRateManager.isUpdating)

                    if let error = exchangeRateManager.lastError {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }

                    if exchangeRateManager.updateSuccess {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Rates updated successfully")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                } header: {
                    Text("Exchange Rates")
                } footer: {
                    Text("Exchange rates are stored offline and can be updated when you have an internet connection.")
                }

                // About Section
                Section {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(AppTheme.secondaryText)
                    }

                    HStack {
                        Label("Supported Currencies", systemImage: "globe")
                        Spacer()
                        Text("\(Currency.supportedCurrencies.count)")
                            .foregroundColor(AppTheme.secondaryText)
                    }
                } header: {
                    Text("About")
                }

                // Privacy Section
                Section {
                    Label("All data stored locally", systemImage: "lock.shield")
                    Label("No account required", systemImage: "person.crop.circle.badge.xmark")
                    Label("No ads or tracking", systemImage: "hand.raised")
                } header: {
                    Text("Privacy")
                } footer: {
                    Text("CoinConvert respects your privacy. Your currency preferences and exchange rates are stored only on your device.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(storeManager)
        }
    }
}

