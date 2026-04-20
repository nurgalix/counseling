import Foundation

final class CounselorService {

    static let shared = CounselorService()
    private let api = APIClient.shared
    private init() {}

    /// GET /counselor/all — list of all counselors with their sessions
    func fetchAll() async throws -> [Counselor] {
        return try await api.get("/counselor/all")
    }

    /// GET /counselor/{counselorId}
    func fetchCounselor(id: Int) async throws -> Counselor {
        return try await api.get("/counselor/\(id)")
    }
}
