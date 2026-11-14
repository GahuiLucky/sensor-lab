import SwiftUI

enum MotionMode: String, CaseIterable, Identifiable {
    case acceleration
    case rotation
    case magnetic
    case attitude

    var id: String { rawValue }

    var title: String {
        switch self {
        case .acceleration: return "Beschleunigung"
        case .rotation: return "Rotation"
        case .magnetic: return "Magnetfeld"
        case .attitude: return "Lage"
        }
    }

    var shortTitle: String {
        switch self {
        case .acceleration: return "Accel"
        case .rotation: return "Gyro"
        case .magnetic: return "Magnet"
        case .attitude: return "Lage"
        }
    }

    var tint: Color {
        switch self {
        case .acceleration: return Theme.green
        case .rotation: return Theme.cyan
        case .magnetic: return Theme.violet
        case .attitude: return Theme.pink
        }
    }
}

struct MotionView: View {
    @EnvironmentObject private var engine: SensorEngine
    @State private var mode: MotionMode = .acceleration

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    picker

                    if !engine.availability.hasAnyMotionSensor && !engine.demoMode {
                        UnavailableBanner(
                            title: "Sensor nicht verfügbar",
                            message: "Auf dem Simulator fehlen Bewegungssensoren. Nutze den Demo-Modus in den Einstellungen."
                        )
                    }

