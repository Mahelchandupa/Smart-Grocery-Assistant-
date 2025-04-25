// MARK: - Navigation

import SwiftUI

/// Represents the possible navigation routes in the application.
enum Route: Hashable {
    case home
    case profile
    case signIn
    case signUp
    case nutritionalInfo
    case locator
    case lists
    case reminder
    case history
    case createNewList
    case recipes
    case listDetail(id: String)
    case shopping(id: String)
    case buy
}