import SwiftUI

struct TimeUpView: View {
    var body: some View {
        ZStack {
            // Soft background
            Color(NSColor.windowBackgroundColor)
                .ignoresSafeArea()
            VStack(spacing: 32) {
                // Large icon
                Image(systemName: "hourglass")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
                    .foregroundColor(Color.secondary)
                    .padding(.top, 16)
                VStack(spacing: 10) {
                    Text("Time's up!")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    Text("Your session has ended. Take a break or start a new session.")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                }
                Button(action: {
                    NSApp.keyWindow?.close()
                }) {
                    Text("OK")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.accentColor.opacity(0.12))
                        .foregroundColor(.accentColor)
                        .cornerRadius(8)
                        .padding(.horizontal, 60)
                }
                .keyboardShortcut(.defaultAction)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 36)
        }
        .frame(minWidth: 400, minHeight: 340)
    }
}

#Preview {
    TimeUpView()
}

