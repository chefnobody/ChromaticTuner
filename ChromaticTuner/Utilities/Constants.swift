import Foundation
import AVFoundation

enum AudioConstants {
    static let sampleRate: Double = 44100
    static let bufferSize: AVAudioFrameCount = 8192
    static let fftSize: Int = 8192
    static let hopSize: Int = 1024

    static let minDetectionFrequency: Float = 75.0
    static let maxDetectionFrequency: Float = 2000.0

    static let peakThresholdDB: Float = -25.0

    static let maxPitchesCount: Int = 6

    static let minimumMagnitudeThreshold: Float = 0.01

    static let chordStabilityDuration: TimeInterval = 2.0
    static let chordClearDelay: TimeInterval = 2.5
    static let chordConfirmationCount: Int = 5
}
