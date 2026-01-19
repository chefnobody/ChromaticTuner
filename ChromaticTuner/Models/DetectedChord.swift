import Foundation

struct DetectedChord {
    let root: Note
    let quality: ChordQuality
    let confidence: Float
    let notes: [Note]

    var displayName: String {
        "\(root.rawValue) \(quality.displayName)"
    }

    var shortName: String {
        root.rawValue + (quality == .minor ? "m" : "")
    }
}
