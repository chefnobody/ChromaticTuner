import Foundation

struct DetectedPitch: Identifiable {
    let id = UUID()
    let frequency: Float
    let magnitude: Float
    let note: Note

    var magnitudeDB: Float {
        20 * log10(max(magnitude, 1e-10))
    }
}

extension DetectedPitch: Comparable {
    static func < (lhs: DetectedPitch, rhs: DetectedPitch) -> Bool {
        lhs.frequency < rhs.frequency
    }
}
