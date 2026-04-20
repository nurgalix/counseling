import SwiftUI

// ═══════════════════════════════════════════
// MARK: - Profile View (the 4th tab)
// ═══════════════════════════════════════════
struct SettingsView: View {
    @StateObject private var vm = SettingsViewModel()
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Scroll content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        heroHeader
                            .padding(.bottom, 24)

                        statsRow
                            .padding(.horizontal, 20)
                            .padding(.bottom, 28)

                        settingsSections
                            .padding(.horizontal, 16)
                            .padding(.bottom, 40)
                    }
                }
                // KEY: extend scroll content behind status bar so gradient fills to the top edge
                .ignoresSafeArea(edges: .top)
                .background(Color(.systemGroupedBackground).ignoresSafeArea())

                // Toast
                if let msg = vm.toastMessage {
                    toastBanner(msg)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 16)
                }
            }
            .navigationTitle("")
            .toolbar(.hidden)
            .sheet(isPresented: $vm.showEditProfile) {
                EditProfileSheet(vm: vm)
            }
            .preferredColorScheme(vm.selectedTheme.colorScheme)
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: vm.toastMessage)
        }
    }

    // ─────────────────────────────────────────
    // MARK: Hero Header
    // ─────────────────────────────────────────
    private var heroHeader: some View {
        // Color.clear gives the ZStack a real size in layout;
        // the background modifier with ignoresSafeArea extends
        // the gradient behind the status bar without breaking scroll.
        Color.clear
            .frame(height: 220)
            .background(
                ZStack(alignment: .bottomLeading) {
                    // Gradient fills behind status bar
                    LinearGradient(
                        colors: [
                            vm.user.avatarColor,
                            vm.user.avatarColor.opacity(0.55)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    // Decorative circles
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 180)
                        .offset(x: -40, y: 30)
                    Circle()
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 120)
                        .offset(x: UIScreen.main.bounds.width - 80, y: -10)

                    // Avatar + name pinned to bottom
                    HStack(alignment: .bottom, spacing: 16) {
                        // Avatar
                        ZStack {
                            Circle()
                                .fill(.white)
                                .frame(width: 82, height: 82)
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [vm.user.avatarColor, vm.user.avatarColor.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 74, height: 74)
                            Text(vm.initials())
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .shadow(color: vm.user.avatarColor.opacity(0.5), radius: 12, x: 0, y: 6)

                        // Name + meta
                        VStack(alignment: .leading, spacing: 3) {
                            Text(vm.user.fullName)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }

                        Spacer()

                        // Edit button
                        Button { vm.showEditProfile = true } label: {
                            Image(systemName: "pencil")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(vm.user.avatarColor)
                                .padding(10)
                                .background(.white)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .ignoresSafeArea(edges: .top)  // background modifier CAN ignore safe area
            )
    }

    // ─────────────────────────────────────────
    // MARK: Stats Row
    // ─────────────────────────────────────────
    private var statsRow: some View {
        HStack(spacing: 12) {
            StatPill(
                value: "\(vm.stats.sessionsCompleted)",
                label: "Sessions",
                icon: "checkmark.seal.fill",
                color: vm.user.avatarColor
            )
            StatPill(
                value: "\(vm.stats.minutesMeditated)",
                label: "Minutes",
                icon: "clock.fill",
                color: Color(red: 0.25, green: 0.72, blue: 0.60)
            )
            StatPill(
                value: "\(vm.stats.currentStreak)d",
                label: "Streak",
                icon: "flame.fill",
                color: Color(red: 0.95, green: 0.50, blue: 0.25)
            )
        }
    }

    // ─────────────────────────────────────────
    // MARK: Settings Sections
    // ─────────────────────────────────────────
    private var settingsSections: some View {
        VStack(spacing: 20) {

            // NOTIFICATIONS
            ProfileSection(title: "Notifications", icon: "bell.badge.fill", color: .red) {
                VStack(spacing: 0) {
                    ProfileToggleRow(
                        icon: "bell.fill", iconColor: .red,
                        title: "Push Notifications",
                        subtitle: nil,
                        isOn: $vm.isPushEnabled
                    )
                    Divider().padding(.leading, 56)
                    ProfileToggleRow(
                        icon: "exclamationmark.triangle.fill", iconColor: .orange,
                        title: "Crisis Alerts",
                        subtitle: "Notified when risk is detected",
                        isOn: $vm.isCrisisAlertsEnabled
                    )
                }
            }

            // APPEARANCE
            ProfileSection(title: "Appearance", icon: "paintbrush.fill", color: vm.user.avatarColor) {
                HStack(spacing: 10) {
                    ForEach(AppTheme.allCases) { theme in
                        ThemePill(
                            theme: theme,
                            isSelected: vm.selectedTheme == theme,
                            accentColor: vm.user.avatarColor
                        ) {
                            vm.updateTheme(theme)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)   // equal top & bottom — pills sit centred in the card
            }

            // PRIVACY & SECURITY
            ProfileSection(title: "Privacy & Security", icon: "lock.shield.fill", color: .green) {
                VStack(spacing: 0) {
                    ProfileToggleRow(
                        icon: "lock.shield.fill", iconColor: .green,
                        title: "Counselor Access",
                        subtitle: "Share chat history for diagnosis",
                        isOn: $vm.isSharingHistoryWithCounselor
                    )
                    Divider().padding(.leading, 56)
                    ProfileToggleRow(
                        icon: "faceid", iconColor: Color(.systemGray),
                        title: "Face ID Login",
                        subtitle: nil,
                        isOn: $vm.isBiometricEnabled
                    )
                    Divider().padding(.leading, 56)
                    ProfileNavRow(icon: "hand.raised.fill", iconColor: .blue, title: "Privacy Policy") {
                        EmptyView()
                    }
                }
            }

            // SUPPORT
            ProfileSection(title: "Support", icon: "questionmark.circle.fill", color: .purple) {
                VStack(spacing: 0) {
                    ProfileNavRow(icon: "envelope.fill", iconColor: .purple, title: "Contact Support") {
                        EmptyView()
                    }
                    Divider().padding(.leading, 56)
                    ProfileNavRow(icon: "star.fill", iconColor: .yellow, title: "Rate the App") {
                        EmptyView()
                    }
                }
            }

            // SIGN OUT
            signOutButton

            // Version
            Text("UniMind v1.0.0  ·  Built with ♡")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
    }

    // ─────────────────────────────────────────
    // MARK: Sign Out Button
    // ─────────────────────────────────────────
    private var signOutButton: some View {
        Button {
            authManager.logout()
        } label: {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 15, weight: .semibold))
                Text("Sign Out")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
            )
        }
    }

    // ─────────────────────────────────────────
    // MARK: Toast Banner
    // ─────────────────────────────────────────
    private func toastBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text(message)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 13)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 6)
        )
    }
}

