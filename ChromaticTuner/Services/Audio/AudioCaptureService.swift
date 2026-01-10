import Foundation
import AVFoundation

class AudioCaptureService: AudioCaptureServiceProtocol {
    weak var delegate: AudioCaptureDelegate?
    private(set) var isRunning: Bool = false

    private let audioEngine = AVAudioEngine()
    private let audioSession = AVAudioSession.sharedInstance()

    func startCapture() throws {
        print("🔧 AudioCaptureService: Requesting microphone permission...")
        try requestMicrophonePermission()
        print("✅ Microphone permission granted")

        print("🔧 AudioCaptureService: Configuring audio session...")
        try configureAudioSession()
        print("✅ Audio session configured")

        print("🔧 AudioCaptureService: Setting up audio engine...")
        try setupAudioEngine()
        print("✅ Audio engine setup complete")

        print("🔧 AudioCaptureService: Starting audio engine...")
        try startAudioEngine()
        print("✅ Audio engine started")

        isRunning = true
    }

    func stopCapture() {
        print("🛑 AudioCaptureService: Stopping audio engine...")
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        isRunning = false
        print("✅ Audio engine stopped")
    }

    private func requestMicrophonePermission() throws {
        let status = audioSession.recordPermission

        switch status {
        case .granted:
            return
        case .denied:
            throw AudioCaptureError.microphonePermissionDenied
        case .undetermined:
            let semaphore = DispatchSemaphore(value: 0)
            var permissionGranted = false

            audioSession.requestRecordPermission { granted in
                permissionGranted = granted
                semaphore.signal()
            }

            semaphore.wait()

            if !permissionGranted {
                throw AudioCaptureError.microphonePermissionDenied
            }
        @unknown default:
            throw AudioCaptureError.microphonePermissionDenied
        }
    }

    private func configureAudioSession() throws {
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: [])
            try audioSession.setPreferredSampleRate(AudioConstants.sampleRate)
            try audioSession.setActive(true)
        } catch {
            throw AudioCaptureError.audioSessionConfigurationFailed
        }
    }

    private func setupAudioEngine() throws {
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        print("📊 Input format: \(inputFormat.sampleRate) Hz, \(inputFormat.channelCount) channel(s)")

        guard inputFormat.sampleRate > 0, inputFormat.channelCount > 0 else {
            print("❌ Invalid format!")
            throw AudioCaptureError.invalidFormat
        }

        inputNode.installTap(
            onBus: 0,
            bufferSize: AudioConstants.bufferSize,
            format: inputFormat
        ) { [weak self] buffer, time in
            self?.delegate?.didCaptureAudioBuffer(buffer, time: time)
        }
        print("🎙️ Audio tap installed with buffer size: \(AudioConstants.bufferSize)")
    }

    private func startAudioEngine() throws {
        do {
            try audioEngine.start()
        } catch {
            throw AudioCaptureError.audioEngineStartFailed
        }
    }
}
