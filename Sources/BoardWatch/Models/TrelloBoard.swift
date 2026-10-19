import Foundation

public struct TrelloBoard: Identifiable, Codable, Sendable, Hashable {
    public let id: String
    public let name: String
    public let closed: Bool?

    public var isOpen: Bool {
        !(closed ?? false)
    }
}

public struct TrelloMember: Identifiable, Codable, Sendable {
    public let id: String
    public let username: String
    public let fullName: String?
    public let avatarUrl: String?
}
