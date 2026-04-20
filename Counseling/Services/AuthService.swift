import Foundation

// MARK: - Request / Response DTOs

struct AuthRequest: Encodable {
    let username: String
    let password: String
    let firstName: String?
    let lastName: String?

    init(username: String, password: String, firstName: String? = nil, lastName: String? = nil) {
        self.username  = username
        self.password  = password
        self.firstName = firstName
        self.lastName  = lastName
    }
}

// AuthResponse removed (using plain tokens)

// MARK: - AuthService

final class AuthService {

    static let shared = AuthService()
    private let api = APIClient.shared
    private init() {}

    // MARK: Student

    func registerStudent(firstName: String, lastName: String, username: String, password: String) async throws -> String {
        let body = AuthRequest(username: username, password: password, firstName: firstName, lastName: lastName)
        return try await api.postString("/student/register", body: body, authenticated: false)
    }

    func loginStudent(username: String, password: String) async throws -> String {
        let body = AuthRequest(username: username, password: password)
        return try await api.postString("/student/authenticate", body: body, authenticated: false)
    }

    func logoutStudent() async throws {
        let _: String = try await api.postString("/student/logout", body: nil as String?, authenticated: true)
    }

    // MARK: Counselor

    func registerCounselor(firstName: String, lastName: String, username: String, password: String) async throws -> String {
        let body = AuthRequest(username: username, password: password, firstName: firstName, lastName: lastName)
        return try await api.postString("/counselor/register", body: body, authenticated: false)
    }

    func loginCounselor(username: String, password: String) async throws -> String {
        let body = AuthRequest(username: username, password: password)
        return try await api.postString("/counselor/authenticate", body: body, authenticated: false)
    }

    func logoutCounselor() async throws {
        let _: String = try await api.postString("/counselor/logout", body: nil as String?, authenticated: true)
    }
}
