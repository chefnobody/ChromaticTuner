import Foundation
import Accelerate
import AVFoundation

class FFTProcessor {
    private let fftSize: Int
    private let fftSetup: vDSP_DFT_Setup

    // Pre-allocated buffers to prevent heap allocation during callbacks
    private var window: [Float]
    private var windowedData: [Float]
    private var evenSamples: [Float]  // Deinterleaved input (even indices) for zrop
    private var oddSamples: [Float]   // Deinterleaved input (odd indices) for zrop
    private var realParts: [Float]    // Output real parts (size N/2)
    private var imagParts: [Float]    // Output imag parts (size N/2)
    private var magnitudes: [Float]   // Magnitude spectrum (size N/2)

    // HPS (Harmonic Product Spectrum) buffers
    private let hpsHarmonics: Int = 5  // Number of harmonics to use (typically 3-5)
    private var hpsSpectrum: [Float]   // Result of HPS computation
    private var hpsLogSpectrum: [Float]  // Log of magnitude spectrum for numerical stability
    private var hpsAccumulator: [Float]  // Accumulator for log-sum

    init(fftSize: Int = 2048) {
        self.fftSize = fftSize

        // Use zrop for real-to-complex transform (more efficient for real audio signals)
        guard let setup = vDSP_DFT_zrop_CreateSetup(
            nil,
            vDSP_Length(fftSize),
            vDSP_DFT_Direction.FORWARD
        ) else {
            fatalError("Failed to create FFT setup")
        }
        self.fftSetup = setup

        self.window = [Float](repeating: 0, count: fftSize)
        self.windowedData = [Float](repeating: 0, count: fftSize)
        self.evenSamples = [Float](repeating: 0, count: fftSize / 2)
        self.oddSamples = [Float](repeating: 0, count: fftSize / 2)
        self.realParts = [Float](repeating: 0, count: fftSize / 2)
        self.imagParts = [Float](repeating: 0, count: fftSize / 2)
        self.magnitudes = [Float](repeating: 0, count: fftSize / 2)

        // HPS output size is spectrum_size / hpsHarmonics (limited by highest downsample factor)
        let hpsSize = fftSize / (2 * hpsHarmonics)
        self.hpsSpectrum = [Float](repeating: 0, count: hpsSize)
        self.hpsLogSpectrum = [Float](repeating: 0, count: fftSize / 2)
        self.hpsAccumulator = [Float](repeating: 0, count: hpsSize)

        vDSP_hann_window(&self.window, vDSP_Length(fftSize), Int32(vDSP_HANN_NORM))
    }

    deinit {
        vDSP_DFT_DestroySetup(fftSetup)
    }

    func processBuffer(_ buffer: AVAudioPCMBuffer) -> [Float] {
        guard let channelData = buffer.floatChannelData?[0] else { return [] }
        let dataSize = min(Int(buffer.frameLength), fftSize)

        // 1. Apply window function
        vDSP_vmul(channelData, 1, window, 1, &windowedData, 1, vDSP_Length(dataSize))

        // Zero-pad if buffer is smaller than FFT size
        if dataSize < fftSize {
            for i in dataSize..<fftSize {
                windowedData[i] = 0
            }
        }

        // 2. Deinterleave windowed data for zrop input format
        // zrop expects: evenSamples[j] = input[2*j], oddSamples[j] = input[2*j+1]
        windowedData.withUnsafeBufferPointer { srcPtr in
            evenSamples.withUnsafeMutableBufferPointer { evenPtr in
                oddSamples.withUnsafeMutableBufferPointer { oddPtr in
                    cblas_scopy(Int32(fftSize / 2), srcPtr.baseAddress!, 2, evenPtr.baseAddress!, 1)
                    cblas_scopy(Int32(fftSize / 2), srcPtr.baseAddress! + 1, 2, oddPtr.baseAddress!, 1)
                }
            }
        }

        // 3. Execute real-to-complex FFT
        vDSP_DFT_Execute(fftSetup, evenSamples, oddSamples, &realParts, &imagParts)

        // 4. Compute magnitudes
        // zrop output packing: realParts[0] = DC, imagParts[0] = Nyquist
        // For bins 1 to N/2-1: realParts[k] + i*imagParts[k] = H[k]

        // Handle DC bin separately (pure real, imagParts[0] contains Nyquist not DC's imaginary)
        magnitudes[0] = abs(realParts[0])

        // Compute magnitudes for bins 1 to N/2-1 using vectorized operation
        realParts.withUnsafeMutableBufferPointer { rPtr in
            imagParts.withUnsafeMutableBufferPointer { iPtr in
                magnitudes.withUnsafeMutableBufferPointer { magPtr in
                    var splitComplex = DSPSplitComplex(
                        realp: rPtr.baseAddress! + 1,
                        imagp: iPtr.baseAddress! + 1
                    )
                    vDSP_zvabs(&splitComplex, 1, magPtr.baseAddress! + 1, 1, vDSP_Length(fftSize / 2 - 1))
                }
            }
        }

        // 5. Scale to get proper magnitude values
        // zrop applies x2 scaling internally, so we divide by N (equivalent to 2/N with zop)
        var scaleFactor = 1.0 / Float(fftSize)
        vDSP_vsmul(magnitudes, 1, &scaleFactor, &magnitudes, 1, vDSP_Length(fftSize / 2))

        return magnitudes
    }

