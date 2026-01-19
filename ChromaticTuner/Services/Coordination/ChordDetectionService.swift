import Foundation
import Combine
import AVFoundation
import os

class ChordDetectionService: ChordDetectionServiceProtocol {
    private let logger = Logger(subsystem: "com.chromatictuner", category: "ChordDetection")
    var chordPublisher: AnyPublisher<DetectedChord?, Never> {
        chordSubject.eraseToAnyPublisher()
    }

    var audioDataPublisher: AnyPublisher<AudioVisualizationData?, Never> {
        audioDataSubject.eraseToAnyPublisher()
    }

    private(set) var isRunning: Bool = false

    private var audioCapture: AudioCaptureServiceProtocol
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
    }

    func start() throws {
        audioCapture.delegate = self
        try audioCapture.startCapture()
        isRunning = true
    }

    func stop() {
        audioCapture.stopCapture()
        isRunning = false
        chordSubject.send(nil)
        audioDataSubject.send(nil)
    }
}

extension ChordDetectionService: AudioCaptureDelegate {
    func didCaptureAudioBuffer(_ buffer: AVAudioPCMBuffer, time: AVAudioTime) {
        
        processingQueue.async { [weak self] in
            guard let self = self else { return }

            // 1. Updated Call: Now captures (pitches, spectrum, chroma)
            let result = self.pitchDetector.detectPitches(from: buffer)
            
            // 2. Pass both pitches and chroma to the updated recognizer
            let chord = self.chordRecognizer.recognizeChord(
                from: result.pitches,
                chroma: result.chroma
            )

            // 3. Prepare visualization data
            let audioData = AudioVisualizationData(
                spectrum: result.spectrum,
                pitches: result.pitches,
                sampleRate: Float(buffer.format.sampleRate)
            )

            // 4. Update UI on main thread
            DispatchQueue.main.async {
                // Only send if the value has actually changed or needs updating
                self.chordSubject.send(chord)
                self.audioDataSubject.send(audioData)
            }
        }
    }

    func didEncounterError(_ error: Error) {
        logger.error("Audio capture error: \(error)")
        stop()
    }
}
