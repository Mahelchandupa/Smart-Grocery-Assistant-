import SwiftUI
import Firebase
import FirebaseAuth
import LocalAuthentication
import FirebaseFirestore

class AuthManager: ObservableObject {
    @Published var currentUser: FirebaseAuth.User? // Explicitly using FirebaseAuth.User
    @Published var isAuthenticated = false
    @Published var authError: String?
    
    init() {
        // Listen for authentication state changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
            self?.isAuthenticated = user != nil
        }
    }

    // Sign In Method
    func signIn(with request: SignInRequest, completion: @escaping (Bool, String?) -> Void) {
        authError = nil
        
        Auth.auth().signIn(withEmail: request.email, password: request.password) { [weak self] authResult, error in
            if let error = error {
                let errorMessage = self?.handleError(error)
                self?.authError = errorMessage
                completion(false, errorMessage)
                return
            }
            
            // Store user preferences like rememberMe if needed
            if let rememberMe = request.rememberMe, rememberMe {
                UserDefaults.standard.set(request.email, forKey: "savedEmail")
            } else {
                UserDefaults.standard.removeObject(forKey: "savedEmail")
            }
            
            completion(true, nil)
        }
    }
    
    // Sign Up Method
    func signUp(with request: SignUpRequest, completion: @escaping (Bool, String?) -> Void) {
        authError = nil
        
        Auth.auth().createUser(withEmail: request.email, password: request.password) { [weak self] authResult, error in
            if let error = error {
                let errorMessage = self?.handleError(error)
                self?.authError = errorMessage
                completion(false, errorMessage)
                return
            }
            
            guard let user = authResult?.user else {
                completion(false, "Failed to get user information")
                return
            }
            
            // Create user profile in Firestore
            self?.createUserProfile(user: user, request: request) { success in
                if success {
                    if let enableBiometrics = request.enableBiometrics, enableBiometrics {
                        UserDefaults.standard.set(true, forKey: "biometricsEnabled")
                        
                        // Ensure KeychainService exists and works
                        KeychainService.saveCredentials(email: request.email, password: request.password)
                    }
                    
                    completion(true, nil)
                } else {
                    completion(false, "Failed to create user profile")
                }
            }
        }
    }
    
    // Sign Out Method
    func signOut() {
        do {
            try Auth.auth().signOut()
            isAuthenticated = false
            currentUser = nil
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
    
    // Biometric Authentication
    func authenticateWithBiometrics(completion: @escaping (Bool, String?) -> Void) {
        guard let credentials = KeychainService.getCredentials() else {
            completion(false, "No stored credentials for biometric login")
            return
        }
        
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Log in to your account"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, error in
                DispatchQueue.main.async {
                    if success {
                        self?.signIn(with: SignInRequest(
                            email: credentials.email,
                            password: credentials.password,
                            rememberMe: true
                        ), completion: completion)
                    } else {
                        completion(false, error?.localizedDescription ?? "Biometric authentication failed")
                    }
                }
            }
        } else {
            completion(false, "Biometric authentication not available")
        }
    }
    
    // Create User Profile
    private func createUserProfile(user: FirebaseAuth.User, request: SignUpRequest, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        
        db.collection("users").document(user.uid).setData([
            "firstName": request.firstName,
            "lastName": request.lastName,
            "email": request.email,
            "phoneNumber": request.phoneNumber,
            "createdAt": FieldValue.serverTimestamp(),
            "enabledBiometrics": request.enableBiometrics ?? false
        ]) { error in
            if let error = error {
                print("Error creating user profile: \(error.localizedDescription)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    // Handle Authentication Errors
    private func handleError(_ error: Error) -> String {
        let authError = error as NSError
        
        switch authError.code {
        case AuthErrorCode.wrongPassword.rawValue:
            return "Invalid email or password"
        case AuthErrorCode.invalidEmail.rawValue:
            return "Invalid email address"
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return "Email is already in use"
        case AuthErrorCode.weakPassword.rawValue:
            return "Password is too weak"
        case AuthErrorCode.userNotFound.rawValue:
            return "Account not found"
        case AuthErrorCode.networkError.rawValue:
            return "Network error. Please try again"
        default:
            return "An error occurred: \(error.localizedDescription)"
        }
    }
}
