// MARK: - Navigation

import SwiftUI

/// Represents the possible navigation routes in the application.
enum Route: Hashable {
    /// Home/dashboard screen
    case home
    
    /// User profile screen
    case profile
    
    /// Sign-in screen
    case signIn
    
    /// Sign-up screen
    case signUp
    
    /// Nutritional information screen
    case nutritionalInfo
    
    /// Store locator screen
    case locator
    
    /// Shopping lists overview screen
    case lists
    
    /// Reminders management screen
    case reminder
    
    /// Purchase history screen
    case history
    
    /// Screen for creating a new shopping list
    case createNewList
    
    /// Recipes screen
    case recipes
    
    /// Detail view for a specific shopping list
    /// - Parameter id: Unique identifier of the shopping list
    case listDetail(id: String)
    
    /// Detail view for a specific shopping item
    /// - Parameter id: Unique identifier of the shopping item
    case shopping(id: String)
    
    /// Shop screen for purchasing items
    case buy
}