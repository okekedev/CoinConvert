import SwiftUI

struct AppTheme {
    // Primary colors
    static let gold = Color(red: 212/255, green: 175/255, blue: 55/255)
    static let darkGold = Color(red: 184/255, green: 134/255, blue: 11/255)
    static let lightGold = Color(red: 250/255, green: 226/255, blue: 156/255)

    static let blue = Color(red: 41/255, green: 98/255, blue: 168/255)
    static let darkBlue = Color(red: 25/255, green: 55/255, blue: 95/255)
    static let lightBlue = Color(red: 173/255, green: 204/255, blue: 237/255)

    // Background colors
    static let background = Color.white
    static let secondaryBackground = Color(red: 248/255, green: 248/255, blue: 250/255)
    static let cardBackground = Color.white

    // Text colors
    static let primaryText = Color(red: 28/255, green: 28/255, blue: 30/255)
    static let secondaryText = Color(red: 142/255, green: 142/255, blue: 147/255)

    // Calculator colors
    static let calculatorButton = Color(red: 235/255, green: 235/255, blue: 240/255)
    static let operatorButton = gold
    static let numberText = primaryText

    // Square corners throughout, to match the faceted low-poly art.
    static let cornerRadius: CGFloat = 0
    static let buttonRadius: CGFloat = 0

    // Shadows
    static let shadowColor = Color.black.opacity(0.08)
    static let shadowRadius: CGFloat = 8
}

// Custom button styles
struct GoldButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [AppTheme.gold, AppTheme.darkGold],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .foregroundColor(.white)
            .cornerRadius(AppTheme.buttonRadius)
            .shadow(color: AppTheme.shadowColor, radius: 4, x: 0, y: 2)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct BlueButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [AppTheme.blue, AppTheme.darkBlue],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .foregroundColor(.white)
            .cornerRadius(AppTheme.buttonRadius)
            .shadow(color: AppTheme.shadowColor, radius: 4, x: 0, y: 2)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct CalculatorButtonStyle: ButtonStyle {
    let isOperator: Bool
    var isEquals: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.app(22, .medium))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                isEquals ?
                LinearGradient(
                    colors: [AppTheme.blue, AppTheme.darkBlue],
                    startPoint: .top,
                    endPoint: .bottom
                ) :
                isOperator ?
                LinearGradient(
                    colors: [AppTheme.gold, AppTheme.darkGold],
                    startPoint: .top,
                    endPoint: .bottom
                ) :
                LinearGradient(
                    colors: [AppTheme.calculatorButton, AppTheme.calculatorButton.opacity(0.9)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .foregroundColor((isOperator || isEquals) ? .white : AppTheme.primaryText)
            .cornerRadius(AppTheme.buttonRadius)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

// MARK: - Type

extension Font {
    /// Chakra Petch, the app's typeface: angular cuts that echo the low-poly
    /// facets, with even-width numbers. Scales with Dynamic Type.
    static func app(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        let face: String
        switch weight {
        case .medium: face = "ChakraPetch-Medium"
        case .semibold: face = "ChakraPetch-SemiBold"
        case .bold, .heavy, .black: face = "ChakraPetch-Bold"
        default: face = "ChakraPetch-Regular"
        }
        return .custom(face, size: size)
    }
}

// MARK: - Screenshot demo mode

/// Launch arguments for App Store screenshots (debug builds only; inert in release):
/// `-demoPro YES` unlock, `-demoMode scan`, `-demoScanAmount 24.5` printed tag instead of
/// the camera, `-demoCalculator 86.4` preset calculator value, `-demoPicker YES` open the
/// currency list, `-demoPaywall YES` open the Pro screen, `-demoOffer YES` then press close.
enum ScreenshotDemo {
    #if DEBUG
    private static let defaults = UserDefaults.standard
    static var isPro: Bool { defaults.bool(forKey: "demoPro") }
    static var startsInScan: Bool { defaults.string(forKey: "demoMode") == "scan" }
    static var scanAmount: Double? { positive(defaults.double(forKey: "demoScanAmount")) }
    static var calculatorValue: Double? { positive(defaults.double(forKey: "demoCalculator")) }
    static var opensPicker: Bool { defaults.bool(forKey: "demoPicker") }
    static var opensPaywall: Bool { defaults.bool(forKey: "demoPaywall") }
    static var opensOffer: Bool { defaults.bool(forKey: "demoOffer") }
    private static func positive(_ value: Double) -> Double? { value > 0 ? value : nil }
    #else
    static let isPro = false
    static let startsInScan = false
    static let scanAmount: Double? = nil
    static let calculatorValue: Double? = nil
    static let opensPicker = false
    static let opensPaywall = false
    static let opensOffer = false
    #endif
}
