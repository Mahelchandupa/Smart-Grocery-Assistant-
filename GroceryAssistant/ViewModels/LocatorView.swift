import SwiftUI
import MapKit
import CoreLocation

// MARK: - Extensions
extension Double {
    var degreesToRadians: Double { return self * .pi / 180 }
    var radiansToDegrees: Double { return self * 180 / .pi }
}

// MARK: - Models
struct Store: Identifiable {
    let id = UUID()
    let name: String
    let coordinates: CLLocationCoordinate2D
    let address: String
    let rating: Double
    let distance: Double
    let type: StoreType // Added store type
}

enum StoreType: String {
    case supermarket = "Supermarket"
    case groceryStore = "Grocery Store"
    case convenience = "Convenience Store"
}

// MARK: - ViewModel
class StoreViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var stores: [Store] = []
    @Published var region = MKCoordinateRegion()
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var selectedStore: Store?
    @Published var directions: [String] = []
    @Published var showingDirections = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var mapCenterLocation: CLLocationCoordinate2D? // Added for map center tracking
    
    private var locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    // Sri Lanka coordinates (approximate center)
    private let sriLankaCenter = CLLocationCoordinate2D(latitude: 7.8731, longitude: 80.7718)
    
    // Popular supermarket chains in Sri Lanka
    private let sriLankaStores = [
        "Keells Super", "Cargills Food City", "Arpico Super Centre",
        "Laugfs Supermarket", "Sathosa", "Glories", "Preethis",
        "Softlogic GLOMARK", "Lanka Sathosa"
    ]
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        // If location services are unavailable or delayed, start with fallback data
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            guard let self = self else { return }
            
            if self.stores.isEmpty && !self.hasFetchedStores {
                print("No location update received, using fallback data")
                self.updateRegion(to: self.sriLankaCenter)
                self.mapCenterLocation = self.sriLankaCenter
                self.createFallbackStores(near: CLLocation(latitude: self.sriLankaCenter.latitude,
                                                         longitude: self.sriLankaCenter.longitude))
                self.hasFetchedStores = true
            }
        }
    }

    private var hasFetchedStores = false

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        userLocation = location.coordinate
        
        let userInSriLanka = isLocationInSriLanka(location.coordinate)
        let locationToUse = userInSriLanka ? location.coordinate : sriLankaCenter
        
        updateRegion(to: locationToUse)
        mapCenterLocation = locationToUse

        if !hasFetchedStores {
            hasFetchedStores = true
            fetchNearbyStores(near: CLLocation(latitude: locationToUse.latitude, longitude: locationToUse.longitude))
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
        errorMessage = "Unable to get your location. Using default Sri Lanka location."
        
        // Use Sri Lanka center coordinates if location fails
        updateRegion(to: sriLankaCenter)
        mapCenterLocation = sriLankaCenter
        fetchNearbyStores(near: CLLocation(latitude: sriLankaCenter.latitude, longitude: sriLankaCenter.longitude))
    }
    
    // Check if coordinates are in Sri Lanka
    private func isLocationInSriLanka(_ coordinate: CLLocationCoordinate2D) -> Bool {
        return coordinate.latitude >= 5.5 && coordinate.latitude <= 10.0 &&
               coordinate.longitude >= 79.0 && coordinate.longitude <= 82.5
    }

    private func updateRegion(to coordinate: CLLocationCoordinate2D) {
        region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    }

    // Updated to fetch both supermarkets and grocery stores
    func fetchNearbyStores(near location: CLLocation) {
        isLoading = true
        errorMessage = nil
        
        // Create two separate requests - one for supermarkets and one for grocery stores
        let supermarketRequest = MKLocalSearch.Request()
        supermarketRequest.naturalLanguageQuery = "supermarket"
        
        let groceryRequest = MKLocalSearch.Request()
        groceryRequest.naturalLanguageQuery = "grocery store"
        
        // Set region for both searches
        let searchRegion = MKCoordinateRegion(
            center: mapCenterLocation ?? sriLankaCenter,
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1) 
        )
        supermarketRequest.region = searchRegion
        groceryRequest.region = searchRegion
        
        // Perform both searches
        let group = DispatchGroup()
        var allStores: [Store] = []
        var searchError: Error?
        
        // Add delay to prevent throttling
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Search for supermarkets
            group.enter()
            let supermarketSearch = MKLocalSearch(request: supermarketRequest)
            supermarketSearch.start { response, error in
                defer { group.leave() }
                
                if let error = error {
                    searchError = error
                    return
                }
                
                if let items = response?.mapItems {
                    let supermarkets = self.processMapItems(items, type: .supermarket, near: location)
                    allStores.append(contentsOf: supermarkets)
                }
            }
            
            // Search for grocery stores
            group.enter()
            let grocerySearch = MKLocalSearch(request: groceryRequest)
            grocerySearch.start { response, error in
                defer { group.leave() }
                
                if let error = error {
                    searchError = error
                    return
                }
                
                if let items = response?.mapItems {
                    let groceries = self.processMapItems(items, type: .groceryStore, near: location)
                    allStores.append(contentsOf: groceries)
                }
            }
            
            // Process results
            group.notify(queue: .main) {
                self.isLoading = false
                
                if let error = searchError {
                    self.errorMessage = "Error finding stores: \(error.localizedDescription)"
                    // If search failed, use fallback data
                    self.createFallbackStores(near: location)
                    return
                }
                
                if allStores.isEmpty {
                    self.errorMessage = "No stores found nearby. Try adjusting the map view."
                    self.createFallbackStores(near: location)
                    return
                }
                
                // Sort by rating and then by distance
                self.stores = allStores.sorted {
                    if $0.rating == $1.rating {
                        return $0.distance < $1.distance
                    }
                    return $0.rating > $1.rating
                }
            }
        }
    }
    
    // Helper method to process map items
    private func processMapItems(_ items: [MKMapItem], type: StoreType, near location: CLLocation) -> [Store] {
        return items.compactMap { item in
            guard let name = item.name,
                  let coordinate = item.placemark.location?.coordinate else { return nil }
            
            // Don't filter by Sri Lanka location - allow viewing stores wherever map is centered
            let address = self.formatAddress(from: item.placemark)
            let distance = location.distance(from: item.placemark.location!) / 1000 // km
            
            // Using random for demo purposes
            let randomRating = Double.random(in: 3.5...5.0)
            
            return Store(name: name,
                         coordinates: coordinate,
                         address: address,
                         rating: randomRating,
                         distance: distance,
                         type: type)
        }
    }
    
    // Create fallback store data when MapKit search fails
    private func createFallbackStores(near location: CLLocation) {
        // Clear any existing error message
        self.errorMessage = nil
        
        // Create some hardcoded stores around Sri Lanka's main cities
        var fallbackStores: [Store] = []
        
        // Colombo supermarkets
        fallbackStores.append(Store(
            name: "Keells Super - Colombo",
            coordinates: CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612),
            address: "Union Place, Colombo 2, Sri Lanka",
            rating: 4.7,
            distance: location.distance(from: CLLocation(latitude: 6.9271, longitude: 79.8612)) / 1000,
            type: .supermarket
        ))
        
        fallbackStores.append(Store(
            name: "Cargills Food City - Colombo",
            coordinates: CLLocationCoordinate2D(latitude: 6.9344, longitude: 79.8500),
            address: "Staples Street, Colombo, Sri Lanka",
            rating: 4.5,
            distance: location.distance(from: CLLocation(latitude: 6.9344, longitude: 79.8500)) / 1000,
            type: .supermarket
        ))
        
        // Kandy supermarkets
        fallbackStores.append(Store(
            name: "Arpico Super Centre - Kandy",
            coordinates: CLLocationCoordinate2D(latitude: 7.2906, longitude: 80.6337),
            address: "Peradeniya Road, Kandy, Sri Lanka",
            rating: 4.6,
            distance: location.distance(from: CLLocation(latitude: 7.2906, longitude: 80.6337)) / 1000,
            type: .supermarket
        ))
        
        // Galle grocery stores
        fallbackStores.append(Store(
            name: "Local Grocery - Galle",
            coordinates: CLLocationCoordinate2D(latitude: 6.0535, longitude: 80.2210),
            address: "Main Street, Galle, Sri Lanka",
            rating: 4.2,
            distance: location.distance(from: CLLocation(latitude: 6.0535, longitude: 80.2210)) / 1000,
            type: .groceryStore
        ))
        
        // Negombo grocery stores
        fallbackStores.append(Store(
            name: "Fresh Market - Negombo",
            coordinates: CLLocationCoordinate2D(latitude: 7.2081, longitude: 79.8371),
            address: "Colombo Road, Negombo, Sri Lanka",
            rating: 4.4,
            distance: location.distance(from: CLLocation(latitude: 7.2081, longitude: 79.8371)) / 1000,
            type: .groceryStore
        ))
        
        // Jaffna stores
        fallbackStores.append(Store(
            name: "Cargills Food City - Jaffna",
            coordinates: CLLocationCoordinate2D(latitude: 9.6615, longitude: 80.0255),
            address: "Hospital Road, Jaffna, Sri Lanka",
            rating: 4.3,
            distance: location.distance(from: CLLocation(latitude: 9.6615, longitude: 80.0255)) / 1000,
            type: .supermarket
        ))
        
        fallbackStores.append(Store(
            name: "Family Mart - Jaffna",
            coordinates: CLLocationCoordinate2D(latitude: 9.6550, longitude: 80.0290),
            address: "Temple Road, Jaffna, Sri Lanka",
            rating: 4.1,
            distance: location.distance(from: CLLocation(latitude: 9.6550, longitude: 80.0290)) / 1000,
            type: .convenience
        ))
        
        // Sort by rating
        self.stores = fallbackStores.sorted { $0.rating > $1.rating }
    }
    
    // Format address specifically for Sri Lanka format
    private func formatAddress(from placemark: MKPlacemark) -> String {
        var components = [String]()
        
        if let thoroughfare = placemark.thoroughfare {
            components.append(thoroughfare)
        }
        
        if let subThoroughfare = placemark.subThoroughfare {
            components.append(subThoroughfare)
        }
        
        if let locality = placemark.locality {
            components.append(locality)
        }
        
        if let administrativeArea = placemark.administrativeArea {
            components.append(administrativeArea)
        }
        
        // Add country for clarity
        if let country = placemark.country {
            components.append(country)
        } else {
            // Default to Sri Lanka for fallback data
            components.append("Sri Lanka")
        }
        
        return components.joined(separator: ", ")
    }

    func getDirections(to store: Store) {
        guard let userLocation = userLocation else {
            errorMessage = "Unable to get your location for directions"
            return
        }
        
        selectedStore = store
        isLoading = true
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: store.coordinates))
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        directions.calculate { [weak self] response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Error getting directions: \(error.localizedDescription)"
                    self.createFallbackDirections(to: store)
                    return
                }
                
                guard let route = response?.routes.first else {
                    self.errorMessage = "No route found to this store"
                    self.createFallbackDirections(to: store)
                    return
                }
                
                // Process step-by-step directions
                self.directions = route.steps.map { step in
                    let distance = self.formatDistance(meters: step.distance)
                    return "\(step.instructions) (\(distance))"
                }
                
                if self.directions.isEmpty {
                    self.createFallbackDirections(to: store)
                    return
                }
                
                self.showingDirections = true
            }
        }
    }
    
    // Create fallback directions when MapKit directions fail
    private func createFallbackDirections(to store: Store) {
        guard let userLocation = self.userLocation else {
            return
        }
        
        // Calculate distance
        let fromLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let toLocation = CLLocation(latitude: store.coordinates.latitude, longitude: store.coordinates.longitude)
        let distanceInKm = fromLocation.distance(from: toLocation) / 1000
        
        // Create generic directions based on cardinal direction
        let bearing = calculateBearing(from: fromLocation, to: toLocation)
        let cardinalDirection = getCardinalDirection(for: bearing)
        
        self.directions = [
            "Start from your current location.",
            "Head \(cardinalDirection) for approximately \(String(format: "%.1f", distanceInKm)) km.",
            "Continue on main roads toward \(store.name).",
            "Look for \(store.name) on your \(Bool.random() ? "right" : "left") side.",
            "Arrive at \(store.name), \(store.address)."
        ]
        
        self.isLoading = false
        self.showingDirections = true
    }
    
    // Calculate bearing between two locations
    private func calculateBearing(from startLocation: CLLocation, to endLocation: CLLocation) -> Double {
        let lat1 = startLocation.coordinate.latitude.degreesToRadians
        let lon1 = startLocation.coordinate.longitude.degreesToRadians
        let lat2 = endLocation.coordinate.latitude.degreesToRadians
        let lon2 = endLocation.coordinate.longitude.degreesToRadians
        
        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let bearing = atan2(y, x).radiansToDegrees
        
        return (bearing + 360).truncatingRemainder(dividingBy: 360)
    }
    
    // Convert bearing to cardinal direction
    private func getCardinalDirection(for bearing: Double) -> String {
        let directions = ["north", "northeast", "east", "southeast", "south", "southwest", "west", "northwest"]
        let index = Int(round(bearing / 45.0)) % 8
        return directions[index]
    }
    
    private func formatDistance(meters: CLLocationDistance) -> String {
        if meters < 1000 {
            return "\(Int(meters))m"
        } else {
            return String(format: "%.1f km", meters / 1000)
        }
    }
    
    // Refresh stores data based on current map center
    func refreshStores() {
        let locationToSearch = mapCenterLocation ?? (userLocation ?? sriLankaCenter)
        fetchNearbyStores(near: CLLocation(latitude: locationToSearch.latitude, longitude: locationToSearch.longitude))
    }
    
    // New function to update stores when map is moved
    func mapRegionDidChange() {
        // Update the map center location
        mapCenterLocation = region.center
        
        // Uncomment the following line if you want to automatically fetch new stores when map moves
        // fetchNearbyStores(near: CLLocation(latitude: region.center.latitude, longitude: region.center.longitude))
    }
}


