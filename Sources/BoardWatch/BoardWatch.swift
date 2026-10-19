import SwiftUI

@main
struct BoardWatchApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            MainContentView(appState: appState)
        } label: {
            HStack(spacing: 3) {
                Image(systemName: "checklist")
                if let badgeText = appState.menuBarBadgeText {
                    Text(badgeText)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
            }
        }
        .menuBarExtraStyle(.window)
    }
}
