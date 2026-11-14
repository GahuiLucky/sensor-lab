import Foundation
import CoreMotion

final class MovementService {
    private let activityManager = CMMotionActivityManager()
    private let pedometer = CMPedometer()
    private let altimeter = CMAltimeter()

    var onPedometer: ((CMPedometerData) -> Void)?
    var onActivity: ((CMMotionActivity) -> Void)?
    var onAltitude: ((CMAltitudeData) -> Void)?

    var isStepCountingAvailable: Bool { CMPedometer.isStepCountingAvailable() }
    var isDistanceAvailable: Bool { CMPedometer.isDistanceAvailable() }
    var isFloorCountingAvailable: Bool { CMPedometer.isFloorCountingAvailable() }
    var isPaceAvailable: Bool { CMPedometer.isPaceAvailable() }
    var isCadenceAvailable: Bool { CMPedometer.isCadenceAvailable() }
    var isActivityAvailable: Bool { CMMotionActivityManager.isActivityAvailable() }
    var isAltimeterAvailable: Bool { CMAltimeter.isRelativeAltitudeAvailable() }

    func startPedometer(from date: Date) {
        guard CMPedometer.isStepCountingAvailable() else { return }
        pedometer.startUpdates(from: date) { [weak self] data, _ in
            guard let data else { return }
            DispatchQueue.main.async {
                self?.onPedometer?(data)
            }
        }
    }

    func startActivityUpdates() {
        guard CMMotionActivityManager.isActivityAvailable() else { return }
        activityManager.startActivityUpdates(to: .main) { [weak self] activity in
            guard let activity else { return }
            self?.onActivity?(activity)
        }
    }

    func startAltimeter() {
        guard CMAltimeter.isRelativeAltitudeAvailable() else { return }
        altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] data, _ in
            guard let data else { return }
            self?.onAltitude?(data)
        }
    }

    func stop() {
        pedometer.stopUpdates()
        activityManager.stopActivityUpdates()
        altimeter.stopRelativeAltitudeUpdates()
    }
}
