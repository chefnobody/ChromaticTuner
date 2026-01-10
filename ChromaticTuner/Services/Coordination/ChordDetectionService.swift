import Foundation
import Combine
import AVFoundation

class ChordDetectionService: ChordDetectionServiceProtocol {
    var chordPublisher: AnyPublisher<DetectedChord?, Never> {
        chordSubject.eraseToAnyPublisher()
    }

    var audioDataPublisher: AnyPublisher<AudioVisualizationData?, Never> {
        audioDataSubject.eraseToAnyPublisher()
    }

    private(set) var isRunning: Bool = false

    private let audioCapture: AudioCaptureServiceProtocol
    private let pitchDetector: PitchDetectorProtocol
    private let chordRecognizer: ChordRecognizerProtocol

    private let chordSubject = CurrentValueSubject<DetectedChord?, Never>(nil)
    private let audioDataSubject = CurrentValueSubject<AudioVisualizationData?, Never>(nil)

    private let processingQueue = DispatchQueue(
        label: "com.chromatictuner.processing",
        qos: .userInitiated
    )

    init(
        audioCapture: AudioCaptureServiceProtocol = AudioCaptureService(),
        pitchDetector: PitchDetectorProtocol = PitchDetector(),
        chordRecognizer: ChordRecognizerProtocol = ChordRecognizer()
    ) {
        self.audioCapture = audioCapture
        self.pitchDetector = pitchDetector
        self.chordRecognizer = chordRecognizer

        var capture = audioCapture
        capture.delegate = self
    }

    func start() throws {
        print("🎵 ChordDetectionService: Starting audio capture...")
        try audioCapture.startCapture()
        isRunning = true
        print("✅ ChordDetectionService: Audio capture started successfully")
    }

    func stop() {
        print("⏹️ ChordDetectionService: Stopping audio capture...")
        audioCapture.stopCapture()
        isRunning = false
        chordSubject.send(nil)
        audioDataSubject.send(nil)
        print("✅ ChordDetectionService: Audio capture stopped")
    }
}

extension ChordDetectionService: AudioCaptureDelegate {
    func didCaptureAudioBuffer(_ buffer: AVAudioPCMBuffer, time: AVAudioTime) {
        print("🎤 Audio buffer received: \(buffer.frameLength) frames at \(buffer.format.sampleRate) Hz")

        processingQueue.async { [weak self] in
            guard let self = self else { return }

            let (pitches, spectrum) = self.pitchDetector.detectPitches(from: buffer)

            print("🎼 Detected \(pitches.count) pitches:")
            for pitch in pitches {
                print("   - \(pitch.note.rawValue): \(String(format: "%.1f", pitch.frequency)) Hz, magnitude: \(String(format: "%.4f", pitch.magnitude))")
            }

            let chord = self.chordRecognizer.recognizeChord(from: pitches)

            if let chord = chord {
                print("🎸 Chord detected: \(chord.displayName) (confidence: \(String(format: "%.2f", chord.confidence)))")
            } else {
                print("❌ No chord detected")
            }

            let audioData = AudioVisualizationData(
                spectrum: spectrum,
                pitches: pitches,
                sampleRate: Float(buffer.format.sampleRate)
            )

            DispatchQueue.main.async {
                self.chordSubject.send(chord)
                self.audioDataSubject.send(audioData)
            }
        }
    }

    func didEncounterError(_ error: Error) {
        print("❌ Audio capture error: \(error)")
        stop()
    }
}
