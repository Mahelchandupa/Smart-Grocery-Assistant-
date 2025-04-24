import SwiftUI

/// A view that displays all of the user's shopping lists.
///
/// This view presents a scrollable list of the user's shopping lists, with options to navigate
/// to list details and create new lists. It handles various states including loading, empty state,
/// and displaying the lists.
struct ListsView: View {
    /// Navigation path for handling navigation within the app
    @Binding var navPath: NavigationPath
    
    /// Authentication manager for user context and data access
    @EnvironmentObject var authManager: AuthManager
    
    /// Collection of user's shopping lists
    @State private var lists: [ShoppingList] = []
    
    /// Flag indicating whether data is currently loading
    @State private var loading = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with navigation and title
            ZStack {
                Color(Color(hex: "4CAF50"))
                    .ignoresSafeArea(edges: .top)
                
                VStack(spacing: 4) {
                    HStack {
                        Button(action: {
                            if navPath.count > 0 {
                                navPath.removeLast()
                            }
                        }) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                        .padding(.trailing, 12)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("My Lists")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("\(lists.count) active lists")
                                .font(.subheadline)
                                .foregroundColor(Color(hex: "E8F5E9"))
                        }
                        
                        Spacer()
                    }
                }
                .padding(.top, 25)
                .padding(.bottom, 25)
                .padding(.horizontal, 16)
            }
            .frame(height: 60)
            mainContent
        }
        .background(Color(hex: "F9FAFB"))
        .navigationBarHidden(true)
        .onAppear {
            fetchLists()
        }
    }
    
    // MARK: - Main Components
    
    /// Main content container that displays either loading view or lists content
    private var mainContent: some View {
        Group {
            if loading {
                loadingView
            } else {
                listsContent
            }
        }
    }
    
    /// Loading indicator shown while fetching data
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.3)
                .tint(Color(hex: "4CAF50"))
            Spacer()
        }
    }
    
    /// Main content view displaying shopping lists
    private var listsContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Your Shopping Lists")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "1F2937"))
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                
                if lists.isEmpty {
                    emptyStateView
                } else {
                    listsView
                }
            }
            .padding(.bottom, 16)
        }
        .background(Color(hex: "F9FAFB"))
    }
    
    /// Lists display when user has shopping lists
    private var listsView: some View {
        ForEach(lists) { list in
            ShoppingListCard(list: list, navPath: $navPath)
                .padding(.horizontal, 16)
        }
    }
    
    /// Empty state display when user has no shopping lists
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 48))
                .foregroundColor(Color(hex: "9CA3AF"))
            
            Text("No shopping lists yet")
                .font(.headline)
                .foregroundColor(Color(hex: "4B5563"))
            
            Text("Create your first shopping list to get started")
                .font(.subheadline)
                .foregroundColor(Color(hex: "6B7280"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            createNewListButton
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    /// Button for creating a new shopping list
    private var createNewListButton: some View {
        Button(action: {
            navPath.append(Route.createNewList)
        }) {
            Text("Create New List")
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(maxWidth: 220)
                .padding(.vertical, 12)
                .background(Color(hex: "16A34A"))
                .cornerRadius(8)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Data Fetching
    
    /// Fetches the user's shopping lists from Firestore
    private func fetchLists() {
        Task {
            do {
                loading = true
                let userLists = try await authManager.getUserLists()
                
                await MainActor.run {
                    self.lists = userLists
                    self.loading = false
                }
            } catch {
                print("Failed to fetch lists: \(error.localizedDescription)")
                await MainActor.run {
                    self.loading = false
                }
            }
        }
    }
}