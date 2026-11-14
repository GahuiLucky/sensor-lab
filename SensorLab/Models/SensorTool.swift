import SwiftUI

// MARK: - Sensorquellen

enum SensorSource: String, Codable, CaseIterable, Identifiable {
    case accelerationX, accelerationY, accelerationZ, accelerationMagnitude
    case rotationX, rotationY, rotationZ, rotationMagnitude
    case roll, pitch, yaw
    case gravity, magneticField
    case altitude, pressure
    case soundLevel, speed, heading
    case steps, cadence

    var id: String { rawValue }

    var title: String {
        switch self {
        case .accelerationX: return "Accel X"
        case .accelerationY: return "Accel Y"
        case .accelerationZ: return "Accel Z"
        case .accelerationMagnitude: return "Accel Betrag"
        case .rotationX: return "Gyro X"
        case .rotationY: return "Gyro Y"
        case .rotationZ: return "Gyro Z"
        case .rotationMagnitude: return "Gyro Betrag"
        case .roll: return "Roll"
        case .pitch: return "Nick"
        case .yaw: return "Gier"
        case .gravity: return "Schwerkraft"
        case .magneticField: return "Magnetfeld"
        case .altitude: return "Rel. Höhe"
        case .pressure: return "Luftdruck"
        case .soundLevel: return "Schallpegel"
        case .speed: return "Tempo"
        case .heading: return "Kompass"
        case .steps: return "Schritte"
        case .cadence: return "Kadenz"
        }
    }

    var unit: String {
        switch self {
        case .accelerationX, .accelerationY, .accelerationZ, .accelerationMagnitude, .gravity:
            return "g"
        case .rotationX, .rotationY, .rotationZ, .rotationMagnitude:
            return "°/s"
        case .roll, .pitch, .yaw, .heading:
            return "°"
        case .magneticField:
            return "µT"
        case .altitude:
            return "m"
        case .pressure:
            return "hPa"
        case .soundLevel:
            return "dB"
        case .speed:
            return "km/h"
        case .steps:
            return ""
        case .cadence:
            return "S/min"
        }
    }

    var symbol: String {
        switch self {
        case .accelerationX, .accelerationY, .accelerationZ, .accelerationMagnitude:
            return "move.3d"
        case .rotationX, .rotationY, .rotationZ, .rotationMagnitude:
            return "gyroscope"
        case .roll, .pitch, .yaw:
            return "rotate.3d"
        case .gravity:
            return "arrow.down"
        case .magneticField:
            return "sensor.tag.radiowaves.forward"
        case .altitude:
            return "arrow.up.right"
        case .pressure:
            return "barometer"
        case .soundLevel:
            return "ear"
        case .speed:
            return "speedometer"
        case .heading:
            return "location.north.fill"
        case .steps:
            return "figure.walk"
        case .cadence:
            return "stopwatch"
        }
    }

    var defaultRange: ClosedRange<Double> {
        switch self {
        case .accelerationX, .accelerationY, .accelerationZ:
            return -1...1
        case .accelerationMagnitude:
            return 0...1
        case .rotationX, .rotationY, .rotationZ, .rotationMagnitude:
            return -180...180
        case .roll, .pitch:
            return -90...90
        case .yaw, .heading:
            return 0...360
        case .gravity:
            return 0...2
        case .magneticField:
            return 0...100
        case .altitude:
            return -20...20
        case .pressure:
            return 950...1050
        case .soundLevel:
            return -80...0
        case .speed:
            return 0...30
        case .steps:
            return 0...10000
        case .cadence:
            return 0...200
        }
    }

