import SwiftUI
import AVFoundation

// MARK: - Onboarding State

enum OnboardingState {
    static let key = "hasOnboarded"

    /// People updating from an earlier version already know the app, so skip
    /// onboarding for them. Saved exchange rates only exist after a previous launch.
    static func skipForExistingUsers() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: key) == nil,
           defaults.data(forKey: "com.coinconvert.exchangerates") != nil {
            defaults.set(true, forKey: key)
        }
    }
}

// MARK: - Onboarding

/// What the app does, your home currency (then location, so the local currency
/// is picked when you travel), and camera permission if the system hasn't asked.
struct OnboardingView: View {
    @EnvironmentObject var currencyManager: CurrencyManager
    @EnvironmentObject var locationDetector: LocationCurrencyDetector
    let onFinish: () -> Void

    private enum Step { case demo, home, camera }

    @State private var step = Step.demo
    @State private var showingCurrencyList = false
    /// Ignores a second tap while the next step slides in, so a quick
    /// double tap can't skip a step or hit a permission button by accident.
    @State private var isTransitioning = false

    private let needsCameraStep = AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined
    private var steps: [Step] { needsCameraStep ? [.demo, .home, .camera] : [.demo, .home] }
    private var stepIndex: Int { steps.firstIndex(of: step) ?? 0 }

