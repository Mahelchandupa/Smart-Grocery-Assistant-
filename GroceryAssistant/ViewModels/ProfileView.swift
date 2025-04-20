import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ProfileView: View {
    @Binding var navPath: NavigationPath
    @Environment(\.dismiss) private var dismiss
    @State private var biometricLogin = true
    @State private var showPersonalInfo = false
    @EnvironmentObject var authManager: AuthManager
    
    @State private var showingLogoutError = false
    @State private var logoutErrorMessage = ""
    
    // User state
    @State private var user: User?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    // Initialize with empty user and fetch data on appear
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
    
    // Fetch user data from Firebase
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
    
    // Format timestamp to readable date
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
    
    // Header view
    private var headerView: some View {
        ZStack {
            AppColors.green600
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
    
    // Profile card view
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
    
    // Account settings view
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
    
    // Personal info dropdown section
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
    
    // Biometric login toggle section
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
                    // Here you would typically update the user's preferences in Firestore
                    // For example: Task { try? await updateUserBiometricPreference(userId: user.id, enabled: newValue) }
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
    
    // Help and support view
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
    
    // Logout button
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
    
    // Helper function for information rows
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

// Preview provider
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(navPath: .constant(NavigationPath()))
            .environmentObject(AuthManager())
    }
}
