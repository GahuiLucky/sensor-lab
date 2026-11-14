import Foundation
import CoreMotion

struct MotionSample {
    var userAcceleration: Vector3
    var gravity: Vector3
    var rotationRate: Vector3
    var magneticField: Vector3
    var attitude: AttitudeReading
}

final class MotionService {
    private let manager = CMMotionManager()
    var onSample: ((MotionSample) -> Void)?

    var isDeviceMotionAvailable: Bool { manager.isDeviceMotionAvailable }
    var isMagnetometerAvailable: Bool { manager.isMagnetometerAvailable }
    var isGyroAvailable: Bool { manager.isGyroAvailable }
    var isAccelerometerAvailable: Bool { manager.isAccelerometerAvailable }

    func start() {
        guard manager.isDeviceMotionAvailable else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 30.0
        // Das Magnetometer liefert nur in Bezugssystemen mit "Corrected"/"Magnetic" echte Werte.
        let frames = CMMotionManager.availableAttitudeReferenceFrames()
        let frame: CMAttitudeReferenceFrame = frames.contains(.xArbitraryCorrectedZVertical)
            ? .xArbitraryCorrectedZVertical
            : .xArbitraryZVertical
        manager.startDeviceMotionUpdates(using: frame, to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            let sample = MotionSample(
                userAcceleration: Vector3(
                    x: motion.userAcceleration.x,
                    y: motion.userAcceleration.y,
                    z: motion.userAcceleration.z
                ),
                gravity: Vector3(
                    x: motion.gravity.x,
                    y: motion.gravity.y,
                    z: motion.gravity.z
                ),
                rotationRate: Vector3(
                    x: motion.rotationRate.x,
                    y: motion.rotationRate.y,
                    z: motion.rotationRate.z
                ),
                magneticField: Vector3(
                    x: motion.magneticField.field.x,
                    y: motion.magneticField.field.y,
                    z: motion.magneticField.field.z
                ),
                attitude: AttitudeReading(
                    roll: motion.attitude.roll,
                    pitch: motion.attitude.pitch,
                    yaw: motion.attitude.yaw
                )
            )
            self.onSample?(sample)
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
    }
}
