import SwiftUI
import UIKit

struct EnvironmentView: View {
    @EnvironmentObject private var engine: SensorEngine
    @Environment(\.openURL) private var openURL

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    header

                    if !engine.availability.barometer && !engine.demoMode {
                        UnavailableBanner(
                            title: "Kein Barometer",
                            message: "Dieses Gerät (oder der Simulator) liefert keine Luftdruckdaten."
                        )
                    }

                    barometerCard
                    soundCard
                    deviceCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 28)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            ScreenTitle(title: "Umgebung", subtitle: "Barometer · Mikrofon · Gerät")
            Spacer()
            LivePill(isLive: !engine.isPaused)
        }
    }

    // MARK: - Barometer

    private var barometerCard: some View {
        Card(title: "Barometer", icon: "barometer", tint: Theme.amber) {
            HStack(spacing: 12) {
                MetricTile(
                    title: "Rel. Höhe",
                    value: engine.relativeAltitude.fixed(2),
                    unit: "m",
                    icon: "arrow.up.right",
                    tint: Theme.amber
                )
                MetricTile(
                    title: "Luftdruck",
                    value: engine.pressure > 0 ? engine.pressure.fixed(1) : "–",
                    unit: "hPa",
                    icon: "gauge",
                    tint: Theme.violet
                )
            }

            if engine.altitudeTrace.values.count > 2 {
                LineChart(
                    series: [
                        ChartSeries(
                            id: "altitude",
                            label: "Höhe",
                            color: Theme.amber,
                            values: engine.altitudeTrace.values
                        )
                    ],
                    height: 130
                )
            } else {
                ChartPlaceholder(text: "Warte auf Barometerdaten …")
            }

            ValueRow(
                label: "Absolute Höhe (GPS)",
                value: engine.location.hasFix ? "\(engine.location.altitude.fixed(1)) m" : "–"
            )
            ValueRow(
                label: "Druckverlauf",
                value: engine.altitudeTrace.values.count > 1 ? "live" : "–",
                tint: Theme.amber
            )
        }
    }

    // MARK: - Schallpegel

    private var soundCard: some View {
        Card(title: "Schallpegel", icon: "waveform", tint: Theme.pink) {
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text("\(Int(engine.soundDB.rounded()))")
                    .monoValue(42, weight: .bold)
                    .foregroundStyle(.white)
                Text("dBFS")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.4))
                Spacer()
                Text(soundLabel.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(Theme.pink)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Theme.pink.opacity(0.14)))
            }

            MeterBar(level: engine.soundLevel, tint: Theme.pink)

            if engine.soundTrace.values.count > 2 {
                Waveform(values: Array(engine.soundTrace.values.suffix(48)), color: Theme.pink)
            } else {
                ChartPlaceholder(text: "Warte auf Mikrofonpegel …")
            }

            if engine.micDenied {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "mic.slash.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.red)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Mikrofonzugriff nicht erlaubt")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.85))
                        Button {
                            openSettings()
                        } label: {
                            Text("In Einstellungen freigeben")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Theme.pink)
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer(minLength: 0)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.red.opacity(0.10)))
            } else if !engine.microphoneActive && !engine.demoMode {
                Text("Der Pegel startet, sobald das Mikrofon bereit ist.")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.35))
            }

            Text("dBFS ist ein relativer Pegel: 0 dB entspricht der Vollaussteuerung. Es werden keine Aufnahmen gespeichert.")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.white.opacity(0.3))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var soundLabel: String {
        guard engine.microphoneActive || engine.demoMode else { return "inaktiv" }
        switch engine.soundDB {
        case -100 ..< -55: return "sehr leise"
        case -55 ..< -40: return "leise"
        case -40 ..< -25: return "moderat"
        case -25 ..< -12: return "laut"
        default: return "sehr laut"
        }
    }

    // MARK: - Gerät

    private var deviceCard: some View {
        Card(title: "Gerät", icon: "iphone", tint: Theme.violet) {
            HStack(spacing: 18) {
                ZStack {
                    RingGauge(progress: max(engine.batteryLevel, 0), color: batteryTint, lineWidth: 9)
                        .frame(width: 88, height: 88)
                    VStack(spacing: 1) {
                        Text(engine.batteryPercent >= 0 ? "\(engine.batteryPercent)%" : "–")
                            .monoValue(18, weight: .bold)
                            .foregroundStyle(.white)
                        Image(systemName: batterySymbol)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(batteryTint)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    ValueRow(label: "Modell", value: engine.deviceModel)
                    ValueRow(label: "Thermik", value: thermalText, tint: Theme.amber)
                    ValueRow(label: "Ausrichtung", value: orientationText, tint: Theme.cyan)
                    ValueRow(label: "Helligkeit", value: "\(Int(engine.screenBrightness * 100)) %")
                }
            }

            Divider().overlay(Color.white.opacity(0.08))

            ValueRow(label: "Akku-Status", value: batteryStateText, tint: batteryTint)
            ValueRow(label: "Stromsparmodus", value: engine.lowPowerMode ? "aktiv" : "aus")
            ValueRow(label: "iOS-Version", value: UIDevice.current.systemVersion)
            ValueRow(label: "Gerätename", value: UIDevice.current.name)

            Divider().overlay(Color.white.opacity(0.08))

            Toggle(isOn: Binding(
                get: { engine.proximityEnabled },
                set: { engine.setProximityMonitoring($0) }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Näherungssensor")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                    Text(engine.proximityEnabled
                         ? (engine.proximityNear ? "Aktuell bedeckt" : "Aktuell frei")
                         : "Display schaltet bei Bedeckung ab")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            .tint(Theme.cyan)
        }
    }

    private var batteryTint: Color {
        switch engine.batteryState {
        case .charging, .full:
            return Theme.green
        case .unplugged:
            return engine.batteryLevel >= 0 && engine.batteryLevel < 0.2 ? Theme.red : Theme.amber
        default:
            return Theme.amber
        }
    }

    private var batterySymbol: String {
        switch engine.batteryState {
        case .charging:
            return "bolt.fill"
        case .full:
            return "battery.100"
        default:
            return "battery.100"
        }
    }

    private var batteryStateText: String {
        switch engine.batteryState {
        case .charging: return "Lädt"
        case .full: return "Voll"
        case .unplugged: return "Akku"
        case .unknown: return "Unbekannt"
        @unknown default: return "Unbekannt"
        }
    }

    private var thermalText: String {
        switch engine.thermalState {
        case .nominal: return "Nominal"
        case .fair: return "Erwärmt"
        case .serious: return "Kritisch"
        case .critical: return "Sehr kritisch"
        @unknown default: return "Unbekannt"
        }
    }

    private var orientationText: String {
        switch engine.deviceOrientation {
        case .portrait: return "Hochformat"
        case .portraitUpsideDown: return "Hochformat umgedreht"
        case .landscapeLeft: return "Querformat links"
        case .landscapeRight: return "Querformat rechts"
        case .faceUp: return "Flach, oben"
        case .faceDown: return "Flach, unten"
        default: return "Unbekannt"
        }
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
    }
}
