import FirebaseFirestore

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
}