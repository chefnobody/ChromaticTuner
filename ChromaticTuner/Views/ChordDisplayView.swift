import SwiftUI

struct ChordDisplayView: View {
    let chord: DetectedChord?
    let dominantPitch: DetectedPitch?

    // Tuning state persistence - holds states to reduce flicker
    @State private var displayedTuningState: TuningState = .neutral
    @State private var lastInTuneTime: Date?

    private enum TuningState: Equatable {
        case flat, inTune, sharp, neutral
    }

    // How long to hold the "in tune" green state after detected
    private let inTuneHoldDuration: TimeInterval = 1.0

    private var currentTuningState: TuningState {
        guard dominantPitch != nil else { return .neutral }
        if dominantPitch?.isInTune == true { return .inTune }
        if dominantPitch?.isFlat == true { return .flat }
        if dominantPitch?.isSharp == true { return .sharp }
        return .neutral
    }

    private var effectiveTuningState: TuningState {
        let current = currentTuningState

        // If currently in tune, always show in tune
        if current == .inTune {
            return .inTune
        }

        // If we were recently in tune, hold the green state
        if let lastInTune = lastInTuneTime,
           Date().timeIntervalSince(lastInTune) < inTuneHoldDuration {
            return .inTune
        }

        return current
    }

    var body: some View {
        VStack(spacing: 8) {
            if let chord = chord {
                // Chord root with flat/sharp indicators
                HStack(spacing: 20) {
                    // Flat indicator (left) - only show when not in tune
                    Text("♭")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundColor(effectiveTuningState == .flat ? .red : .gray.opacity(0.2))
                        .frame(width: 70)

                    // Chord root
                    Text(chord.root.rawValue)
                        .font(.system(size: 120, weight: .bold, design: .rounded))
                        .foregroundColor(effectiveTuningState == .inTune ? .green : .white)
                        .animation(.interactiveSpring, value: effectiveTuningState)

                    // Sharp indicator (right) - only show when not in tune
                    Text("♯")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundColor(effectiveTuningState == .sharp ? .orange : .gray.opacity(0.2))
                        .frame(width: 70)
                }
            } else {
                HStack(spacing: 20) {
                    Text("♭")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundColor(.gray.opacity(0.2))
                        .frame(width: 70)

                    Text("—")
                        .font(.system(size: 120, weight: .bold, design: .rounded))
                        .foregroundColor(.gray.opacity(0.3))

                    Text("♯")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundColor(.gray.opacity(0.2))
                        .frame(width: 70)
                }
            }
        }
        .frame(height: 260)
        .overlay {
            // Particle effect layer - larger frame allows particles to spread beyond chord view
            if effectiveTuningState == .inTune && chord != nil {
                ParticleBurstView()
                    .frame(width: 600, height: 600)
                    .allowsHitTesting(false)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: chord?.displayName)
        .animation(.easeInOut(duration: 0.2), value: effectiveTuningState)
        .onChange(of: currentTuningState) { _, newState in
            if newState == .inTune {
                lastInTuneTime = Date()
            }
        }
    }
}

// MARK: - Sparkler Particle Effect

private struct ParticleBurstView: View {
    @State private var particles: [SparkleParticle] = []
    @State private var emissionPoints: [CGPoint] = []
    @State private var timer: Timer?
    @State private var canvasSize: CGSize = .zero

    private let emissionRate: TimeInterval = 0.012  // New particle every 12ms
    private let maxParticles = 250
    private let numberOfEmissionPoints = 16

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                // Store canvas size for emission point generation
                if canvasSize != size {
                    DispatchQueue.main.async {
                        canvasSize = size
                        emissionPoints = generateEmissionPoints(in: size)
                    }
                }

                let now = timeline.date.timeIntervalSinceReferenceDate

