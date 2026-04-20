import SwiftUI

// MARK: - Main view for counselors (Chat + Schedule + Profile)

struct CounselorMainView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        TabView {
            // Chat with students
            NavigationStack {
                CounselorChatListView()
            }
            .tabItem {
                Image(systemName: "message.fill")
                Text("Chat")
            }

            // Session management
            CounselorScheduleView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Schedule")
                }

            // Profile (reuse student settings view)
            SettingsView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
        }
    }
}

#Preview {
    CounselorMainView().environmentObject(AuthManager())
}
