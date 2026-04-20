import Foundation
import Combine
import Starscream

// MARK: - STOMP Frame Builder

private enum STOMP {
    static func connect(host: String, token: String) -> String {
        "CONNECT\naccept-version:1.2\nhost:\(host)\nAuthorization:Bearer \(token)\n\n\0"
    }

    static func subscribe(destination: String, id: String = "sub-0") -> String {
        "SUBSCRIBE\nid:\(id)\ndestination:\(destination)\n\n\0"
    }

    static func send(destination: String, body: String) -> String {
        "SEND\ndestination:\(destination)\ncontent-type:application/json\ncontent-length:\(body.utf8.count)\n\n\(body)\0"
    }

    static func disconnect() -> String {
        "DISCONNECT\n\n\0"
    }

    /// Parse a raw STOMP frame into command + headers + body
    static func parse(_ text: String) -> (command: String, headers: [String: String], body: String)? {
        var parts = text.components(separatedBy: "\n\n")
        guard parts.count >= 1 else { return nil }
        let headerLines = parts[0].components(separatedBy: "\n")
        guard let command = headerLines.first, !command.isEmpty else { return nil }
        var headers: [String: String] = [:]
        for line in headerLines.dropFirst() {
            let kv = line.split(separator: ":", maxSplits: 1).map(String.init)
            if kv.count == 2 { headers[kv[0]] = kv[1] }
        }
        let body = parts.dropFirst().joined(separator: "\n\n").replacingOccurrences(of: "\0", with: "")
        return (command, headers, body)
    }
}

// MARK: - WebSocketService

@MainActor
final class WebSocketService: ObservableObject {

    static let shared = WebSocketService()

    // Published message streams
    @Published var lastReceivedMessage: Message?
    @Published var lastGPTMessage: Message?
    @Published var isConnected = false

    private var socket: WebSocket?
    private var pendingSubscriptions: [String] = []

    private let wsURL = URL(string: "wss://psyhological-counseling-app-production.up.railway.app/ws/websocket")!
    private let host  = "psyhological-counseling-app-production.up.railway.app"

    private var jsonDecoder: JSONDecoder = {
        let d = JSONDecoder()
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        d.dateDecodingStrategy = .custom { dec in
            let c = try dec.singleValueContainer()
            let s = try c.decode(String.self)
            return iso.date(from: s) ?? Date()
        }
        return d
    }()

    private var jsonEncoder: JSONEncoder = {
        let e = JSONEncoder()
        return e
    }()

    private init() {}

    // MARK: - Connect / Disconnect

    func connect() {
        guard !isConnected, let token = KeychainManager.shared.token else { return }

        var request = URLRequest(url: wsURL)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30

        let ws = WebSocket(request: request)
        ws.onEvent = { [weak self] event in
            Task { @MainActor in
                self?.handleEvent(event)
            }
        }
        socket = ws
        ws.connect()
    }

    func disconnect() {
        socket?.write(string: STOMP.disconnect())
        socket?.disconnect()
        socket = nil
        isConnected = false
    }

    // MARK: - Send Chat Message

    func sendMessage(toUsername recipientUsername: String, content: String) {
        guard isConnected else { return }
        let payload = ChatSendPayload(recipientUsername: recipientUsername, text: content, fromCounselor: KeychainManager.shared.role == .counselor)
        guard let data = try? jsonEncoder.encode(payload),
              let json  = String(data: data, encoding: .utf8) else { return }
        socket?.write(string: STOMP.send(destination: "/app/chat", body: json))
    }

    // MARK: - Send GPT Message

    func sendGPTMessage(content: String) {
        guard isConnected else { return }
        let payload = GPTSendPayload(input: content)
        guard let data = try? jsonEncoder.encode(payload),
              let json  = String(data: data, encoding: .utf8) else { return }
        socket?.write(string: STOMP.send(destination: "/app/gpt", body: json))
    }

    // MARK: - Subscribe helper (must be called AFTER CONNECTED)

    private func subscribe(to destination: String, id: String) {
        socket?.write(string: STOMP.subscribe(destination: destination, id: id))
    }

    // MARK: - Event handler

    private func handleEvent(_ event: WebSocketEvent) {
        switch event {
        case .connected:
            guard let token = KeychainManager.shared.token else { return }
            socket?.write(string: STOMP.connect(host: host, token: token))

        case .text(let text):
            handleSTOMP(frame: text)

        case .disconnected:
            isConnected = false

        case .error:
            isConnected = false

        case .cancelled:
            isConnected = false

        default:
            break
        }
    }

    // MARK: - STOMP frame routing

    private func handleSTOMP(frame text: String) {
        guard let (command, headers, body) = STOMP.parse(text) else { return }

        switch command {
        case "CONNECTED":
            isConnected = true
            // Subscribe to personal message queue
            subscribe(to: "/user/queue/messages", id: "sub-chat")
            subscribe(to: "/user/queue/gpt",      id: "sub-gpt")

        case "MESSAGE":
            guard let data = body.data(using: .utf8) else { return }
            // Try to decode as chat message
            if let msg = try? jsonDecoder.decode(Message.self, from: data) {
                if headers["subscription"] == "sub-gpt" {
                    lastGPTMessage = msg
                } else {
                    lastReceivedMessage = msg
                }
            }

        case "ERROR":
            print("[WebSocket] STOMP error: \(body)")

        default:
            break
        }
    }
}

// MARK: - Chat history (REST - no WS needed)

extension WebSocketService {
    /// GET /student/chat/{counselorId}
    func fetchStudentChatHistory(counselorId: Int) async throws -> [Message] {
        return try await APIClient.shared.get("/student/chat/\(counselorId)")
    }

    /// GET /counselor/chat/{studentId}
    func fetchCounselorChatHistory(studentId: Int) async throws -> [Message] {
        return try await APIClient.shared.get("/counselor/chat/\(studentId)")
    }
}
