import SwiftUI

struct SettingsIcon: View {
    let icon: String
    let color: Color
    
    var body: some View {
        Image(systemName: icon)
            .resizable()
            .scaledToFit()
            .frame(width: 16, height: 16) // Icon size
            .foregroundColor(.white)
            .padding(6)
            .background(color) // Colored background
            .cornerRadius(6)   // Corner radius
            .frame(width: 30, height: 30)
    }
}
