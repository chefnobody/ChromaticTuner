import Foundation
import AVFoundation

class PitchDetector: PitchDetectorProtocol {
    private let fftProcessor: FFTProcessor

    init(fftProcessor: FFTProcessor = FFTProcessor()) {
        self.fftProcessor = fftProcessor
    }

    func detectPitches(from buffer: AVAudioPCMBuffer) -> ([DetectedPitch], [Float]) {
        print("📊 PitchDetector: Processing buffer...")
        let spectrum = fftProcessor.processBuffer(buffer)
        let sampleRate = Float(buffer.format.sampleRate)

        let peaks = fftProcessor.detectPeaks(
            in: spectrum,
            sampleRate: sampleRate,
            minFreq: AudioConstants.minDetectionFrequency,
            maxFreq: AudioConstants.maxDetectionFrequency
        )

        print("🔍 Found \(peaks.count) frequency peaks from FFT")

        var filteredCount = 0
        let pitches = peaks.compactMap { peak -> DetectedPitch? in
            if peak.magnitude < AudioConstants.minimumMagnitudeThreshold {
                filteredCount += 1
                return nil
            }

            let frequency = binToFrequency(bin: peak.bin, sampleRate: sampleRate)

            guard let note = Note.from(frequency: frequency) else {
                return nil
            }

            return DetectedPitch(
                frequency: frequency,
                magnitude: peak.magnitude,
                note: note
            )
        }

        if filteredCount > 0 {
            print("🚫 Filtered out \(filteredCount) peaks below magnitude threshold (\(AudioConstants.minimumMagnitudeThreshold))")
        }

        print("✅ Created \(pitches.count) pitch candidates")

        let filteredPitches = removeOctaveDuplicates(pitches)

        if pitches.count != filteredPitches.count {
            print("🔄 Removed \(pitches.count - filteredPitches.count) octave duplicates")
        }

        print("🎵 Final: \(filteredPitches.count) unique pitches")

        return (filteredPitches, spectrum)
    }

    private func binToFrequency(bin: Int, sampleRate: Float) -> Float {
        let binWidth = sampleRate / Float(AudioConstants.fftSize)
        return Float(bin) * binWidth
    }

    private func removeOctaveDuplicates(_ pitches: [DetectedPitch]) -> [DetectedPitch] {
        var uniquePitches: [DetectedPitch] = []

        for pitch in pitches {
            let isDuplicate = uniquePitches.contains { existingPitch in
                pitch.note == existingPitch.note
            }

            if !isDuplicate {
                uniquePitches.append(pitch)
            }
        }

        return uniquePitches
    }
}
