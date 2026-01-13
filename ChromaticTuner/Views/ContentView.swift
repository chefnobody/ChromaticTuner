import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ChordDetectionViewModel()

    private var dominantPitch: DetectedPitch? {
        viewModel.audioData?.pitches.max(by: { $0.magnitude < $1.magnitude })
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 40) {
                StatusIndicatorView(isRecording: viewModel.isRecording)
                    .padding(.top, 40)

                Spacer()

                ChordDisplayView(chord: viewModel.currentChord, dominantPitch: dominantPitch)
 
                if let audioData = viewModel.audioData {
                    SpectrumVisualizationView(audioData: audioData)
                        .frame(height: 200)
                        .padding(.horizontal)
                }

                Spacer()

                ControlsView(
                    isRecording: viewModel.isRecording,
                    onToggle: viewModel.toggleRecording
                )
                .padding(.bottom, 40)
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }
}

#Preview {
    ContentView()
}
