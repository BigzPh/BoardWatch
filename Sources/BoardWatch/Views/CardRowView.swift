import SwiftUI
import AppKit

struct CardRowView: View {
    let card: TrelloCard
    let isTracked: Bool
    let onToggleComplete: () -> Void
    let onToggleTrack: () -> Void

    @State private var isHovering: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Completion Checkbox
            Button(action: onToggleComplete) {
                Image(systemName: card.isComplete ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundColor(card.isComplete ? .green : .secondary)
            }
            .buttonStyle(.plain)
            .padding(.top, 2)

            // Main Info
            VStack(alignment: .leading, spacing: 4) {
                // Card title
                Text(card.name)
                    .font(.system(size: 13, weight: .medium))
                    .strikethrough(card.isComplete, color: .secondary)
                    .foregroundColor(card.isComplete ? .secondary : .primary)
                    .lineLimit(2)

                // Context: Board & List
                HStack(spacing: 6) {
                    if let boardName = card.board?.name {
                        Text(boardName)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    if let listName = card.list?.name {
                        Text("•")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                        Text(listName)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                // Metadata Badges (Due Date, Checklist, Labels)
                HStack(spacing: 6) {
                    // Due Date Pill
                    if let dueDate = card.dueDate {
                        HStack(spacing: 3) {
                            Image(systemName: "clock")
                                .font(.system(size: 9))
                            Text(formatDueDate(dueDate, status: card.dueStatus))
                                .font(.system(size: 10, weight: .medium))
                        }
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(card.dueStatus.color.opacity(0.15))
                        .foregroundColor(card.dueStatus.color)
                        .cornerRadius(4)
                    }

                    // Checklist Progress
                    if let progress = card.badges?.checklistProgress {
                        HStack(spacing: 3) {
                            Image(systemName: "checklist")
                                .font(.system(size: 9))
                            Text(progress)
                                .font(.system(size: 10))
                        }
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.12))
                        .foregroundColor(.secondary)
                        .cornerRadius(4)
                    }

                    // Color Labels Dots
                    if let labels = card.labels, !labels.isEmpty {
                        HStack(spacing: 3) {
                            ForEach(labels.prefix(3)) { label in
                                Circle()
                                    .fill(label.displayColor)
                                    .frame(width: 6, height: 6)
                            }
                        }
                    }
                }
            }

            Spacer(minLength: 4)

            // Action Buttons
            HStack(spacing: 6) {
                // Pin / Track Button
                Button(action: onToggleTrack) {
                    Image(systemName: isTracked ? "pin.fill" : "pin")
                        .font(.system(size: 12))
                        .foregroundColor(isTracked ? .accentColor : .secondary.opacity(0.7))
                }
                .buttonStyle(.plain)
                .help(isTracked ? "Untrack card" : "Track card in Menu Bar")

                // Open in Browser
                if let urlString = card.url, let url = URL(string: urlString) {
                    Button(action: {
                        NSWorkspace.shared.open(url)
                    }) {
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Open card in Trello")
                }
            }
            .opacity(isHovering || isTracked ? 1.0 : 0.4)
            .padding(.top, 2)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isHovering ? Color.secondary.opacity(0.08) : Color.clear)
        .cornerRadius(6)
        .onHover { hovering in
            isHovering = hovering
        }
    }

    private func formatDueDate(_ date: Date, status: DueStatus) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return "Today \(formatter.string(from: date))"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}