    var body: some View {
        ZStack {
            OnboardingPalette.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                progress
                    .frame(height: 44)
                    .padding(.top, 8)

                Spacer(minLength: 24)

                Group {
                    switch step {
                    case .demo: PriceTagDemo(homeCurrency: currencyManager.homeCurrency)
                    case .home: homeCurrencyVisual
                    case .camera: cameraVisual
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 300)

                Spacer(minLength: 24)

                VStack(alignment: .leading, spacing: 10) {
                    Text(headline)
                        .font(.app(34, .bold))
                        .foregroundColor(.white)
                    Text(message)
                        .font(.app(17))
                        .foregroundColor(OnboardingPalette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .id(step)
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .opacity))

                Spacer(minLength: 32)

                Button(action: advance) {
                    Text(buttonTitle)
                        .font(.app(18, .bold))
                        .foregroundColor(OnboardingPalette.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(AppTheme.gold)
                }

                Button(action: onFinish) {
                    Text("Not now")
                        .font(.app(16, .medium))
                        .foregroundColor(OnboardingPalette.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .opacity(step == .camera ? 1 : 0)
                .disabled(step != .camera)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 8)
        }
        .font(.app(17))
        .sheet(isPresented: $showingCurrencyList) {
            CurrencyListView(selectedCurrency: Binding(
                get: { currencyManager.homeCurrency },
                set: { currencyManager.setHomeCurrency($0) }
            ))
        }
    }

    // MARK: Pieces

    private var progress: some View {
        HStack(spacing: 6) {
            ForEach(steps.indices, id: \.self) { index in
                Rectangle()
                    .fill(index <= stepIndex ? AppTheme.gold : Color.white.opacity(0.2))
                    .frame(width: index == stepIndex ? 22 : 8, height: 8)
            }
        }
        .animation(.easeOut(duration: 0.25), value: step)
        .accessibilityElement()
        .accessibilityLabel("Step \(stepIndex + 1) of \(steps.count)")
    }

    private var homeCurrencyVisual: some View {
        let home = currencyManager.homeCurrency
        let palette = FlagPalette.palette(for: home.flag)
        return Button(action: { showingCurrencyList = true }) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    Text(home.flag).font(.app(34))
                    Text(home.code)
                        .font(.app(26, .bold))
                    Image(systemName: "chevron.down")
                        .font(.app(15, .bold))
                        .opacity(0.8)
                }
                Spacer()
                Text(home.name)
                    .font(.app(20, .semibold))
            }
            .foregroundColor(.white)
            .padding(22)
            .frame(width: 240, height: 180, alignment: .leading)
            .background(
                LinearGradient(colors: [palette.primary, palette.primaryDeep],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .overlay(alignment: .bottom) { palette.accent.frame(height: 6) }
            .clipShape(Rectangle())
            .shadow(color: .black.opacity(0.35), radius: 18, x: 0, y: 10)
        }
        .accessibilityLabel("Home currency: \(home.name). Tap to change.")
    }

    private var cameraVisual: some View {
        ZStack {
            ScanCorners()
                .stroke(Color.white.opacity(0.9), style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                .frame(width: 220, height: 220)
            LowPolyIcon(kind: .camera)
                .frame(width: 150, height: 150)
        }
        .accessibilityHidden(true)
    }

    // MARK: Copy

    private var headline: String {
        switch step {
        case .demo: return "Point at any price."
        case .home: return "Your home currency."
        case .camera: return "Allow the camera."
        }
    }

    private var message: String {
        switch step {
        case .demo: return "See tags, menus and receipts in your money."
        case .home: return "Prices convert to this. When you travel, the local currency is picked for you."
        case .camera: return "Used only to read prices. Nothing is saved."
        }
    }

    private var buttonTitle: String {
        switch step {
        case .demo: return "Continue"
        case .home: return needsCameraStep ? "Continue" : "Get started"
        case .camera: return "Allow camera"
        }
    }

    // MARK: Actions

    private func advance() {
        guard !isTransitioning else { return }
        isTransitioning = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { isTransitioning = false }

        switch step {
        case .demo:
            withAnimation(.easeOut(duration: 0.3)) { step = .home }
        case .home:
            currencyManager.setHomeCurrency(currencyManager.homeCurrency)
            // Ask for location now, while "the local currency is picked for you" is on screen.
            locationDetector.requestPermission {
                if needsCameraStep {
                    withAnimation(.easeOut(duration: 0.3)) { step = .camera }
                } else {
                    onFinish()
                }
            }
        case .camera:
            AVCaptureDevice.requestAccess(for: .video) { _ in
                DispatchQueue.main.async(execute: onFinish)
            }
        }
    }
}

// MARK: - Palette

private enum OnboardingPalette {
    /// Matches the navy of the app icon.
    static let background = Color(red: 13/255, green: 35/255, blue: 66/255)
    static let secondaryText = Color.white.opacity(0.72)
    static let paper = Color(red: 252/255, green: 250/255, blue: 245/255)
}

// MARK: - Price Tag Demo

/// A paper price tag gets "scanned": the corners close in, then the
/// converted amount appears below. Loops so it reads even if you glance late.
private struct PriceTagDemo: View {
    @EnvironmentObject var exchangeRateManager: ExchangeRateManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let homeCurrency: Currency

    @State private var scanned = false

    /// A yen price converted to your home currency (or a euro price if home is yen).
    private var example: (tag: String, amount: Double, code: String) {
        homeCurrency.code == "JPY" ? ("€24.00", 24, "EUR") : ("¥4,800", 4800, "JPY")
    }

    private var tagText: String { example.tag }

    private var convertedText: String {
        guard let from = Currency.currency(for: example.code),
              let value = exchangeRateManager.convert(amount: example.amount, from: from, to: homeCurrency) else {
            return ""
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = homeCurrency.code
        formatter.maximumFractionDigits = value >= 1000 ? 0 : 2
        return formatter.string(from: NSNumber(value: value)) ?? ""
    }

    var body: some View {
        VStack(spacing: 28) {
            ZStack {
                tag
                    .rotationEffect(.degrees(-6))

                ScanCorners()
                    .stroke(AppTheme.gold, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                    .frame(width: scanned ? 262 : 300, height: scanned ? 156 : 200)
                    .opacity(scanned ? 1 : 0.5)
            }
            .frame(height: 200)

            Text("≈ \(convertedText)")
                .font(.app(40, .heavy))
                .monospacedDigit()
                .foregroundColor(AppTheme.gold)
                .opacity(scanned ? 1 : 0)
                .offset(y: scanned ? 0 : 12)
        }
        .accessibilityElement()
        .accessibilityLabel("A price tag reading \(tagText), converted to \(convertedText).")
        .task { await runLoop() }
    }

    private var tag: some View {
        HStack(spacing: 14) {
            Circle()
                .stroke(Color.black.opacity(0.25), lineWidth: 2)
                .frame(width: 14, height: 14)
            Text(tagText)
                .font(.app(44, .heavy))
                .monospacedDigit()
                .foregroundColor(OnboardingPalette.background)
        }
        .padding(.leading, 34)
        .padding(.trailing, 26)
        .frame(height: 96)
        .background(
            TagShape().fill(OnboardingPalette.paper)
        )
        .shadow(color: Color.black.opacity(0.35), radius: 18, x: 0, y: 10)
    }

    private func runLoop() async {
        if reduceMotion {
            scanned = true
            return
        }
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 700_000_000)
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { scanned = true }
            try? await Task.sleep(nanoseconds: 2_600_000_000)
            withAnimation(.easeInOut(duration: 0.35)) { scanned = false }
        }
    }
}

// MARK: - Shapes

/// A price tag pointing left, with a squared right end.
private struct TagShape: Shape {
    func path(in rect: CGRect) -> Path {
        let point = min(rect.height * 0.42, 40)
        let radius: CGFloat = 10
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX + point, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + radius), control: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - radius, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + point, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// Four viewfinder corners, like the scanner's brackets.
struct ScanCorners: Shape {
    func path(in rect: CGRect) -> Path {
        let length = min(rect.width, rect.height) * 0.22
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + length))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + length, y: rect.minY))
        path.move(to: CGPoint(x: rect.maxX - length, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + length))
        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - length))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - length, y: rect.maxY))
        path.move(to: CGPoint(x: rect.minX + length, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - length))
        return path
    }
}

// MARK: - Camera Access Off

/// Shown in place of the camera preview when camera access was denied.
struct CameraAccessOffView: View {
    var body: some View {
        VStack(spacing: 14) {
            LowPolyIcon(kind: .camera)
                .frame(width: 72, height: 72)
            Text("Camera access is off")
                .font(.app(20, .bold))
                .foregroundColor(.white)
            Text("Turn on Camera for Tagwise in Settings to scan prices.")
                .font(.app(15))
                .foregroundColor(.white.opacity(0.75))
                .multilineTextAlignment(.center)
            Button(action: {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }) {
                Text("Open Settings")
                    .font(.app(16, .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(AppTheme.blue)
                    .cornerRadius(AppTheme.buttonRadius)
            }
            .padding(.top, 4)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}
