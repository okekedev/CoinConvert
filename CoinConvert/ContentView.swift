import SwiftUI

struct ContentView: View {
    @EnvironmentObject var exchangeRateManager: ExchangeRateManager
    @EnvironmentObject var currencyManager: CurrencyManager
    @State private var selectedTab = 0

    // Shared state between tabs
    @State private var capturedAmount: Double?
    @State private var capturedConverted: Double?

    init() {
        // Configure tab bar appearance - white background
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.white

        // Unselected items - gray
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.systemGray]

        // Selected items - gold
        let goldColor = UIColor(red: 212/255, green: 175/255, blue: 55/255, alpha: 1)
        appearance.stackedLayoutAppearance.selected.iconColor = goldColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: goldColor]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            ScannerTab(
                capturedAmount: $capturedAmount,
                capturedConverted: $capturedConverted,
                onCapture: { amount, converted in
                    capturedAmount = amount
                    capturedConverted = converted
                    selectedTab = 1 // Switch to calculator tab
                },
                onContinueToCalculator: {
                    selectedTab = 1 // Switch to calculator tab
                }
            )
            .tabItem {
                Image(systemName: "camera.viewfinder")
                Text("Scan")
            }
            .tag(0)

            CalculatorTab(
                initialAmount: $capturedAmount,
                initialConverted: $capturedConverted
            )
            .tabItem {
                Image(systemName: "plus.forwardslash.minus")
                Text("Calculator")
            }
            .tag(1)

            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(2)
        }
        .tint(AppTheme.gold)
    }
}

// MARK: - Currency Conversion Header (shared between tabs)

struct CurrencyConversionHeader: View {
    @EnvironmentObject var currencyManager: CurrencyManager
    let sourceAmount: Double
    let convertedAmount: Double
    var onSourceTap: (() -> Void)?
    var onDestinationTap: (() -> Void)?

    @State private var showingSourcePicker = false
    @State private var showingDestinationPicker = false

    var body: some View {
        HStack(spacing: 0) {
            // Source currency & amount
            Button(action: {
                showingSourcePicker = true
            }) {
                VStack(spacing: 4) {
                    Text(currencyManager.sourceCurrency.flag)
                        .font(.title)
                    Text(currencyManager.sourceCurrency.code)
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryText)
                    Text(formatCurrency(sourceAmount, currency: currencyManager.sourceCurrency))
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(AppTheme.primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity)
            }
            .sheet(isPresented: $showingSourcePicker) {
                CurrencyListView(selectedCurrency: Binding(
                    get: { currencyManager.sourceCurrency },
                    set: { currencyManager.setSourceCurrency($0) }
                ))
            }

            // Arrow with swap button
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    currencyManager.swapCurrencies()
                }
            }) {
                Image(systemName: "arrow.left.arrow.right.circle.fill")
                    .font(.title)
                    .foregroundColor(AppTheme.gold)
            }

            // Destination currency & amount
            Button(action: {
                showingDestinationPicker = true
            }) {
                VStack(spacing: 4) {
                    Text(currencyManager.destinationCurrency.flag)
                        .font(.title)
                    Text(currencyManager.destinationCurrency.code)
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryText)
                    Text(formatCurrency(convertedAmount, currency: currencyManager.destinationCurrency))
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(AppTheme.gold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity)
            }
            .sheet(isPresented: $showingDestinationPicker) {
                CurrencyListView(selectedCurrency: Binding(
                    get: { currencyManager.destinationCurrency },
                    set: { currencyManager.setDestinationCurrency($0) }
                ))
            }
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadius)
        .shadow(color: AppTheme.shadowColor, radius: AppTheme.shadowRadius, x: 0, y: 4)
    }

    private func formatCurrency(_ amount: Double, currency: Currency) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency.code
        formatter.currencySymbol = currency.symbol
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "\(currency.symbol)\(amount)"
    }
}

// MARK: - Scanner Tab

struct ScannerTab: View {
    @EnvironmentObject var exchangeRateManager: ExchangeRateManager
    @EnvironmentObject var currencyManager: CurrencyManager
    @EnvironmentObject var storeManager: StoreManager

    @Binding var capturedAmount: Double?
    @Binding var capturedConverted: Double?
    var onCapture: (Double, Double?) -> Void
    var onContinueToCalculator: () -> Void

    @State private var isScanning = true
    @State private var scannedAmount: Double?
    @State private var convertedAmount: Double?
    @State private var showPaywall = false
    @State private var showPurchaseError = false
    @State private var purchaseErrorMessage = ""
    @State private var showProductLoadError = false

    // Secret unlock sequence: Left button 4 times
    @State private var secretTapCount: Int = 0
    private let requiredTaps = 4

