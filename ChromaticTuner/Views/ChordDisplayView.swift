import SwiftUI

struct ChordDisplayView: View {
    let chord: DetectedChord?
    let dominantPitch: DetectedPitch?

    var body: some View {
        VStack(spacing: 8) {
            if let chord = chord {
                HStack(spacing: 16) {
                    AdjacentChordLabel(chord: chord.previousChord, position: .previous)
                        .frame(minWidth: 60)

                    Text(chord.root.rawValue)
                        .font(.system(size: 80, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    AdjacentChordLabel(chord: chord.nextChord, position: .next)
                        .frame(minWidth: 60)
                }

                Text(chord.quality.displayName)
                    .font(.system(size: 32, weight: .medium, design: .rounded))
                    .foregroundColor(.gray)

                Text(String(format: "%.0f%%", chord.confidence * 100))
                    .font(.system(size: 16, weight: .regular, design: .monospaced))
                    .foregroundColor(.gray.opacity(0.6))

                HzDeviationView(pitch: dominantPitch)
                    .padding(.top, 4)

            } else {
                Text("—")
                    .font(.system(size: 80, weight: .bold, design: .rounded))
                    .foregroundColor(.gray.opacity(0.3))

                Text("No chord detected")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.gray.opacity(0.5))

                HzDeviationView(pitch: nil)
                    .padding(.top, 4)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: chord?.displayName)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        ChordDisplayView(
            chord: DetectedChord(
                root: .C,
                quality: .major,
                confidence: 0.85,
                notes: [.C, .E, .G]
            ),
            dominantPitch: DetectedPitch(
                frequency: 262.5,
                magnitude: 0.8,
                note: .C
            )
        )
    }
}
