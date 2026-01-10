import Foundation
import Combine

protocol ChordDetectionServiceProtocol {
    var chordPublisher: AnyPublisher<DetectedChord?, Never> { get }
    var audioDataPublisher: AnyPublisher<AudioVisualizationData?, Never> { get }
    var isRunning: Bool { get }

    func start() throws
    func stop()
}
