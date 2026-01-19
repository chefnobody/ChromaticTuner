import Foundation
import AVFoundation
import os

class AudioCaptureService: AudioCaptureServiceProtocol {
    private let logger = Logger(subsystem: "com.chromatictuner", category: "AudioCapture")
    weak var delegate: AudioCaptureDelegate?
    private(set) var isRunning: Bool = false

    private let audioEngine = AVAudioEngine()
    private let audioSession = AVAudioSession.sharedInstance()

    func startCapture() throws {
        logger.debug("Requesting microphone permission...")
        try requestMicrophonePermission()
        logger.info("Microphone permission granted")

        logger.debug("Configuring audio session...")
        try configureAudioSession()
        logger.info("Audio session configured")

        logger.debug("Setting up audio engine...")
        try setupAudioEngine()
        logger.info("Audio engine setup complete")

        logger.debug("Starting audio engine...")
        try startAudioEngine()
        logger.info("Audio engine started")

        isRunning = true
    }

    func stopCapture() {
        logger.info("Stopping audio engine...")
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        isRunning = false
        logger.info("Audio engine stopped")
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

        logger.debug("Input format: \(inputFormat.sampleRate) Hz, \(inputFormat.channelCount) channel(s)")

        guard inputFormat.sampleRate > 0, inputFormat.channelCount > 0 else {
            logger.error("Invalid audio format")
            throw AudioCaptureError.invalidFormat
        }

        inputNode.installTap(
            onBus: 0,
            bufferSize: AudioConstants.bufferSize,
            format: inputFormat
        ) { [weak self] buffer, time in
            self?.delegate?.didCaptureAudioBuffer(buffer, time: time)
        }
        logger.info("Audio tap installed with buffer size: \(AudioConstants.bufferSize)")
    }

    private func startAudioEngine() throws {
        do {
            try audioEngine.start()
        } catch {
            throw AudioCaptureError.audioEngineStartFailed
        }
    }
}
