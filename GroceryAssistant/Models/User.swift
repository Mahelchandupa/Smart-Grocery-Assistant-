import SwiftUI
import Firebase
import FirebaseAuth
import LocalAuthentication
import FirebaseFirestore

// MARK: - User Model

/// Represents a user in the application with profile information.
/// This model combines Firebase authentication data with additional user information
/// stored in Firestore.
struct User {
    let id: String
    let firstName: String
    let lastName: String
    let email: String
    let phone: String
    let enableBiometrics: Bool
    var avatar: String? 
    var memberSince: String?
    
    static func from(firebaseUser: FirebaseAuth.User, userData: [String: Any]) -> User {
        return User(
            id: firebaseUser.uid,
            firstName: userData["firstName"] as? String ?? "",
            lastName: userData["lastName"] as? String ?? "",
            email: userData["email"] as? String ?? firebaseUser.email ?? "",
            phone: userData["phoneNumber"] as? String ?? "",
            enableBiometrics: userData["enableBiometrics"] as? Bool ?? false,
            avatar: userData["avatar"] as? String,
            memberSince: userData["memberSince"] as? String
        )
    }
}

// MARK: - Authentication Request Models

/// Model representing a sign-in request with credentials.
struct SignInRequest {
    let email: String
    let password: String
    let rememberMe: Bool
}

/// Model representing a sign-up request with user information.
struct SignUpRequest {
    let firstName: String
    let lastName: Strin
    let email: String
    let password: String
    let phoneNumber: String
    let enableBiometrics: Bool?
}

/// Enumeration of authentication-related errors.
enum AuthError: LocalizedError {
    /// Error case for when a user is not authenticated
    case notAuthenticated

    /// description of the error
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You are not authenticated. Please sign in."
        }
    }
}
