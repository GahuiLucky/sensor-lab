import Foundation
import SwiftUI

// MARK: - Vektoren & Lage

struct Vector3: Equatable {
    var x: Double
    var y: Double
    var z: Double

    static let zero = Vector3(x: 0, y: 0, z: 0)

    var magnitude: Double { (x * x + y * y + z * z).squareRoot() }

    func scaled(by factor: Double) -> Vector3 {
        Vector3(x: x * factor, y: y * factor, z: z * factor)
    }
}

struct AttitudeReading: Equatable {
    var roll: Double = 0
    var pitch: Double = 0
    var yaw: Double = 0

    var rollDegrees: Double { roll * 180 / .pi }
    var pitchDegrees: Double { pitch * 180 / .pi }
    var yawDegrees: Double { yaw * 180 / .pi }
}

// MARK: - Ringpuffer für Live-Diagramme

struct Trace: Equatable {
    private(set) var x: [Double] = []
    private(set) var y: [Double] = []
    private(set) var z: [Double] = []
    var capacity: Int = 180

    init(capacity: Int = 180) {
        self.capacity = capacity
    }

    var count: Int { x.count }
    var isEmpty: Bool { x.isEmpty }

    mutating func append(_ vector: Vector3) {
        x.append(vector.x)
        y.append(vector.y)
        z.append(vector.z)
        trim()
    }

    mutating func clear() {
        x.removeAll(keepingCapacity: true)
        y.removeAll(keepingCapacity: true)
        z.removeAll(keepingCapacity: true)
    }

    func scaled(by factor: Double) -> Trace {
        var copy = self
        copy.x = x.map { $0 * factor }
        copy.y = y.map { $0 * factor }
        copy.z = z.map { $0 * factor }
        return copy
    }

    private mutating func trim() {
        let overflow = x.count - capacity
        guard overflow > 0 else { return }
        x.removeFirst(overflow)
        y.removeFirst(overflow)
        z.removeFirst(overflow)
    }
}

struct ValueTrace: Equatable {
    private(set) var values: [Double] = []
    var capacity: Int = 150

    init(capacity: Int = 150) {
        self.capacity = capacity
    }

    var latest: Double { values.last ?? 0 }
    var peak: Double { values.max() ?? 0 }
    var average: Double { values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count) }

    mutating func append(_ value: Double) {
        values.append(value)
        let overflow = values.count - capacity
        if overflow > 0 { values.removeFirst(overflow) }
    }

    mutating func clear() {
        values.removeAll(keepingCapacity: true)
    }
}

// MARK: - Standort

struct LocationReading: Equatable {
    var latitude: Double = 0
    var longitude: Double = 0
    var altitude: Double = 0
    var speed: Double = 0
    var course: Double = 0
    var horizontalAccuracy: Double = 0
    var verticalAccuracy: Double = 0
    var speedAccuracy: Double = 0
    var timestamp: Date?
    var hasFix: Bool = false
}

// MARK: - Aktivität

enum ActivityKind: String {
    case unknown
    case stationary
    case walking
    case running
    case cycling
    case automotive

    var title: String {
        switch self {
        case .unknown: return "Unbekannt"
        case .stationary: return "Stationär"
        case .walking: return "Gehen"
        case .running: return "Laufen"
        case .cycling: return "Radfahren"
        case .automotive: return "Fahrzeug"
        }
    }

    var symbol: String {
        switch self {
        case .unknown: return "questionmark.circle.fill"
        case .stationary: return "pause.circle.fill"
        case .walking: return "figure.walk"
        case .running: return "figure.run"
        case .cycling: return "bicycle"
        case .automotive: return "car.fill"
        }
    }

    var tint: Color {
        switch self {
        case .unknown: return Color.white.opacity(0.6)
        case .stationary: return Theme.amber
        case .walking: return Theme.green
        case .running: return Theme.pink
        case .cycling: return Theme.cyan
        case .automotive: return Theme.violet
        }
    }
}

// MARK: - Formatierung

extension Double {
    func fixed(_ digits: Int = 1) -> String {
        String(format: "%.\(digits)f", self)
    }

    var degrees: Double { self * 180 / .pi }
}

extension Int {
    var grouped: String { formatted(.number) }
}
