import Foundation

enum Operation {
    case add, subtract, multiply, divide

    var symbol: String {
        switch self {
        case .add: return "+"
        case .subtract: return "−"
        case .multiply: return "×"
        case .divide: return "÷"
        }
    }

    func apply(_ a: Double, _ b: Double) -> Double? {
        switch self {
        case .add: return a + b
        case .subtract: return a - b
        case .multiply: return a * b
        case .divide: return b == 0 ? nil : a / b
        }
    }
}

final class CalculatorEngine: ObservableObject {
    @Published private(set) var display = "0"
    @Published private(set) var activeOperation: Operation?
    /// The equation being entered, e.g. "8 × 5", or "8 × 5 =" once evaluated.
    @Published private(set) var expression = ""

    private var accumulator: Double?
    private var pendingOperation: Operation?
    private var isTyping = false
    private var hasError = false
    // Committed parts of the equation, e.g. ["8", "×"].
    private var tokens: [String] = []
    // Remembered for repeated "=" presses (e.g. 5 × 3 = = → 45).
    private var lastOperation: Operation?
    private var lastOperand: Double?

    var clearLabel: String { (isTyping && display != "0") ? "C" : "AC" }

    private var currentValue: Double { Double(display) ?? 0 }

    func inputDigit(_ digit: Int) {
        if hasError { allClear() }
        if !isTyping {
            display = String(digit)
            isTyping = true
        } else if display == "0" {
            display = String(digit)
        } else if display.filter(\.isNumber).count < 16 {
            display += String(digit)
        }
        activeOperation = nil
        updateExpression()
    }

    func inputDecimal() {
        if hasError { allClear() }
        if !isTyping {
            display = "0."
            isTyping = true
        } else if !display.contains(".") {
            display += "."
        }
        activeOperation = nil
        updateExpression()
    }

    func setOperation(_ op: Operation) {
        if hasError { return }
        if isTyping || accumulator == nil {
            tokens += [display, op.symbol]
            if let acc = accumulator, let pending = pendingOperation {
                guard let result = pending.apply(acc, currentValue) else { return showError() }
                accumulator = result
                show(result)
            } else {
                accumulator = currentValue
            }
        } else if !tokens.isEmpty {
            tokens[tokens.count - 1] = op.symbol  // Changed operator before typing a number.
        }
        pendingOperation = op
        activeOperation = op
        isTyping = false
        lastOperation = nil
        updateExpression()
    }

    func equals() {
        if hasError { return }
        if let pending = pendingOperation, let acc = accumulator {
            let operand = currentValue
            guard let result = pending.apply(acc, operand) else { return showError() }
            let equation = (tokens + [display, "="]).joined(separator: " ")
            lastOperation = pending
            lastOperand = operand
            finish(with: result)
            expression = equation
        } else if let op = lastOperation, let operand = lastOperand {
            guard let result = op.apply(currentValue, operand) else { return showError() }
            let equation = [display, op.symbol, Self.format(operand), "="].joined(separator: " ")
            finish(with: result)
            expression = equation
        }
    }

    func percent() {
        if hasError { return }
        show(currentValue / 100)
        isTyping = true
        updateExpression()
    }

    func toggleSign() {
        if hasError { return }
        if display.hasPrefix("-") {
            display.removeFirst()
        } else if display != "0" {
            display = "-" + display
        }
        if isTyping { updateExpression() }
    }

    func clear() {
        if isTyping && display != "0" {
            display = "0"
            isTyping = false
            activeOperation = pendingOperation
            updateExpression()
        } else {
            allClear()
        }
    }

    func allClear() {
        display = "0"
        accumulator = nil
        pendingOperation = nil
        activeOperation = nil
        lastOperation = nil
        lastOperand = nil
        isTyping = false
        hasError = false
        tokens = []
        expression = ""
    }

    func backspace() {
        guard isTyping, !hasError else { return }
        display.removeLast()
        if display.isEmpty || display == "-" { display = "0" }
        updateExpression()
    }

    private func finish(with result: Double) {
        show(result)
        accumulator = nil
        pendingOperation = nil
        activeOperation = nil
        isTyping = false
        tokens = []
    }

    private func updateExpression() {
        expression = (tokens + (isTyping ? [display] : [])).joined(separator: " ")
    }

    private func showError() {
        allClear()
        display = "Error"
        hasError = true
    }

    private func show(_ value: Double) {
        guard value.isFinite else { return showError() }
        display = Self.format(value)
    }

    static func format(_ value: Double) -> String {
        if value == 0 { return "0" }
        let magnitude = abs(value)
        if magnitude >= 1e16 || magnitude < 1e-9 {
            return String(format: "%.8g", value)
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.maximumSignificantDigits = 15
        formatter.usesSignificantDigits = true
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }
}
