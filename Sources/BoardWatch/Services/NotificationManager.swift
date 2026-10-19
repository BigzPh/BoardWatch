import Foundation
import UserNotifications

public final class NotificationManager: @unchecked Sendable {
    public static let shared = NotificationManager()

    private let defaults = UserDefaults.standard
    private let kSeenCardIDs = "boardwatch_seen_card_ids"
    private let kLastDueAlertDate = "boardwatch_last_due_alert_date"

    private var hasInitializedSeenCards = false

    private init() {}

    public func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error)")
            }
        }
    }

    public func checkAndNotify(cards: [TrelloCard]) {
        let incompleteCards = cards.filter { !$0.isComplete }

        var seenIDs = Set(defaults.stringArray(forKey: kSeenCardIDs) ?? [])

        // If this is the very first time running, seed existing cards so we don't spam notifications
        if !hasInitializedSeenCards {
            hasInitializedSeenCards = true
            if seenIDs.isEmpty {
                defaults.set(Array(incompleteCards.map { $0.id }), forKey: kSeenCardIDs)
                return
            }
        }

        // 1. Notify for newly assigned cards
        for card in incompleteCards {
            if !seenIDs.contains(card.id) {
                seenIDs.insert(card.id)
                sendNotification(
                    id: "new-\(card.id)",
                    title: "New Task Assigned",
                    subtitle: card.board?.name ?? "Trello",
                    body: card.name
                )
            }
        }
        defaults.set(Array(seenIDs), forKey: kSeenCardIDs)

        // 2. Notify for tasks due today or overdue
        let calendar = Calendar.current
        let todayString = ISO8601DateFormatter().string(from: calendar.startOfDay(for: Date()))
        let lastAlertDate = defaults.string(forKey: kLastDueAlertDate)

        // Alert at most once per day for due tasks
        if lastAlertDate != todayString {
            let dueCards = incompleteCards.filter { $0.dueStatus == .dueToday || $0.dueStatus == .overdue }
            if !dueCards.isEmpty {
                defaults.set(todayString, forKey: kLastDueAlertDate)
                let count = dueCards.count
                let names = dueCards.prefix(2).map { $0.name }.joined(separator: ", ")
                let body = count > 2 ? "\(names), and \(count - 2) more" : names

                sendNotification(
                    id: "due-summary-\(todayString)",
                    title: "\(count) Task\(count == 1 ? "" : "s") Due",
                    subtitle: "Overdue or due today",
                    body: body
                )
            }
        }
    }

    private func sendNotification(id: String, title: String, subtitle: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.subtitle = subtitle
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(identifier: id, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
