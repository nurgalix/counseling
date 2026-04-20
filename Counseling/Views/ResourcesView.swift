import SwiftUI

// ─────────────────────────────────────────────
// MARK: - Main Resources View
// ─────────────────────────────────────────────
struct ResourcesView: View {
    @StateObject private var vm = ResourcesViewModel()
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {

                    // Header
                    headerSection

                    // Category pills
                    categoryPills

                    // Featured card
                    if let featured = vm.featuredItem {
                        featuredCard(featured)
                    }

                    // Grid
                    if !vm.gridItems.isEmpty {
                        sectionTitle("More Sessions")
                        resourceGrid
                    }

                    Spacer(minLength: 20)
                }
                .padding(.top, 8)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("")
            .toolbar(.hidden)
        }
    }

    private var headerSection: some View {
        let name = authManager.currentUserName.isEmpty ? authManager.currentUsername : authManager.currentUserName.split(separator: " ").first.map(String.init) ?? "User"
        return VStack(alignment: .leading, spacing: 4) {
            Text("Hello, \(name) 👋")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            Text("What would you like to practice today?")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Category Pills
    private var categoryPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(ResourceCategory.allCases) { category in
                    let isSelected = vm.selectedCategory == category
                    Button {
                        vm.select(category: category)
                    } label: {
                        Text(category.rawValue)
                            .font(.system(size: 15, weight: .semibold))
                            .padding(.vertical, 9)
                            .padding(.horizontal, 18)
                            .background(
                                isSelected
                                    ? category.accentColor
                                    : Color(.secondarySystemGroupedBackground)
                            )
                            .foregroundColor(isSelected ? .white : .primary)
                            .clipShape(Capsule())
                            .shadow(
                                color: isSelected ? category.accentColor.opacity(0.4) : .clear,
                                radius: 6, x: 0, y: 3
                            )
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 4)
        }
    }

    // MARK: - Featured Card
    private func featuredCard(_ item: ResourceItem) -> some View {
        NavigationLink(destination: PlayerView(item: item, vm: vm)) {
            ZStack(alignment: .bottomLeading) {
                // Background gradient
                RoundedRectangle(cornerRadius: 24)
                    .fill(vm.selectedCategory.backgroundGradient)

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Featured")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(vm.selectedCategory.accentColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule().fill(vm.selectedCategory.accentColor.opacity(0.15))
                            )

                        Text(item.title)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .lineLimit(2)

                        Text(item.subtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Spacer()

                        HStack(spacing: 6) {
                            Image(systemName: "play.circle.fill")
                                .font(.title3)
                                .foregroundColor(vm.selectedCategory.accentColor)
                            Text("Start · \(item.durationLabel)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                    }

                    Spacer()

                    Image(systemName: item.icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 90, height: 90)
                        .foregroundStyle(vm.selectedCategory.accentColor.opacity(0.85))
                        .padding(.trailing, 4)
                }
                .padding(24)
            }
            .frame(height: 190)
            .padding(.horizontal, 20)
            .shadow(color: vm.selectedCategory.accentColor.opacity(0.18), radius: 16, x: 0, y: 8)
        }
        .transition(.opacity.combined(with: .move(edge: .leading)))
        .animation(.easeInOut(duration: 0.25), value: vm.selectedCategory)
    }

    // MARK: - Grid
    private var resourceGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
            spacing: 14
        ) {
            ForEach(vm.gridItems) { item in
                NavigationLink(destination: PlayerView(item: item, vm: vm)) {
                    ResourceCard(item: item, vm: vm)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .animation(.easeInOut(duration: 0.25), value: vm.selectedCategory)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundColor(.primary)
            .padding(.horizontal, 20)
    }
}

// ─────────────────────────────────────────────
// MARK: - Resource Card
// ─────────────────────────────────────────────
struct ResourceCard: View {
    let item: ResourceItem
    @ObservedObject var vm: ResourcesViewModel

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 8) {
                // Icon
                Image(systemName: item.icon)
                    .font(.system(size: 32))
                    .foregroundStyle(item.category.accentColor)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                Text(item.title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(2)

                Text(item.subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Duration badge
                Label(item.durationLabel, systemImage: "clock")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(item.category.accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(item.category.accentColor.opacity(0.12))
                    .clipShape(Capsule())
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 170, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
            )

            // Favorite button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    vm.toggleFavorite(item)
                }
            } label: {
                Image(systemName: vm.isFavorited(item) ? "heart.fill" : "heart")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(vm.isFavorited(item) ? .red : .secondary)
                    .padding(8)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .padding(10)
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Player View
// ─────────────────────────────────────────────
struct PlayerView: View {
    let item: ResourceItem
    @ObservedObject var vm: ResourcesViewModel
    @Environment(\.dismiss) private var dismiss

    // Playback state
    @State private var isPlaying = false
    @State private var elapsedSeconds: Int = 0
    @State private var timer: Timer? = nil
    @State private var progressAnimation: Bool = false

    private var progress: Double {
        guard item.durationSeconds > 0 else { return 0 }
        return Double(elapsedSeconds) / Double(item.durationSeconds)
    }

    private var timeRemaining: Int {
        max(0, item.durationSeconds - elapsedSeconds)
    }

    private func timeString(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }

    var body: some View {
        ZStack {
            // Background
            item.category.accentColor.opacity(0.08)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Nav bar area
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(12)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    Spacer()

                    // Favorite
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                            vm.toggleFavorite(item)
                        }
                    } label: {
                        Image(systemName: vm.isFavorited(item) ? "heart.fill" : "heart")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(vm.isFavorited(item) ? .red : .primary)
                            .padding(12)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                Spacer()

                // Album art / icon circle
                ZStack {
                    Circle()
                        .fill(item.category.backgroundGradient)
                        .frame(width: 220, height: 220)

                    Circle()
                        .stroke(item.category.accentColor.opacity(0.25), lineWidth: 12)
                        .frame(width: 220, height: 220)

                    // Pulse ring when playing
                    if isPlaying {
                        Circle()
                            .stroke(item.category.accentColor.opacity(0.15), lineWidth: 8)
                            .frame(width: progressAnimation ? 260 : 220, height: progressAnimation ? 260 : 220)
                            .animation(
                                .easeInOut(duration: 1.4).repeatForever(autoreverses: true),
                                value: progressAnimation
                            )
                    }

                    Image(systemName: item.icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundStyle(item.category.accentColor)
                }
                .shadow(color: item.category.accentColor.opacity(0.30), radius: 30, x: 0, y: 12)
                .padding(.bottom, 36)
                .onAppear { if isPlaying { progressAnimation = true } }
                .onChange(of: isPlaying) { playing in
                    progressAnimation = playing
                }

                // Titles
                VStack(spacing: 6) {
                    Text(item.title)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text(item.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    // Category badge
                    Text(item.category.rawValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(item.category.accentColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(
                            Capsule().fill(item.category.accentColor.opacity(0.14))
                        )
                        .padding(.top, 4)
                }
                .padding(.horizontal, 24)

                Spacer()

                // Progress section
                VStack(spacing: 10) {
                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemFill))
                                .frame(height: 6)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(item.category.accentColor)
                                .frame(width: geo.size.width * CGFloat(progress), height: 6)
                                .animation(.linear(duration: 0.5), value: progress)
                        }
                    }
                    .frame(height: 6)
                    .padding(.horizontal, 30)

                    // Time labels
                    HStack {
                        Text(timeString(elapsedSeconds))
                        Spacer()
                        Text("-\(timeString(timeRemaining))")
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 30)
                }

                // Controls
                HStack(spacing: 48) {
                    // Rewind 10 s
                    Button {
                        elapsedSeconds = max(0, elapsedSeconds - 10)
                    } label: {
                        Image(systemName: "gobackward.10")
                            .font(.system(size: 28))
                            .foregroundColor(.secondary)
                    }

                    // Play / Pause
                    Button {
                        togglePlayback()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(item.category.accentColor)
                                .frame(width: 72, height: 72)
                                .shadow(color: item.category.accentColor.opacity(0.45),
                                        radius: 14, x: 0, y: 6)

                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                                .offset(x: isPlaying ? 0 : 2)
                        }
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPlaying)

                    // Forward 10 s
                    Button {
                        elapsedSeconds = min(item.durationSeconds, elapsedSeconds + 10)
                        if elapsedSeconds >= item.durationSeconds { stopPlayback() }
                    } label: {
                        Image(systemName: "goforward.10")
                            .font(.system(size: 28))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 20)

                Spacer(minLength: 40)
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .onDisappear { stopPlayback() }
    }

    // MARK: - Playback helpers
    private func togglePlayback() {
        if isPlaying {
            pausePlayback()
        } else {
            startPlayback()
        }
    }

    private func startPlayback() {
        guard elapsedSeconds < item.durationSeconds else {
            elapsedSeconds = 0
            return
        }
        isPlaying = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                elapsedSeconds += 1
                if elapsedSeconds >= item.durationSeconds {
                    stopPlayback()
                }
            }
        }
    }

    private func pausePlayback() {
        isPlaying = false
        timer?.invalidate()
        timer = nil
    }

    private func stopPlayback() {
        isPlaying = false
        timer?.invalidate()
        timer = nil
    }
}

// ─────────────────────────────────────────────
// MARK: - Preview
// ─────────────────────────────────────────────
#Preview {
    ResourcesView()
}
