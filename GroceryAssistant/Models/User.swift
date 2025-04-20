//
//  User.swift
//  GroceryAssistant
//
//  Created by sasiri rukshan nanayakkara on 3/31/25.
//

import SwiftUI
import Firebase
import FirebaseAuth
import LocalAuthentication
import FirebaseFirestore

// User model - represents our app's user data structure
struct User {
    let id: String
    let firstName: String
    let lastName: String
    let email: String
    let phone: String
    let enableBiometrics: Bool
    var avatar: String?
    var memberSince: String?
    
    // Create User from FirebaseAuth.User and additional data
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


// Request models
struct SignInRequest {
    let email: String
    let password: String
    let rememberMe: Bool
}

struct SignUpRequest {
    let firstName: String
    let lastName: String
    let email: String
    let password: String
    let phoneNumber: String
    let enableBiometrics: Bool?
}


enum AuthError: LocalizedError {
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You are not authenticated. Please sign in."
        }
    }
}
