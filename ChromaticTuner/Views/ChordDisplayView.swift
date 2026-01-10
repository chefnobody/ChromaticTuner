import SwiftUI

struct ChordDisplayView: View {
    let chord: DetectedChord?

    var body: some View {
        VStack(spacing: 8) {
            if let chord = chord {
                Text(chord.root.rawValue)
                    .font(.system(size: 80, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text(chord.quality.displayName)
                    .font(.system(size: 32, weight: .medium, design: .rounded))
                    .foregroundColor(.gray)

                Text(String(format: "%.0f%%", chord.confidence * 100))
                    .font(.system(size: 16, weight: .regular, design: .monospaced))
                    .foregroundColor(.gray.opacity(0.6))
            } else {
                Text("—")
                    .font(.system(size: 80, weight: .bold, design: .rounded))
                    .foregroundColor(.gray.opacity(0.3))

                Text("No chord detected")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.gray.opacity(0.5))
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
            )
        )
    }
}
