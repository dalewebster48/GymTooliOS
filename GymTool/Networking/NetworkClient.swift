import Foundation

protocol NetworkClient: AnyObject {
    func get<Request: Encodable, Response: Decodable>(
        url: URL,
        query: Request
    ) async throws -> Response

    func get<Response: Decodable>(url: URL) async throws -> Response
}