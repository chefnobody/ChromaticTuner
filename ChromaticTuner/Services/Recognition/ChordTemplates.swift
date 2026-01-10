import Foundation

struct ChordTemplate {
    let quality: ChordQuality
    let intervals: [Int]
    let requiredIntervals: Set<Int>
    let optionalIntervals: Set<Int>

    init(quality: ChordQuality, intervals: [Int], requiredIntervals: [Int]? = nil) {
        self.quality = quality
        self.intervals = intervals
        self.requiredIntervals = Set(requiredIntervals ?? intervals)
        self.optionalIntervals = Set(intervals).subtracting(self.requiredIntervals)
    }
}

enum ChordTemplates {
    static let all: [ChordTemplate] = [
        ChordTemplate(
            quality: .major,
            intervals: [0, 4, 7],
            requiredIntervals: [4]
        ),
        ChordTemplate(
            quality: .minor,
            intervals: [0, 3, 7],
            requiredIntervals: [3]
        )
    ]

    static func template(for quality: ChordQuality) -> ChordTemplate? {
        all.first { $0.quality == quality }
    }
}
