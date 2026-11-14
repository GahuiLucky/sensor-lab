import SwiftUI

struct WelcomeView: View {
    let onStart: (Bool) -> Void

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    Spacer(minLength: 34)

                    logo

                    VStack(spacing: 8) {
                        Text("Sensor Lab")
                            .font(.system(size: 34, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Alle Sensoren deines iPhones – live, präzise und schön visualisiert.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.55))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Card {
                        VStack(spacing: 14) {
                            featureRow(icon: "gyroscope", tint: Theme.cyan, title: "Bewegung & Lage", detail: "Accelerometer, Gyroskop, Magnetometer, Attitude")
                            Divider().overlay(Color.white.opacity(0.08))
                            featureRow(icon: "location.north.fill", tint: Theme.pink, title: "Standort & Kompass", detail: "GPS, Geschwindigkeit, Höhe, Kompassrose")
                            Divider().overlay(Color.white.opacity(0.08))
                            featureRow(icon: "figure.walk", tint: Theme.green, title: "Aktivität & Schritte", detail: "Schrittzähler, Distanz, Etagen, Kadenz")
                            Divider().overlay(Color.white.opacity(0.08))
                            featureRow(icon: "gauge", tint: Theme.amber, title: "Umgebung & Gerät", detail: "Barometer, Schallpegel, Akku, Thermik")
                        }
                    }

                    VStack(spacing: 12) {
                        Button {
                            onStart(false)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "waveform.path.ecg")
                                Text("Sensoren aktivieren")
                            }
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color(red: 0.02, green: 0.06, blue: 0.10))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                Capsule().fill(
                                    LinearGradient(
                                        colors: [Theme.cyan, Theme.green],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            )
                            .shadow(color: Theme.cyan.opacity(0.35), radius: 16, y: 8)
                        }
                        .buttonStyle(.plain)

                        Button {
                            onStart(true)
                        } label: {
                            Text("Ohne Sensoren testen (Demo)")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.85))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Capsule().fill(Color.white.opacity(0.08)))
                                .overlay(Capsule().strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }

                    Text("Sensor Lab benötigt Zugriff auf Bewegung, Standort und Mikrofon. Alle Messwerte bleiben ausschließlich auf deinem Gerät.")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.35))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 26)
                .padding(.bottom, 34)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var logo: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Theme.cyan.opacity(0.35), Theme.violet.opacity(0.25)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 106, height: 106)
                .blur(radius: 1)
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [Theme.cyan.opacity(0.8), Theme.violet.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .frame(width: 106, height: 106)
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.system(size: 40, weight: .medium))
                .foregroundStyle(Theme.cyan)
                .shadow(color: Theme.cyan.opacity(0.6), radius: 14)
        }
    }

    private func featureRow(icon: String, tint: Color, title: String, detail: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(tint.opacity(0.15)).frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tint)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                Text(detail)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
            }
            Spacer(minLength: 0)
        }
    }
}