// MARK: - Views
struct LocatorView: View {
    @Binding var navPath: NavigationPath
    @StateObject private var viewModel = StoreViewModel()

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Color.green.ignoresSafeArea(edges: .top)
                HStack {
                    Button(action: {}) {
                        Image(systemName: "arrow.left")
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Text("Find Stores")
                        .foregroundColor(.white)
                        .bold()
                    Spacer()
                    Button(action: {
                        viewModel.refreshStores()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.white)
                    }
                }.padding()
            }.frame(height: 44)

            ZStack {
                Map(coordinateRegion: $viewModel.region, annotationItems: viewModel.stores) { store in
                    MapAnnotation(coordinate: store.coordinates) {
                        ZStack {
                            Circle()
                                .fill(storeColor(for: store.type))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Image(systemName: storeIcon(for: store.type))
                                        .foregroundColor(.white)
                                )
                                .shadow(radius: 2)
                                .onTapGesture {
                                    viewModel.selectedStore = store
                                }
                            
                            // Display rating on the map
                            Text(String(format: "%.1f", store.rating))
                                .font(.system(size: 8))
                                .foregroundColor(.white)
                                .padding(2)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(4)
                                .offset(y: 20)
                        }
                    }
                }
                .frame(height: 300)
                .onAppear {
                    // Disable showing user location blue dot
                    // This is handled by the initial map center
                }
                // Use MapReader instead of onChange for detecting map movements
                .onAppear {
                    // Set up a timer to periodically check if map has moved
                    Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                        viewModel.mapRegionDidChange()
                    }
                }
                
                // Search button overlay
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            viewModel.refreshStores()
                        }) {
                            Text("Find Stores Here")
                                .font(.system(size: 14, weight: .medium))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(20)
                                .shadow(radius: 3)
                        }
                        .padding(.bottom, 10)
                        .padding(.trailing, 10)
                        Spacer()
                    }
                }
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(10)
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.red)
                        .cornerRadius(8)
                        .padding()
                        .transition(.slide)
                }
            }

            // Store type legend
            HStack(spacing: 12) {
                ForEach([StoreType.supermarket, .groceryStore, .convenience], id: \.self) { type in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(storeColor(for: type))
                            .frame(width: 12, height: 12)
                        Text(type.rawValue)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.vertical, 6)
            
            ScrollView {
                if viewModel.stores.isEmpty && !viewModel.isLoading {
                    VStack(spacing: 10) {
                        Image(systemName: "mappin.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text("No stores found")
                            .font(.headline)
                        
                        Text("Move the map to a different area and tap 'Find Stores Here'")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Refresh") {
                            viewModel.refreshStores()
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.top, 10)
                    }
                    .padding(.vertical, 40)
                } else {
                    VStack(spacing: 12) {
                        ForEach(viewModel.stores) { store in
                            StoreRow(store: store, viewModel: viewModel)
                        }
                    }.padding()
                }
            }
        }
        .sheet(isPresented: $viewModel.showingDirections) {
            if let store = viewModel.selectedStore {
                DirectionsView(store: store, directions: viewModel.directions)
            }
        }
        .alert(item: Binding<StoreViewModel.Alert?>(
            get: {
                if let message = viewModel.errorMessage {
                    return StoreViewModel.Alert(message: message)
                }
                return nil
            },
            set: { _ in viewModel.errorMessage = nil }
        )) { alert in
            Alert(title: Text("Error"), message: Text(alert.message), dismissButton: .default(Text("OK")))
        }
    }
    
    // Helper functions for store type visual indicators
    func storeColor(for type: StoreType) -> Color {
        switch type {
        case .supermarket:
            return Color.green
        case .groceryStore:
            return Color.blue
        case .convenience:
            return Color.orange
        }
    }
    
    func storeIcon(for type: StoreType) -> String {
        switch type {
        case .supermarket:
            return "cart.fill"
        case .groceryStore:
            return "bag.fill"
        case .convenience:
            return "house.fill"
        }
    }
}

