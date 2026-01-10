import SwiftUI

struct StatusIndicatorView: View {
    let isRecording: Bool
    @State private var isPulsing = false

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isRecording ? Color.red : Color.gray.opacity(0.3))
                .frame(width: 12, height: 12)
                .scaleEffect(isPulsing && isRecording ? 1.2 : 1.0)
                .opacity(isPulsing && isRecording ? 0.6 : 1.0)
                .animation(
                    isRecording ? .easeInOut(duration: 1.0).repeatForever(autoreverses: true) : .default,
                    value: isPulsing
                )

            Text(isRecording ? "Recording" : "Ready")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isRecording ? .white : .gray)
        }
        .onChange(of: isRecording) { oldValue, newValue in
            isPulsing = newValue
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 20) {
            StatusIndicatorView(isRecording: false)
            StatusIndicatorView(isRecording: true)
        }
    }
}
