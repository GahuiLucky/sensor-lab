import Foundation
import SwiftUI
import CoreMotion
import CoreLocation
import AVFoundation
import UIKit

final class SensorEngine: ObservableObject {

    struct Availability {
        var deviceMotion = false
        var magnetometer = false
        var gyroscope = false
        var accelerometer = false
        var stepCounting = false
        var distance = false
        var floors = false
        var pace = false
        var cadence = false
        var activity = false
        var barometer = false
        var heading = false

        var hasAnyMotionSensor: Bool { deviceMotion || accelerometer || gyroscope }
    }

    // MARK: - Zustand

    @Published var isPaused = false
    @Published var demoMode = false
    @Published var locationStatus: CLAuthorizationStatus = .notDetermined
    @Published var micDenied = false
    @Published var microphoneActive = false

    // MARK: - Bewegung

    @Published var acceleration = Vector3.zero
    @Published var gravity = Vector3(x: 0, y: 0, z: -1)
    @Published var rotationRate = Vector3.zero
    @Published var magneticField = Vector3.zero
    @Published var attitude = AttitudeReading()
    @Published var accelTrace = Trace()
    @Published var rotationTrace = Trace()
    @Published var magneticTrace = Trace()

    // MARK: - Standort

    @Published var location = LocationReading()
    @Published var heading: Double = 0
    @Published var magneticHeading: Double = 0
    @Published var trueHeading: Double = 0
    @Published var headingAccuracy: Double = 0
    @Published var hasHeading = false

    // MARK: - Aktivität

    @Published var steps = 0
    @Published var distance = 0.0
    @Published var floorsUp = 0
    @Published var floorsDown = 0
    @Published var cadence = 0.0      // Schritte pro Minute
    @Published var pace = 0.0         // Sekunden pro Meter
    @Published var activityKind: ActivityKind = .unknown
    @Published var activityConfidence = ""
    @Published var activitySince: Date?

    // MARK: - Umgebung

    @Published var relativeAltitude = 0.0
    @Published var pressure = 0.0     // hPa
    @Published var barometerActive = false
    @Published var altitudeTrace = ValueTrace()
    @Published var soundLevel = 0.0   // 0…1
    @Published var soundDB = -80.0
    @Published var soundTrace = ValueTrace()

    // MARK: - Gerät

    @Published var batteryLevel = 0.0
    @Published var batteryState: UIDevice.BatteryState = .unknown
    @Published var thermalState: ProcessInfo.ThermalState = .nominal
    @Published var deviceOrientation: UIDeviceOrientation = .unknown
    @Published var screenBrightness = 0.0
    @Published var lowPowerMode = false
    @Published var proximityNear = false
    @Published var proximityEnabled = false

    // MARK: - Abgeleitete Werte

    var accelerationMagnitude: Double { acceleration.magnitude }
    var rotationRateDegrees: Vector3 { rotationRate.scaled(by: 180 / .pi) }
    var totalMagneticField: Double { magneticField.magnitude }
    var speedKmh: Double { location.speed * 3.6 }
    var batteryPercent: Int { batteryLevel < 0 ? -1 : Int((batteryLevel * 100).rounded()) }
    var stepsProgress: Double { min(Double(steps) / 10_000, 1) }

    let availability: Availability
    let deviceModel: String

    // MARK: - Dienste

    private let motion: MotionService
    private let locationService = LocationService()
    private let movement: MovementService
    private let audio = AudioLevelService()
    private let device: DeviceMonitor

    private var started = false
    private var demoTimer: Timer?
    private var demoClock: Double = 0
    private var demoSlowTick = 0
    private var demoSampleCounter = 0

