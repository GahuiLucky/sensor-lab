import SwiftUI

// MARK: - Künstlicher Horizont

struct AttitudeView: View {
    let attitude: AttitudeReading

    var body: some View {
        GeometryReader { geo in
            let diameter = min(geo.size.width, geo.size.height)
            ZStack {
                Color(red: 0.05, green: 0.07, blue: 0.13)

                VStack(spacing: 0) {
                    LinearGradient(
                        colors: [
                            Color(red: 0.16, green: 0.52, blue: 0.95),
                            Color(red: 0.42, green: 0.82, blue: 1.00)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    LinearGradient(
                        colors: [
                            Color(red: 0.36, green: 0.16, blue: 0.42),
                            Color(red: 0.08, green: 0.04, blue: 0.12)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .frame(width: diameter * 2.6, height: diameter * 2.6)
                .offset(y: CGFloat(attitude.pitch / (.pi / 2)) * diameter * 0.85)
                .rotationEffect(.degrees(-attitude.rollDegrees))

                // Horizontlinie
                Rectangle()
                    .fill(Color.white.opacity(0.55))
                    .frame(width: diameter * 1.1, height: 1)
                    .rotationEffect(.degrees(-attitude.rollDegrees))

                // Visier
                HStack(spacing: 20) {
                    Capsule().fill(Color.white.opacity(0.9)).frame(width: 34, height: 2)
                    Circle()
                        .strokeBorder(Color.white.opacity(0.9), lineWidth: 1.5)
                        .frame(width: 8, height: 8)
                    Capsule().fill(Color.white.opacity(0.9)).frame(width: 34, height: 2)
                }
            }
            .frame(width: diameter, height: diameter)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.45), .white.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .overlay(alignment: .top) {
                Text("\(Int(attitude.pitchDegrees.rounded()))°")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(.black.opacity(0.35)))
                    .padding(.top, 10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - 3D-Gerätelage

struct DeviceTiltView: View {
    let attitude: AttitudeReading

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height) * 0.62
            ZStack {
                Ellipse()
                    .fill(Color.black.opacity(0.45))
                    .frame(width: side * 1.1, height: side * 0.32)
                    .blur(radius: 12)
                    .offset(y: side * 0.44)

                RoundedRectangle(cornerRadius: side * 0.18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.cyan.opacity(0.35),
                                Theme.violet.opacity(0.30),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: side * 0.18, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
                    )
                    .overlay(
                        Circle()
                            .fill(Color.white.opacity(0.10))
                            .frame(width: side * 0.34, height: side * 0.34)
                            .overlay(Circle().strokeBorder(Color.white.opacity(0.2), lineWidth: 1))
                    )
                    .frame(width: side * 0.62, height: side)
                    .rotation3DEffect(.degrees(attitude.pitchDegrees), axis: (x: 1, y: 0, z: 0))
                    .rotation3DEffect(.degrees(-attitude.rollDegrees), axis: (x: 0, y: 0, z: 1))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
