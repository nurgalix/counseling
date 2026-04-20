import Foundation

// MARK: - Message (Unified for both REST and WebSocket)

struct Message: Identifiable, Codable {
    let id: String
    let content: String
    let sentAt: Date
    let isCurrentUser: Bool

    // Legacy or internal properties mapping
    var text: String { content }
    
    // Internal backing properties from decoders
    private var _senderBool: Bool?
    private var _senderUsername: String?

    enum CodingKeys: String, CodingKey {
        case id, text, date, sender, senderUsername
    }

    // Custom Decoder to handle both REST history and WebSocket payloads
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        
        // IDs: REST uses Int/String, Websocket might omit. Local fallbacks to UUID String.
        if let intId = try? c.decodeIfPresent(Int.self, forKey: .id) {
            id = String(intId)
        } else if let strId = try? c.decodeIfPresent(String.self, forKey: .id) {
            id = strId
        } else {
            id = UUID().uuidString
        }

        // Content
        if let txt = try? c.decodeIfPresent(String.self, forKey: .text) {
            content = txt
        } else {
            content = ""
        }

        // Date (can be string or time interval, backend sends string usually)
        if let dateStr = try? c.decodeIfPresent(String.self, forKey: .date),
           let d = ISO8601DateFormatter().date(from: dateStr) {
            sentAt = d
        } else {
            // fallback
            sentAt = Date()
        }

        // Sender matching logic
        _senderBool = try? c.decodeIfPresent(Bool.self, forKey: .sender)
        _senderUsername = try? c.decodeIfPresent(String.self, forKey: .senderUsername)
        
        // Compute isCurrentUser
        let kc = KeychainManager.shared
        if let u = _senderUsername, let myU = kc.username {
            isCurrentUser = (u == myU)
        } else if let isCounselor = _senderBool {
            let myRole = kc.role ?? .student
            isCurrentUser = (myRole == .counselor && isCounselor) || (myRole == .student && !isCounselor)
        } else {
            isCurrentUser = false
        }
    }

    // Local init
    init(id: String = UUID().uuidString, content: String, sentAt: Date = Date(), isCurrentUser: Bool) {
        self.id            = id
        self.content       = content
        self.sentAt        = sentAt
        self.isCurrentUser = isCurrentUser
    }

    // legacy convenience for GPT chat
    static func local(text: String, isCurrentUser: Bool) -> Message {
        Message(content: text, isCurrentUser: isCurrentUser)
    }

    // Required by Encodable if needed elsewhere, though usually we only decode
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(content, forKey: .text)
        try c.encode(sentAt.description, forKey: .date)
        if let b = _senderBool { try c.encode(b, forKey: .sender) }
        if let u = _senderUsername { try c.encode(u, forKey: .senderUsername) }
    }
}

// MARK: - WebSocket send payloads

struct ChatSendPayload: Encodable {
    let recipientUsername: String
    let text: String
    let fromCounselor: Bool
}

struct GPTSendPayload: Encodable {
    let input: String
}