    init() {
        let motionService = MotionService()
        let movementService = MovementService()
        let deviceMonitor = DeviceMonitor()

        var avail = Availability()
        avail.deviceMotion = motionService.isDeviceMotionAvailable
        avail.magnetometer = motionService.isMagnetometerAvailable
        avail.gyroscope = motionService.isGyroAvailable
        avail.accelerometer = motionService.isAccelerometerAvailable
        avail.stepCounting = movementService.isStepCountingAvailable
        avail.distance = movementService.isDistanceAvailable
        avail.floors = movementService.isFloorCountingAvailable
        avail.pace = movementService.isPaceAvailable
        avail.cadence = movementService.isCadenceAvailable
        avail.activity = movementService.isActivityAvailable
        avail.barometer = movementService.isAltimeterAvailable
        avail.heading = CLLocationManager.headingAvailable()

        motion = motionService
        movement = movementService
        device = deviceMonitor
        availability = avail
        deviceModel = deviceMonitor.modelIdentifier
    }

    // MARK: - Lebenszyklus

    func start(demo: Bool = false) {
        guard !started else { return }
        started = true
        demoMode = demo
        wire()
        device.start()
        refreshDevice()

        if demo {
            startDemo()
        } else {
            startHardware()
        }
    }

    func togglePause() {
        isPaused.toggle()
    }

    func setDemoMode(_ enabled: Bool) {
        guard demoMode != enabled else { return }
        demoMode = enabled
        guard started else { return }

        stopEverything()
        resetReadings()

        if enabled {
            startDemo()
        } else {
            startHardware()
        }
    }

    // MARK: - Verdrahtung

    private func wire() {
        motion.onSample = { [weak self] sample in
            self?.applyMotion(sample)
        }
        locationService.onLocation = { [weak self] newLocation in
            self?.applyLocation(newLocation)
        }
        locationService.onHeading = { [weak self] newHeading in
            self?.applyHeading(newHeading)
        }
        locationService.onAuthorization = { [weak self] status in
            self?.locationStatus = status
        }
        movement.onPedometer = { [weak self] data in
            self?.applyPedometer(data)
        }
        movement.onActivity = { [weak self] activity in
            self?.applyActivity(activity)
        }
        movement.onAltitude = { [weak self] data in
            self?.applyAltitude(data)
        }
        audio.onLevel = { [weak self] level, db in
            self?.applyAudio(level: level, db: db)
        }
        device.onChange = { [weak self] in
            self?.refreshDevice()
        }
    }

    private func startHardware() {
        motion.start()
        locationService.start()
        movement.startPedometer(from: Calendar.current.startOfDay(for: Date()))
        movement.startActivityUpdates()
        movement.startAltimeter()
        startAudio()
        locationStatus = locationService.authorizationStatus
    }

    private func stopEverything() {
        motion.stop()
        locationService.stop()
        movement.stop()
        audio.stop()
        demoTimer?.invalidate()
        demoTimer = nil
        microphoneActive = false
    }

    // MARK: - Audio

    func startAudio() {
        switch audio.permission {
        case .granted:
            microphoneActive = audio.start()
            micDenied = !microphoneActive
        case .undetermined:
            audio.requestPermission { [weak self] granted in
                guard let self else { return }
                if granted {
                    self.microphoneActive = self.audio.start()
                    self.micDenied = !self.microphoneActive
                } else {
                    self.microphoneActive = false
                    self.micDenied = true
                }
            }
        case .denied:
            microphoneActive = false
            micDenied = true
        @unknown default:
            microphoneActive = false
            micDenied = true
        }
    }

    // MARK: - Sensordaten übernehmen

    private func applyMotion(_ sample: MotionSample) {
        guard !isPaused else { return }
        acceleration = sample.userAcceleration
        gravity = sample.gravity
        rotationRate = sample.rotationRate
        magneticField = sample.magneticField
        attitude = sample.attitude
        accelTrace.append(sample.userAcceleration)
        rotationTrace.append(sample.rotationRate)
        magneticTrace.append(sample.magneticField)
    }

