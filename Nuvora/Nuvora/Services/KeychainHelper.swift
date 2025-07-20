import Foundation
import Security

/// A secure keychain wrapper for storing sensitive data like Supabase credentials
class KeychainHelper {
    static let shared = KeychainHelper()
    
    private init() {}
    
    private let service = "com.nuvora.app"
    
    enum KeychainError: Error {
        case itemNotFound
        case duplicateItem
        case invalidItemFormat
        case unexpectedStatus(OSStatus)
    }
    
    // MARK: - Store Data
    func store(_ data: Data, for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete any existing item first
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    func store(_ string: String, for key: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw KeychainError.invalidItemFormat
        }
        try store(data, for: key)
    }
    
    // MARK: - Retrieve Data
    func retrieve(for key: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unexpectedStatus(status)
        }
        
        guard let data = result as? Data else {
            throw KeychainError.invalidItemFormat
        }
        
        return data
    }
    
    func retrieveString(for key: String) throws -> String {
        let data = try retrieve(for: key)
        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidItemFormat
        }
        return string
    }
    
    // MARK: - Delete Data
    func delete(for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    // MARK: - Check if item exists
    func exists(for key: String) -> Bool {
        do {
            _ = try retrieve(for: key)
            return true
        } catch {
            return false
        }
    }
}

// MARK: - Convenience methods for Supabase credentials
extension KeychainHelper {
    private enum SupabaseKeys {
        static let url = "supabase_url"
        static let anonKey = "supabase_anon_key"
        static let accessToken = "supabase_access_token"
        static let refreshToken = "supabase_refresh_token"
    }
    
    func storeSupabaseCredentials(url: String, anonKey: String) throws {
        try store(url, for: SupabaseKeys.url)
        try store(anonKey, for: SupabaseKeys.anonKey)
    }
    
    func getSupabaseURL() throws -> String {
        try retrieveString(for: SupabaseKeys.url)
    }
    
    func getSupabaseAnonKey() throws -> String {
        try retrieveString(for: SupabaseKeys.anonKey)
    }
    
    func storeAccessToken(_ token: String) throws {
        try store(token, for: SupabaseKeys.accessToken)
    }
    
    func getAccessToken() throws -> String {
        try retrieveString(for: SupabaseKeys.accessToken)
    }
    
    func storeRefreshToken(_ token: String) throws {
        try store(token, for: SupabaseKeys.refreshToken)
    }
    
    func getRefreshToken() throws -> String {
        try retrieveString(for: SupabaseKeys.refreshToken)
    }
    
    func clearSupabaseTokens() {
        try? delete(for: SupabaseKeys.accessToken)
        try? delete(for: SupabaseKeys.refreshToken)
    }
}