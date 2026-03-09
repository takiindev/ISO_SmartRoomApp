// TokenManager.swift
import Foundation

class TokenManager {
    static let shared = TokenManager()
    
    private let keychain = KeychainManager.shared
    private let serviceName = "com.smartroom.app"
    
    private init() {
        // Migration: Chuyển dữ liệu từ UserDefaults sang Keychain nếu có
        migrateToKeychain()
    }
    
    // MARK: - Keys
    private let tokenKey = "authToken"
    private let tokenBackupKey = "authToken_backup" // Backup trong UserDefaults
    private let usernameKey = "savedUsername"
    private let passwordKey = "savedPassword"
    private let apiURLKey = "savedAPIURL"
    private let userGroupsKey = "userGroups"
    private let currentUsernameKey = "currentUsername"
    
    // MARK: - Migration
    private func migrateToKeychain() {
        // Chuyển token từ UserDefaults sang Keychain
        if let oldToken = UserDefaults.standard.string(forKey: tokenKey) {
            keychain.save(oldToken, service: serviceName, account: tokenKey)
            UserDefaults.standard.set(oldToken, forKey: tokenBackupKey) // Lưu backup
            UserDefaults.standard.removeObject(forKey: tokenKey)
            UserDefaults.standard.synchronize()
            print("Migrated token to Keychain + UserDefaults backup")
        }
        
        // Chuyển password từ UserDefaults sang Keychain
        if let oldPassword = UserDefaults.standard.string(forKey: passwordKey) {
            keychain.save(oldPassword, service: serviceName, account: passwordKey)
            UserDefaults.standard.removeObject(forKey: passwordKey)
            UserDefaults.standard.synchronize()
            print("Migrated password to Keychain")
        }
    }
    
    // MARK: - Token Management (Keychain)
    func saveToken(_ token: String) {
        // LƯU VÀO KEYCHAIN (Primary)
        let keychainSuccess = keychain.save(token, service: serviceName, account: tokenKey)
        
        // LƯU VÀO USERDEFAULTS (Backup)
        UserDefaults.standard.set(token, forKey: tokenBackupKey)
        UserDefaults.standard.synchronize()
        
        if keychainSuccess {
            print("TokenManager: Token SAVED to Keychain successfully")
            print("   Service: \(serviceName)")
            print("   Account: \(tokenKey)")
            print("   Token (first 20 chars): \(String(token.prefix(20)))...")
        } else {
            print("TokenManager: Keychain save failed, but saved to UserDefaults backup")
        }
        print("TokenManager: Token BACKUP saved to UserDefaults")
    }
    
    func getToken() -> String? {
        // ĐỌC TỪ KEYCHAIN (Primary)
        var token = keychain.getString(service: serviceName, account: tokenKey)
        
        if let token = token {
            print("TokenManager: Token RETRIEVED from Keychain")
            print("   Token exists: true")
            print("   Token length: \(token.count)")
            print("   Token (first 20 chars): \(String(token.prefix(20)))...")
            return token
        }
        
        // FALLBACK: ĐỌC TỪ USERDEFAULTS (Backup)
        token = UserDefaults.standard.string(forKey: tokenBackupKey)
        if let token = token {
            print("TokenManager: Token retrieved from UserDefaults BACKUP")
            print("   Token exists: true")
            print("   Token length: \(token.count)")
            
            // Thử lưu lại vào Keychain
            _ = keychain.save(token, service: serviceName, account: tokenKey)
            return token
        }
        
        print("TokenManager: NO token found in Keychain OR UserDefaults")
        return nil
    }
    
    func clearToken() {
        // Xóa cả Keychain và UserDefaults
        let keychainSuccess = keychain.delete(service: serviceName, account: tokenKey)
        UserDefaults.standard.removeObject(forKey: tokenBackupKey)
        UserDefaults.standard.synchronize()
        
        if keychainSuccess {
            print("TokenManager: Token DELETED from Keychain")
        }
        print("TokenManager: Token BACKUP deleted from UserDefaults")
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
    
    // MARK: - API URL Management
    func saveAPIURL(_ url: String) {
        UserDefaults.standard.set(url, forKey: apiURLKey)
        UserDefaults.standard.synchronize() // Force sync
        print("TokenManager: API URL SAVED to UserDefaults")
        print("   URL: \(url)")
    }
    
    func getAPIURL() -> String? {
        let url = UserDefaults.standard.string(forKey: apiURLKey)
        if let url = url {
            print("TokenManager: API URL RETRIEVED from UserDefaults")
            print("   URL: \(url)")
        } else {
            print("TokenManager: NO API URL found in UserDefaults")
        }
        return url
    }
    
    func clearAPIURL() {
        UserDefaults.standard.removeObject(forKey: apiURLKey)
    }
    
    // MARK: - Remember Me: Credentials
    func saveCredentials(username: String, password: String, apiURL: String) {
        // Username lưu trong UserDefaults (không nhạy cảm)
        UserDefaults.standard.set(username, forKey: usernameKey)
        
        // Password lưu trong Keychain (nhạy cảm)
        _ = keychain.save(password, service: serviceName, account: passwordKey)
        
        print("Remember Me: Saved credentials")
    }
    
    func getSavedCredentials() -> (username: String, password: String, apiURL: String)? {
        guard
            let username = UserDefaults.standard.string(forKey: usernameKey),
            let password = keychain.getString(service: serviceName, account: passwordKey),
            let apiURL = getAPIURL() // Lấy từ API URL đã lưu
        else { return nil }
        
        return (username, password, apiURL)
    }
    
    func clearCredentials() {
        UserDefaults.standard.removeObject(forKey: usernameKey)
        _ = keychain.delete(service: serviceName, account: passwordKey)
        print("Remember Me: Cleared credentials")
    }
    
    // MARK: - Logout toàn cục
    var onLogout: (() -> Void)?
    
    func logout() {
        // Xóa token (phiên đăng nhập)
        clearToken()
        
        // Xóa dữ liệu session
        clearGroups()
        clearCurrentUsername()
        
        // GIỮ LẠI: API URL và Remember Me credentials
        // Để user không phải nhập lại khi đăng nhập lần sau
        
        print("Logged out - Token cleared, API URL & credentials preserved")
        
        DispatchQueue.main.async {
            self.onLogout?()
        }
    }
    
    // Xóa TOÀN BỘ dữ liệu (bao gồm cả Remember Me)
    func clearAllData() {
        clearToken()
        clearGroups()
        clearCurrentUsername()
        clearAPIURL()
        clearCredentials()
        
        // Xóa luôn backup
        UserDefaults.standard.removeObject(forKey: tokenBackupKey)
        UserDefaults.standard.synchronize()
        
        print("Cleared all data including Remember Me credentials and backups")
    }
    
    // MARK: - Helper
    func isLoggedIn() -> Bool {
        return getToken() != nil
    }
    
    // MARK: - Debug
    func printDebugInfo() {
        print("\n===== TOKEN MANAGER DEBUG INFO =====")
        print("Token exists: \(getToken() != nil)")
        print("API URL: \(getAPIURL() ?? "nil")")
        print("Current Username: \(getCurrentUsername() ?? "nil")")
        print("Groups: \(getGroups()?.joined(separator: ", ") ?? "nil")")
        print("Remember Me credentials: \(getSavedCredentials() != nil)")
        print("=========================================\n")
    }
}
