import SwiftUI

// MARK: - Role Selection Screen

struct RoleSelectionView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedRole: UserRole? = nil

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(red: 0.06, green: 0.06, blue: 0.14),
                         Color(red: 0.10, green: 0.12, blue: 0.24)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Decorative blobs
            Circle()
                .fill(Color(red: 0.32, green: 0.58, blue: 0.96).opacity(0.18))
                .frame(width: 280, height: 280)
                .blur(radius: 60)
                .offset(x: -80, y: -180)

            Circle()
                .fill(Color(red: 0.65, green: 0.40, blue: 0.92).opacity(0.14))
                .frame(width: 220, height: 220)
                .blur(radius: 50)
                .offset(x: 110, y: 200)

            VStack(spacing: 0) {
                Spacer()

                // Logo + Title
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(colors: [.blue, Color(red: 0.40, green: 0.80, blue: 1.0)],
                                               startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .frame(width: 84, height: 84)
                            .shadow(color: .blue.opacity(0.45), radius: 20, x: 0, y: 8)

                        Image(systemName: "leaf.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }

                    Text("MindBridge")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Choose how you're joining")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.55))
                }

                Spacer()

                // Role Cards
                VStack(spacing: 14) {
                    roleCard(
                        role: .student,
                        icon: "graduationcap.fill",
                        title: "I'm a Student",
                        subtitle: "Book sessions, chat with counselors & AI",
                        gradient: [Color(red: 0.32, green: 0.58, blue: 0.96),
                                   Color(red: 0.20, green: 0.72, blue: 0.90)]
                    )

                    roleCard(
                        role: .counselor,
                        icon: "person.crop.circle.badge.checkmark",
                        title: "I'm a Counselor",
                        subtitle: "Manage sessions & chat with your students",
                        gradient: [Color(red: 0.55, green: 0.30, blue: 0.92),
                                   Color(red: 0.85, green: 0.40, blue: 0.70)]
                    )
                }
                .padding(.horizontal, 24)

                Spacer().frame(height: 48)
            }
        }
        .navigationDestination(item: $selectedRole) { role in
            LoginView(selectedRole: role)
                .environmentObject(authManager)
        }
        .navigationBarHidden(true)
    }

    @ViewBuilder
    private func roleCard(role: UserRole, icon: String, title: String,
                          subtitle: String, gradient: [Color]) -> some View {
        Button {
            selectedRole = role
        } label: {
            HStack(spacing: 18) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(LinearGradient(colors: gradient,
                                             startPoint: .topLeading,
                                             endPoint: .bottomTrailing))
                        .frame(width: 56, height: 56)
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.60))
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.40))
            }
            .padding(20)
            .background(.ultraThinMaterial.opacity(0.3),
                        in: RoundedRectangle(cornerRadius: 22))
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

extension UserRole: Identifiable {
    public var id: String { rawValue }
}

#Preview {
    NavigationStack {
        RoleSelectionView().environmentObject(AuthManager())
    }
}
