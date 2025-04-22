import SwiftUI

struct ShoppingCategory: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var items: [ShoppingItem]?
    var createdDate: Date?
    var userId: String?
    
    init(id: String = UUID().uuidString, name: String, items: [ShoppingItem]? = nil, createdDate: Date? = nil, userId: String? = nil) {
        self.id = id
        self.name = name
        self.items = items
        self.createdDate = createdDate
        self.userId = userId
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case items
        case createdDate
        case userId
    }
    
    // Function to convert to a dictionary for Firestore
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "name": name
        ]
        
        if let createdDate = createdDate {
            dict["createdDate"] = createdDate
        }
        
        if let userId = userId {
            dict["userId"] = userId
        }
        
        // We don't store items directly in the category document
        // They are linked by categoryId in the items collection
        
        return dict
    }
    
    // Implement Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ShoppingCategory, rhs: ShoppingCategory) -> Bool {
        return lhs.id == rhs.id
    }
}
