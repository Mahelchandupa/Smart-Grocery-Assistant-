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
    /// Unique identifier for the user (from Firebase Auth)
    let id: String
    
    /// User's first name
    let firstName: String
    
    /// User's last name
    let lastName: String
    
    /// User's email address
    let email: String
    
    /// User's phone number
    let phone: String
    
    /// Whether biometric authentication is enabled for this user
    let enableBiometrics: Bool
    
    /// Optional URL or reference to the user's avatar/profile picture
    var avatar: String?
    
    /// Optional string representing when the user joined
    var memberSince: String?
    
    /// Creates a User instance from a Firebase user and additional Firestore data.
    /// - Parameters:
    ///   - firebaseUser: The Firebase Auth user object
    ///   - userData: Additional user data from Firestore
    /// - Returns: A fully populated User object
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
    /// User's email address
    let email: String
    
    /// User's password
    let password: String
    
    /// Whether to remember credentials for biometric login
    let rememberMe: Bool
}

/// Model representing a sign-up request with user information.
struct SignUpRequest {
    /// User's first name
    let firstName: String
    
    /// User's last name
    let lastName: String
    
    /// User's email address
    let email: String
    
    /// User's password
    let password: String
    
    /// User's phone number
    let phoneNumber: String
    
    /// Whether to enable biometric authentication
    let enableBiometrics: Bool?
}

/// Enumeration of authentication-related errors.
enum AuthError: LocalizedError {
    /// Error case for when a user is not authenticated
    case notAuthenticated

    /// Localized description of the error
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You are not authenticated. Please sign in."
        }
    }
}
