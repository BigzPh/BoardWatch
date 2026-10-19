import SwiftUI

struct EmptyStateView: View {
    let tab: CardFilterTab
    let searchQuery: String
    let onOpenSettings: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Spacer()

            if !searchQuery.isEmpty {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 32))
                    .foregroundColor(.secondary)

                Text("No matching cards")
                    .font(.system(size: 13, weight: .semibold))

                Text("Try searching for a different keyword or board.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                switch tab {
                case .tracked:
                    Image(systemName: "pin.slash")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)

                    Text("No Tracked Cards")
                        .font(.system(size: 13, weight: .semibold))

                    Text("Click the 📌 pin icon on any card in the Assigned or All tab to track it here.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)

                case .assigned:
                    Image(systemName: "checkmark.seal")
                        .font(.system(size: 32))
                        .foregroundColor(.green.opacity(0.8))

                    Text("All Caught Up!")
                        .font(.system(size: 13, weight: .semibold))

                    Text("You have no pending cards assigned to you.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                case .all:
                    Image(systemName: "tray")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)

                    Text("No Cards Found")
                        .font(.system(size: 13, weight: .semibold))

                    Text("Check your board selection in Settings or refresh.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(20)
    }
}
