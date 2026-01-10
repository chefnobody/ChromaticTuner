import Foundation

enum Note: String, CaseIterable {
    case C = "C"
    case CSharp = "C#"
    case D = "D"
    case DSharp = "D#"
    case E = "E"
    case F = "F"
    case FSharp = "F#"
    case G = "G"
    case GSharp = "G#"
    case A = "A"
    case ASharp = "A#"
    case B = "B"

    var semitoneOffset: Int {
        switch self {
        case .C: return 0
        case .CSharp: return 1
        case .D: return 2
        case .DSharp: return 3
        case .E: return 4
        case .F: return 5
        case .FSharp: return 6
        case .G: return 7
        case .GSharp: return 8
        case .A: return 9
        case .ASharp: return 10
        case .B: return 11
        }
    }

    static func from(midiNote: Int) -> Note {
        let index = midiNote % 12
        return Note.allCases[index]
    }

    static func from(frequency: Float) -> Note? {
        guard frequency > 0 else { return nil }
        let midiNote = 69 + 12 * log2(frequency / 440.0)
        let roundedMidi = Int(round(midiNote))
        return from(midiNote: roundedMidi)
    }

    func interval(to other: Note) -> Int {
        let diff = other.semitoneOffset - self.semitoneOffset
        return diff >= 0 ? diff : diff + 12
    }
}

extension Note: Comparable {
    static func < (lhs: Note, rhs: Note) -> Bool {
        lhs.semitoneOffset < rhs.semitoneOffset
    }
}
