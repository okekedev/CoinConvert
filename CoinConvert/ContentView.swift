import SwiftUI
import StoreKit

struct ContentView: View {
    @EnvironmentObject var exchangeRateManager: ExchangeRateManager
    @EnvironmentObject var currencyManager: CurrencyManager
    @EnvironmentObject var storeManager: StoreManager
    // Calculator is the home screen. Launch arg `-initialTab N` opens another tab for screenshots.
    @State private var selectedTab = UserDefaults.standard.integer(forKey: "initialTab")

    // Shared state between tabs
    @State private var capturedAmount: Double?
    @State private var capturedConverted: Double?
    @AppStorage(OnboardingState.key) private var hasOnboarded = false

    var body: some View {
        TabView(selection: $selectedTab) {
            CalculatorTab(
                initialAmount: $capturedAmount,
                initialConverted: $capturedConverted
            )
            .toolbar(.hidden, for: .tabBar)
            .safeAreaPadding(.bottom, AppTabBar.reservedHeight)
            .tag(AppTab.calculator)

            ScannerTab(
                onContinueToCalculator: {
                    selectedTab = AppTab.calculator
                }
            )
            .toolbar(.hidden, for: .tabBar)
            .safeAreaPadding(.bottom, AppTabBar.reservedHeight)
            .tag(AppTab.scan)

            SettingsView(selectedTab: $selectedTab)
                .toolbar(.hidden, for: .tabBar)
                .safeAreaPadding(.bottom, AppTabBar.reservedHeight)
                .tag(AppTab.settings)
        }
        // Custom bar: icons only, in the app's navy and gold. Each tab reserves
        // room for it with safeAreaPadding so nothing sits underneath.
        .overlay(alignment: .bottom) {
            AppTabBar(selection: $selectedTab)
        }
        .tint(AppTheme.gold)
        .fullScreenCover(isPresented: Binding(get: { !hasOnboarded }, set: { hasOnboarded = !$0 })) {
            OnboardingView {
                // Start on the free pair so the scanner works right away.
                if !storeManager.isPro {
                    currencyManager.selectFreeScanPair()
                }
                // Onboarding ends on the camera, so land where it works.
                selectedTab = AppTab.scan
                hasOnboarded = true
            }
            .environmentObject(exchangeRateManager)
        }
    }
}

// MARK: - Tab Bar

/// Tab indices, in the order shown in the bar.
enum AppTab {
    static let calculator = 0
    static let scan = 1
    static let settings = 2
}

/// Floating navy capsule with icon-only tabs; the selected one sits in a gold circle.
struct AppTabBar: View {
    @Binding var selection: Int

    /// Bar height (66) plus its bottom gap, reserved at the bottom of every tab.
    static let reservedHeight: CGFloat = 74

    private let tabs: [(icon: String, label: String)] = [
        ("plus.forwardslash.minus", "Calculator"),
        ("camera.viewfinder", "Scan"),
        ("gearshape.fill", "Settings"),
    ]

    var body: some View {
        HStack(spacing: 28) {
            ForEach(tabs.indices, id: \.self) { index in
                let isSelected = selection == index
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { selection = index }
                }) {
                    Image(systemName: tabs[index].icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(isSelected ? AppTheme.darkBlue : .white.opacity(0.65))
                        .frame(width: 50, height: 50)
                        .background(Circle().fill(isSelected ? AppTheme.gold : .clear))
                }
                .accessibilityLabel(tabs[index].label)
                .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(AppTheme.darkBlue, in: Capsule())
        .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 4)
        .padding(.bottom, 4)
    }
}

// MARK: - Currency Conversion Header (shared between tabs)

struct CurrencyConversionHeader: View {
    @EnvironmentObject var currencyManager: CurrencyManager
    let sourceAmount: Double
    let convertedAmount: Double
    var onSourceTap: (() -> Void)?
    var onDestinationTap: (() -> Void)?
    /// Override what happens when a currency is picked (e.g. to gate it behind Pro).
    var selectSource: ((Currency) -> Void)?
    var selectDestination: ((Currency) -> Void)?

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
                    set: { selectSource?($0) ?? currencyManager.setSourceCurrency($0) }
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
                    set: { selectDestination?($0) ?? currencyManager.setDestinationCurrency($0) }
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

