import SwiftUI
import Firebase
import FirebaseAuth
import LocalAuthentication

class AuthManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var authError: String?
    
    init() {
        // Listen for authentication state changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
            self?.isAuthenticated = user != nil
        }
    }
    
    // MARK: - Sign In Methods
    func signIn(with request: SignInRequest, completion: @escaping (Bool, String?) -> Void) {
        authError = nil
        
        Auth.auth().signIn(withEmail: request.email, password: request.password) { [weak self] authResult, error in
            if let error = error {
                let errorMessage = self?.handleError(error)
                self?.authError = errorMessage
                completion(false, errorMessage)
                return
            }
            
            // Store user preferences like rememberMe if needed
            if let rememberMe = request.rememberMe, rememberMe {
                UserDefaults.standard.set(request.email, forKey: "savedEmail")
            } else {
                UserDefaults.standard.removeObject(forKey: "savedEmail")
            }
            
            completion(true, nil)
        }
    }
    
    // MARK: - Sign Up Methods
    func signUp(with request: SignUpRequest, completion: @escaping (Bool, String?) -> Void) {
        authError = nil
        
        Auth.auth().createUser(withEmail: request.email, password: request.password) { [weak self] authResult, error in
            if let error = error {
                let errorMessage = self?.handleError(error)
                self?.authError = errorMessage
                completion(false, errorMessage)
                return
            }
            
            // User created successfully, now save additional information to Firestore
            guard let user = authResult?.user else {
                completion(false, "Failed to get user information")
                return
            }
            
            // Create user profile in Firestore
            self?.createUserProfile(user: user, request: request) { success in
                if success {
                    // Save biometric preference if needed
                    if let enableBiometrics = request.enableBiometrics, enableBiometrics {
                        UserDefaults.standard.set(true, forKey: "biometricsEnabled")
                        
                        // In a real app, you would securely store the credentials
                        // This is just for demonstration
                        KeychainService.saveCredentials(email: request.email, password: request.password)
                    }
                    
                    completion(true, nil)
                } else {
                    completion(false, "Failed to create user profile")
                }
            }
        }
    }
    
    // MARK: - Sign Out Method
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Biometric Authentication
    func authenticateWithBiometrics(completion: @escaping (Bool, String?) -> Void) {
        // Check if we have stored credentials
        guard let credentials = KeychainService.getCredentials() else {
            completion(false, "No stored credentials for biometric login")
            return
        }
        
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Log in to your account"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, error in
                DispatchQueue.main.async {
                    if success {
                        // User successfully authenticated with biometrics, now sign in with Firebase
                        self?.signIn(with: SignInRequest(
                            email: credentials.email,
                            password: credentials.password,
                            rememberMe: true
                        ), completion: completion)
                    } else {
                        completion(false, error?.localizedDescription ?? "Biometric authentication failed")
                    }
                }
            }
        } else {
            completion(false, "Biometric authentication not available")
        }
    }
    
    // MARK: - Helper Methods
    private func createUserProfile(user: User, request: SignUpRequest, completion: @escaping (Bool) -> Void) {
        // Create a reference to Firestore
        let db = Firestore.firestore()
        
        // Create a user document with additional profile information
        db.collection("users").document(user.uid).setData([
            "firstName": request.firstName,
            "lastName": request.lastName,
            "email": request.email,
            "phoneNumber": request.phoneNumber,
            "createdAt": FieldValue.serverTimestamp(),
            "enabledBiometrics": request.enableBiometrics ?? false
        ]) { error in
            if let error = error {
                print("Error creating user profile: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            // Profile created successfully
            completion(true)
        }
    }
    
    private func handleError(_ error: Error) -> String {
        let authError = error as NSError
        
        switch authError.code {
        case AuthErrorCode.wrongPassword.rawValue:
            return "Invalid email or password"
        case AuthErrorCode.invalidEmail.rawValue:
            return "Invalid email address"
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return "Email is already in use"
        case AuthErrorCode.weakPassword.rawValue:
            return "Password is too weak"
        case AuthErrorCode.userNotFound.rawValue:
            return "Account not found"
        case AuthErrorCode.networkError.rawValue:
            return "Network error. Please try again"
        default:
            return "An error occurred: \(error.localizedDescription)"
        }
        .navigationBarHidden(true)
        .alert(isPresented: .constant(authManager.authError != nil)) {
            Alert(
                title: Text("Authentication Error"),
                message: Text(authManager.authError ?? "An unknown error occurred"),
                dismissButton: .default(Text("OK")) {
                    authManager.authError = nil
                }
            )
        }
    }
    
    private func checkBiometricType() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            if context.biometryType == .faceID {
                biometricType = .faceID
            } else {
                biometricType = .none
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
            authManager.signUp(with: signUpRequest) { success, error in
                isLoading = false
                
                if success {
                    // Navigate back to sign in screen
                    navPath.removeLast()
                } else if let error = error {
                    // Display the appropriate error
                    if error.contains("email") {
                        emailError = error
                    } else if error.contains("password") {
                        passwordError = error
                    } else {
                        authManager.authError = error
                    }
                }
            }
        }
    }
}
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var authError: String?
    
    init() {
        // Listen for authentication state changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
            self?.isAuthenticated = user != nil
        }
    }
    
    // Sign In Methods
    func signIn(with request: SignInRequest, completion: @escaping (Bool, String?) -> Void) {
        authError = nil
        
        Auth.auth().signIn(withEmail: request.email, password: request.password) { [weak self] authResult, error in
            if let error = error {
                let errorMessage = self?.handleError(error)
                self?.authError = errorMessage
                completion(false, errorMessage)
                return
            }
            
            // Store user preferences like rememberMe
            if let rememberMe = request.rememberMe, rememberMe {
                UserDefaults.standard.set(request.email, forKey: "savedEmail")
            } else {
                UserDefaults.standard.removeObject(forKey: "savedEmail")
            }
            
            completion(true, nil)
        }
    }

    //  Sign Up Methods
    func signUp(with request: SignUpRequest, completion: @escaping (Bool, String?) -> Void) {
        authError = nil
        
        Auth.auth().createUser(withEmail: request.email, password: request.password) { [weak self] authResult, error in
            if let error = error {
                let errorMessage = self?.handleError(error)
                self?.authError = errorMessage
                completion(false, errorMessage)
                return
            }
            
            // User created successfully, now save additional information to Firestore
            guard let user = authResult?.user else {
                completion(false, "Failed to get user information")
                return
            }
            
            // Create user profile in Firestore
            self?.createUserProfile(user: user, request: request) { success in
                if success {
                    // Save biometric preference if needed
                    if let enableBiometrics = request.enableBiometrics, enableBiometrics {
                        UserDefaults.standard.set(true, forKey: "biometricsEnabled")
                        
                        // In a real app, you would securely store the credentials
                        // This is just for demonstration
                        KeychainService.saveCredentials(email: request.email, password: request.password)
                    }
                    
                    completion(true, nil)
                } else {
                    completion(false, "Failed to create user profile")
                }
            }
        }
    }

    // Sign Out Method
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }

    // Biometric Authentication
    func authenticateWithBiometrics(completion: @escaping (Bool, String?) -> Void) {
        // Check if we have stored credentials
        guard let credentials = KeychainService.getCredentials() else {
            completion(false, "No stored credentials for biometric login")
            return
        }
        
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Log in to your account"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, error in
                DispatchQueue.main.async {
                    if success {
                        // User successfully authenticated with biometrics, now sign in with Firebase
                        self?.signIn(with: SignInRequest(
                            email: credentials.email,
                            password: credentials.password,
                            rememberMe: true
                        ), completion: completion)
                    } else {
                        completion(false, error?.localizedDescription ?? "Biometric authentication failed")
                    }
                }
            }
        } else {
            completion(false, "Biometric authentication not available")
        }
    }

    // Helper Methods
    private func createUserProfile(user: User, request: SignUpRequest, completion: @escaping (Bool) -> Void) {
        // Create a reference to Firestore
        let db = Firestore.firestore()
        
        // Create a user document with additional profile information
        db.collection("users").document(user.uid).setData([
            "firstName": request.firstName,
            "lastName": request.lastName,
            "email": request.email,
            "phoneNumber": request.phoneNumber,
            "createdAt": FieldValue.serverTimestamp(),
            "enabledBiometrics": request.enableBiometrics ?? false
        ]) { error in
            if let error = error {
                print("Error creating user profile: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            // Profile created successfully
            completion(true)
        }
    }

      private func handleError(_ error: Error) -> String {
        let authError = error as NSError
        
        switch authError.code {
        case AuthErrorCode.wrongPassword.rawValue:
            return "Invalid email or password"
        case AuthErrorCode.invalidEmail.rawValue:
            return "Invalid email address"
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return "Email is already in use"
        case AuthErrorCode.weakPassword.rawValue:
            return "Password is too weak"
        case AuthErrorCode.userNotFound.rawValue:
            return "Account not found"
        case AuthErrorCode.networkError.rawValue:
            return "Network error. Please try again"
        default:
            return "An error occurred: \(error.localizedDescription)"
        }
        .navigationBarHidden(true)
        .alert(isPresented: .constant(authManager.authError != nil)) {
            Alert(
                title: Text("Authentication Error"),
                message: Text(authManager.authError ?? "An unknown error occurred"),
                dismissButton: .default(Text("OK")) {
                    authManager.authError = nil
                }
            )
        }
    }

    private func checkBiometricType() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            if context.biometryType == .faceID {
                biometricType = .faceID
            } else {
                biometricType = .none
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
    