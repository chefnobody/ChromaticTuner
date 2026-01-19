import SwiftUI

struct SpectrumVisualizationView: View {
    let audioData: AudioVisualizationData

    private let minFreq: Float = 60
    private let maxFreq: Float = 1000

    private let targetBarCount = 32

    var body: some View {
        Canvas { context, size in
            let spectrum = audioData.spectrum
            guard spectrum.count > 0 else { return }

            let binWidth = audioData.frequencyBinWidth
            let minBin = Int(minFreq / binWidth)
            let maxBin = min(Int(maxFreq / binWidth), spectrum.count - 1)

            guard maxBin > minBin else { return }

            let relevantSpectrum = Array(spectrum[minBin...maxBin])

            // Group bins together to create fewer, wider bars
            let binsPerBar = max(1, relevantSpectrum.count / targetBarCount)
            var groupedSpectrum: [Float] = []
            
            for i in stride(from: 0, to: relevantSpectrum.count, by: binsPerBar) {
                let end = min(i + binsPerBar, relevantSpectrum.count)
                let group = relevantSpectrum[i..<end]
                let avg = group.reduce(0, +) / Float(group.count)
                groupedSpectrum.append(avg)
            }

            let maxMagnitude = groupedSpectrum.max() ?? 1.0

            let barCount = groupedSpectrum.count
            let barWidth = size.width / CGFloat(barCount)
            let barGap: CGFloat = 2

            for (index, magnitude) in groupedSpectrum.enumerated() {
                let normalizedHeight = CGFloat(magnitude / maxMagnitude)
                let barHeight = normalizedHeight * size.height

                let x = CGFloat(index) * barWidth
                let y = size.height - barHeight

                let rect = CGRect(x: x + barGap / 2, y: y, width: barWidth - barGap, height: barHeight)

                let color = Color.blue.opacity(0.7)
                context.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(color))
            }

        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        SpectrumVisualizationView(
            audioData: AudioVisualizationData(
                spectrum: Array(repeating: 0.1, count: 2048),
                pitches: [],
                sampleRate: 44100
            )
        )
        .frame(height: 200)
        .padding()
    }
}
