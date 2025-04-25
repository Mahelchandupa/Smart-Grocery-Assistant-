import SwiftUI
import FirebaseAuth

/// A view that displays the detailed contents of a shopping list.
///
/// This view shows all items in a shopping list grouped by category,
/// allows checking items off, searching for specific items, and adding
/// new items to the list.
struct ListDetailView: View {
    /// The unique identifier of the shopping list to display
    let listId: String
    
    /// Navigation path for handling navigation within the app
    @Binding var navPath: NavigationPath
    
    /// Authentication manager for user context
    @EnvironmentObject var authManager: AuthManager
    
    /// Text entered in the search field for filtering items
    @State private var searchQuery = ""
    
    /// Flag controlling whether the add item modal is displayed
    @State private var showAddItemModal = false
    
    /// Flag indicating whether data is currently loading
    @State private var loading = true
    
    /// Categories with their associated items from the shopping list
    @State private var categories: [CategoryWithItems] = []
    
    /// Name of the shopping list
    @State private var listName = "Shopping List"
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with list name and item count
            ZStack {
                Color(hex: "4CAF50")
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
                            Text(listName)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("\(checkedItemsCount) of \(totalItemsCount) items")
                                .font(.subheadline)
                                .foregroundColor(Color(hex: "DCFCE7"))
                        }
                        
                        Spacer()
                    }
                }
                .padding(.top, 25)
                .padding(.bottom, 20)
                .padding(.horizontal, 16)
            }
            .frame(height: 60)
            
            // Search bar and add button
            HStack(spacing: 8) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color(hex: "9CA3AF"))
                        .padding(.leading, 12)
                    
                    TextField("Search items...", text: $searchQuery)
                        .padding(.vertical, 12)
                }
                .background(Color(hex: "F3F4F6"))
                .cornerRadius(20)
                
                Button(action: {
                    showAddItemModal = true
                }) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "16A34A"))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                            .font(.system(size: 20))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            
            // Content area with conditional states
            if loading && categories.isEmpty {
                // Loading state
                VStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.3)
                        .tint(Color(hex: "16A34A"))
                    
                    Text("Loading list items...")
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "6B7280"))
                        .padding(.top, 16)
                    Spacer()
                }
            } else if filteredCategories.isEmpty {
                // Empty state
                emptyListView
            } else {
                // Shopping list items grouped by category
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(filteredCategories) { category in
                            VStack(spacing: 0) {
                                // Category header
                                HStack {
                                    Text(category.name)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color(hex: "4B5563"))
                                    
                                    Spacer()
                                    
                                    Text("\(completedItemsCount(in: category))/\(category.items.count)")
                                        .font(.caption)
                                        .foregroundColor(Color(hex: "6B7280"))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color(hex: "F3F4F6"))
                                
                                // Category items
                                ForEach(category.items) { item in
                                    ItemRow(
                                        item: item, 
                                        categoryId: category.id,
                                        onToggle: handleToggleItem
                                    )
                                    .background(Color.white)
                                    Divider()
                                }
                            }
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.vertical, 16)
                }
                .background(Color(hex: "F9FAFB"))
            }
            
            // Bottom action bar with start shopping button
            VStack {
                Button(action: {
                    navPath.append(Route.shopping(id: listId))
                }) {
                    Text("Start Shopping")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(hex: "16A34A"))
                        .cornerRadius(24)
                        .padding(.horizontal, 16)
                }
                .padding(.vertical, 30)
                .background(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: -2)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationBarHidden(true)
        .onAppear {
            fetchListData()
        }
        .sheet(isPresented: $showAddItemModal) {
            AddItemView(
                listId: listId,
                isPresented: $showAddItemModal,
                onItemAdded: {
                    fetchListData()
                }
            )
        }
    }
    
    /// View displayed when the list is empty or no search results are found
    private var emptyListView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "bag")
                .font(.system(size: 48))
                .foregroundColor(Color(hex: "D1D5DB"))
            
            if searchQuery.isEmpty {
                Text("No items in this list yet")
                    .font(.headline)
                    .foregroundColor(Color(hex: "9CA3AF"))
                
                Button(action: {
                    showAddItemModal = true
                }) {
                    Text("Add First Item")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color(hex: "16A34A"))
                        .cornerRadius(24)
                }
                .padding(.top, 8)
            } else {
                Text("No items match your search")
                    .font(.headline)
                    .foregroundColor(Color(hex: "9CA3AF"))
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color(hex: "F9FAFB"))
    }
    
    // MARK: - Computed Properties
    
    /// Total number of items in the shopping list
    private var totalItemsCount: Int {
        categories.reduce(0) { $0 + $1.items.count }
    }
    
    /// Number of checked (completed) items in the list
    private var checkedItemsCount: Int {
        categories.reduce(0) { $0 + $1.items.filter(\.checked).count }
    }
    
    /// Filtered categories based on the search query
    private var filteredCategories: [CategoryWithItems] {
        if searchQuery.isEmpty {
            return categories
        }
        
        return categories.compactMap { category in
            let filteredItems = category.items.filter {
                $0.name.lowercased().contains(searchQuery.lowercased())
            }
            
            if filteredItems.isEmpty {
                return nil
            }
            
            return CategoryWithItems(
                id: category.id,
                name: category.name,
                items: filteredItems
            )
        }
    }
    
    /// Calculates the number of completed items within a category
    /// - Parameter category: The category to count completed items for
    /// - Returns: The number of checked items in the category
    private func completedItemsCount(in category: CategoryWithItems) -> Int {
        category.items.filter(\.checked).count
    }
    
    // MARK: - Data Operations
    
    /// Fetches list data including items and categories from Firestore
    private func fetchListData() {
        Task {
            do {
                guard let userId = Auth.auth().currentUser?.uid else {
                    throw NSError(domain: "ListDetailView", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
                }
                
                loading = true
                
                // Fetch list details
                let list = try await FirestoreService.getListById(userId: userId, listId: listId)
                
                // Fetch list items
                let items = try await FirestoreService.getListItems(userId: userId, listId: listId)
                
                // Group items by category
                let groupedItems = Dictionary(grouping: items) { item in
                    item.categoryName ?? item.categoryId ?? "Uncategorized"
                }
                
                // Create categories with items
                let categoriesWithItems = groupedItems.map { key, items in
                    let categoryId = items.first?.categoryId ?? key
                    let categoryName = items.first?.categoryName ?? key
                    
                    return CategoryWithItems(
                        id: categoryId,
                        name: categoryName,
                        items: items
                    )
                }.sorted { $0.name < $1.name }
                
                await MainActor.run {
                    self.listName = list.name
                    self.categories = categoriesWithItems
                    self.loading = false
                }
            } catch {
                print("Error fetching list data: \(error.localizedDescription)")
                await MainActor.run {
                    self.loading = false
                }
            }
        }
    }
    
    /// Handles toggling the checked state of an item
    /// - Parameters:
    ///   - categoryId: ID of the category containing the item
    ///   - itemId: ID of the item to toggle
    ///   - isChecked: Current checked state of the item
    private func handleToggleItem(categoryId: String, itemId: String, isChecked: Bool) {
        Task {
            do {
                guard let userId = Auth.auth().currentUser?.uid else { return }
                
                // Optimistic UI update
                updateItemCheckedState(categoryId: categoryId, itemId: itemId, isChecked: !isChecked)
                
                // Update in Firestore
                try await FirestoreService.toggleItemChecked(userId: userId, itemId: itemId, isChecked: !isChecked, listId: listId)
            } catch {
                print("Error toggling item: \(error.localizedDescription)")
                // Revert on error
                updateItemCheckedState(categoryId: categoryId, itemId: itemId, isChecked: isChecked)
            }
        }
    }
    
    /// Updates the local checked state of an item
    /// - Parameters:
    ///   - categoryId: ID of the category containing the item
    ///   - itemId: ID of the item to update
    ///   - isChecked: New checked state for the item
    private func updateItemCheckedState(categoryId: String, itemId: String, isChecked: Bool) {
        categories = categories.map { category in
            if category.id == categoryId {
                var updatedItems = category.items
                if let index = updatedItems.firstIndex(where: { $0.id == itemId }) {
                    updatedItems[index].checked = isChecked
                }
                
                return CategoryWithItems(
                    id: category.id,
                    name: category.name,
                    items: updatedItems
                )
            }
            return category
        }
    }
}

