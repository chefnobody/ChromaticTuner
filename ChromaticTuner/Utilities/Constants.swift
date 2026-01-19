import Foundation
import AVFoundation

enum AudioConstants {
    static let sampleRate: Double = 44100
    static let bufferSize: AVAudioFrameCount = 4096
    static let fftSize: Int = 4096
    static let hopSize: Int = 1024

    static let minDetectionFrequency: Float = 60.0
    static let maxDetectionFrequency: Float = 2000.0

    static let peakThresholdDB: Float = -25.0

    static let maxPitchesCount: Int = 6

    static let minimumMagnitudeThreshold: Float = 0.01

    static let chordStabilityDuration: TimeInterval = 2.0
    static let chordClearDelay: TimeInterval = 2.5
    static let chordConfirmationCount: Int = 5
}
