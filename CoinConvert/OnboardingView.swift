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

/// What the app does, then camera permission (only if the system hasn't asked yet).
/// Finishing drops people straight into the scanner on the free currency pair.
struct OnboardingView: View {
    let onFinish: () -> Void

    @State private var step = 0
    /// Ignores a second tap while the next step slides in, so a quick
    /// double tap can't skip a step or hit "Allow camera" by accident.
    @State private var isTransitioning = false

    private let needsCameraStep = AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined
    private var stepCount: Int { needsCameraStep ? 2 : 1 }
    private var isCameraStep: Bool { step == 1 }

    var body: some View {
        ZStack {
            OnboardingPalette.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                topBar

                Spacer(minLength: 24)

                Group {
                    if isCameraStep { cameraVisual } else { PriceTagDemo() }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 300)

                Spacer(minLength: 24)

                VStack(alignment: .leading, spacing: 10) {
                    Text(isCameraStep ? "Allow the camera." : "Point at any price.")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text(isCameraStep ? "Used only to read prices. Nothing is saved."
                                      : "See tags, menus and receipts in your money.")
                        .font(.system(size: 17))
                        .foregroundColor(OnboardingPalette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .id(step)
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .opacity))

                Spacer(minLength: 32)

                primaryButton

                Button(action: onFinish) {
                    Text("Not now")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(OnboardingPalette.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .opacity(isCameraStep ? 1 : 0)
                .disabled(!isCameraStep)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 8)
        }
    }

    // MARK: Pieces

    private var topBar: some View {
        HStack {
            if stepCount > 1 {
                HStack(spacing: 6) {
                    ForEach(0..<stepCount, id: \.self) { index in
                        Capsule()
                            .fill(index <= step ? AppTheme.gold : Color.white.opacity(0.2))
                            .frame(width: index == step ? 22 : 8, height: 8)
                    }
                }
                .animation(.easeOut(duration: 0.25), value: step)
                .accessibilityElement()
                .accessibilityLabel("Step \(step + 1) of \(stepCount)")
            }
            Spacer()
        }
        .frame(height: 44)
        .padding(.top, 8)
    }

    private var primaryButton: some View {
        Button(action: advance) {
            Text(isCameraStep ? "Allow camera" : (needsCameraStep ? "Continue" : "Start scanning"))
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(OnboardingPalette.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(AppTheme.gold)
                .cornerRadius(14)
        }
    }

    private var cameraVisual: some View {
        ZStack {
            ScanCorners()
                .stroke(Color.white.opacity(0.9), style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                .frame(width: 200, height: 200)
            Image(systemName: "camera.fill")
                .font(.system(size: 64, weight: .regular))
                .foregroundColor(AppTheme.gold)
        }
        .accessibilityHidden(true)
    }

    // MARK: Actions

    private func advance() {
        guard !isTransitioning else { return }
        isTransitioning = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { isTransitioning = false }

        if isCameraStep {
            AVCaptureDevice.requestAccess(for: .video) { _ in
                DispatchQueue.main.async(execute: onFinish)
            }
        } else if needsCameraStep {
            withAnimation(.easeOut(duration: 0.3)) { step = 1 }
        } else {
            onFinish()
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

/// A paper price tag in pounds gets "scanned": the corners close in, then the
/// converted amount appears below. Loops so it reads even if you glance late.
private struct PriceTagDemo: View {
    @EnvironmentObject var exchangeRateManager: ExchangeRateManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var scanned = false
    // Matches the free GBP <-> AUD pair people land on after onboarding.
    private let tagText = "£24.00"
    private let sourceAmount = 24.0

    private var convertedText: String {
        guard let gbp = Currency.currency(for: "GBP"), let aud = Currency.currency(for: "AUD"),
              let value = exchangeRateManager.convert(amount: sourceAmount, from: gbp, to: aud) else {
            return ""
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "AUD"
        formatter.currencySymbol = "A$"
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
                .font(.system(size: 40, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundColor(AppTheme.gold)
                .opacity(scanned ? 1 : 0)
                .offset(y: scanned ? 0 : 12)
        }
        .accessibilityElement()
        .accessibilityLabel("A price tag reading 24 pounds, converted to \(convertedText).")
        .task { await runLoop() }
    }

    private var tag: some View {
        HStack(spacing: 14) {
            Circle()
                .stroke(Color.black.opacity(0.25), lineWidth: 2)
                .frame(width: 14, height: 14)
            Text(tagText)
                .font(.system(size: 44, weight: .heavy, design: .rounded))
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
            Image(systemName: "camera.fill")
                .font(.system(size: 40))
                .foregroundColor(AppTheme.gold)
            Text("Camera access is off")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            Text("Turn on Camera for Tagwise in Settings to scan prices.")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.75))
                .multilineTextAlignment(.center)
            Button(action: {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }) {
                Text("Open Settings")
                    .font(.system(size: 16, weight: .semibold))
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
