import Foundation

enum FrequencyConverter {
    static func frequencyToMIDINote(_ frequency: Float) -> Float {
        69.0 + 12.0 * log2(frequency / 440.0)
    }

    static func midiNoteToFrequency(_ midiNote: Float) -> Float {
        440.0 * pow(2.0, (midiNote - 69.0) / 12.0)
    }

    static func frequencyToNote(_ frequency: Float) -> Note? {
        Note.from(frequency: frequency)
    }

    static func centsOffset(_ frequency: Float, from note: Note) -> Float {
        let midiNote = frequencyToMIDINote(frequency)
        let roundedMidi = round(midiNote)
        return (midiNote - roundedMidi) * 100.0
    }

    static func semitoneInterval(_ freq1: Float, _ freq2: Float) -> Int {
        let midi1 = frequencyToMIDINote(freq1)
        let midi2 = frequencyToMIDINote(freq2)
        return Int(round(midi2 - midi1)) % 12
    }
}
