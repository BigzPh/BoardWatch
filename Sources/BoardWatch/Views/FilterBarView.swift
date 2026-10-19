import SwiftUI

struct FilterBarView: View {
    @Bindable var appState: AppState

    var body: some View {
        VStack(spacing: 8) {
            // Segmented Picker
            HStack(spacing: 4) {
                tabButton(
                    tab: .tracked,
                    title: "Tracked",
                    count: appState.cards.filter { appState.settings.isTracked(cardId: $0.id) && (!$0.isComplete || !appState.settings.hideCompletedCards) }.count,
                    icon: "pin.fill"
                )

                tabButton(
                    tab: .assigned,
                    title: "Assigned",
                    count: appState.cards.filter { card in
                        guard let user = appState.currentUser else { return false }
                        return (card.idMembers?.contains(user.id) ?? false) && (!card.isComplete || !appState.settings.hideCompletedCards)
                    }.count,
                    icon: "person.fill"
                )

                tabButton(
                    tab: .all,
                    title: "All",
                    count: appState.cards.filter { !$0.isComplete || !appState.settings.hideCompletedCards }.count,
                    icon: "list.bullet"
                )
            }
            .padding(2)
            .background(Color.secondary.opacity(0.12))
            .cornerRadius(8)

            // Search Bar
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                TextField("Search cards...", text: $appState.searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))

                if !appState.searchQuery.isEmpty {
                    Button(action: {
                        appState.searchQuery = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 6)
    }

    @ViewBuilder
    private func tabButton(tab: CardFilterTab, title: String, count: Int, icon: String) -> some View {
        let isSelected = appState.selectedTab == tab

        Button(action: {
            withAnimation(.easeInOut(duration: 0.15)) {
                appState.selectedTab = tab
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))

                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))

                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.15))
                        .foregroundColor(isSelected ? .accentColor : .secondary)
                        .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 5)
            .background(isSelected ? Color(NSColor.controlBackgroundColor) : Color.clear)
            .foregroundColor(isSelected ? .primary : .secondary)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}
