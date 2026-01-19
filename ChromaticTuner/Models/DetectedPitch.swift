import Foundation

struct DetectedPitch: Identifiable {
    let id = UUID()
    let frequency: Float
    let magnitude: Float
    let note: Note

    var magnitudeDB: Float {
        20 * log10(max(magnitude, 1e-10))
    }

    /// The ideal frequency for the locked note in the octave closest to the detected frequency
    var idealFrequency: Float {
        // Use the assigned note (which may be locked via hysteresis), not a recalculated one
        let semitoneOffset = Float(note.semitoneOffset - 9)  // A = semitone 9, offset from A
        let a4Freq: Float = 440.0

        // Find the octave that puts this note closest to the detected frequency
        var bestFreq: Float = a4Freq
        var bestDistance: Float = .infinity

        for octaveOffset in -4...4 {
            let candidateFreq = a4Freq * pow(2.0, Float(octaveOffset) + semitoneOffset / 12.0)
            let distance = abs(candidateFreq - frequency)
            if distance < bestDistance {
                bestDistance = distance
                bestFreq = candidateFreq
            }
        }

        return bestFreq
    }

    /// Deviation in cents from the ideal frequency (-50 to +50 cents = within the same note)
    var centsDeviation: Float {
        1200 * log2(frequency / idealFrequency)
    }

    /// True if the pitch is flat (below ideal frequency)
    var isFlat: Bool {
        centsDeviation < -5  // More than 5 cents flat
    }

    /// True if the pitch is sharp (above ideal frequency)
    var isSharp: Bool {
        centsDeviation > 5  // More than 5 cents sharp
    }

    /// True if the pitch is in tune (within 5 cents)
    var isInTune: Bool {
        abs(centsDeviation) <= 5
    }
}

extension DetectedPitch: Comparable {
    static func < (lhs: DetectedPitch, rhs: DetectedPitch) -> Bool {
        lhs.frequency < rhs.frequency
    }
}
