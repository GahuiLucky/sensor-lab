import Foundation
import UIKit

final class DeviceMonitor {
    private var observers: [NSObjectProtocol] = []
    var onChange: (() -> Void)?

    var modelIdentifier: String {
        var info = utsname()
        uname(&info)
        let mirror = Mirror(reflecting: info.machine)
        return mirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
    }

    var screenBrightness: Double {
        let screen = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.screen
        return Double(screen?.brightness ?? 0)
    }

    func start() {
        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true
        device.beginGeneratingDeviceOrientationNotifications()

        let center = NotificationCenter.default
        let names: [Notification.Name] = [
            UIDevice.batteryLevelDidChangeNotification,
            UIDevice.batteryStateDidChangeNotification,
            UIDevice.orientationDidChangeNotification,
            ProcessInfo.thermalStateDidChangeNotification,
            Notification.Name.NSProcessInfoPowerStateDidChange
        ]

        for name in names {
            let token = center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                self?.onChange?()
            }
            observers.append(token)
        }
    }

    func stop() {
        let center = NotificationCenter.default
        for observer in observers {
            center.removeObserver(observer)
        }
        observers.removeAll()
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
        UIDevice.current.isProximityMonitoringEnabled = false
    }
}
