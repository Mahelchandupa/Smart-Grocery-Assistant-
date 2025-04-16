//
//  Profile.swift
//  GroceryAssistant

import SwiftUI

struct ProfileView: View {
    @Binding var navPath: NavigationPath
    @State private var biometricLogin = true
    @State private var showPersonalInfo = false
    @EnvironmentObject var authManager: AuthManager
    
    // Modified User struct - moved outside of view for clarity
    let user: UserProfile
    
    // Initialize with default user data
    init(navPath: Binding<NavigationPath>) {
        self._navPath = navPath
        self.user = UserProfile(
            firstName: "Sarah",
            lastName: "Johnson",
            email: "sarah.johnson@example.com",
            phone: "+1 (555) 123-4567",
            avatar: "/api/placeholder/100/100",
            memberSince: "March 2023"
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            ScrollView {
                VStack(spacing: 16) {
                    // User Profile Card
                    profileCardView
                    
                    // Account Settings
                    accountSettingsView
                    
                    // Help & Support
                    helpAndSupportView
                    
                    // Logout Button
                    logoutButton
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
        }
        .background(Color(.systemGray6))
        .edgesIgnoringSafeArea(.top)
        .navigationBarHidden(true)
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
                        navPath.removeLast()
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
    private var profileCardView: some View {
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
    private var accountSettingsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Account Settings")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(Color(.darkGray))
                .padding(.bottom, 4)
            
            // Personal Information Dropdown
            personalInfoSection
            
            // Biometric Login Toggle
            biometricLoginSection
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // Personal info dropdown section
    private var personalInfoSection: some View {
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
                    infoRow(label: "Member Since:", value: user.memberSince)
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
    private var biometricLoginSection: some View {
        HStack {
            Image(systemName: "key.fill")
                .foregroundColor(Color(.darkGray))
                .frame(width: 24, height: 24)
            
            Text("Biometric Login")
                .foregroundColor(Color(.darkGray))
            
            Spacer()
            
            Toggle("", isOn: $biometricLogin)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: AppColors.green500))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
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
            authManager.signOut()
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

// Separate user profile model
struct UserProfile {
    let firstName: String
    let lastName: String
    let email: String
    let phone: String
    let avatar: String
    let memberSince: String
}

// Preview provider
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(navPath: .constant(NavigationPath()))
            .environmentObject(AuthManager())
    }
}
