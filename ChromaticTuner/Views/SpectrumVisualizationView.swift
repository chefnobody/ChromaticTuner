import SwiftUI

struct SpectrumVisualizationView: View {
    let audioData: AudioVisualizationData

    private let minFreq: Float = 60
    private let maxFreq: Float = 1000

    var body: some View {
        Canvas { context, size in
            let spectrum = audioData.spectrum
            guard spectrum.count > 0 else { return }

            let binWidth = audioData.frequencyBinWidth
            let minBin = Int(minFreq / binWidth)
            let maxBin = min(Int(maxFreq / binWidth), spectrum.count - 1)

            guard maxBin > minBin else { return }

            let relevantSpectrum = Array(spectrum[minBin...maxBin])
            let maxMagnitude = relevantSpectrum.max() ?? 1.0

            let barCount = relevantSpectrum.count
            let barWidth = size.width / CGFloat(barCount)

            for (index, magnitude) in relevantSpectrum.enumerated() {
                let normalizedHeight = CGFloat(magnitude / maxMagnitude)
                let barHeight = normalizedHeight * size.height

                let x = CGFloat(index) * barWidth
                let y = size.height - barHeight

                let rect = CGRect(x: x, y: y, width: barWidth - 1, height: barHeight)

                let color = Color.blue.opacity(0.7)
                context.fill(Path(rect), with: .color(color))
            }

            for pitch in audioData.pitches {
                let frequency = pitch.frequency
                if frequency >= minFreq && frequency <= maxFreq {
                    let bin = Int(frequency / binWidth) - minBin
                    if bin >= 0 && bin < relevantSpectrum.count {
                        let x = CGFloat(bin) * barWidth + barWidth / 2
                        let markerPath = Path { path in
                            path.move(to: CGPoint(x: x, y: size.height))
                            path.addLine(to: CGPoint(x: x, y: 0))
                        }
                        context.stroke(markerPath, with: .color(.green), lineWidth: 2)

                        let noteText = Text(pitch.note.rawValue)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.green)

                        context.draw(noteText, at: CGPoint(x: x, y: 10))
                    }
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        SpectrumVisualizationView(
            audioData: AudioVisualizationData(
                spectrum: Array(repeating: 0.1, count: 1024),
                pitches: [],
                sampleRate: 44100
            )
        )
        .frame(height: 200)
        .padding()
    }
}
