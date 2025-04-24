import SwiftUI
import FirebaseFirestore
import FirebaseAuth

/// A view that displays the user's shopping history, focusing on past purchases.
///
/// This view shows a list of completed shopping trips, with details like
/// date, store name, total spent, and number of items. Users can tap on a purchase
/// to see more detailed information.
struct HistoryView: View {
    /// Navigation path for handling navigation within the app
    @Binding var navPath: NavigationPath
    
    /// View model that handles data fetching and business logic
    @StateObject private var viewModel = HistoryViewModel()
    
    /// Authentication manager for user context
    @EnvironmentObject var authManager: AuthManager
    
    /// Currently active tab in the view
    @State private var activeTab = "purchases"
    
    /// Presentation mode for dismissing the view
    @Environment(\.presentationMode) var presentationMode
    
    /// Date formatter configured for displaying purchase dates
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }()
    
    /// Currency formatter for displaying monetary values
    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter
    }()
    
    var body: some View {
        ZStack {
            
            VStack(spacing: 0) {
                // Custom navigation header
                ZStack {
                    Color(hex: "4CAF50")
                        .ignoresSafeArea(edges: .top)
                    VStack {
                        HStack {
                            Button(action: {
                                if navPath.count > 0 {
                                    navPath.removeLast()
                                }
                            })
                            {
                                Image(systemName: "arrow.left")
                                    .foregroundColor(.white)
                                    .font(.system(size: 20))
                            }
                            .padding(.trailing, 8)
                            
                            Text("Shopping History")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Spacer()
                        }
                    }
                    .padding(.top, 25)
                    .padding(.bottom, 20)
                    .padding(.horizontal, 16)
                }
                .frame(height: 60)
                .padding(.bottom, 20)
                
                VStack(spacing: 0) {
                    // Tab navigation for different history sections
                    HStack {
                        Button(action: {
                            activeTab = "purchases"
                        }) {
                            VStack(spacing: 8) {
                                Text("Recent Purchases")
                                    .font(.subheadline)
                                    .fontWeight(activeTab == "purchases" ? .semibold : .regular)
                                    .foregroundColor(activeTab == "purchases" ? .green : .gray)
                                
                                Rectangle()
                                    .fill(activeTab == "purchases" ? Color.green : Color.clear)
                                    .frame(height: 2)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .background(Color.white)
                    
                    // Content area showing purchases with different states
                    ScrollView {
                        if viewModel.isLoading {
                            // Loading state
                            ProgressView()
                                .padding()
                        } else if let errorMessage = viewModel.errorMessage {
                            // Error state
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .padding()
                        } else if viewModel.recentPurchases.isEmpty {
                            // Empty state
                            VStack(spacing: 16) {
                                Image(systemName: "bag")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray)
                                
                                Text("No purchase history yet")
                                    .font(.headline)
                                
                                Text("Your completed shopping trips will appear here")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            .padding(.top, 100)
                        } else {
                            // Content state - list of purchases
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.recentPurchases) { purchase in
                                    PurchaseCard(purchase: purchase, dateFormatter: dateFormatter, currencyFormatter: currencyFormatter)
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.fetchPurchaseHistory()
            }
        }
    }
    
    /// A card component that displays summary information for a single purchase.
    ///
    /// This card shows purchase details like list name, total spent, date, store name,
    /// and item count. It also serves as a navigation link to the full purchase details.
    struct PurchaseCard: View {
        /// The purchase to display
        let purchase: Purchase
        
        /// Date formatter for displaying the purchase date
        let dateFormatter: DateFormatter
        
        /// Currency formatter for displaying the total spent
        let currencyFormatter: NumberFormatter
        
        var body: some View {
            NavigationLink(destination: PurchaseDetailView(purchase: purchase)) {
                VStack(spacing: 12) {
                    HStack {
                        Text(purchase.listName)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text(currencyFormatter.string(from: NSNumber(value: purchase.totalSpent)) ?? "$0.00")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text(dateFormatter.string(from: purchase.date))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Divider()
                            .frame(width: 1, height: 12)
                            .overlay(Color.gray.opacity(0.5))
                            .padding(.horizontal, 8)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "bag")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text(purchase.storeName)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                    }
                    
                    Text("\(purchase.itemCount) items purchased")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack {
                        Text("View Details")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
        }
    }
    
    /// A detail view that displays comprehensive information about a purchase.
    ///
    /// This view shows both the purchase metadata (date, store, total) and
    /// a list of all items that were part of the purchase.
    struct PurchaseDetailView: View {
        /// The purchase to display details for
        let purchase: Purchase
        
        /// View model for fetching and managing purchase item details
        @StateObject private var detailViewModel = PurchaseDetailViewModel()
        
        var body: some View {
            List {
                Section(header: Text("Purchase Information")) {
                    HStack {
                        Text("List")
                        Spacer()
                        Text(purchase.listName)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Date")
                        Spacer()
                        Text(formatDate(purchase.date))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Store")
                        Spacer()
                        Text(purchase.storeName)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Total")
                        Spacer()
                        Text(formatCurrency(purchase.totalSpent))
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Items")) {
                    if detailViewModel.isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else if detailViewModel.items.isEmpty {
                        Text("No items found")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .listRowBackground(Color.clear)
                    } else {
                        ForEach(detailViewModel.items) { item in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(item.name)
                                    
                                    if let quantity = item.targetQuantity, let unit = item.targetUnit {
                                        Text("\(quantity) \(unit)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                if let price = item.price {
                                    Text(formatCurrency(price))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Purchase Details")
            .onAppear {
                detailViewModel.fetchItems(for: purchase)
            }
        }
        
        /// Formats a date into a readable string with both date and time.
        /// - Parameter date: The date to format
        /// - Returns: A formatted date string (e.g., "Jan 1, 2023, 3:30 PM")
        private func formatDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
        
        /// Formats a number as currency.
        /// - Parameter value: The monetary value to format
        /// - Returns: A formatted currency string (e.g., "$10.99")
        private func formatCurrency(_ value: Double) -> String {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = "USD"
            return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
        }
    }
    
    /// View model for handling the details of a purchase, including fetching associated items.
    class PurchaseDetailViewModel: ObservableObject {
        /// The list of items in this purchase
        @Published var items: [ShoppingItem] = []
        
        /// Flag indicating whether items are currently being loaded
        @Published var isLoading = false
        
        /// Error message if loading fails
        @Published var errorMessage: String?
        
        /// Reference to Firestore database
        private let db = Firestore.firestore()
        
        /// Fetches all items associated with a specific purchase.
        /// - Parameter purchase: The purchase for which to fetch items
        func fetchItems(for purchase: Purchase) {
            guard let userId = Auth.auth().currentUser?.uid else {
                self.errorMessage = "No user logged in"
                return
            }
            
            isLoading = true
            
            db.collection("users")
                .document(userId)
                .collection("purchaseItems")
                .whereField("purchaseId", isEqualTo: purchase.id)
                .getDocuments { [weak self] querySnapshot, error in
                    guard let self = self else { return }
                    
                    self.isLoading = false
                    
                    if let error = error {
                        self.errorMessage = "Error fetching items: \(error.localizedDescription)"
                        return
                    }
                    
                    guard let documents = querySnapshot?.documents else {
                        self.errorMessage = "No items found"
                        return
                    }
                    
                    self.items = documents.compactMap { document -> ShoppingItem? in
                        do {
                            return try document.data(as: ShoppingItem.self)
                        } catch {
                            print("Error decoding item: \(error)")
                            return nil
                        }
                    }
                }
        }
    }
}

// MARK: - Model Extensions

/// Extension to convert ShoppingList to dictionary format for Firestore storage.
extension ShoppingList {
    /// Converts the shopping list to a dictionary for Firestore storage.
    /// - Returns: A dictionary representation of the shopping list
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "name": name,
            "color": color,
            "dueDate": dueDate?.timeIntervalSince1970 ?? NSNull(),
            "totalItems": totalItems,
            "completedItems": completedItems
        ]
    }
}

/// Extension to convert ShoppingItem to dictionary format for Firestore storage.
extension ShoppingItem {
    /// Converts the shopping item to a dictionary for Firestore storage.
    /// This method handles optional properties by only including them if they have values.
    /// - Returns: A dictionary representation of the shopping item
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "name": name,
            "checked": checked,
            "needToBuy": needToBuy,
            "useSimpleCount": useSimpleCount
        ]
        
        // Add optional properties only if they exist
        if let price = price { dict["price"] = price }
        if let originalPrice = originalPrice { dict["originalPrice"] = originalPrice }
        if let targetQuantity = targetQuantity { dict["targetQuantity"] = targetQuantity }
        if let targetUnit = targetUnit { dict["targetUnit"] = targetUnit }
        if let categoryId = categoryId { dict["categoryId"] = categoryId }
        if let categoryName = categoryName { dict["categoryName"] = categoryName }
        if let listId = listId { dict["listId"] = listId }
        if let listName = listName { dict["listName"] = listName }
        if let createdDate = createdDate { dict["createdDate"] = Timestamp(date: createdDate) }
        if let updatedDate = updatedDate { dict["updatedDate"] = Timestamp(date: updatedDate) }
        if let userId = userId { dict["userId"] = userId }
        if let currentQuantity = currentQuantity { dict["currentQuantity"] = currentQuantity }
        if let currentUnit = currentUnit { dict["currentUnit"] = currentUnit }
        
        return dict
    }
}