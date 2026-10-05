import SwiftUI

@main
struct CalculatorApp: App {
    var body: some Scene {
        WindowGroup("Calculator") {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}
