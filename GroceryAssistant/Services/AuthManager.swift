import SwiftUI
import Firebase
import FirebaseAuth
import LocalAuthentication
import FirebaseFirestore

// Main AuthManager class
class AuthManager: ObservableObject {
    @Published var currentFirebaseUser: FirebaseAuth.User?
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var authError: String?
    
    // We'll make this optional since it might not always be needed
    var navPath: Binding<NavigationPath>?
    
    init() {
        setupAuthListener()
    }
    
    convenience init(navPath: Binding<NavigationPath>) {
        self.init()
        self.navPath = navPath
    }
    
    private func setupAuthListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentFirebaseUser = user
            self?.isAuthenticated = user != nil
            
            if let user = user {
                // Fetch additional user data when auth state changes
                Task {
                    do {
                        let userData = try await FirestoreService.getUserData(uid: user.uid)
                        DispatchQueue.main.async {
                            self?.currentUser = User.from(firebaseUser: user, userData: userData)
                        }
                    } catch {
                        print("Error fetching user data: \(error.localizedDescription)")
                    }
                }
            } else {
                self?.currentUser = nil
            }
        }
    }
    
    // Sign In Method with async/await
    func signIn(with request: SignInRequest) async throws {
        do {
            // Sign in with Firebase
            let firebaseUser = try await AuthService.signIn(
                email: request.email,
                password: request.password
            )
            
            // If "remember me" is selected, save credentials for biometric login
            if request.rememberMe {
                _ = KeychainService.saveCredentials(
                    email: request.email,
                    password: request.password
                )
            }
            
            // Fetch user data
            let userData = try await FirestoreService.getUserData(uid: firebaseUser.uid)
            
            // Update our current user
            DispatchQueue.main.async {
                self.currentFirebaseUser = firebaseUser
                self.currentUser = User.from(firebaseUser: firebaseUser, userData: userData)
            }
        } catch {
            DispatchQueue.main.async {
                self.authError = self.handleError(error)
            }
            throw error
        }
    }
    
    // Sign In Method with completion handler (for biometric auth)
    func signIn(with request: SignInRequest, completion: @escaping (Bool, String?) -> Void) {
        Task {
            do {
                try await signIn(with: request)
                completion(true, nil)
            } catch {
                completion(false, handleError(error))
            }
        }
    }
    
    // Sign Up Method
    func signUp(with request: SignUpRequest) async throws {
        do {
            let userData: [String: Any] = [
                "firstName": request.firstName,
                "lastName": request.lastName,
                "email": request.email,
                "phoneNumber": request.phoneNumber,
                "enableBiometrics": request.enableBiometrics ?? false,
                "createdAt": FieldValue.serverTimestamp()
            ]
            
            // Sign up with Firebase
            let firebaseUser = try await AuthService.signUp(
                email: request.email,
                password: request.password,
                userData: userData
            )
            
            // If biometrics enabled, save credentials
            if request.enableBiometrics == true {
                _ = KeychainService.saveCredentials(
                    email: request.email,
                    password: request.password
                )
            }
            
            // Update our current user
            DispatchQueue.main.async {
                self.currentFirebaseUser = firebaseUser
                self.currentUser = User.from(firebaseUser: firebaseUser, userData: userData)
            }
        } catch {
            DispatchQueue.main.async {
                self.authError = self.handleError(error)
            }
            throw error
        }
    }
    
    // Sign Out Method
    func signOut() throws {
        do {
            try AuthService.signOut()
        } catch {
            DispatchQueue.main.async {
                self.authError = self.handleError(error)
            }
            throw error
        }
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
     
    // ------------- Firestore Methods -------------- //

    func createList(_ list: ShoppingList) async throws {
        guard let userId = currentFirebaseUser?.uid else { throw AuthError.notAuthenticated }
        try await FirestoreService.createList(userId: userId, list: list)
    }
    
    func getUserLists() async throws -> [ShoppingList] {
        guard let userId = currentFirebaseUser?.uid else { throw AuthError.notAuthenticated }
        return try await FirestoreService.getUserLists(userId: userId)
    }

    func getAllItems() async throws -> [ShoppingItem] {
        guard let userId = currentFirebaseUser?.uid else { throw AuthError.notAuthenticated }
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
    }
}

// Extension to create an error alert when needed
extension View {
    func authErrorAlert(authManager: AuthManager) -> some View {
        alert(isPresented: .constant(authManager.authError != nil)) {
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
