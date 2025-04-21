import SwiftUI
import Firebase

struct ShoppingView: View {
    let itemID: String
    @Binding var navPath: NavigationPath
    @EnvironmentObject var authManager: AuthManager
    @State private var categories: [ShoppingCategory] = []
    @Environment(\.dismiss) private var dismiss 
    @State private var listName: String = "Shopping List"
    @State private var totalCost: Double = 0
    @State private var totalSavings: Double = 0
    @State private var loading: Bool = true
    @State private var showOnlyToBuy: Bool = true
    @State private var expandedCategories: [String: Bool] = [:]
    
    // For edit modal
    @State private var showEditModal: Bool = false
    @State private var currentEditItem: ShoppingItem?
    @State private var tempQuantity: String = ""
    @State private var tempUnit: String = ""
    @State private var tempPrice: String = ""
    @State private var tempOriginalPrice: String = ""
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGray6)
                .ignoresSafeArea()
            
            if loading && categories.isEmpty {
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .green))
                        .scaleEffect(1.5)
                    
                    Text("Loading shopping list...")
                        .foregroundColor(.gray)
                        .padding(.top)
                }
            } else {
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // Filter Toggle
                    filterToggleView
                    
                    // Shopping List
                    if filteredCategories.isEmpty {
                        emptyStateView
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 0, pinnedViews: []) {
                                ForEach(filteredCategories, id: \.id) { category in
                                    categorySection(category)
                                }
                                
                                // Summary
                                summaryView
                                    .padding(.horizontal)
                                    .padding(.bottom, 20)
                            }
                        }
                    }
                    
                    // Bottom Action Bar
                    bottomActionBar
                }
                .edgesIgnoringSafeArea(.bottom)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            fetchShoppingData()
        }
        .sheet(isPresented: $showEditModal) {
            editItemModal
        }
    }
    
    // Computed Properties
    
    private var filteredCategories: [ShoppingCategory] {
        if !showOnlyToBuy {
            return categories
        }
        
        return categories
            .map { category in
                var newCategory = category
                // Ensure items is not nil before filtering
                if let items = category.items {
                    newCategory.items = items.filter { item in
                        item.needToBuy && !item.checked
                    }
                } else {
                    newCategory.items = []
                }
                return newCategory
            }
            .filter { category in
                // Check if items exists and is not empty
                if let items = category.items {
                    return !items.isEmpty
                }
                return false
            }
    }
    
    private var totalItems: Int {
        categories.reduce(0) { sum, category in
            sum + (category.items?.count ?? 0)
        }
    }
    
    private var purchasedItems: Int {
        categories.reduce(0) { sum, category in
            sum + (category.items?.filter { $0.checked }.count ?? 0)
        }
    }
    
    private var toBuyItems: Int {
        categories.reduce(0) { sum, category in
            sum + (category.items?.filter { $0.needToBuy && !$0.checked }.count ?? 0)
        }
    }
    
    // UI Components
    // MARK: - Main Header Component
    private var headerView: some View {
        VStack(spacing: 0) {
            navigationHeader
            shoppingProgressSection
        }
        .background(Color.green)
    }

    // MARK: - Navigation Header Component
    private var navigationHeader: some View {
        HStack {
            backButton
            Spacer()
            cartStatus
        }
        .padding()
    }

    // MARK: - Back Button Component
    private var backButton: some View {
        Button(action: {
            dismiss()
        }) {
            HStack {
                Image(systemName: "arrow.left")
                    .foregroundColor(.white)
                
                Text(listName)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
        }
    }

    // MARK: - Cart Status Component
    private var cartStatus: some View {
        HStack {
            Text("\(purchasedItems)/\(totalItems)")
                .foregroundColor(Color.green.opacity(0.8))
            
            Image(systemName: "cart")
                .foregroundColor(.white)
        }
    }

    // MARK: - Shopping Progress Section Component
    private var shoppingProgressSection: some View {
        VStack(spacing: 4) {
            progressHeader
            ProgressBar(purchasedItems: purchasedItems, totalItems: totalItems)
                .frame(height: 8)
        }
        .padding()
        .background(Color.green.opacity(0.2))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.bottom)
    }

    // MARK: - Progress Header Component
    private var progressHeader: some View {
        HStack {
            Text("Shopping Progress")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            Spacer()
            
            Text("\(Int((Double(purchasedItems) / Double(max(totalItems, 1))) * 100))%")
                .foregroundColor(.white)
        }
    }

    private func ProgressBar(purchasedItems: Int, totalItems: Int) -> some View {
        let progress = CGFloat(purchasedItems) / CGFloat(max(totalItems, 1))
        let progressWidth = UIScreen.main.bounds.width * 0.9 * progress

        return ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.green.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.white, lineWidth: 1)
                )

            RoundedRectangle(cornerRadius: 5)
                .fill(Color.white)
                .frame(width: progressWidth, height: 8)
        }
        .frame(height: 8)
    }
    
    private var filterToggleView: some View {
        HStack {
            Button(action: {
                withAnimation {
                    showOnlyToBuy.toggle()
                }
            }) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(showOnlyToBuy ? Color.green : Color.gray, lineWidth: 1.5)
                            .frame(width: 20, height: 20)
                        
                        if showOnlyToBuy {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.green)
                                .frame(width: 20, height: 20)
                            
                            Image(systemName: "checkmark")
                                .resizable()
                                .frame(width: 10, height: 10)
                                .foregroundColor(.white)
                        }
                    }
                    
                    Text("Show only items to buy (\(toBuyItems))")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                }
            }
            
            Spacer()
            
            HStack {
                Text("Total:")
                    .foregroundColor(.gray)
                
                Text("$\(String(format: "%.2f", totalCost))")
                    .fontWeight(.bold)
            }
        }
        .padding()
        .background(Color.white)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.2)),
            alignment: .bottom
        )
    }
    
    private var emptyStateView: some View {
        VStack {
            Image(systemName: "cart")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 50, height: 50)
                .foregroundColor(.gray.opacity(0.5))
            
            Text(showOnlyToBuy
                ? "No items left to purchase!"
                : "No items in this shopping list")
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.top)
            
            Button(action: {
                if navPath.count > 0 {
                    navPath.removeLast()
                }
            }) {
                Text("Return to List")
                    .foregroundColor(.white)
                    .fontWeight(.medium)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.green)
                    .cornerRadius(20)
            }
            .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func categorySection(_ category: ShoppingCategory) -> some View {
        VStack(spacing: 0) {
            // Category Header
            Button(action: {
                withAnimation {
                    toggleCategoryExpanded(categoryId: category.id)
                }
            }) {
                HStack {
                    Text(category.name)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    HStack {
                        Text("\((category.items?.filter { $0.checked }.count ?? 0))/\(category.items?.count ?? 0)")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Image(systemName: expandedCategories[category.id, default: true] ? "chevron.up" : "chevron.down")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                }
                .padding()
                .background(Color(UIColor.systemGray5))
            }
            
            // Category Items
            if expandedCategories[category.id, default: true] {
                ForEach(category.items ?? [], id: \.id) { item in
                    itemRow(item, categoryId: category.id)
                }
            }
        }
    }
    
    private func itemRow(_ item: ShoppingItem, categoryId: String) -> some View {
        HStack(alignment: .center) {
            // Checkbox
            Button(action: {
                handleToggleItem(categoryId: categoryId, item: item)
            }) {
                ZStack {
                    Circle()
                        .stroke(item.checked ? Color.green : Color.gray, lineWidth: 1.5)
                        .frame(width: 24, height: 24)
                    
                    if item.checked {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 24, height: 24)
                        
                        Image(systemName: "checkmark")
                            .resizable()
                            .frame(width: 10, height: 10)
                            .foregroundColor(.white)
                    }
                }
                .padding(.trailing, 5)
            }
            
            // Item Details
            VStack(alignment: .leading) {
                Text(item.name)
                    .foregroundColor(item.checked ? .gray : .black)
                    .strikethrough(item.checked)
                
                HStack {
                    Text(item.useSimpleCount ? "Qty: \(item.targetQuantity ?? 1)" : item.targetUnit ?? "")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    if let price = item.price, price > 0 {
                        HStack(spacing: 2) {
                            if let originalPrice = item.originalPrice, originalPrice > price {
                                Text("$\(String(format: "%.2f", originalPrice))")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                    .strikethrough()
                            }
                            
                            Text("$\(String(format: "%.2f", price))")
                                .font(.subheadline)
                                .foregroundColor(.green)
                                .fontWeight(.medium)
                        }
                    } else {
                        Text("No price")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.leading, 5)
            
            Spacer()
            
            // Edit Button
            Button(action: {
                handleEditItem(item)
            }) {
                Image(systemName: "pencil")
                    .foregroundColor(.gray)
                    .padding(5)
            }
        }
        .padding()
        .background(Color.white)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.2)),
            alignment: .bottom
        )
    }
    
    private var summaryView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Shopping Summary")
                .font(.headline)
                .fontWeight(.bold)
            
            HStack {
                Text("Items Purchased:")
                Spacer()
                Text("\(purchasedItems) of \(totalItems)")
            }
            .font(.subheadline)
            
            HStack {
                Text("Subtotal:")
                Spacer()
                Text("$\(String(format: "%.2f", totalCost))")
            }
            .font(.subheadline)
            
            if totalSavings > 0 {
                HStack {
                    Text("Savings:")
                    Spacer()
                    Text("-$\(String(format: "%.2f", totalSavings))")
                        .foregroundColor(.green)
                }
                .font(.subheadline)
            }
            
            Divider()
            
            HStack {
                Text("Total:")
                    .fontWeight(.bold)
                Spacer()
                Text("$\(String(format: "%.2f", totalCost))")
                    .fontWeight(.bold)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.top)
    }
    
    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            Divider()
            
            Button(action: {
                if navPath.count > 0 {
                    navPath.removeLast()
                }
            }) {
                Text("Return to List")
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(25)
                    .padding(.horizontal)
                    .padding(.vertical, 30)
            }
            .background(Color.white)
        }
    }
    
    private var editItemModal: some View {
        let item = currentEditItem
        
        return NavigationStack {
            VStack(spacing: 20) {
                // Quantity Input
                VStack(alignment: .leading, spacing: 8) {
                    Text(item?.useSimpleCount ?? true ? "Quantity" : "Unit/Amount")
                        .fontWeight(.medium)
                    
                    if item?.useSimpleCount ?? true {
                        TextField("Enter quantity", text: $tempQuantity)
                            .keyboardType(.numberPad)
                            .padding()
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(10)
                    } else {
                        TextField("e.g. 1kg, 2 boxes", text: $tempUnit)
                            .padding()
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(10)
                    }
                }
                
                // Price Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Price")
                        .fontWeight(.medium)
                    
                    HStack {
                        Image(systemName: "dollarsign")
                            .foregroundColor(.gray)
                        
                        TextField("0.00", text: $tempPrice)
                            .keyboardType(.decimalPad)
                    }
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(10)
                }
                
                // Original Price Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Original Price (optional)")
                        .fontWeight(.medium)
                    
                    HStack {
                        Image(systemName: "dollarsign")
                            .foregroundColor(.gray)
                        
                        TextField("0.00", text: $tempOriginalPrice)
                            .keyboardType(.decimalPad)
                    }
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(10)
                    
                    Text("Enter original price if the item is on sale to track savings")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Action Buttons
                HStack {
                    Button(action: {
                        showEditModal = false
                    }) {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(UIColor.systemGray5))
                            .foregroundColor(.black)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        saveItemChanges()
                    }) {
                        Text("Save Changes")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .fontWeight(.medium)
                            .cornerRadius(10)
                    }
                }
            }
            .padding()
            .navigationTitle("Update \(item?.name ?? "Item")")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showEditModal = false
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
    
    // Functions
    private func fetchShoppingData() {
        Task {
            do {
                loading = true
                guard let userId = authManager.currentFirebaseUser?.uid else { return }
                
                // Get list name
                let list = try await FirestoreService.getListById(userId: userId, listId: itemID)
                listName = list.name
                
                // Get items for this list
                let items = try await FirestoreService.getListItems(userId: userId, listId: itemID)
                
                // Group by category
                let groupedItems = groupItemsByCategory(items)
                
                // Update state on main thread
                DispatchQueue.main.async {
                    self.categories = groupedItems
                    
                    // Initialize expanded categories
                    var expanded = [String: Bool]()
                    for cat in groupedItems {
                        expanded[cat.id] = true
                    }
                    self.expandedCategories = expanded
                    
                    // Calculate totals
                    self.calculateTotals()
                    self.loading = false
                }
            } catch {
                print("Error fetching shopping data: \(error)")
                DispatchQueue.main.async {
                    self.loading = false
                }
            }
        }
    }
    
    private func groupItemsByCategory(_ items: [ShoppingItem]) -> [ShoppingCategory] {
        var categoriesDict = [String: ShoppingCategory]()
        
        for item in items {
            let categoryKey = item.categoryId ?? "uncategorized"
            let categoryName = item.categoryName ?? "Uncategorized"
            
            if categoriesDict[categoryKey] == nil {
                categoriesDict[categoryKey] = ShoppingCategory(
                    id: categoryKey,
                    name: categoryName,
                    items: []
                )
            }
            
            // Make a mutable copy of the category
            if var category = categoriesDict[categoryKey] {
                // Ensure items is initialized
                if category.items == nil {
                    category.items = []
                }
                // Append the item
                category.items?.append(item)
                // Update the dictionary
                categoriesDict[categoryKey] = category
            }
        }
        
        return Array(categoriesDict.values)
    }
    
    private func calculateTotals() {
        var cost: Double = 0
        var savings: Double = 0
        
        for category in categories {
            for item in category.items ?? [] {
                if let price = item.price {
                    cost += price
                    
                    if let originalPrice = item.originalPrice, originalPrice > price {
                        savings += (originalPrice - price)
                    }
                }
            }
        }
        
        totalCost = cost
        totalSavings = savings
    }
    
    private func handleToggleItem(categoryId: String, item: ShoppingItem) {
        // If item is being marked as purchased but has no price, open edit modal
        if !item.checked && (item.price == nil || item.price == 0) {
            handleEditItem(item)
            return
        }
        
        // Optimistically update UI
        for (index, category) in categories.enumerated() {
            if category.id == categoryId {
                if var items = category.items {
                    for (itemIndex, categoryItem) in items.enumerated() {
                        if categoryItem.id == item.id {
                            items[itemIndex].checked.toggle()
                            categories[index].items = items
                            break
                        }
                    }
                }
            }
        }
        
        // Update in Firestore
        Task {
            do {
                guard let userId = authManager.currentFirebaseUser?.uid else { return }
                try await FirestoreService.toggleItemChecked(
                    userId: userId,
                    itemId: item.id,
                    isChecked: !item.checked,
                    listId: itemID
                )
                
                // Recalculate totals after toggling
                DispatchQueue.main.async {
                    self.calculateTotals()
                }
            } catch {
                print("Error toggling item: \(error)")
                // Revert the optimistic update by refetching
                fetchShoppingData()
            }
        }
    }
    
    private func handleEditItem(_ item: ShoppingItem) {
        currentEditItem = item
        
        // Set initial values for edit form
        if item.useSimpleCount {
            tempQuantity = item.targetQuantity != nil ? "\(item.targetQuantity!)" : ""
        } else {
            tempUnit = item.targetUnit ?? ""
        }
        
        tempPrice = item.price != nil ? "\(item.price!)" : ""
        tempOriginalPrice = item.originalPrice != nil ? "\(item.originalPrice!)" : ""
        
        showEditModal = true
    }
    
    private func saveItemChanges() {
        guard let item = currentEditItem else {
            showEditModal = false
            return
        }
        
        var updates = [String: Any]()
        
        // Handle quantity updates
        if item.useSimpleCount {
            if let quantity = Int(tempQuantity) {
                updates["targetQuantity"] = quantity
            }
        } else if !tempUnit.isEmpty {
            updates["targetUnit"] = tempUnit
        }
        
        // Handle price updates
        if let price = Double(tempPrice) {
            updates["price"] = price
        } else {
            updates["price"] = nil
        }
        
        if let originalPrice = Double(tempOriginalPrice) {
            updates["originalPrice"] = originalPrice
        } else {
            updates["originalPrice"] = nil
        }
        
        // Close the modal first to improve UI responsiveness
        showEditModal = false
        
        // Update Firestore
        Task {
            do {
                guard let userId = authManager.currentFirebaseUser?.uid else { return }
                try await FirestoreService.updateItem(
                    userId: userId,
                    itemId: item.id,
                    updates: updates
                )
                
                // After successful update, refresh the data instead of manual updating
                await fetchUpdatedData()
            } catch {
                print("Error updating item: \(error)")
                // Show error alert or feedback to user
            }
        }
    }
    
    private func fetchUpdatedData() async {
        do {
            guard let userId = authManager.currentFirebaseUser?.uid else { return }
            let items = try await FirestoreService.getListItems(userId: userId, listId: itemID)
            let groupedItems = groupItemsByCategory(items)
            
            // Update state on main thread
            DispatchQueue.main.async {
                self.categories = groupedItems
                self.calculateTotals()
            }
        } catch {
            print("Error refreshing data: \(error)")
        }
    }
    
    private func toggleCategoryExpanded(categoryId: String) {
        expandedCategories[categoryId] = !(expandedCategories[categoryId] ?? true)
    }
}

// Preview Provider for SwiftUI Canvas
struct ShoppingView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ShoppingView(itemID: "preview-list-id", navPath: .constant(NavigationPath()))
                .environmentObject(AuthManager())
        }
    }
}
