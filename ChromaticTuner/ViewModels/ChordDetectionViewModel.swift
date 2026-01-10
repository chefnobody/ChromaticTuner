import Foundation
import Combine
import SwiftUI

class ChordDetectionViewModel: ObservableObject {
    @Published var currentChord: DetectedChord?
    @Published var isRecording: Bool = false
    @Published var audioData: AudioVisualizationData?
    @Published var errorMessage: String?

    private let service: ChordDetectionServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    init(service: ChordDetectionServiceProtocol = ChordDetectionService()) {
        self.service = service

        service.chordPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] chord in
                self?.currentChord = chord
            }
            .store(in: &cancellables)

        service.audioDataPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                self?.audioData = data
            }
            .store(in: &cancellables)
    }

    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        do {
            try service.start()
            isRecording = true
            errorMessage = nil
        } catch AudioCaptureError.microphonePermissionDenied {
            errorMessage = "Microphone access required. Please enable in Settings."
        } catch {
            errorMessage = "Failed to start: \(error.localizedDescription)"
        }
    }

    private func stopRecording() {
        service.stop()
        isRecording = false
        currentChord = nil
        audioData = nil
    }
}
