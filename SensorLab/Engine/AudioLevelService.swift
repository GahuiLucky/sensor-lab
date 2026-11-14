import Foundation
import AVFoundation

final class AudioLevelService {
    private let audioEngine = AVAudioEngine()
    private(set) var isRunning = false

    /// (normierter Pegel 0…1, dBFS)
    var onLevel: ((Double, Double) -> Void)?

    var permission: AVAudioApplication.recordPermission {
        AVAudioApplication.shared.recordPermission
    }

    func requestPermission(completion: @escaping (Bool) -> Void) {
        AVAudioApplication.requestRecordPermission { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    @discardableResult
    func start() -> Bool {
        guard !isRunning else { return true }
        guard permission == .granted else { return false }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: [])
            try session.setActive(true)

            let input = audioEngine.inputNode
            let format = input.inputFormat(forBus: 0)
            guard format.sampleRate > 0, format.channelCount > 0 else { return false }

            input.installTap(onBus: 0, bufferSize: 2048, format: format) { [weak self] buffer, _ in
                self?.process(buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()
            isRunning = true
            return true
        } catch {
            isRunning = false
            return false
        }
    }

    func stop() {
        guard isRunning else { return }
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        isRunning = false
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }

    private func process(_ buffer: AVAudioPCMBuffer) {
        guard let channels = buffer.floatChannelData, buffer.frameLength > 0 else { return }
        let channel = channels[0]
        let frameCount = Int(buffer.frameLength)
        guard frameCount > 0 else { return }

        var sum: Double = 0
        for index in 0..<frameCount {
            let sample = Double(channel[index])
            sum += sample * sample
        }
        let rms = (sum / Double(frameCount)).squareRoot()
        let dbfs = 20 * log10(max(rms, 0.0000001))
        let normalized = min(max((dbfs + 60) / 60, 0), 1)

        DispatchQueue.main.async { [weak self] in
            self?.onLevel?(normalized, dbfs)
        }
    }
}
