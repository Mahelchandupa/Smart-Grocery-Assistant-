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
        setupAuthListener()
    }
    
    private func setupAuthListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
            self?.isAuthenticated = user != nil
        }
    }
    
    // Sign In Methods  
    func signIn(with request: SignInRequest) async throws {
        currentUser = try await AuthService.signIn(
            email: request.email,
            password: request.password
        )
    }
    
    // Sign Up Methods
     func signUp(with request: SignUpRequest) async throws {
        let userData: [String: Any] = [
            "firstName": request.firstName,
            "lastName": request.lastName,
            "email": request.email,
            "phoneNumber": request.phoneNumber,
            "enableBiometrics": request.enableBiometrics ?? false
        ]
        
        currentUser = try await AuthService.signUp(
            email: request.email,
            password: request.password,
            userData: userData
        )
    }
    
    // Sign Out Method
     func signOut() throws {
        try AuthService.signOut()
    }
    
    // Biometric Authentication
    func authenticateWithBiometrics(completion: @escaping (Bool, String?) -> Void) {
        // Check if we have stored credentials
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
                        // User successfully authenticated with biometrics, now sign in with Firebase
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
    
    // Helper Methods
    private func createUserProfile(user: User, request: SignUpRequest, completion: @escaping (Bool) -> Void) {
        // Create a reference to Firestore
        let db = Firestore.firestore()
        
        // Create a user document with additional profile information
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
                return
            }
            
            // Profile created successfully
            completion(true)
        }
    }
    
     
    // ------------- Firestore Methods -------------- //

    func createList(_ list: ShoppingList) async throws {
        guard let userId = currentUser?.uid else { throw AuthError.notAuthenticated }
        try await FirestoreService.createList(userId: userId, list: list)
    }
    
    func getUserLists() async throws -> [ShoppingList] {
        guard let userId = currentUser?.uid else { throw AuthError.notAuthenticated }
        return try await FirestoreService.getUserLists(userId: userId)
    }

    func getAllItems() async throws -> [ShoppingItem] {
        guard let userId = currentUser?.uid else { throw AuthError.notAuthenticated }
        return try await FirestoreService.getAllItems(userId: userId)
    }

    // Error Handling
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
        .navigationBarHidden(true)
        .alert(isPresented: .constant(authManager.authError != nil)) {
            Alert(
                title: Text("Authentication Error"),
                message: Text(authManager.authError ?? "An unknown error occurred"),
                dismissButton: .default(Text("OK")) {
                    authManager.authError = nil
                }
            )
        }
    }
    
}
    
