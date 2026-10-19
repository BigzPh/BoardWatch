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

            // Workspace Filter Dropdown
            Menu("Workspace: \(appState.currentWorkspaceFilterName)") {
                Button(action: {
                    appState.settings.selectedWorkspaceFilter = nil
                }) {
                    let isSelected = appState.settings.selectedWorkspaceFilter == nil
                    let count = appState.cards.filter { !$0.isComplete }.count
                    Text("\(isSelected ? "✓ " : "  ")All Workspaces (\(count))")
                }

                if !appState.availableWorkspaces.isEmpty {
                    Divider()

                    ForEach(appState.availableWorkspaces, id: \.self) { ws in
                        let isSelected = appState.settings.selectedWorkspaceFilter == ws
                        let count = appState.cards.filter { !$0.isComplete && $0.workspaceName == ws }.count
                        Button(action: {
                            appState.settings.selectedWorkspaceFilter = ws
                        }) {
                            Text("\(isSelected ? "✓ " : "  ")\(ws) (\(count))")
                        }
                    }
                }
            }

            let groups = appState.groupedPendingCards

            if groups.isEmpty {
                Divider()
                Text("No pending cards in \(appState.currentWorkspaceFilterName)")
            } else {
                Divider()

                ForEach(groups) { group in
                    Section("\(group.workspaceName) › \(group.boardName)") {
                        let limit = 10
                        ForEach(group.cards.prefix(limit)) { card in
                            Button(action: {
                                if let urlString = card.url, let url = URL(string: urlString) {
                                    NSWorkspace.shared.open(url)
                                }
                            }) {
                                Text(formatCardMenuItem(card))
                            }
                        }

                        if group.cards.count > limit {
                            let remaining = group.cards.count - limit
                            Button(action: {
                                let boardUrl = "https://trello.com/b/\(group.boardId ?? "")"
                                if let url = URL(string: boardUrl) {
                                    NSWorkspace.shared.open(url)
                                }
                            }) {
                                Text("View \(remaining) more in Trello...")
                            }
                        }
                    }
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
            suffix = " (Due \(formatter.string(from: dueDate)))"
        }

        let listTag = card.listName != nil ? " • \(card.listName!)" : ""
        return "\(prefix)\(card.name)\(listTag)\(suffix)"
    }

    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