    /// Computes the Harmonic Product Spectrum from a magnitude spectrum.
    /// HPS aligns harmonics at the fundamental frequency by downsampling and multiplying,
    /// making fundamental frequency detection more robust against strong harmonics.
    ///
    /// Uses log-sum instead of direct multiplication for numerical stability:
    /// log(HPS[k]) = Σ log|X[n*k]| for n = 1 to R
    ///
    /// - Parameter spectrum: The magnitude spectrum from processBuffer()
    /// - Returns: The HPS spectrum (smaller than input due to downsampling limits)
    func computeHPS(from spectrum: [Float]) -> [Float] {
        let spectrumSize = spectrum.count
        let hpsSize = spectrumSize / hpsHarmonics

        guard hpsSize > 0 else { return [] }

        // 1. Compute log of magnitude spectrum (add small epsilon to avoid log(0))
        var epsilon: Float = 1e-10
        var logInput = spectrum
        vDSP_vsadd(spectrum, 1, &epsilon, &logInput, 1, vDSP_Length(spectrumSize))

        var logCount = Int32(spectrumSize)
        vvlogf(&hpsLogSpectrum, logInput, &logCount)

        // 2. Initialize accumulator with the first harmonic (no downsampling, n=1)
        for i in 0..<hpsSize {
            hpsAccumulator[i] = hpsLogSpectrum[i]
        }

        // 3. Add log of downsampled spectra for harmonics 2 through hpsHarmonics
        // Downsampling by n means taking every nth sample: spectrum[n*k] for k = 0, 1, 2, ...
        for harmonic in 2...hpsHarmonics {
            for k in 0..<hpsSize {
                let sourceIndex = k * harmonic
                if sourceIndex < spectrumSize {
                    hpsAccumulator[k] += hpsLogSpectrum[sourceIndex]
                }
            }
        }

        // 4. Convert back from log domain: HPS = exp(log_sum)
        var expCount = Int32(hpsSize)
        vvexpf(&hpsSpectrum, hpsAccumulator, &expCount)

        return Array(hpsSpectrum.prefix(hpsSize))
    }

    /// Detects peaks in the HPS spectrum and converts to frequency with octave error correction.
    ///
    /// - Parameters:
    ///   - hpsSpectrum: The HPS spectrum from computeHPS()
    ///   - originalSpectrum: The original magnitude spectrum (for octave correction validation)
    ///   - sampleRate: Audio sample rate in Hz
    ///   - minFreq: Minimum frequency to search (Hz)
    ///   - maxFreq: Maximum frequency to search (Hz)
    /// - Returns: Array of detected peaks with bin, magnitude, and interpolated frequency
    func detectHPSPeaks(
        in hpsSpectrum: [Float],
        originalSpectrum: [Float],
        sampleRate: Float,
        minFreq: Float,
        maxFreq: Float
    ) -> [(bin: Int, magnitude: Float, interpolatedFreq: Float)] {
        // HPS bin k corresponds to the same frequency as original spectrum bin k
        // The bin width is identical to the original spectrum
        let binWidth = sampleRate / Float(fftSize)

        // Constrain search range to valid HPS bins
        let minBin = max(1, Int(ceil(minFreq / binWidth)))
        let maxBin = min(hpsSpectrum.count - 2, Int(floor(maxFreq / binWidth)))

        guard minBin <= maxBin else { return [] }

        var detectedPeaks: [(bin: Int, magnitude: Float, interpolatedFreq: Float)] = []

        for i in minBin...maxBin {
            let val = hpsSpectrum[i]

            // Local maxima check
            if val > hpsSpectrum[i - 1] && val > hpsSpectrum[i + 1] {
                // Quadratic interpolation for sub-bin accuracy
                let alpha = hpsSpectrum[i - 1]
                let beta = hpsSpectrum[i]
                let gamma = hpsSpectrum[i + 1]

                let denominator = alpha - 2 * beta + gamma
                let p = denominator != 0 ? 0.5 * (alpha - gamma) / denominator : 0

                let interpolatedBin = Float(i) + p
                var frequency = interpolatedBin * binWidth

                // Apply octave error correction
                frequency = correctOctaveError(
                    frequency: frequency,
                    hpsMagnitude: val,
                    originalSpectrum: originalSpectrum,
                    sampleRate: sampleRate
                )

                detectedPeaks.append((bin: i, magnitude: val, interpolatedFreq: frequency))
            }
        }

        detectedPeaks.sort { $0.magnitude > $1.magnitude }
        return Array(detectedPeaks.prefix(10))
    }