    func value(in engine: SensorEngine) -> Double {
        switch self {
        case .accelerationX: return engine.acceleration.x
        case .accelerationY: return engine.acceleration.y
        case .accelerationZ: return engine.acceleration.z
        case .accelerationMagnitude: return engine.accelerationMagnitude
        case .rotationX: return engine.rotationRateDegrees.x
        case .rotationY: return engine.rotationRateDegrees.y
        case .rotationZ: return engine.rotationRateDegrees.z
        case .rotationMagnitude: return engine.rotationRateDegrees.magnitude
        case .roll: return engine.attitude.rollDegrees
        case .pitch: return engine.attitude.pitchDegrees
        case .yaw: return engine.attitude.yawDegrees
        case .gravity: return engine.gravity.magnitude
        case .magneticField: return engine.totalMagneticField
        case .altitude: return engine.relativeAltitude
        case .pressure: return engine.pressure
        case .soundLevel: return engine.soundDB
        case .speed: return engine.speedKmh
        case .heading: return engine.heading
        case .steps: return Double(engine.steps)
        case .cadence: return engine.cadence
        }
    }
}

// MARK: - Signalform & Darstellung

enum ToolTransform: String, Codable, CaseIterable, Identifiable {
    case raw, absolute, smoothed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .raw: return "Rohwert"
        case .absolute: return "Betrag"
        case .smoothed: return "Geglättet"
        }
    }
}

enum ToolVisualization: String, Codable, CaseIterable, Identifiable {
    case number, line, gauge, bar

    var id: String { rawValue }

    var title: String {
        switch self {
        case .number: return "Zahl"
        case .line: return "Linie"
        case .gauge: return "Ring"
        case .bar: return "Balken"
        }
    }

    var symbol: String {
        switch self {
        case .number: return "textformat.123"
        case .line: return "waveform.path.ecg"
        case .gauge: return "circle.dashed"
        case .bar: return "chart.bar.fill"
        }
    }
}

enum ToolPalette {
    static let colors: [Color] = [Theme.cyan, Theme.green, Theme.pink, Theme.violet, Theme.amber, Theme.red]
    static let names: [String] = ["Cyan", "Grün", "Pink", "Violett", "Amber", "Rot"]

    static func color(_ index: Int) -> Color {
        colors[min(max(index, 0), colors.count - 1)]
    }
}

// MARK: - Tool-Definition

