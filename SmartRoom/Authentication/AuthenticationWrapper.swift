import SwiftUI

struct AuthenticationWrapper: View {

    @State private var isLoggedIn = false
    @State private var isCheckingAuth = true
    @State private var showingTokenExpiredAlert = false
    @Environment(\.scenePhase) private var scenePhase // Detect app lifecycle

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
            print("AuthenticationWrapper appeared")
            setupTokenExpiryCallback()
            checkAuthenticationStatus()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            // Khi app trở về foreground (active), check lại token
            if newPhase == .active {
                print("App became ACTIVE - Checking auth again")
                // Nếu đang ở LoginView và có token, check lại
                if !isLoggedIn && !isCheckingAuth {
                    // Có thể user đã kill app rồi mở lại
                    isCheckingAuth = true
                    checkAuthenticationStatus()
                }
            }
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
        print("\n===== APP OPENED - CHECKING AUTH =====")
        print("Timestamp: \(Date())")
        
        // In ra debug info
        TokenManager.shared.printDebugInfo()

        // Kiểm tra token trong Keychain
        guard let token = TokenManager.shared.getToken(), !token.isEmpty else {
            print("No token found in Keychain")
            print("Showing LoginView")
            print("=========================================\n")
            isLoggedIn = false
            isCheckingAuth = false
            return
        }
        
        // Lấy API URL đã lưu để validate token
        guard let apiURL = TokenManager.shared.getAPIURL(), !apiURL.isEmpty else {
            print("No API URL found in UserDefaults")
            print("Clearing token and showing LoginView")
            TokenManager.shared.clearToken() // Clear token vì không có API URL
            print("=========================================\n")
            isLoggedIn = false
            isCheckingAuth = false
            return
        }
        
        // Set lại API URL cho service
        SmartRoomAPIService.shared.setBaseURL(apiURL)
        print("Found both token and API URL")
        print("Validating token with server...")

        Task {
            let valid = await validateTokenWithServer(token)
            await MainActor.run {
                self.isLoggedIn = valid
                self.isCheckingAuth = false
                if !valid {
                    print("Token validation FAILED")
                    print("Clearing token and showing LoginView")
                    TokenManager.shared.clearToken()
                } else {
                    print("Token validation SUCCESS")
                    print("Auto-login to HomeScreen")
                }
                print("=========================================\n")
            }
        }
    }

    private func validateTokenWithServer(_ token: String) async -> Bool {
        do {
            // Use the API URL from SmartRoomAPIService instead of hardcoded URL
            let baseURL = SmartRoomAPIService.shared.getBaseURL()
            guard let url = URL(string: "\(baseURL)/floors") else {
                print("Invalid API URL")
                return false
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse {
                print("Token validation status: \(http.statusCode)")
                return http.statusCode == 200
            }
            return false

        } catch {
            print("Token validation failed: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Callbacks
    private func handleLoginSuccess() {
        print("Login success")
        isLoggedIn = true
    }

    private func handleLogout() {
        print("User logout")
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