                for particle in particles {
                    let age = now - particle.birthTime
                    guard age < particle.lifetime else { continue }

                    let progress = age / particle.lifetime
                    let distance = particle.speed * age

                    // Calculate position traveling outward from emission point (centered in canvas)
                    let centerX = size.width / 2
                    let centerY = size.height / 2
                    let offsetX = particle.origin.x - 300  // Adjust from 600x600 reference to center
                    let offsetY = particle.origin.y - 300
                    let x = centerX + offsetX + cos(particle.angle) * distance
                    let y = centerY + offsetY + sin(particle.angle) * distance

                    // Smooth ease-out fade: starts slow, accelerates toward end
                    let easedProgress = progress * progress
                    let opacity = 1.0 - easedProgress

                    // Shrink smoothly
                    let scale = max(0.1, 1.0 - easedProgress * 0.9)

                    let particleSize = particle.size * scale
                    let rect = CGRect(
                        x: x - particleSize / 2,
                        y: y - particleSize / 2,
                        width: particleSize,
                        height: particleSize
                    )

                    // Draw glowing sparkle with outer glow
                    context.opacity = opacity
                    context.fill(
                        Circle().path(in: rect.insetBy(dx: -8, dy: -8)),
                        with: .color(particle.color.opacity(0.1))
                    )
                    context.fill(
                        Circle().path(in: rect.insetBy(dx: -4, dy: -4)),
                        with: .color(particle.color.opacity(0.25))
                    )
                    context.fill(
                        Circle().path(in: rect),
                        with: .color(particle.color)
                    )
                }
            }
        }
        .onAppear {
            startEmitting()
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }

    private func generateEmissionPoints(in size: CGSize) -> [CGPoint] {
        // Generate random points along the approximate edge of a letter
        // The letter is roughly centered in a 500x500 canvas
        let centerX = size.width / 2
        let centerY = size.height / 2
        let letterWidth: CGFloat = 80   // Approximate letter width
        let letterHeight: CGFloat = 110  // Approximate letter height

        var points: [CGPoint] = []
        for _ in 0..<numberOfEmissionPoints {
            // Pick a random edge (top, bottom, left, right) and position along it
            let edge = Int.random(in: 0..<4)
            let point: CGPoint
            switch edge {
            case 0: // Top edge
                point = CGPoint(
                    x: centerX + CGFloat.random(in: -letterWidth/2...letterWidth/2),
                    y: centerY - letterHeight/2 + CGFloat.random(in: -8...8)
                )
            case 1: // Bottom edge
                point = CGPoint(
                    x: centerX + CGFloat.random(in: -letterWidth/2...letterWidth/2),
                    y: centerY + letterHeight/2 + CGFloat.random(in: -8...8)
                )
            case 2: // Left edge
                point = CGPoint(
                    x: centerX - letterWidth/2 + CGFloat.random(in: -8...8),
                    y: centerY + CGFloat.random(in: -letterHeight/2...letterHeight/2)
                )
            default: // Right edge
                point = CGPoint(
                    x: centerX + letterWidth/2 + CGFloat.random(in: -8...8),
                    y: centerY + CGFloat.random(in: -letterHeight/2...letterHeight/2)
                )
            }
            points.append(point)
        }
        return points
    }

    private func startEmitting() {
        // Initialize emission points centered in 500x500 canvas
        emissionPoints = generateEmissionPoints(in: CGSize(width: 600, height: 600))

        // Emit initial burst from each point
        for point in emissionPoints {
            for _ in 0..<10 {
                particles.append(SparkleParticle(origin: point))
            }
        }

        // Continuous emission
        timer = Timer.scheduledTimer(withTimeInterval: emissionRate, repeats: true) { _ in
            // Remove dead particles
            let now = Date().timeIntervalSinceReferenceDate
            particles.removeAll { now - $0.birthTime > $0.lifetime }

            // Occasionally shuffle emission points for variety
            if Int.random(in: 0..<15) == 0 {
                emissionPoints = generateEmissionPoints(in: CGSize(width: 600, height: 600))
            }

            // Add multiple new particles from random emission points
            for _ in 0..<4 {
                if particles.count < maxParticles, let point = emissionPoints.randomElement() {
                    particles.append(SparkleParticle(origin: point))
                }
            }
        }
    }
}

private struct SparkleParticle: Identifiable {
    let id = UUID()
    let birthTime: TimeInterval
    let origin: CGPoint
    let angle: Double
    let speed: Double
    let size: Double
    let lifetime: Double
    let color: Color

    init(origin: CGPoint) {
        self.birthTime = Date().timeIntervalSinceReferenceDate
        self.origin = origin
        self.angle = Double.random(in: 0...(2 * .pi))
        self.speed = Double.random(in: 120...320)  // pixels per second - faster for more spread
        self.size = Double.random(in: 3...8)  // sparkles
        self.lifetime = Double.random(in: 1.0...2.0)  // longer-lived for particles to travel further

        // Random green or yellow color with some white sparkles
        let colors: [Color] = [
            .green,
            .green.opacity(0.9),
            .yellow,
            Color(red: 0.7, green: 1.0, blue: 0.3),  // lime
            Color(red: 1.0, green: 0.9, blue: 0.2),  // gold
            .white,
            Color(red: 0.8, green: 1.0, blue: 0.8),  // pale green
        ]
        self.color = colors.randomElement()!
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 40) {
            // Flat example
            ChordDisplayView(
                chord: DetectedChord(root: .C, quality: .major, confidence: 0.85, notes: [.C, .E, .G]),
                dominantPitch: DetectedPitch(frequency: 250, magnitude: 0.8, note: .C)  // Flat
            )
            // In tune example
            ChordDisplayView(
                chord: DetectedChord(root: .A, quality: .minor, confidence: 0.90, notes: [.A, .C, .E]),
                dominantPitch: DetectedPitch(frequency: 440, magnitude: 0.8, note: .A)  // In tune
            )
            // Sharp example
            ChordDisplayView(
                chord: DetectedChord(root: .G, quality: .major, confidence: 0.75, notes: [.G, .B, .D]),
                dominantPitch: DetectedPitch(frequency: 400, magnitude: 0.8, note: .G)  // Sharp
            )
        }
    }
}

#Preview("Particle Burst") {
    ZStack {
        Color.black.ignoresSafeArea()
        ZStack {
            ParticleBurstView()
                .frame(width: 600, height: 600)
            Text("A")
                .font(.system(size: 120, weight: .bold, design: .rounded))
                .foregroundColor(.green)
        }
    }
}
