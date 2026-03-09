import SwiftUI

// MARK: - Login Screen (Entry Point)
// This file exists for backward compatibility
// The actual implementation is in LoginView.swift and LoginViewModel.swift

struct LoginScreen: View {
    let onLoginSuccess: () -> Void
    
    var body: some View {
        LoginView(onLoginSuccess: onLoginSuccess)
    }
}

// MARK: - Preview
#Preview {
    LoginScreen(onLoginSuccess: {
        print("Login success")
    })
}
