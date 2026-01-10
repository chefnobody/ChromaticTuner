import Foundation
import AVFoundation

protocol AudioCaptureDelegate: AnyObject {
    func didCaptureAudioBuffer(_ buffer: AVAudioPCMBuffer, time: AVAudioTime)
    func didEncounterError(_ error: Error)
}

protocol AudioCaptureServiceProtocol {
    var delegate: AudioCaptureDelegate? { get set }
    var isRunning: Bool { get }

    func startCapture() throws
    func stopCapture()
}

enum AudioCaptureError: Error {
    case microphonePermissionDenied
    case audioSessionConfigurationFailed
    case audioEngineStartFailed
    case bufferAllocationFailed
    case invalidFormat
}
