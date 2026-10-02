import SwiftUI
import StoreKit

struct SettingsView: View {
    @EnvironmentObject var exchangeRateManager: ExchangeRateManager
    @EnvironmentObject var storeManager: StoreManager
    @EnvironmentObject var currencyManager: CurrencyManager
    @EnvironmentObject var locationDetector: LocationCurrencyDetector
    @Binding var selectedTab: Int
    @State private var showingHomePicker = false

    var body: some View {
        NavigationView {
            List {
                // Home currency and location
                Section {
                    Button(action: { showingHomePicker = true }) {
                        HStack {
                            Label("Home currency", systemImage: "house")
                                .foregroundColor(AppTheme.primaryText)
                            Spacer()
                            Text("\(currencyManager.homeCurrency.flag) \(currencyManager.homeCurrency.code)")
                                .foregroundColor(AppTheme.secondaryText)
                        }
                    }

                    if locationDetector.isAuthorized {
                        HStack {
                            Label("Detect local currency", systemImage: "location")
                            Spacer()
                            Image(systemName: "checkmark")
                                .foregroundColor(AppTheme.gold)
                        }
                    } else if locationDetector.status == .notDetermined {
                        Button(action: {
                            locationDetector.requestPermission {
                                locationDetector.detectCountry { currencyManager.applyDetectedCountry($0) }
                            }
                        }) {
                            Label("Detect local currency", systemImage: "location")
                        }
                    } else {
                        Button(action: {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Label("Turn on location in Settings", systemImage: "location.slash")
                        }
                    }
                }
                .listRowBackground(AppTheme.secondaryBackground)
                .sheet(isPresented: $showingHomePicker) {
                    CurrencyListView(selectedCurrency: Binding(
                        get: { currencyManager.homeCurrency },
                        set: { currencyManager.setHomeCurrency($0) }
                    ))
                }

                // Subscription Section
                Section {
                    if storeManager.isPro {
                        HStack {
                            Label("Pro", systemImage: "star.fill")
                                .foregroundColor(AppTheme.gold)
                            Spacer()
                            Text(storeManager.hasLifetime ? "Lifetime" : "Active")
                                .foregroundColor(.green)
                                .font(.app(15, .medium))
                        }

                        if !storeManager.hasLifetime {
                            Button(action: {
                                Task {
                                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                                        try? await AppStore.showManageSubscriptions(in: windowScene)
                                    }
                                }
                            }) {
                                Label("Manage Subscription", systemImage: "creditcard")
                            }
                        }
                    } else {
                        // Non-subscribers only see this; tapping anything opens the Pro screen.
                        HStack {
                            Label("Pro", systemImage: "star")
                            Spacer()
                            Text("Not subscribed")
                                .foregroundColor(AppTheme.secondaryText)
                        }
                    }
                } header: {
                    Text("Subscription")
                }
                .listRowBackground(AppTheme.secondaryBackground)

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
                                .font(.app(12))
                                .foregroundColor(.red)
                        }
                    }

                    if exchangeRateManager.updateSuccess {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Rates updated successfully")
                                .font(.app(12))
                                .foregroundColor(.green)
                        }
                    }
                } header: {
                    Text("Exchange Rates")
                } footer: {
                    Text("Exchange rates are stored offline and can be updated when you have an internet connection.")
                }
                .listRowBackground(AppTheme.secondaryBackground)

                // About Section
                Section {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")
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
                .listRowBackground(AppTheme.secondaryBackground)

                // Privacy Section
                Section {
                    Label("All data stored locally", systemImage: "lock.shield")
                    Label("No account required", systemImage: "person.crop.circle.badge.xmark")
                    Label("No ads or tracking", systemImage: "hand.raised")
                } header: {
                    Text("Privacy")
                } footer: {
                    Text("Tagwise respects your privacy. Your currency preferences and exchange rates are stored only on your device.")
                }
                .listRowBackground(AppTheme.secondaryBackground)
            }
            // White page like the other screens; square, edge-to-edge grey rows.
            .listStyle(.grouped)
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

