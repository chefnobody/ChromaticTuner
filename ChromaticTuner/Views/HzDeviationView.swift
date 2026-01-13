import SwiftUI

struct HzDeviationView: View {
    let pitch: DetectedPitch?

    private var deviationColor: Color {
        guard let pitch = pitch else { return .gray.opacity(0.3) }
        let absDeviation = abs(pitch.clampedHzDeviation)
        if absDeviation <= 2 {
            return .green
        } else if absDeviation <= 10 {
            return .yellow
        } else {
            return .orange
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            if let pitch = pitch {
                Image(systemName: pitch.clampedHzDeviation >= 0 ? "arrow.up" : "arrow.down")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(deviationColor)
                    .opacity(abs(pitch.clampedHzDeviation) > 2 ? 1.0 : 0.3)

                Text(String(format: "%+.0f Hz", pitch.clampedHzDeviation))
                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                    .foregroundColor(deviationColor)
            } else {
                Image(systemName: "arrow.up")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.gray.opacity(0.3))
                    .opacity(0.3)

                Text("— Hz")
                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                    .foregroundColor(.gray.opacity(0.3))
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 20) {
            HzDeviationView(pitch: DetectedPitch(
                frequency: 442, magnitude: 0.5, note: .A
            ))
            HzDeviationView(pitch: DetectedPitch(
                frequency: 435, magnitude: 0.5, note: .A
            ))
            HzDeviationView(pitch: DetectedPitch(
                frequency: 440, magnitude: 0.5, note: .A
            ))
        }
    }
}
