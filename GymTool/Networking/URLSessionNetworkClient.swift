import Foundation

final class URLSessionNetworkClient: NetworkClient {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }

    func get<Request: Encodable, Response: Decodable>(
        url: URL,
        query: Request
    ) async throws -> Response {
        let data = try encoder.encode(query)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = json.compactMap { key, value in
            URLQueryItem(name: key, value: "\(value)")
        }

        guard let finalURL = components?.url else {
            throw NetworkError.invalidURL
        }

        let (responseData, response) = try await session.data(from: finalURL)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }

        return try decoder.decode(Response.self, from: responseData)
    }

    func get<Response: Decodable>(url: URL) async throws -> Response {
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }

        return try decoder.decode(Response.self, from: data)
    }
}