    private func applyLocation(_ newLocation: CLLocation) {
        guard !isPaused else { return }
        var reading = location
        reading.latitude = newLocation.coordinate.latitude
        reading.longitude = newLocation.coordinate.longitude
        reading.altitude = newLocation.altitude
        reading.horizontalAccuracy = newLocation.horizontalAccuracy
        reading.verticalAccuracy = newLocation.verticalAccuracy
        reading.speedAccuracy = newLocation.speedAccuracy
        reading.speed = max(newLocation.speed, 0)
        reading.course = max(newLocation.course, 0)
        reading.timestamp = newLocation.timestamp
        reading.hasFix = newLocation.horizontalAccuracy >= 0
        location = reading
    }

    private func applyHeading(_ newHeading: CLHeading) {
        guard !isPaused else { return }
        magneticHeading = newHeading.magneticHeading
        trueHeading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        heading = trueHeading
        headingAccuracy = newHeading.headingAccuracy
        hasHeading = true
    }

    private func applyPedometer(_ data: CMPedometerData) {
        guard !isPaused else { return }
        steps = data.numberOfSteps.intValue
        if let value = data.distance { distance = value.doubleValue }
        if let value = data.floorsAscended { floorsUp = value.intValue }
        if let value = data.floorsDescended { floorsDown = value.intValue }
        if let value = data.currentCadence { cadence = value.doubleValue * 60 }
        if let value = data.currentPace { pace = value.doubleValue }
    }

    private func applyActivity(_ activity: CMMotionActivity) {
        guard !isPaused else { return }
        if activity.running {
            activityKind = .running
        } else if activity.walking {
            activityKind = .walking
        } else if activity.cycling {
            activityKind = .cycling
        } else if activity.automotive {
            activityKind = .automotive
        } else if activity.stationary {
            activityKind = .stationary
        } else {
            activityKind = .unknown
        }

        switch activity.confidence {
        case .low: activityConfidence = "niedrig"
        case .medium: activityConfidence = "mittel"
        case .high: activityConfidence = "hoch"
        @unknown default: activityConfidence = "unbekannt"
        }
        activitySince = activity.startDate
    }

    private func applyAltitude(_ data: CMAltitudeData) {
        guard !isPaused else { return }
        relativeAltitude = data.relativeAltitude.doubleValue
        pressure = data.pressure.doubleValue * 10
        barometerActive = true
        altitudeTrace.append(relativeAltitude)
    }

    private func applyAudio(level: Double, db: Double) {
        guard !isPaused else { return }
        soundLevel = level
        soundDB = db
        soundTrace.append(level)
    }

    // MARK: - Gerätestatus

    func refreshDevice() {
        batteryLevel = UIDevice.current.batteryLevel
        batteryState = UIDevice.current.batteryState
        thermalState = ProcessInfo.processInfo.thermalState
        deviceOrientation = UIDevice.current.orientation
        screenBrightness = device.screenBrightness
        lowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        proximityNear = UIDevice.current.proximityState
    }

    func setProximityMonitoring(_ enabled: Bool) {
        proximityEnabled = enabled
        UIDevice.current.isProximityMonitoringEnabled = enabled
        proximityNear = UIDevice.current.proximityState
    }

    // MARK: - Demo-Modus

    private func startDemo() {
        demoClock = 0
        demoSlowTick = 0
        demoSampleCounter = 0
        let timer = Timer(timeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.tickDemo()
        }
        RunLoop.main.add(timer, forMode: .common)
        demoTimer = timer
        applyDemoSlowValues()
    }

