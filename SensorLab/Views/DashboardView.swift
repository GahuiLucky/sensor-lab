import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var engine: SensorEngine
    @State private var showSettings = false

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    header

                    if !engine.availability.hasAnyMotionSensor && !engine.demoMode {
                        UnavailableBanner(
                            title: "Keine Bewegungssensoren gefunden",
                            message: "Der Simulator liefert keine Accelerometer-, Gyro- oder Barometerdaten. Aktiviere den Demo-Modus in den Einstellungen."
                        )
                    }

                    heroCard
                    motionCard
                    ringRow
                    metricGrid
                    compassCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 28)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(engine)
        }
    }

    // MARK: - Kopfbereich

    private var header: some View {
        HStack(alignment: .center, spacing: 9) {
            ScreenTitle(title: "Sensor Lab", subtitle: subtitle)
            Spacer(minLength: 4)
            LivePill(isLive: !engine.isPaused)
            CircleIconButton(systemName: engine.isPaused ? "play.fill" : "pause.fill") {
                engine.togglePause()
            }
            CircleIconButton(systemName: "slider.horizontal.3") {
                showSettings = true
            }
        }
    }

    private var subtitle: String {
        engine.demoMode ? "Demo-Modus · simulierte Werte" : "Alle Sensoren live"
    }

    // MARK: - Lage

    private var heroCard: some View {
        Card(title: "Lage & Neigung", icon: "gyroscope", tint: Theme.cyan) {
            HStack(alignment: .center, spacing: 16) {
                AttitudeView(attitude: engine.attitude)
                    .frame(width: 118, height: 118)

                VStack(alignment: .leading, spacing: 9) {
                    ValueRow(label: "Roll", value: "\(engine.attitude.rollDegrees.fixed(1))°", tint: Theme.cyan)
                    ValueRow(label: "Nick", value: "\(engine.attitude.pitchDegrees.fixed(1))°", tint: Theme.violet)
                    ValueRow(label: "Gier", value: "\(engine.attitude.yawDegrees.fixed(0))°", tint: Theme.pink)
                    Divider().overlay(Color.white.opacity(0.08))
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.green)
                        Text("Schwerkraft \(engine.gravity.magnitude.fixed(2)) g")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
        }
    }

    // MARK: - Beschleunigung

    private var motionCard: some View {
        Card(title: "Beschleunigung", icon: "waveform.path.ecg", tint: Theme.green) {
            HStack(spacing: 12) {
                LegendChip(label: "X", value: "\(engine.acceleration.x.fixed(2)) g", color: Theme.green)
                LegendChip(label: "Y", value: "\(engine.acceleration.y.fixed(2)) g", color: Theme.cyan)
                LegendChip(label: "Z", value: "\(engine.acceleration.z.fixed(2)) g", color: Theme.pink)
            }

            if engine.accelTrace.count > 2 {
                LineChart(series: accelSeries, height: 140)
            } else {
                ChartPlaceholder()
            }
        }
    }

    private var accelSeries: [ChartSeries] {
        [
            ChartSeries(id: "x", label: "X", color: Theme.green, values: engine.accelTrace.x),
            ChartSeries(id: "y", label: "Y", color: Theme.cyan, values: engine.accelTrace.y),
            ChartSeries(id: "z", label: "Z", color: Theme.pink, values: engine.accelTrace.z)
        ]
    }

    // MARK: - Ringe

    private var ringRow: some View {
        HStack(spacing: 12) {
            MiniRingCard(
                title: "Schritte",
                value: engine.steps.grouped,
                progress: engine.stepsProgress,
                tint: Theme.green,
                icon: "figure.walk"
            )
            MiniRingCard(
                title: "Akku",
                value: engine.batteryPercent >= 0 ? "\(engine.batteryPercent) %" : "–",
                progress: max(engine.batteryLevel, 0),
                tint: Theme.amber,
                icon: "battery.100"
            )
            MiniRingCard(
                title: "Pegel",
                value: "\(Int(engine.soundDB.rounded())) dB",
                progress: engine.soundLevel,
                tint: Theme.pink,
                icon: "waveform"
            )
        }
    }

    // MARK: - Kennzahlen

    private var metricGrid: some View {
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
                title: "Höhe",
                value: engine.location.hasFix ? engine.location.altitude.fixed(0) : "–",
                unit: "m",
                icon: "arrow.up.right",
                tint: Theme.violet
            )
            MetricTile(
                title: "Luftdruck",
                value: engine.pressure > 0 ? engine.pressure.fixed(1) : "–",
                unit: "hPa",
                icon: "barometer",
                tint: Theme.amber
            )
            MetricTile(
                title: "Schallpegel",
                value: "\(Int(engine.soundDB.rounded()))",
                unit: "dB",
                icon: "ear",
                tint: Theme.pink
            )
            MetricTile(
                title: "Magnetfeld",
                value: engine.totalMagneticField.fixed(0),
                unit: "µT",
                icon: "sensor.tag.radiowaves.forward",
                tint: Theme.green
            )
            MetricTile(
                title: "Drehrate",
                value: engine.rotationRateDegrees.magnitude.fixed(1),
                unit: "°/s",
                icon: "gyroscope",
                tint: Theme.cyan
            )
        }
    }

    // MARK: - Kompass

    private var compassCard: some View {
        Card(title: "Kompass", icon: "location.north.fill", tint: Theme.pink) {
            HStack(spacing: 18) {
                CompassDial(heading: engine.heading, showReadout: false)
                    .frame(width: 132, height: 132)

                VStack(alignment: .leading, spacing: 9) {
                    ValueRow(label: "Richtung", value: "\(Int(engine.heading.rounded()))°", tint: Theme.pink)
                    ValueRow(
                        label: "Genauigkeit",
                        value: engine.hasHeading ? "± \(Int(engine.headingAccuracy.rounded()))°" : "–"
                    )
                    ValueRow(
                        label: "Breite",
                        value: engine.location.hasFix ? "\(engine.location.latitude.fixed(5))°" : "–"
                    )
                    ValueRow(
                        label: "Länge",
                        value: engine.location.hasFix ? "\(engine.location.longitude.fixed(5))°" : "–"
                    )
                }
            }
        }
    }
}
