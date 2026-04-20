import SwiftUI

struct ChatConversationView: View {
    let title: String
    let peerId: Int?
    let peerUsername: String?
    let isGPTMode: Bool

    @StateObject private var viewModel: ChatViewModel
    @FocusState private var isInputFocused: Bool

    init(title: String, peerId: Int? = nil, peerUsername: String? = nil, isGPTMode: Bool = false) {
        self.title        = title
        self.peerId       = peerId
        self.peerUsername = peerUsername
        self.isGPTMode    = isGPTMode
        _viewModel        = StateObject(wrappedValue: ChatViewModel(peerId: peerId, peerUsername: peerUsername, isGPTMode: isGPTMode))
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            messageBubble(for: message)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.last?.id) { id in
                    if let id { withAnimation { proxy.scrollTo(id, anchor: .bottom) } }
                }
            }

            if viewModel.isLoadingHistory {
                ProgressView().padding(8)
            }

            inputBar
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onAppear {
            Task { await viewModel.loadHistory() }
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField(isGPTMode ? "Ask the AI..." : "Message...",
                      text: $viewModel.draftText, axis: .vertical)
                .focused($isInputFocused)
                .padding(10)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(20)
                .lineLimit(1...5)

            Button {
                Task { await viewModel.sendMessage() }
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.title2)
                    .foregroundColor(viewModel.draftText.trimmingCharacters(in: .whitespaces).isEmpty ? .gray : .blue)
            }
            .disabled(viewModel.draftText.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isSending)
        }
        .padding()
        .background(.bar)
    }

    // MARK: - Message Bubble

    @ViewBuilder
    private func messageBubble(for message: Message) -> some View {
        HStack {
            if message.isCurrentUser { Spacer() }

            Text(message.content)
                .padding(12)
                .background(message.isCurrentUser
                            ? (isGPTMode ? Color.blue : Color.accentColor)
                            : Color(.systemGray5))
                .foregroundColor(message.isCurrentUser ? .white : .primary)
                .cornerRadius(16)
                .frame(maxWidth: 280, alignment: message.isCurrentUser ? .trailing : .leading)

            if !message.isCurrentUser { Spacer() }
        }
    }
}
