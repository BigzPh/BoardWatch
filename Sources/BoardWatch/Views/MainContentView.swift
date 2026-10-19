import SwiftUI

struct MainContentView: View {
    @Bindable var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            HeaderView(appState: appState)

            Divider()

            if appState.showingSettings {
                SettingsView(appState: appState)
                    .transition(.move(edge: .trailing))
            } else {
                VStack(spacing: 0) {
                    FilterBarView(appState: appState)
                    CardListView(appState: appState)
                }
                .transition(.move(edge: .leading))
            }
        }
        .frame(width: 360, height: 500)
        .background(Color(NSColor.windowBackgroundColor))
        .task {
            if appState.settings.isConfigured && appState.cards.isEmpty {
                await appState.refresh()
            }
        }
    }
}
