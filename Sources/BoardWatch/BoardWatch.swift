import SwiftUI
import AppKit

extension NSImage {
    static func statusIcon(named symbolName: String, hasNew: Bool) -> NSImage {
        if !hasNew {
            let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .medium)
            let img = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)?.withSymbolConfiguration(config)
            img?.isTemplate = true
            return img ?? NSImage()
        }

        let size = NSSize(width: 20, height: 18)
        let img = NSImage(size: size, flipped: false) { _ in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }

            let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .medium)
                .applying(.init(paletteColors: [NSColor.labelColor]))
            if let base = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)?.withSymbolConfiguration(config) {
                let symbolWidth: CGFloat = symbolName.contains("circle") ? 16 : 17
                let symbolHeight: CGFloat = symbolName.contains("circle") ? 16 : 15
                let originY: CGFloat = (size.height - symbolHeight) / 2
                base.draw(in: NSRect(x: 0, y: originY, width: symbolWidth, height: symbolHeight))
            }

            // Outer bottom-right corner notification dot with clean background cutout
            let dotDiameter: CGFloat = 5.0
            let dotX: CGFloat = 14.5
            let dotY: CGFloat = 0.5
            let dotRect = NSRect(x: dotX, y: dotY, width: dotDiameter, height: dotDiameter)
            let cutoutRect = dotRect.insetBy(dx: -1.0, dy: -1.0)

            ctx.saveGState()
            ctx.setBlendMode(.destinationOut)
            NSColor.black.setFill()
            NSBezierPath(ovalIn: cutoutRect).fill()
            ctx.restoreGState()

            NSColor.systemRed.setFill()
            NSBezierPath(ovalIn: dotRect).fill()

            return true
        }
        img.isTemplate = false
        return img
    }
}

@main
struct BoardWatchApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView(appState: appState)
        } label: {
            HStack(spacing: 3) {
                Image(nsImage: .statusIcon(named: appState.statusIconName, hasNew: appState.hasNewTasks))
                    .id("\(appState.statusIconName)-\(appState.hasNewTasks)")

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

            // Unread / New Indicator Banner
            if appState.hasNewTasks {
                Button(action: {
                    appState.markAllAsRead()
                }) {
                    Text("Mark \(appState.newCardsCount) new as read")
                }
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
                                appState.markCardAsRead(card.id)
                                if let urlString = card.url, let url = URL(string: urlString) {
                                    NSWorkspace.shared.open(url)
                                }
                            }) {
                                Label(
                                    formatCardMenuItem(card, isNew: appState.isCardNew(card.id)),
                                    systemImage: cardIcon(card, isNew: appState.isCardNew(card.id))
                                )
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

    private func cardIcon(_ card: TrelloCard, isNew: Bool) -> String {
        switch card.dueStatus {
        case .overdue:
            return "exclamationmark.circle.fill"
        case .dueToday:
            return "clock.fill"
        default:
            return isNew ? "sparkles" : "pin.fill"
        }
    }

    private func formatCardMenuItem(_ card: TrelloCard, isNew: Bool) -> String {
        var prefix = isNew ? "[New] " : ""
        switch card.dueStatus {
        case .overdue:
            prefix += "[Overdue] "
        case .dueToday:
            prefix += "[Due Today] "
        case .dueTomorrow:
            prefix += "[Tomorrow] "
        default:
            break
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
