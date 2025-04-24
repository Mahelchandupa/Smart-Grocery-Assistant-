import SwiftUI

/// A view that displays purchasable items from the shop.
///
/// This view presents a list of items available for purchase, fetched from Firestore.
/// It includes a custom navigation header and handles loading, error, and empty states.
struct BuyItemsView: View {
    /// Authentication manager for user context
    @EnvironmentObject var authManager: AuthManager
    
    /// Navigation path for handling navigation within the app
    @Binding var navPath: NavigationPath
    
    /// Array of items available for purchase
    @State private var buyItems: [Buy] = []
    
    /// Flag indicating whether shop items are currently being loaded
    @State private var isLoading = false
    
    /// Error message to display if loading fails
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom navigation header
            ZStack {
                Color(Color(hex: "4CAF50"))
                    .ignoresSafeArea(edges: .top)
                VStack {
                    HStack {
                        Button(action: {
                            if navPath.count > 0 {
                                navPath.removeLast()
                            }
                        }) {
                            Image(systemName: "arrow.left")
                                .foregroundColor(.white)
                                .font(.system(size: 20))
                        }
                        .padding(.trailing, 8)
                        
                        Text("Shop")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 20)
                .padding(.horizontal, 16)
            }
            .frame(height: 40)
            
            // Content scroll view with conditional states
            ScrollView(.vertical, showsIndicators: false) {
                if isLoading {
                    // Loading state
                    ProgressView()
                        .padding()
                } else if let errorMessage = errorMessage {
                    // Error state
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                } else if buyItems.isEmpty {
                    // Empty state
                    Text("No shop items available")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    // Content state - list of shop items
                    VStack(spacing: 16) {
                        ForEach(buyItems) { item in
                            BuyItemCard(item: item)
                        }
                    }
                }
             
            }
            .padding(.top, 16)
            .padding(.horizontal)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .navigationBarHidden(true)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color(.systemGroupedBackground))
        .task {
            await loadShopItems()
        }
    }
    
    /// Loads shop items from Firestore.
    ///
    /// This method sets loading state, attempts to fetch shop items,
    /// and handles any errors that occur during the process.
    private func loadShopItems() async {
        isLoading = true
        errorMessage = nil
        
        do {
            buyItems = try await FirestoreService.getBuyItems()
        } catch {
            errorMessage = "Failed to load shop items: \(error.localizedDescription)"
            print("Error loading shop items: \(error)")
        }
        
        isLoading = false
    }
}

/// Preview provider for BuyItemsView
struct BuyItemsView_Previews: PreviewProvider {
    static var previews: some View {
        BuyItemsView(navPath: .constant(NavigationPath()))
    }
}