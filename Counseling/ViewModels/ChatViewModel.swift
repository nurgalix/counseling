import Foundation
import Combine

// MARK: - ChatViewModel

@MainActor
final class ChatViewModel: ObservableObject {

    @Published private(set) var messages: [Message] = []
    @Published var draftText: String = ""
    @Published private(set) var isLoadingHistory = false
    @Published private(set) var isSending = false
    @Published var errorMessage: String?

    // Who we're talking to (nil = GPT-only mode)
    let peerId: Int?          // counselorId (student) or studentId (counselor)
    let peerUsername: String?
    let isGPTMode: Bool       // true = /app/gpt channel

    private let ws = WebSocketService.shared
    private var cancellables = Set<AnyCancellable>()
    private var currentUserId: Int { KeychainManager.shared.userId ?? 0 }
    private var currentRole: UserRole { KeychainManager.shared.role ?? .student }

    init(peerId: Int? = nil, peerUsername: String? = nil, isGPTMode: Bool = false) {
        self.peerId       = peerId
        self.peerUsername = peerUsername
        self.isGPTMode    = isGPTMode
        bindWebSocket()
    }

    // MARK: - History

    func loadHistory() async {
        guard !isLoadingHistory else { return }
        isLoadingHistory = true
        defer { isLoadingHistory = false }

        guard let id = peerId, !isGPTMode else { return }

        do {
            if currentRole == .student {
                messages = try await ws.fetchStudentChatHistory(counselorId: id)
            } else {
                messages = try await ws.fetchCounselorChatHistory(studentId: id)
            }
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
    }

    // MARK: - Send

    func sendMessage() async {
        let trimmed = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isSending else { return }

        isSending = true
        draftText = ""
        errorMessage = nil

        // Optimistic local append
        let optimistic = Message.local(text: trimmed, isCurrentUser: true)
        messages.append(optimistic)

        if isGPTMode {
            ws.sendGPTMessage(content: trimmed)
        } else if let un = peerUsername {
            ws.sendMessage(toUsername: un, content: trimmed)
        }

        isSending = false
    }

    // MARK: - WebSocket binding

    private func bindWebSocket() {
        // Incoming chat messages
        ws.$lastReceivedMessage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (msg: Message) in
                guard let self else { return }
                // For simplicity, any incoming ws personal message in this view is appended
                if !self.isGPTMode {
                    self.messages.append(msg)
                }
            }
            .store(in: &cancellables)

        // GPT replies
        ws.$lastGPTMessage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (msg: Message) in
                guard let self, self.isGPTMode else { return }
                self.messages.append(msg)
            }
            .store(in: &cancellables)
    }
}
