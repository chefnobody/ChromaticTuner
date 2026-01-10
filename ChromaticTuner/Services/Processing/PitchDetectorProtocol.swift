import Foundation
import AVFoundation

protocol PitchDetectorProtocol {
    func detectPitches(from buffer: AVAudioPCMBuffer) -> (pitches: [DetectedPitch], spectrum: [Float], chroma: [Float])
}
