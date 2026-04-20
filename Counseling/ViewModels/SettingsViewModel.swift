import Foundation
import SwiftUI

struct UserProfile {
    var fullName: String
    var username: String
    var avatarColor: Color

    static var `default`: UserProfile {
        UserProfile(
            fullName: KeychainManager.shared.fullName ?? KeychainManager.shared.username ?? "User",
            username: KeychainManager.shared.username ?? "",
            avatarColor: Color(red: 0.32, green: 0.58, blue: 0.96)
        )
    }
}

// MARK: - User Stats
struct UserStats {
    var sessionsCompleted: Int
    var minutesMeditated: Int
    var currentStreak: Int      // days
    var favoriteCategory: String

    static let `default` = UserStats(
        sessionsCompleted: 12,
        minutesMeditated: 134,
        currentStreak: 5,
        favoriteCategory: "Peace"
    )
}

// MARK: - ViewModel
@MainActor
final class SettingsViewModel: ObservableObject {

    // MARK: Profile
    @Published var user: UserProfile = .default
    @Published var stats: UserStats = .default

    // MARK: Notification settings (persisted)
    @Published var isPushEnabled: Bool {
        didSet { UserDefaults.standard.set(isPushEnabled, forKey: "notif_push") }
    }
    @Published var isCrisisAlertsEnabled: Bool {
        didSet { UserDefaults.standard.set(isCrisisAlertsEnabled, forKey: "notif_crisis") }
    }

    // MARK: Privacy / Security (persisted)
    @Published var isSharingHistoryWithCounselor: Bool {
        didSet { UserDefaults.standard.set(isSharingHistoryWithCounselor, forKey: "priv_sharing") }
    }
    @Published var isBiometricEnabled: Bool {
        didSet { UserDefaults.standard.set(isBiometricEnabled, forKey: "sec_biometric") }
    }

    // MARK: App Appearance (persisted)
    @Published var selectedTheme: AppTheme {
        didSet { UserDefaults.standard.set(selectedTheme.rawValue, forKey: "app_theme") }
    }

    // MARK: UI State
    @Published var isProcessingRequest = false
    @Published var toastMessage: String?
    @Published var showEditProfile = false

    // MARK: Init
    init() {
        let ud = UserDefaults.standard
        isPushEnabled             = ud.object(forKey: "notif_push")     as? Bool ?? true
        isCrisisAlertsEnabled     = ud.object(forKey: "notif_crisis")   as? Bool ?? true
        isSharingHistoryWithCounselor = ud.object(forKey: "priv_sharing") as? Bool ?? true
        isBiometricEnabled        = ud.object(forKey: "sec_biometric")  as? Bool ?? false
        let themeRaw              = ud.string(forKey: "app_theme") ?? AppTheme.system.rawValue
        selectedTheme             = AppTheme(rawValue: themeRaw) ?? .system

        loadProfile()
    }

    // MARK: - Actions
    func saveProfile() {
        persistProfile()
        showToast("Profile updated ✓")
    }

    func updateNotifications(push: Bool? = nil, crisis: Bool? = nil) {
        if let push { isPushEnabled = push }
        if let crisis { isCrisisAlertsEnabled = crisis }
        showToast("Notification settings saved")
    }

    func updatePrivacy(isSharingEnabled: Bool) {
        isSharingHistoryWithCounselor = isSharingEnabled
        showToast("Privacy preferences saved")
    }

    func updateSecurity(isBiometricEnabled: Bool) {
        self.isBiometricEnabled = isBiometricEnabled
        showToast("Security settings updated")
    }

    func updateTheme(_ theme: AppTheme) {
        selectedTheme = theme
        showToast("Theme set to \(theme.label)")
    }

    // MARK: - Toast helper
    func showToast(_ message: String) {
        isProcessingRequest = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.isProcessingRequest = false
            self.toastMessage = message
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                self.toastMessage = nil
            }
        }
    }

    // MARK: - Initials helper
    func initials() -> String {
        let parts = user.fullName.split(separator: " ")
        let f = parts.first.flatMap(\.first).map(String.init) ?? ""
        let l = parts.count > 1 ? parts.last.flatMap(\.first).map(String.init) ?? "" : ""
        return f + l
    }

    // MARK: - Persistence
    private func persistProfile() {
        KeychainManager.shared.fullName = user.fullName
        KeychainManager.shared.username = user.username
    }

    private func loadProfile() {
        let kc = KeychainManager.shared
        if let name = kc.fullName, !name.isEmpty {
            user.fullName = name
        } else if let un = kc.username, !un.isEmpty {
            user.fullName = un
        }
        if let un = kc.username, !un.isEmpty { user.username = un }
    }
}

// MARK: - AppTheme
enum AppTheme: String, CaseIterable, Identifiable {
    case system = "system"
    case light  = "light"
    case dark   = "dark"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "System"
        case .light:  return "Light"
        case .dark:   return "Dark"
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light:  return "sun.max.fill"
        case .dark:   return "moon.fill"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}