    var body: some View {
        NavigationView {
            Group {
                if storeManager.isPro {
                    // Pro user - show scanner
                    scannerContent
                } else {
                    // Free user - show locked view with subscription
                    lockedScannerView
                }
            }
            .background(AppTheme.background)
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showPaywall) {
            PaywallView(onContinueToCalculator: onContinueToCalculator)
                .environmentObject(storeManager)
        }
        .onChange(of: scannedAmount) { _, newValue in
            if let amount = newValue {
                convertedAmount = exchangeRateManager.convert(
                    amount: amount,
                    from: currencyManager.sourceCurrency,
                    to: currencyManager.destinationCurrency
                )
            }
        }
        .onChange(of: currencyManager.sourceCurrency) { _, _ in
            if let amount = scannedAmount {
                convertedAmount = exchangeRateManager.convert(
                    amount: amount,
                    from: currencyManager.sourceCurrency,
                    to: currencyManager.destinationCurrency
                )
            }
        }
        .onChange(of: currencyManager.destinationCurrency) { _, _ in
            if let amount = scannedAmount {
                convertedAmount = exchangeRateManager.convert(
                    amount: amount,
                    from: currencyManager.sourceCurrency,
                    to: currencyManager.destinationCurrency
                )
            }
        }
    }

    // MARK: - Scanner Content (Pro users)
    private var scannerContent: some View {
        VStack(spacing: 0) {
            // Currency conversion header
            CurrencyConversionHeader(
                sourceAmount: scannedAmount ?? 0,
                convertedAmount: convertedAmount ?? 0
            )
            .padding(.horizontal)
            .padding(.top, 8)

            // Camera view
            ScannerView(
                scannedAmount: $scannedAmount,
                convertedAmount: $convertedAmount,
                isActive: isScanning
            )
            .cornerRadius(AppTheme.cornerRadius)
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 16)

            // Bottom controls - side by side buttons
            HStack(spacing: 12) {
                // Pause/Resume button
                stopButton

                // Use in Calculator button
                Button(action: {
                    if let amount = scannedAmount {
                        onCapture(amount, convertedAmount)
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.right.circle.fill")
                        Text("Calculator")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: scannedAmount != nil
                                ? [AppTheme.blue, AppTheme.darkBlue]
                                : [Color.gray.opacity(0.5), Color.gray.opacity(0.4)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(AppTheme.cornerRadius)
                    .shadow(color: AppTheme.shadowColor, radius: 4, x: 0, y: 2)
                }
                .disabled(scannedAmount == nil)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Locked Scanner View (Free users)
    private var lockedScannerView: some View {
        ZStack {
            // Falling flags background
            FallingFlagsView()
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer().frame(height: 40)

                    // App logo
                    AppLogoView()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)

                    // Title and description
                    VStack(spacing: 8) {
                        Text("Price Scanner")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(AppTheme.primaryText)

                        Text("Point your camera at any price tag\nand instantly convert currencies")
                            .font(.system(size: 16))
                            .foregroundColor(AppTheme.secondaryText)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }

                    // Feature highlights
                    VStack(alignment: .leading, spacing: 14) {
                        LockedFeatureRow(icon: "camera.fill", text: "Real-time camera scanning")
                        LockedFeatureRow(icon: "text.viewfinder", text: "Automatic price detection")
                        LockedFeatureRow(icon: "bolt.fill", text: "Instant currency conversion")
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 8)

                    // Subscription section
                    if let product = storeManager.products.first {
                        VStack(spacing: 8) {
                            Text("7-Day Free Trial")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(AppTheme.primaryText)

                            Text("Then \(product.displayPrice)/month")
                                .font(.system(size: 15))
                                .foregroundColor(AppTheme.secondaryText)

                            Text("Cancel anytime")
                                .font(.system(size: 13))
                                .foregroundColor(AppTheme.secondaryText.opacity(0.7))
                        }
                        .padding(.top, 8)

                        // Subscribe button
                        Button(action: {
                            Task {
                                do {
                                    _ = try await storeManager.purchase(product)
                                } catch {
                                    purchaseErrorMessage = "Unable to complete purchase. Please try again."
                                    showPurchaseError = true
                                }
                            }
                        }) {
                            Group {
                                if storeManager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Start Free Trial")
                                        .font(.system(size: 18, weight: .bold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [AppTheme.gold, AppTheme.darkGold],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .cornerRadius(AppTheme.cornerRadius)
                            .shadow(color: AppTheme.shadowColor, radius: 6, x: 0, y: 3)
                        }
                        .padding(.horizontal, 40)
                        .disabled(storeManager.isLoading)
                    } else if showProductLoadError {
                        VStack(spacing: 12) {
                            Text("Unable to load subscription")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(AppTheme.secondaryText)

                            Button(action: {
                                showProductLoadError = false
                                Task {
                                    await storeManager.loadProducts()
                                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                                    if storeManager.products.isEmpty {
                                        showProductLoadError = true
                                    }
                                }
                            }) {
                                Text("Retry")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        LinearGradient(
                                            colors: [AppTheme.gold, AppTheme.darkGold],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .cornerRadius(AppTheme.cornerRadius)
                            }
                            .padding(.horizontal, 40)
                        }
                    } else {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.gold))
                            .onAppear {
                                Task {
                                    try? await Task.sleep(nanoseconds: 5_000_000_000)
                                    if storeManager.products.isEmpty {
                                        showProductLoadError = true
                                    }
                                }
                            }
                    }

                    // Restore purchases
                    Button(action: {
                        Task {
                            await storeManager.restorePurchases()
                        }
                    }) {
                        Text("Restore Purchases")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    .disabled(storeManager.isLoading)

                    // Privacy & Terms links
                    HStack(spacing: 12) {
                        Link("Privacy Policy", destination: URL(string: "https://okekedev.github.io/CoinConvert/privacy.html")!)
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.secondaryText.opacity(0.7))

                        Text("•")
                            .foregroundColor(AppTheme.secondaryText.opacity(0.5))

                        Link("Terms of Use", destination: URL(string: "https://okekedev.github.io/CoinConvert/terms.html")!)
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.secondaryText.opacity(0.7))
                    }

                    // Continue to calculator button
                    Button(action: {
                        onContinueToCalculator()
                    }) {
                        HStack(spacing: 8) {
                            Text("Continue to Calculator")
                                .font(.system(size: 16, weight: .medium))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(AppTheme.blue)
                    }
                    .padding(.top, 8)

                    // Secret unlock dots
                    HStack(spacing: 24) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(AppTheme.blue)
                                .frame(width: 10, height: 10)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    handleSecretTap(index)
                                }
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
        }
        .alert("Purchase Error", isPresented: $showPurchaseError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(purchaseErrorMessage)
        }
    }

    // MARK: - Secret Unlock Handler
    private func handleSecretTap(_ dotIndex: Int) {
        // Only count taps on the left dot (index 0)
        if dotIndex == 0 {
            secretTapCount += 1

            // Check if we reached required taps
            if secretTapCount >= requiredTaps {
                // Correct sequence - unlock with haptic feedback!
                let impactMedium = UIImpactFeedbackGenerator(style: .medium)
                impactMedium.impactOccurred()

                // Set secret unlock in store manager and update pro status
                storeManager.secretUnlocked = true
                Task {
                    await storeManager.updateProStatus()
                }
                secretTapCount = 0
            }
        } else {
            // Wrong dot tapped, reset count
            secretTapCount = 0
        }
    }

    private var stopButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3)) {
                isScanning.toggle()
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: isScanning ? "pause.fill" : "play.fill")
                Text(isScanning ? "Pause" : "Resume")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [AppTheme.gold, AppTheme.darkGold],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(AppTheme.cornerRadius)
            .shadow(color: AppTheme.shadowColor, radius: 4, x: 0, y: 2)
        }
    }
}

// MARK: - Locked Feature Row
struct LockedFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AppTheme.gold)
                .frame(width: 24)

            Text(text)
                .font(.system(size: 15))
                .foregroundColor(AppTheme.secondaryText)

            Spacer()
        }
    }
}

