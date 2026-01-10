import Foundation

struct AudioVisualizationData {
    let spectrum: [Float]
    let pitches: [DetectedPitch]
    let sampleRate: Float

    var frequencyBinWidth: Float {
        sampleRate / Float(spectrum.count * 2)
    }

    func frequency(forBin bin: Int) -> Float {
        Float(bin) * frequencyBinWidth
    }
}
