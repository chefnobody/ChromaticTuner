import SwiftUI

struct ChordDisplayView: View {
    let chord: DetectedChord?
    let dominantPitch: DetectedPitch?

    private var isFlat: Bool {
        dominantPitch?.isFlat ?? false
    }

    private var isSharp: Bool {
        dominantPitch?.isSharp ?? false
    }

    private var isInTune: Bool {
        dominantPitch?.isInTune ?? false
    }

    var body: some View {
        VStack(spacing: 8) {
            if let chord = chord {
                // Chord root with flat/sharp indicators
                HStack(spacing: 20) {
                    // Flat indicator (left)
                    Text("♭")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(isFlat ? .red : .gray.opacity(0.2))
                        .frame(width: 50)

                    // Chord root
                    Text(chord.root.rawValue)
                        .font(.system(size: 80, weight: .bold, design: .rounded))
                        .foregroundColor(isInTune ? .green : .white)

                    // Sharp indicator (right)
                    Text("♯")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(isSharp ? .orange : .gray.opacity(0.2))
                        .frame(width: 50)
                }

                Text(chord.quality.displayName)
                    .font(.system(size: 32, weight: .medium, design: .rounded))
                    .foregroundColor(.gray)

                Text(String(format: "%.0f%%", chord.confidence * 100))
                    .font(.system(size: 16, weight: .regular, design: .monospaced))
                    .foregroundColor(.gray.opacity(0.6))
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

                Text("No chord detected")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.gray.opacity(0.5))
            }
        }
        .frame(height: 180)
        .animation(.easeInOut(duration: 0.2), value: chord?.displayName)
        .animation(.easeInOut(duration: 0.15), value: isFlat)
        .animation(.easeInOut(duration: 0.15), value: isSharp)
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
