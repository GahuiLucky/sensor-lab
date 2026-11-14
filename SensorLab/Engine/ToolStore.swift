import Foundation
import Combine
import UIKit

// MARK: - Persistenz

final class ToolStore: ObservableObject {
    @Published private(set) var tools: [SensorTool] = []

    private let storageKey = "sensorlab.tools.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([SensorTool].self, from: data),
           !decoded.isEmpty {
            tools = decoded
        } else {
            tools = SensorTool.presets()
            persist()
        }
    }

    func tool(id: UUID) -> SensorTool? {
        tools.first { $0.id == id }
    }

    func add(_ tool: SensorTool) {
        tools.append(tool)
        persist()
    }

    func update(_ tool: SensorTool) {
        guard let index = tools.firstIndex(where: { $0.id == tool.id }) else { return }
        tools[index] = tool
        persist()
    }

    func delete(_ tool: SensorTool) {
        tools.removeAll { $0.id == tool.id }
        persist()
    }

    func resetPresets() {
        tools = SensorTool.presets()
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(tools) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}

// MARK: - Laufzeit eines Tools

final class ToolRuntime: ObservableObject {
    @Published private(set) var value: Double = 0
    @Published private(set) var trace = ValueTrace(capacity: 180)
    @Published private(set) var isAlarming = false

    private var smoothedValue: Double?
    private var lastHaptic = Date.distantPast
    private let impact = UIImpactFeedbackGenerator(style: .medium)
    private let warning = UINotificationFeedbackGenerator()

    func sample(tool: SensorTool, engine: SensorEngine) {
        let raw = tool.source.value(in: engine)
        var transformed = raw

        switch tool.transform {
        case .raw:
            smoothedValue = nil
        case .absolute:
            transformed = abs(raw)
            smoothedValue = nil
        case .smoothed:
            let alpha = min(max(tool.smoothing, 0.02), 0.95)
            if let current = smoothedValue {
                smoothedValue = current + (raw - current) * alpha
            } else {
                smoothedValue = raw
            }
            transformed = smoothedValue ?? raw
        }

        let scaled = tool.scaledValue(transformed)
        value = scaled
        trace.append(scaled)
        updateAlarm(tool: tool, value: scaled)
    }

    func reset() {
        value = 0
        trace.clear()
        isAlarming = false
        smoothedValue = nil
    }

    private func updateAlarm(tool: SensorTool, value: Double) {
        let alarm = tool.alertEnabled && (tool.alertAbove ? value > tool.threshold : value < tool.threshold)

        if alarm == isAlarming {
            if alarm && tool.haptics && Date().timeIntervalSince(lastHaptic) > 1.6 {
                impact.impactOccurred()
                lastHaptic = Date()
            }
            return
        }

        isAlarming = alarm
        if alarm && tool.haptics {
            warning.notificationOccurred(.warning)
            lastHaptic = Date()
        }
    }
}