                    content
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 28)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            ScreenTitle(title: "Bewegung", subtitle: "Accelerometer · Gyroskop · Magnetometer")
            Spacer()
            LivePill(isLive: !engine.isPaused)
        }
    }

    private var picker: some View {
        Picker("Sensor", selection: $mode) {
            ForEach(MotionMode.allCases) { item in
                Text(item.shortTitle).tag(item)
            }
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    private var content: some View {
        switch mode {
        case .acceleration:
            vectorDetail(
                trace: engine.accelTrace,
                current: engine.acceleration,
                unit: "g",
                digits: 3,
                tint: Theme.green,
                title: "Beschleunigung"
            )
        case .rotation:
            vectorDetail(
                trace: engine.rotationTrace.scaled(by: 180 / .pi),
                current: engine.rotationRateDegrees,
                unit: "°/s",
                digits: 1,
                tint: Theme.cyan,
                title: "Rotation"
            )
        case .magnetic:
            VStack(spacing: 16) {
                vectorDetail(
                    trace: engine.magneticTrace,
                    current: engine.magneticField,
                    unit: "µT",
                    digits: 1,
                    tint: Theme.violet,
                    title: "Magnetfeld"
                )
                magneticStrengthCard
            }
        case .attitude:
            attitudeContent
        }
    }

    // MARK: - Vektor-Details

    private func vectorDetail(
        trace: Trace,
        current: Vector3,
        unit: String,
        digits: Int,
        tint: Color,
        title: String
    ) -> some View {
        VStack(spacing: 16) {
            Card(title: title, icon: "waveform.path.ecg", tint: tint) {
                HStack(spacing: 12) {
                    LegendChip(label: "X", value: "\(current.x.fixed(digits)) \(unit)", color: Theme.green)
                    LegendChip(label: "Y", value: "\(current.y.fixed(digits)) \(unit)", color: Theme.cyan)
                    LegendChip(label: "Z", value: "\(current.z.fixed(digits)) \(unit)", color: Theme.pink)
                }

                if trace.count > 2 {
                    LineChart(series: series(for: trace), height: 190)
                } else {
                    ChartPlaceholder()
                }
            }

            HStack(spacing: 12) {
                MetricTile(
                    title: "Betrag",
                    value: current.magnitude.fixed(digits),
                    unit: unit,
                    icon: "arrow.up.right",
                    tint: tint
                )
                MetricTile(
                    title: "Spitzenwert",
                    value: magnitudePeak(trace).fixed(digits),
                    unit: unit,
                    icon: "chart.line.uptrend.xyaxis",
                    tint: tint
                )
            }

            Card(title: "Statistik", icon: "chart.bar.fill", tint: tint) {
                HStack {
                    Text("Achse")
                        .frame(width: 46, alignment: .leading)
                    Text("Ø")
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    Text("Min")
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    Text("Max")
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white.opacity(0.35))

                statRow("X", values: trace.x, color: Theme.green, digits: digits)
                statRow("Y", values: trace.y, color: Theme.cyan, digits: digits)
                statRow("Z", values: trace.z, color: Theme.pink, digits: digits)

                Text("Fenster: letzte \(trace.count) Messpunkte")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.white.opacity(0.3))
            }
        }
    }

    private func series(for trace: Trace) -> [ChartSeries] {
        [
            ChartSeries(id: "x", label: "X", color: Theme.green, values: trace.x),
            ChartSeries(id: "y", label: "Y", color: Theme.cyan, values: trace.y),
            ChartSeries(id: "z", label: "Z", color: Theme.pink, values: trace.z)
        ]
    }

    private func statRow(_ label: String, values: [Double], color: Color, digits: Int) -> some View {
        let stats = statistics(values)
        return HStack {
            HStack(spacing: 6) {
                Circle().fill(color).frame(width: 6, height: 6)
                Text(label)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .frame(width: 46, alignment: .leading)

            Text(stats.average.fixed(digits))
                .frame(maxWidth: .infinity, alignment: .trailing)
            Text(stats.minimum.fixed(digits))
                .frame(maxWidth: .infinity, alignment: .trailing)
            Text(stats.maximum.fixed(digits))
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .font(.system(size: 12, weight: .medium, design: .rounded))
        .monospacedDigit()
        .foregroundStyle(.white.opacity(0.85))
    }

    private func statistics(_ values: [Double]) -> (minimum: Double, maximum: Double, average: Double) {
        guard !values.isEmpty else { return (0, 0, 0) }
        return (
            values.min() ?? 0,
            values.max() ?? 0,
            values.reduce(0, +) / Double(values.count)
        )
    }

    private func magnitudePeak(_ trace: Trace) -> Double {
        guard trace.count > 0 else { return 0 }
        var peak: Double = 0
        for index in 0..<trace.count {
            let x = trace.x[index]
            let y = trace.y[index]
            let z = trace.z[index]
            peak = max(peak, (x * x + y * y + z * z).squareRoot())
        }
        return peak
    }

    // MARK: - Magnetfeld

    private var magneticStrengthCard: some View {
        Card(title: "Feldstärke", icon: "sensor.tag.radiowaves.forward", tint: Theme.violet) {
            HStack(spacing: 20) {
                ZStack {
                    RingGauge(
                        progress: min(engine.totalMagneticField / 80, 1),
                        color: Theme.violet,
                        lineWidth: 10
                    )
                    .frame(width: 96, height: 96)

                    VStack(spacing: 0) {
                        Text(engine.totalMagneticField.fixed(1))
                            .monoValue(19, weight: .bold)
                            .foregroundStyle(.white)
                        Text("µT")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }

                VStack(alignment: .leading, spacing: 9) {
                    ValueRow(label: "Erdfeld typisch", value: "25 – 65 µT")
                    ValueRow(label: "X", value: engine.magneticField.x.fixed(1), tint: Theme.green)
                    ValueRow(label: "Y", value: engine.magneticField.y.fixed(1), tint: Theme.cyan)
                    ValueRow(label: "Z", value: engine.magneticField.z.fixed(1), tint: Theme.pink)
                }
            }
        }
    }

    // MARK: - Lage

    private var attitudeContent: some View {
        VStack(spacing: 16) {
            Card(title: "Künstlicher Horizont", icon: "gyroscope", tint: Theme.pink) {
                AttitudeView(attitude: engine.attitude)
                    .frame(height: 220)
            }

            HStack(spacing: 12) {
                MetricTile(
                    title: "Roll",
                    value: engine.attitude.rollDegrees.fixed(1),
                    unit: "°",
                    icon: "gyroscope",
                    tint: Theme.cyan
                )
                MetricTile(
                    title: "Nick",
                    value: engine.attitude.pitchDegrees.fixed(1),
                    unit: "°",
                    icon: "arrow.up.and.down",
                    tint: Theme.violet
                )
            }

            HStack(spacing: 12) {
                MetricTile(
                    title: "Gier",
                    value: engine.attitude.yawDegrees.fixed(0),
                    unit: "°",
                    icon: "arrow.left.and.right",
                    tint: Theme.pink
                )
                MetricTile(
                    title: "Schwerkraft",
                    value: engine.gravity.magnitude.fixed(2),
                    unit: "g",
                    icon: "arrow.down",
                    tint: Theme.green
                )
            }

            Card(title: "Gerätelage", icon: "iphone", tint: Theme.cyan) {
                DeviceTiltView(attitude: engine.attitude)
                    .frame(height: 200)

                HStack(spacing: 12) {
                    LegendChip(label: "gx", value: engine.gravity.x.fixed(2), color: Theme.green)
                    LegendChip(label: "gy", value: engine.gravity.y.fixed(2), color: Theme.cyan)
                    LegendChip(label: "gz", value: engine.gravity.z.fixed(2), color: Theme.pink)
                }
            }
        }
    }
}
