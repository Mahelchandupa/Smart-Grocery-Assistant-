import SwiftUI

/// A view for adding a new shopping item to a list.
/// 
/// This view provides a form for users to enter details about a new shopping item,
/// including name, category, quantity type, and quantity information. It also supports
/// creating new categories on-the-fly.
struct AddItemView: View {
    /// The ID of the shopping list to which the new item will be added
    let listId: String
    
    /// Binding to control whether this view is presented
    @Binding var isPresented: Bool
    
    /// Callback that is executed when an item is successfully added
    var onItemAdded: () -> Void
    
    /// Authentication manager for user context and Firestore operations
    @EnvironmentObject var authManager: AuthManager
    
    // MARK: - State Properties
    
    /// Name of the item being created
    @State private var itemName = ""
    
    /// ID of the currently selected category
    @State private var selectedCategory: String = "Uncategorized"
    
    /// Flag indicating whether the "Add New Category" sheet is presented
    @State private var isAddingNewCategory = false
    
    /// Name for a new category being created
    @State private var newCategoryName = ""
    
    /// Legacy quantity field (not used in current implementation)
    @State private var quantity = ""
    
    /// Whether to use simple count (true) or custom unit (false) for quantity
    @State private var useSimpleCount = true
    
    /// Legacy unit field (not used in current implementation)
    @State private var unit = ""
    
    /// Current quantity when using simple count
    @State private var currentQuantity = ""
    
    /// Target quantity (how many needed) when using simple count
    @State private var targetQuantity = ""
    
    /// Current quantity description when using custom units
    @State private var currentUnit = ""
    
    /// Target quantity description when using custom units
    @State private var targetUnit = ""
    
    /// Flag indicating whether item creation is in progress
    @State private var isSubmitting = false
    
    /// Array of available categories for the user
    @State private var categories: [ShoppingCategory] = []
    
    /// Flag indicating whether categories are currently being loaded
    @State private var isLoadingCategories = true
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Item Details")) {
                    TextField("Item Name", text: $itemName)
                    
                    if isLoadingCategories {
                        HStack {
                            Text("Loading categories...")
                            Spacer()
                            ProgressView()
                        }
                    } else {
                        categoryPicker
                    }
                    
                    Picker("Quantity Type", selection: $useSimpleCount) {
                        Text("Simple Count").tag(true)
                        Text("Custom Unit").tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    if useSimpleCount {
                        HStack {
                            Text("Current:")
                            TextField("0", text: $currentQuantity)
                                .keyboardType(.numberPad)
                        }
                        
                        HStack {
                            Text("Need:")
                            TextField("1", text: $targetQuantity)
                                .keyboardType(.numberPad)
                        }
                    } else {
                        HStack {
                            Text("Current:")
                            TextField("e.g. 1 bottle", text: $currentUnit)
                        }
                        
                        HStack {
                            Text("Need:")
                            TextField("e.g. 2 bottles", text: $targetUnit)
                        }
                    }
                }
                
