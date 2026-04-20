import Foundation
import Security

// MARK: - KeychainManager

final class KeychainManager {

    static let shared = KeychainManager()
    private init() {}

    // MARK: - Keys
    private enum Key {
        static let token   = "auth.jwt.token"
        static let userId  = "auth.user.id"
        static let role    = "auth.user.role"
        static let name    = "auth.user.name"
        static let username = "auth.user.username"
    }

    // MARK: - Public API

    var token: String? {
        get { read(key: Key.token) }
        set { newValue == nil ? delete(key: Key.token) : save(newValue!, key: Key.token) }
    }

    var userId: Int? {
        get { read(key: Key.userId).flatMap { Int($0) } }
        set { newValue == nil ? delete(key: Key.userId) : save(String(newValue!), key: Key.userId) }
    }

    var role: UserRole? {
        get { read(key: Key.role).flatMap { UserRole(rawValue: $0) } }
        set { newValue == nil ? delete(key: Key.role) : save(newValue!.rawValue, key: Key.role) }
    }

    var fullName: String? {
        get { read(key: Key.name) }
        set { newValue == nil ? delete(key: Key.name) : save(newValue!, key: Key.name) }
    }

    var username: String? {
        get { read(key: Key.username) }
        set { newValue == nil ? delete(key: Key.username) : save(newValue!, key: Key.username) }
    }

    /// Wipe all stored credentials (logout)
    func clearAll() {
        [Key.token, Key.userId, Key.role, Key.name, Key.username].forEach { delete(key: $0) }
    }

    // MARK: - Private helpers

    @discardableResult
    private func save(_ value: String, key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        delete(key: key)
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecValueData:   data
        ]
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    private func read(key: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass:            kSecClassGenericPassword,
            kSecAttrAccount:      key,
            kSecReturnData:       true,
            kSecMatchLimit:       kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    @discardableResult
    private func delete(key: String) -> Bool {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: key
        ]
        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }
}

// MARK: - UserRole

enum UserRole: String, Codable {
    case student   = "ROLE_STUDENT"
    case counselor = "ROLE_COUNSELOR"

    var displayName: String {
        switch self {
        case .student:   return "Student"
        case .counselor: return "Counselor"
        }
    }
}
