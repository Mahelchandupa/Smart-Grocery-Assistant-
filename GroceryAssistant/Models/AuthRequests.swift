//
//  AuthRequests.swift
//  GroceryAssistant
//
//  Created by sasiri rukshan nanayakkara on 3/30/25.
//

import Foundation

struct SignUpRequest: Codable {
    let firstName: String
    let lastName: String
    let email: String
    let password: String
    let phoneNumber: String
    let enableBiometrics: Bool?
}

struct SignInRequest: Codable {
    let email: String
    let password: String
    let rememberMe: Bool?
}
