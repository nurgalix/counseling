import SwiftUI

enum ResourceCategory: String, CaseIterable, Identifiable {
    case sleep   = "Sleep"
    case peace   = "Peace"
    case stress  = "Stress"
    case anxiety = "Anxiety"
    case focus   = "Focus"

    var id: String { rawValue }

    var accentColor: Color {
        switch self {
        case .sleep:   return Color(red: 0.42, green: 0.35, blue: 0.80)   // indigo/lavender
        case .peace:   return Color(red: 0.20, green: 0.72, blue: 0.60)   // teal
        case .stress:  return Color(red: 0.95, green: 0.45, blue: 0.35)   // coral
        case .anxiety: return Color(red: 0.95, green: 0.72, blue: 0.25)   // amber
        case .focus:   return Color(red: 0.25, green: 0.55, blue: 0.95)   // blue
        }
    }

    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [accentColor.opacity(0.30), accentColor.opacity(0.12)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct ResourceItem: Identifiable, Equatable {
    let id: UUID
    let title: String
    let subtitle: String
    let durationSeconds: Int  // total duration in seconds
    let category: ResourceCategory
    let icon: String

    var durationLabel: String {
        let m = durationSeconds / 60
        return "\(m) min"
    }

    static func == (lhs: ResourceItem, rhs: ResourceItem) -> Bool { lhs.id == rhs.id }
}

// MARK: - Sample Data
extension ResourceItem {
    static let allItems: [ResourceItem] = [
        // Sleep
        ResourceItem(id: UUID(), title: "Deep Sleep", subtitle: "Guided relaxation",
                     durationSeconds: 900, category: .sleep, icon: "moon.stars.fill"),
        ResourceItem(id: UUID(), title: "Bedtime Story", subtitle: "Calm your mind",
                     durationSeconds: 720, category: .sleep, icon: "bed.double.fill"),
        ResourceItem(id: UUID(), title: "Sleep Rain", subtitle: "White noise",
                     durationSeconds: 1800, category: .sleep, icon: "cloud.rain.fill"),
        ResourceItem(id: UUID(), title: "Body Scan", subtitle: "Progressive relaxation",
                     durationSeconds: 600, category: .sleep, icon: "figure.wave"),

        // Peace
        ResourceItem(id: UUID(), title: "Zen Meditation", subtitle: "Inner peace",
                     durationSeconds: 780, category: .peace, icon: "figure.mind.and.body"),
        ResourceItem(id: UUID(), title: "Visualization", subtitle: "Mental imagery",
                     durationSeconds: 780, category: .peace, icon: "eye.fill"),
        ResourceItem(id: UUID(), title: "Reflection", subtitle: "Self-awareness",
                     durationSeconds: 360, category: .peace, icon: "text.book.closed.fill"),
        ResourceItem(id: UUID(), title: "Kindness", subtitle: "Loving-kindness",
                     durationSeconds: 900, category: .peace, icon: "heart.fill"),

        // Stress
        ResourceItem(id: UUID(), title: "Box Breathing", subtitle: "4-4-4-4 technique",
                     durationSeconds: 480, category: .stress, icon: "wind"),
        ResourceItem(id: UUID(), title: "PMR", subtitle: "Progressive muscle",
                     durationSeconds: 660, category: .stress, icon: "figure.strengthtraining.traditional"),
        ResourceItem(id: UUID(), title: "Nature Walk", subtitle: "Guided imagery",
                     durationSeconds: 600, category: .stress, icon: "leaf.fill"),
        ResourceItem(id: UUID(), title: "Journaling", subtitle: "Write it out",
                     durationSeconds: 420, category: .stress, icon: "pencil.and.outline"),

        // Anxiety
        ResourceItem(id: UUID(), title: "5-4-3-2-1", subtitle: "Grounding technique",
                     durationSeconds: 300, category: .anxiety, icon: "hand.raised.fingers.spread"),
        ResourceItem(id: UUID(), title: "Calm Breath", subtitle: "Slow exhale",
                     durationSeconds: 420, category: .anxiety, icon: "aqi.low"),
        ResourceItem(id: UUID(), title: "Worry Time", subtitle: "Structured worry",
                     durationSeconds: 600, category: .anxiety, icon: "clock.fill"),
        ResourceItem(id: UUID(), title: "Body Check", subtitle: "Tension release",
                     durationSeconds: 540, category: .anxiety, icon: "person.fill"),

        // Focus
        ResourceItem(id: UUID(), title: "Focus", subtitle: "Deep work",
                     durationSeconds: 600, category: .focus, icon: "target"),
        ResourceItem(id: UUID(), title: "Pomodoro", subtitle: "25 min burst",
                     durationSeconds: 1500, category: .focus, icon: "timer"),
        ResourceItem(id: UUID(), title: "Study Flow", subtitle: "Flow state",
                     durationSeconds: 720, category: .focus, icon: "brain.head.profile"),
        ResourceItem(id: UUID(), title: "Mind Warm Up", subtitle: "Cognitive prep",
                     durationSeconds: 300, category: .focus, icon: "bolt.fill"),
    ]
}
