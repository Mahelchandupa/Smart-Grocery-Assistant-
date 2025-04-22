import SwiftUI
import FirebaseAuth

struct ListDetailView: View {
    let listId: String
    @Binding var navPath: NavigationPath
    @EnvironmentObject var authManager: AuthManager
    
    @State private var searchQuery = ""
    @State private var showAddItemModal = false
    @State private var loading = true
    @State private var categories: [CategoryWithItems] = []
    @State private var listName = "Shopping List"
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
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
                                .foregroundColor(Color(hex: "DCFCE7")) // Light green
                        }
                        
                        Spacer()
                    }
                }
                .padding(.top, 25)
                .padding(.bottom, 20)
                .padding(.horizontal, 16)
            }
            .frame(height: 60)
            
            // Search Bar
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
            
            if loading && categories.isEmpty {
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
                emptyListView
            } else {
                // Shopping List Items
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(filteredCategories) { category in
                            VStack(spacing: 0) {
                                // Category Header
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
                                
                                // Category Items
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
            
            // Bottom Action Bar
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
    
    // Computed properties
    private var totalItemsCount: Int {
        categories.reduce(0) { $0 + $1.items.count }
    }
    
    private var checkedItemsCount: Int {
        categories.reduce(0) { $0 + $1.items.filter(\.checked).count }
    }
    
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
    
    private func completedItemsCount(in category: CategoryWithItems) -> Int {
        category.items.filter(\.checked).count
    }
    
    // Functions
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

// Item Row Component
struct ItemRow: View {
    let item: ShoppingItem
    let categoryId: String
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
                
                // Quantity information
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
