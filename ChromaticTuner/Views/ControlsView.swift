import SwiftUI

struct RecordingButtonStyle: ButtonStyle {
    let isRecording: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(isRecording ? Color.red : Color.blue)
            .cornerRadius(28)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

struct ControlsView: View {
    let isRecording: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: isRecording ? "microphone.slash.fill" : "microphone.fill")
                    .font(.system(size: 20))
                Text(isRecording ? "Stop" : "Start")
                    .font(.system(size: 18, weight: .semibold))
            }
        }
        .buttonStyle(
            RecordingButtonStyle(isRecording: isRecording)
        )
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 20) {
            ControlsView(isRecording: false, onToggle: {})
            ControlsView(isRecording: true, onToggle: {})
        }
    }
}
