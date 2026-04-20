import SwiftUI

// MARK: - Chat History View (Student)
// Shows list of counselors to start/continue a chat with,
// plus the GPT "New Consultation" option.

struct ChatHistoryView: View {
    @StateObject private var vm = ChatHistoryViewModel()

    var body: some View {
        List {
            // GPT Chat
            NavigationLink(destination: ChatConversationView(title: "AI Psychologist", isGPTMode: true)) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.blue, .cyan],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 46, height: 46)
                        Image(systemName: "sparkles")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AI Consultation")
                            .font(.headline)
                        Text("Chat with AI psychologist")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 6)
            }

            // Counselors section
            if !vm.counselors.isEmpty {
                Section("Your Counselors") {
                    ForEach(vm.counselors) { counselor in
                        NavigationLink(
                            destination: ChatConversationView(
                                title: counselor.fullName,
                                peerId: counselor.id,
                                peerUsername: counselor.username
                            )
                        ) {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(counselor.color.opacity(0.18))
                                        .frame(width: 46, height: 46)
                                    Text(counselor.initials)
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundColor(counselor.color)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(counselor.fullName)
                                        .font(.headline)
                                    Text(counselor.displaySpecialization)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }

            if vm.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
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
}

// MARK: - ViewModel

@MainActor
final class ChatHistoryViewModel: ObservableObject {
    @Published var counselors: [Counselor] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            counselors = try await CounselorService.shared.fetchAll()
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
    }
}
