struct ShoppingList: Codable, Identifiable {
    var id: String
    var name: String
    var color: String
    var dueDate: Date?
    var items: [String]
    var completedItems: Int
    
    enum CodingKeys: String, CodingKey {
        case id, name, color, dueDate, items, completedItems
    }
    
    init(id: String, name: String, color: String, dueDate: Date? = nil, items: [String], completedItems: Int) {
        self.id = id
        self.name = name
        self.color = color
        self.dueDate = dueDate
        self.items = items
        self.completedItems = completedItems
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        color = try container.decode(String.self, forKey: .color)
        items = try container.decode([String].self, forKey: .items)
        completedItems = try container.decode(Int.self, forKey: .completedItems)
        
        // Handle Firestore timestamp
        if let timestamp = try? container.decode(Timestamp.self, forKey: .dueDate) {
            dueDate = timestamp.dateValue()
        } else {
            dueDate = nil
        }
    }
}