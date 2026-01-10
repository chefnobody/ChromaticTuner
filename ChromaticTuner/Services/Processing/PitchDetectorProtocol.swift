import Foundation
import AVFoundation

protocol PitchDetectorProtocol {
    func detectPitches(from buffer: AVAudioPCMBuffer) -> ([DetectedPitch], [Float])
}
