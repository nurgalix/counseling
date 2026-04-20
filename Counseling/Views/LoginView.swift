import SwiftUI

// MARK: - Login / Register View

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    let selectedRole: UserRole

    @State private var username   = ""
    @State private var password   = ""
    @State private var fullName   = ""
    @State private var isRegistering = false
    @State private var showPassword  = false

    private var roleColor: Color {
        selectedRole == .student
            ? Color(red: 0.32, green: 0.58, blue: 0.96)
            : Color(red: 0.55, green: 0.30, blue: 0.92)
    }

    private var roleGradient: [Color] {
        selectedRole == .student
            ? [Color(red: 0.32, green: 0.58, blue: 0.96), Color(red: 0.20, green: 0.72, blue: 0.90)]
            : [Color(red: 0.55, green: 0.30, blue: 0.92), Color(red: 0.85, green: 0.40, blue: 0.70)]
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.06, green: 0.06, blue: 0.14),
                         Color(red: 0.10, green: 0.12, blue: 0.24)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(roleColor.opacity(0.18))
                .frame(width: 260, height: 260)
                .blur(radius: 60)
                .offset(x: 100, y: -160)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    Spacer(minLength: 30)

                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: roleGradient,
                                                     startPoint: .topLeading,
                                                     endPoint: .bottomTrailing))
                                .frame(width: 76, height: 76)
                                .shadow(color: roleColor.opacity(0.45), radius: 18, x: 0, y: 6)
                            Image(systemName: selectedRole == .student ? "graduationcap.fill" : "person.crop.circle.badge.checkmark")
                                .font(.system(size: 34))
                                .foregroundColor(.white)
                        }

                        Text(isRegistering ? "Create Account" : "Welcome Back")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text("\(selectedRole.displayName) · \(isRegistering ? "Sign Up" : "Sign In")")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.50))
                    }

                    // Form
                    VStack(spacing: 16) {
                        if isRegistering {
                            darkField(text: $fullName, placeholder: "Full Name", icon: "person")
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        darkField(text: $username, placeholder: "Username", icon: "person.text.rectangle")
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        // Password field with eye toggle
                        HStack(spacing: 12) {
                            Image(systemName: "lock")
                                .foregroundColor(.white.opacity(0.40))
                                .frame(width: 20)

                            Group {
                                if showPassword {
                                    TextField("Password", text: $password)
                                } else {
                                    SecureField("Password", text: $password)
                                }
                            }
                            .foregroundColor(.white)
                            .tint(roleColor)

                            Button { showPassword.toggle() } label: {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .foregroundColor(.white.opacity(0.40))
                            }
                        }
                        .padding(16)
                        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.10), lineWidth: 1))
                    }
                    .padding(.horizontal, 24)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isRegistering)

                    // Error banner
                    if let err = authManager.errorMessage {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(err)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.85))
                                .multilineTextAlignment(.leading)
                        }
                        .padding(14)
                        .background(Color.orange.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.orange.opacity(0.25), lineWidth: 1))
                        .padding(.horizontal, 24)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Action button
                    Button {
                        Task {
                            if isRegistering {
                                await authManager.register(fullName: fullName, username: username,
                                                           password: password, role: selectedRole)
                            } else {
                                await authManager.login(username: username, password: password, role: selectedRole)
                            }
                        }
                    } label: {
                        ZStack {
                            if authManager.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text(isRegistering ? "Create Account" : "Sign In")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(18)
                        .background(
                            LinearGradient(colors: roleGradient,
                                           startPoint: .leading, endPoint: .trailing),
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                        .shadow(color: roleColor.opacity(0.45), radius: 12, x: 0, y: 6)
                    }
                    .disabled(authManager.isLoading || !isFormValid)
                    .opacity(isFormValid ? 1 : 0.6)
                    .padding(.horizontal, 24)

                    // Toggle sign-in / register
                    HStack(spacing: 6) {
                        Text(isRegistering ? "Already have an account?" : "Don't have an account?")
                            .foregroundColor(.white.opacity(0.45))
                            .font(.subheadline)
                        Button {
                            withAnimation(.spring()) {
                                isRegistering.toggle()
                                authManager.errorMessage = nil
                            }
                        } label: {
                            Text(isRegistering ? "Sign In" : "Create")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(roleColor)
                        }
                    }

                    Spacer(minLength: 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                            to: nil, from: nil, for: nil)
        }
    }

    // MARK: – Helpers

    private var isFormValid: Bool {
        let hasUsername = !username.trimmingCharacters(in: .whitespaces).isEmpty
        let hasPassword = password.count >= 4
        let hasName     = !isRegistering || !fullName.trimmingCharacters(in: .whitespaces).isEmpty
        return hasUsername && hasPassword && hasName
    }

    @ViewBuilder
    private func darkField(text: Binding<String>, placeholder: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.40))
                .frame(width: 20)
            TextField(placeholder, text: text)
                .foregroundColor(.white)
                .tint(roleColor)
        }
        .padding(16)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.10), lineWidth: 1))
    }
}

#Preview {
    NavigationStack {
        LoginView(selectedRole: .student).environmentObject(AuthManager())
    }
}
