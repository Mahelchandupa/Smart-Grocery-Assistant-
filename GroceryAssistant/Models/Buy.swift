// MARK: - Shopping Models

import SwiftUI

/// Model representing an item available for purchase in the shop.
struct Buy: Identifiable {
    /// Unique identifier for the shop item
    var id = UUID()
    
    /// Name of the item
    var name: String
    
    /// Available quantity or size description
    var quantity: String
    
    /// Price of the item
    var price: Double
    
    /// URL or path to more information about the item
    var link: String
    
    /// URL or path to the item's image
    var image: String
}