import SwiftUI
import StoreKit

struct ContentView: View {
    @EnvironmentObject var exchangeRateManager: ExchangeRateManager
    @EnvironmentObject var currencyManager: CurrencyManager
    @EnvironmentObject var storeManager: StoreManager
    @EnvironmentObject var locationDetector: LocationCurrencyDetector
    // Launch arg `-initialTab N` opens another tab for screenshots.
    @State private var selectedTab = UserDefaults.standard.integer(forKey: "initialTab")
    @State private var converterMode: ConverterTab.Mode = ScreenshotDemo.startsInScan ? .scan : .calculator
    @State private var showPaywall = false
    @AppStorage(OnboardingState.key) private var hasOnboarded = false

    var body: some View {
        Group {
            if storeManager.isPro || storeManager.hasCheckedEntitlements {
                mainTabs
                    // Non-subscribers can see the home screen; any tap asks them to subscribe.
                    .overlay {
                        if !storeManager.isPro {
                            Color.clear
                                .contentShape(Rectangle())
                                .onTapGesture { showPaywall = true }
                                .accessibilityLabel("Subscribe to use Tagwise")
                                .accessibilityAddTraits(.isButton)
                        }
                    }
                    .fullScreenCover(isPresented: $showPaywall) {
                        PaywallView(onClose: { showPaywall = false })
                            .environmentObject(storeManager)
                    }
                    .onChange(of: storeManager.isPro) { _, isPro in
                        if isPro { showPaywall = false }
                    }
                    .onAppear { if ScreenshotDemo.opensPaywall { showPaywall = true } }
            } else {
                // Brief logo while the purchase check runs, so the app doesn't flicker.
                LowPolyLogo(shimmer: false)
                    .frame(width: 96, height: 96)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppTheme.background)
            }
        }
        .font(.app(17))
        .fullScreenCover(isPresented: Binding(get: { !hasOnboarded }, set: { hasOnboarded = !$0 })) {
            OnboardingView {
                selectedTab = AppTab.convert
                hasOnboarded = true
                locationDetector.detectCountry { currencyManager.applyDetectedCountry($0) }
            }
            .environmentObject(exchangeRateManager)
            .environmentObject(currencyManager)
            .environmentObject(locationDetector)
        }
    }

    private var mainTabs: some View {
        VStack(spacing: 0) {
            TabView(selection: $selectedTab) {
                ConverterTab(mode: $converterMode)
                    .toolbar(.hidden, for: .tabBar)
                    .tag(AppTab.convert)

                SettingsView(selectedTab: $selectedTab)
                    .toolbar(.hidden, for: .tabBar)
                    .tag(AppTab.settings)
            }

            // Docked at the bottom like a standard iOS tab bar, in the app's background.
            AppTabBar(selectedTab: $selectedTab, mode: $converterMode)
        }
    }
}

// MARK: - Tab Bar

/// Tab indices, in the order shown in the bar.
enum AppTab {
    static let convert = 0
    static let settings = 1
}

/// Standard docked tab bar with low-poly icons; the selected one is in full color
/// with a gold dot, the others greyed. Calculator and Scan are two modes of the same Convert screen, so the
/// currency cards (and a scanned price) carry across.
struct AppTabBar: View {
    @Binding var selectedTab: Int
    @Binding var mode: ConverterTab.Mode

    private enum Item: CaseIterable {
        case calculator, scan, settings

        var art: LowPolyIcon.Kind {
            switch self {
            case .calculator: return .calculator
            case .scan: return .tag
            case .settings: return .gear
            }
        }

        var label: String {
            switch self {
            case .calculator: return String(localized: "Calculator")
            case .scan: return String(localized: "Scan")
            case .settings: return String(localized: "Settings")
            }
        }
    }

    private func isSelected(_ item: Item) -> Bool {
        switch item {
        case .calculator: return selectedTab == AppTab.convert && mode == .calculator
        case .scan: return selectedTab == AppTab.convert && mode == .scan
        case .settings: return selectedTab == AppTab.settings
        }
    }

