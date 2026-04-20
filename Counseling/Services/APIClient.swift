import Foundation

// MARK: - APIError

enum APIError: LocalizedError {
    case invalidURL
    case unauthorized
    case serverError(statusCode: Int, message: String?)
    case decodingError(Error)
    case networkError(Error)
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidURL:                          return "Invalid request URL."
        case .unauthorized:                        return "Session expired. Please log in again."
        case .serverError(let code, let msg):      return msg ?? "Server error (\(code))."
        case .decodingError(let e):                return "Data format error: \(e.localizedDescription)"
        case .networkError(let e):                 return e.localizedDescription
        case .unknown:                             return "An unknown error occurred."
        }
    }
}

// MARK: - APIClient

final class APIClient {

    static let shared = APIClient()
    private init() {}

    private let baseURL = URL(string: "https://psyhological-counseling-app-production.up.railway.app")!
    private let session = URLSession.shared

    private var decoder: JSONDecoder = {
        let d = JSONDecoder()
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)
            if let date = iso.date(from: str) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot parse date: \(str)")
        }
        return d
    }()

    private var encoder: JSONEncoder = {
        let e = JSONEncoder()
        return e
    }()

    // MARK: - Request builders

    func get<T: Decodable>(_ path: String, authenticated: Bool = true) async throws -> T {
        let req = try buildRequest(path: path, method: "GET", body: nil as EmptyBody?, authenticated: authenticated)
        return try await perform(req)
    }

    func post<B: Encodable, T: Decodable>(_ path: String, body: B, authenticated: Bool = true) async throws -> T {
        let req = try buildRequest(path: path, method: "POST", body: body, authenticated: authenticated)
        return try await perform(req)
    }

    /// POST with no response body — returns Void
    func post<B: Encodable>(_ path: String, body: B, authenticated: Bool = true) async throws {
        let req = try buildRequest(path: path, method: "POST", body: body, authenticated: authenticated)
        let _: EmptyResponse = try await perform(req)
    }

    /// POST with no request or response body
    func postEmpty(_ path: String, authenticated: Bool = true) async throws {
        let req = try buildRequest(path: path, method: "POST", body: nil as EmptyBody?, authenticated: authenticated)
        let _: EmptyResponse = try await perform(req)
    }

    /// POST that expects a raw String response (like the raw JWT token)
    func postString<B: Encodable>(_ path: String, body: B, authenticated: Bool = true) async throws -> String {
        let req = try buildRequest(path: path, method: "POST", body: body, authenticated: authenticated)
        
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: req)
        } catch {
            throw APIError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else { throw APIError.unknown }

        switch http.statusCode {
        case 200..<300:
            guard let str = String(data: data, encoding: .utf8) else {
                throw APIError.decodingError(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Expected UTF8 string"]))
            }
            // in case they send a JSON {"token": "..."} despite the docs, we try to strip it simply:
            if str.hasPrefix("{"), str.contains("\"token\"") {
                if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: String], let token = dict["token"] {
                    return token
                }
            }
            return str.trimmingCharacters(in: .whitespacesAndNewlines)
        case 401, 403:
            throw APIError.unauthorized
        default:
            let msg = String(data: data, encoding: .utf8)
            throw APIError.serverError(statusCode: http.statusCode, message: msg)
        }
    }

    // MARK: - Core perform

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.unknown
        }

        switch http.statusCode {
        case 200..<300:
            if T.self == EmptyResponse.self {
                return EmptyResponse() as! T
            }
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingError(error)
            }
        case 401, 403:
            throw APIError.unauthorized
        default:
            let msg = String(data: data, encoding: .utf8)
            throw APIError.serverError(statusCode: http.statusCode, message: msg)
        }
    }

    // MARK: - Request factory

    private func buildRequest<B: Encodable>(
        path: String,
        method: String,
        body: B?,
        authenticated: Bool
    ) throws -> URLRequest {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw APIError.invalidURL
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        if authenticated, let token = KeychainManager.shared.token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            req.httpBody = try encoder.encode(body)
        }
        return req
    }
}

// MARK: - Helpers
private struct EmptyBody: Encodable {}
struct EmptyResponse: Decodable {}
