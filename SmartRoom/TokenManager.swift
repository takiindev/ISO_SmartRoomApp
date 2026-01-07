// TokenManager.swift
import Foundation

class TokenManager {
    static let shared = TokenManager()
    
    private init() {}
    
    // MARK: - Keys
    private let tokenKey = "authToken"
    private let usernameKey = "savedUsername"
    private let passwordKey = "savedPassword"
    private let apiURLKey = "savedAPIURL"
    
    // MARK: - Token Management
    func saveToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: tokenKey)
    }
    
    func getToken() -> String? {
        UserDefaults.standard.string(forKey: tokenKey)
    }
    
    func clearToken() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
    }
    
    // MARK: - Remember Me: Credentials
    func saveCredentials(username: String, password: String, apiURL: String) {
        UserDefaults.standard.set(username, forKey: usernameKey)
        UserDefaults.standard.set(password, forKey: passwordKey)
        UserDefaults.standard.set(apiURL, forKey: apiURLKey)
    }
    
    func getSavedCredentials() -> (username: String, password: String, apiURL: String)? {
        guard
            let username = UserDefaults.standard.string(forKey: usernameKey),
            let password = UserDefaults.standard.string(forKey: passwordKey),
            let apiURL = UserDefaults.standard.string(forKey: apiURLKey)
        else { return nil }
        
        return (username, password, apiURL)
    }
    
    func clearCredentials() {
        UserDefaults.standard.removeObject(forKey: usernameKey)
        UserDefaults.standard.removeObject(forKey: passwordKey)
        UserDefaults.standard.removeObject(forKey: apiURLKey)
    }
    
    // MARK: - Logout toàn cục
    var onLogout: (() -> Void)?
    
    func logout() {
        clearToken()
        clearCredentials() // Xóa luôn credentials khi logout
        DispatchQueue.main.async {
            self.onLogout?()
        }
    }
    
    // MARK: - Helper
    func isLoggedIn() -> Bool {
        return getToken() != nil
    }
}
