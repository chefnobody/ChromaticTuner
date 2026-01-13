import SwiftUI

struct AdjacentChordsView: View {
    let chord: DetectedChord

    var body: some View {
        HStack(spacing: 24) {
            AdjacentChordLabel(chord: chord.previousChord, position: .previous)
            Spacer()
            AdjacentChordLabel(chord: chord.nextChord, position: .next)
        }
        .padding(.horizontal, 40)
    }
}

struct AdjacentChordLabel: View {
    let chord: DetectedChord
    let position: Position

    enum Position {
        case previous, next
    }

    var body: some View {
        Text(chord.shortName)
            .font(.system(size: 56, weight: .medium, design: .rounded))
            .foregroundColor(.gray.opacity(0.5))
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 40) {
            AdjacentChordsView(chord: DetectedChord(
                root: .C,
                quality: .major,
                confidence: 0.85,
                notes: [.C, .E, .G]
            ))

            AdjacentChordsView(chord: DetectedChord(
                root: .A,
                quality: .minor,
                confidence: 0.85,
                notes: [.A, .C, .E]
            ))
        }
    }
}
