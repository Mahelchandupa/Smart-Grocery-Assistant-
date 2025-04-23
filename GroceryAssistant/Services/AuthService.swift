import FirebaseAuth

/// A service that handles Firebase authentication operations.
/// This struct provides static methods for common authentication tasks such as
/// sign-up, sign-in, and sign-out, abstracting the Firebase Authentication API.
struct AuthService {
    /// Creates a new user account with the provided email and password.
    /// Also saves additional user data to Firestore.
    ///
    /// - Parameters:
    ///   - email: The user's email address
    ///   - password: The user's password
    ///   - userData: Additional user data to store in Firestore
    /// - Throws: FirebaseAuth errors if account creation fails or FirestoreService errors
    ///   if saving additional user data fails
    /// - Returns: The Firebase User object for the newly created user
    static func signUp(
        email: String,
        password: String,
        userData: [String: Any]
    ) async throws -> FirebaseAuth.User {
        let authResult = try await Auth.auth().createUser(
            withEmail: email,
            password: password
        )
        
        // Save additional user data
        try await FirestoreService.saveUserData(
            uid: authResult.user.uid,
            data: userData
        )
        
        return authResult.user
    }
    
    /// Signs in a user with the provided email and password.
    ///
    /// - Parameters:
    ///   - email: The user's email address
    ///   - password: The user's password
    /// - Throws: FirebaseAuth errors if sign-in fails
    /// - Returns: The Firebase User object for the authenticated user
    static func signIn(email: String, password: String) async throws -> FirebaseAuth.User {
        let authResult = try await Auth.auth().signIn(
            withEmail: email,
            password: password
        )
        return authResult.user
    }
    
    /// Signs out the currently authenticated user.
    ///
    /// - Throws: FirebaseAuth errors if sign-out fails
    static func signOut() throws {
        try Auth.auth().signOut()
    }
}
