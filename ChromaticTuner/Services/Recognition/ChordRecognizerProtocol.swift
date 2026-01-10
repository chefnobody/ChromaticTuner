protocol ChordRecognizerProtocol {
    /// Recognizes a chord using a combination of discrete pitch peaks and a chroma energy vector.
    /// - Parameters:
    ///   - pitches: The list of discrete pitches identified in the spectrum.
    ///   - chroma: A 12-element array representing the energy in each semitone (C through B).
    /// - Returns: A `DetectedChord` if a match is found and passes temporal smoothing.
    func recognizeChord(from pitches: [DetectedPitch], chroma: [Float]) -> DetectedChord?
}
