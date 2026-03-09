import SwiftUI
import Foundation

// MARK: - Login ViewModel (MVVM)
@MainActor
class LoginViewModel: ObservableObject {
    // Published properties for View binding
    @Published var apiURL: String = "http://192.168.2.29:8080/api/v1"
    @Published var emailOrUsername: String = ""
    @Published var password: String = ""
    @Published var isPasswordVisible: Bool = false
    @Published var rememberMe: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    @Published var showErrorAlert: Bool = false
    
    private let apiService = SmartRoomAPIService.shared
    private let tokenManager = TokenManager.shared
    
    init() {
        loadSavedCredentials()
    }
    
    // MARK: - Public Methods
    
    func login(onSuccess: @escaping () -> Void) {
        guard validateInputs() else { return }
        
        apiService.setBaseURL(apiURL)
        isLoading = true
        
        Task {
            do {
                let loginData = try await apiService.login(username: emailOrUsername, password: password)
                handleLoginSuccess(loginData: loginData, onSuccess: onSuccess)
            } catch let error as SmartRoomAPIError {
                handleAPIError(error)
            } catch {
                handleGenericError(error)
            }
        }
    }
    
    func loadSavedCredentials() {
        if let saved = tokenManager.getSavedCredentials() {
            emailOrUsername = saved.username
            password = saved.password
            apiURL = saved.apiURL
            rememberMe = true
        }
    }
    
    // MARK: - Private Methods
    
    private func validateInputs() -> Bool {
        guard !apiURL.isEmpty, !emailOrUsername.isEmpty, !password.isEmpty else {
            showError("Please enter API URL, username, and password")
            return false
        }
        
        guard let url = URL(string: apiURL),
              (url.scheme == "http" || url.scheme == "https") else {
            showError("Invalid API URL format. Please use http:// or https://")
            return false
        }
        
        return true
    }
    
    private func handleLoginSuccess(loginData: LoginTokenData, onSuccess: @escaping () -> Void) {
        isLoading = false
        
        print("\n===== LOGIN SUCCESS - SAVING DATA =====")
        print("Token received: \(String(loginData.token.prefix(20)))...")
        print("Username: \(loginData.username)")
        print("Groups: \(loginData.groups)")
        print("API URL: \(apiURL)")
        print("Remember Me: \(rememberMe)")
        
        // Lưu token và thông tin session (luôn lưu để giữ phiên đăng nhập)
        tokenManager.saveToken(loginData.token)
        tokenManager.saveGroups(loginData.groups)
        tokenManager.saveCurrentUsername(loginData.username)
        tokenManager.saveAPIURL(apiURL) // Lưu API URL để validate token khi mở lại app
        
        // Lưu credentials chỉ khi Remember Me được bật
        if rememberMe {
            tokenManager.saveCredentials(username: emailOrUsername, password: password, apiURL: apiURL)
        } else {
            tokenManager.clearCredentials()
        }
        
        print("All data saved successfully")
        print("=========================================\n")
        
        onSuccess()
    }
    
    private func handleAPIError(_ error: SmartRoomAPIError) {
        isLoading = false
        switch error {
        case .unauthorized:
            showError("Invalid username or password")
        case .networkError(let message):
            showError("Network error: \(message)")
        case .invalidResponse:
            showError("Invalid response from server. Please check the API URL.")
        case .tokenExpired:
            showError("Session expired")
        case .serverError(let message):
            showError("Server error: \(message)")
        }
    }
    
    private func handleGenericError(_ error: Error) {
        isLoading = false
        let errorMsg = error.localizedDescription
        
        if errorMsg.contains("Could not connect") || errorMsg.contains("timed out") {
            showError("Cannot connect to server at \(apiURL). Please check the URL and network connection.")
        } else if errorMsg.contains("The Internet connection appears to be offline") {
            showError("No internet connection. Please check your network.")
        } else {
            showError("Login failed: \(errorMsg)")
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showErrorAlert = true
    }
}
