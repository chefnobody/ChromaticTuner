import Foundation

struct DetectedPitch: Identifiable {
    let id = UUID()
    let frequency: Float
    let magnitude: Float
    let note: Note

    var magnitudeDB: Float {
        20 * log10(max(magnitude, 1e-10))
    }

    var idealFrequency: Float {
        let midiNote = 69.0 + 12.0 * log2(Double(frequency) / 440.0)
        let roundedMidi = round(midiNote)
        return Float(440.0 * pow(2.0, (roundedMidi - 69.0) / 12.0))
    }

    var hzDeviation: Float {
        frequency - idealFrequency
    }

    var clampedHzDeviation: Float {
        min(max(hzDeviation, -20), 20)
    }
}

extension DetectedPitch: Comparable {
    static func < (lhs: DetectedPitch, rhs: DetectedPitch) -> Bool {
        lhs.frequency < rhs.frequency
    }
}
