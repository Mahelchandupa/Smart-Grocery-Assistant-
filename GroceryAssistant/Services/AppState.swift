class AppState: ObservableObject {
    @Published var isInitialized = false
    @Published var isAuthenticated = false
}

// Setup Firebase main App struct
@main
struct GroceryAssistantApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var appState = AppState()
    
    init() {
        setupFirebase()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(appState)
        }
    }
    
    private func setupFirebase() {
        FirebaseApp.configure()
    }
}