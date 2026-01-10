import Foundation

struct ChordTemplate {
    let name: String
    let root: String
    let mask: [Float] // 12-element vector (1.0 if note is in chord, 0.0 if not)
}

class ChordLibrary {
    static let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    private(set) var templates: [ChordTemplate] = []

    init() {
        generateTemplates()
    }

    private func generateTemplates() {
        let majorIntervals = [0, 4, 7]      // Root, Major 3rd, Perfect 5th
        let minorIntervals = [0, 3, 7]      // Root, Minor 3rd, Perfect 5th
        let dominant7Intervals = [0, 4, 7, 10] // Root, Major 3rd, Perfect 5th, Minor 7th

        for i in 0..<12 {
            let rootName = ChordLibrary.noteNames[i]
            
            templates.append(createTemplate(name: "\(rootName) Maj", rootIdx: i, intervals: majorIntervals))
            templates.append(createTemplate(name: "\(rootName) min", rootIdx: i, intervals: minorIntervals))
            templates.append(createTemplate(name: "\(rootName) 7", rootIdx: i, intervals: dominant7Intervals))
        }
    }

    private func createTemplate(name: String, rootIdx: Int, intervals: [Int]) -> ChordTemplate {
        var mask = [Float](repeating: 0.0, count: 12)
        for interval in intervals {
            let noteIdx = (rootIdx + interval) % 12
            mask[noteIdx] = 1.0
        }
        return ChordTemplate(name: name, root: ChordLibrary.noteNames[rootIdx], mask: mask)
    }
}
