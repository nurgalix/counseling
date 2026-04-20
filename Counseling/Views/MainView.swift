import SwiftUI

struct MainView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        TabView {
            // Chat Tab
            NavigationStack {
                ChatHistoryView()
            }
            .tabItem {
                Image(systemName: "message.fill")
                Text("Chat")
            }

            // Schedule Tab
            SchedulingView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Schedule")
                }

            // Resources Tab
            ResourcesView()
                .tabItem {
                    Image(systemName: "leaf.fill")
                    Text("Resources")
                }

            // Profile Tab
            SettingsView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
        }
    }
}

#Preview {
    MainView().environmentObject(AuthManager())
}
