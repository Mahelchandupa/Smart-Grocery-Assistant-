import FirebaseFirestore
import FirebaseAuth
import Foundation

/// A service struct that provides methods for interacting with Firestore database.
/// This service handles all database operations related to users, shopping lists,
/// items, categories, reminders, and purchases.
struct FirestoreService {
    /// The Firestore database instance used for all operations
    private static let db = Firestore.firestore()
    
    // MARK: - User Operations
    
    /// Saves user data to the Firestore database.
    ///
    /// - Parameters:
    ///   - uid: The user's unique identifier
    ///   - data: A dictionary containing user data to save
    /// - Throws: Firestore errors if the save operation fails
    static func saveUserData(uid: String, data: [String: Any]) async throws {
        try await db.collection("users").document(uid).setData(data)
    }
    
    /// Retrieves user data from the Firestore database.
    ///
    /// - Parameter uid: The user's unique identifier
    /// - Throws: AuthError.notAuthenticated if user data is not found
    /// - Returns: A dictionary containing the user's data
    static func getUserData(uid: String) async throws -> [String: Any] {
          let db = Firestore.firestore()
          let document = try await db.collection("users").document(uid).getDocument()
          
          guard let data = document.data() else {
              throw AuthError.notAuthenticated
          }
          
          return data
      }
    
    // MARK: - Shopping List Operations
    
    /// Creates a new shopping list for the specified user.
    ///
    /// - Parameters:
    ///   - userId: The user's unique identifier
    ///   - list: The ShoppingList object to store
    /// - Throws: Firestore errors if the creation fails
    static func createList(userId: String, list: ShoppingList) async throws {
        let listWithDate = list.toDictionary() // Convert to [String: Any]
        try await db.collection("users")
            .document(userId)
            .collection("lists")
            .document(list.id)
            .setData(listWithDate)
    }
    
