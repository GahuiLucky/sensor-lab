import SwiftUI

struct ToolRunnerView: View {
    let toolID: UUID

    @EnvironmentObject private var store: ToolStore
    @EnvironmentObject private var engine: SensorEngine
    @Environment(\.dismiss) private var dismiss

    @StateObject private var runtime = ToolRuntime()
    @State private var showEditor = false

    private let timer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()

    private var tool: SensorTool? {
        store.tool(id: toolID)
    }

    var body: some View {
        ZStack {
            ScreenBackground()

            if let tool = tool {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        header(tool)

                        if runtime.isAlarming {
                            alarmBanner(tool)
                        }

                        visualization(tool)
                        statistics(tool)
                        configuration(tool)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 30)
                }
            } else {
                VStack(spacing: 14) {
                    Text("Tool nicht gefunden")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                    Button("Schließen") { dismiss() }
                        .foregroundStyle(Theme.cyan)
                }
            }
        }
        .onReceive(timer) { _ in
            if let tool = tool {
                runtime.sample(tool: tool, engine: engine)
            }
        }
        .sheet(isPresented: $showEditor) {
            if let tool = tool {
                ToolEditorView(tool: tool) { updated in
                    store.update(updated)
                }
            }
        }
    }

    // MARK: - Kopf

    private func header(_ tool: SensorTool) -> some View {
        HStack(spacing: 10) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.white.opacity(0.08)))
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(tool.name)
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("\(tool.source.title) · \(tool.transform.title)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.45))
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            if runtime.isAlarming {
                Text("ALARM")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(Theme.red)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Theme.red.opacity(0.16)))
            }

            Button {
                showEditor = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.white.opacity(0.08)))
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Alarm

    private func alarmBanner(_ tool: SensorTool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.red)
            VStack(alignment: .leading, spacing: 2) {
                Text("Alarm ausgelöst")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                Text("Wert \(tool.formatted(runtime.value)) \(tool.unit) \(tool.alertAbove ? "über" : "unter") Schwelle \(tool.formatted(tool.threshold)) \(tool.unit)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.red.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Theme.red.opacity(0.28), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.2), value: runtime.isAlarming)
    }

    // MARK: - Darstellung

    private func visualization(_ tool: SensorTool) -> some View {
        Card(title: "Live", icon: tool.visualization.symbol, tint: tool.color) {
            switch tool.visualization {
            case .number:
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text(tool.formatted(runtime.value))
                        .monoValue(52, weight: .bold)
                        .foregroundStyle(tool.color)
                        .lineLimit(1)
                        .minimumScaleFactor(0.4)
                    Text(tool.unit)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.4))
                    Spacer(minLength: 0)
                }
                MeterBar(level: tool.progress(runtime.value), tint: tool.color)
                rangeRow(tool)

            case .line:
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text(tool.formatted(runtime.value))
                        .monoValue(34, weight: .bold)
                        .foregroundStyle(tool.color)
                    Text(tool.unit)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.4))
                    Spacer(minLength: 0)
                }
                if runtime.trace.values.count > 2 {
                    LineChart(
                        series: [
                            ChartSeries(id: "value", label: tool.name, color: tool.color, values: runtime.trace.values)
                        ],
                        height: 200
                    )
                } else {
                    ChartPlaceholder()
                }

            case .gauge:
                ZStack {
                    RingGauge(progress: tool.progress(runtime.value), color: tool.color, lineWidth: 14)
                        .frame(width: 208, height: 208)
                    VStack(spacing: 2) {
                        Text(tool.formatted(runtime.value))
                            .monoValue(36, weight: .bold)
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                        Text(tool.unit)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                rangeRow(tool)

            case .bar:
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text(tool.formatted(runtime.value))
                        .monoValue(44, weight: .bold)
                        .foregroundStyle(tool.color)
                        .lineLimit(1)
                        .minimumScaleFactor(0.45)
                    Text(tool.unit)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.4))
                    Spacer(minLength: 0)
                }
                MeterBar(level: tool.progress(runtime.value), tint: tool.color)
                rangeRow(tool)
            }
        }
    }

    private func rangeRow(_ tool: SensorTool) -> some View {
        HStack {
            Text(tool.formatted(tool.gaugeMin))
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white.opacity(0.3))
            Spacer()
            Text(tool.formatted(tool.gaugeMax))
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white.opacity(0.3))
        }
    }

    // MARK: - Statistik

    private func statistics(_ tool: SensorTool) -> some View {
        let values = runtime.trace.values
        let average = values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
        let minimum = values.min() ?? 0
        let maximum = values.max() ?? 0

        return HStack(spacing: 10) {
            statBox("Ø", tool.formatted(average), tint: tool.color)
            statBox("Min", tool.formatted(minimum), tint: Theme.cyan)
            statBox("Max", tool.formatted(maximum), tint: Theme.pink)
        }
    }

    private func statBox(_ title: String, _ value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 8, weight: .bold))
                .tracking(1.1)
                .foregroundStyle(.white.opacity(0.35))
            Text(value)
                .monoValue(15, weight: .semibold)
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
        )
    }

    // MARK: - Konfiguration

    private func configuration(_ tool: SensorTool) -> some View {
        Card(title: "Konfiguration", icon: "slider.horizontal.3", tint: tool.color) {
            ValueRow(label: "Quelle", value: tool.source.title)
            ValueRow(label: "Umformung", value: tool.transform.title)
            ValueRow(label: "Faktor", value: tool.scale.fixed(2))
            ValueRow(label: "Offset", value: tool.offset.fixed(2))
            ValueRow(label: "Darstellung", value: tool.visualization.title)
            ValueRow(label: "Fenster", value: "\(runtime.trace.values.count) Punkte")

            if tool.alertEnabled {
                ValueRow(
                    label: "Alarm",
                    value: "\(tool.alertAbove ? "über" : "unter") \(tool.formatted(tool.threshold)) \(tool.unit)",
                    tint: Theme.red
                )
            }
        }
    }
}
