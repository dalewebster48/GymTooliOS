import Foundation

enum NetworkError: Error {
    case invalidResponse
    case invalidURL
    case httpError(statusCode: Int)
}