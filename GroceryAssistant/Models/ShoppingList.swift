import SwiftUI
import FirebaseCore

struct ShoppingList: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var color: String
    var dueDate: Date?
    var items: [ShoppingItem]
    var completedItems: Int
    
    static func == (lhs: ShoppingList, rhs: ShoppingList) -> Bool {
        return lhs.id == rhs.id
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, color, dueDate, items, completedItems
    }
    
    init(id: String, name: String, color: String, dueDate: Date? = nil, items: [String], completedItems: Int) {
        self.id = id
        self.name = name
        self.color = color
        self.dueDate = dueDate
        // Convert strings to ShoppingItem objects
        self.items = items.map { ShoppingItem(name: $0) }
        self.completedItems = completedItems
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        color = try container.decode(String.self, forKey: .color)
        
        // Handle item decoding - either directly as ShoppingItems or convert from strings
        do {
            items = try container.decode([ShoppingItem].self, forKey: .items)
        } catch {
            // Handle the case where items are stored as strings
            let stringItems = try container.decode([String].self, forKey: .items)
            items = stringItems.map { ShoppingItem(name: $0) }
        }
        
        completedItems = try container.decode(Int.self, forKey: .completedItems)
        
        // Handle Firestore timestamp
        if let timestamp = try? container.decode(Timestamp.self, forKey: .dueDate) {
            dueDate = timestamp.dateValue()
        } else {
            dueDate = nil
        }
    }
}
