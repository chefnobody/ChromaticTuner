import SwiftUI

struct ChordDisplayView: View {
    let chord: DetectedChord?
    let dominantPitch: DetectedPitch?

    // Tuning state persistence - holds states to reduce flicker
    @State private var displayedTuningState: TuningState = .neutral
    @State private var lastInTuneTime: Date?

    private enum TuningState: Equatable {
        case flat, inTune, sharp, neutral
    }

    // How long to hold the "in tune" green state after detected
    private let inTuneHoldDuration: TimeInterval = 1.0

    private var currentTuningState: TuningState {
        guard dominantPitch != nil else { return .neutral }
        if dominantPitch?.isInTune == true { return .inTune }
        if dominantPitch?.isFlat == true { return .flat }
        if dominantPitch?.isSharp == true { return .sharp }
        return .neutral
    }

    private var effectiveTuningState: TuningState {
        let current = currentTuningState

        // If currently in tune, always show in tune
        if current == .inTune {
            return .inTune
        }

        // If we were recently in tune, hold the green state
        if let lastInTune = lastInTuneTime,
           Date().timeIntervalSince(lastInTune) < inTuneHoldDuration {
            return .inTune
        }

        return current
    }

    var body: some View {
        VStack(spacing: 8) {
            if let chord = chord {
                // Chord root with flat/sharp indicators
                HStack(spacing: 20) {
                    // Flat indicator (left) - only show when not in tune
                    Text("♭")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(effectiveTuningState == .flat ? .red : .gray.opacity(0.2))
                        .frame(width: 50)

                    // Chord root
                    Text(chord.root.rawValue)
                        .font(.system(size: 80, weight: .bold, design: .rounded))
                        .foregroundColor(effectiveTuningState == .inTune ? .green : .white)
                        .animation(.interactiveSpring, value: effectiveTuningState)

                    // Sharp indicator (right) - only show when not in tune
                    Text("♯")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(effectiveTuningState == .sharp ? .orange : .gray.opacity(0.2))
                        .frame(width: 50)
                }
            } else {
                HStack(spacing: 20) {
                    Text("♭")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.gray.opacity(0.2))
                        .frame(width: 50)

                    Text("—")
                        .font(.system(size: 80, weight: .bold, design: .rounded))
                        .foregroundColor(.gray.opacity(0.3))

                    Text("♯")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.gray.opacity(0.2))
                        .frame(width: 50)
                }
            }
        }
        .frame(height: 180)
        .animation(.easeInOut(duration: 0.2), value: chord?.displayName)
        .animation(.easeInOut(duration: 0.2), value: effectiveTuningState)
        .onChange(of: currentTuningState) { _, newState in
            if newState == .inTune {
                lastInTuneTime = Date()
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 40) {
            // Flat example
            ChordDisplayView(
                chord: DetectedChord(root: .C, quality: .major, confidence: 0.85, notes: [.C, .E, .G]),
                dominantPitch: DetectedPitch(frequency: 250, magnitude: 0.8, note: .C)  // Flat
            )
            // In tune example
            ChordDisplayView(
                chord: DetectedChord(root: .A, quality: .minor, confidence: 0.90, notes: [.A, .C, .E]),
                dominantPitch: DetectedPitch(frequency: 440, magnitude: 0.8, note: .A)  // In tune
            )
            // Sharp example
            ChordDisplayView(
                chord: DetectedChord(root: .G, quality: .major, confidence: 0.75, notes: [.G, .B, .D]),
                dominantPitch: DetectedPitch(frequency: 400, magnitude: 0.8, note: .G)  // Sharp
            )
        }
    }
}