/// A row component that displays a shopping item with a checkbox and details.
///
/// This component shows an item's name, quantity information, and checked state,
/// and allows toggling the checked state by tapping the checkbox.
struct ItemRow: View {
    /// The shopping item to display
    let item: ShoppingItem
    
    /// ID of the category containing this item
    let categoryId: String
    
    /// Callback function called when the item is toggled
    let onToggle: (String, String, Bool) -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Checkbox
            Button(action: {
                onToggle(categoryId, item.id, item.checked)
            }) {
                ZStack {
                    Circle()
                        .stroke(item.checked ? Color(hex: "16A34A") : Color(hex: "9CA3AF"), lineWidth: 1.5)
                        .frame(width: 24, height: 24)
                    
                    if item.checked {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(hex: "16A34A"))
                    }
                }
            }
            .frame(width: 24, height: 24)
            .padding(.top, 2)
            
            // Item details
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.body)
                    .foregroundColor(item.checked ? Color(hex: "9CA3AF") : Color(hex: "1F2937"))
                    .strikethrough(item.checked)
                
                // Quantity information - simple count
                if item.useSimpleCount != false {
                    HStack {
                        if let current = item.currentQuantity {
                            Text("Have: \(current)")
                                .font(.caption)
                                .foregroundColor(Color(hex: "6B7280"))
                        }
                        
                        if let target = item.targetQuantity {
                            Text("Need: \(target)")
                                .font(.caption)
                                .foregroundColor(Color(hex: "6B7280"))
                        }
                        
                        if let current = item.currentQuantity, 
                           let target = item.targetQuantity,
                           item.needToBuy == true && target > current {
                            Text("(Buy \(target - current))")
                                .font(.caption)
                                .foregroundColor(Color(hex: "F97316"))
                        }
                    }
                } else {
                    // Quantity information - custom unit
                    HStack {
                        if let current = item.currentUnit, !current.isEmpty {
                            Text("Have: \(current)")
                                .font(.caption)
                                .foregroundColor(Color(hex: "6B7280"))
                        }
                        
                        if let target = item.targetUnit, !target.isEmpty {
                            Text("Need: \(target)")
                                .font(.caption)
                                .foregroundColor(Color(hex: "6B7280"))
                        }
                    }
                }
            }
            
            Spacer()
            
            // Need to buy indicator
            Image(systemName: "bag")
                .foregroundColor(item.needToBuy == true ? Color(hex: "F97316") : Color(hex: "9CA3AF"))
                .font(.system(size: 18))
                .padding(.top, 2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}