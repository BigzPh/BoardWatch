import Foundation
import SwiftUI

public struct CardBoardGroup: Identifiable {
    public var id: String { "\(workspaceName) • \(boardName)" }
    public let workspaceName: String
    public let boardName: String
    public let cards: [TrelloCard]
}

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

    private var refreshTimer: Timer?

    public init(settings: SettingsManager = SettingsManager(), apiService: TrelloAPIService = TrelloAPIService()) {
        self.settings = settings
        self.apiService = apiService

        NotificationManager.shared.requestAuthorization()
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

    public var pendingCards: [TrelloCard] {
        cards
            .filter { !$0.isComplete }
            .sorted { a, b in
                guard let dateA = a.dueDate else { return false }
                guard let dateB = b.dueDate else { return true }
                return dateA < dateB
            }
    }

    public var groupedPendingCards: [CardBoardGroup] {
        let groups = Dictionary(grouping: pendingCards) { card in
            "\(card.workspaceName ?? "Personal") • \(card.boardName ?? "Board")"
        }

        return groups.map { _, cards in
            let first = cards.first
            return CardBoardGroup(
                workspaceName: first?.workspaceName ?? "Personal",
                boardName: first?.boardName ?? "Board",
                cards: cards
            )
        }.sorted { $0.id < $1.id }
    }

    public var urgentCardsCount: Int {
        pendingCards.filter { $0.dueStatus == .overdue || $0.dueStatus == .dueToday }.count
    }

    public var menuBarBadgeText: String? {
        guard settings.isConfigured else { return "!" }
        let count = pendingCards.count
        return count > 0 ? "\(count)" : nil
    }

    public var statusIconName: String {
        if !settings.isConfigured {
            return "exclamationmark.triangle"
        }
        if urgentCardsCount > 0 {
            return "exclamationmark.circle.fill"
        }
        return "checklist"
    }

    public func refresh() async {
        guard settings.isConfigured else { return }

        isLoading = true
        errorMessage = nil

        do {
            let key = settings.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            let token = settings.token.trimmingCharacters(in: .whitespacesAndNewlines)

            async let userFetch = apiService.verifyCredentials(apiKey: key, token: token)
            async let orgsFetch = apiService.fetchOrganizations(apiKey: key, token: token)
            async let boardsFetch = apiService.fetchBoards(apiKey: key, token: token)
            async let cardsFetch = apiService.fetchAssignedCards(apiKey: key, token: token)

            let (user, orgs, boards, assignedCards) = try await (userFetch, orgsFetch, boardsFetch, cardsFetch)
            self.currentUser = user
            self.boards = boards

            // Build lookup dictionaries
            let orgMap = Dictionary(uniqueKeysWithValues: orgs.map { ($0.id, $0.displayName) })
            var boardMap: [String: TrelloBoard] = [:]
            var listMap: [String: String] = [:]

            for board in boards {
                boardMap[board.id] = board
                if let lists = board.lists {
                    for list in lists {
                        listMap[list.id] = list.name
                    }
                }
            }

            // Enrich all cards with Workspace, Board, and List names
            var allCards = assignedCards
            let assignedCardIDs = Set(assignedCards.map { $0.id })
            let missingTrackedIDs = settings.trackedCardIDs.subtracting(assignedCardIDs)

            for missingId in missingTrackedIDs {
                if let singleCard = try? await apiService.fetchCard(cardId: missingId, apiKey: key, token: token) {
                    allCards.append(singleCard)
                }
            }

            for i in allCards.indices {
                let boardId = allCards[i].idBoard ?? ""
                let listId = allCards[i].idList ?? ""
                let board = boardMap[boardId]

                allCards[i].boardName = board?.name ?? "Board"
                if let orgId = board?.idOrganization, let orgName = orgMap[orgId] {
                    allCards[i].workspaceName = orgName
                } else {
                    allCards[i].workspaceName = "Personal"
                }
                allCards[i].listName = listMap[listId] ?? "List"
            }

            self.cards = allCards
            self.lastUpdated = Date()

            // Trigger native macOS notifications for new or due cards
            NotificationManager.shared.checkAndNotify(cards: allCards)
        } catch {
            self.errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
