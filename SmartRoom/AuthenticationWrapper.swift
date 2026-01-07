import SwiftUI

struct AuthenticationWrapper: View {

    @State private var isLoggedIn = false
    @State private var isCheckingAuth = true
    @State private var showingTokenExpiredAlert = false

    var body: some View {
        ZStack {

            if isCheckingAuth {
                SplashScreen()

            } else if isLoggedIn {
                NavigationStack {
                    HomeScreen(onLogout: handleLogout)
                }

            } else {
                NavigationStack {
                    LoginView {
                        handleLoginSuccess()
                    }
                }
            }
        }
        .onAppear {
            setupTokenExpiryCallback()
            checkAuthenticationStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: .forceAuthenticationCheck)) { _ in
            checkAuthenticationStatus()
        }
        .alert("Session Expired", isPresented: $showingTokenExpiredAlert) {
            Button("OK") {
                forceLogout()
            }
        } message: {
            Text("Your session has expired. Please log in again.")
        }
    }

    // MARK: - Auth logic
    private func checkAuthenticationStatus() {
        print("🔐 Checking authentication status")

        guard let token = TokenManager.shared.getToken(), !token.isEmpty else {
            print("❌ No token found, forcing LoginView")
            isLoggedIn = false
            isCheckingAuth = false
            return
        }

        Task {
            let valid = await validateTokenWithServer(token)
            await MainActor.run {
                self.isLoggedIn = valid
                self.isCheckingAuth = false
                if !valid {
                    TokenManager.shared.clearToken()
                }
            }
        }
    }

    private func validateTokenWithServer(_ token: String) async -> Bool {
        do {
            let url = URL(string: "http://192.168.2.29:8080/api/v1/floors")!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse {
                print("🔐 Token validation status: \(http.statusCode)")
                return http.statusCode == 200
            }
            return false

        } catch {
            print("❌ Token validation failed: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Callbacks
    private func handleLoginSuccess() {
        print("✅ Login success")
        isLoggedIn = true
    }

    private func handleLogout() {
        print("🚪 User logout")
        TokenManager.shared.logout()
        isLoggedIn = false
    }

    private func setupTokenExpiryCallback() {
        SmartRoomAPIService.shared.onTokenExpired = {
            DispatchQueue.main.async {
                self.showingTokenExpiredAlert = true
            }
        }
    }

    private func forceLogout() {
        print("🚨 Force logout")
        TokenManager.shared.logout()
        isLoggedIn = false
        isCheckingAuth = false
    }
}
