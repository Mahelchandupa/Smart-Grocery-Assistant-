//
//  SignUpView.swift
//  GroceryAssistant

import SwiftUI
import LocalAuthentication

struct SignUpView: View {
    @Binding var navPath: NavigationPath
    @EnvironmentObject private var authManager: AuthManager
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var phoneNumber: String = ""
    @State private var enableBiometrics: Bool = false
    @State private var showPassword: Bool = false
    @State private var isLoading: Bool = false
    
    @State private var firstNameError: String? = nil
    @State private var lastNameError: String? = nil
    @State private var emailError: String? = nil
    @State private var passwordError: String? = nil
    @State private var phoneNumberError: String? = nil
    
    @State private var biometricType: BiometricType = .none
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ZStack {
                Color.green
                    .ignoresSafeArea()
                VStack {
                    HStack {
                        Button(action: {
                            // Go back to sign in
                            navPath.removeLast()
                        }) {
                            HStack {
                                Image(systemName: "arrow.left")
                                    .foregroundColor(.white)
                                    .font(.system(size: 20))
                            }
                        }
                        .padding(.trailing, 8)
                        
                        Text("Sign Up")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 8)
                .padding(.horizontal, 16)
            }
            .frame(height: 50)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Title section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Create Account")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color(.darkGray))
                        
                        Text("Sign up to start organizing your shopping lists")
                            .font(.subheadline)
                            .foregroundColor(Color.gray)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 16)
                    
                    // Form
                    VStack(spacing: 16) {
                        // First Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("First Name")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color(.darkGray))
                            
                            TextField("Enter your first name", text: $firstName)
                                .padding(12)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(firstNameError != nil ? Color.red : Color.clear, lineWidth: 1)
                                )
                            
                            if let error = firstNameError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // Last Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Last Name")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color(.darkGray))
                            
                            TextField("Enter your last name", text: $lastName)
                                .padding(12)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(lastNameError != nil ? Color.red : Color.clear, lineWidth: 1)
                                )
                            
                            if let error = lastNameError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // Email
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color(.darkGray))
                            
                            TextField("Enter your email", text: $email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .padding(12)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(emailError != nil ? Color.red : Color.clear, lineWidth: 1)
                                )
                            
                            if let error = emailError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color(.darkGray))
                            
                            HStack {
                                if showPassword {
                                    TextField("Enter your password", text: $password)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                } else {
                                    SecureField("Enter your password", text: $password)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                }
                                
                                Button(action: {
                                    showPassword.toggle()
                                }) {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(passwordError != nil ? Color.red : Color.clear, lineWidth: 1)
                            )
                            
                            if let error = passwordError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            
                            Text("Must be at least 8 characters")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        // Phone Number
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Phone Number")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color(.darkGray))
                            
                            TextField("Enter your phone number", text: $phoneNumber)
                                .keyboardType(.phonePad)
                                .padding(12)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(phoneNumberError != nil ? Color.red : Color.clear, lineWidth: 1)
                                )
                            
                            if let error = phoneNumberError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // Biometric Authentication Option
                        if biometricType != .none {
                            Button(action: {
                                enableBiometrics.toggle()
                            }) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(enableBiometrics ? Color.green : Color.gray, lineWidth: 1.5)
                                            .frame(width: 24, height: 24)
                                        
                                        if enableBiometrics {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 14))
                                                .foregroundColor(.white)
                                                .frame(width: 24, height: 24)
                                                .background(Color.green)
                                                .cornerRadius(4)
                                        }
                                    }
                                    
                                    HStack(spacing: 8) {
                                        Image(systemName: "faceid")
                                            .font(.system(size: 22))
                                            .foregroundColor(.green)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Enable Biometric Login")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(Color(.darkGray))
                                            
                                            Text("Use Face ID to sign in")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.top, 8)
                        }
                        
                        // Sign Up Button
                        Button(action: handleSignUp) {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Sign Up")
                                    .font(.headline)
                                    .fontWeight(.bold)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(8)
                        .disabled(isLoading)
                        .padding(.top, 8)
                        .disabled(isLoading)
                        
                        // Error message form Firebase
                        if let errorMsg = authManager.authError {
                            Text(errorMsg)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.top, 8)
                        }
                        
                        // Already Have Account
                        HStack {
                            Text("Already have an account?")
                                .foregroundColor(.gray)
                            
                            Button(action: {
                                // Navigate to sign in
                                if navPath.count > 0 {
                                    navPath.removeLast()
                                }
                            }) {
                                Text("Sign In")
                                    .fontWeight(.medium)
                                    .foregroundColor(.green)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 32)
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .onAppear {
            checkBiometricType()
        }
        .navigationBarHidden(true)
    }
    
    private func checkBiometricType() {
    let context = LAContext()
    var error: NSError?
    
    if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
        switch context.biometryType {
        case .faceID: biometricType = .faceID
        case .touchID: biometricType = .touchID
        default: biometricType = .none
        }
    } else {
        biometricType = .none
    }
}
    
    private func validateEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func validatePassword(_ password: String) -> Bool {
        return password.count >= 8
    }
    
    private func validatePhoneNumber(_ phoneNumber: String) -> Bool {
        let phoneRegex = "^\\+?[0-9]{10,14}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: phoneNumber)
    }
    
    private func handleSignUp() {
        // Reset errors
        firstNameError = nil
        lastNameError = nil
        emailError = nil
        passwordError = nil
        phoneNumberError = nil
        
        var isValid = true
        
        // Validate first name
        if firstName.isEmpty {
            firstNameError = "First name is required"
            isValid = false
        }
        
        // Validate last name
        if lastName.isEmpty {
            lastNameError = "Last name is required"
            isValid = false
        }
        
        // Validate email
        if !validateEmail(email) {
            emailError = "Please enter a valid email"
            isValid = false
        }
        
        // Validate password
        if !validatePassword(password) {
            passwordError = "Password must be at least 8 characters"
            isValid = false
        }
        
        // Validate phone number
        if !validatePhoneNumber(phoneNumber) {
            phoneNumberError = "Please enter a valid phone number"
            isValid = false
        }
        
        if isValid {
            isLoading = true
            
            // Prepare the sign-up request
            let signUpRequest = SignUpRequest(
                firstName: firstName,
                lastName: lastName,
                email: email,
                password: password,
                phoneNumber: phoneNumber,
                enableBiometrics: enableBiometrics
            )
            
            // Call the AuthManager to handle Firebase authentication
            Task {
                isLoading = true
                do {
                    try await authManager.signUp(with: signUpRequest)
                    navPath.append(Route.signIn)
                } catch {
                    isLoading = false
                    let errorMessage = error.localizedDescription
                    if errorMessage.contains("email") {
                        emailError = errorMessage
                    } else if errorMessage.contains("password") {
                        passwordError = errorMessage
                    } else {
                        authManager.authError = errorMessage
                    }
                }
            }

        }
    }
}