    private func select(_ item: Item) {
        switch item {
        case .calculator:
            selectedTab = AppTab.convert
            mode = .calculator
        case .scan:
            selectedTab = AppTab.convert
            mode = .scan
        case .settings:
            selectedTab = AppTab.settings
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.black.opacity(0.08))
                .frame(height: 0.5)

            HStack(spacing: 0) {
                ForEach(Item.allCases, id: \.self) { item in
                    let selected = isSelected(item)
                    Button(action: { select(item) }) {
                        VStack(spacing: 5) {
                            LowPolyIcon(kind: item.art, shimmer: item == .scan)
                                .frame(width: item == .scan ? 42 : 30, height: item == .scan ? 42 : 30)
                                .frame(height: 42)
                                // Unselected tabs sit back in grey, like a standard tab bar.
                                .saturation(selected ? 1 : 0)
                                .opacity(selected ? 1 : 0.45)
                            Rectangle()
                                .fill(AppTheme.gold)
                                .frame(width: 5, height: 5)
                                .opacity(selected ? 1 : 0)
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .animation(.easeOut(duration: 0.2), value: selected)
                    }
                    .accessibilityLabel(item.label)
                    .accessibilityAddTraits(selected ? [.isSelected, .isButton] : .isButton)
                }
            }
            .padding(.vertical, 6)
        }
        .background(AppTheme.background.ignoresSafeArea(edges: .bottom))
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
                        .font(.app(28, .bold))
                    Text(currencyManager.sourceCurrency.code)
                        .font(.app(12))
                        .foregroundColor(AppTheme.secondaryText)
                    Text(formatCurrency(sourceAmount, currency: currencyManager.sourceCurrency))
                        .font(.app(15, .semibold))
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
                    .font(.app(28, .bold))
                    .foregroundColor(AppTheme.gold)
            }

