//
//  SignInView.swift
//  GroceryAssistant
//
//  Created by sasiri rukshan nanayakkara on 3/30/25.
//

import SwiftUI
import LocalAuthentication

struct SignInView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @State private var rememberMe: Bool = false
    @State private var emailError: String? = nil
    @State private var passwordError: String? = nil
    @State private var biometricType: BiometricType = .none
    @State private var biometricsEnabled: Bool = false
    @State private var biometricsAvailable: Bool = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ZStack {
                Color.green
                    .ignoresSafeArea()
                VStack {
                    HStack {
                        Text("Sign In")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 12)
                .padding(.horizontal, 16)
            }
            .frame(height: 50)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Logo
                    VStack(spacing: 12) {
                        Circle()
                            .fill(Color.green.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image("grocery_asisstant_logo")
                                    .resizable()
                                    .frame(width: 70, height: 70)
                            )
                        
                        
                        Text("Grocery Assistant")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Sign in to your account")
                            .foregroundColor(.gray)
                    }
                    .padding(.bottom, 16)
                    .padding(.top, 16)
                    
                    // Biometric Auth
                    if biometricsAvailable && biometricsEnabled {
                        Button(action: authenticateWithBiometrics) {
                            HStack {
                                Image(systemName: biometricType == .faceID ? "faceid" : "touchid")
                                    .foregroundColor(.green)
                                    .font(.system(size: 20))
                                
                                Text("Sign in with \(biometricType == .faceID ? "Face ID" : "Touch ID")")
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                    
                    // Form
                    VStack(spacing: 20) {
                        // Email Field
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Email")
                                .fontWeight(.medium)
                            
                            TextField("Enter your email", text: $email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(emailError != nil ? Color.red : Color.clear, lineWidth: 1)
                                )
                            
                            if let error = emailError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.top, 4)
                            }
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Password")
                                .fontWeight(.medium)
                            
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
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(passwordError != nil ? Color.red : Color.clear, lineWidth: 1)
                            )
                            
                            if let error = passwordError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.top, 4)
                            }
                        }
                        
                        // Remember Me and Forgot Password
                        HStack {
                            Button(action: {
                                rememberMe.toggle()
                            }) {
                                HStack {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(rememberMe ? Color.green : Color.gray, lineWidth: 1.5)
                                            .frame(width: 20, height: 20)
                                        
                                        if rememberMe {
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(Color.green)
                                                .frame(width: 12, height: 12)
                                        }
                                    }
                                    
                                    Text("Remember me")
                                        .foregroundColor(.primary)
                                        .font(.subheadline)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Spacer()
                            
                            Button(action: {
                                // Handle forgot password
                            }) {
                                Text("Forgot Password?")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.green)
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal)
                    
                    // Sign In Button
                    Button(action: handleSignIn) {
                        Text("Sign In")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                    .padding(.top, 16)
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Create Account Link
                    HStack {
                        Text("Don't have an account?")
                            .foregroundColor(.gray)
                        
                        Button(action: {
                            // Navigate to signup
                        }) {
                            Text("Sign Up")
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.bottom, 16)
                }
            }
        }
        .onAppear {
            checkBiometricType()
            checkBiometricsEnabled()
        }
    }
    
    private func checkBiometricType() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            biometricsAvailable = true
            switch context.biometryType {
            case .faceID:
                biometricType = .faceID
            case .touchID:
                biometricType = .touchID
            default:
                biometricType = .none
                biometricsAvailable = false
            }
        } else {
            biometricType = .none
            biometricsAvailable = false
        }
    }
    
    private func checkBiometricsEnabled() {
        // In a real app, this would check user preferences or keychain
        // For demo purposes, we'll assume biometrics was enabled during signup
        biometricsEnabled = true
    }
    
    private func handleSignIn() {
        // Reset errors
        emailError = nil
        passwordError = nil
        
        var isValid = true
        
        // Validate email
        if email.isEmpty {
            emailError = "Email is required"
            isValid = false
        } else if !isValidEmail(email) {
            emailError = "Please enter a valid email"
            isValid = false
        }
        
        // Validate password
        if password.isEmpty {
            passwordError = "Password is required"
            isValid = false
        }
        
        if isValid {
            // Authenticate user with email/password
            print("Signing in with email: \(email)")
            // Navigate to app home on success
        }
    }
    
    private func authenticateWithBiometrics() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Log in to your account"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                DispatchQueue.main.async {
                    if success {
                        print("Biometric authentication successful")
                        // Navigate to app home
                    } else {
                        // Handle error or fallback to password
                        print("Authentication failed: \(error?.localizedDescription ?? "Unknown error")")
                    }
                }
            }
        } else {
            // Biometrics not available
            print("Biometrics not available: \(error?.localizedDescription ?? "Unknown error")")
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView()
    }
}
