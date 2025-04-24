import SwiftUI
import FirebaseFirestore
import FirebaseAuth

/// A view model for handling shopping history data and operations.
///
/// This class manages the fetching and storing of purchase history data from Firestore,
/// providing a reactive interface for views to display purchase history information.
class HistoryViewModel: ObservableObject {
    /// Array of recent purchases, sorted by date
    @Published var recentPurchases: [Purchase] = []
    
    /// Flag indicating whether data is currently being loaded
    @Published var isLoading = false
    
    /// Error message if data fetching fails
    @Published var errorMessage: String?
    
    /// Reference to Firestore database
    private let db = Firestore.firestore()
    
    /// Fetches the most recent purchases for the current user.
    ///
    /// This method retrieves up to 10 of the most recent purchases from Firestore,
    /// sorted by date in descending order (newest first). It handles authentication
    /// checks, loading states, and error conditions.
    func fetchPurchaseHistory() {
        guard let userId = Auth.auth().currentUser?.uid else {
            self.errorMessage = "No user logged in"
            return
        }
        
        isLoading = true
        
        db.collection("users")
            .document(userId)
            .collection("purchases")
            .order(by: "date", descending: true)
            .limit(to: 10)
            .getDocuments { [weak self] querySnapshot, error in
                guard let self = self else { return }
                
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Error fetching data: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    self.errorMessage = "No documents found"
                    return
                }
                
                self.recentPurchases = documents.compactMap { document -> Purchase? in
                    do {
                        return try document.data(as: Purchase.self)
                    } catch {
                        print("Error decoding purchase: \(error)")
                        return nil
                    }
                }
            }
    }
    
    /// Adds a new purchase record to the user's history in Firestore.
    ///
    /// This method saves a completed purchase to the user's purchase history collection.
    /// It should be called when a shopping trip is completed or when items are purchased.
    ///
    /// - Parameter purchase: The Purchase object to add to history
    func addPurchaseToHistory(purchase: Purchase) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No user logged in")
            return
        }
        
        do {
            try db.collection("users")
                .document(userId)
                .collection("purchases")
                .document(purchase.id)
                .setData(from: purchase)
        } catch {
            print("Error adding purchase to history: \(error)")
        }
    }
}
