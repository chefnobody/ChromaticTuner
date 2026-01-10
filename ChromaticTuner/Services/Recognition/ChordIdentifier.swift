import Foundation

class ChordIdentifier {
    private let library = ChordLibrary()
    
    /// Identifies the most likely chord from a Chroma vector.
    /// - Parameter chroma: A 12-bin normalized array from ChromaProcessor.
    /// - Returns: The name of the detected chord and a confidence score.
    func identifyChord(from chroma: [Float]) -> (name: String, confidence: Float)? {
        guard chroma.count == 12 else { return nil }
        
        var bestMatchName = "Unknown"
        var highestScore: Float = -1.0
        
        for template in library.templates {
            let score = calculateCosineSimilarity(chroma, template.mask)
            
            if score > highestScore {
                highestScore = score
                bestMatchName = template.name
            }
        }
        
        // Threshold check: If the score is too low, we are likely hearing noise
        return highestScore > 0.5 ? (bestMatchName, highestScore) : nil
    }

    /// Calculates cosine similarity between two vectors.
    private func calculateCosineSimilarity(_ v1: [Float], _ v2: [Float]) -> Float {
        var dotProduct: Float = 0
        var magnitude1: Float = 0
        var magnitude2: Float = 0

        for i in 0..<12 {
            dotProduct += v1[i] * v2[i]
            magnitude1 += v1[i] * v1[i]
            magnitude2 += v2[i] * v2[i]
        }

        let magnitudeProduct = sqrt(magnitude1) * sqrt(magnitude2)
        guard magnitudeProduct > 0 else { return 0 }

        return dotProduct / magnitudeProduct
    }
}
