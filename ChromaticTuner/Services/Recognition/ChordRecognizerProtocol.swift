import Foundation

protocol ChordRecognizerProtocol {
    func recognizeChord(from pitches: [DetectedPitch]) -> DetectedChord?
}
