import SwiftUI

struct CardListView: View {
    @Bindable var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            // Error Banner
            if let error = appState.errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.yellow)

                    Text(error)
                        .font(.system(size: 11))
                        .lineLimit(2)

                    Spacer()

                    Button("Dismiss") {
                        appState.errorMessage = nil
                    }
                    .font(.system(size: 10, weight: .semibold))
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.yellow.opacity(0.15))
            }

            // Cards Content
            let cards = appState.filteredCards
            if cards.isEmpty && !appState.isLoading {
                EmptyStateView(
                    tab: appState.selectedTab,
                    searchQuery: appState.searchQuery,
                    onOpenSettings: {
                        appState.showingSettings = true
                    }
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(cards) { card in
                            CardRowView(
                                card: card,
                                isTracked: appState.settings.isTracked(cardId: card.id),
                                onToggleComplete: {
                                    Task {
                                        await appState.toggleCardComplete(card: card)
                                    }
                                },
                                onToggleTrack: {
                                    appState.toggleCardTracking(card: card)
                                }
                            )

                            if card.id != cards.last?.id {
                                Divider()
                                    .padding(.leading, 38)
                                    .opacity(0.4)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Divider()

            // Bottom Status Bar
            HStack {
                if let lastUpdated = appState.lastUpdated {
                    Text("Updated \(timeAgo(lastUpdated))")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                } else {
                    Text("Ready")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("\(appState.filteredCards.count) cards")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor))
        }
    }

    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
