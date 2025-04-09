struct ShoppingList: Codable, Identifiable {
    var id: String
    var name: String
    var color: String
    var dueDate: Date?
    var items: [String]
    var completedItems: Int
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "name": name,
            "color": color,
            "items": items,
            "completedItems": completedItems
        ]
        
        if let dueDate = dueDate {
            dict["dueDate"] = Timestamp(date: dueDate)
        }
        
        return dict
    }
}