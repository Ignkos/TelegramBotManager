import Foundation

let url = "http://Your_IP:8000"

struct authenticate: Codable{
    let email: String
    let password: String
    var username: String? = nil
}

struct authResponse: Codable{
    let token: String
}

struct Bot: Codable, Identifiable {
    let id: String
    let bot_name: String
    let telegram_token: String
    let user_id: String
}

struct Block: Codable, Identifiable {
    let id: String
    let type: String
    let config: String
    let bot_id: String
}

enum error: Error {
    case emailTaken
    case invalidCredentials
    case serverError(Int)
}

struct Booking: Codable, Identifiable {
    let id: String
    let bot_id: String
    let type: String
    let name: String
    let selection: String
    let created_at: String
}

class apiRequest{
    static let api = apiRequest()
    
    func saveToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: "token")
    }

    func getToken() -> String? {
        return UserDefaults.standard.string(forKey: "token")
    }

    func logout() {
        UserDefaults.standard.removeObject(forKey: "token")
    }
    
    private func handleError(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        if http.statusCode == 409 { throw error.emailTaken }
        if http.statusCode == 401 { throw error.invalidCredentials }
        if http.statusCode >= 400 { throw error.serverError(http.statusCode) }
    }
    
    private func post<Body: Codable, responseJson: Codable>(endpoint: String, body: Body) async throws -> responseJson {
        var request = URLRequest(url: URL(string: url + endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        if let token = getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        print("sending to: \(url + endpoint)")
        let (data, response) = try await URLSession.shared.data(for: request)
        try handleError(response: response, data: data)
        return try JSONDecoder().decode(responseJson.self, from: data)
    }

    func register(email: String, password: String, username: String) async throws -> authResponse {
        return try await post(endpoint: "/auth/register", body: authenticate(email: email, password: password, username: username))
    }

    func login(email: String, password: String) async throws -> authResponse {
        return try await post(endpoint: "/auth/login", body: authenticate(email: email, password: password))
    }
    func getBots() async throws -> [Bot] {
        return try await get(endpoint: "/bots")
    }

    func createBot(botName: String, telegramToken: String) async throws -> Bot {
        return try await postQuery(endpoint: "/bots?bot_name=\(botName)&telegram_token=\(telegramToken)")
    }

    func deleteBot(botId: String) async throws {
        try await delete(endpoint: "/bots/\(botId)")
    }

    private func get<Response: Codable>(endpoint: String) async throws -> Response {
        var request = URLRequest(url: URL(string: url + endpoint)!, timeoutInterval: 10)
        request.httpMethod = "GET"
        if let token = getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        try handleError(response: response, data: data)
        return try JSONDecoder().decode(Response.self, from: data)
    }

    private func postQuery<Response: Codable>(endpoint: String) async throws -> Response {
        var request = URLRequest(url: URL(string: url + endpoint)!, timeoutInterval: 10)
        request.httpMethod = "POST"
        if let token = getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        try handleError(response: response, data: data)
        return try JSONDecoder().decode(Response.self, from: data)
    }

    private func delete(endpoint: String) async throws {
        var request = URLRequest(url: URL(string: url + endpoint)!, timeoutInterval: 10)
        request.httpMethod = "DELETE"
        if let token = getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        try handleError(response: response, data: data)
    }
    
    func getBlocks(botId: String) async throws -> [Block] {
        return try await get(endpoint: "/bots/\(botId)/blocks")
    }

    func addBlock(botId: String, blockType: String) async throws -> Block {
        return try await postQuery(endpoint: "/bots/\(botId)/blocks?block_type=\(blockType)&config=%7B%7D")
    }

    func deleteBlock(blockId: String) async throws {
        try await delete(endpoint: "/blocks/\(blockId)")
    }
    
    private func put<Response: Codable>(endpoint: String) async throws -> Response {
        var request = URLRequest(url: URL(string: url + endpoint)!, timeoutInterval: 10)
        request.httpMethod = "PUT"
        if let token = getToken() {
            request.setValue("Token \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        try handleError(response: response, data: data)
        return try JSONDecoder().decode(Response.self, from: data)
    }

    func updateBlock(blockId: String, config: String) async throws -> Block {
        let encodedConfig = config.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? config
        return try await put(endpoint: "/blocks/\(blockId)?config=\(encodedConfig)")
    }
    
    func startBot(botId: String) async throws -> [String: String] {
        return try await postQuery(endpoint: "/bots/\(botId)/start")
    }
    
    func getBookings(botId: String) async throws -> [Booking] {
        return try await get(endpoint: "/bots/\(botId)/bookings")
    }
    
    func deleteBooking(bookingId: String) async throws {
        try await delete(endpoint: "/bookings/\(bookingId)")
    }

}
