//
//  GroceryAssistantApp.swift
//  GroceryAssistant
//
//  Created by sasiri rukshan nanayakkara on 3/30/25.
//

import SwiftUI
import Firebase

//@main
//struct GroceryAssistantApp: App {
//    init(){
//        FirebaseApp.configure()
//    }
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//        }
//    }
//}

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