// ═══════════════════════════════════════════
// MARK: - Sub-components
// ═══════════════════════════════════════════

// MARK: Stat Pill
struct StatPill: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
        )
    }
}

// MARK: Profile Section Card
struct ProfileSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            .padding(.leading, 4)
            .padding(.bottom, 8)

            // Card body
            VStack(spacing: 0) {
                content()
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: Toggle Row
struct ProfileToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 14) {
                SettingsIcon(icon: icon, color: iconColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                    if let sub = subtitle {
                        Text(sub)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .tint(.green)
    }
}

// MARK: Nav Row
struct ProfileNavRow<Dest: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    @ViewBuilder let destination: () -> Dest

    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 14) {
                SettingsIcon(icon: icon, color: iconColor)
                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }
}

// MARK: Theme Pill
struct ThemePill: View {
    let theme: AppTheme
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: theme.icon)
                    .font(.caption)
                Text(theme.label)
                    .font(.system(size: 13, weight: .semibold))
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? accentColor : Color(.tertiarySystemGroupedBackground))
            )
            .foregroundColor(isSelected ? .white : .secondary)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// ═══════════════════════════════════════════
// MARK: - Edit Profile Sheet
// ═══════════════════════════════════════════
struct EditProfileSheet: View {
    @ObservedObject var vm: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    // local drafts
    @State private var draftName: String = ""
    @State private var draftUsername: String = ""

    private let accentColors: [Color] = [
        Color(red: 0.32, green: 0.58, blue: 0.96),
        Color(red: 0.25, green: 0.72, blue: 0.60),
        Color(red: 0.85, green: 0.38, blue: 0.60),
        Color(red: 0.60, green: 0.38, blue: 0.90),
        Color(red: 0.95, green: 0.55, blue: 0.28),
    ]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {

                    // Avatar preview
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [vm.user.avatarColor, vm.user.avatarColor.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 90, height: 90)
                        Text(vm.initials())
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .shadow(color: vm.user.avatarColor.opacity(0.45), radius: 14, x: 0, y: 6)
                    .padding(.top, 8)

                    // Color picker
                    VStack(spacing: 10) {
                        Text("Avatar Color")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        HStack(spacing: 14) {
                            ForEach(accentColors, id: \.self) { c in
                                Circle()
                                    .fill(c)
                                    .frame(width: 34, height: 34)
                                    .overlay(
                                        Circle()
                                            .stroke(.white, lineWidth: vm.user.avatarColor == c ? 3 : 0)
                                            .padding(2)
                                    )
                                    .shadow(color: c.opacity(0.4), radius: 6, x: 0, y: 3)
                                    .scaleEffect(vm.user.avatarColor == c ? 1.15 : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: vm.user.avatarColor == c)
                                    .onTapGesture { vm.user.avatarColor = c }
                            }
                        }
                    }

                    // Fields
                    VStack(spacing: 16) {
                        EditField(icon: "person.fill", placeholder: "Full Name", text: $draftName)
                        EditField(icon: "person.text.rectangle", placeholder: "Username", text: $draftUsername)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: 20)
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.secondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        commitChanges()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(vm.user.avatarColor)
                }
            }
            .onAppear {
                draftName  = vm.user.fullName
                draftUsername = vm.user.username
            }
        }
    }

    private func commitChanges() {
        vm.user.fullName = draftName.trimmingCharacters(in: .whitespaces).isEmpty
            ? vm.user.fullName
            : draftName.trimmingCharacters(in: .whitespaces)
        vm.user.username = draftUsername.trimmingCharacters(in: .whitespaces).isEmpty
            ? vm.user.username
            : draftUsername.trimmingCharacters(in: .whitespaces)
        vm.saveProfile()
    }
}

// MARK: Edit Field
struct EditField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 24)
            TextField(placeholder, text: $text)
                .font(.system(size: 15))
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

// ═══════════════════════════════════════════
// MARK: - Preview
// ═══════════════════════════════════════════
#Preview {
    SettingsView()
        .environmentObject(AuthManager())
}
