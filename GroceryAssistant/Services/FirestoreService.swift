import FirebaseFirestore
import FirebaseAuth

struct FirestoreService {
    private static let db = Firestore.firestore()
    
    static func saveUserData(uid: String, data: [String: Any]) async throws {
        try await db.collection("users").document(uid).setData(data)
    }
    
    static func createList(userId: String, list: ShoppingList) async throws {
        let listWithDate = list.toDictionary() // Convert to [String: Any]
        try await db.collection("users")
            .document(userId)
            .collection("lists")
            .document(list.id)
            .setData(listWithDate)
    }
    
    static func getUserLists(userId: String) async throws -> [ShoppingList] {
        let snapshot = try await db.collection("users")
            .document(userId)
            .collection("lists")
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? document.data(as: ShoppingList.self)
        }
    }
    
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
    
    static func getAllItems(userId: String) async throws -> [ShoppingItem] {
        let querySnapshot = try await db.collection("users")
            .document(userId)
            .collection("items")
            .getDocuments()
        
        return querySnapshot.documents.compactMap { document in
            try? document.data(as: ShoppingItem.self)
        }
    }
    
    static func toggleItemChecked(userId: String, itemId: String, isChecked: Bool) async throws {
        try await db.collection("users")
            .document(userId)
            .collection("items")
            .document(itemId)
            .updateData([
                "checked": isChecked,
                "updatedDate": FieldValue.serverTimestamp()
            ])
    }
    
    static func updateItem(userId: String, itemId: String, updates: [String: Any]) async throws {
        var updatedData = updates
        updatedData["updatedDate"] = FieldValue.serverTimestamp()
        
        try await db.collection("users")
            .document(userId)
            .collection("items")
            .document(itemId)
            .updateData(updatedData)
    }
    
    static func createItem(userId: String, item: ShoppingItem, listId: String, categoryId: String?) async throws -> ShoppingItem {
        let itemsCollection = db.collection("users")
            .document(userId)
            .collection("items")
        
        var itemData = item.toDictionary()
        itemData["listId"] = listId
        itemData["categoryId"] = categoryId
        itemData["userId"] = userId
        itemData["createdDate"] = FieldValue.serverTimestamp()
        itemData["updatedDate"] = FieldValue.serverTimestamp()
        itemData["checked"] = item.checked
        
        let documentReference = try await itemsCollection.addDocument(data: itemData)
        
        // Retrieve the newly created item to get server timestamps
        let newItem = try await itemsCollection.document(documentReference.documentID).getDocument()
        guard var createdItem = try? newItem.data(as: ShoppingItem.self) else {
            throw NSError(domain: "FirestoreService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to retrieve created item"])
        }
        
        // Update ID to match Firestore document ID
        createdItem.id = documentReference.documentID
        return createdItem
    }
    
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
}

extension Encodable {
    func toDictionary() -> [String: Any] {
        guard let data = try? JSONEncoder().encode(self) else {
            return [:]
        }
        
        guard let dictionary = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            return [:]
        }
        
        return dictionary
    }
}