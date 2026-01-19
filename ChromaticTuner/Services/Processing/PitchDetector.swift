import Foundation
import AVFoundation

class PitchDetector: PitchDetectorProtocol {
    private let fftProcessor: FFTProcessor
    private let chromaProcessor: ChromaProcessor

    // Note locking state for stable tuner behavior
    private var lockedNote: Note?
    private var lockedNoteFrequency: Float = 0
    private var lockConfidence: Int = 0

    // Frequency smoothing buffer
    private var frequencyHistory: [Float] = []
    private let smoothingWindowSize = 5

    // Hysteresis threshold in cents - only switch notes when this far into the new note
    // A semitone is 100 cents, so 35 cents means we need to be 35% into the next note
    private let hysteresisCents: Float = 35

    init(
        fftProcessor: FFTProcessor = FFTProcessor(fftSize: AudioConstants.fftSize),
        chromaProcessor: ChromaProcessor = ChromaProcessor()
    ) {
        self.fftProcessor = fftProcessor
        self.chromaProcessor = chromaProcessor
    }

    /// Analyzes a buffer to return high-precision pitches and a 12-bin Chromagram.
    /// Uses Harmonic Product Spectrum (HPS) for more accurate fundamental frequency detection.
    /// - Returns: A tuple containing detected pitches, the raw spectrum, and the 12-bin chroma vector.
    func detectPitches(from buffer: AVAudioPCMBuffer) -> (
        pitches: [DetectedPitch],
        spectrum: [Float],
        chroma: [Float]
    ) {
        let sampleRate = Float(buffer.format.sampleRate)

        // 1. Generate Magnitude Spectrum
        let spectrum = fftProcessor.processBuffer(buffer)

        // 2. Generate Chromagram (uses full spectrum - harmonics are useful for chroma)
        let chroma = chromaProcessor.calculateChroma(from: spectrum, sampleRate: sampleRate)

        // 3. Compute Harmonic Product Spectrum for robust fundamental frequency detection
        // HPS aligns harmonics at the fundamental, reducing octave errors and harmonic confusion
        let hpsSpectrum = fftProcessor.computeHPS(from: spectrum)

        // 4. Detect peaks using HPS with octave error correction
        let peaks = fftProcessor.detectHPSPeaks(
            in: hpsSpectrum,
            originalSpectrum: spectrum,
            sampleRate: sampleRate,
            minFreq: AudioConstants.minDetectionFrequency,
            maxFreq: AudioConstants.maxDetectionFrequency
        )

        // 5. Map peaks to formal Pitch objects with note locking
        let binWidth = sampleRate / Float(AudioConstants.fftSize)
        let detectedPitches = peaks.compactMap { peak -> DetectedPitch? in
            let rawFrequency = peak.interpolatedFreq

            // Look up magnitude from original spectrum for accurate amplitude
            let originalBin = Int(rawFrequency / binWidth)
            let magnitude = originalBin < spectrum.count ? spectrum[originalBin] : peak.magnitude

            guard magnitude >= AudioConstants.minimumMagnitudeThreshold else {
                return nil
            }

            // Apply frequency smoothing to reduce jitter
            let smoothedFrequency = smoothFrequency(rawFrequency)

            // Apply note locking with hysteresis for stable note detection
            let note = lockNote(for: smoothedFrequency)

            return DetectedPitch(
                frequency: smoothedFrequency,
                magnitude: magnitude,
                note: note
            )
        }

        // 6. Clean up Discrete Pitches (Sort by strength and remove octave duplicates)
        let sortedPitches = detectedPitches.sorted { $0.magnitude > $1.magnitude }
        let uniquePitches = removeOctaveDuplicates(sortedPitches)

        return (uniquePitches, spectrum, chroma)
    }

    /// Smooths frequency readings using a moving average to reduce jitter
    private func smoothFrequency(_ frequency: Float) -> Float {
        frequencyHistory.append(frequency)

        // Keep only the most recent readings
        if frequencyHistory.count > smoothingWindowSize {
            frequencyHistory.removeFirst()
        }

        // Return the median for robustness against outliers
        let sorted = frequencyHistory.sorted()
        return sorted[sorted.count / 2]
    }

    /// Locks onto a note and only switches when the pitch moves significantly past the boundary.
    /// This prevents the display from jumping between notes when near the boundary.
    private func lockNote(for frequency: Float) -> Note {
        // Calculate the nearest note using standard rounding
        let nearestNote = Note.from(frequency: frequency) ?? .A

        // If no note is locked yet, lock to the nearest note
        guard let currentLocked = lockedNote else {
            lockedNote = nearestNote
            lockedNoteFrequency = idealFrequency(for: nearestNote, near: frequency)
            lockConfidence = 1
            return nearestNote
        }

        // Calculate cents deviation from the currently locked note
        let centsFromLocked = 1200 * log2(frequency / lockedNoteFrequency)

        // If we're within 50 cents of the locked note, stay locked
        // (50 cents is the boundary to the next semitone)
        if abs(centsFromLocked) <= 50 {
            lockConfidence = min(lockConfidence + 1, 10)
            return currentLocked
        }

        // We're past the boundary - check if we should switch
        // Only switch if we're hysteresisCents into the new note's territory
        let centsIntoNewNote = abs(centsFromLocked) - 50

        if centsIntoNewNote >= hysteresisCents {
            // Switch to the new note
            lockedNote = nearestNote
            lockedNoteFrequency = idealFrequency(for: nearestNote, near: frequency)
            lockConfidence = 1
            return nearestNote
        }

        // In the hysteresis zone - stay with the locked note but decrease confidence
        lockConfidence = max(lockConfidence - 1, 0)

        // If confidence drops to zero, allow the switch
        if lockConfidence == 0 {
            lockedNote = nearestNote
            lockedNoteFrequency = idealFrequency(for: nearestNote, near: frequency)
            lockConfidence = 1
            return nearestNote
        }

        return currentLocked
    }

    /// Calculates the ideal frequency for a note in the octave nearest to the reference frequency
    private func idealFrequency(for note: Note, near referenceFreq: Float) -> Float {
        // A4 = 440 Hz = MIDI 69
        // Find the octave that puts this note closest to the reference frequency
        let a4Freq: Float = 440.0
        let semitoneOffset = note.semitoneOffset - 9  // A is semitone 9, so offset from A

        // Try different octaves and find the closest one
        var bestFreq: Float = a4Freq
        var bestDistance: Float = .infinity

        for octaveOffset in -4...4 {
            let freq = a4Freq * pow(2.0, Float(octaveOffset) + Float(semitoneOffset) / 12.0)
            let distance = abs(freq - referenceFreq)
            if distance < bestDistance {
                bestDistance = distance
                bestFreq = freq
            }
        }

        return bestFreq
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
