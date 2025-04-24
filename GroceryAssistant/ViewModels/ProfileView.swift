import SwiftUI
import FirebaseFirestore
import FirebaseAuth

/// A view that displays the user's profile information and account settings.
///
/// This view allows users to view their personal information, toggle biometric login,
/// access help and support, and log out of the application.
struct ProfileView: View {
    /// Navigation path for handling navigation within the app
    @Binding var navPath: NavigationPath
    
    /// Environment value for dismissing the view
    @Environment(\.dismiss) private var dismiss
    
    /// Toggle state for biometric login
    @State private var biometricLogin = true
    
    /// Toggle state for showing/hiding personal information
    @State private var showPersonalInfo = false
    
    /// Authentication manager for user context and sign-out functionality
    @EnvironmentObject var authManager: AuthManager
    
    /// Flag indicating whether a logout error alert is being shown
    @State private var showingLogoutError = false
    
    /// Error message to display in the logout error alert
    @State private var logoutErrorMessage = ""
    
    // MARK: - User State
    
    /// The current user's profile data
    @State private var user: User?
    
    /// Flag indicating whether user data is being loaded
    @State private var isLoading = true
    
    /// Error message if user data fails to load
    @State private var errorMessage: String?
    
    /// Initializes the view with a navigation path
    /// - Parameter navPath: Binding to the navigation path
    init(navPath: Binding<NavigationPath>) {
        self._navPath = navPath
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            ScrollView {
                if isLoading {
                    VStack {
                        ProgressView()
                            .padding()
                        Text("Loading profile...")
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .padding(.top, 100)
                } else if let errorMessage = errorMessage {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                            .padding()
                        
                        Text("Error loading profile")
                            .font(.headline)
                            .padding(.bottom, 4)
                        
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        
                        Button("Try Again") {
                            Task {
                                await fetchUserData()
                            }
                        }
                        .padding()
                        .background(AppColors.green500)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.top)
                        
                        logoutButton
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .padding(.top, 50)
                } else if let user = user {
                    VStack(spacing: 16) {
                        // User Profile Card
                        profileCardView(for: user)
                        
                        // Account Settings
                        accountSettingsView(for: user)
                        
                        // Help & Support
                        helpAndSupportView
                        
                        // Logout Button
                        logoutButton
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
        }
        .background(Color(.systemGray6))
        .edgesIgnoringSafeArea(.top)
        .navigationBarHidden(true)
        .onAppear {
            Task {
                await fetchUserData()
            }
        }
        .alert("Logout Error", isPresented: $showingLogoutError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(logoutErrorMessage)
        }
    }
    
    // MARK: - Data Fetching
    
    /// Fetches the current user's data from Firebase
    private func fetchUserData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Get the current user ID
            guard let firebaseUser = Auth.auth().currentUser else {
                errorMessage = "No user is signed in"
                isLoading = false
                return
            }
            
            // Fetch user data from Firestore
            let userData = try await FirestoreService.getUserData(uid: firebaseUser.uid)
            
            // Update UI on main thread
            await MainActor.run {
                // Create a User from Firebase user and Firestore data
                self.user = User.from(firebaseUser: firebaseUser, userData: userData)
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load profile: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    /// Formats a Firestore timestamp into a readable date string
    /// - Parameter timestamp: The Firestore timestamp to format
    /// - Returns: A formatted date string
    private func formatMemberSince(_ timestamp: Timestamp?) -> String {
        guard let timestamp = timestamp else {
            return "Unknown"
        }
        
        let date = timestamp.dateValue()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    // MARK: - Component Views
    
    /// Header view with navigation and title
    private var headerView: some View {
        ZStack {
            Color(hex: "4CAF50")
                .ignoresSafeArea(edges: .top)
            VStack {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "arrow.left")
                            .foregroundColor(.white)
                            .font(.system(size: 20))
                    }
                    .padding(.trailing, 8)
                    
                    Text("Profile")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
            }
            .padding(.top, 40)
            .padding(.bottom, 8)
            .padding(.horizontal, 16)
        }
        .frame(height: 120)
    }
    
    /// Card view displaying user profile information
    /// - Parameter user: The user to display profile information for
    /// - Returns: A styled card view with the user's avatar and basic info
    private func profileCardView(for user: User) -> some View {
        VStack(alignment: .leading) {
            HStack(spacing: 16) {
                // Avatar placeholder
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Text(String(user.firstName.prefix(1)) + String(user.lastName.prefix(1)))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(user.firstName) \(user.lastName)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(.darkGray))
                    
                    Text(user.email)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    /// Section for account settings options
    /// - Parameter user: The user whose settings should be displayed
    /// - Returns: A card view with account setting options
    private func accountSettingsView(for user: User) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Account Settings")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(Color(.darkGray))
                .padding(.bottom, 4)
            
            // Personal Information Dropdown
            personalInfoSection(for: user)
            
            // Biometric Login Toggle
            biometricLoginSection(for: user)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    /// Expandable section showing personal information details
    /// - Parameter user: The user whose personal info should be displayed
    /// - Returns: An expandable section view with personal information
    private func personalInfoSection(for user: User) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: {
                withAnimation {
                    showPersonalInfo.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(Color(.darkGray))
                        .frame(width: 24, height: 24)
                    
                    Text("Personal Information")
                        .foregroundColor(Color(.darkGray))
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color(.systemGray))
                        .rotationEffect(.degrees(showPersonalInfo ? 90 : 0))
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 4)
            
            if showPersonalInfo {
                VStack(alignment: .leading, spacing: 8) {
                    infoRow(label: "First Name:", value: user.firstName)
                    infoRow(label: "Last Name:", value: user.lastName)
                    infoRow(label: "Email:", value: user.email)
                    infoRow(label: "Phone:", value: user.phone)
                    infoRow(label: "Member Since:", value: user.memberSince ?? "Unknown")
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.top, 4)
                .padding(.bottom, 8)
            }
            
            Divider()
        }
    }
    
    /// Toggle section for enabling or disabling biometric login
    /// - Parameter user: The user whose biometric setting should be displayed
    /// - Returns: A toggle section for biometric login
    private func biometricLoginSection(for user: User) -> some View {
        HStack {
            Image(systemName: "key.fill")
                .foregroundColor(Color(.darkGray))
                .frame(width: 24, height: 24)
            
            Text("Biometric Login")
                .foregroundColor(Color(.darkGray))
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { self.biometricLogin },
                set: { newValue in
                    self.biometricLogin = newValue
                }
            ))
            .labelsHidden()
            .toggleStyle(SwitchToggleStyle(tint: AppColors.green500))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
        .onAppear {
            // Initialize toggle with user preference from Firebase
            self.biometricLogin = user.enableBiometrics
        }
    }
    
    /// Section showing help and support options
    private var helpAndSupportView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Help & Support")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(Color(.darkGray))
                .padding(.bottom, 4)
            
            Button(action: { }) {
                HStack {
                    Image(systemName: "questionmark.circle.fill")
                        .foregroundColor(Color(.darkGray))
                        .frame(width: 24, height: 24)
                    
                    Text("About")
                        .foregroundColor(Color(.darkGray))
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color(.systemGray))
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 4)
            
            Divider()
            
            Button(action: { }) {
                HStack {
                    Image(systemName: "questionmark.circle.fill")
                        .foregroundColor(Color(.darkGray))
                        .frame(width: 24, height: 24)
                    
                    Text("Contact Support")
                        .foregroundColor(Color(.darkGray))
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color(.systemGray))
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 4)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    /// Button that logs the user out of the application
    private var logoutButton: some View {
        Button(action: {
            do {
                try authManager.signOut()
            } catch {
                // Set the error message and show the alert
                logoutErrorMessage = error.localizedDescription
                showingLogoutError = true
            }
        }) {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .foregroundColor(AppColors.red)
                
                Text("Logout")
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.red)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .padding(.bottom, 16)
    }
    
    /// Creates a row displaying a labeled piece of information
    /// - Parameters:
    ///   - label: The label text (e.g., "First Name:")
    ///   - value: The value to display
    /// - Returns: A formatted row with label and value
    private func infoRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 4) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color(.darkGray))
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(Color(.darkGray))
        }
    }
}

/// Preview provider for ProfileView
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(navPath: .constant(NavigationPath()))
            .environmentObject(AuthManager())
    }
}