    /// Corrects common harmonic errors in HPS detection.
    /// Checks if the detected frequency is actually a harmonic (2nd, 3rd, 4th, or 5th)
    /// of a lower fundamental by looking for energy at sub-harmonic frequencies.
    ///
    /// Rule: If magnitude at f/n > threshold * magnitude at f, choose f/n
    private func correctOctaveError(
        frequency: Float,
        hpsMagnitude: Float,
        originalSpectrum: [Float],
        sampleRate: Float
    ) -> Float {
        let binWidth = sampleRate / Float(fftSize)
        let currentBin = Int(frequency / binWidth)
        let currentMagnitude = currentBin < originalSpectrum.count ? originalSpectrum[currentBin] : 0

        // Harmonic correction threshold: if the sub-harmonic has at least 20% of the energy,
        // it's likely the true fundamental (harmonics often exceed fundamental in amplitude)
        let harmonicCorrectionThreshold: Float = 0.2
        let minFrequency: Float = 50.0  // Noise floor

        // Check sub-harmonics in order of likelihood (2nd, 3rd, 4th, 5th)
        // Lower divisors are more common harmonic errors
        for divisor in 2...5 {
            let subHarmonicFreq = frequency / Float(divisor)
            let subHarmonicBin = currentBin / divisor

            // Check if sub-harmonic bin is valid and above noise floor
            guard subHarmonicBin > 0,
                  subHarmonicBin < originalSpectrum.count,
                  subHarmonicFreq >= minFrequency else {
                continue
            }

            let subHarmonicMagnitude = originalSpectrum[subHarmonicBin]

            if subHarmonicMagnitude > harmonicCorrectionThreshold * currentMagnitude {
                // Found a likely fundamental - recursively check if this is also a harmonic
                return correctOctaveError(
                    frequency: subHarmonicFreq,
                    hpsMagnitude: hpsMagnitude,
                    originalSpectrum: originalSpectrum,
                    sampleRate: sampleRate
                )
            }
        }

        return frequency
    }

    func detectPeaks(in spectrum: [Float], sampleRate: Float, minFreq: Float, maxFreq: Float) -> [(bin: Int, magnitude: Float, interpolatedFreq: Float)] {
        let binWidth = sampleRate / Float(fftSize)
        let minBin = max(1, Int(ceil(minFreq / binWidth)))
        let maxBin = min(spectrum.count - 2, Int(floor(maxFreq / binWidth)))

        var detectedPeaks: [(bin: Int, magnitude: Float, interpolatedFreq: Float)] = []

        for i in minBin...maxBin {
            let val = spectrum[i]
            
            // Local maxima check
            if val > spectrum[i-1] && val > spectrum[i+1] {
                // Quadratic Interpolation for sub-bin accuracy
                let alpha = spectrum[i-1]
                let beta = spectrum[i]
                let gamma = spectrum[i+1]
                
                let denominator = (alpha - 2 * beta + gamma)
                let p = denominator != 0 ? 0.5 * (alpha - gamma) / denominator : 0
                
                let interpolatedBin = Float(i) + p
                let actualFreq = interpolatedBin * binWidth
                
                detectedPeaks.append((bin: i, magnitude: val, interpolatedFreq: actualFreq))
            }
        }

        detectedPeaks.sort { $0.magnitude > $1.magnitude }
        return Array(detectedPeaks.prefix(10))
    }
}
