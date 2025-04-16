//
//  ContentView.swift
//  GroceryAssistant

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 2 // Start with Home tab selected
    @State private var navPath = NavigationPath()
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                // User is authenticated - show main app with tab bar
                mainAppView
            } else {
                // User is not authenticated - show sign in
                NavigationStack(path: $navPath) {
                    SignInView(navPath: $navPath)
                        .navigationDestination(for: Route.self) { route in
                            switch route {
                            case .signUp:
                                SignUpView(navPath: $navPath)
                            default:
                                EmptyView()
                            }
                        }
                }
            }
        }
        // Listen for authentication state changes
        .onReceive(authManager.$isAuthenticated) { isAuthenticated in
            // Reset navigation when auth state changes
            navPath = NavigationPath()
            
            // Reset to home tab when user signs in
            if isAuthenticated {
                selectedTab = 2 // Home tab
            }
        }
    }
    
    // Extract the main app view with tabs to keep code clean
    private var mainAppView: some View {
        NavigationStack(path: $navPath) {
            ZStack(alignment: .bottom) {
                TabView(selection: $selectedTab) {
                    NutritionalInfoView(navPath: $navPath)
                        .tag(0)
                    
                    LocatorView(navPath: $navPath)
                        .tag(1)
                    
                    HomeView(navPath: $navPath)
                        .tag(2)
                    
                    ListsView(navPath: $navPath)
                        .tag(3)
                    
                    ReminderView(navPath: $navPath)
                        .tag(4)
                }
                .edgesIgnoringSafeArea(.bottom)
                
                CustomTabBar(selectedTab: $selectedTab)
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .profile:
                    ProfileView(navPath: $navPath)
                case .signIn:
                    // Should not navigate to sign in when already authenticated
                    // This is included for completeness
                    EmptyView()
                case .signUp:
                    // Should not navigate to sign up when already authenticated
                    // This is included for completeness
                    EmptyView()
                case .home:
                    HomeView(navPath: $navPath)
                case .createNewList:
                    CreateNewListView(navPath: $navPath)
                case .recipes:
                    RecipeSuggestionsView(navPath: $navPath)
                case .recipeDetail(String recipeID):
                    RecipeDetailView(navPath: $navPath, recipeID: recipeID)
                case .lists:
                    ListsView(navPath: $navPath)
                case .listDetail(let id):
                    ListDetailView(listID: id, navPath: $navPath)
                case .shopping(let id):
                    ShoppingView(itemID: id, navPath: $navPath)   
                case .reminder:
                    ReminderView(navPath: $navPath)      
                }  
            }

        }
    }
}

// Custom tab bar view
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<5) { index in
                Button(action: {
                    selectedTab = index
                }) {
                    VStack(spacing: 5) {
                        ZStack {
                            if index == 2 { // Home button
                                Circle()
                                    .stroke(Color(AppColors.green600), lineWidth: 2)
                                    .frame(width: 50, height: 50)
                            }
                            
                            Image(systemName: getIconName(for: index))
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 25, height: 25)
                                .foregroundColor(selectedTab == index ? Color(AppColors.green600) : Color(AppColors.green500))
                        }
                        
                        if index != 2 { // Not home button
                            Text(getTabName(for: index))
                                .font(.system(size: 10))
                                .foregroundColor(selectedTab == index ? Color(AppColors.green600) : Color(AppColors.green500))
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 70)
        .background(
            Color(AppColors.background)
                .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: -4)
                .clipShape(CustomShape())
        )
    }
    
    func getIconName(for index: Int) -> String {
        switch index {
        case 0: return "leaf"              // Nutritional
        case 1: return "location"          // Locator
        case 2: return "house"             // Home
        case 3: return "list.bullet"       // Item Lists
        case 4: return "calendar"          // Reminders
        default: return "questionmark"
        }
    }
    
    func getTabName(for index: Int) -> String {
        switch index {
        case 0: return "Nutritional"
        case 1: return "Locator"
        case 2: return "Home"
        case 3: return "Item Lists"
        case 4: return "Reminders"
        default: return ""
        }
    }
}

struct CustomShape: Shape {
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: 30, height: 30)
        )
        return Path(path.cgPath)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthManager())
    }
}