struct SensorTool: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var symbol: String
    var colorIndex: Int
    var source: SensorSource
    var transform: ToolTransform
    var smoothing: Double
    var scale: Double
    var offset: Double
    var visualization: ToolVisualization
    var gaugeMin: Double
    var gaugeMax: Double
    var alertEnabled: Bool
    var alertAbove: Bool
    var threshold: Double
    var haptics: Bool

    static let symbolChoices: [String] = [
        "gauge", "waveform", "speedometer", "gyroscope", "location.north.fill", "figure.walk",
        "ear", "barometer", "thermometer", "bolt.fill", "scope", "ruler"
    ]

    init(
        id: UUID = UUID(),
        name: String,
        symbol: String,
        colorIndex: Int,
        source: SensorSource,
        transform: ToolTransform = .raw,
        smoothing: Double = 0.25,
        scale: Double = 1,
        offset: Double = 0,
        visualization: ToolVisualization = .number,
        gaugeMin: Double = 0,
        gaugeMax: Double = 100,
        alertEnabled: Bool = false,
        alertAbove: Bool = true,
        threshold: Double = 0,
        haptics: Bool = true
    ) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.colorIndex = colorIndex
        self.source = source
        self.transform = transform
        self.smoothing = smoothing
        self.scale = scale
        self.offset = offset
        self.visualization = visualization
        self.gaugeMin = gaugeMin
        self.gaugeMax = gaugeMax
        self.alertEnabled = alertEnabled
        self.alertAbove = alertAbove
        self.threshold = threshold
        self.haptics = haptics
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Tool"
        symbol = try container.decodeIfPresent(String.self, forKey: .symbol) ?? "gauge"
        colorIndex = try container.decodeIfPresent(Int.self, forKey: .colorIndex) ?? 0
        source = try container.decodeIfPresent(SensorSource.self, forKey: .source) ?? .accelerationMagnitude
        transform = try container.decodeIfPresent(ToolTransform.self, forKey: .transform) ?? .raw
        smoothing = try container.decodeIfPresent(Double.self, forKey: .smoothing) ?? 0.25
        scale = try container.decodeIfPresent(Double.self, forKey: .scale) ?? 1
        offset = try container.decodeIfPresent(Double.self, forKey: .offset) ?? 0
        visualization = try container.decodeIfPresent(ToolVisualization.self, forKey: .visualization) ?? .number
        gaugeMin = try container.decodeIfPresent(Double.self, forKey: .gaugeMin) ?? 0
        gaugeMax = try container.decodeIfPresent(Double.self, forKey: .gaugeMax) ?? 100
        alertEnabled = try container.decodeIfPresent(Bool.self, forKey: .alertEnabled) ?? false
        alertAbove = try container.decodeIfPresent(Bool.self, forKey: .alertAbove) ?? true
        threshold = try container.decodeIfPresent(Double.self, forKey: .threshold) ?? 0
        haptics = try container.decodeIfPresent(Bool.self, forKey: .haptics) ?? true
    }

    var color: Color { ToolPalette.color(colorIndex) }
    var unit: String { source.unit }

    func scaledValue(_ raw: Double) -> Double {
        raw * scale + offset
    }

    func formatted(_ value: Double) -> String {
        switch source {
        case .steps:
            return Int(value.rounded()).grouped
        case .cadence, .soundLevel, .pressure:
            return value.fixed(0)
        case .accelerationX, .accelerationY, .accelerationZ, .accelerationMagnitude, .gravity:
            return value.fixed(2)
        default:
            return value.fixed(1)
        }
    }

    func progress(_ value: Double) -> Double {
        let span = gaugeMax - gaugeMin
        guard abs(span) > 0.000_001 else { return 0 }
        return min(max((value - gaugeMin) / span, 0), 1)
    }

    var rangeDescription: String {
        "\(formatted(gaugeMin)) – \(formatted(gaugeMax))"
    }

    static func blank() -> SensorTool {
        var tool = SensorTool(
            name: "Mein Tool",
            symbol: "gauge",
            colorIndex: 0,
            source: .accelerationMagnitude,
            transform: .raw,
            visualization: .number
        )
        let range = tool.source.defaultRange
        tool.gaugeMin = range.lowerBound
        tool.gaugeMax = range.upperBound
        return tool
    }

    static func presets() -> [SensorTool] {
        [
            SensorTool(
                name: "Wasserwaage",
                symbol: "ruler",
                colorIndex: 1,
                source: .roll,
                transform: .absolute,
                visualization: .bar,
                gaugeMin: 0,
                gaugeMax: 30,
                alertEnabled: true,
                alertAbove: false,
                threshold: 1.0,
                haptics: true
            ),
            SensorTool(
                name: "Erschütterung",
                symbol: "bolt.fill",
                colorIndex: 5,
                source: .accelerationMagnitude,
                transform: .raw,
                visualization: .number,
                gaugeMin: 0,
                gaugeMax: 1,
                alertEnabled: true,
                alertAbove: true,
                threshold: 0.25,
                haptics: true
            ),
            SensorTool(
                name: "Lärmampel",
                symbol: "ear",
                colorIndex: 4,
                source: .soundLevel,
                transform: .raw,
                visualization: .gauge,
                gaugeMin: -80,
                gaugeMax: 0,
                alertEnabled: true,
                alertAbove: true,
                threshold: -30,
                haptics: false
            ),
            SensorTool(
                name: "Tempo",
                symbol: "speedometer",
                colorIndex: 0,
                source: .speed,
                transform: .smoothed,
                visualization: .gauge,
                gaugeMin: 0,
                gaugeMax: 25
            ),
            SensorTool(
                name: "Schrittziel",
                symbol: "figure.walk",
                colorIndex: 1,
                source: .steps,
                transform: .raw,
                visualization: .gauge,
                gaugeMin: 0,
                gaugeMax: 10000,
                alertEnabled: true,
                alertAbove: true,
                threshold: 10000,
                haptics: true
            ),
            SensorTool(
                name: "Höhenprofil",
                symbol: "arrow.up.right",
                colorIndex: 3,
                source: .altitude,
                transform: .smoothed,
                visualization: .line,
                gaugeMin: -10,
                gaugeMax: 10
            )
        ]
    }
}
