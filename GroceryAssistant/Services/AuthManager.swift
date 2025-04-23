import SwiftUI
import Firebase
import FirebaseAuth
import LocalAuthentication
import FirebaseFirestore

/// AuthManager is responsible for handling all authentication-related operations in the app.
/// It manages user state, authentication flows, and provides methods for sign-in, sign-up,
/// and biometric authentication. The class also includes Firestore operations that require
/// authentication context.
class AuthManager: ObservableObject {
    /// The current Firebase User object, if a user is authenticated
    @Published var currentFirebaseUser: FirebaseAuth.User?
    
    /// The application's user model that includes additional profile information
    /// beyond what Firebase Auth provides
    @Published var currentUser: User?

    /// A boolean value indicating whether a user is currently authenticated
    @Published var isAuthenticated = false

    /// The most recent authentication error message, if any
    @Published var authError: String?
    
    /// Optional navigation path for handling navigation after authentication events
    /// Make this optional since it might not always be needed
    var navPath: Binding<NavigationPath>?
    
    /// Initializes a new AuthManager and sets up Firebase authentication state listener
    init() {
        setupAuthListener()
    }
    
    /// Convenience initializer that takes a navigation path for routing after auth events
    /// - Parameter navPath: The navigation path binding to use for routing
    convenience init(navPath: Binding<NavigationPath>) {
        self.init()
        self.navPath = navPath
    }

    /// Sets up the Firebase authentication state change listener
    /// This listener updates the current user whenever authentication state changes  
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
    
    /// Signs in a user with the provided email and password
    /// - Parameter request: The sign-in request containing email, password, and remember me flag
    /// - Throws: An error if sign-in fails
    /// - Returns: Void
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
    
    /// Signs in a user with completion handler (used for biometric authentication)
    /// - Parameters:
    ///   - request: The sign-in request containing email, password, and remember me flag
    ///   - completion: Completion handler called with success status and optional error message
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
    
    /// Creates a new user account with the provided details
    /// - Parameter request: The sign-up request containing user details and password
    /// - Throws: An error if sign-up fails
    /// - Returns: Void
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
    
    /// Signs out the current user
    /// - Throws: An error if sign-out fails
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
    
    /// Authenticates the user using device biometrics (Face ID or Touch ID)
    /// - Parameter completion: Completion handler called with success status and optional error message
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
     
    // MARK: - Firestore Methods
    
    /// Creates a new shopping list for the current user
    /// - Parameter list: The shopping list to create
    /// - Throws: AuthError.notAuthenticated if no user is signed in, or any Firestore errors
    func createList(_ list: ShoppingList) async throws {
        guard let userId = currentFirebaseUser?.uid else { throw AuthError.notAuthenticated }
        try await FirestoreService.createList(userId: userId, list: list)
    }
    
    /// Retrieves all shopping lists for the current user
    /// - Throws: AuthError.notAuthenticated if no user is signed in, or any Firestore errors
    /// - Returns: An array of ShoppingList objects
    func getUserLists() async throws -> [ShoppingList] {
        guard let userId = currentFirebaseUser?.uid else { throw AuthError.notAuthenticated }
        return try await FirestoreService.getUserLists(userId: userId)
    }

    /// Retrieves all shopping items across all lists for the current user
    /// - Throws: AuthError.notAuthenticated if no user is signed in, or any Firestore errors
    /// - Returns: An array of ShoppingItem objects
    func getAllItems() async throws -> [ShoppingItem] {
        guard let userId = currentFirebaseUser?.uid else { throw AuthError.notAuthenticated }
        return try await FirestoreService.getAllItems(userId: userId)
    }

    /// Translates authentication errors into user-friendly messages
    /// - Parameter error: The original error from Firebase Auth
    /// - Returns: A user-friendly error message
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

/// Extension to add an error alert modifier to any SwiftUI View
extension View {
    /// Adds an authentication error alert to a view
    /// - Parameter authManager: The AuthManager instance to monitor for errors
    /// - Returns: A modified view with an alert that displays authentication errors
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
