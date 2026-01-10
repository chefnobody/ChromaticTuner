import Foundation

class ChromaProcessor {
    // 12 bins for the 12 semitones
    private let numberOfNotes = 12
    private let referenceFrequency: Float = 440.0 // A4
    
    func calculateChroma(from spectrum: [Float], sampleRate: Float) -> [Float] {
        var chroma = [Float](repeating: 0.0, count: numberOfNotes)
        let binWidth = sampleRate / Float(AudioConstants.fftSize)
        
        // We only care about the musical range (e.g., 20Hz to 5000Hz)
        let minBin = Int(ceil(20.0 / binWidth))
        let maxBin = min(spectrum.count - 1, Int(floor(5000.0 / binWidth)))
        
        for bin in minBin...maxBin {
            let magnitude = spectrum[bin]
            guard magnitude > 0 else { continue }
            
            let frequency = Float(bin) * binWidth
            
            // Convert frequency to a pitch index (MIDI-style float)
            // formula: 12 * log2(f / 440) + 69
            let pitchIndex = 12.0 * log2(frequency / referenceFrequency) + 69.0
            
            // Map to 0-11 (C to B)
            // We use floor to "bucket" the energy, or rounding for center-focus
            let noteSymbol = Int(round(pitchIndex)) % numberOfNotes
            let chromaIndex = (noteSymbol >= 0) ? noteSymbol : noteSymbol + numberOfNotes
            
            // Add the energy of this bin to the corresponding chroma bin
            chroma[chromaIndex] += magnitude
        }
        
        // Check if there's enough energy to be considered actual audio (not just noise)
        // Threshold filters out ambient noise that would otherwise match random chords
        guard let maxVal = chroma.max(), maxVal > 0.01 else {
            // Return empty chroma for silence/noise - prevents false chord detection
            return [Float](repeating: 0.0, count: numberOfNotes)
        }

        // Normalize the chroma vector (0.0 to 1.0) so volume doesn't break detection
        for i in 0..<numberOfNotes {
            chroma[i] /= maxVal
        }

        return chroma
    }
}
