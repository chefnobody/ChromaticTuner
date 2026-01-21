import SwiftUI

struct SpectrumVisualizationView: View {
    let audioData: AudioVisualizationData

    private let minFreq: Float = 60
    private let maxFreq: Float = 1000
    private let targetBarCount = 32

    @State private var barHeights: [CGFloat] = Array(repeating: 0, count: 32)

    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .center, spacing: 2) {
                ForEach(0..<barHeights.count, id: \.self) { index in
                    WaveformBar(height: barHeights[index], maxHeight: geometry.size.height)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onChange(of: audioData.spectrum) {
            updateBarHeights()
        }
        .onAppear {
            updateBarHeights()
        }
    }

    private func updateBarHeights() {
        let spectrum = audioData.spectrum
        guard spectrum.count > 0 else { return }

        let binWidth = audioData.frequencyBinWidth
        let minBin = Int(minFreq / binWidth)
        let maxBin = min(Int(maxFreq / binWidth), spectrum.count - 1)

        guard maxBin > minBin else { return }

        let relevantSpectrum = Array(spectrum[minBin...maxBin])

        let binsPerBar = max(1, relevantSpectrum.count / targetBarCount)
        var groupedSpectrum: [Float] = []

        for i in stride(from: 0, to: relevantSpectrum.count, by: binsPerBar) {
            let end = min(i + binsPerBar, relevantSpectrum.count)
            let group = relevantSpectrum[i..<end]
            let avg = group.reduce(0, +) / Float(group.count)
            groupedSpectrum.append(avg)
        }

        let maxMagnitude = max(groupedSpectrum.max() ?? 1.0, 0.001)

        var newHeights: [CGFloat] = []
        for i in 0..<targetBarCount {
            if i < groupedSpectrum.count {
                let normalized = CGFloat(groupedSpectrum[i] / maxMagnitude)
                newHeights.append(min(normalized, 1.0))
            } else {
                newHeights.append(0)
            }
        }

        withAnimation(.interpolatingSpring(stiffness: 300, damping: 15)) {
            barHeights = newHeights
        }
    }
}

private struct WaveformBar: View {
    let height: CGFloat
    let maxHeight: CGFloat

    private let minBarHeight: CGFloat = 4

    var body: some View {
        let barHeight = max(height * maxHeight, minBarHeight)

        Capsule()
            .fill(
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.9),
                        Color.cyan.opacity(0.7)
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .frame(height: barHeight)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        SpectrumVisualizationView(
            audioData: AudioVisualizationData(
                spectrum: (0..<2048).map { i in
                    Float.random(in: 0.05...0.5) * (1.0 - Float(i) / 2048.0)
                },
                pitches: [],
                sampleRate: 44100
            )
        )
        .frame(height: 200)
        .padding()
    }
}
