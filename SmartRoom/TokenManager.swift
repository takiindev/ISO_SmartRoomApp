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
    private let userGroupsKey = "userGroups"
    private let currentUsernameKey = "currentUsername"
    
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
    
    // MARK: - Groups Management
    func saveGroups(_ groups: [String]) {
        UserDefaults.standard.set(groups, forKey: userGroupsKey)
    }
    
    func getGroups() -> [String]? {
        UserDefaults.standard.stringArray(forKey: userGroupsKey)
    }
    
    func clearGroups() {
        UserDefaults.standard.removeObject(forKey: userGroupsKey)
    }
    
    // MARK: - Current Username Management
    func saveCurrentUsername(_ username: String) {
        UserDefaults.standard.set(username, forKey: currentUsernameKey)
    }
    
    func getCurrentUsername() -> String? {
        UserDefaults.standard.string(forKey: currentUsernameKey)
    }
    
    func clearCurrentUsername() {
        UserDefaults.standard.removeObject(forKey: currentUsernameKey)
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
        clearGroups()
        clearCurrentUsername()
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
