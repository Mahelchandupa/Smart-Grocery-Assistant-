import SwiftUI

/// A view that displays detailed nutritional information for food products.
///
/// This view allows users to select products from a dropdown menu or search,
/// and displays comprehensive nutritional information including calories,
/// nutrients, allergens, and ingredients.
struct NutritionalInfoView: View {
    /// Navigation path for handling navigation within the app
    @Binding var navPath: NavigationPath
    
    /// Authentication manager for user context
    @EnvironmentObject var authManager: AuthManager
    
    /// Sample product data for demonstration
    @State private var dummyProducts = FoodProduct.dummyData()
    
    /// Currently selected product to display details for
    @State private var selectedProduct: FoodProduct?
    
    /// User's search query when looking for products
    @State private var searchQuery = ""
    
    /// Flag controlling the visibility of the product dropdown
    @State private var showDropdown = false
    
    /// Flag controlling the visibility of search results
    @State private var showSearchResults = false
    
    /// Flag controlling the display of the error banner
    @State private var showErrorBanner = false

    /// Initializes the view with a navigation path and preselects the first product
    /// - Parameter navPath: Binding to the navigation path
    init(navPath: Binding<NavigationPath>) {
        self._navPath = navPath
        self._selectedProduct = State(initialValue: FoodProduct.dummyData().first)
    }

    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            ScrollView {
                // Product selection dropdown
                productSelectionSection
                
                // Error message banner (toggle for demo)
                if showErrorBanner {
                    errorBanner(message: "Could not connect to nutrition database. Showing estimates.")
                }
                
                // Product details or no selection view
                if let product = selectedProduct {
                    productDetailsView(product: product)
                } else {
                    noSelectionView
                }
            }
        }
    }
    
    // MARK: - Header Components
    
    /// Header view with navigation and title
    private var headerView: some View {
        ZStack {
            Color(hex: "4CAF50")
                .ignoresSafeArea(edges: .top)
            VStack {
                HStack {
                    Button(action: {
                        if navPath.count > 0 {
                            navPath.removeLast()
                        }
                    }) {
                        Image(systemName: "arrow.left")
                            .foregroundColor(.white)
                            .font(.system(size: 20))
                    }
                    .padding(.trailing, 8)
                    
                    Text("Nutritional Info")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
            }
            .padding(.top, 25)
            .padding(.bottom, 20)
            .padding(.horizontal, 16)
        }
        .frame(height: 60)
    }
    
    // MARK: - Product Selection Section
    
    /// Section for selecting a product via dropdown
    private var productSelectionSection: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Button(action: {
                    withAnimation {
                        showDropdown.toggle()
                    }
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Select Product")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text(selectedProduct?.name ?? "Select a product")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .foregroundColor(.gray)
                            .rotationEffect(.degrees(showDropdown ? 180 : 0))
                    }
                    .padding()
                    .contentShape(Rectangle())
                }
                
                if showDropdown {
                    VStack(spacing: 12) {
                        // Search bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            
                            TextField("Search for a product...", text: $searchQuery)
                                .onChange(of: searchQuery) { newValue in
                                    showSearchResults = !newValue.isEmpty
                                }
                            
                            if !searchQuery.isEmpty {
                                Button(action: {
                                    searchQuery = ""
                                    showSearchResults = false
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(8)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                        
                        // Search results or user items
                        if showSearchResults {
                            searchResultsList
                        } else {
                            userItemsList
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                }
            }
            .background(Color.white)
            .cornerRadius(showDropdown ? 12 : 0)
            .shadow(color: Color.black.opacity(0.1), radius: showDropdown ? 8 : 0)
            .padding(.horizontal, showDropdown ? 12 : 0)
            .zIndex(1)
            
            Divider()
        }
    }
    
    // MARK: - List Components
    
    /// List showing search results based on user query
    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Filter products that match the search query for demo
                let results = dummyProducts.filter {
                    $0.name.lowercased().contains(searchQuery.lowercased()) ||
                    $0.brand.lowercased().contains(searchQuery.lowercased())
                }
                
                ForEach(results) { product in
                    Button(action: {
                        selectedProduct = product
                        showDropdown = false
                        showSearchResults = false
                        searchQuery = ""
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(product.name)
                                    .foregroundColor(.primary)
                                Text(product.brand)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 4)
                    }
                    
                    if product.id != results.last?.id {
                        Divider()
                    }
                }
                
                // If no results found
                if results.isEmpty {
                    VStack(spacing: 8) {
                        Text("No products found")
                            .foregroundColor(.gray)
                        Text("Try a different search term")
                            .font(.caption)
                            .foregroundColor(.gray.opacity(0.8))
                    }
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(maxHeight: 250)
        }
    }
    
    /// List showing user's previously viewed ingredients
    private var userItemsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("YOUR INGREDIENTS")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.gray)
                .padding(.top, 4)
            
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(dummyProducts) { product in
                        Button(action: {
                            selectedProduct = product
                            showDropdown = false
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(product.name)
                                        .foregroundColor(.primary)
                                    Text(product.brand)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 4)
                        }
                        
                        if product.id != dummyProducts.last?.id {
                            Divider()
                        }
                    }
                }
            }
            .frame(maxHeight: 250)
        }
    }
    
    // MARK: - Error Banner
    
    /// Creates an error banner with the specified message
    /// - Parameter message: The error message to display
    /// - Returns: A styled view containing the error message
    private func errorBanner(message: String) -> some View {
        HStack {
            Image(systemName: "info.circle")
                .foregroundColor(.orange)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding()
        .background(Color.yellow.opacity(0.2))
    }
    
    // MARK: - Empty State View
    
    /// View displayed when no product is selected
    private var noSelectionView: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.3))
            
            Text("Select a product to view its nutritional information")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            Button(action: {
                withAnimation {
                    showDropdown = true
                }
            }) {
                Text("Choose a Product")
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color(AppColors.green500))
                    .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Product Details Components
    
    /// Main view displaying product nutritional details
    /// - Parameter product: The food product to display details for
    /// - Returns: A view containing formatted nutritional information
    private func productDetailsView(product: FoodProduct) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // Product header
                productHeaderView(product: product)
                
                // Allergen warnings
                if !product.allergens.isEmpty {
                    allergenWarningView(allergens: product.allergens)
                }
                
                // Nutrition facts
                nutritionFactsView(product: product)
                
                // Ingredients
                ingredientsView(ingredients: product.ingredients)
                
                // Data source notice
                Text("Nutritional data provided by Food Database API.\nValues may vary by region and brand.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
            }
        }
    }
    
    /// Header view displaying product image, name, brand and health labels
    /// - Parameter product: The food product to display
    /// - Returns: A styled header view
    private func productHeaderView(product: FoodProduct) -> some View {
        HStack(alignment: .top, spacing: 16) {
            // Product image (using SF Symbols as placeholders)
            AsyncImage(url: URL(string: product.image)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 80, height: 80)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(6)
                        .frame(width: 80, height: 80)
                        .background(Color(AppColors.green500).opacity(0.1))
                        .cornerRadius(8)
                case .failure:
                    Image(systemName: product.image.foodImage(fallback: "leaf"))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(6)
                        .frame(width: 80, height: 80)
                        .background(Color(AppColors.green500).opacity(0.1))
                        .foregroundColor(AppColors.green500)
                        .cornerRadius(8)
                @unknown default:
                    EmptyView()
                }
            }

            
            // Product info
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text(product.brand)
                    .foregroundColor(.gray)
                
                // Health labels
                if !product.healthLabels.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(product.healthLabels, id: \.self) { label in
                                Text(label)
                                    .font(.caption)
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(12)
                            }
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    /// Warning view for food allergens
    /// - Parameter allergens: Array of allergen names
    /// - Returns: A styled warning view
    private func allergenWarningView(allergens: [String]) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.red)
            
            Text("Contains allergens: \(allergens.joined(separator: ", "))")
                .font(.subheadline)
                .foregroundColor(.red)
            
            Spacer()
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    /// Nutrition facts table view
    /// - Parameter product: The food product to display nutrition for
    /// - Returns: A styled nutrition facts table
    private func nutritionFactsView(product: FoodProduct) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Nutrition Facts")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text("Serving Size \(product.serving)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            
            Divider()
            
            // Calories
            HStack {
                Text("Calories")
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("\(product.calories)")
                    .fontWeight(.bold)
            }
            .padding()
            .background(Color.white)
            
            Divider()
            
            // Nutrients list
            ForEach(product.nutrients) { nutrient in
                nutrientRow(nutrient: nutrient)
                Divider()
            }
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 1)
        .padding(.horizontal)
    }
    
    /// Row view for a nutrient with optional sub-nutrients
    /// - Parameter nutrient: The nutrient information to display
    /// - Returns: A styled row view
    private func nutrientRow(nutrient: NutrientInfo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Main nutrient
            HStack {
                Text(nutrient.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("\(Int(nutrient.value))\(nutrient.unit)")
                        .font(.subheadline)
                    
                    if let dailyValue = nutrient.dailyValue {
                        Text("\(dailyValue)%")
                            .font(.subheadline)
                            .foregroundColor(nutrient.dailyValueColor())
                    }
                }
            }
            
            // Sub nutrients (if any)
            if let subNutrients = nutrient.subNutrients {
                ForEach(subNutrients) { subNutrient in
                    HStack {
                        Text(subNutrient.name)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.leading, 16)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Text("\(Int(subNutrient.value))\(subNutrient.unit)")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            if let dailyValue = subNutrient.dailyValue {
                                Text("\(dailyValue)%")
                                    .font(.caption)
                                    .foregroundColor(subNutrient.dailyValueColor())
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
    }
    
    /// Ingredients list view
    /// - Parameter ingredients: String containing ingredients list
    /// - Returns: A styled ingredients view
    private func ingredientsView(ingredients: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ingredients")
                .font(.title3)
                .fontWeight(.bold)
            
            Text(ingredients)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 1)
        .padding(.horizontal)
    }
}

/// Preview provider for NutritionalInfoView
struct NutritionalInfoView_Previews: PreviewProvider {
    static var previews: some View {
        NutritionalInfoView(navPath: .constant(NavigationPath()))
            .environmentObject(AuthManager())
    }
}