    private func tickDemo() {
        guard !isPaused else { return }
        demoClock += 1.0 / 30.0
        let t = demoClock

        let accel = Vector3(
            x: 0.16 * sin(t * 3.1) + 0.05 * sin(t * 11.3),
            y: 0.11 * sin(t * 2.4 + 1.1),
            z: 0.07 * cos(t * 5.5)
        )
        let rotation = Vector3(
            x: 0.55 * sin(t * 1.4),
            y: 0.42 * cos(t * 1.1),
            z: 0.30 * sin(t * 0.8 + 0.6)
        )
        var gravity = Vector3(
            x: 0.32 * sin(t * 0.6),
            y: 0.90 * cos(t * 0.6),
            z: -0.12
        )
        let gravityMagnitude = max(gravity.magnitude, 0.0001)
        gravity = gravity.scaled(by: 1 / gravityMagnitude)
        let magnetic = Vector3(
            x: 19 + 5 * sin(t * 0.7),
            y: -6 + 3 * cos(t * 0.9),
            z: 43 + 4 * sin(t * 0.3)
        )
        let attitude = AttitudeReading(
            roll: 0.32 * sin(t * 0.6),
            pitch: 0.20 * cos(t * 0.45),
            yaw: (t * 0.22).truncatingRemainder(dividingBy: 2 * .pi)
        )

        applyMotion(
            MotionSample(
                userAcceleration: accel,
                gravity: gravity,
                rotationRate: rotation,
                magneticField: magnetic,
                attitude: attitude
            )
        )

        demoSampleCounter += 1
        if demoSampleCounter >= 30 {
            demoSampleCounter = 0
            demoSlowTick += 1
            applyDemoSlowValues()
        }
    }

    private func applyDemoSlowValues() {
        guard !isPaused else { return }
        let t = Double(demoSlowTick)

        steps = 4820 + Int(t) * 2
        distance = Double(steps) * 0.74
        floorsUp = 7 + Int(t) / 20
        floorsDown = 6 + Int(t) / 30
        cadence = 108 + 6 * sin(t * 0.4)
        pace = 0.68 + 0.03 * sin(t * 0.3)
        activityKind = .walking
        activityConfidence = "hoch"
        if activitySince == nil { activitySince = Date() }

        relativeAltitude = 1.8 * sin(t * 0.12) + 0.35
        pressure = 1013.2 + 1.4 * sin(t * 0.12)
        altitudeTrace.append(relativeAltitude)
        barometerActive = true

        heading = (t * 6).truncatingRemainder(dividingBy: 360)
        magneticHeading = heading
        trueHeading = (heading + 2).truncatingRemainder(dividingBy: 360)
        headingAccuracy = 6
        hasHeading = true

        location = LocationReading(
            latitude: 52.520008 + 0.00012 * sin(t * 0.1),
            longitude: 13.404954 + 0.00015 * cos(t * 0.1),
            altitude: 42 + relativeAltitude,
            speed: 1.35 + 0.15 * sin(t * 0.3),
            course: heading,
            horizontalAccuracy: 4.5,
            verticalAccuracy: 6,
            speedAccuracy: 0.4,
            timestamp: Date(),
            hasFix: true
        )

        soundLevel = 0.28 + 0.18 * abs(sin(t * 0.5))
        soundDB = -46 + 8 * sin(t * 0.5)
        soundTrace.append(soundLevel)
        microphoneActive = true
        micDenied = false

        batteryLevel = max(0.15, 0.82 - t * 0.0006)
        batteryState = .unplugged
        lowPowerMode = false
        thermalState = .nominal
        screenBrightness = 0.62
        deviceOrientation = .portrait
    }

    private func resetReadings() {
        accelTrace.clear()
        rotationTrace.clear()
        magneticTrace.clear()
        altitudeTrace.clear()
        soundTrace.clear()

        acceleration = .zero
        gravity = Vector3(x: 0, y: 0, z: -1)
        rotationRate = .zero
        magneticField = .zero
        attitude = AttitudeReading()

        relativeAltitude = 0
        pressure = 0
        barometerActive = false
        soundLevel = 0
        soundDB = -80

        steps = 0
        distance = 0
        floorsUp = 0
        floorsDown = 0
        cadence = 0
        pace = 0
        activityKind = .unknown
        activityConfidence = ""
        activitySince = nil

        location = LocationReading()
        heading = 0
        magneticHeading = 0
        trueHeading = 0
        headingAccuracy = 0
        hasHeading = false
    }
}
