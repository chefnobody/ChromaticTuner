import Foundation
import Accelerate
import AVFoundation

class FFTProcessor {
    private let fftSize: Int
    private let fftSetup: vDSP_DFT_Setup
    
    // Pre-allocated buffers to prevent heap allocation during callbacks
    private var window: [Float]
    private var realParts: [Float]
    private var imagParts: [Float]
    private var inputImagParts: [Float]
    private var magnitudes: [Float]
    private var windowedData: [Float]

    init(fftSize: Int = 2048) {
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
        self.realParts = [Float](repeating: 0, count: fftSize)
        self.imagParts = [Float](repeating: 0, count: fftSize)
        self.inputImagParts = [Float](repeating: 0, count: fftSize)
        self.magnitudes = [Float](repeating: 0, count: fftSize / 2)
        self.windowedData = [Float](repeating: 0, count: fftSize)

        vDSP_hann_window(&self.window, vDSP_Length(fftSize), Int32(vDSP_HANN_NORM))
    }

    deinit {
        vDSP_DFT_DestroySetup(fftSetup)
    }

    func processBuffer(_ buffer: AVAudioPCMBuffer) -> [Float] {
        guard let channelData = buffer.floatChannelData?[0] else { return [] }
        let dataSize = min(Int(buffer.frameLength), fftSize)

        // 1. Vectorized Windowing
        vDSP_vmul(channelData, 1, window, 1, &windowedData, 1, vDSP_Length(dataSize))

        // 2. Execute FFT
        vDSP_DFT_Execute(fftSetup, windowedData, inputImagParts, &realParts, &imagParts)

        // 3. Vectorized Magnitude Calculation (Fixing the inout warning)
        // We create the SplitComplex structure locally so the pointers are valid for the call
        realParts.withUnsafeMutableBufferPointer { rPtr in
            imagParts.withUnsafeMutableBufferPointer { iPtr in
                var splitComplex = DSPSplitComplex(realp: rPtr.baseAddress!, imagp: iPtr.baseAddress!)
                vDSP_zvabs(&splitComplex, 1, &magnitudes, 1, vDSP_Length(fftSize / 2))
            }
        }

        // 4. Vectorized Scaling
        var scaleFactor = 2.0 / Float(fftSize)
        vDSP_vsmul(magnitudes, 1, &scaleFactor, &magnitudes, 1, vDSP_Length(fftSize / 2))

        return magnitudes
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
