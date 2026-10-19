import Foundation
import SwiftUI

public struct TrelloCard: Identifiable, Codable, Sendable {
    public let id: String
    public let name: String
    public let desc: String?
    public let url: String?
    public let due: String?
    public var dueComplete: Bool?
    public let idBoard: String?
    public let idList: String?
    public let board: NamedEntity?
    public let list: NamedEntity?
    public let labels: [TrelloLabel]?
    public let badges: TrelloBadges?
    public let idMembers: [String]?

    // Enriched metadata
    public var workspaceName: String?
    public var boardName: String?
    public var listName: String?

    public struct NamedEntity: Codable, Sendable {
        public let id: String?
        public let name: String?
    }

    public var isComplete: Bool {
        dueComplete ?? false
    }

    public var dueDate: Date? {
        guard let due = due else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: due) {
            return date
        }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: due)
    }

    public var dueStatus: DueStatus {
        guard let dueDate = dueDate else { return .none }
        if isComplete { return .completed }

        let now = Date()
        let calendar = Calendar.current

        if dueDate < now {
            return .overdue
        } else if calendar.isDateInToday(dueDate) {
            return .dueToday
        } else if calendar.isDateInTomorrow(dueDate) {
            return .dueTomorrow
        } else {
            return .upcoming
        }
    }
}

public enum DueStatus: Sendable {
    case overdue
    case dueToday
    case dueTomorrow
    case upcoming
    case completed
    case none

    public var displayText: String {
        switch self {
        case .overdue: return "Overdue"
        case .dueToday: return "Due Today"
        case .dueTomorrow: return "Tomorrow"
        case .upcoming: return "Upcoming"
        case .completed: return "Done"
        case .none: return ""
        }
    }

    public var color: Color {
        switch self {
        case .overdue: return .red
        case .dueToday: return .orange
        case .dueTomorrow: return .yellow
        case .upcoming: return .secondary
        case .completed: return .green
        case .none: return .clear
        }
    }
}

public struct TrelloLabel: Identifiable, Codable, Sendable {
    public let id: String
    public let name: String?
    public let color: String?

    public var displayColor: Color {
        switch color?.lowercased() {
        case "green": return .green
        case "yellow": return .yellow
        case "orange": return .orange
        case "red": return .red
        case "purple": return .purple
        case "blue": return .blue
        case "sky": return .cyan
        case "lime": return .mint
        case "pink": return .pink
        case "black": return .primary
        default: return .gray
        }
    }
}

public struct TrelloBadges: Codable, Sendable {
    public let checkItems: Int?
    public let checkItemsChecked: Int?
    public let comments: Int?
    public let attachments: Int?

    public var hasChecklist: Bool {
        (checkItems ?? 0) > 0
    }

    public var checklistProgress: String? {
        guard let total = checkItems, total > 0 else { return nil }
        let completed = checkItemsChecked ?? 0
        return "\(completed)/\(total)"
    }
}
