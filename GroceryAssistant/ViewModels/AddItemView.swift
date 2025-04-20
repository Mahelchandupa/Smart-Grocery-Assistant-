import SwiftUI

struct AddItemView: View {
    let listId: String
    @Binding var isPresented: Bool
    var onItemAdded: () -> Void
    @EnvironmentObject var authManager: AuthManager
    
    @State private var itemName = ""
    @State private var category = ""
    @State private var quantity = ""
    @State private var useSimpleCount = true
    @State private var unit = ""
    @State private var currentQuantity = ""
    @State private var targetQuantity = ""
    @State private var currentUnit = ""
    @State private var targetUnit = ""
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Item Details")) {
                    TextField("Item Name", text: $itemName)
                    
                    TextField("Category", text: $category)
                        .autocapitalization(.words)
                    
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
        }
    }
    
    private func addItem() {
        Task {
            guard let userId = authManager.currentFirebaseUser?.uid else { return }
            
            isSubmitting = true
            
            do {
                // Find or create category
                let categoryObj = try await FirestoreService.findOrCreateCategory(
                    userId: userId,
                    categoryName: category.isEmpty ? "Uncategorized" : category
                )
                
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
