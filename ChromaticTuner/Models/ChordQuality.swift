import Foundation

enum ChordQuality: String {
    case major = "Major"
    case minor = "Minor"

    var displayName: String {
        rawValue
    }

    var intervals: [Int] {
        switch self {
        case .major:
            return [0, 4, 7]
        case .minor:
            return [0, 3, 7]
        }
    }
}