// Alert Identifiable extension for ViewModel
extension StoreViewModel {
    struct Alert: Identifiable {
        let id = UUID()
        let message: String
    }
}

// MARK: - Components
struct StoreRow: View {
    let store: Store
    @ObservedObject var viewModel: StoreViewModel

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        Text(store.name)
                            .font(.headline)
                        
                        Text(store.type.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(typeColor(for: store.type).opacity(0.2))
                            .foregroundColor(typeColor(for: store.type))
                            .cornerRadius(4)
                    }
                    
                    Text(store.address)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    HStack {
                        ForEach(0..<Int(store.rating), id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.system(size: 12))
                        }
                        if floor(store.rating) < store.rating {
                            Image(systemName: "star.leadinghalf.fill")
                                .foregroundColor(.yellow)
                                .font(.system(size: 12))
                        }
                    }
                    
                    Text("\(store.rating, specifier: "%.1f")")
                        .foregroundColor(.black)
                        .font(.caption)
                }
            }

            Divider()
            
            HStack {
                Text("\(store.distance, specifier: "%.1f") km away")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button(action: {
                    viewModel.getDirections(to: store)
                }) {
                    HStack {
                        Image(systemName: "location.fill")
                            .font(.caption)
                        Text("Get Directions")
                            .font(.caption)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(typeColor(for: store.type))
                    .foregroundColor(.white)
                    .cornerRadius(20)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4)
    }
    
    // Helper for type color
    func typeColor(for type: StoreType) -> Color {
        switch type {
        case .supermarket:
            return Color.green
        case .groceryStore:
            return Color.blue
        case .convenience:
            return Color.orange
        }
    }
}

