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
    case listDetail(id: String) // Pass the list ID or name for detail view
    case recipeDetail(id: String) // Pass the recipe ID or name for detail view
    case shopping(id: String) // Pass the shopping item ID or name for detail view
}