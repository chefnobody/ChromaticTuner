import Foundation

class ChordRecognizer: ChordRecognizerProtocol {
    private let chordIdentifier: ChordIdentifier
    private var lastChord: DetectedChord?
    private var lastChordTime: Date?

    private var candidateChord: DetectedChord?
    private var candidateCount: Int = 0

    init(chordIdentifier: ChordIdentifier = ChordIdentifier()) {
        self.chordIdentifier = chordIdentifier
    }

    // Protocol requirement updated here:
    func recognizeChord(from pitches: [DetectedPitch], chroma: [Float]) -> DetectedChord? {
        
        // 1. Identification via Chroma Template Matching
        guard let identification = chordIdentifier.identifyChord(from: chroma) else {
            return applyTemporalSmoothing(nil)
        }

        // 2. Parse identification (e.g., "C Maj") into Root and Quality
        let parts = identification.name.split(separator: " ")
        guard let rootName = parts.first.map({ String($0) }),
              let rootNote = Note(rawValue: rootName) else {
            return applyTemporalSmoothing(nil)
        }
        
        // 3. Map string names to your existing ChordQuality enum
        // If your enum doesn't support .dominant7, we map it to .major
        let quality: ChordQuality
        if identification.name.contains("min") {
            quality = .minor
        } else {
            // This covers both "Maj" and "7" cases
            quality = .major
        }

        // 3. Assemble the Chord
        let currentMatch = DetectedChord(
            root: rootNote,
            quality: quality,
            confidence: identification.confidence,
            notes: pitches.map { $0.note } // Metadata for display
        )

        return applyTemporalSmoothing(currentMatch)
    }

    // ... applyTemporalSmoothing logic remains the same ...
    private func applyTemporalSmoothing(_ newChord: DetectedChord?) -> DetectedChord? {
        let now = Date()
        if let newChord = newChord {
            if let last = lastChord, newChord.root == last.root && newChord.quality == last.quality,
               let lastTime = lastChordTime, now.timeIntervalSince(lastTime) < AudioConstants.chordStabilityDuration {
                candidateChord = nil
                candidateCount = 0
                return last
            }
            if let candidate = candidateChord, newChord.root == candidate.root && newChord.quality == candidate.quality {
                candidateCount += 1
                if candidateCount >= AudioConstants.chordConfirmationCount {
                    lastChord = newChord
                    lastChordTime = now
                    candidateChord = nil
                    candidateCount = 0
                    return newChord
                }
                return lastChord
            } else {
                candidateChord = newChord
                candidateCount = 1
                return lastChord
            }
        } else {
            candidateChord = nil
            candidateCount = 0
            if let last = lastChord, let lastTime = lastChordTime, now.timeIntervalSince(lastTime) < AudioConstants.chordClearDelay {
                return last
            }
            lastChord = nil
            lastChordTime = nil
            return nil
        }
    }
}
