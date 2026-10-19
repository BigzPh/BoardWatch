import Foundation
import SwiftUI
import ServiceManagement

public enum BadgeDisplayMode: String, CaseIterable, Identifiable, Codable, Sendable {
    case trackedOnly = "Tracked Cards Count"
    case allAssigned = "All Assigned Incomplete"
    case dueSoonOrOverdue = "Due Soon / Overdue"
    case none = "Icon Only (No Count)"

    public var id: String { rawValue }
}

public enum CardFilterTab: String, CaseIterable, Identifiable, Sendable {
    case tracked = "Tracked"
    case assigned = "Assigned"
    case all = "All"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .tracked: return "pin.fill"
        case .assigned: return "person.fill"
        case .all: return "list.bullet"
        }
    }
}

@Observable
public final class SettingsManager: @unchecked Sendable {
    private let defaults = UserDefaults.standard

    // Keys
    private let kApiKey = "trello_api_key"
    private let kToken = "trello_token"
    private let kTrackedCardIDs = "trello_tracked_card_ids"
    private let kSelectedBoardIDs = "trello_selected_board_ids"
    private let kRefreshInterval = "trello_refresh_interval"
    private let kHideCompleted = "trello_hide_completed"
    private let kBadgeMode = "trello_badge_mode"
    private let kWorkspaceFilter = "trello_workspace_filter"

    public var selectedWorkspaceFilter: String? {
        didSet {
            if let filter = selectedWorkspaceFilter {
                defaults.set(filter, forKey: kWorkspaceFilter)
            } else {
                defaults.removeObject(forKey: kWorkspaceFilter)
            }
        }
    }

    public var apiKey: String {
        didSet { defaults.set(apiKey, forKey: kApiKey) }
    }

    public var token: String {
        didSet { defaults.set(token, forKey: kToken) }
    }

    public var trackedCardIDs: Set<String> {
        didSet {
            defaults.set(Array(trackedCardIDs), forKey: kTrackedCardIDs)
        }
    }

    public var selectedBoardIDs: Set<String> {
        didSet {
            defaults.set(Array(selectedBoardIDs), forKey: kSelectedBoardIDs)
        }
    }

    public var refreshIntervalMinutes: Int {
        didSet { defaults.set(refreshIntervalMinutes, forKey: kRefreshInterval) }
    }

    public var hideCompletedCards: Bool {
        didSet { defaults.set(hideCompletedCards, forKey: kHideCompleted) }
    }

    public var badgeDisplayMode: BadgeDisplayMode {
        didSet { defaults.set(badgeDisplayMode.rawValue, forKey: kBadgeMode) }
    }

    public init() {
        self.apiKey = defaults.string(forKey: kApiKey) ?? ""
        self.token = defaults.string(forKey: kToken) ?? ""

        let savedTracked = defaults.stringArray(forKey: kTrackedCardIDs) ?? []
        self.trackedCardIDs = Set(savedTracked)

        let savedBoards = defaults.stringArray(forKey: kSelectedBoardIDs) ?? []
        self.selectedBoardIDs = Set(savedBoards)

        let interval = defaults.integer(forKey: kRefreshInterval)
        self.refreshIntervalMinutes = interval > 0 ? interval : 5

        self.hideCompletedCards = defaults.object(forKey: kHideCompleted) != nil ? defaults.bool(forKey: kHideCompleted) : true

        if let badgeRaw = defaults.string(forKey: kBadgeMode), let mode = BadgeDisplayMode(rawValue: badgeRaw) {
            self.badgeDisplayMode = mode
        } else {
            self.badgeDisplayMode = .trackedOnly
        }

        self.selectedWorkspaceFilter = defaults.string(forKey: kWorkspaceFilter)
    }

    public var isConfigured: Bool {
        !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public func toggleTracking(for cardId: String) {
        if trackedCardIDs.contains(cardId) {
            trackedCardIDs.remove(cardId)
        } else {
            trackedCardIDs.insert(cardId)
        }
    }

    public func isTracked(cardId: String) -> Bool {
        trackedCardIDs.contains(cardId)
    }

    public func toggleBoardSelection(for boardId: String) {
        if selectedBoardIDs.contains(boardId) {
            selectedBoardIDs.remove(boardId)
        } else {
            selectedBoardIDs.insert(boardId)
        }
    }
}
