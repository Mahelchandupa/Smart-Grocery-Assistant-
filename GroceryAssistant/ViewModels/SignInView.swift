//
//  SignInView.swift
//  GroceryAssistant

import SwiftUI
import LocalAuthentication

struct SignInView: View {
    @EnvironmentObject var authManager: AuthManager
    @Binding var navPath: NavigationPath

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @State private var rememberMe: Bool = false
    @State private var emailError: String? = nil
    @State private var passwordError: String? = nil
    @State private var biometricType: BiometricType = .none
    @State private var biometricsEnabled: Bool = false
    @State private var biometricsAvailable: Bool = false
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ZStack {
                Color(hex: "4CAF50")
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
//                                .keyboardType(.emailAddress)
//                                .autocapitalization(.none)
//                                .disableAutocorrection(true)
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
//                                        .autocapitalization(.none)
//                                        .disableAutocorrection(true)
                                } else {
                                    SecureField("Enter your password", text: $password)
//                                        .autocapitalization(.none)
//                                        .disableAutocorrection(true)
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
                        navPath.append(Route.signUp)
                    }       ) {
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
        .navigationBarHidden(true)
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
         // Check if biometrics is available on the device
         let context = LAContext()
         var error: NSError?
         
         if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
             biometricsAvailable = true
             
             // Determine the biometric type (Face ID or Touch ID)
             switch context.biometryType {
             case .faceID:
                 biometricType = .faceID
             case .touchID:
                 biometricType = .touchID
             default:
                 biometricType = .none
                 biometricsAvailable = false
             }
             
             // Check if the user has stored credentials for biometrics
             biometricsEnabled = KeychainService.isBiometricsEnabled()
         } else {
             biometricType = .none
             biometricsAvailable = false
             biometricsEnabled = false
         }
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
                    isLoading = true
                    
                    let request = SignInRequest(
                        email: email,
                        password: password,
                        rememberMe: rememberMe
                    )
                    
                    authManager.signIn(with: request) { success, error in
                        isLoading = false
                        
                        if success {
                            // Successfully signed in
                            // The auth state listener in AuthManager will update isAuthenticated
                            // and trigger a navigation to the main app
                        } else if let error = error {
                            // Show error to user
                            if error.contains("email") {
                                emailError = error
                            } else if error.contains("password") {
                                passwordError = error
                            }
                        }
                    }
                }
    }
    
    private func authenticateWithBiometrics() {
           // Use the AuthManager's biometric authentication
           authManager.authenticateWithBiometrics { success, error in
               if success {
                   // If authentication is successful, navigate to home
                   navPath.append(Route.home)
               } else if let error = error {
                   // Display the error to the user
                   authManager.authError = error
               }
           }
       }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}
