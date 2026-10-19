import Foundation
import SwiftUI

@MainActor
@Observable
public final class AppState {
    public let settings: SettingsManager
    private let apiService: TrelloAPIService

    public var cards: [TrelloCard] = []
    public var boards: [TrelloBoard] = []
    public var currentUser: TrelloMember?
    public var isLoading: Bool = false
    public var errorMessage: String?
    public var lastUpdated: Date?

    public var selectedTab: CardFilterTab = .tracked
    public var searchQuery: String = ""
    public var showingSettings: Bool = false

    private var refreshTimer: Timer?

    public init(settings: SettingsManager = SettingsManager(), apiService: TrelloAPIService = TrelloAPIService()) {
        self.settings = settings
        self.apiService = apiService

        if !settings.isConfigured {
            self.showingSettings = true
        }

        setupTimer()
    }

    public func setupTimer() {
        refreshTimer?.invalidate()
        let interval = Double(max(1, settings.refreshIntervalMinutes)) * 60.0
        refreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.refresh()
            }
        }
    }

    public var menuBarBadgeText: String? {
        guard settings.isConfigured else { return "!" }

        switch settings.badgeDisplayMode {
        case .none:
            return nil
        case .trackedOnly:
            let count = cards.filter { settings.isTracked(cardId: $0.id) && !$0.isComplete }.count
            return count > 0 ? "\(count)" : nil
        case .allAssigned:
            let count = cards.filter { !$0.isComplete }.count
            return count > 0 ? "\(count)" : nil
        case .dueSoonOrOverdue:
            let count = cards.filter { card in
                !card.isComplete && (card.dueStatus == .overdue || card.dueStatus == .dueToday)
            }.count
            return count > 0 ? "\(count)" : nil
        }
    }

    public var filteredCards: [TrelloCard] {
        var result = cards

        // 1. Filter by Tab
        switch selectedTab {
        case .tracked:
            result = result.filter { settings.isTracked(cardId: $0.id) }
        case .assigned:
            if let user = currentUser {
                result = result.filter { card in
                    card.idMembers?.contains(user.id) ?? false
                }
            }
        case .all:
            break
        }

        // 2. Filter by Selected Boards (if user specified specific boards)
        if !settings.selectedBoardIDs.isEmpty {
            result = result.filter { card in
                guard let boardId = card.idBoard else { return true }
                return settings.selectedBoardIDs.contains(boardId)
            }
        }

        // 3. Filter by Completed
        if settings.hideCompletedCards {
            result = result.filter { !$0.isComplete }
        }

        // 4. Filter by Search Query
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !query.isEmpty {
            result = result.filter { card in
                card.name.lowercased().contains(query) ||
                (card.board?.name?.lowercased().contains(query) ?? false) ||
                (card.list?.name?.lowercased().contains(query) ?? false) ||
                (card.labels?.contains { $0.name?.lowercased().contains(query) ?? false } ?? false)
            }
        }

        // 5. Sort: Overdue first, then Due Today, Upcoming, then No Due Date
        return result.sorted { a, b in
            if a.isComplete != b.isComplete {
                return !a.isComplete && b.isComplete
            }
            guard let dateA = a.dueDate else { return false }
            guard let dateB = b.dueDate else { return true }
            return dateA < dateB
        }
    }

    public func refresh() async {
        guard settings.isConfigured else {
            showingSettings = true
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let key = settings.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            let token = settings.token.trimmingCharacters(in: .whitespacesAndNewlines)

            async let userFetch = apiService.verifyCredentials(apiKey: key, token: token)
            async let boardsFetch = apiService.fetchBoards(apiKey: key, token: token)
            async let cardsFetch = apiService.fetchAssignedCards(apiKey: key, token: token)

            let (user, boards, assignedCards) = try await (userFetch, boardsFetch, cardsFetch)
            self.currentUser = user
            self.boards = boards

            // Also check if there are pinned cards that weren't in assigned cards
            var allCards = assignedCards
            let assignedCardIDs = Set(assignedCards.map { $0.id })
            let missingTrackedIDs = settings.trackedCardIDs.subtracting(assignedCardIDs)

            for missingId in missingTrackedIDs {
                if let singleCard = try? await apiService.fetchCard(cardId: missingId, apiKey: key, token: token) {
                    allCards.append(singleCard)
                }
            }

            self.cards = allCards
            self.lastUpdated = Date()
        } catch {
            self.errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    public func toggleCardComplete(card: TrelloCard) async {
        guard let index = cards.firstIndex(where: { $0.id == card.id }) else { return }
        let newStatus = !card.isComplete
        cards[index].dueComplete = newStatus

        let key = settings.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let token = settings.token.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            try await apiService.setCardComplete(cardId: card.id, complete: newStatus, apiKey: key, token: token)
        } catch {
            // Revert on failure
            cards[index].dueComplete = !newStatus
            errorMessage = "Failed to update card: \(error.localizedDescription)"
        }
    }

    public func toggleCardTracking(card: TrelloCard) {
        settings.toggleTracking(for: card.id)
    }
}
