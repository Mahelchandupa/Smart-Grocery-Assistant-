
import SwiftUI

struct BuyItemsView: View {
    @EnvironmentObject var authManager: AuthManager
    @Binding var navPath: NavigationPath
    
    @State private var buyItems: [Buy] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
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
            
            // Content Scroll
            ScrollView(.vertical, showsIndicators: false) {
                if isLoading {
                    ProgressView()
                        .padding()
                } else if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                } else if buyItems.isEmpty {
                    Text("No shop items available")
                        .foregroundColor(.gray)
                        .padding()
                } else {
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

struct BuyItemsView_Previews: PreviewProvider {
    static var previews: some View {
        BuyItemsView(navPath: .constant(NavigationPath()))
    }
}
