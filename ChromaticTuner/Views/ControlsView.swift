import SwiftUI

struct ControlsView: View {
    let isRecording: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: isRecording ? "stop.fill" : "play.fill")
                    .font(.system(size: 20))
                Text(isRecording ? "Stop" : "Start")
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(width: 160, height: 56)
            .background(isRecording ? Color.red : Color.blue)
            .cornerRadius(28)
        }
        .animation(.easeInOut(duration: 0.2), value: isRecording)
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
