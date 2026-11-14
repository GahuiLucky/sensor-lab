import SwiftUI

// MARK: - Kompassrose

struct CompassDial: View {
    let heading: Double
    var showReadout: Bool = true

    private var cardinal: String {
        let labels = ["N", "NO", "O", "SO", "S", "SW", "W", "NW"]
        let normalized = ((heading.truncatingRemainder(dividingBy: 360)) + 360)
            .truncatingRemainder(dividingBy: 360)
        let index = Int((normalized / 45).rounded()) % 8
        return labels[index]
    }

    var body: some View {
        ZStack {
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = min(size.width, size.height) / 2 - 6
                let rotation = heading

                // Innenkreis
                var inner = Path()
                inner.addEllipse(
                    in: CGRect(
                        x: center.x - radius * 0.62,
                        y: center.y - radius * 0.62,
                        width: radius * 1.24,
                        height: radius * 1.24
                    )
                )
                context.stroke(inner, with: .color(.white.opacity(0.08)), lineWidth: 1)

                // Skalenstriche
                for index in 0..<72 {
                    let degrees = Double(index) * 5 - rotation
                    let radians = degrees * .pi / 180
                    let isMajor = index % 9 == 0
                    let isMedium = index % 3 == 0
                    let innerRadius = radius - (isMajor ? 17 : (isMedium ? 11 : 6))
                    let outerRadius = radius - 3

                    var tick = Path()
                    tick.move(
                        to: CGPoint(
                            x: center.x + sin(radians) * innerRadius,
                            y: center.y - cos(radians) * innerRadius
                        )
                    )
                    tick.addLine(
                        to: CGPoint(
                            x: center.x + sin(radians) * outerRadius,
                            y: center.y - cos(radians) * outerRadius
                        )
                    )
                    context.stroke(
                        tick,
                        with: .color(.white.opacity(isMajor ? 0.9 : (isMedium ? 0.45 : 0.22))),
                        lineWidth: isMajor ? 2 : 1
                    )
                }

                // Himmelsrichtungen
                let labels = [("N", 0.0), ("O", 90.0), ("S", 180.0), ("W", 270.0)]
                for (label, baseAngle) in labels {
                    let radians = (baseAngle - rotation) * .pi / 180
                    let labelRadius = radius - 36
                    let point = CGPoint(
                        x: center.x + sin(radians) * labelRadius,
                        y: center.y - cos(radians) * labelRadius
                    )
                    let color: Color = label == "N" ? Theme.pink : .white.opacity(0.7)
                    context.draw(
                        Text(label)
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .foregroundStyle(color),
                        at: point
                    )
                }

                // Gradzahlen
                for degrees in stride(from: 0, to: 360, by: 30) {
                    let radians = (Double(degrees) - rotation) * .pi / 180
                    let labelRadius = radius - 58
                    let point = CGPoint(
                        x: center.x + sin(radians) * labelRadius,
                        y: center.y - cos(radians) * labelRadius
                    )
                    context.draw(
                        Text("\(degrees)")
                            .font(.system(size: 8, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.3)),
                        at: point
                    )
                }

                // Zeiger oben
                var needle = Path()
                needle.move(to: CGPoint(x: center.x, y: center.y - radius + 2))
                needle.addLine(to: CGPoint(x: center.x - 7, y: center.y - radius + 16))
                needle.addLine(to: CGPoint(x: center.x + 7, y: center.y - radius + 16))
                needle.closeSubpath()
                context.fill(needle, with: .color(Theme.cyan))
                context.stroke(needle, with: .color(Theme.cyan.opacity(0.6)), lineWidth: 1)
            }

            if showReadout {
                VStack(spacing: 0) {
                    Text("\(Int(heading.rounded()))°")
                        .monoValue(30, weight: .bold)
                        .foregroundStyle(.white)
                    Text(cardinal)
                        .font(.system(size: 11, weight: .bold))
                        .tracking(2)
                        .foregroundStyle(Theme.cyan.opacity(0.85))
                }
            }
        }
    }
}
