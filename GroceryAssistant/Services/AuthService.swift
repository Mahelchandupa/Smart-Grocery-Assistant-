import FirebaseAuth

// AuthService for Firebase authentication operations
struct AuthService {
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
    
    static func signIn(email: String, password: String) async throws -> FirebaseAuth.User {
        let authResult = try await Auth.auth().signIn(
            withEmail: email,
            password: password
        )
        return authResult.user
    }
    
    static func signOut() throws {
        try Auth.auth().signOut()
    }
}