            // Destination currency & amount
            Button(action: {
                showingDestinationPicker = true
            }) {
                VStack(spacing: 4) {
                    Text(currencyManager.destinationCurrency.flag)
                        .font(.app(28, .bold))
                    Text(currencyManager.destinationCurrency.code)
                        .font(.app(12))
                        .foregroundColor(AppTheme.secondaryText)
                    Text(formatCurrency(convertedAmount, currency: currencyManager.destinationCurrency))
                        .font(.app(15, .bold))
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

// MARK: - Converter Tab

/// The main screen: flag cards on top, then the keypad or the camera (switched
/// from the tab bar). Switching from Scan to Calculator carries the scanned
/// price over so you can do math on it.
struct ConverterTab: View {
    enum Mode { case calculator, scan }
    @EnvironmentObject var exchangeRateManager: ExchangeRateManager
    @EnvironmentObject var currencyManager: CurrencyManager

    @Binding var mode: Mode
    @State private var calculatorDisplay = "0"
    @State private var calculatorResult: Double?
    @State private var calculatorConverted: Double?
    @State private var scannedAmount: Double?
    @State private var convertedAmount: Double?
    @Environment(\.requestReview) private var requestReview

    var body: some View {
        VStack(spacing: 12) {
            ScanReadout(
                sourceAmount: mode == .scan ? scannedAmount : calculatorResult,
                convertedAmount: mode == .scan ? convertedAmount : calculatorConverted,
                selectSource: currencyManager.setSourceCurrency,
                selectDestination: currencyManager.setDestinationCurrency,
                popsOnChange: mode == .scan
            )
            .frame(height: 150)

            Group {
                switch mode {
                case .calculator:
                    CalculatorView(
                        displayValue: $calculatorDisplay,
                        calculatedResult: $calculatorResult,
                        onResultChanged: { updateCalculatorConversion(from: $0) }
                    )
                case .scan:
                    ScannerView(scannedAmount: $scannedAmount, convertedAmount: $convertedAmount, isActive: true)
                }
            }
            .frame(maxHeight: .infinity)
            .clipShape(Rectangle())
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(AppTheme.background)
        .onAppear {
            if let value = ScreenshotDemo.calculatorValue {
                calculatorDisplay = formatNumber(value)
                calculatorResult = value
                updateCalculatorConversion(from: value)
            }
        }
        .onChange(of: mode) { _, newMode in
            switch newMode {
            case .calculator:
                // Carry the scanned price into the calculator.
                if let amount = scannedAmount {
                    calculatorDisplay = formatNumber(amount)
                    calculatorResult = amount
                    updateCalculatorConversion(from: amount)
                }
            case .scan:
                scannedAmount = nil
                convertedAmount = nil
            }
        }
        .onChange(of: scannedAmount) { _, newValue in
            if let amount = newValue {
                convertedAmount = convert(amount)
                if ReviewPrompt.recordSuccessfulScan() {
                    requestReview()
                }
            }
        }
        .onChange(of: currencyManager.sourceCurrency) { _, _ in refreshConversions() }
        .onChange(of: currencyManager.destinationCurrency) { _, _ in refreshConversions() }
    }

    private func convert(_ amount: Double) -> Double? {
        exchangeRateManager.convert(amount: amount, from: currencyManager.sourceCurrency, to: currencyManager.destinationCurrency)
    }

    private func refreshConversions() {
        updateCalculatorConversion(from: calculatorResult ?? 0)
        if let amount = scannedAmount {
            convertedAmount = convert(amount)
        }
    }

    private func updateCalculatorConversion(from value: Double) {
        calculatorConverted = convert(value)
    }

    private func formatNumber(_ number: Double) -> String {
        if number.truncatingRemainder(dividingBy: 1) == 0 && abs(number) < 1e10 {
            return String(format: "%.0f", number)
        }
        return String(format: "%.2f", number)
    }
}

// MARK: - Paywall

/// Full-screen Pro screen, opened when a non-subscriber taps anything. Closing it
/// shows the half-price lifetime offer screen; "No thanks" returns to the home screen.
struct PaywallView: View {
    @EnvironmentObject var storeManager: StoreManager
    let onClose: () -> Void

    @State private var showPurchaseError = false
    @State private var purchaseErrorMessage = ""
    @State private var showProductLoadError = false
    @State private var selectedProductID = StoreManager.monthlyID
    @State private var trialEligibleIDs: Set<String> = []
    @State private var showExitOffer = false

    // Secret unlock sequence: left dot 4 times
    @State private var secretTapCount: Int = 0
    private let requiredTaps = 4

    private var exitOfferAvailable: Bool {
        storeManager.lifetimeOfferProduct != nil && storeManager.lifetimeProduct != nil
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            FallingFlagsView()
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    Spacer().frame(height: 40)

                    AppLogoView()
                        .frame(width: 110, height: 110)
                        .clipShape(Rectangle())
                        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)

                    Text("Unlock Tagwise")
                        .font(.app(30, .bold))
                        .foregroundColor(AppTheme.primaryText)

                    plans

                    Button(action: { Task { await storeManager.restorePurchases() } }) {
                        Text("Restore Purchases")
                            .font(.app(14))
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    .disabled(storeManager.isLoading)

                    HStack(spacing: 12) {
                        Link("Privacy Policy", destination: URL(string: "https://okekedev.github.io/CoinConvert/privacy.html")!)
                        Text("•").foregroundColor(AppTheme.secondaryText.opacity(0.5))
                        Link("Terms of Use", destination: URL(string: "https://okekedev.github.io/CoinConvert/terms.html")!)
                    }
                    .font(.app(11))
                    .foregroundColor(AppTheme.secondaryText.opacity(0.7))

                    secretDots
                }
                .frame(maxWidth: .infinity)
            }

            Button(action: close) {
                Image(systemName: "xmark")
                    .font(.app(15, .bold))
                    .foregroundColor(AppTheme.secondaryText)
                    .frame(width: 36, height: 36)
                    .background(AppTheme.secondaryBackground, in: Rectangle())
            }
            .padding(.leading, 16)
            .padding(.top, 8)
            .accessibilityLabel("Close")
        }
        .font(.app(17))
        .background(AppTheme.background)
        .task(id: storeManager.products.map(\.id)) {
            await loadTrialEligibility()
            if ScreenshotDemo.opensOffer && exitOfferAvailable { close() }
        }
        .fullScreenCover(isPresented: $showExitOffer, onDismiss: {
            if !storeManager.isPro { onClose() }
        }) {
            if let regular = storeManager.lifetimeProduct, let offer = storeManager.lifetimeOfferProduct {
                ExitOfferView(regular: regular, offer: offer) {
                    Task {
                        do {
                            if try await storeManager.purchase(offer) { showExitOffer = false }
                        } catch {
                            purchaseErrorMessage = String(localized: "Couldn't complete the purchase. Try again.")
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

    private func close() {
        guard exitOfferAvailable else {
            onClose()
            return
        }
        showExitOffer = true
    }

    @ViewBuilder
    private var plans: some View {
        if let product = selectedProduct {
            VStack(spacing: 10) {
                ForEach(storeManager.planProducts, id: \.id) { option in
                    PlanOptionRow(product: option, badge: planBadge(for: option), isSelected: option.id == product.id)
                        .onTapGesture { selectedProductID = option.id }
                }
            }
            .padding(.horizontal, 24)

            Button(action: {
                Task {
                    do {
                        _ = try await storeManager.purchase(product)
                    } catch {
                        purchaseErrorMessage = String(localized: "Couldn't complete the purchase. Try again.")
                        showPurchaseError = true
                    }
                }
            }) {
                Group {
                    if storeManager.isLoading {
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(purchaseButtonTitle(for: product))
                            .font(.app(18, .bold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(LinearGradient(colors: [AppTheme.gold, AppTheme.darkGold], startPoint: .top, endPoint: .bottom))
                .cornerRadius(AppTheme.cornerRadius)
                .shadow(color: AppTheme.shadowColor, radius: 6, x: 0, y: 3)
            }
            .disabled(storeManager.isLoading)
            .padding(.horizontal, 24)

            Text(purchaseDisclosure(for: product))
                .font(.app(11))
                .foregroundColor(AppTheme.secondaryText.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        } else if showProductLoadError {
            VStack(spacing: 16) {
                Text("Couldn't load plans. Check your connection.")
                    .font(.app(15, .semibold))
                    .foregroundColor(AppTheme.secondaryText)
                Button(action: {
                    showProductLoadError = false
                    Task {
                        await storeManager.loadProducts()
                        try? await Task.sleep(nanoseconds: 3_000_000_000)
                        if storeManager.products.isEmpty { showProductLoadError = true }
                    }
                }) {
                    Text("Try again")
                        .font(.app(17, .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 14)
                        .background(AppTheme.gold)
                        .cornerRadius(AppTheme.cornerRadius)
                }
            }
        } else {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.gold))
                .onAppear {
                    Task {
                        try? await Task.sleep(nanoseconds: 5_000_000_000)
                        if storeManager.products.isEmpty { showProductLoadError = true }
                    }
                }
        }
    }

    private var secretDots: some View {
        HStack(spacing: 24) {
            ForEach(0..<3, id: \.self) { index in
                Rectangle()
                    .fill(AppTheme.blue)
                    .frame(width: 10, height: 10)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                    .onTapGesture { handleSecretTap(index) }
            }
        }
        .padding(.bottom, 30)
    }

    // MARK: Plan helpers

    private var selectedProduct: Product? {
        storeManager.planProducts.first { $0.id == selectedProductID } ?? storeManager.planProducts.first
    }

    private func planBadge(for product: Product) -> String? {
        switch product.id {
        case StoreManager.monthlyID: return String(localized: "Most Popular")
        case StoreManager.lifetimeID: return String(localized: "Best Value")
        default: return nil
        }
    }

    private func trialText(for product: Product) -> String? {
        guard trialEligibleIDs.contains(product.id),
              let offer = product.subscription?.introductoryOffer,
              offer.paymentMode == .freeTrial else { return nil }
        return String(localized: "Free for \(offer.period.durationText)")
    }

    private func purchaseButtonTitle(for product: Product) -> String {
        if product.id == StoreManager.lifetimeID { return String(localized: "Unlock Forever") }
        return trialText(for: product) == nil ? String(localized: "Subscribe") : String(localized: "Start Free Trial")
    }

    private func purchaseDisclosure(for product: Product) -> String {
        guard let period = product.subscription?.subscriptionPeriod else {
            return String(localized: "One-time purchase of \(product.displayPrice). No subscription.")
        }
        let renewal = "\(product.displayPrice) / \(period.unitLabel)"
        let lead = trialText(for: product).map { String(localized: "\($0), then \(renewal).") } ?? "\(renewal)."
        return lead + " " + String(localized: "Auto-renews, cancel anytime.")
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

    private func handleSecretTap(_ dotIndex: Int) {
        // Only taps on the left dot count; any other dot resets.
        guard dotIndex == 0 else {
            secretTapCount = 0
            return
        }
        secretTapCount += 1
        if secretTapCount >= requiredTaps {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            storeManager.secretUnlocked = true
            Task { await storeManager.updateProStatus() }
            secretTapCount = 0
        }
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
        LowPolyLogo()
            .padding(14)
            .background(Color.white)
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
        VStack(spacing: 18) {
            Spacer()

            LowPolyLogo()
                .frame(width: 110, height: 110)

            Text("Wait — one-time offer")
                .font(.app(14, .semibold))
                .foregroundColor(AppTheme.darkGold)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(AppTheme.lightGold.opacity(0.35))

            Text("\(percentOff)% off Lifetime")
                .font(.app(36, .bold))
                .foregroundColor(AppTheme.primaryText)
                .multilineTextAlignment(.center)

            Text("Unlock camera scanning forever.\nPay once. No subscription.")
                .font(.app(16))
                .foregroundColor(AppTheme.secondaryText)
                .multilineTextAlignment(.center)

            // Price card, styled like the plan rows on the Pro screen.
            HStack(alignment: .firstTextBaseline, spacing: 14) {
                Text(regular.displayPrice)
                    .font(.app(22))
                    .strikethrough()
                    .foregroundColor(AppTheme.secondaryText)
                Text(offer.displayPrice)
                    .font(.app(44, .bold))
                    .foregroundColor(AppTheme.primaryText)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 14)
            .overlay(Rectangle().stroke(AppTheme.gold, lineWidth: 2))
            .padding(.top, 6)

            Spacer()

            Button(action: onPurchase) {
                Group {
                    if storeManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Unlock Forever for \(offer.displayPrice)")
                            .font(.app(18, .bold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(LinearGradient(colors: [AppTheme.gold, AppTheme.darkGold], startPoint: .top, endPoint: .bottom))
            }
            .disabled(storeManager.isLoading)
            .padding(.horizontal, 24)

            Text("One-time purchase. No subscription.")
                .font(.app(11))
                .foregroundColor(AppTheme.secondaryText.opacity(0.8))

            Button("No thanks", action: onDecline)
                .font(.app(15))
                .foregroundColor(AppTheme.secondaryText)
                .padding(.bottom, 24)
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.background)
    }
}

// MARK: - Plan Option Row

struct PlanOptionRow: View {
    let product: Product
    let badge: String?
    let isSelected: Bool

    /// Our own plan names (translated), not App Store Connect's display names,
    /// which can't be edited once a subscription is approved.
    private var planName: String {
        switch product.id {
        case StoreManager.weeklyID: return String(localized: "Weekly")
        case StoreManager.monthlyID: return String(localized: "Monthly")
        default: return String(localized: "Lifetime")
        }
    }

    private var periodText: String {
        guard let period = product.subscription?.subscriptionPeriod else { return String(localized: "one time") }
        return String(localized: "per \(period.unitLabel)")
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.app(22))
                .foregroundColor(isSelected ? AppTheme.gold : AppTheme.secondaryText.opacity(0.5))

            VStack(alignment: .leading, spacing: 2) {
                Text(planName)
                    .font(.app(16, .semibold))
                    .foregroundColor(AppTheme.primaryText)
                if let badge {
                    Text(badge)
                        .font(.app(11, .bold))
                        .foregroundColor(AppTheme.darkGold)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(product.displayPrice)
                    .font(.app(17, .bold))
                    .foregroundColor(AppTheme.primaryText)
                Text(periodText)
                    .font(.app(12))
                    .foregroundColor(AppTheme.secondaryText)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(AppTheme.cardBackground)
        .overlay(
            Rectangle()
                .stroke(isSelected ? AppTheme.gold : AppTheme.secondaryText.opacity(0.2), lineWidth: isSelected ? 2 : 1)
        )
        .cornerRadius(AppTheme.cornerRadius)
        .contentShape(Rectangle())
    }
}

private extension Product.SubscriptionPeriod.Unit {
    var label: String {
        switch self {
        case .day: return String(localized: "day")
        case .week: return String(localized: "week")
        case .month: return String(localized: "month")
        case .year: return String(localized: "year")
        @unknown default: return String(localized: "period")
        }
    }
}

private extension Product.SubscriptionPeriod {
    /// Billing unit for "per week" / "$0.99 / week". StoreKit can report a one-week
    /// period as 7 days, so whole weeks of days are shown as weeks.
    var unitLabel: String {
        if unit == .day && value % 7 == 0 { return Unit.week.label }
        return unit.label
    }

    /// "3 days", "1 week" in the user's language.
    var durationText: String {
        var components = DateComponents()
        switch unit {
        case .day: components.day = value
        case .week: components.weekOfMonth = value
        case .month: components.month = value
        case .year: components.year = value
        @unknown default: components.day = value
        }
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        return formatter.string(from: components) ?? "\(value)"
    }
}
