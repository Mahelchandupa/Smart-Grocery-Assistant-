import Security
import Foundation

class KeychainService {
    static func saveCredentials(email: String, password: String) {
        let credentials = "\(email):\(password)"
        let data = credentials.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "userCredentials",
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary) // Remove existing item
        SecItemAdd(query as CFDictionary, nil)
    }
    
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
    
    static func clearCredentials() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "userCredentials"
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    // Add a method to check if biometrics is enabled for the current user
    static func isBiometricsEnabled() -> Bool {
        return getCredentials() != nil
    }
}

