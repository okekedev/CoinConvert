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

    // Border radius
    static let cornerRadius: CGFloat = 12
    static let buttonRadius: CGFloat = 10

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
            .font(.title2.weight(.medium))
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
