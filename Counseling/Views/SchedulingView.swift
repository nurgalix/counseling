import SwiftUI

// ══════════════════════════════════════════════
// MARK: - Scheduling View (Student)
// ══════════════════════════════════════════════
struct SchedulingView: View {
    @StateObject private var vm = SchedulingViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerBar
                segmentTabs
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                if vm.selectedTab == 0 {
                    counselorsTab
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal:   .move(edge: .trailing).combined(with: .opacity)
                        ))
                } else {
                    sessionsTab
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal:   .move(edge: .leading).combined(with: .opacity)
                        ))
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .animation(.easeInOut(duration: 0.22), value: vm.selectedTab)
            // Booking sheet (pick session slot of selected counselor)
            .sheet(item: $vm.selectedCounselor) { counselor in
                SessionBookingSheet(counselor: counselor,
                                    sessions: counselor.sessions?.filter { $0.status == .created } ?? []) { sessionId in
                    Task { await vm.book(sessionId: sessionId) }
                }
            }
            // Unbook confirmation
            .confirmationDialog(
                "Cancel Session",
                isPresented: $vm.showUnbookConfirm,
                titleVisibility: .visible
            ) {
                Button("Cancel Session", role: .destructive) {
                    Task { await vm.confirmUnbook() }
                }
                Button("Keep It", role: .cancel) {}
            } message: {
                Text("Your session slot will become available for others.")
            }
            .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
                Button("OK") { vm.errorMessage = nil }
            } message: {
                Text(vm.errorMessage ?? "")
            }
        }
        .task { await vm.loadAll() }
        .refreshable { await vm.loadAll() }
    }

    // ─────────────────────────────────────────
    // MARK: Header
    // ─────────────────────────────────────────
    private var headerBar: some View {
        HStack(alignment: .lastTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Schedule")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text(Date().formatted(.dateTime.weekday(.wide).month().day()))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if !vm.upcomingSessions.isEmpty {
                HStack(spacing: 5) {
                    Image(systemName: "calendar.badge.clock").font(.caption)
                    Text("\(vm.upcomingSessions.count) upcoming")
                        .font(.caption).fontWeight(.semibold)
                }
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(Capsule().fill(Color(red: 0.32, green: 0.58, blue: 0.96).opacity(0.14)))
                .foregroundColor(Color(red: 0.32, green: 0.58, blue: 0.96))
            }
        }
        .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 4)
    }

    // ─────────────────────────────────────────
    // MARK: Segment Tabs
    // ─────────────────────────────────────────
    private var segmentTabs: some View {
        HStack(spacing: 0) {
            tabButton(title: "Counselors", icon: "person.2.fill", tag: 0)
            tabButton(title: "My Sessions", icon: "calendar.circle.fill", tag: 1)
        }
        .padding(4)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private func tabButton(title: String, icon: String, tag: Int) -> some View {
        let selected = vm.selectedTab == tag
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { vm.selectedTab = tag }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 13, weight: .semibold))
                Text(title).font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(selected ? .white : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(
                selected ? Color(red: 0.32, green: 0.58, blue: 0.96) : Color.clear,
                in: RoundedRectangle(cornerRadius: 11)
            )
            .shadow(color: selected ? Color(red: 0.32, green: 0.58, blue: 0.96).opacity(0.35) : .clear,
                    radius: 6, x: 0, y: 3)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selected)
    }

    // ─────────────────────────────────────────
    // MARK: Counselors Tab
    // ─────────────────────────────────────────
    private var counselorsTab: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary).font(.system(size: 15))
                TextField("Search counselors or specialization…", text: $vm.searchText)
                    .font(.system(size: 15))
                if !vm.searchText.isEmpty {
                    Button { vm.searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 11)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 20).padding(.bottom, 16)

            if vm.isLoading && vm.counselors.isEmpty {
                Spacer()
                ProgressView("Loading counselors…")
                Spacer()
            } else if vm.filteredCounselors.isEmpty {
                Spacer()
                ContentUnavailableView("No Results", systemImage: "magnifyingglass",
                                       description: Text("Try a different name or specialization"))
                Spacer()
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 14) {
                        ForEach(vm.filteredCounselors) { counselor in
                            CounselorCard(counselor: counselor) {
                                vm.selectedCounselor = counselor
                            }
                        }
                    }
                    .padding(.horizontal, 20).padding(.bottom, 20)
                }
            }
        }
    }

    // ─────────────────────────────────────────
    // MARK: Sessions Tab
    // ─────────────────────────────────────────
    private var sessionsTab: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {

                if !vm.upcomingSessions.isEmpty {
                    sectionHeader("Upcoming", icon: "calendar.badge.clock",
                                  color: Color(red: 0.32, green: 0.58, blue: 0.96))
                    ForEach(vm.upcomingSessions) { session in
                        SessionCard(session: session, daysUntil: vm.daysUntil(session.dateTime)) {
                            vm.sessionToUnbook = session
                            vm.showUnbookConfirm = true
                        }
                    }
                }

                if !vm.pastSessions.isEmpty {
                    sectionHeader("Past & Cancelled", icon: "clock.arrow.circlepath", color: .secondary)
                    ForEach(vm.pastSessions) { session in
                        SessionCard(session: session, daysUntil: 0, onCancel: nil).opacity(0.6)
                    }
                }

                if vm.upcomingSessions.isEmpty && vm.pastSessions.isEmpty && !vm.isLoading {
                    VStack(spacing: 14) {
                        Spacer(minLength: 40)
                        Image(systemName: "calendar.badge.plus").font(.system(size: 52))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("No sessions yet").font(.title3).fontWeight(.semibold)
                        Text("Browse counselors and book your first session")
                            .font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
                        Button {
                            withAnimation { vm.selectedTab = 0 }
                        } label: {
                            Label("Find a Counselor", systemImage: "person.2.fill")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24).padding(.vertical, 13)
                                .background(Color(red: 0.32, green: 0.58, blue: 0.96), in: Capsule())
                        }.padding(.top, 6)
                    }
                    .frame(maxWidth: .infinity).padding(.horizontal, 20)
                }
            }
            .padding(.horizontal, 20).padding(.bottom, 30)
        }
    }

    private func sectionHeader(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.caption).foregroundColor(color)
            Text(title).font(.caption).fontWeight(.semibold)
                .foregroundColor(.secondary).textCase(.uppercase).tracking(0.5)
        }.padding(.top, 4)
    }
}

