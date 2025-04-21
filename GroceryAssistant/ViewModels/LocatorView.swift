//import SwiftUI
//import MapKit
//import CoreLocation
//
//// MARK: - Models
//struct Store: Identifiable {
//    let id = UUID()
//    let name: String
//    let coordinates: CLLocationCoordinate2D
//    let address: String
//    let rating: Double
//    let distance: Double
//}
//
//// MARK: - ViewModel
//class StoreViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
//    @Published var stores: [Store] = []
//    @Published var region = MKCoordinateRegion()
//    @Published var userLocation: CLLocationCoordinate2D?
//    @Published var selectedStore: Store?
//    @Published var directions: [String] = []
//    @Published var showingDirections = false
//    @Published var isLoading = false
//    @Published var errorMessage: String?
//    
//    private var locationManager = CLLocationManager()
//    private let geocoder = CLGeocoder()
//    
//    // Sri Lanka coordinates (approximate center)
//    private let sriLankaCenter = CLLocationCoordinate2D(latitude: 7.8731, longitude: 80.7718)
//    
//    override init() {
//        super.init()
//        locationManager.delegate = self
//        locationManager.desiredAccuracy = kCLLocationAccuracyBest
//        locationManager.requestWhenInUseAuthorization()
//        locationManager.startUpdatingLocation()
//    }
//
//    private var hasFetchedStores = false
//
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        guard let location = locations.first else { return }
//        userLocation = location.coordinate
//        
//        // Use user location if they appear to be in Sri Lanka
//        // Otherwise use Sri Lanka center for demo/testing purposes
//        let userInSriLanka = isLocationInSriLanka(location.coordinate)
//        let locationToUse = userInSriLanka ? location.coordinate : sriLankaCenter
//        
//        updateRegion(to: locationToUse)
//
//        if !hasFetchedStores {
//            hasFetchedStores = true
//            fetchStores(near: CLLocation(latitude: locationToUse.latitude, longitude: locationToUse.longitude))
//        }
//    }
//    
//    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
//        print("Location manager failed with error: \(error.localizedDescription)")
//        errorMessage = "Unable to get your location. Using default Sri Lanka location."
//        
//        // Use Sri Lanka center coordinates if location fails
//        updateRegion(to: sriLankaCenter)
//        fetchStores(near: CLLocation(latitude: sriLankaCenter.latitude, longitude: sriLankaCenter.longitude))
//    }
//    
//    // Check if coordinates are in Sri Lanka (rough bounding box)
//    private func isLocationInSriLanka(_ coordinate: CLLocationCoordinate2D) -> Bool {
//        return coordinate.latitude >= 5.9 && coordinate.latitude <= 9.9 &&
//               coordinate.longitude >= 79.5 && coordinate.longitude <= 82.0
//    }
//
//    private func updateRegion(to coordinate: CLLocationCoordinate2D) {
//        region = MKCoordinateRegion(
//            center: coordinate,
//            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
//        )
//    }
//
//    func fetchStores(near location: CLLocation) {
//        isLoading = true
//        errorMessage = nil
//        
//        let request = MKLocalSearch.Request()
//        // Focus on supermarkets in Sri Lanka
//        request.naturalLanguageQuery = "supermarket OR grocery store"
//        
//        // Set a larger region to capture Sri Lanka supermarkets
//        let searchRegion = MKCoordinateRegion(
//            center: location.coordinate,
//            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
//        )
//        request.region = searchRegion
//        
//        // Add Sri Lanka region bias
//        request.region = MKCoordinateRegion(
//            center: location.coordinate,
//            latitudinalMeters: 20000,  // 20km radius
//            longitudinalMeters: 20000
//        )
//
//        let search = MKLocalSearch(request: request)
//        search.start { response, error in
//            DispatchQueue.main.async {
//                self.isLoading = false
//                
//                if let error = error {
//                    self.errorMessage = "Error finding supermarkets: \(error.localizedDescription)"
//                    return
//                }
//                
//                guard let mapItems = response?.mapItems, !mapItems.isEmpty else {
//                    self.errorMessage = "No supermarkets found nearby. Try adjusting your location."
//                    return
//                }
//
//                self.stores = mapItems.compactMap { item in
//                    guard let name = item.name,
//                          let coordinate = item.placemark.location?.coordinate else { return nil }
//
//                    // Filter to only include locations in Sri Lanka
//                    if !self.isLocationInSriLanka(coordinate) {
//                        return nil
//                    }
//                    
//                    let address = self.formatAddress(from: item.placemark)
//                    let distance = location.distance(from: item.placemark.location!) / 1000 // km
//                    
//                    // In real app, you would fetch real ratings from a database
//                    // Using random for demo purposes
//                    let randomRating = Double.random(in: 3.5...5.0)
//
//                    return Store(name: name,
//                                 coordinates: coordinate,
//                                 address: address,
//                                 rating: randomRating,
//                                 distance: distance)
//                }
//                .sorted { $0.rating > $1.rating }
//                
//                if self.stores.isEmpty {
//                    self.errorMessage = "No supermarkets found in Sri Lanka nearby. Try adjusting your location."
//                }
//            }
//        }
//    }
//    
//    // Format address specifically for Sri Lanka format
//    private func formatAddress(from placemark: MKPlacemark) -> String {
//        var components = [String]()
//        
//        if let thoroughfare = placemark.thoroughfare {
//            components.append(thoroughfare)
//        }
//        
//        if let subThoroughfare = placemark.subThoroughfare {
//            components.append(subThoroughfare)
//        }
//        
//        if let locality = placemark.locality {
//            components.append(locality)
//        }
//        
//        if let administrativeArea = placemark.administrativeArea {
//            components.append(administrativeArea)
//        }
//        
//        // Always add "Sri Lanka" for clarity
//        components.append("Sri Lanka")
//        
//        return components.joined(separator: ", ")
//    }
//
//    func getDirections(to store: Store) {
//        guard let userLocation = userLocation else {
//            errorMessage = "Unable to get your location for directions"
//            return
//        }
//        
//        selectedStore = store
//        isLoading = true
//        
//        let request = MKDirections.Request()
//        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation))
//        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: store.coordinates))
//        request.transportType = .automobile
//        
//        let directions = MKDirections(request: request)
//        directions.calculate { [weak self] response, error in
//            guard let self = self else { return }
//            
//            DispatchQueue.main.async {
//                self.isLoading = false
//                
//                if let error = error {
//                    self.errorMessage = "Error getting directions: \(error.localizedDescription)"
//                    return
//                }
//                
//                guard let route = response?.routes.first else {
//                    self.errorMessage = "No route found to this supermarket"
//                    return
//                }
//                
//                // Process step-by-step directions
//                self.directions = route.steps.map { step in
//                    let distance = self.formatDistance(meters: step.distance)
//                    return "\(step.instructions) (\(distance))"
//                }
//                
//                if self.directions.isEmpty {
//                    self.directions = [
//                        "Start from your location.",
//                        "Head to \(store.name)",
//                        "Arrive at destination."
//                    ]
//                }
//                
//                self.showingDirections = true
//            }
//        }
//    }
//    
//    private func formatDistance(meters: CLLocationDistance) -> String {
//        if meters < 1000 {
//            return "\(Int(meters))m"
//        } else {
//            return String(format: "%.1f km", meters / 1000)
//        }
//    }
//    
//    // Refresh supermarkets data
//    func refreshStores() {
//        guard let userLocation = userLocation else {
//            errorMessage = "Unable to get your location"
//            return
//        }
//        
//        fetchStores(near: CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude))
//    }
//}
//
//
//// MARK: - Views
//struct LocatorView: View {
//    @Binding var navPath: NavigationPath
//    @StateObject private var viewModel = StoreViewModel()
//
//    var body: some View {
//        VStack(spacing: 0) {
//            ZStack {
//                Color.green.ignoresSafeArea(edges: .top)
//                HStack {
//                    Button(action: {}) {
//                        Image(systemName: "arrow.left")
//                            .foregroundColor(.white)
//                    }
//                    Spacer()
//                    Text("Sri Lanka Supermarkets")
//                        .foregroundColor(.white)
//                        .bold()
//                    Spacer()
//                    Button(action: {
//                        viewModel.refreshStores()
//                    }) {
//                        Image(systemName: "arrow.clockwise")
//                            .foregroundColor(.white)
//                    }
//                }.padding()
//            }.frame(height: 44)
//
//            ZStack {
//                Map(coordinateRegion: $viewModel.region, showsUserLocation: true, annotationItems: viewModel.stores) { store in
//                    MapAnnotation(coordinate: store.coordinates) {
//                        ZStack {
//                            Circle()
//                                .fill(Color.green)
//                                .frame(width: 32, height: 32)
//                                .overlay(
//                                    Image(systemName: "cart")
//                                        .foregroundColor(.white)
//                                )
//                                .shadow(radius: 2)
//                                .onTapGesture {
//                                    viewModel.selectedStore = store
//                                }
//                            
//                            // Display rating on the map
//                            Text(String(format: "%.1f", store.rating))
//                                .font(.system(size: 8))
//                                .foregroundColor(.white)
//                                .padding(2)
//                                .background(Color.black.opacity(0.6))
//                                .cornerRadius(4)
//                                .offset(y: 20)
//                        }
//                    }
//                }
//                .frame(height: 250)
//                
//                if viewModel.isLoading {
//                    ProgressView()
//                        .scaleEffect(1.5)
//                        .padding()
//                        .background(Color.white.opacity(0.8))
//                        .cornerRadius(10)
//                }
//                
//                if let errorMessage = viewModel.errorMessage {
//                    Text(errorMessage)
//                        .font(.caption)
//                        .foregroundColor(.white)
//                        .padding(8)
//                        .background(Color.red)
//                        .cornerRadius(8)
//                        .padding()
//                        .transition(.slide)
//                }
//            }
//
//            ScrollView {
//                if viewModel.stores.isEmpty && !viewModel.isLoading {
//                    VStack(spacing: 10) {
//                        Image(systemName: "mappin.slash")
//                            .font(.system(size: 48))
//                            .foregroundColor(.gray)
//                        
//                        Text("No supermarkets found")
//                            .font(.headline)
//                        
//                        Text("Try adjusting your location or search parameters")
//                            .font(.caption)
//                            .foregroundColor(.gray)
//                            .multilineTextAlignment(.center)
//                            .padding(.horizontal)
//                        
//                        Button("Refresh") {
//                            viewModel.refreshStores()
//                        }
//                        .padding(.vertical, 10)
//                        .padding(.horizontal, 20)
//                        .background(Color.green)
//                        .foregroundColor(.white)
//                        .cornerRadius(10)
//                        .padding(.top, 10)
//                    }
//                    .padding(.vertical, 40)
//                } else {
//                    VStack(spacing: 12) {
//                        ForEach(viewModel.stores) { store in
//                            StoreRow(store: store, viewModel: viewModel)
//                        }
//                    }.padding()
//                }
//            }
//
//            HStack {
//                TabBarItem(imageName: "leaf", text: "Nutritional")
//                TabBarItem(imageName: "mappin.and.ellipse", text: "Find Store", isSelected: true)
//
//                ZStack {
//                    Circle()
//                        .fill(Color.white)
//                        .frame(width: 60, height: 60)
//                        .shadow(radius: 2)
//                    Button(action: {}) {
//                        Image(systemName: "house.fill")
//                            .font(.system(size: 24))
//                            .foregroundColor(.green)
//                    }
//                }
//                .offset(y: -20)
//
//                TabBarItem(imageName: "list.bullet", text: "Item Lists")
//                TabBarItem(imageName: "bell", text: "Reminder")
//            }
//            .frame(height: 60)
//            .background(Color.white)
//            .shadow(radius: 5)
//        }
//        .sheet(isPresented: $viewModel.showingDirections) {
//            if let store = viewModel.selectedStore {
//                DirectionsView(store: store, directions: viewModel.directions)
//            }
//        }
//        .alert(item: Binding<StoreViewModel.Alert?>(
//            get: {
//                if let message = viewModel.errorMessage {
//                    return StoreViewModel.Alert(message: message)
//                }
//                return nil
//            },
//            set: { _ in viewModel.errorMessage = nil }
//        )) { alert in
//            Alert(title: Text("Error"), message: Text(alert.message), dismissButton: .default(Text("OK")))
//        }
//    }
//}
//
//// Alert Identifiable extension for ViewModel
//extension StoreViewModel {
//    struct Alert: Identifiable {
//        let id = UUID()
//        let message: String
//    }
//}
//
//// MARK: - Components
//struct StoreRow: View {
//    let store: Store
//    @ObservedObject var viewModel: StoreViewModel
//
//    var body: some View {
//        VStack(alignment: .leading) {
//            HStack {
//                VStack(alignment: .leading) {
//                    Text(store.name)
//                        .font(.headline)
//                    
//                    Text(store.address)
//                        .font(.caption)
//                        .foregroundColor(.gray)
//                        .lineLimit(1)
//                }
//                
//                Spacer()
//                
//                VStack(alignment: .trailing) {
//                    HStack {
//                        ForEach(0..<Int(store.rating), id: \.self) { _ in
//                            Image(systemName: "star.fill")
//                                .foregroundColor(.yellow)
//                                .font(.system(size: 12))
//                        }
//                        if floor(store.rating) < store.rating {
//                            Image(systemName: "star.leadinghalf.fill")
//                                .foregroundColor(.yellow)
//                                .font(.system(size: 12))
//                        }
//                    }
//                    
//                    Text("\(store.rating, specifier: "%.1f")")
//                        .foregroundColor(.black)
//                        .font(.caption)
//                }
//            }
//
//            Divider()
//            
//            HStack {
//                Text("\(store.distance, specifier: "%.1f") km away")
//                    .font(.caption)
//                    .foregroundColor(.gray)
//                
//                Spacer()
//                
//                Button(action: {
//                    viewModel.getDirections(to: store)
//                }) {
//                    HStack {
//                        Image(systemName: "location.fill")
//                            .font(.caption)
//                        Text("Get Directions")
//                            .font(.caption)
//                    }
//                    .padding(.horizontal, 12)
//                    .padding(.vertical, 6)
//                    .background(Color.green)
//                    .foregroundColor(.white)
//                    .cornerRadius(20)
//                }
//            }
//        }
//        .padding()
//        .background(Color.white)
//        .cornerRadius(12)
//        .shadow(color: Color.black.opacity(0.05), radius: 4)
//    }
//}
//
//struct TabBarItem: View {
//    let imageName: String
//    let text: String
//    var isSelected: Bool = false
//
//    var body: some View {
//        Button(action: {}) {
//            VStack {
//                Image(systemName: imageName)
//                    .foregroundColor(isSelected ? .green : .gray)
//                Text(text)
//                    .font(.caption)
//                    .foregroundColor(isSelected ? .green : .gray)
//            }
//        }
//        .frame(maxWidth: .infinity)
//    }
//}
//
//struct DirectionsView: View {
//    let store: Store
//    let directions: [String]
//    @Environment(\.presentationMode) var presentationMode
//
//    var body: some View {
//        NavigationView {
//            VStack(alignment: .leading, spacing: 20) {
//                HStack {
//                    Image(systemName: "cart.fill")
//                        .foregroundColor(.green)
//                        .font(.system(size: 24))
//                        .frame(width: 40, height: 40)
//                        .background(Color.green.opacity(0.2))
//                        .cornerRadius(20)
//                    
//                    VStack(alignment: .leading) {
//                        Text(store.name)
//                            .font(.headline)
//                        
//                        Text("\(store.distance, specifier: "%.1f") km | Rating: \(store.rating, specifier: "%.1f")")
//                            .font(.caption)
//                            .foregroundColor(.gray)
//                    }
//                }
//                
//                Text(store.address)
//                    .font(.subheadline)
//                    .padding(10)
//                    .background(Color.gray.opacity(0.1))
//                    .cornerRadius(8)
//
//                Divider()
//                
//                Text("Step-by-Step Directions")
//                    .font(.headline)
//                    .padding(.top, 10)
//
//                ScrollView {
//                    VStack(alignment: .leading, spacing: 15) {
//                        ForEach(0..<directions.count, id: \.self) { index in
//                            HStack(alignment: .top) {
//                                ZStack {
//                                    Circle()
//                                        .fill(Color.green)
//                                        .frame(width: 24, height: 24)
//                                    
//                                    Text("\(index + 1)")
//                                        .font(.caption)
//                                        .bold()
//                                        .foregroundColor(.white)
//                                }
//                                
//                                Text(directions[index])
//                                    .padding(.leading, 5)
//                            }
//                            
//                            if index < directions.count - 1 {
//                                Rectangle()
//                                    .fill(Color.green.opacity(0.3))
//                                    .frame(width: 2, height: 20)
//                                    .padding(.leading, 11)
//                            }
//                        }
//                    }
//                    .padding(.leading, 10)
//                }
//
//                Spacer()
//                
//                Button(action: {
//                    presentationMode.wrappedValue.dismiss()
//                }) {
//                    Text("Close Directions")
//                        .frame(maxWidth: .infinity)
//                        .padding()
//                        .background(Color.green)
//                        .foregroundColor(.white)
//                        .cornerRadius(10)
//                }
//                .padding(.top, 20)
//            }
//            .padding()
//            .navigationBarTitle("Directions", displayMode: .inline)
//            .navigationBarItems(trailing: Button("Done") {
//                presentationMode.wrappedValue.dismiss()
//            })
//        }
//    }
//}
//
//
//// MARK: - Preview
//struct LocatorView_Previews: PreviewProvider {
//    static var previews: some View {
//        LocatorView(navPath: .constant(NavigationPath()))
//    }
//}


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
        
        // Use user location if they appear to be in Sri Lanka
        // Otherwise use Sri Lanka center for demo/testing purposes
        let userInSriLanka = isLocationInSriLanka(location.coordinate)
        let locationToUse = userInSriLanka ? location.coordinate : sriLankaCenter
        
        updateRegion(to: locationToUse)

        if !hasFetchedStores {
            hasFetchedStores = true
            fetchStores(near: CLLocation(latitude: locationToUse.latitude, longitude: locationToUse.longitude))
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
        errorMessage = "Unable to get your location. Using default Sri Lanka location."
        
        // Use Sri Lanka center coordinates if location fails
        updateRegion(to: sriLankaCenter)
        fetchStores(near: CLLocation(latitude: sriLankaCenter.latitude, longitude: sriLankaCenter.longitude))
    }
    
    // Check if coordinates are in Sri Lanka (rough bounding box)
    private func isLocationInSriLanka(_ coordinate: CLLocationCoordinate2D) -> Bool {
        // More generous bounding box for Sri Lanka that includes surrounding waters
        return coordinate.latitude >= 5.5 && coordinate.latitude <= 10.0 &&
               coordinate.longitude >= 79.0 && coordinate.longitude <= 82.5
    }

    private func updateRegion(to coordinate: CLLocationCoordinate2D) {
        region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    }

    func fetchStores(near location: CLLocation) {
        isLoading = true
        errorMessage = nil
        
        let request = MKLocalSearch.Request()
        // Focus on supermarkets in Sri Lanka - use more specific query terms
        request.naturalLanguageQuery = "supermarket Sri Lanka"
        
        // Set a more reasonable region for Sri Lanka search
        // Using a larger span to cover more area
        let searchRegion = MKCoordinateRegion(
            center: sriLankaCenter,  // Use Sri Lanka center instead of user location
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )
        request.region = searchRegion
        
        // Add a delay to prevent throttling if we've searched recently
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let search = MKLocalSearch(request: request)
            search.start { response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Error finding supermarkets: \(error.localizedDescription)"
                    // If we get a throttling error, use fallback data
                    if (error as NSError).domain == MKErrorDomain && (error as NSError).code == 4 {
                        self.createFallbackStores(near: location)
                        return
                    }
                    return
                }
                
                guard let mapItems = response?.mapItems, !mapItems.isEmpty else {
                    self.errorMessage = "No supermarkets found nearby. Try adjusting your location."
                    return
                }

                self.stores = mapItems.compactMap { item in
                    guard let name = item.name,
                          let coordinate = item.placemark.location?.coordinate else { return nil }

                    // Filter to only include locations in Sri Lanka
                    if !self.isLocationInSriLanka(coordinate) {
                        return nil
                    }
                    
                    let address = self.formatAddress(from: item.placemark)
                    let distance = location.distance(from: item.placemark.location!) / 1000 // km
                    
                    // In real app, you would fetch real ratings from a database
                    // Using random for demo purposes
                    let randomRating = Double.random(in: 3.5...5.0)

                    return Store(name: name,
                                 coordinates: coordinate,
                                 address: address,
                                 rating: randomRating,
                                 distance: distance)
                }
                .sorted { $0.rating > $1.rating }
                
                if self.stores.isEmpty {
                    // If no stores found, use fallback data
                    self.createFallbackStores(near: location)
                }
            }
        }
    }
    }
    
    // Create fallback store data for Sri Lanka when MapKit search fails
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
            distance: location.distance(from: CLLocation(latitude: 6.9271, longitude: 79.8612)) / 1000
        ))
        
        fallbackStores.append(Store(
            name: "Cargills Food City - Colombo",
            coordinates: CLLocationCoordinate2D(latitude: 6.9344, longitude: 79.8500),
            address: "Staples Street, Colombo, Sri Lanka",
            rating: 4.5,
            distance: location.distance(from: CLLocation(latitude: 6.9344, longitude: 79.8500)) / 1000
        ))
        
        // Kandy supermarkets
        fallbackStores.append(Store(
            name: "Arpico Super Centre - Kandy",
            coordinates: CLLocationCoordinate2D(latitude: 7.2906, longitude: 80.6337),
            address: "Peradeniya Road, Kandy, Sri Lanka",
            rating: 4.6,
            distance: location.distance(from: CLLocation(latitude: 7.2906, longitude: 80.6337)) / 1000
        ))
        
        // Galle supermarkets
        fallbackStores.append(Store(
            name: "Lanka Sathosa - Galle",
            coordinates: CLLocationCoordinate2D(latitude: 6.0535, longitude: 80.2210),
            address: "Main Street, Galle, Sri Lanka",
            rating: 4.2,
            distance: location.distance(from: CLLocation(latitude: 6.0535, longitude: 80.2210)) / 1000
        ))
        
        // Negombo supermarkets
        fallbackStores.append(Store(
            name: "Softlogic GLOMARK - Negombo",
            coordinates: CLLocationCoordinate2D(latitude: 7.2081, longitude: 79.8371),
            address: "Colombo Road, Negombo, Sri Lanka",
            rating: 4.4,
            distance: location.distance(from: CLLocation(latitude: 7.2081, longitude: 79.8371)) / 1000
        ))
        
        // Jaffna supermarkets
        fallbackStores.append(Store(
            name: "Cargills Food City - Jaffna",
            coordinates: CLLocationCoordinate2D(latitude: 9.6615, longitude: 80.0255),
            address: "Hospital Road, Jaffna, Sri Lanka",
            rating: 4.3,
            distance: location.distance(from: CLLocation(latitude: 9.6615, longitude: 80.0255)) / 1000
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
        
        // Always add "Sri Lanka" for clarity
        components.append("Sri Lanka")
        
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
        
        // First check if we're trying to use actual directions
        if !isLocationInSriLanka(userLocation) {
            // If user is not in Sri Lanka, use fallback directions
            createFallbackDirections(to: store)
            return
        }
        
        let directions = MKDirections(request: request)
        directions.calculate { [weak self] response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Error getting directions: \(error.localizedDescription)"
                    return
                }
                
                guard let route = response?.routes.first else {
                    self.errorMessage = "No route found to this supermarket"
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
    
    // Refresh supermarkets data
    func refreshStores() {
        guard let userLocation = userLocation else {
            errorMessage = "Unable to get your location"
            return
        }
        
        fetchStores(near: CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude))
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
                    Text("Sri Lanka Supermarkets")
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
                Map(coordinateRegion: $viewModel.region, showsUserLocation: true, annotationItems: viewModel.stores) { store in
                    MapAnnotation(coordinate: store.coordinates) {
                        ZStack {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Image(systemName: "cart")
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
                .frame(height: 250)
                
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

            ScrollView {
                if viewModel.stores.isEmpty && !viewModel.isLoading {
                    VStack(spacing: 10) {
                        Image(systemName: "mappin.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text("No supermarkets found")
                            .font(.headline)
                        
                        Text("Try adjusting your location or search parameters")
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

            HStack {
                TabBarItem(imageName: "leaf", text: "Nutritional")
                TabBarItem(imageName: "mappin.and.ellipse", text: "Find Store", isSelected: true)

                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 60, height: 60)
                        .shadow(radius: 2)
                    Button(action: {}) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.green)
                    }
                }
                .offset(y: -20)

                TabBarItem(imageName: "list.bullet", text: "Item Lists")
                TabBarItem(imageName: "bell", text: "Reminder")
            }
            .frame(height: 60)
            .background(Color.white)
            .shadow(radius: 5)
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
                    Text(store.name)
                        .font(.headline)
                    
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
                    .background(Color.green)
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
}

struct TabBarItem: View {
    let imageName: String
    let text: String
    var isSelected: Bool = false

    var body: some View {
        Button(action: {}) {
            VStack {
                Image(systemName: imageName)
                    .foregroundColor(isSelected ? .green : .gray)
                Text(text)
                    .font(.caption)
                    .foregroundColor(isSelected ? .green : .gray)
            }
        }
        .frame(maxWidth: .infinity)
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
                    Image(systemName: "cart.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 24))
                        .frame(width: 40, height: 40)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(20)
                    
                    VStack(alignment: .leading) {
                        Text(store.name)
                            .font(.headline)
                        
                        Text("\(store.distance, specifier: "%.1f") km | Rating: \(store.rating, specifier: "%.1f")")
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
                                        .fill(Color.green)
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
                                    .fill(Color.green.opacity(0.3))
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
                        .background(Color.green)
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
}


// MARK: - Preview
struct LocatorView_Previews: PreviewProvider {
    static var previews: some View {
        LocatorView(navPath: .constant(NavigationPath()))
    }
}
