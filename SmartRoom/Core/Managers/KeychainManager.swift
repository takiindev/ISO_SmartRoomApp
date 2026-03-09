// KeychainManager.swift
import Foundation
import Security

class KeychainManager {
    static let shared = KeychainManager()
    
    private init() {}
    
    // MARK: - Save to Keychain
    @discardableResult
    func save(_ data: Data, service: String, account: String) -> Bool {
        // Xóa item cũ nếu có
        _ = delete(service: service, account: account)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            // Thay đổi accessibility để luôn truy cập được khi device unlock
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            print("Keychain: Saved \(account) successfully")
            return true
        } else {
            print("Keychain: Failed to save \(account). Status: \(status)")
            if status == errSecDuplicateItem {
                print("   Reason: Duplicate item (should not happen after delete)")
            } else if status == errSecAuthFailed {
                print("   Reason: Authentication failed")
            }
            return false
        }
    }
    
    @discardableResult
    func save(_ string: String, service: String, account: String) -> Bool {
        guard let data = string.data(using: .utf8) else { return false }
        return save(data, service: service, account: account)
    }
    
    // MARK: - Get from Keychain
    func get(service: String, account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess {
            print("Keychain: Retrieved \(account) successfully")
            return result as? Data
        } else if status == errSecItemNotFound {
            print("Keychain: \(account) not found")
            return nil
        } else {
            print("Keychain: Failed to retrieve \(account). Status: \(status)")
            return nil
        }
    }
    
    func getString(service: String, account: String) -> String? {
        guard let data = get(service: service, account: account) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    @discardableResult
    // MARK: - Delete from Keychain
    func delete(service: String, account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess || status == errSecItemNotFound {
            print("Keychain: Deleted \(account)")
            return true
        } else {
            print("Keychain: Failed to delete \(account). Status: \(status)")
            return false
        }
    }
    
    @discardableResult
    // MARK: - Clear all items for service
    func clearAll(service: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess || status == errSecItemNotFound {
            print("Keychain: Cleared all items for service: \(service)")
            return true
        } else {
            print("Keychain: Failed to clear service: \(service). Status: \(status)")
            return false
        }
    }
}
