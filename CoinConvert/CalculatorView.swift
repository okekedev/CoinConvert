import SwiftUI

struct CalculatorView: View {
    @Binding var displayValue: String
    @Binding var calculatedResult: Double?
    var onResultChanged: ((Double) -> Void)?

    @State private var currentOperation: CalculatorOperation?
    @State private var previousValue: Double = 0
    @State private var shouldResetDisplay = false
    @State private var hasDecimal = false
    @State private var isPercentMode = false

    private let buttons: [[CalculatorButton]] = [
        [.clear, .plusMinus, .percent, .divide],
        [.seven, .eight, .nine, .multiply],
        [.four, .five, .six, .subtract],
        [.one, .two, .three, .add],
        [.zero, .decimal, .equals]
    ]

    var body: some View {
        VStack(spacing: 8) {
            // Display
            VStack(alignment: .trailing, spacing: 4) {
                if let op = currentOperation {
                    Text("\(formatNumber(previousValue)) \(op.symbol)")
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryText)
                }

                Text(isPercentMode ? "\(displayValue)%" : displayValue)
                    .font(.system(size: 36, weight: .light, design: .rounded))
                    .foregroundColor(AppTheme.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(AppTheme.secondaryBackground)
            .cornerRadius(AppTheme.cornerRadius)

            // Button grid
            ForEach(buttons, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { button in
                        Button(action: {
                            buttonTapped(button)
                        }) {
                            Text(button.title)
                                .font(.title2.weight(.medium))
                                .frame(maxWidth: .infinity, minHeight: 50)
                        }
                        .buttonStyle(CalculatorButtonStyle(isOperator: button.isOperator, isEquals: button.isEquals))
                    }
                }
            }
        }
        .padding(12)
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadius)
        .shadow(color: AppTheme.shadowColor, radius: AppTheme.shadowRadius, x: 0, y: 4)
    }

    private func buttonTapped(_ button: CalculatorButton) {
        switch button {
        case .zero, .one, .two, .three, .four, .five, .six, .seven, .eight, .nine:
            appendDigit(button.title)
        case .decimal:
            appendDecimal()
        case .add:
            setOperation(.add)
        case .subtract:
            setOperation(.subtract)
        case .multiply:
            setOperation(.multiply)
        case .divide:
            setOperation(.divide)
        case .equals:
            calculateResult()
        case .clear:
            clear()
        case .plusMinus:
            toggleSign()
        case .percent:
            applyPercent()
        }
    }

    private func appendDigit(_ digit: String) {
        if shouldResetDisplay || isPercentMode {
            displayValue = digit
            shouldResetDisplay = false
            isPercentMode = false
        } else if displayValue == "0" {
            displayValue = digit
        } else {
            displayValue += digit
        }
        updateResult()
    }

    private func appendDecimal() {
        if shouldResetDisplay {
            displayValue = "0."
            shouldResetDisplay = false
            hasDecimal = true
        } else if !hasDecimal {
            displayValue += "."
            hasDecimal = true
        }
    }

    private func setOperation(_ operation: CalculatorOperation) {
        if let current = currentOperation {
            // Chain operations
            calculateResult()
        }

        // Use the actual value (considering percent mode)
        if isPercentMode, let value = Double(displayValue) {
            previousValue = value / 100
        } else if let value = Double(displayValue) {
            previousValue = value
        }
        currentOperation = operation
        shouldResetDisplay = true
        hasDecimal = false
        isPercentMode = false
    }

    private func calculateResult() {
        guard let operation = currentOperation,
              let rawValue = Double(displayValue) else {
            return
        }

        // Get the actual current value (considering percent mode)
        let currentValue = isPercentMode ? rawValue / 100 : rawValue

        var result: Double = 0

        switch operation {
        case .add:
            result = previousValue + currentValue
        case .subtract:
            result = previousValue - currentValue
        case .multiply:
            result = previousValue * currentValue
        case .divide:
            if currentValue != 0 {
                result = previousValue / currentValue
            } else {
                displayValue = "Error"
                currentOperation = nil
                isPercentMode = false
                return
            }
        }

        displayValue = formatNumber(result)
        calculatedResult = result
        currentOperation = nil
        shouldResetDisplay = true
        hasDecimal = displayValue.contains(".")
        isPercentMode = false
        onResultChanged?(result)
    }

    private func clear() {
        displayValue = "0"
        calculatedResult = nil
        currentOperation = nil
        previousValue = 0
        shouldResetDisplay = false
        hasDecimal = false
        isPercentMode = false
        onResultChanged?(0)
    }

    private func toggleSign() {
        if let value = Double(displayValue) {
            let newValue = -value
            displayValue = formatNumber(newValue)
            updateResult()
        }
    }

    private func applyPercent() {
        if let value = Double(displayValue) {
            // Store the display value as the percentage (e.g., "80" for 80%)
            // But the actual calculated result is value/100 (e.g., 0.80)
            let decimalValue = value / 100
            isPercentMode = true
            calculatedResult = decimalValue
            onResultChanged?(decimalValue)
        }
    }

    private func updateResult() {
        if let value = Double(displayValue) {
            calculatedResult = value
            onResultChanged?(value)
        }
    }

    private func formatNumber(_ number: Double) -> String {
        if number.truncatingRemainder(dividingBy: 1) == 0 && abs(number) < 1e10 {
            return String(format: "%.0f", number)
        } else {
            let formatter = NumberFormatter()
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 8
            formatter.numberStyle = .decimal
            return formatter.string(from: NSNumber(value: number)) ?? String(number)
        }
    }

    func setDisplayValue(_ value: Double) {
        displayValue = formatNumber(value)
        calculatedResult = value
        hasDecimal = displayValue.contains(".")
    }
}

enum CalculatorButton: Hashable {
    case zero, one, two, three, four, five, six, seven, eight, nine
    case decimal, equals, add, subtract, multiply, divide
    case clear, plusMinus, percent

    var title: String {
        switch self {
        case .zero: return "0"
        case .one: return "1"
        case .two: return "2"
        case .three: return "3"
        case .four: return "4"
        case .five: return "5"
        case .six: return "6"
        case .seven: return "7"
        case .eight: return "8"
        case .nine: return "9"
        case .decimal: return "."
        case .equals: return "="
        case .add: return "+"
        case .subtract: return "-"
        case .multiply: return "×"
        case .divide: return "÷"
        case .clear: return "C"
        case .plusMinus: return "±"
        case .percent: return "%"
        }
    }

    var isOperator: Bool {
        switch self {
        case .add, .subtract, .multiply, .divide:
            return true
        default:
            return false
        }
    }

    var isEquals: Bool {
        self == .equals
    }
}
