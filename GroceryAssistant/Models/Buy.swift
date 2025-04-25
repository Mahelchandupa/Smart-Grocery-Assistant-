// MARK: - Shopping Models

import SwiftUI

/// Model representing an item available for purchase in the shop.
struct Buy: Identifiable {
    var id = UUID()
    var name: String
    var quantity: String
    var price: Double
    var link: String
    var image: String
}