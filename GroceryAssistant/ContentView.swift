import SwiftUI

/// The main container view of the application that handles authentication state
/// and manages tab navigation for the authenticated experience.
struct ContentView: View {
    /// The currently selected tab index, starting with Home (index 2)
    @State private var selectedTab = 2

    /// Navigation path for handling deep linking and navigation between views
    @State private var navPath = NavigationPath()

    /// Authentication manager to determine if the user is signed in
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        ZStack {
            if authManager.isAuthenticated {
                mainAppView
            } else {
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
    
    /// The main authenticated app view with tabs and navigation
    private var mainAppView: some View {
        // Uses ZStack to position the tab bar outside the NavigationStack
        ZStack(alignment: .bottom) {
            NavigationStack(path: $navPath) {
                // TabView to manage switching between main app sections
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
                .navigationDestination(for: Route.self) { route in
                    // Handle all navigation destinations here
                    destinationView(for: route)
                }
            }
            
            // The tab bar is outside the NavigationStack but inside the ZStack
            // This ensures it's always visible at the bottom
            if navPath.isEmpty {
                CustomTabBar(selectedTab: $selectedTab)
                    .transition(.move(edge: .bottom))
            }
        }
    }
    
    /// Creates the appropriate view based on the navigation route
    /// - Parameter route: The route to navigate to
    /// - Returns: The destination view for the specified route
    @ViewBuilder
    private func destinationView(for route: Route) -> some View {
        switch route {
        case .profile:
            ProfileView(navPath: $navPath)
        case .signIn, .signUp:
            // Should not navigate to sign in/up when already authenticated
            EmptyView()
        case .home:
            HomeView(navPath: $navPath)
        case .createNewList:
            CreateNewListView(navPath: $navPath)
        case .recipes:
            RecipeSuggestionsView(navPath: $navPath)
        case .lists:
            ListsView(navPath: $navPath)
        case .listDetail(let id):
            ListDetailView(listId: id, navPath: $navPath)
        case .shopping(let id):
            ShoppingView(itemID: id, navPath: $navPath)
        case .reminder:
            ReminderView(navPath: $navPath)
        case .nutritionalInfo:
            NutritionalInfoView(navPath: $navPath)
        case .locator:
            LocatorView(navPath: $navPath)
        case .history:
            HistoryView(navPath: $navPath)
        case .buy:
            BuyItemsView(navPath: $navPath)
        }
    }
}

/// Custom tab bar for the main application navigation
struct CustomTabBar: View {
    /// The currently selected tab index, bound to the parent view
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<5, id: \.self) { index in
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

                        if index != 2 {
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
    
    /// Returns the SF Symbol name for the given tab index
    /// - Parameter index: The tab index
    /// - Returns: SF Symbol name as a string
    func getIconName(for index: Int) -> String {
        switch index {
        case 0: return "leaf"                // Nutritional
        case 1: return "mappin.and.ellipse"  // Locator
        case 2: return "house"               // Home
        case 3: return "list.bullet"         // Item Lists
        case 4: return "calendar"            // Reminders
        default: return "questionmark"
        }
    }
    
    /// Returns the display name for the given tab index
    /// - Parameter index: The tab index
    /// - Returns: Tab name as a string
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

/// Preview provider for ContentView
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthManager())
    }
}
