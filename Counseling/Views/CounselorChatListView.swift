import SwiftUI

// MARK: - Counselor Chat List
// Shows students who have booked sessions (from counselor's sessions list)

@MainActor
final class CounselorChatListViewModel: ObservableObject {
    @Published var sessions: [Session] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            // fetch assigned sessions to find student IDs to chat with
            sessions = try await SessionService.shared.fetchCounselorSessions()
                .filter { $0.status == .assigned || $0.status == .completed }
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
    }
}

struct CounselorChatListView: View {
    @StateObject private var vm = CounselorChatListViewModel()

    // Deduplicated students (by studentId)
    private var uniqueStudents: [(id: Int, name: String, username: String?)] {
        var seen = Set<Int>()
        return vm.sessions.compactMap { session -> (id: Int, name: String, username: String?)? in
            guard let sid = session.studentId, !seen.contains(sid) else { return nil }
            seen.insert(sid)
            return (id: sid, name: session.displayStudentName, username: session.student?.username)
        }
    }

    var body: some View {
        List {
            if vm.isLoading && vm.sessions.isEmpty {
                HStack { Spacer(); ProgressView(); Spacer() }
            } else if uniqueStudents.isEmpty {
                ContentUnavailableView(
                    "No Conversations",
                    systemImage: "message.badge.waveform",
                    description: Text("Assigned students will appear here")
                )
            } else {
                Section("Students") {
                    ForEach(uniqueStudents, id: \.id) { student in
                        NavigationLink(
                            destination: ChatConversationView(
                                title: student.name,
                                peerId: student.id,
                                peerUsername: student.username
                            )
                        ) {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(Color(red: 0.32, green: 0.58, blue: 0.96).opacity(0.15))
                                        .frame(width: 46, height: 46)
                                    Text(initials(for: student.name))
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundColor(Color(red: 0.32, green: 0.58, blue: 0.96))
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(student.name).font(.headline)
                                    Text("Student").font(.caption).foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .navigationTitle("Chats")
        .task { await vm.load() }
        .refreshable { await vm.load() }
        .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
            Button("OK") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }

    private func initials(for name: String) -> String {
        let parts = name.split(separator: " ")
        let f = parts.first?.first.map(String.init) ?? ""
        let l = parts.count > 1 ? parts.last?.first.map(String.init) ?? "" : ""
        return (f + l).uppercased()
    }
}