struct DirectionsView: View {
    let store: Store
    let directions: [String]
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Image(systemName: typeIcon(for: store.type))
                        .foregroundColor(typeColor(for: store.type))
                        .font(.system(size: 24))
                        .frame(width: 40, height: 40)
                        .background(typeColor(for: store.type).opacity(0.2))
                        .cornerRadius(20)
                    
                    VStack(alignment: .leading) {
                        Text(store.name)
                            .font(.headline)
                        
                        Text("\(store.distance, specifier: "%.1f") km | Rating: \(store.rating, specifier: "%.1f") | \(store.type.rawValue)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Text(store.address)
                    .font(.subheadline)
                    .padding(10)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)

                Divider()
                
                Text("Step-by-Step Directions")
                    .font(.headline)
                    .padding(.top, 10)

                ScrollView {
                    VStack(alignment: .leading, spacing: 15) {
                        ForEach(0..<directions.count, id: \.self) { index in
                            HStack(alignment: .top) {
                                ZStack {
                                    Circle()
                                        .fill(typeColor(for: store.type))
                                        .frame(width: 24, height: 24)
                                    
                                    Text("\(index + 1)")
                                        .font(.caption)
                                        .bold()
                                        .foregroundColor(.white)
                                }
                                
                                Text(directions[index])
                                    .padding(.leading, 5)
                            }
                            
                            if index < directions.count - 1 {
                                Rectangle()
                                    .fill(typeColor(for: store.type).opacity(0.3))
                                    .frame(width: 2, height: 20)
                                    .padding(.leading, 11)
                            }
                        }
                    }
                    .padding(.leading, 10)
                }

                Spacer()
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Close Directions")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(typeColor(for: store.type))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.top, 20)
            }
            .padding()
            .navigationBarTitle("Directions", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    // Helper for type color
    func typeColor(for type: StoreType) -> Color {
        switch type {
        case .supermarket:
            return Color.green
        case .groceryStore:
            return Color.blue
        case .convenience:
            return Color.orange
        }
    }
    
    // Helper for type icon
    func typeIcon(for type: StoreType) -> String {
        switch type {
        case .supermarket:
            return "cart.fill"
        case .groceryStore:
            return "bag.fill"
        case .convenience:
            return "house.fill"
        }
    }
}


// MARK: - Preview
struct LocatorView_Previews: PreviewProvider {
    static var previews: some View {
        LocatorView(navPath: .constant(NavigationPath()))
    }
}
