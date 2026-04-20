import SwiftUI

// MARK: - Counselor (backend DTO + UI helpers)

struct Counselor: Identifiable, Codable {
    let counselorId: Int
    let firstName: String
    let lastName: String
    let username: String
    let sessions: [Session]?       // embedded sessions list from GET /counselor/all

    enum CodingKeys: String, CodingKey {
        case counselorId, firstName, lastName, username, sessions
    }

    // MARK: - UI helpers (not from API)

    var id: Int { counselorId }

    var fullName: String {
        [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
    }

    /// First + last initial of the name
    var initials: String {
        let f = firstName.first.map(String.init) ?? ""
        let l = lastName.first.map(String.init) ?? ""
        return (f + l).uppercased()
    }

    /// Deterministic color derived from counselor id
    var color: Color {
        let palette: [Color] = [
            Color(red: 0.32, green: 0.58, blue: 0.96),   // blue
            Color(red: 0.25, green: 0.72, blue: 0.55),   // green
            Color(red: 0.95, green: 0.55, blue: 0.28),   // orange
            Color(red: 0.65, green: 0.40, blue: 0.92),   // purple
            Color(red: 0.90, green: 0.35, blue: 0.55),   // pink
        ]
        return palette[abs(id) % palette.count]
    }

    var displaySpecialization: String {
        "Counselor"
    }

    var displayExperience: String {
        ""
    }

    var displayRating: Double {
        0.0
    }

    /// Number of CREATED (open) session slots available for booking
    var availableSlots: Int {
        sessions?.filter { $0.status == .created }.count ?? 0
    }

    var tags: [String] {
        []
    }
}

extension Counselor: Equatable {
    static func == (lhs: Counselor, rhs: Counselor) -> Bool { lhs.counselorId == rhs.counselorId }
}