// ══════════════════════════════════════════════
// MARK: - Counselor Card (reuses Counselor model)
// ══════════════════════════════════════════════
struct CounselorCard: View {
    let counselor: Counselor
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 14) {
                    ZStack {
                        Circle().fill(counselor.color.opacity(0.18)).frame(width: 56, height: 56)
                        Text(counselor.initials)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(counselor.color)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(counselor.fullName).font(.system(size: 15, weight: .bold)).foregroundColor(.primary)
                        Text(counselor.displaySpecialization).font(.subheadline).foregroundColor(.secondary)

                        HStack(spacing: 10) {
                            if !counselor.displayExperience.isEmpty {
                                Label(counselor.displayExperience, systemImage: "briefcase.fill")
                            }
                            if counselor.displayRating > 0 {
                                HStack(spacing: 3) {
                                    Image(systemName: "star.fill").foregroundColor(.yellow)
                                    Text(String(format: "%.1f", counselor.displayRating))
                                }
                            }
                        }
                        .font(.caption).foregroundColor(.secondary).padding(.top, 2)
                    }

                    Spacer()
                    availabilityBadge
                }

                if !counselor.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(counselor.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2).fontWeight(.semibold)
                                    .padding(.horizontal, 9).padding(.vertical, 5)
                                    .background(counselor.color.opacity(0.12))
                                    .foregroundColor(counselor.color)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                HStack {
                    Spacer()
                    if counselor.availableSlots > 0 {
                        Label("Book Session", systemImage: "calendar.badge.plus")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 18).padding(.vertical, 9)
                            .background(counselor.color, in: Capsule())
                    } else {
                        Text("No open slots")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
            )
        }
        .buttonStyle(.plain)
        .disabled(counselor.availableSlots == 0)
    }

    private var availabilityBadge: some View {
        VStack(spacing: 2) {
            if counselor.availableSlots > 0 {
                Text("\(counselor.availableSlots)")
                    .font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(counselor.color)
                Text("slots").font(.caption2).foregroundColor(.secondary)
            } else {
                Image(systemName: "calendar.badge.exclamationmark").font(.system(size: 18)).foregroundColor(.secondary)
                Text("Full").font(.caption2).foregroundColor(.secondary)
            }
        }.frame(width: 44)
    }
}

