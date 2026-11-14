import SwiftUI

enum Theme {
    static let cyan = Color(red: 0.30, green: 0.85, blue: 1.00)
    static let violet = Color(red: 0.60, green: 0.48, blue: 1.00)
    static let pink = Color(red: 1.00, green: 0.42, blue: 0.70)
    static let green = Color(red: 0.35, green: 0.95, blue: 0.62)
    static let amber = Color(red: 1.00, green: 0.76, blue: 0.30)
    static let red = Color(red: 1.00, green: 0.38, blue: 0.38)

    static let background = LinearGradient(
        colors: [
            Color(red: 0.07, green: 0.08, blue: 0.16),
            Color(red: 0.03, green: 0.03, blue: 0.07)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardGradient = LinearGradient(
        colors: [Color.white.opacity(0.10), Color.white.opacity(0.03)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct ScreenBackground: View {
    var body: some View {
        ZStack {
            Theme.background
            RadialGradient(
                colors: [Theme.violet.opacity(0.30), .clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 460
            )
            RadialGradient(
                colors: [Theme.cyan.opacity(0.16), .clear],
                center: .bottomLeading,
                startRadius: 10,
                endRadius: 420
            )
        }
        .ignoresSafeArea()
    }
}

extension View {
    func screenBackground() -> some View {
        background(ScreenBackground())
    }

    func monoValue(_ size: CGFloat, weight: Font.Weight = .semibold) -> some View {
        font(.system(size: size, weight: weight, design: .rounded)).monospacedDigit()
    }
}
