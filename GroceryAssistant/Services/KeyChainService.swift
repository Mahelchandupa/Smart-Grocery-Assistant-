import Security
import Foundation

/// A service class that provides methods for securely storing and retrieving user credentials
/// in the iOS Keychain. This service is primarily used to support biometric authentication
/// by storing credentials that can be retrieved after successful biometric verification.
class KeychainService {
    /// Saves user credentials (email and password) to the iOS Keychain.
    ///
    /// The credentials are stored as a single string in the format "email:password"
    /// and associated with the key "userCredentials".
    ///
    /// - Parameters:
    ///   - email: The user's email address
    ///   - password: The user's password
    static func saveCredentials(email: String, password: String) {
        let credentials = "\(email):\(password)"
        let data = credentials.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "userCredentials",
            kSecValueData as String: data
        ]
        
        // Remove any existing credentials before adding new ones
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    /// Retrieves user credentials from the iOS Keychain.
    ///
    /// - Returns: A tuple containing the user's email and password if credentials are found,
    ///   or nil if no credentials are stored or if retrieval fails
    static func getCredentials() -> (email: String, password: String)? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "userCredentials",
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess, let data = result as? Data,
           let credentials = String(data: data, encoding: .utf8) {
            let parts = credentials.split(separator: ":")
            if parts.count == 2 {
                return (String(parts[0]), String(parts[1]))
            }
        }
        
        return nil
    }
    
    /// Removes all stored credentials from the iOS Keychain.
    ///
    /// This method is typically called when a user logs out or disables biometric authentication.
    static func clearCredentials() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "userCredentials"
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    /// Checks if biometric authentication is enabled for the current user.
    ///
    /// Biometric authentication is considered enabled if there are credentials
    /// stored in the Keychain that can be retrieved after biometric verification.
    ///
    /// - Returns: A boolean indicating whether biometric authentication is enabled
    static func isBiometricsEnabled() -> Bool {
        return getCredentials() != nil
    }
}