// ══════════════════════════════════════════════
// MARK: - Session Card
// ══════════════════════════════════════════════
struct SessionCard: View {
    let session: Session
    let daysUntil: Int
    let onCancel: (() -> Void)?

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 3)
                .fill(session.status.color)
                .frame(width: 5)
                .padding(.vertical, 12)

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(session.displayCounselorName)
                            .font(.system(size: 15, weight: .bold)).foregroundColor(.primary)
                        if !session.displayCabinet.isEmpty, session.displayCabinet != "—" {
                            Label("Cabinet \(session.displayCabinet)", systemImage: "mappin.circle")
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: session.status.icon).font(.caption2)
                        Text(session.status.displayName).font(.caption).fontWeight(.semibold)
                    }
                    .foregroundColor(session.status.color)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(session.status.color.opacity(0.12), in: Capsule())
                }

                HStack(spacing: 12) {
                    Label(session.dateTime.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()),
                          systemImage: "calendar")
                    Label(session.dateTime.formatted(.dateTime.hour().minute()), systemImage: "clock")
                }
                .font(.caption).foregroundColor(.secondary)

                if daysUntil > 0 && session.canUnbook {
                    HStack(spacing: 5) {
                        Image(systemName: "timer").font(.caption2)
                        Text(daysUntil == 1 ? "Tomorrow" : "In \(daysUntil) days")
                            .font(.caption).fontWeight(.semibold)
                    }
                    .foregroundColor(Color(red: 0.32, green: 0.58, blue: 0.96))
                    .padding(.horizontal, 9).padding(.vertical, 4)
                    .background(Color(red: 0.32, green: 0.58, blue: 0.96).opacity(0.1), in: Capsule())
                }

                if let onCancel, session.canUnbook {
                    HStack {
                        Spacer()
                        Button(action: onCancel) {
                            Text("Cancel Booking")
                                .font(.caption).fontWeight(.semibold).foregroundColor(.red)
                        }
                    }
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 14)
        }
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

// ══════════════════════════════════════════════
// MARK: - Session Booking Sheet
// Shows CREATED session slots for a counselor to book
// ══════════════════════════════════════════════
struct SessionBookingSheet: View {
    let counselor: Counselor
    let sessions: [Session]
    let onBook: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedSession: Session? = nil

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Counselor header
                    HStack(spacing: 16) {
                        ZStack {
                            Circle().fill(counselor.color.opacity(0.18)).frame(width: 64, height: 64)
                            Text(counselor.initials)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(counselor.color)
                        }
                        .shadow(color: counselor.color.opacity(0.35), radius: 10, x: 0, y: 4)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(counselor.fullName).font(.system(size: 17, weight: .bold))
                            Text(counselor.displaySpecialization).font(.subheadline).foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20).padding(.top, 8)

                    Divider()

                    if sessions.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.system(size: 44)).foregroundColor(.secondary.opacity(0.5))
                            Text("No available slots").font(.headline)
                            Text("Check back later for open sessions")
                                .font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
                        }
                        .padding(.top, 40)
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 6) {
                                Image(systemName: "clock").font(.caption).foregroundColor(.secondary)
                                Text("Available Slots")
                                    .font(.caption).fontWeight(.semibold)
                                    .foregroundColor(.secondary).textCase(.uppercase).tracking(0.5)
                            }.padding(.horizontal, 20)

                            ForEach(sessions) { session in
                                slotRow(session)
                            }
                        }
                    }

                    Spacer(minLength: 20)
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Book a Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(.secondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm") {
                        if let s = selectedSession {
                            onBook(s.id)
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(selectedSession != nil ? counselor.color : .secondary)
                    .disabled(selectedSession == nil)
                }
            }
        }
    }

    @ViewBuilder
    private func slotRow(_ session: Session) -> some View {
        let isSelected = selectedSession?.id == session.id
        Button { selectedSession = session } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.dateTime.formatted(.dateTime.weekday(.wide).month().day()))
                        .font(.system(size: 15, weight: .semibold))
                    Text(session.dateTime.formatted(.dateTime.hour().minute()))
                        .font(.subheadline).foregroundColor(.secondary)
                    if let cab = session.cabinetNumber, !cab.isEmpty {
                        Label("Cabinet \(cab)", systemImage: "mappin.circle")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? counselor.color : .secondary.opacity(0.4))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected
                          ? counselor.color.opacity(0.10)
                          : Color(.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? counselor.color : Color.clear, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
    }
}

// ══════════════════════════════════════════════
// MARK: - Preview
// ══════════════════════════════════════════════
#Preview {
    SchedulingView()
}
