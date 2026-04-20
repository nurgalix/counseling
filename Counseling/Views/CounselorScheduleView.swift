import SwiftUI

// ══════════════════════════════════════════════
// MARK: - Counselor Schedule View
// ══════════════════════════════════════════════

@MainActor
final class CounselorScheduleViewModel: ObservableObject {
    @Published var sessions: [Session] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showCreateSheet = false

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            sessions = try await SessionService.shared.fetchCounselorSessions()
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
    }

    func createSession(date: Date, cabinet: String) async {
        do {
            try await SessionService.shared.createSession(dateTime: date, cabinetNumber: cabinet)
            await load()
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
    }

    var upcomingSessions: [Session] {
        sessions.filter { $0.dateTime >= Date() && $0.status != .cancelled }
            .sorted { $0.dateTime < $1.dateTime }
    }

    var pastSessions: [Session] {
        sessions.filter { $0.dateTime < Date() || $0.status == .cancelled }
            .sorted { $0.dateTime > $1.dateTime }
    }
}

struct CounselorScheduleView: View {
    @StateObject private var vm = CounselorScheduleViewModel()

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 20) {

                    // Upcoming
                    if !vm.upcomingSessions.isEmpty {
                        sectionHeader("Upcoming", icon: "calendar.badge.clock",
                                      color: Color(red: 0.32, green: 0.58, blue: 0.96))
                        ForEach(vm.upcomingSessions) { session in
                            counselorSessionCard(session)
                        }
                    }

                    // Past
                    if !vm.pastSessions.isEmpty {
                        sectionHeader("Past & Cancelled", icon: "clock.arrow.circlepath", color: .secondary)
                        ForEach(vm.pastSessions) { session in
                            counselorSessionCard(session).opacity(0.6)
                        }
                    }

                    // Empty
                    if vm.upcomingSessions.isEmpty && vm.pastSessions.isEmpty && !vm.isLoading {
                        VStack(spacing: 14) {
                            Spacer(minLength: 60)
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 52)).foregroundColor(.secondary.opacity(0.5))
                            Text("No sessions yet").font(.title3).fontWeight(.semibold)
                            Text("Tap + to create your first session slot")
                                .font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                    }

                    if vm.isLoading {
                        HStack { Spacer(); ProgressView(); Spacer() }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("My Schedule")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        vm.showCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
            }
            .sheet(isPresented: $vm.showCreateSheet) {
                CreateSessionSheet { date, cabinet in
                    Task { await vm.createSession(date: date, cabinet: cabinet) }
                }
            }
            .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
                Button("OK") { vm.errorMessage = nil }
            } message: { Text(vm.errorMessage ?? "") }
        }
        .task { await vm.load() }
        .refreshable { await vm.load() }
    }

    @ViewBuilder
    private func counselorSessionCard(_ session: Session) -> some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 3)
                .fill(session.status.color)
                .frame(width: 5)
                .padding(.vertical, 12)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(session.status == .assigned
                             ? session.displayStudentName
                             : "Open Slot")
                            .font(.system(size: 15, weight: .bold))
                        if let cab = session.cabinetNumber, !cab.isEmpty {
                            Label("Cabinet \(cab)", systemImage: "mappin.circle")
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

    private func sectionHeader(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.caption).foregroundColor(color)
            Text(title).font(.caption).fontWeight(.semibold)
                .foregroundColor(.secondary).textCase(.uppercase).tracking(0.5)
        }
    }
}

// ══════════════════════════════════════════════
// MARK: - Create Session Sheet
// ══════════════════════════════════════════════

struct CreateSessionSheet: View {
    let onConfirm: (Date, String) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var selectedDate = Date()
    @State private var cabinetNumber = ""

    private let accentColor = Color(red: 0.55, green: 0.30, blue: 0.92)

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    VStack(alignment: .leading, spacing: 8) {
                        sectionLabel("Session Date & Time", icon: "calendar")
                        DatePicker("", selection: $selectedDate, in: Date()...,
                                   displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.graphical)
                            .accentColor(accentColor)
                            .padding(.horizontal, 8)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        sectionLabel("Cabinet Number", icon: "mappin.circle")
                        HStack(spacing: 12) {
                            Image(systemName: "mappin.circle").foregroundColor(.secondary)
                            TextField("e.g. 204", text: $cabinetNumber)
                                .keyboardType(.numberPad)
                        }
                        .padding(14)
                        .background(Color(.secondarySystemGroupedBackground),
                                    in: RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, 20)
                    }

                    Spacer(minLength: 20)
                }
                .padding(.top, 8)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("New Session Slot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(.secondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onConfirm(selectedDate, cabinetNumber)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(cabinetNumber.isEmpty ? .secondary : accentColor)
                    .disabled(cabinetNumber.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func sectionLabel(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.caption).foregroundColor(.secondary)
            Text(title).font(.caption).fontWeight(.semibold)
                .foregroundColor(.secondary).textCase(.uppercase).tracking(0.5)
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    CounselorScheduleView()
}
