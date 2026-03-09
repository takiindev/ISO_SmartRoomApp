import SwiftUI

// MARK: - Home Screen Wrapper
struct HomeScreen: View {
    let onLogout: () -> Void
    
    var body: some View {
        MainTabView(onLogout: onLogout)
    }
}

// MARK: - Preview
#Preview {
    HomeScreen(onLogout: {
        print("Logout")
    })
}
