import SwiftUI

// MARK: - AuthManager

@MainActor
final class AuthManager: ObservableObject {

    @Published var isAuthenticated: Bool = false
    @Published var currentRole: UserRole = .student
    @Published var currentUserId: Int = 0
    @Published var currentUserName: String = ""
    @Published var currentUsername: String = ""

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let auth    = AuthService.shared
    private let keychain = KeychainManager.shared
    private let ws      = WebSocketService.shared

    init() {
        // Restore session from Keychain
        if let token = keychain.token, !token.isEmpty {
            isAuthenticated   = true
            currentRole       = keychain.role ?? .student
            currentUserId     = keychain.userId ?? 0
            currentUserName   = keychain.fullName ?? ""
            currentUsername   = keychain.username ?? ""
            ws.connect()
        }
    }

    // MARK: - Login

    func login(username: String, password: String, role: UserRole) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let token: String
            switch role {
            case .student:   token = try await auth.loginStudent(username: username, password: password)
            case .counselor: token = try await auth.loginCounselor(username: username, password: password)
            }
            persist(token: token, role: role, username: username, firstName: nil, lastName: nil)
            withAnimation { isAuthenticated = true }
            ws.connect()
        } catch let e as APIError {
            errorMessage = e.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Register

    func register(fullName: String, username: String, password: String, role: UserRole) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let token: String
            let parts = fullName.split(separator: " ").map(String.init)
            let firstName = parts.first ?? ""
            let lastName = parts.count > 1 ? parts.dropFirst().joined(separator: " ") : ""

            switch role {
            case .student:   token = try await auth.registerStudent(firstName: firstName, lastName: lastName, username: username, password: password)
            case .counselor: token = try await auth.registerCounselor(firstName: firstName, lastName: lastName, username: username, password: password)
            }
            persist(token: token, role: role, username: username, firstName: firstName, lastName: lastName)
            withAnimation { isAuthenticated = true }
            ws.connect()
        } catch let e as APIError {
            errorMessage = e.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Logout

    func logout() {
        Task {
            ws.disconnect()
            do {
                switch currentRole {
                case .student:   try await auth.logoutStudent()
                case .counselor: try await auth.logoutCounselor()
                }
            } catch {
                // Best-effort — still clear session locally
            }
            keychain.clearAll()
            withAnimation {
                errorMessage     = nil
                isAuthenticated  = false
                currentUserId    = 0
                currentUserName  = ""
                currentUsername  = ""
            }
        }
    }

    // MARK: - Private

    private func persist(token: String, role: UserRole, username: String, firstName: String?, lastName: String?) {
        keychain.token    = token
        keychain.role     = role
        let first = firstName ?? ""
        let last = lastName ?? ""
        if !first.isEmpty {
            keychain.fullName = [first, last].filter { !$0.isEmpty }.joined(separator: " ")
        }
        keychain.username = username
        currentRole       = role
        currentUserName   = keychain.fullName ?? ""
        currentUsername   = keychain.username ?? ""
    }
}

// MARK: - RootView

struct RootView: View {
    @StateObject private var authManager = AuthManager()

    var body: some View {
        Group {
            if authManager.isAuthenticated {
                if authManager.currentRole == .counselor {
                    CounselorMainView()
                        .environmentObject(authManager)
                } else {
                    MainView()
                        .environmentObject(authManager)
                }
            } else {
                NavigationStack {
                    RoleSelectionView()
                        .environmentObject(authManager)
                }
            }
        }
    }
}