    var onContinueToCalculator: () -> Void

    @State private var isScanning = true
    @State private var scannedAmount: Double?
    @State private var convertedAmount: Double?
    @State private var showPurchaseError = false
    @State private var purchaseErrorMessage = ""
    @State private var showProductLoadError = false
    @State private var selectedProductID = StoreManager.monthlyID
    @State private var trialEligibleIDs: Set<String> = []
    @State private var showExitOffer = false
    @State private var showPaywallSheet = false
    @State private var afterExitOffer: (() -> Void)?
    @Environment(\.requestReview) private var requestReview
    @AppStorage("exitOfferLastShown") private var exitOfferLastShown: Double = 0

    // Secret unlock sequence: Left button 4 times
    @State private var secretTapCount: Int = 0
    private let requiredTaps = 4

    var body: some View {
        NavigationView {
            Group {
                if storeManager.isPro || currencyManager.isFreeScanPair {
                    // Pro user, or free user on the free GBP <-> AUD pair
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
        .onChange(of: scannedAmount) { _, newValue in
            if let amount = newValue {
                convertedAmount = exchangeRateManager.convert(
                    amount: amount,
                    from: currencyManager.sourceCurrency,
                    to: currencyManager.destinationCurrency
                )
                if ReviewPrompt.recordSuccessfulScan() {
                    requestReview()
                }
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
        .sheet(isPresented: $showPaywallSheet, onDismiss: {
            if !storeManager.isPro { continueOrShowExitOffer() }
        }) {
            paywallView(inSheet: true)
                .onChange(of: storeManager.isPro) { _, isPro in
                    if isPro { showPaywallSheet = false }
                }
        }
        .sheet(isPresented: $showExitOffer, onDismiss: {
            if !storeManager.isPro { afterExitOffer?() }
            afterExitOffer = nil
        }) {
            if let regular = storeManager.lifetimeProduct, let offer = storeManager.lifetimeOfferProduct {
                ExitOfferView(regular: regular, offer: offer) {
                    Task {
                        do {
                            if try await storeManager.purchase(offer) { showExitOffer = false }
                        } catch {
                            purchaseErrorMessage = "Unable to complete purchase. Please try again."
                            showPurchaseError = true
                        }
                    }
                } onDecline: {
                    showExitOffer = false
                }
                .environmentObject(storeManager)
            }
        }
        .alert("Purchase Error", isPresented: $showPurchaseError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(purchaseErrorMessage)
        }
    }

    // MARK: - Scanner Content (Pro users)
    private var scannerContent: some View {
        VStack(spacing: 14) {
            // Big result on top; the camera only needs to fit the price
            ScanReadout(
                sourceAmount: scannedAmount,
                convertedAmount: convertedAmount,
                selectSource: { selectScanCurrency($0, isSource: true) },
                selectDestination: { selectScanCurrency($0, isSource: false) }
            )
            .frame(height: 240)

            ScannerView(
                scannedAmount: $scannedAmount,
                convertedAmount: $convertedAmount,
                isActive: isScanning
            )
            .frame(minHeight: 300)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }

    // MARK: - Paywall
    /// Shown inline when a free user's pair isn't GBP <-> AUD (e.g. changed in the
    /// calculator), and as a sheet when they pick another currency in the scanner.
    private var lockedScannerView: some View { paywallView(inSheet: false) }

    private func paywallView(inSheet: Bool) -> some View {
        ZStack {
            // Falling flags background
            FallingFlagsView()
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    Spacer().frame(height: 50)

                    // App logo
                    AppLogoView()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)

                    Text("Unlock every currency")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppTheme.primaryText)
                        .multilineTextAlignment(.center)

                    // Plan picker
                    if let product = selectedProduct {
                        VStack(spacing: 10) {
                            ForEach(storeManager.planProducts, id: \.id) { option in
                                PlanOptionRow(
                                    product: option,
                                    badge: planBadge(for: option),
                                    isSelected: option.id == product.id
                                )
                                .onTapGesture { selectedProductID = option.id }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)

                        // Purchase button
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
                                    Text(purchaseButtonTitle(for: product))
                                        .font(.system(size: 18, weight: .bold))
                                }
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 40)
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
                        .disabled(storeManager.isLoading)

                        Text(purchaseDisclosure(for: product))
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.secondaryText.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    } else if showProductLoadError {
                        VStack(spacing: 16) {
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
                                    .padding(.horizontal, 40)
                                    .padding(.vertical, 14)
                                    .background(
                                        LinearGradient(
                                            colors: [AppTheme.gold, AppTheme.darkGold],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .cornerRadius(AppTheme.cornerRadius)
                            }
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

                    if inSheet {
                        Button("Not now") { showPaywallSheet = false }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppTheme.blue)
                    } else {
                        Button(action: {
                            currencyManager.selectFreeScanPair()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "camera.viewfinder")
                                Text("Scan free with GBP ↔ AUD")
                            }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppTheme.blue)
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
                    .padding(.top, 8)

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
                    .padding(.top, 8)

                    if !inSheet {
                        // Continue to calculator button
                        Button(action: {
                            continueOrShowExitOffer(then: onContinueToCalculator)
                        }) {
                            HStack(spacing: 8) {
                                Text("Continue to Calculator")
                                    .font(.system(size: 16, weight: .medium))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(AppTheme.blue)
                        }
                        .padding(.top, 16)

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
                        .padding(.top, 8)
                        .padding(.bottom, 30)
                    }
                }
            }
        }
        .task(id: storeManager.products.map(\.id)) {
            await loadTrialEligibility()
        }
    }

    // MARK: - Plan Helpers
    private var selectedProduct: Product? {
        storeManager.planProducts.first { $0.id == selectedProductID } ?? storeManager.planProducts.first
    }

    private func planBadge(for product: Product) -> String? {
        switch product.id {
        case StoreManager.monthlyID: return "Most Popular"
        case StoreManager.lifetimeID: return "Best Value"
        default: return nil
        }
    }

    private func trialText(for product: Product) -> String? {
        guard trialEligibleIDs.contains(product.id),
              let offer = product.subscription?.introductoryOffer,
              offer.paymentMode == .freeTrial else { return nil }
        return "\(offer.period.value)-\(offer.period.unit.label) free trial"
    }

    private func purchaseButtonTitle(for product: Product) -> String {
        if product.id == StoreManager.lifetimeID { return "Unlock Forever" }
        return trialText(for: product) == nil ? "Subscribe" : "Start Free Trial"
    }

    private func purchaseDisclosure(for product: Product) -> String {
        guard let period = product.subscription?.subscriptionPeriod else {
            return "One-time purchase of \(product.displayPrice). No subscription."
        }
        let renewal = "\(product.displayPrice)/\(period.unit.label)"
        let lead = trialText(for: product).map { "\($0.capitalizedFirst), then \(renewal)." } ?? "\(renewal)."
        return "\(lead) Renews automatically unless cancelled at least 24 hours before the end of the period. Manage in Settings."
    }

    /// Shows the half-price lifetime offer at most once a day when leaving the paywall,
    /// then runs `next` (if any) once it's dismissed.
    private func continueOrShowExitOffer(then next: (() -> Void)? = nil) {
        let oneDay: TimeInterval = 24 * 60 * 60
        let now = Date().timeIntervalSince1970
        guard storeManager.lifetimeOfferProduct != nil,
              storeManager.lifetimeProduct != nil,
              now - exitOfferLastShown >= oneDay else {
            next?()
            return
        }
        exitOfferLastShown = now
        afterExitOffer = next
        showExitOffer = true
    }

    /// Free users can switch within GBP <-> AUD; any other currency opens the paywall.
    private func selectScanCurrency(_ currency: Currency, isSource: Bool) {
        let other = isSource ? currencyManager.destinationCurrency : currencyManager.sourceCurrency
        guard storeManager.isPro || CurrencyManager.freeScanPair.contains(currency.code) else {
            // Let the picker sheet finish dismissing before presenting the paywall.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { showPaywallSheet = true }
            return
        }
        if currency == other {
            currencyManager.swapCurrencies()
        } else if isSource {
            currencyManager.setSourceCurrency(currency)
        } else {
            currencyManager.setDestinationCurrency(currency)
        }
    }

    private func loadTrialEligibility() async {
        var eligible: Set<String> = []
        for product in storeManager.products {
            if let subscription = product.subscription,
               subscription.introductoryOffer != nil,
               await subscription.isEligibleForIntroOffer {
                eligible.insert(product.id)
            }
        }
        trialEligibleIDs = eligible
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

                // Ensure scanner starts unpaused
                isScanning = true

                secretTapCount = 0
            }
        } else {
            // Wrong dot tapped, reset count
            secretTapCount = 0
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
        VStack(spacing: 14) {
            // Same flag cards as the scanner; every currency is free here.
            ScanReadout(
                sourceAmount: calculatorResult,
                convertedAmount: convertedAmount,
                selectSource: currencyManager.setSourceCurrency,
                selectDestination: currencyManager.setDestinationCurrency,
                locksProCurrencies: false,
                popsOnChange: false
            )
            .frame(height: 150)

            CalculatorView(
                displayValue: $calculatorDisplay,
                calculatedResult: $calculatorResult,
                onResultChanged: { value in
                    updateConversion(from: value)
                }
            )
            .frame(maxHeight: .infinity)
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(AppTheme.background)
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

// MARK: - Falling Item Model
struct FallingItem: Identifiable {
    let id = UUID()
    var symbol: String
    var position: CGPoint
    var size: CGFloat
    var speed: CGFloat
    var opacity: Double
}

// MARK: - Falling Flags Background (Canvas-based for performance)
struct FallingFlagsView: View {
    @State private var items: [FallingItem] = []

    // Currency flags and symbols to display
    private let symbols: [String] = [
        "🇺🇸", "🇪🇺", "🇬🇧", "🇯🇵", "🇨🇦", "🇦🇺", "🇨🇭", "🇨🇳",
        "🇮🇳", "🇧🇷", "🇲🇽", "🇰🇷", "🇸🇬", "🇭🇰", "🇳🇿", "🇸🇪",
        "🇳🇴", "🇩🇰", "🇿🇦", "🇹🇭", "🇵🇭", "🇮🇩", "🇲🇾", "🇻🇳",
        "$", "€", "£", "¥", "₹", "₩", "₽", "₿", "💰", "💵", "💴", "💶", "💷"
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                TimelineView(.animation) { timeline in
                    Canvas { context, size in
                        for item in items {
                            context.opacity = item.opacity
                            context.draw(
                                Text(item.symbol).font(.system(size: item.size)),
                                at: item.position
                            )
                        }
                    }
                    .onChange(of: timeline.date) {
                        updateItems(in: geometry.size)
                    }
                }

                // White gradient overlay for softer look
                LinearGradient(
                    colors: [
                        Color(.systemBackground).opacity(0.15),
                        Color(.systemBackground).opacity(0.05),
                        Color(.systemBackground).opacity(0.15)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .onAppear {
            items = createInitialItems(in: UIScreen.main.bounds.size)
        }
    }

    private func createInitialItems(in size: CGSize) -> [FallingItem] {
        var initialItems: [FallingItem] = []
        for _ in 0..<40 {
            initialItems.append(createItem(in: size, isInitial: true))
        }
        return initialItems
    }

    private func createItem(in size: CGSize, isInitial: Bool = false) -> FallingItem {
        let symbol = symbols.randomElement()!
        let x = CGFloat.random(in: 0...size.width)
        let y = isInitial ? CGFloat.random(in: 0...size.height) : -30
        let itemSize = CGFloat.random(in: 18...35)
        let speed = CGFloat.random(in: 0.8...2.5)
        let opacity = Double.random(in: 0.08...0.18)

        return FallingItem(
            symbol: symbol,
            position: CGPoint(x: x, y: y),
            size: itemSize,
            speed: speed,
            opacity: opacity
        )
    }

    private func updateItems(in size: CGSize) {
        for i in 0..<items.count {
            items[i].position.y += items[i].speed

            // Reset item if it goes off screen
            if items[i].position.y > size.height + 30 {
                items[i] = createItem(in: size)
            }
        }

        // Add new items periodically
        if items.count < 60 && Int.random(in: 0...15) == 0 {
            items.append(createItem(in: size))
        }
    }
}

// MARK: - App Logo View
struct AppLogoView: View {
    var body: some View {
        if let uiImage = UIImage(named: "AppLogo") {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            // Debug: show red box if image fails to load
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.red)
                .overlay(
                    Text("IMG\nFAIL")
                        .font(.caption)
                        .foregroundColor(.white)
                )
        }
    }
}

// MARK: - Review Prompt

/// Asks for a rating after successful scans on 3 different days, then waits
/// 90 days before asking again (Apple also caps the prompt at 3 per year).
enum ReviewPrompt {
    private static let scanDaysKey = "reviewPrompt.scanDays"
    private static let lastAskedKey = "reviewPrompt.lastAsked"
    private static let requiredDays = 3
    private static let cooldown: TimeInterval = 90 * 24 * 60 * 60

    static func recordSuccessfulScan(now: Date = Date()) -> Bool {
        let defaults = UserDefaults.standard
        let today = Calendar.current.startOfDay(for: now).timeIntervalSince1970
        var days = Set(defaults.array(forKey: scanDaysKey) as? [Double] ?? [])
        guard days.insert(today).inserted else { return false }
        defaults.set(Array(days), forKey: scanDaysKey)

        let lastAsked = defaults.double(forKey: lastAskedKey)
        guard days.count >= requiredDays,
              now.timeIntervalSince1970 - lastAsked >= cooldown else { return false }
        defaults.set(now.timeIntervalSince1970, forKey: lastAskedKey)
        defaults.set([Double](), forKey: scanDaysKey)
        return true
    }
}

// MARK: - Exit Offer

struct ExitOfferView: View {
    @EnvironmentObject var storeManager: StoreManager
    let regular: Product
    let offer: Product
    let onPurchase: () -> Void
    let onDecline: () -> Void

    private var percentOff: Int {
        guard regular.price > 0 else { return 0 }
        let ratio = NSDecimalNumber(decimal: offer.price / regular.price).doubleValue
        return Int(((1 - ratio) * 100).rounded())
    }

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Wait — one-time offer")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppTheme.darkGold)

            Text("\(percentOff)% off Lifetime")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(AppTheme.primaryText)

            Text("Unlock camera scanning forever.\nPay once. No subscription.")
                .font(.system(size: 16))
                .foregroundColor(AppTheme.secondaryText)
                .multilineTextAlignment(.center)

            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(regular.displayPrice)
                    .font(.system(size: 22))
                    .strikethrough()
                    .foregroundColor(AppTheme.secondaryText)
                Text(offer.displayPrice)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(AppTheme.primaryText)
            }
            .padding(.top, 8)

            Spacer()

            Button(action: onPurchase) {
                Group {
                    if storeManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Unlock Forever for \(offer.displayPrice)")
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
            }
            .disabled(storeManager.isLoading)
            .padding(.horizontal, 24)

            Text("One-time purchase. No subscription.")
                .font(.system(size: 11))
                .foregroundColor(AppTheme.secondaryText.opacity(0.8))

            Button("No thanks", action: onDecline)
                .font(.system(size: 15))
                .foregroundColor(AppTheme.secondaryText)
                .padding(.bottom, 24)
        }
        .padding(.horizontal)
        .presentationDetents([.large])
    }
}

// MARK: - Plan Option Row

struct PlanOptionRow: View {
    let product: Product
    let badge: String?
    let isSelected: Bool

    private var periodText: String {
        guard let period = product.subscription?.subscriptionPeriod else { return "one time" }
        return "per \(period.unit.label)"
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 22))
                .foregroundColor(isSelected ? AppTheme.gold : AppTheme.secondaryText.opacity(0.5))

            VStack(alignment: .leading, spacing: 2) {
                Text(product.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.primaryText)
                if let badge {
                    Text(badge)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppTheme.darkGold)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(product.displayPrice)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(AppTheme.primaryText)
                Text(periodText)
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.secondaryText)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(AppTheme.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .stroke(isSelected ? AppTheme.gold : AppTheme.secondaryText.opacity(0.2), lineWidth: isSelected ? 2 : 1)
        )
        .cornerRadius(AppTheme.cornerRadius)
        .contentShape(Rectangle())
    }
}

private extension Product.SubscriptionPeriod.Unit {
    var label: String {
        switch self {
        case .day: return "day"
        case .week: return "week"
        case .month: return "month"
        case .year: return "year"
        @unknown default: return "period"
        }
    }
}

private extension String {
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }
}
