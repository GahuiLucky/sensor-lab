import SwiftUI
import UIKit

struct ToolEditorView: View {
    @EnvironmentObject private var engine: SensorEngine
    @Environment(\.dismiss) private var dismiss

    @State private var draft: SensorTool
    private let onSave: (SensorTool) -> Void

    init(tool: SensorTool, onSave: @escaping (SensorTool) -> Void) {
        _draft = State(initialValue: tool)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScreenBackground()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        nameCard
                        sourceCard
                        transformCard
                        visualizationCard
                        alertCard
                        livePreviewCard
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Tool")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") { dismiss() }
                        .foregroundStyle(.white.opacity(0.7))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sichern") { save() }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.cyan)
                        .disabled(draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Name, Symbol, Farbe

    private var nameCard: some View {
        Card(title: "Name & Symbol", icon: "character.cursor.ibeam", tint: draft.color) {
            TextField("Name", text: $draft.name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.07))
                )

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6),
                spacing: 8
            ) {
                ForEach(SensorTool.symbolChoices, id: \.self) { symbol in
                    Button {
                        draft.symbol = symbol
                    } label: {
                        Image(systemName: symbol)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(draft.symbol == symbol ? Color.white : Color.white.opacity(0.45))
                            .frame(maxWidth: .infinity)
                            .frame(height: 34)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(draft.symbol == symbol ? draft.color.opacity(0.25) : Color.white.opacity(0.04))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 9) {
                ForEach(0..<ToolPalette.colors.count, id: \.self) { index in
                    Button {
                        draft.colorIndex = index
                    } label: {
                        Circle()
                            .fill(ToolPalette.color(index))
                            .frame(width: 26, height: 26)
                            .overlay(
                                Circle().strokeBorder(
                                    Color.white.opacity(draft.colorIndex == index ? 0.9 : 0.12),
                                    lineWidth: draft.colorIndex == index ? 2 : 1
                                )
                            )
                    }
                    .buttonStyle(.plain)
                }
                Spacer(minLength: 0)
            }
        }
    }

    // MARK: - Quelle

    private var sourceCard: some View {
        Card(title: "Sensorquelle", icon: "dot.radiowaves.left.and.right", tint: draft.color) {
            Picker("Quelle", selection: $draft.source) {
                ForEach(SensorSource.allCases) { source in
                    Text("\(source.title) · \(source.unit.isEmpty ? "Anzahl" : source.unit)")
                        .tag(source)
                }
            }
            .pickerStyle(.menu)
            .tint(draft.color)

            Text("Messbereich des Sensors: \(sourceRangeText)")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.35))
        }
    }

    // MARK: - Signalform

    private var transformCard: some View {
        Card(title: "Signalform", icon: "function", tint: draft.color) {
            Picker("Umformung", selection: $draft.transform) {
                ForEach(ToolTransform.allCases) { item in
                    Text(item.title).tag(item)
                }
            }
            .pickerStyle(.segmented)

            if draft.transform == .smoothed {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Glättung")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.65))
                        Spacer()
                        Text(draft.smoothing.fixed(2))
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(draft.color)
                    }
                    Slider(value: $draft.smoothing, in: 0.02...0.95)
                        .tint(draft.color)
                    Text("Klein = träge und ruhig, groß = schnell und direkt")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.white.opacity(0.3))
                }
            }

            HStack(spacing: 10) {
                numberField("Faktor", value: $draft.scale)
                numberField("Offset", value: $draft.offset)
            }
        }
    }

    // MARK: - Darstellung

    private var visualizationCard: some View {
        Card(title: "Darstellung", icon: "square.on.square", tint: draft.color) {
            Picker("Visualisierung", selection: $draft.visualization) {
                ForEach(ToolVisualization.allCases) { item in
                    Text(item.title).tag(item)
                }
            }
            .pickerStyle(.segmented)

            if draft.visualization == .gauge || draft.visualization == .bar {
                HStack(spacing: 10) {
                    numberField("Min", value: $draft.gaugeMin)
                    numberField("Max", value: $draft.gaugeMax)
                }

                Button {
                    let range = draft.source.defaultRange
                    draft.gaugeMin = range.lowerBound
                    draft.gaugeMax = range.upperBound
                } label: {
                    Label("Sensorbereich übernehmen", systemImage: "arrow.counterclockwise")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(draft.color)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Alarm

    private var alertCard: some View {
        Card(title: "Alarm", icon: "bell.badge.fill", tint: draft.color) {
            Toggle(isOn: $draft.alertEnabled) {
                Text("Alarm bei Schwellwert")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .tint(draft.color)

            if draft.alertEnabled {
                Picker("Richtung", selection: $draft.alertAbove) {
                    Text("Über Schwelle").tag(true)
                    Text("Unter Schwelle").tag(false)
                }
                .pickerStyle(.segmented)

                numberField("Schwelle", value: $draft.threshold)

                Toggle(isOn: $draft.haptics) {
                    Text("Haptisches Feedback")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .tint(draft.color)
            }
        }
    }

    // MARK: - Vorschau

    private var livePreviewCard: some View {
        Card(title: "Live-Vorschau", icon: "eye.fill", tint: draft.color) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(draft.formatted(previewValue))
                    .monoValue(34, weight: .bold)
                    .foregroundStyle(draft.color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text(draft.unit)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.4))

                Spacer()

                if isPreviewAlarming {
                    Text("ALARM")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1.2)
                        .foregroundStyle(Theme.red)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Theme.red.opacity(0.15)))
                }
            }

            Text("\(draft.source.title) · \(draft.transform.title)")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.35))
        }
    }

    // MARK: - Helfer

    private var sourceRangeText: String {
        let range = draft.source.defaultRange
        return "\(draft.formatted(range.lowerBound)) – \(draft.formatted(range.upperBound)) \(draft.unit)"
    }

    private func numberField(_ title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title.uppercased())
                .font(.system(size: 8, weight: .bold))
                .tracking(1.1)
                .foregroundStyle(.white.opacity(0.35))
            TextField("0", value: value, format: .number)
                .keyboardType(.numbersAndPunctuation)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(0.07))
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var previewValue: Double {
        var raw = draft.source.value(in: engine)
        if draft.transform == .absolute {
            raw = abs(raw)
        }
        return draft.scaledValue(raw)
    }

    private var isPreviewAlarming: Bool {
        guard draft.alertEnabled else { return false }
        return draft.alertAbove ? previewValue > draft.threshold : previewValue < draft.threshold
    }

    private func save() {
        var tool = draft
        tool.name = tool.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if abs(tool.gaugeMax - tool.gaugeMin) < 0.000_001 {
            tool.gaugeMax = tool.gaugeMin + 1
        }
        onSave(tool)
        dismiss()
    }
}
