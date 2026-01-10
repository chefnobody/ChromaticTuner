import Foundation

class ChordRecognizer: ChordRecognizerProtocol {
    private let templates: [ChordTemplate]
    private var lastChord: DetectedChord?
    private var lastChordTime: Date?

    private var candidateChord: DetectedChord?
    private var candidateCount: Int = 0

    init(templates: [ChordTemplate] = ChordTemplates.all) {
        self.templates = templates
    }

    func recognizeChord(from pitches: [DetectedPitch]) -> DetectedChord? {
        print("🎹 ChordRecognizer: Analyzing \(pitches.count) pitches...")

        guard pitches.count >= 2 else {
            print("⚠️ ChordRecognizer: Not enough pitches (need at least 2)")
            return applyTemporalSmoothing(nil)
        }

        let notes = pitches.map { $0.note }.sorted()
        let uniqueNotes = Array(Set(notes))

        print("🎵 Unique notes: \(uniqueNotes.map { $0.rawValue }.joined(separator: ", "))")

        guard uniqueNotes.count >= 2 else {
            print("⚠️ ChordRecognizer: Not enough unique notes (need at least 2)")
            return applyTemporalSmoothing(nil)
        }

        var bestMatch: (chord: DetectedChord, score: Float)?

        for rootNote in uniqueNotes {
            for template in templates {
                if let match = tryMatch(notes: uniqueNotes, root: rootNote, template: template, pitches: pitches) {
                    print("   ✓ Match: \(rootNote.rawValue) \(template.quality.rawValue) (score: \(String(format: "%.3f", match.score)))")
                    if bestMatch == nil || match.score > bestMatch!.score {
                        bestMatch = match
                    }
                }
            }
        }

        if let best = bestMatch {
            print("🏆 Best match: \(best.chord.displayName) (score: \(String(format: "%.3f", best.score)))")
        } else {
            print("❌ No chord pattern matched")
        }

        return applyTemporalSmoothing(bestMatch?.chord)
    }

    private func tryMatch(
        notes: [Note],
        root: Note,
        template: ChordTemplate,
        pitches: [DetectedPitch]
    ) -> (chord: DetectedChord, score: Float)? {
        let intervals = notes.map { root.interval(to: $0) }
        let intervalSet = Set(intervals)

        let matchedRequired = template.requiredIntervals.intersection(intervalSet)
        guard matchedRequired.count >= template.requiredIntervals.count else {
            return nil
        }

        let matchedAll = intervalSet.intersection(Set(template.intervals))
        let matchRatio = Float(matchedAll.count) / Float(template.intervals.count)

        guard matchRatio >= 0.5 else {
            return nil
        }

        let avgMagnitude = pitches.map { $0.magnitude }.reduce(0, +) / Float(pitches.count)
        let confidence = matchRatio * min(avgMagnitude * 10, 1.0)

        let matchedNotes = notes.filter { note in
            let interval = root.interval(to: note)
            return template.intervals.contains(interval)
        }

        let chord = DetectedChord(
            root: root,
            quality: template.quality,
            confidence: confidence,
            notes: matchedNotes
        )

        return (chord: chord, score: confidence)
    }

    private func applyTemporalSmoothing(_ newChord: DetectedChord?) -> DetectedChord? {
        let now = Date()

        if let newChord = newChord {
            // If this is the same as the currently displayed chord, keep it and reset candidate
            if let lastChord = lastChord,
               newChord.root == lastChord.root && newChord.quality == lastChord.quality,
               let lastTime = lastChordTime,
               now.timeIntervalSince(lastTime) < AudioConstants.chordStabilityDuration {
                print("🔒 Temporal smoothing: Keeping displayed \(lastChord.displayName) (same chord within stability window)")
                candidateChord = nil
                candidateCount = 0
                return lastChord
            }

            // If this is a new chord, use confirmation buffer
            if let candidate = candidateChord,
               newChord.root == candidate.root && newChord.quality == candidate.quality {
                // Same candidate as before, increment count
                candidateCount += 1
                print("📊 Temporal smoothing: Candidate \(newChord.displayName) confirmation \(candidateCount)/\(AudioConstants.chordConfirmationCount)")

                if candidateCount >= AudioConstants.chordConfirmationCount {
                    // Confirmed! Switch to new chord
                    print("✨ Temporal smoothing: Confirmed new chord \(newChord.displayName)")
                    self.lastChord = newChord
                    self.lastChordTime = now
                    self.candidateChord = nil
                    self.candidateCount = 0
                    return newChord
                } else {
                    // Not confirmed yet, keep showing the old chord
                    if let lastChord = lastChord {
                        print("⏸️  Temporal smoothing: Holding \(lastChord.displayName) while confirming candidate")
                        return lastChord
                    } else {
                        return nil
                    }
                }
            } else {
                // Different chord than candidate, start new candidate
                print("🔄 Temporal smoothing: New candidate \(newChord.displayName) (1/\(AudioConstants.chordConfirmationCount))")
                candidateChord = newChord
                candidateCount = 1

                // Keep showing the old chord while we confirm the new one
                if let lastChord = lastChord {
                    return lastChord
                } else {
                    return nil
                }
            }
        } else {
            // No chord detected
            candidateChord = nil
            candidateCount = 0

            // Hold the last chord for the clear delay period
            if let lastChord = lastChord,
               let lastTime = lastChordTime,
               now.timeIntervalSince(lastTime) < AudioConstants.chordClearDelay {
                let elapsed = now.timeIntervalSince(lastTime)
                print("⏳ Temporal smoothing: Holding \(lastChord.displayName) (\(String(format: "%.1f", elapsed))s / \(AudioConstants.chordClearDelay)s)")
                return lastChord
            }

            if lastChord != nil {
                print("🧹 Temporal smoothing: Clearing chord display")
            }
            self.lastChord = nil
            self.lastChordTime = nil
            return nil
        }
    }
}