    /// Retrieves all shopping lists for the specified user.
    ///
    /// - Parameter userId: The user's unique identifier
    /// - Throws: Firestore errors if the retrieval fails
    /// - Returns: An array of ShoppingList objects
    static func getUserLists(userId: String) async throws -> [ShoppingList] {
        let snapshot = try await db.collection("users")
            .document(userId)
            .collection("lists")
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? document.data(as: ShoppingList.self)
        }
    }
    
    /// Retrieves a specific shopping list by its ID.
    ///
    /// - Parameters:
    ///   - userId: The user's unique identifier
    ///   - listId: The ID of the shopping list to retrieve
    /// - Throws: NSError with code 404 if the list is not found
    /// - Returns: The requested ShoppingList object
    static func getListById(userId: String, listId: String) async throws -> ShoppingList {
        let documentSnapshot = try await db.collection("users")
            .document(userId)
            .collection("lists")
            .document(listId)
            .getDocument()
        
        guard let list = try? documentSnapshot.data(as: ShoppingList.self) else {
            throw NSError(domain: "FirestoreService", code: 404, userInfo: [NSLocalizedDescriptionKey: "List not found"])
        }
        
        return list
    }
    
    // MARK: - Shopping Item Operations
    
    /// Retrieves all items in a specific shopping list.
    ///
    /// - Parameters:
    ///   - userId: The user's unique identifier
    ///   - listId: The ID of the shopping list
    /// - Throws: Firestore errors if the retrieval fails
    /// - Returns: An array of ShoppingItem objects
    static func getListItems(userId: String, listId: String) async throws -> [ShoppingItem] {
        let querySnapshot = try await db.collection("users")
            .document(userId)
            .collection("items")
            .whereField("listId", isEqualTo: listId)
            .getDocuments()
        
        return querySnapshot.documents.compactMap { document in
            try? document.data(as: ShoppingItem.self)
        }
    }
    
    /// Retrieves all shopping items across all lists for the specified user.
    ///
    /// - Parameter userId: The user's unique identifier
    /// - Throws: Firestore errors if the retrieval fails
    /// - Returns: An array of ShoppingItem objects
    static func getAllItems(userId: String) async throws -> [ShoppingItem] {
        let querySnapshot = try await db.collection("users")
            .document(userId)
            .collection("items")
            .getDocuments()
        
        return querySnapshot.documents.compactMap { document in
            try? document.data(as: ShoppingItem.self)
        }
    }
    
    /// Toggles the checked state of a shopping item and updates the list's completed items count.
    ///
    /// - Parameters:
    ///   - userId: The user's unique identifier
    ///   - itemId: The ID of the item to update
    ///   - isChecked: The new checked state
    ///   - listId: The ID of the shopping list containing the item
    /// - Throws: Firestore errors if the update fails
    static func toggleItemChecked(userId: String, itemId: String, isChecked: Bool, listId: String) async throws {
        let userRef = db.collection("users").document(userId)
        let itemRef = userRef.collection("items").document(itemId)
        let listRef = userRef.collection("lists").document(listId)

        // 1. Update item checked state
        try await itemRef.updateData([
            "checked": isChecked,
            "updatedDate": FieldValue.serverTimestamp()
        ])

        // 2. Update completedItems count in the list
        let incrementAmount: Int64 = isChecked ? 1 : -1

        try await listRef.updateData([
            "completedItems": FieldValue.increment(incrementAmount)
        ])
    }
    
    /// Updates a shopping item with the specified changes.
    ///
    /// - Parameters:
    ///   - userId: The user's unique identifier
    ///   - itemId: The ID of the item to update
    ///   - updates: A dictionary containing the fields to update and their new values
    /// - Throws: NSError with code 404 if the item is not found
    static func updateItem(userId: String, itemId: String, updates: [String: Any]) async throws {
        var updatedData = updates
        updatedData["updatedDate"] = FieldValue.serverTimestamp()
        
        // Try to get the document first to check if it exists
        let docRef = db.collection("users")
            .document(userId)
            .collection("items")
            .document(itemId)
        
        let docSnapshot = try await docRef.getDocument()
        
        if !docSnapshot.exists {
            print("WARNING: Document with ID \(itemId) does not exist in Firestore!")
            
            // throw an error
            throw NSError(domain: "FirestoreService", code: 404,
                         userInfo: [NSLocalizedDescriptionKey: "Item with ID \(itemId) not found"])
        }
        
        // The document exists, so proceed with the update
        try await docRef.updateData(updatedData)
    }
    
    /// Creates a new shopping item and adds it to a list.
    ///
    /// - Parameters:
    ///   - userId: The user's unique identifier
    ///   - item: The ShoppingItem object to create
    ///   - listId: The ID of the shopping list to add the item to
    ///   - categoryId: Optional category ID to associate with the item
    /// - Throws: Firestore errors if the creation fails or NSError if retrieval fails
    /// - Returns: The created ShoppingItem with server-generated timestamps
    static func createItem(userId: String, item: ShoppingItem, listId: String, categoryId: String?) async throws -> ShoppingItem {
        let userRef = db.collection("users").document(userId)
        let itemsCollection = userRef.collection("items")
        let listRef = userRef.collection("lists").document(listId)
        
        var itemData = item.toDictionary()
        itemData["listId"] = listId
        itemData["categoryId"] = categoryId
        itemData["userId"] = userId
        itemData["createdDate"] = FieldValue.serverTimestamp()
        itemData["updatedDate"] = FieldValue.serverTimestamp()
        itemData["checked"] = item.checked

        // Create the item document
        try await itemsCollection.document(item.id).setData(itemData)

        // Increment the totalItems count in the list document
        try await listRef.updateData([
            "totalItems": FieldValue.increment(Int64(1))
        ])
        
        if item.checked {
            itemData["completedItems"] = FieldValue.increment(Int64(1))
        }

        // Retrieve the newly created item to get server timestamps
        let newItem = try await itemsCollection.document(item.id).getDocument()
        guard var createdItem = try? newItem.data(as: ShoppingItem.self) else {
            throw NSError(domain: "FirestoreService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to retrieve created item"])
        }

        return createdItem
    }

    // MARK: - Category Operations
    
    /// Finds an existing category by name or creates a new one if it doesn't exist.
    ///
    /// - Parameters:
    ///   - userId: The user's unique identifier
    ///   - categoryName: The name of the category to find or create
    /// - Throws: Firestore errors if the operation fails
    /// - Returns: The found or created ShoppingCategory  
    static func findOrCreateCategory(userId: String, categoryName: String) async throws -> ShoppingCategory {
        // Check if category exists
        let querySnapshot = try await db.collection("users")
            .document(userId)
            .collection("categories")
            .whereField("name", isEqualTo: categoryName)
            .getDocuments()
        
        // If found, return existing category
        if let document = querySnapshot.documents.first,
           let existingCategory = try? document.data(as: ShoppingCategory.self) {
            return existingCategory
        }
        
        // Otherwise create a new category
        let categoryId = UUID().uuidString
        let newCategory = ShoppingCategory(
            id: categoryId,
            name: categoryName
        )
        
        var categoryData = newCategory.toDictionary()
        categoryData["createdDate"] = FieldValue.serverTimestamp()
        categoryData["userId"] = userId
        
        try await db.collection("users")
            .document(userId)
            .collection("categories")
            .document(categoryId)
            .setData(categoryData)
        
        return newCategory
    }

    /// Retrieves all categories for the specified user.
    ///
    /// - Parameter userId: The user's unique identifier
    /// - Throws: Firestore errors if the retrieval fails
    /// - Returns: An array of ShoppingCategory objects sorted by name
    static func getUserCategories(userId: String) async throws -> [ShoppingCategory] {
        let querySnapshot = try await db.collection("users")
            .document(userId)
            .collection("categories")
            .order(by: "name")
            .getDocuments()
        
        return querySnapshot.documents.compactMap { document in
            // Get the document data
            let data = document.data()
            
            // Extract the name from the data
            guard let name = data["name"] as? String else { return nil }
            
            // Create a ShoppingCategory object
            return ShoppingCategory(
                id: document.documentID,
                name: name
            )
        }
    }

    // MARK: - Reminder Operations
    
    /// Retrieves all reminders for the specified user.
    ///
    /// - Parameter userId: The user's unique identifier
    /// - Throws: Firestore errors or NSError if data format is invalid
    /// - Returns: An array of ShoppingReminder objects
    static func getReminders(userId: String) async throws -> [ShoppingReminder] {
        let snapshot = try await db.collection("users")
            .document(userId)
            .collection("reminders")
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            let data = document.data()
            
            // Get all the fields
            guard let id = data["id"] as? String,
                  let typeRaw = data["type"] as? String,
                  let type = ReminderType(rawValue: typeRaw),
                  let title = data["title"] as? String,
                  let listId = data["listId"] as? String,
                  let timestamp = data["date"] as? Timestamp,
                  let message = data["message"] as? String,
                  let isActive = data["isActive"] as? Bool else {
                throw NSError(domain: "FirestoreService", code: 400, userInfo: [
                    NSLocalizedDescriptionKey: "Invalid reminder data format"
                ])
            }
            
            // Optional fields
            let listName = data["listName"] as? String
            let itemId = data["itemId"] as? String
            let eventId = data["eventId"] as? String
            
            // Convert Timestamp to Date
            let date = timestamp.dateValue()
            
            return ShoppingReminder(
                id: id,
                type: type,
                title: title,
                listId: listId,
                listName: listName,
                itemId: itemId,
                date: date,
                message: message,
                isActive: isActive,
                eventId: eventId
            )
        }
    }
    
    /// Saves a new reminder to the Firestore database.
    ///
    /// - Parameters:
    ///   - userId: The user's unique identifier
    ///   - reminder: The ShoppingReminder object to save
    /// - Throws: Firestore errors if the save operation fails
    static func saveReminder(userId: String, reminder: ShoppingReminder) async throws {
        var reminderData = reminder.toDictionary()
        
        // Date is stored as a Timestamp
        reminderData["date"] = Timestamp(date: reminder.date)
        reminderData["createdAt"] = FieldValue.serverTimestamp()
        reminderData["updatedAt"] = FieldValue.serverTimestamp()
        
        try await db.collection("users")
            .document(userId)
            .collection("reminders")
            .document(reminder.id)
            .setData(reminderData)
    }
    
    /// Updates a reminder's active status.
    ///
    /// - Parameters:
    ///   - userId: The user's unique identifier
    ///   - reminderId: The ID of the reminder to update
    ///   - isActive: The new active status
    /// - Throws: Firestore errors if the update fails
    static func updateReminder(userId: String, reminderId: String, isActive: Bool) async throws {
        try await db.collection("users")
            .document(userId)
            .collection("reminders")
            .document(reminderId)
            .updateData([
                "isActive": isActive,
                "updatedAt": FieldValue.serverTimestamp()
            ])
    }
    
    /// Deletes a reminder from the Firestore database.
    ///
    /// - Parameters:
    ///   - userId: The user's unique identifier
    ///   - reminderId: The ID of the reminder to delete
    /// - Throws: Firestore errors if the deletion fails
    static func deleteReminder(userId: String, reminderId: String) async throws {
        try await db.collection("users")
            .document(userId)
            .collection("reminders")
            .document(reminderId)
            .delete()
    }
    
    // MARK: - Purchase Operations
    
    /// Saves purchased items to the Firestore database.
    ///
    /// - Parameters:
    ///   - userId: The user's unique identifier
    ///   - purchaseId: The ID of the purchase
    ///   - items: An array of ShoppingItem objects that were purchased
    /// - Throws: Firestore errors if the save operation fails
    static func savePurchaseItems(userId: String, purchaseId: String, items: [ShoppingItem]) async throws {
        let batch = db.batch()
        
        for item in items {
            let itemRef = db.collection("users")
                .document(userId)
                .collection("purchaseItems")
                .document()
            
            var itemData = item.toDictionary()
            itemData["purchaseId"] = purchaseId
            
            batch.setData(itemData, forDocument: itemRef)
        }
        
        try await batch.commit()
    }
    
    /// Creates a new purchase record from a shopping list.
    ///
    /// - Parameters:
    ///   - list: The ShoppingList that items were purchased from
    ///   - items: An array of ShoppingItem objects that were purchased
    ///   - store: The name of the store where items were purchased
    ///   - totalSpent: The total amount spent on the purchase
    /// - Throws: AuthError.notAuthenticated if no user is signed in, or Firestore errors
    /// - Returns: The created Purchase object
    static func createPurchaseFromList(list: ShoppingList, items: [ShoppingItem], store: String, totalSpent: Double) async throws -> Purchase {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw AuthError.notAuthenticated
        }
        
        let purchase = Purchase(
            id: UUID().uuidString,
            listId: list.id,
            listName: list.name,
            date: Date(),
            itemCount: items.count,
            totalSpent: totalSpent,
            storeName: store,
            userId: userId
        )
        
        try await db.collection("users")
            .document(userId)
            .collection("purchases")
            .document(purchase.id)
            .setData(from: purchase)
        
        return purchase
    }
    
    // MARK: - Shop Operations
    
    /// Retrieves all available items for purchase from the shop.
    ///
    /// - Throws: Firestore errors if the retrieval fails
    /// - Returns: An array of Buy objects representing available items
    static func getBuyItems() async throws -> [Buy] {
        let snapshot = try await db.collection("shop").getDocuments()
        
        var buyItems: [Buy] = []
        
        for document in snapshot.documents {
            let data = document.data()
            
            guard let name = data["name"] as? String,
                  let quantity = data["quantity"] as? String,
                  let price = data["price"] as? Double,
                  let link = data["link"] as? String,
                  let image = data["image"] as? String else {
                print("Error parsing shop item document: \(document.documentID)")
                continue
            }
            
            let buyItem = Buy(
                name: name,
                quantity: quantity,
                price: price,
                link: link,
                image: image
            )
            
            buyItems.append(buyItem)
        }
        
        return buyItems
    }
}
