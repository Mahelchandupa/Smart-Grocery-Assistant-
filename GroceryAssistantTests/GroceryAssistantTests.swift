import Testing
@testable import GroceryAssistant
import XCTest

struct GroceryAssistantTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

}

// Adding shopping item model tests
class ShoppingItemTests: XCTestCase {
    
    func testShoppingItemInitialization() {
        // Arrange
        let id = "testID"
        let name = "Apples"
        let checked = false
        let needToBuy = true
        
        // Act
        let item = ShoppingItem(
            id: id,
            name: name,
            checked: checked,
            needToBuy: needToBuy
        )
        
        // Assert
        XCTAssertEqual(item.id, id)
        XCTAssertEqual(item.name, name)
        XCTAssertEqual(item.checked, checked)
        XCTAssertEqual(item.needToBuy, needToBuy)
    }
    
    func testToDictionary() {
        // Arrange
        let item = ShoppingItem(
            id: "testID",
            name: "Apples",
            checked: false,
            needToBuy: true,
            categoryId: "fruits"
        )
        
        // Act
        let dict = item.toDictionary()
        
        // Assert
        XCTAssertEqual(dict["id"] as? String, "testID")
        XCTAssertEqual(dict["name"] as? String, "Apples")
        XCTAssertEqual(dict["checked"] as? Bool, false)
        XCTAssertEqual(dict["needToBuy"] as? Bool, true)
        XCTAssertEqual(dict["categoryId"] as? String, "fruits")
    }
}

// Create a protocol for the FirestoreService
protocol FirestoreServiceProtocol {
    func getUserLists(userId: String) async throws -> [ShoppingList]
    func getListItems(userId: String, listId: String) async throws -> [ShoppingItem]
    func toggleItemChecked(userId: String, itemId: String, isChecked: Bool, listId: String) async throws
}

// Mock implementation for testing
class MockFirestoreService: FirestoreServiceProtocol {
    var mockLists: [ShoppingList] = []
    var mockItems: [ShoppingItem] = []
    var errorToThrow: Error?
    var toggleItemCalled = false
    
    func getUserLists(userId: String) async throws -> [ShoppingList] {
        if let error = errorToThrow {
            throw error
        }
        return mockLists
    }
    
    func getListItems(userId: String, listId: String) async throws -> [ShoppingItem] {
        if let error = errorToThrow {
            throw error
        }
        return mockItems.filter { $0.listId == listId }
    }
    
    func toggleItemChecked(userId: String, itemId: String, isChecked: Bool, listId: String) async throws {
        if let error = errorToThrow {
            throw error
        }
        toggleItemCalled = true
        if let index = mockItems.firstIndex(where: { $0.id == itemId }) {
            mockItems[index].checked = isChecked
        }
    }
}

// Test using the mock
class FirestoreServiceTests: XCTestCase {
    var mockService: MockFirestoreService!
    
    override func setUp() {
        super.setUp()
        mockService = MockFirestoreService()
        // Set up test data
        mockService.mockLists = [
            ShoppingList(id: "list1", name: "Groceries", color: "#FF0000"),
            ShoppingList(id: "list2", name: "Hardware", color: "#00FF00")
        ]
        mockService.mockItems = [
            ShoppingItem(id: "item1", name: "Apples", listId: "list1"),
            ShoppingItem(id: "item2", name: "Bananas", listId: "list1"),
            ShoppingItem(id: "item3", name: "Hammer", listId: "list2")
        ]
    }
    
    func testGetUserLists() async throws {
        // Act
        let lists = try await mockService.getUserLists(userId: "user1")
        
        // Assert
        XCTAssertEqual(lists.count, 2)
        XCTAssertEqual(lists.first?.name, "Groceries")
    }
    
    func testGetListItems() async throws {
        // Act
        let items = try await mockService.getListItems(userId: "user1", listId: "list1")
        
        // Assert
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items.first?.name, "Apples")
    }
    
    func testGetListItemsWithError() async {
        // Arrange
        mockService.errorToThrow = NSError(domain: "test", code: 404, userInfo: nil)
        
        // Act & Assert
        do {
            _ = try await mockService.getListItems(userId: "user1", listId: "list1")
            XCTFail("Expected error was not thrown")
        } catch {
            // Success - error was thrown as expected
        }
    }
    
    func testToggleItemChecked() async throws {
        // Act
        try await mockService.toggleItemChecked(userId: "user1", itemId: "item1", isChecked: true, listId: "list1")
        
        // Assert
        XCTAssertTrue(mockService.toggleItemCalled)
        XCTAssertTrue(mockService.mockItems.first?.checked ?? false)
    }
}