// MARK: - Calculator Tab

struct CalculatorTab: View {
    @EnvironmentObject var exchangeRateManager: ExchangeRateManager
    @EnvironmentObject var currencyManager: CurrencyManager

    @Binding var initialAmount: Double?
    @Binding var initialConverted: Double?

    @State private var calculatorDisplay = "0"
    @State private var calculatorResult: Double?
    @State private var convertedAmount: Double?

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Spacer()

                // Conversion header
                CurrencyConversionHeader(
                    sourceAmount: calculatorResult ?? 0,
                    convertedAmount: convertedAmount ?? 0
                )
                .padding(.horizontal)
                .padding(.bottom, 16)

                // Calculator
                CalculatorView(
                    displayValue: $calculatorDisplay,
                    calculatedResult: $calculatorResult,
                    onResultChanged: { value in
                        updateConversion(from: value)
                    }
                )
                .padding(.horizontal)

                Spacer()
            }
            .background(AppTheme.background)
            .navigationTitle("Calculator")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onChange(of: initialAmount) { _, newValue in
            if let amount = newValue {
                calculatorDisplay = formatNumber(amount)
                calculatorResult = amount
                convertedAmount = initialConverted
                initialAmount = nil
                initialConverted = nil
            }
        }
        .onChange(of: currencyManager.sourceCurrency) { _, _ in
            updateConversion(from: calculatorResult ?? 0)
        }
        .onChange(of: currencyManager.destinationCurrency) { _, _ in
            updateConversion(from: calculatorResult ?? 0)
        }
        .onAppear {
            if let amount = initialAmount {
                calculatorDisplay = formatNumber(amount)
                calculatorResult = amount
                convertedAmount = initialConverted
                initialAmount = nil
                initialConverted = nil
            }
        }
    }

    private func updateConversion(from value: Double) {
        convertedAmount = exchangeRateManager.convert(
            amount: value,
            from: currencyManager.sourceCurrency,
            to: currencyManager.destinationCurrency
        )
    }

    private func formatNumber(_ number: Double) -> String {
        if number.truncatingRemainder(dividingBy: 1) == 0 && abs(number) < 1e10 {
            return String(format: "%.0f", number)
        }
        return String(format: "%.2f", number)
    }
}
