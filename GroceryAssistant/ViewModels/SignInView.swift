import SwiftUI
import LocalAuthentication

/// A view that handles user authentication by presenting a sign-in form.
///
/// This view allows users to sign in with their email and password, or with biometric
/// authentication if available and previously configured. It includes form validation,
/// "remember me" functionality, and navigation to sign up.
struct SignInView: View {
    /// Authentication manager for handling sign-in operations
    @EnvironmentObject var authManager: AuthManager
    
    /// Navigation path for handling navigation between views
    @Binding var navPath: NavigationPath

    /// User's email input
    @State private var email: String = ""
    
    /// User's password input
    @State private var password: String = ""
    
    /// Flag controlling password visibility
    @State private var showPassword: Bool = false
    
    /// Flag for "remember me" option to enable biometric login
    @State private var rememberMe: Bool = false
    
    /// Error message for email validation
    @State private var emailError: String? = nil
    
    /// Error message for password validation
    @State private var passwordError: String? = nil
    
    /// Type of biometric authentication available on the device
    @State private var biometricType: BiometricType = .none
    
    /// Whether biometric login is enabled for this user
    @State private var biometricsEnabled: Bool = false
    
    /// Whether biometric authentication is available on the device
    @State private var biometricsAvailable: Bool = false
    
    /// Flag indicating whether a sign-in operation is in progress
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
                    // Logo and title
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
                    
                    // Biometric authentication button (if available)
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
                    
                    // Sign-in form
                    VStack(spacing: 20) {
                        // Email field
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
                        
                        // Password field with show/hide toggle
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
                        
                        // Remember me checkbox and forgot password link
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
                    
                    // Sign Up link
                    HStack {
                        Text("Don't have an account?")
                            .foregroundColor(.gray)
                        
                        Button(action: {
                            // Navigate to signup
                            navPath.append(Route.signUp)
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
        .navigationBarHidden(true)
    }
    
    // MARK: - Biometric Authentication
    
    /// Determines the type of biometric authentication available on the device.
    ///
    /// This method checks whether Face ID or Touch ID is available and sets
    /// the appropriate biometric type.
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
    
    /// Checks if biometric authentication is enabled for the current user.
    ///
    /// This method determines both the availability of biometrics on the device
    /// and whether the user has previously stored credentials for biometric login.
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
    
    // MARK: - Form Handling
    
    /// Validates form inputs and initiates the sign-in process.
    ///
    /// This method performs validation on the email and password fields,
    /// displays appropriate error messages, and calls the authentication
    /// manager to sign in the user if validation passes.
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
    
    /// Initiates biometric authentication if available.
    ///
    /// This method uses the AuthManager to authenticate the user with Face ID or Touch ID,
    /// and navigates to the home screen on success.
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
    
    /// Validates if a string is a properly formatted email address.
    /// - Parameter email: The email string to validate
    /// - Returns: True if the email format is valid, false otherwise
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}