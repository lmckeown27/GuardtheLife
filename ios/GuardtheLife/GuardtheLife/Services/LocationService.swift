import Foundation
import CoreLocation
import MapKit
import Combine

class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()
    
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLocationEnabled = false
    @Published var locationError: String?
    @Published var nearbyLifeguards: [Lifeguard] = []
    
    private let locationManager = CLLocationManager()
    private let apiService = APIService.shared
    private let socketService = SocketService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Location update timer
    private var locationUpdateTimer: Timer?
    private let locationUpdateInterval: TimeInterval = 30.0 // 30 seconds
    
    // Geofencing
    private var monitoredRegions: Set<CLCircularRegion> = []
    
    private override init() {
        super.init()
        setupLocationManager()
        setupLocationUpdateTimer()
    }
    
    // MARK: - Setup
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // meters
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        
        // Check current authorization status
        authorizationStatus = locationManager.authorizationStatus
        isLocationEnabled = CLLocationManager.locationServicesEnabled()
    }
    
    private func setupLocationUpdateTimer() {
        locationUpdateTimer = Timer.scheduledTimer(withTimeInterval: locationUpdateInterval, repeats: true) { [weak self] _ in
            self?.updateLocationIfNeeded()
        }
    }
    
    // MARK: - Authorization
    func requestLocationPermission() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            locationError = "Location access is required for this app to function properly. Please enable it in Settings."
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        @unknown default:
            break
        }
    }
    
    func requestAlwaysLocationPermission() {
        locationManager.requestAlwaysAuthorization()
    }
    
    // MARK: - Location Updates
    func startLocationUpdates() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            locationError = "Location permission not granted"
            return
        }
        
        guard isLocationEnabled else {
            locationError = "Location services are disabled"
            return
        }
        
        locationManager.startUpdatingLocation()
        locationManager.startMonitoringSignificantLocationChanges()
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()
    }
    
    private func updateLocationIfNeeded() {
        guard let location = currentLocation else { return }
        
        // Emit location update via Socket.IO
        socketService.emitLocationUpdate(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        
        // Update lifeguard location if user is a lifeguard
        if let user = AuthService.shared.currentUser, user.role == .lifeguard {
            Task {
                do {
                    try await apiService.updateLifeguardLocation(
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude
                    )
                } catch {
                    print("Failed to update lifeguard location: \(error)")
                }
            }
        }
    }
    
    // MARK: - Nearby Lifeguards
    func findNearbyLifeguards(radius: Double = 10.0) async {
        guard let location = currentLocation else { return }
        
        do {
            let lifeguards = try await apiService.getLifeguards(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                radius: radius
            )
            
            DispatchQueue.main.async {
                self.nearbyLifeguards = lifeguards
            }
        } catch {
            DispatchQueue.main.async {
                self.locationError = "Failed to find nearby lifeguards: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Geofencing
    func startMonitoringRegion(for lifeguard: Lifeguard) {
        guard let lifeguardLocation = lifeguard.currentLocation else { return }
        
        let region = CLCircularRegion(
            center: lifeguardLocation.coordinate,
            radius: 100, // 100 meters
            identifier: "lifeguard_\(lifeguard.id)"
        )
        
        region.notifyOnEntry = true
        region.notifyOnExit = true
        
        locationManager.startMonitoring(for: region)
        monitoredRegions.insert(region)
    }
    
    func stopMonitoringRegion(for lifeguard: Lifeguard) {
        let regionIdentifier = "lifeguard_\(lifeguard.id)"
        
        for region in monitoredRegions {
            if region.identifier == regionIdentifier {
                locationManager.stopMonitoring(for: region)
                monitoredRegions.remove(region)
                break
            }
        }
    }
    
    // MARK: - Distance Calculations
    func calculateDistance(to location: Location) -> CLLocationDistance? {
        guard let currentLocation = currentLocation else { return nil }
        
        let targetLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        return currentLocation.distance(from: targetLocation)
    }
    
    func calculateDistanceInMiles(to location: Location) -> Double? {
        guard let distance = calculateDistance(to: location) else { return nil }
        return distance * 0.000621371 // Convert meters to miles
    }
    
    func formatDistance(to location: Location) -> String {
        guard let distanceInMiles = calculateDistanceInMiles(to: location) else {
            return "Distance unknown"
        }
        
        if distanceInMiles < 1.0 {
            let yards = distanceInMiles * 1760
            return "\(Int(yards)) yards away"
        } else if distanceInMiles < 10.0 {
            return String(format: "%.1f miles away", distanceInMiles)
        } else {
            return String(format: "%.0f miles away", distanceInMiles)
        }
    }
    
    // MARK: - Map Integration
    func getMapRegion(for locations: [Location], padding: Double = 0.01) -> MKCoordinateRegion? {
        guard !locations.isEmpty else { return nil }
        
        var minLat = locations[0].latitude
        var maxLat = locations[0].latitude
        var minLon = locations[0].longitude
        var maxLon = locations[0].longitude
        
        for location in locations {
            minLat = min(minLat, location.latitude)
            maxLat = max(maxLat, location.latitude)
            minLon = min(minLon, location.longitude)
            maxLon = max(maxLon, location.longitude)
        }
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) + padding,
            longitudeDelta: (maxLon - minLon) + padding
        )
        
        return MKCoordinateRegion(center: center, span: span)
    }
    
    // MARK: - Emergency Location
    func getEmergencyLocation() -> Location? {
        guard let location = currentLocation else { return nil }
        
        return Location(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            address: nil,
            city: nil,
            state: nil,
            country: nil
        )
    }
    
    // MARK: - Cleanup
    deinit {
        stopLocationUpdates()
        locationUpdateTimer?.invalidate()
        cancellables.removeAll()
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        DispatchQueue.main.async {
            self.currentLocation = location
            self.locationError = nil
        }
        
        // Find nearby lifeguards when location updates
        Task {
            await findNearbyLifeguards()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.locationError = error.localizedDescription
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status
            
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                self.isLocationEnabled = true
                self.startLocationUpdates()
            case .denied, .restricted:
                self.isLocationEnabled = false
                self.locationError = "Location access denied"
            case .notDetermined:
                self.isLocationEnabled = false
            @unknown default:
                break
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Entered region: \(region.identifier)")
        // Handle entering a monitored region (e.g., lifeguard area)
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Exited region: \(region.identifier)")
        // Handle exiting a monitored region
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Monitoring failed for region: \(region?.identifier ?? "unknown")")
    }
} 