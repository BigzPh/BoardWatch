import SwiftUI
import AppKit

@main
struct BoardWatchApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView(appState: appState)
        } label: {
            HStack(spacing: 3) {
                Image(systemName: appState.statusIconName)
                if let badgeText = appState.menuBarBadgeText {
                    Text(badgeText)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
            }
        }
        .menuBarExtraStyle(.menu)
    }
}

struct MenuBarContentView: View {
    @Bindable var appState: AppState

    var body: some View {
        if !appState.settings.isConfigured {
            Button("Connect Trello Account...") {
                SettingsWindowController.shared.showSettings(appState: appState)
            }
            Divider()
        } else {
            if let user = appState.currentUser {
                Text("Assigned to @\(user.username)")
            }

            let pending = appState.pendingCards

            if pending.isEmpty {
                Text("No pending cards")
            } else {
                Divider()

                ForEach(pending.prefix(15)) { card in
                    Button(action: {
                        if let urlString = card.url, let url = URL(string: urlString) {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        Text(formatCardMenuItem(card))
                    }
                }

                if pending.count > 15 {
                    Text("... and \(pending.count - 15) more")
                }
            }

            Divider()
        }

        // Actions
        Button(action: {
            Task {
                await appState.refresh()
            }
        }) {
            if let updated = appState.lastUpdated {
                Text("Check Now (Updated \(timeAgo(updated)))")
            } else {
                Text("Check Now")
            }
        }

        Button("Settings...") {
            SettingsWindowController.shared.showSettings(appState: appState)
        }

        Divider()

        Button("Quit BoardWatch") {
            NSApplication.shared.terminate(nil)
        }
    }

    private func formatCardMenuItem(_ card: TrelloCard) -> String {
        var prefix = ""
        switch card.dueStatus {
        case .overdue:
            prefix = "[Overdue] "
        case .dueToday:
            prefix = "[Due Today] "
        case .dueTomorrow:
            prefix = "[Tomorrow] "
        default:
            prefix = ""
        }

        var suffix = ""
        if let dueDate = card.dueDate, card.dueStatus != .dueToday && card.dueStatus != .dueTomorrow && card.dueStatus != .overdue {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            suffix = " (\(formatter.string(from: dueDate)))"
        }

        let board = card.board?.name != nil ? " [\(card.board!.name!)]" : ""
        return "\(prefix)\(card.name)\(board)\(suffix)"
    }

    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
