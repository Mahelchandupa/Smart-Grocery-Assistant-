import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class HistoryViewModel: ObservableObject {
    @Published var recentPurchases: [Purchase] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    
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
    
    // Extension to FirestoreService to get purchase history
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
