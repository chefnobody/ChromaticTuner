import Foundation
import AVFoundation

class PitchDetector: PitchDetectorProtocol {
    private let fftProcessor: FFTProcessor
    private let chromaProcessor: ChromaProcessor

    init(
        fftProcessor: FFTProcessor = FFTProcessor(fftSize: AudioConstants.fftSize),
        chromaProcessor: ChromaProcessor = ChromaProcessor()
    ) {
        self.fftProcessor = fftProcessor
        self.chromaProcessor = chromaProcessor
    }

    /// Analyzes a buffer to return high-precision pitches and a 12-bin Chromagram.
    /// - Returns: A tuple containing detected pitches, the raw spectrum, and the 12-bin chroma vector.
    func detectPitches(from buffer: AVAudioPCMBuffer) -> (pitches: [DetectedPitch], spectrum: [Float], chroma: [Float]) {
        let sampleRate = Float(buffer.format.sampleRate)
        
        // 1. Generate Magnitude Spectrum
        let spectrum = fftProcessor.processBuffer(buffer)
        
        // 2. Generate Chromagram (The 12-note energy profile)
        let chroma = chromaProcessor.calculateChroma(from: spectrum, sampleRate: sampleRate)

        // 3. Detect discrete peaks with sub-bin precision
        let peaks = fftProcessor.detectPeaks(
            in: spectrum,
            sampleRate: sampleRate,
            minFreq: AudioConstants.minDetectionFrequency,
            maxFreq: AudioConstants.maxDetectionFrequency
        )

        // 4. Map peaks to formal Pitch objects
        let detectedPitches = peaks.compactMap { peak -> DetectedPitch? in
            guard peak.magnitude >= AudioConstants.minimumMagnitudeThreshold else {
                return nil
            }

            // Use interpolated frequency for pinpoint note mapping
            let frequency = peak.interpolatedFreq
            guard let note = Note.from(frequency: frequency) else {
                return nil
            }

            return DetectedPitch(
                frequency: frequency,
                magnitude: peak.magnitude,
                note: note
            )
        }

        // 5. Clean up Discrete Pitches (Sort by strength and remove octave duplicates)
        let sortedPitches = detectedPitches.sorted { $0.magnitude > $1.magnitude }
        let uniquePitches = removeOctaveDuplicates(sortedPitches)

        return (uniquePitches, spectrum, chroma)
    }

    private func removeOctaveDuplicates(_ pitches: [DetectedPitch]) -> [DetectedPitch] {
        var uniquePitches: [DetectedPitch] = []
        var seenNoteNames = Set<String>()

        for pitch in pitches {
            // Note: If your 'Note' enum/struct includes octaves (e.g., C3 vs C4),
            // you may want to filter by the base name (e.g., "C") to find chord components.
            let noteName = pitch.note.rawValue
            
            if !seenNoteNames.contains(noteName) {
                uniquePitches.append(pitch)
                seenNoteNames.insert(noteName)
            }
        }

        return uniquePitches
    }
}
