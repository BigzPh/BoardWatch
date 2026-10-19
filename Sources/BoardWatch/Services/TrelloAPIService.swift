import Foundation

public enum TrelloAPIError: LocalizedError {
    case invalidURL
    case missingCredentials
    case invalidResponse(Int)
    case networkError(Error)
    case decodingError(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Trello API URL."
        case .missingCredentials:
            return "Trello API Key or Token is missing. Please configure them in Settings."
        case .invalidResponse(let statusCode):
            if statusCode == 401 {
                return "Unauthorized (401). Please check your API Key and Token."
            }
            return "Trello returned error HTTP \(statusCode)."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to parse Trello data: \(error.localizedDescription)"
        }
    }
}

public actor TrelloAPIService {
    private let baseURL = "https://api.trello.com/1"
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func verifyCredentials(apiKey: String, token: String) async throws -> TrelloMember {
        let endpoint = "\(baseURL)/members/me"
        let queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "token", value: token),
            URLQueryItem(name: "fields", value: "id,username,fullName,avatarUrl")
        ]

        guard var components = URLComponents(string: endpoint) else {
            throw TrelloAPIError.invalidURL
        }
        components.queryItems = queryItems

        guard let url = components.url else {
            throw TrelloAPIError.invalidURL
        }

        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TrelloAPIError.invalidResponse(0)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw TrelloAPIError.invalidResponse(httpResponse.statusCode)
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(TrelloMember.self, from: data)
        } catch {
            throw TrelloAPIError.decodingError(error)
        }
    }

    public func fetchBoards(apiKey: String, token: String) async throws -> [TrelloBoard] {
        let endpoint = "\(baseURL)/members/me/boards"
        let queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "token", value: token),
            URLQueryItem(name: "filter", value: "open"),
            URLQueryItem(name: "fields", value: "id,name,closed")
        ]

        guard var components = URLComponents(string: endpoint) else {
            throw TrelloAPIError.invalidURL
        }
        components.queryItems = queryItems

        guard let url = components.url else {
            throw TrelloAPIError.invalidURL
        }

        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TrelloAPIError.invalidResponse(0)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw TrelloAPIError.invalidResponse(httpResponse.statusCode)
        }

        do {
            let decoder = JSONDecoder()
            let boards = try decoder.decode([TrelloBoard].self, from: data)
            return boards.filter { $0.isOpen }
        } catch {
            throw TrelloAPIError.decodingError(error)
        }
    }

    public func fetchAssignedCards(apiKey: String, token: String) async throws -> [TrelloCard] {
        let endpoint = "\(baseURL)/members/me/cards"
        let queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "token", value: token),
            URLQueryItem(name: "filter", value: "all"),
            URLQueryItem(name: "fields", value: "id,name,desc,due,dueComplete,url,idBoard,idList,labels,badges,idMembers"),
            URLQueryItem(name: "board", value: "true"),
            URLQueryItem(name: "board_fields", value: "id,name"),
            URLQueryItem(name: "list", value: "true"),
            URLQueryItem(name: "list_fields", value: "id,name")
        ]

        guard var components = URLComponents(string: endpoint) else {
            throw TrelloAPIError.invalidURL
        }
        components.queryItems = queryItems

        guard let url = components.url else {
            throw TrelloAPIError.invalidURL
        }

        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TrelloAPIError.invalidResponse(0)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw TrelloAPIError.invalidResponse(httpResponse.statusCode)
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode([TrelloCard].self, from: data)
        } catch {
            throw TrelloAPIError.decodingError(error)
        }
    }

    public func fetchCard(cardId: String, apiKey: String, token: String) async throws -> TrelloCard {
        let endpoint = "\(baseURL)/cards/\(cardId)"
        let queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "token", value: token),
            URLQueryItem(name: "fields", value: "id,name,desc,due,dueComplete,url,idBoard,idList,labels,badges,idMembers"),
            URLQueryItem(name: "board", value: "true"),
            URLQueryItem(name: "board_fields", value: "id,name"),
            URLQueryItem(name: "list", value: "true"),
            URLQueryItem(name: "list_fields", value: "id,name")
        ]

        guard var components = URLComponents(string: endpoint) else {
            throw TrelloAPIError.invalidURL
        }
        components.queryItems = queryItems

        guard let url = components.url else {
            throw TrelloAPIError.invalidURL
        }

        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw TrelloAPIError.invalidResponse(0)
        }

        let decoder = JSONDecoder()
        return try decoder.decode(TrelloCard.self, from: data)
    }

    public func setCardComplete(cardId: String, complete: Bool, apiKey: String, token: String) async throws {
        let endpoint = "\(baseURL)/cards/\(cardId)"
        let queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "token", value: token),
            URLQueryItem(name: "dueComplete", value: complete ? "true" : "false")
        ]

        guard var components = URLComponents(string: endpoint) else {
            throw TrelloAPIError.invalidURL
        }
        components.queryItems = queryItems

        guard let url = components.url else {
            throw TrelloAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"

        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw TrelloAPIError.invalidResponse((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
    }
}