                Section {
                    Button(action: addItem) {
                        HStack {
                            Spacer()
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Text("Add Item")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .background(Color(hex: "16A34A"))
                        .cornerRadius(8)
                    }
                    .disabled(itemName.isEmpty || isSubmitting)
                }
            }
            .navigationTitle("Add New Item")
            .navigationBarItems(
                trailing: Button("Cancel") {
                    isPresented = false
                }
            )
            .sheet(isPresented: $isAddingNewCategory) {
                addNewCategoryView
            }
            .onAppear {
                loadCategories()
            }
        }
    }
    
    // MARK: - Subviews
    
    /// View for selecting or adding a category
    private var categoryPicker: some View {
        VStack {
            Picker("Category", selection: $selectedCategory) {
                ForEach(categories) { category in
                    Text(category.name).tag(category.id)
                }
                Divider()
                Text("+ Add New Category").tag("new_category")
            }
            .onChange(of: selectedCategory) { newValue in
                if newValue == "new_category" {
                    isAddingNewCategory = true
                    // Reset to first category after selecting "Add New"
                    selectedCategory = categories.first?.id ?? "Uncategorized"
                }
            }
        }
    }
    
    /// Sheet view for adding a new category
    private var addNewCategoryView: some View {
        NavigationView {
            Form {
                Section(header: Text("New Category")) {
                    TextField("Category Name", text: $newCategoryName)
                }
                
                Section {
                    Button(action: createNewCategory) {
                        HStack {
                            Spacer()
                            Text("Create Category")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .background(Color(hex: "16A34A"))
                        .cornerRadius(8)
                    }
                    .disabled(newCategoryName.isEmpty)
                }
            }
            .navigationTitle("Add New Category")
            .navigationBarItems(
                trailing: Button("Cancel") {
                    isAddingNewCategory = false
                    newCategoryName = ""
                }
            )
        }
    }
    
    // MARK: - Methods
    
    /// Loads the user's categories from Firestore
    private func loadCategories() {
        Task {
            isLoadingCategories = true
            
            guard let userId = authManager.currentFirebaseUser?.uid else {
                isLoadingCategories = false
                return
            }
            
            do {
                let fetchedCategories = try await FirestoreService.getUserCategories(userId: userId)
                
                // Add "Uncategorized" if it doesn't exist
                var updatedCategories = fetchedCategories
                if !updatedCategories.contains(where: { $0.name == "Uncategorized" }) {
                    let uncategorized = ShoppingCategory(id: "uncategorized", name: "Uncategorized")
                    updatedCategories.insert(uncategorized, at: 0)
                } else {
                    // Move Uncategorized to the front
                    if let index = updatedCategories.firstIndex(where: { $0.name == "Uncategorized" }) {
                        let uncategorized = updatedCategories.remove(at: index)
                        updatedCategories.insert(uncategorized, at: 0)
                    }
                }
                
                await MainActor.run {
                    self.categories = updatedCategories
                    if let firstCategory = categories.first {
                        self.selectedCategory = firstCategory.id
                    }
                    isLoadingCategories = false
                }
            } catch {
                print("Error loading categories: \(error.localizedDescription)")
                await MainActor.run {
                    // Add default "Uncategorized" category if loading fails
                    self.categories = [ShoppingCategory(id: "uncategorized", name: "Uncategorized")]
                    self.selectedCategory = "uncategorized"
                    isLoadingCategories = false
                }
            }
        }
    }
    
    /// Creates a new category and adds it to the available categories
    private func createNewCategory() {
        guard !newCategoryName.isEmpty else { return }
        
        Task {
            guard let userId = authManager.currentFirebaseUser?.uid else { return }
            
            do {
                let newCategory = try await FirestoreService.findOrCreateCategory(
                    userId: userId,
                    categoryName: newCategoryName
                )
                
                await MainActor.run {
                    // Add the new category to our list if it's not already there
                    if !categories.contains(where: { $0.id == newCategory.id }) {
                        categories.append(newCategory)
                    }
                    selectedCategory = newCategory.id
                    isAddingNewCategory = false
                    newCategoryName = ""
                }
            } catch {
                print("Error creating category: \(error.localizedDescription)")
            }
        }
    }
    
    /// Creates a new shopping item and adds it to the specified list
    private func addItem() {
        Task {
            guard let userId = authManager.currentFirebaseUser?.uid else { return }
            
            isSubmitting = true
            
            do {
                // Get the selected category
                guard let categoryObj = categories.first(where: { $0.id == selectedCategory }) else {
                    throw NSError(domain: "AddItemView", code: 400, userInfo: [NSLocalizedDescriptionKey: "Selected category not found"])
                }
                
                // Prepare item data
                var currentQty: Int? = nil
                var targetQty: Int? = nil
                var currentUnitValue: String? = nil
                var targetUnitValue: String? = nil
                
                if useSimpleCount {
                    currentQty = Int(currentQuantity) ?? 0
                    targetQty = Int(targetQuantity).flatMap { $0 > 0 ? $0 : 1 } ?? 1
                } else {
                    currentUnitValue = currentUnit.isEmpty ? nil : currentUnit
                    targetUnitValue = targetUnit.isEmpty ? nil : targetUnit
                }
                
                // Calculate needToBuy flag
                var needToBuy = false
                if useSimpleCount {
                    needToBuy = (currentQty ?? 0) < (targetQty ?? 1)
                } else {
                    needToBuy = targetUnitValue != nil && (currentUnitValue == nil || currentUnitValue!.isEmpty)
                }
                
                // Create the new item
                let newItem = ShoppingItem(
                    id: UUID().uuidString,
                    name: itemName,
                    checked: false,
                    needToBuy: needToBuy,
                    price: nil,
                    originalPrice: nil,
                    useSimpleCount: useSimpleCount,
                    targetQuantity: targetQty,
                    targetUnit: targetUnitValue,
                    categoryId: categoryObj.id,
                    categoryName: categoryObj.name,
                    listId: listId,
                    listName: nil,
                    createdDate: Date(),
                    updatedDate: Date(),
                    userId: userId,
                    currentQuantity: currentQty,
                    currentUnit: currentUnitValue
                )
                
                _ = try await FirestoreService.createItem(
                    userId: userId,
                    item: newItem,
                    listId: listId,
                    categoryId: categoryObj.id
                )
                
                await MainActor.run {
                    isSubmitting = false
                    isPresented = false
                    onItemAdded()
                }
            } catch {
                print("Error adding item: \(error.localizedDescription)")
                await MainActor.run {
                    isSubmitting = false
                }
            }
        }
    }
}