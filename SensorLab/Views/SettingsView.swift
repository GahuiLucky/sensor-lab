import SwiftUI
import UIKit
import CoreLocation

struct SettingsView: View {
    @EnvironmentObject private var engine: SensorEngine
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScreenBackground()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        demoCard
                        motionSensorsCard
                        locationSensorsCard
                        permissionCard
                        aboutCard
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") { dismiss() }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.cyan)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    private var demoCard: some View {
        Card(title: "Demo-Modus", icon: "sparkles", tint: Theme.violet) {
            Toggle(isOn: Binding(
                get: { engine.demoMode },
                set: { engine.setDemoMode($0) }
            )) {
                Text("Simulierte Sensordaten")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .tint(Theme.violet)

            Text("Erzeugt realistische Beispielwerte für alle Sensoren – ideal für den Simulator oder zum Vorführen. Beim Ausschalten starten die echten Sensoren.")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.45))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var motionSensorsCard: some View {
        Card(title: "Bewegungssensoren", icon: "gyroscope", tint: Theme.cyan) {
            availabilityRow("Accelerometer", available: engine.availability.accelerometer, symbol: "arrow.up.and.down")
            availabilityRow("Gyroskop", available: engine.availability.gyroscope, symbol: "gyroscope")
            availabilityRow("Magnetometer", available: engine.availability.magnetometer, symbol: "sensor.tag.radiowaves.forward")
            availabilityRow("Device Motion", available: engine.availability.deviceMotion, symbol: "move.3d")
        }
    }

    private var locationSensorsCard: some View {
        Card(title: "Standort & Aktivität", icon: "location.fill", tint: Theme.pink) {
            availabilityRow("Kompass", available: engine.availability.heading, symbol: "location.north.fill")
            availabilityRow("Schrittzähler", available: engine.availability.stepCounting, symbol: "figure.walk")
            availabilityRow("Distanz", available: engine.availability.distance, symbol: "map")
            availabilityRow("Etagen", available: engine.availability.floors, symbol: "arrow.up.arrow.down")
            availabilityRow("Kadenz & Pace", available: engine.availability.cadence && engine.availability.pace, symbol: "stopwatch")
            availabilityRow("Aktivitätserkennung", available: engine.availability.activity, symbol: "figure.run")
            availabilityRow("Barometer", available: engine.availability.barometer, symbol: "barometer")
        }
    }

    private var permissionCard: some View {
        Card(title: "Berechtigungen", icon: "lock.shield.fill", tint: Theme.amber) {
            ValueRow(label: "Standort", value: locationPermissionText, tint: Theme.amber)
            ValueRow(label: "Mikrofon", value: microphonePermissionText, tint: Theme.pink)

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "gearshape.fill")
                    Text("Systemeinstellungen öffnen")
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Capsule().fill(Color.white.opacity(0.10)))
            }
            .buttonStyle(.plain)
        }
    }

    private var aboutCard: some View {
        Card(title: "Über Sensor Lab", icon: "info.circle.fill", tint: Theme.violet) {
            ValueRow(label: "Version", value: "\(version) (\(build))")
            ValueRow(label: "Gerät", value: engine.deviceModel)
            ValueRow(label: "iOS", value: UIDevice.current.systemVersion)
            ValueRow(label: "Datenhaltung", value: "Nur lokal", tint: Theme.green)
            Text("Alle Messwerte werden ausschließlich auf dem Gerät verarbeitet und nicht übertragen. Das Mikrofon dient nur der Pegelmessung, es werden keine Aufnahmen gespeichert.")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func availabilityRow(_ title: String, available: Bool, symbol: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.35))
                .frame(width: 18)
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.75))
            Spacer()
            Image(systemName: available ? "checkmark.circle.fill" : "slash.circle.fill")
                .font(.system(size: 12))
                .foregroundStyle(available ? Theme.green : Theme.red.opacity(0.75))
            Text(available ? "aktiv" : "n/a")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(available ? Theme.green : Color.white.opacity(0.35))
                .frame(width: 34, alignment: .trailing)
        }
    }

    private var locationPermissionText: String {
        switch engine.locationStatus {
        case .authorizedAlways: return "Immer"
        case .authorizedWhenInUse: return "Bei Verwendung"
        case .denied: return "Verweigert"
        case .restricted: return "Eingeschränkt"
        case .notDetermined: return "Nicht angefragt"
        @unknown default: return "Unbekannt"
        }
    }

    private var microphonePermissionText: String {
        if engine.microphoneActive { return "Aktiv" }
        if engine.micDenied { return "Verweigert" }
        return "Inaktiv"
    }
}
