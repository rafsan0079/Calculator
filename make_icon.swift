// Draws the app icon (a calculator) and writes a 1024×1024 PNG.
// Usage: swift make_icon.swift <output.png>
import AppKit

let size: CGFloat = 1024
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                           colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> NSColor {
    NSColor(deviceRed: r / 255, green: g / 255, blue: b / 255, alpha: 1)
}

// Body: macOS-style rounded square with drop shadow.
let body = NSRect(x: 100, y: 100, width: 824, height: 824)
let bodyPath = NSBezierPath(roundedRect: body, xRadius: 185, yRadius: 185)
NSGraphicsContext.saveGraphicsState()
let shadow = NSShadow()
shadow.shadowColor = NSColor.black.withAlphaComponent(0.35)
shadow.shadowBlurRadius = 30
shadow.shadowOffset = NSSize(width: 0, height: -12)
shadow.set()
rgb(40, 40, 46).setFill()
bodyPath.fill()
NSGraphicsContext.restoreGraphicsState()
NSGradient(starting: rgb(72, 72, 80), ending: rgb(28, 28, 32))!.draw(in: bodyPath, angle: -90)

// Display.
let display = NSRect(x: 180, y: 690, width: 664, height: 160)
let displayPath = NSBezierPath(roundedRect: display, xRadius: 36, yRadius: 36)
NSGradient(starting: rgb(190, 236, 214), ending: rgb(140, 204, 178))!.draw(in: displayPath, angle: -90)
let digits = NSAttributedString(string: "123", attributes: [
    .font: NSFont.monospacedDigitSystemFont(ofSize: 120, weight: .medium),
    .foregroundColor: rgb(30, 60, 50),
])
let textSize = digits.size()
digits.draw(at: NSPoint(x: display.maxX - 40 - textSize.width, y: display.midY - textSize.height / 2))

// 4×4 keypad: grey number keys, orange right-hand column.
let symbols = [["7", "8", "9", "÷"], ["4", "5", "6", "×"], ["1", "2", "3", "−"], ["0", ".", "=", "+"]]
let keyGap: CGFloat = 28
let keyW = (664 - 3 * keyGap) / 4
let keyH: CGFloat = 96
for (row, keys) in symbols.enumerated() {
    for (col, symbol) in keys.enumerated() {
        let rect = NSRect(x: 180 + CGFloat(col) * (keyW + keyGap),
                          y: 640 - CGFloat(row + 1) * keyH - CGFloat(row) * keyGap,
                          width: keyW, height: keyH)
        let keyPath = NSBezierPath(roundedRect: rect, xRadius: 30, yRadius: 30)
        let isOperator = col == 3
        let (top, bottom) = isOperator ? (rgb(255, 176, 60), rgb(240, 130, 20)) : (rgb(120, 120, 130), rgb(88, 88, 96))
        NSGradient(starting: top, ending: bottom)!.draw(in: keyPath, angle: -90)
        let label = NSAttributedString(string: symbol, attributes: [
            .font: NSFont.systemFont(ofSize: 64, weight: .semibold),
            .foregroundColor: NSColor.white,
        ])
        let s = label.size()
        label.draw(at: NSPoint(x: rect.midX - s.width / 2, y: rect.midY - s.height / 2))
    }
}

NSGraphicsContext.current = nil
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
