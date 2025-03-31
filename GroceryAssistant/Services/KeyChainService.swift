store credentials
class KeychainService {
    static func saveCredentials(email: String, password: String) {
        // In a real app, you would implement proper Keychain storage
        // This is just for demonstration
        UserDefaults.standard.set(email, forKey: "biometric_email")
        // NEVER store passwords in UserDefaults in a real app
        // This is just for demonstration purposes
        UserDefaults.standard.set(password, forKey: "biometric_password")
    }
    
    static func getCredentials() -> (email: String, password: String)? {
        guard let email = UserDefaults.standard.string(forKey: "biometric_email"),
              let password = UserDefaults.standard.string(forKey: "biometric_password") else {
            return nil
        }
        
        return (email, password)
    }
    
    static func clearCredentials() {
        UserDefaults.standard.removeObject(forKey: "biometric_email")
        UserDefaults.standard.removeObject(forKey: "biometric_password")
    }
}