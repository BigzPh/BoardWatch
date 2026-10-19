import Foundation

public struct TrelloOrganization: Identifiable, Codable, Sendable {
    public let id: String
    public let displayName: String
}

public struct TrelloList: Identifiable, Codable, Sendable {
    public let id: String
    public let name: String
}

public struct TrelloBoard: Identifiable, Codable, Sendable, Hashable {
    public let id: String
    public let name: String
    public let idOrganization: String?
    public let closed: Bool?
    public let lists: [TrelloList]?

    public var isOpen: Bool {
        !(closed ?? false)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: TrelloBoard, rhs: TrelloBoard) -> Bool {
        lhs.id == rhs.id
    }
}

public struct TrelloMember: Identifiable, Codable, Sendable {
    public let id: String
    public let username: String
    public let fullName: String?
    public let avatarUrl: String?
}
