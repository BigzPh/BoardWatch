import SwiftUI
import AppKit

struct HeaderView: View {
    @Bindable var appState: AppState

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checklist")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.accentColor)

            VStack(alignment: .leading, spacing: 1) {
                Text("BoardWatch")
                    .font(.system(size: 13, weight: .bold))

                if let user = appState.currentUser {
                    Text("@\(user.username)")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Refresh Button
            Button(action: {
                Task {
                    await appState.refresh()
                }
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12))
                    .rotationEffect(.degrees(appState.isLoading ? 360 : 0))
                    .animation(appState.isLoading ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: appState.isLoading)
            }
            .buttonStyle(.plain)
            .disabled(appState.isLoading)
            .help("Refresh Cards")

            // Settings Gear Button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    appState.showingSettings.toggle()
                }
            }) {
                Image(systemName: appState.showingSettings ? "checklist" : "gearshape")
                    .font(.system(size: 12))
                    .foregroundColor(appState.showingSettings ? .accentColor : .secondary)
            }
            .buttonStyle(.plain)
            .help(appState.showingSettings ? "Back to Cards" : "Settings & Filters")

            // Menu Options (Quit)
            Menu {
                if let url = URL(string: "https://trello.com") {
                    Button("Open Trello in Browser") {
                        NSWorkspace.shared.open(url)
                    }
                }
                Divider()
                Button("Quit BoardWatch") {
                    NSApplication.shared.terminate(nil)
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(NSColor.windowBackgroundColor))
    }
}
