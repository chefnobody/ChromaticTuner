import Foundation
import Accelerate
import AVFoundation

class FFTProcessor {
    private let fftSize: Int
    private let fftSetup: vDSP_DFT_Setup
    private var window: [Float]

    private var realParts: [Float]
    private var imagParts: [Float]
    private var inputImagParts: [Float]

    init(fftSize: Int = AudioConstants.fftSize) {
        self.fftSize = fftSize

        guard let setup = vDSP_DFT_zop_CreateSetup(
            nil,
            vDSP_Length(fftSize),
            vDSP_DFT_Direction.FORWARD
        ) else {
            fatalError("Failed to create FFT setup")
        }

        self.fftSetup = setup

        self.window = [Float](repeating: 0, count: fftSize)
        vDSP_hann_window(&self.window, vDSP_Length(fftSize), Int32(vDSP_HANN_NORM))

        self.realParts = [Float](repeating: 0, count: fftSize)
        self.imagParts = [Float](repeating: 0, count: fftSize)
        self.inputImagParts = [Float](repeating: 0, count: fftSize)
    }

    deinit {
        vDSP_DFT_DestroySetup(fftSetup)
    }

    func processBuffer(_ buffer: AVAudioPCMBuffer) -> [Float] {
        guard let channelData = buffer.floatChannelData?[0] else {
            print("❌ FFTProcessor: No channel data available")
            return []
        }

        let frameCount = Int(buffer.frameLength)
        let dataSize = min(frameCount, fftSize)

        // Calculate RMS of input signal
        var rms: Float = 0
        vDSP_rmsqv(channelData, 1, &rms, vDSP_Length(dataSize))
        print("📈 FFTProcessor: Input RMS: \(String(format: "%.6f", rms))")

        var windowedData = [Float](repeating: 0, count: fftSize)

        for i in 0..<dataSize {
            windowedData[i] = channelData[i] * window[i]
        }

        vDSP_DFT_Execute(fftSetup, windowedData, inputImagParts, &realParts, &imagParts)

        return computeMagnitudeSpectrum()
    }

    private func computeMagnitudeSpectrum() -> [Float] {
        let halfSize = fftSize / 2
        var magnitudes = [Float](repeating: 0, count: halfSize)

        for i in 0..<halfSize {
            let real = realParts[i]
            let imag = imagParts[i]
            magnitudes[i] = sqrt(real * real + imag * imag)
        }

        let scaleFactor = 2.0 / Float(fftSize)
        vDSP_vsmul(magnitudes, 1, [scaleFactor], &magnitudes, 1, vDSP_Length(halfSize))

        return magnitudes
    }

    func detectPeaks(in spectrum: [Float], sampleRate: Float, minFreq: Float, maxFreq: Float) -> [(bin: Int, magnitude: Float)] {
        let binWidth = sampleRate / Float(fftSize)
        let minBin = Int(ceil(minFreq / binWidth))
        let maxBin = Int(floor(maxFreq / binWidth))

        print("🔎 FFTProcessor: Searching for peaks between \(minFreq)-\(maxFreq) Hz (bins \(minBin)-\(maxBin))")

        guard maxBin > minBin, maxBin < spectrum.count else {
            print("❌ FFTProcessor: Invalid bin range")
            return []
        }

        let relevantSpectrum = Array(spectrum[minBin...maxBin])
        guard let maxMagnitude = relevantSpectrum.max(), maxMagnitude > 0 else {
            print("⚠️ FFTProcessor: No signal in spectrum (max magnitude = 0)")
            return []
        }

        let thresholdLinear = maxMagnitude * pow(10, AudioConstants.peakThresholdDB / 20.0)
        print("📊 FFTProcessor: Max magnitude: \(String(format: "%.6f", maxMagnitude)), Threshold: \(String(format: "%.6f", thresholdLinear)) (\(AudioConstants.peakThresholdDB) dB)")

        var peaks: [(bin: Int, magnitude: Float)] = []

        for i in 1..<relevantSpectrum.count - 1 {
            let magnitude = relevantSpectrum[i]

            if magnitude > thresholdLinear &&
               magnitude > relevantSpectrum[i - 1] &&
               magnitude > relevantSpectrum[i + 1] {
                let freq = Float(minBin + i) * binWidth
                peaks.append((bin: minBin + i, magnitude: magnitude))
                print("   🎯 Peak at bin \(minBin + i): \(String(format: "%.1f", freq)) Hz, magnitude: \(String(format: "%.6f", magnitude))")
            }
        }

        peaks.sort { $0.magnitude > $1.magnitude }

        let finalPeaks = Array(peaks.prefix(AudioConstants.maxPitchesCount))
        print("✅ FFTProcessor: Returning top \(finalPeaks.count) peaks")

        return finalPeaks
    }
}
