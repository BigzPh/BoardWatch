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
            async let boardsFetch = apiService.fetchBoards(apiKey: key, token: token)
            async let cardsFetch = apiService.fetchAssignedCards(apiKey: key, token: token)

            let (user, boards, assignedCards) = try await (userFetch, boardsFetch, cardsFetch)
            self.currentUser = user
            self.boards = boards

            // Check if there are pinned cards not in assigned cards
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

            // Trigger native macOS notifications for new or due cards
            NotificationManager.shared.checkAndNotify(cards: allCards)
        } catch {
            self.errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
