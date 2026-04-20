import Foundation

final class SessionService {

    static let shared = SessionService()
    private let api = APIClient.shared
    private init() {}

    // MARK: - Student

    /// GET /student/sessions
    func fetchStudentSessions() async throws -> [Session] {
        return try await api.get("/student/sessions")
    }

    /// POST /session/book/{sessionId}
    func bookSession(id: Int) async throws {
        let _: String = try await api.postString("/session/book/\(id)", body: nil as String?)
    }

    /// POST /session/unbook/{sessionId}
    func unbookSession(id: Int) async throws {
        let _: String = try await api.postString("/session/unbook/\(id)", body: nil as String?)
    }

    // MARK: - Counselor

    /// GET /counselor/sessions
    func fetchCounselorSessions() async throws -> [Session] {
        return try await api.get("/counselor/sessions")
    }

    /// POST /session/create — counselor creates a new slot
    func createSession(dateTime: Date, cabinetNumber: String) async throws {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]
        let req = CreateSessionRequest(startTime: iso.string(from: dateTime),
                                       roomNumber: cabinetNumber)
        // returns {"startTime": "...", "roomNumber": "..."} which we discard since it lacks ID
        let _: String = try await api.postString("/session/create", body: req)
    }
}
