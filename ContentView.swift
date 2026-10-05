import SwiftUI
import AppKit

private enum Key: Hashable {
    case digit(Int), decimal, op(Operation), equals, percent, sign, clear
}

private let rows: [[Key]] = [
    [.clear, .sign, .percent, .op(.divide)],
    [.digit(7), .digit(8), .digit(9), .op(.multiply)],
    [.digit(4), .digit(5), .digit(6), .op(.subtract)],
    [.digit(1), .digit(2), .digit(3), .op(.add)],
    [.digit(0), .decimal, .equals],
]

private let buttonSize: CGFloat = 68
private let spacing: CGFloat = 12

struct ContentView: View {
    @StateObject private var engine = CalculatorEngine()
    @State private var keyMonitor: Any?

    private static let backgroundImage: NSImage? = {
        guard let url = Bundle.main.url(forResource: "6", withExtension: "jpg") else { return nil }
        return NSImage(contentsOf: url)
    }()

    var body: some View {
        ZStack {
            background

            VStack(spacing: spacing) {
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(engine.expression)
                        .font(.system(size: 24, weight: .regular))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .truncationMode(.head)
                        .frame(height: 30)
                    Text(engine.display)
                        .font(.system(size: 64, weight: .light))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.35)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .shadow(color: .black.opacity(0.6), radius: 6, y: 2)
                .padding(.horizontal, 8)
                .padding(.bottom, 8)

                ForEach(rows.indices, id: \.self) { r in
                    HStack(spacing: spacing) {
                        ForEach(rows[r], id: \.self) { key in
                            button(for: key)
                        }
                    }
                }
            }
            .padding(20)
        }
        .frame(width: 4 * buttonSize + 3 * spacing + 40, height: 580)
        .onAppear(perform: installKeyMonitor)
        .onDisappear {
            if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        }
    }

    private var background: some View {
        ZStack {
            // Overlay on a Color so the image fills the window without widening the layout.
            Color.black.overlay {
                if let image = Self.backgroundImage {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                }
            }
            .clipped()
            LinearGradient(
                colors: [.black.opacity(0.15), .black.opacity(0.55)],
                startPoint: .top, endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private func button(for key: Key) -> some View {
        let isWide = key == .digit(0)
        Button { press(key) } label: {
            Text(label(for: key))
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(foreground(for: key))
                .frame(width: isWide ? buttonSize * 2 + spacing : buttonSize, height: buttonSize)
        }
        .buttonStyle(FrostedButtonStyle(tint: tint(for: key)))
    }

    private func label(for key: Key) -> String {
        switch key {
        case .digit(let d): return String(d)
        case .decimal: return "."
        case .equals: return "="
        case .percent: return "%"
        case .sign: return "±"
        case .clear: return engine.clearLabel
        case .op(let op): return op.symbol
        }
    }

    private func tint(for key: Key) -> Color {
        switch key {
        case .op(let op) where engine.activeOperation == op: return .white.opacity(0.9)
        case .op, .equals: return .orange.opacity(0.75)
        case .clear, .sign, .percent: return .white.opacity(0.35)
        default: return .black.opacity(0.25)
        }
    }

    private func foreground(for key: Key) -> Color {
        if case .op(let op) = key, engine.activeOperation == op { return .orange }
        return .white
    }

    private func press(_ key: Key) {
        switch key {
        case .digit(let d): engine.inputDigit(d)
        case .decimal: engine.inputDecimal()
        case .op(let op): engine.setOperation(op)
        case .equals: engine.equals()
        case .percent: engine.percent()
        case .sign: engine.toggleSign()
        case .clear: engine.clear()
        }
    }

    private func installKeyMonitor() {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.contains(.command) { return event }
            switch event.keyCode {
            case 36, 76: engine.equals(); return nil          // Return, keypad Enter
            case 53: engine.allClear(); return nil            // Escape
            case 51, 117: engine.backspace(); return nil      // Delete, forward delete
            default: break
            }
            guard let char = event.charactersIgnoringModifiers?.first else { return event }
            switch char {
            case "0"..."9": engine.inputDigit(Int(String(char))!)
            case ".", ",": engine.inputDecimal()
            case "+": engine.setOperation(.add)
            case "-": engine.setOperation(.subtract)
            case "*", "x", "X": engine.setOperation(.multiply)
            case "/": engine.setOperation(.divide)
            case "=": engine.equals()
            case "%": engine.percent()
            case "c", "C": engine.clear()
            default: return event
            }
            return nil
        }
    }
}

private struct FrostedButtonStyle: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(Capsule().fill(tint))
                    .overlay(Capsule().strokeBorder(.white.opacity(0.25), lineWidth: 1))
            )
            .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
            .opacity(configuration.isPressed ? 0.6 : 1)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}
