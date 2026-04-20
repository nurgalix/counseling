import SwiftUI

// MARK: - SessionStatus (matches backend enum)

enum SessionStatus: String, Codable {
    case created   = "CREATED"
    case assigned  = "ASSIGNED"
    case completed = "COMPLETED"
    case cancelled = "CANCELLED"

    var color: Color {
        switch self {
        case .created:   return Color(red: 0.95, green: 0.65, blue: 0.20)   // amber
        case .assigned:  return Color(red: 0.20, green: 0.72, blue: 0.50)   // green
        case .completed: return Color(red: 0.50, green: 0.50, blue: 0.95)   // purple
        case .cancelled: return Color(red: 0.90, green: 0.35, blue: 0.35)   // red
        }
    }

    var icon: String {
        switch self {
        case .created:   return "clock.fill"
        case .assigned:  return "checkmark.circle.fill"
        case .completed: return "checkmark.seal.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }

    var displayName: String {
        switch self {
        case .created:   return "Available"
        case .assigned:  return "Booked"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }
}

// MARK: - User DTO nested in sessions
struct SessionUserDto: Codable {
    let id: Int
    let firstName: String?
    let lastName: String?
    let username: String?

    var fullName: String {
        [firstName, lastName].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
    }
}

// MARK: - Session (replaces Appointment, maps to backend /session)

struct Session: Identifiable, Codable {
    let id: Int
    let startTime: String
    let roomNumber: String?
    let sessionStatus: SessionStatus
    
    let counselor: SessionUserDto?
    let student: SessionUserDto?

    enum CodingKeys: String, CodingKey {
        case id, startTime, roomNumber, sessionStatus, counselor, student
    }

    // MARK: - API field adapters
    var counselorId: Int? { counselor?.id }
    var studentId: Int?   { student?.id }

    // MARK: - UI helpers

    var displayCounselorName: String {
        let name = counselor?.fullName ?? ""
        return name.isEmpty ? "Counselor" : name
    }
    
    var displayStudentName: String {
        let name = student?.fullName ?? ""
        return name.isEmpty ? "Student" : name
    }
    
    var displayCabinet: String { roomNumber ?? "—" }

    var dateTime: Date {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = iso.date(from: startTime) { return d }
        // fallback standard ISO8601
        let std = ISO8601DateFormatter()
        if let d = std.date(from: startTime) { return d }
        // fallback to just returning now if it completely fails to parse
        return Date()
    }

    var canBook: Bool   { sessionStatus == .created }
    var canUnbook: Bool { sessionStatus == .assigned }
    
    // For UI compatibility with previous code (in CounselorCard etc)
    var status: SessionStatus { sessionStatus }
    var cabinetNumber: String? { roomNumber }
}

extension Session: Equatable {
    static func == (lhs: Session, rhs: Session) -> Bool { lhs.id == rhs.id }
}

// MARK: - CreateSessionRequest (for counselor POST /session/create)

struct CreateSessionRequest: Encodable {
    let startTime: String   // ISO-8601
    let roomNumber: String
}
