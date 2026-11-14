import SwiftUI
import UIKit

struct LocationView: View {
    @EnvironmentObject private var engine: SensorEngine
    @Environment(\.openURL) private var openURL

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    header

                    if engine.locationStatus == .denied || engine.locationStatus == .restricted {
                        permissionCard
                    }

                    compassCard
                    coordinateCard

                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ],
                        spacing: 12
                    ) {
                        MetricTile(
                            title: "Tempo",
                            value: engine.speedKmh.fixed(1),
                            unit: "km/h",
                            icon: "speedometer",
                            tint: Theme.cyan
                        )
                        MetricTile(
                            title: "Kurs",
                            value: engine.location.hasFix ? engine.location.course.fixed(0) : "–",
                            unit: "°",
                            icon: "location.north",
                            tint: Theme.pink
                        )
                        MetricTile(
                            title: "Höhe",
                            value: engine.location.hasFix ? engine.location.altitude.fixed(1) : "–",
                            unit: "m",
                            icon: "arrow.up.right",
                            tint: Theme.violet
                        )
                        MetricTile(
                            title: "Horiz. Genauigkeit",
                            value: engine.location.hasFix ? engine.location.horizontalAccuracy.fixed(1) : "–",
                            unit: "m",
                            icon: "scope",
                            tint: Theme.green
                        )
                        MetricTile(
                            title: "Vert. Genauigkeit",
                            value: engine.location.hasFix ? engine.location.verticalAccuracy.fixed(1) : "–",
                            unit: "m",
                            icon: "arrow.up.and.down",
                            tint: Theme.amber
                        )
                        MetricTile(
                            title: "Geschw. Genauigkeit",
                            value: engine.location.hasFix ? engine.location.speedAccuracy.fixed(1) : "–",
                            unit: "m/s",
                            icon: "speedometer",
                            tint: Theme.cyan
                        )
                    }

                    if !engine.availability.heading && !engine.demoMode {
                        UnavailableBanner(
                            title: "Kein Kompass",
                            message: "Dieses Gerät besitzt keinen Magnetometer-Kompass. Die Position wird weiterhin über GPS ermittelt."
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 28)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            ScreenTitle(title: "Standort", subtitle: "GPS · Kompass · Höhe")
            Spacer()
            LivePill(isLive: !engine.isPaused)
        }
    }

    private var permissionCard: some View {
        Card(title: "Berechtigung", icon: "lock.shield.fill", tint: Theme.amber) {
            Text("Ohne Standortfreigabe stehen GPS, Höhe und Kompass nicht zur Verfügung.")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
                .fixedSize(horizontal: false, vertical: true)

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "gearshape.fill")
                    Text("Einstellungen öffnen")
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(red: 0.02, green: 0.06, blue: 0.10))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Capsule().fill(Theme.amber))
            }
            .buttonStyle(.plain)
        }
    }

    private var compassCard: some View {
        Card(title: "Kompass", icon: "location.north.fill", tint: Theme.pink) {
            CompassDial(heading: engine.heading)
                .frame(width: 250, height: 250)
                .frame(maxWidth: .infinity)

            HStack(spacing: 12) {
                LegendChip(
                    label: "Magnetisch",
                    value: engine.hasHeading ? "\(Int(engine.magneticHeading.rounded()))°" : "–",
                    color: Theme.pink
                )
                LegendChip(
                    label: "Geografisch",
                    value: engine.hasHeading ? "\(Int(engine.trueHeading.rounded()))°" : "–",
                    color: Theme.cyan
                )
                LegendChip(
                    label: "Genauigkeit",
                    value: engine.hasHeading ? "± \(Int(engine.headingAccuracy.rounded()))°" : "–",
                    color: Theme.violet
                )
            }
        }
    }

    private var coordinateCard: some View {
        Card(title: "Position", icon: "mappin.and.ellipse", tint: Theme.cyan) {
            if engine.location.hasFix {
                ValueRow(label: "Breitengrad", value: "\(engine.location.latitude.fixed(6))°", tint: Theme.cyan)
                ValueRow(label: "Längengrad", value: "\(engine.location.longitude.fixed(6))°", tint: Theme.cyan)
                Divider().overlay(Color.white.opacity(0.08))
                ValueRow(label: "Höhe über Meeresspiegel", value: "\(engine.location.altitude.fixed(1)) m")
                ValueRow(label: "GPS-Genauigkeit", value: "± \(engine.location.horizontalAccuracy.fixed(1)) m")
                if let timestamp = engine.location.timestamp {
                    ValueRow(
                        label: "Letztes Update",
                        value: timestamp.formatted(date: .omitted, time: .standard)
                    )
                }
            } else {
                ChartPlaceholder(text: "Warte auf GPS-Signal …")
            }
        }
    }
}
