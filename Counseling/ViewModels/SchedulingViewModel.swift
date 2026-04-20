import SwiftUI
import Combine

@MainActor
final class SchedulingViewModel: ObservableObject {

    // MARK: - Data (live from backend)
    @Published var counselors: [Counselor]    = []
    @Published var sessions: [Session]        = []

    // MARK: - UI State
    @Published var selectedTab: Int           = 0    // 0 = Counselors, 1 = My Sessions
    @Published var searchText: String         = ""
    @Published var selectedCounselor: Counselor? = nil
    @Published var sessionToUnbook: Session?  = nil
    @Published var showUnbookConfirm: Bool    = false
    @Published var isLoading: Bool            = false
    @Published var errorMessage: String?      = nil

    private let counselorService = CounselorService.shared
    private let sessionService   = SessionService.shared

    // MARK: - Derived

    var filteredCounselors: [Counselor] {
        if searchText.isEmpty { return counselors }
        let q = searchText.lowercased()
        return counselors.filter {
            $0.fullName.lowercased().contains(q)
            || $0.displaySpecialization.lowercased().contains(q)
            || $0.tags.contains { $0.lowercased().contains(q) }
        }
    }

    var upcomingSessions: [Session] {
        sessions
            .filter { $0.dateTime >= Date() && $0.status != .cancelled }
            .sorted { $0.dateTime < $1.dateTime }
    }

    var pastSessions: [Session] {
        sessions
            .filter { $0.dateTime < Date() || $0.status == .cancelled }
            .sorted { $0.dateTime > $1.dateTime }
    }

    // MARK: - Load

    func loadAll() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadCounselors() }
            group.addTask { await self.loadSessions() }
        }
    }

    private func loadCounselors() async {
        do {
            counselors = try await counselorService.fetchAll()
        } catch {
            errorMessage = errorMessage ?? (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func loadSessions() async {
        do {
            sessions = try await sessionService.fetchStudentSessions()
        } catch {
            errorMessage = errorMessage ?? (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
    }

    // MARK: - Book

    func book(sessionId: Int) async {
        do {
            try await sessionService.bookSession(id: sessionId)
            await loadSessions()
            withAnimation { selectedTab = 1 }
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
    }

    // MARK: - Unbook

    func confirmUnbook() async {
        guard let s = sessionToUnbook else { return }
        do {
            try await sessionService.unbookSession(id: s.id)
            await loadSessions()
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
        sessionToUnbook = nil
    }

    // MARK: - Time helpers

    func daysUntil(_ date: Date) -> Int {
        Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
    }
}
