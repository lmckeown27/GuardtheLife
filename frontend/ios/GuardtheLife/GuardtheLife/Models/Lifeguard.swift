import Foundation
import CoreLocation

struct Lifeguard: Codable, Identifiable {
    let id: String
    let userId: String
    let user: User
    let certifications: [Certification]
    let experience: Int // years
    let hourlyRate: Double
    let isAvailable: Bool
    let currentLocation: Location?
    let rating: Double
    let totalBookings: Int
    let specialties: [String]
    let bio: String?
    let createdAt: Date
    let updatedAt: Date
    
    var displayName: String {
        user.fullName
    }
    
    var isOnline: Bool {
        isAvailable && currentLocation != nil
    }
}

struct Certification: Codable, Identifiable {
    let id: String
    let name: String
    let issuingOrganization: String
    let issueDate: Date
    let expiryDate: Date?
    let isActive: Bool
    
    var isExpired: Bool {
        guard let expiryDate = expiryDate else { return false }
        return Date() > expiryDate
    }
}

struct Location: Codable {
    let latitude: Double
    let longitude: Double
    let address: String?
    let city: String?
    let state: String?
    let country: String?
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var formattedAddress: String {
        let components = [address, city, state, country].compactMap { $0 }
        return components.joined(separator: ", ")
    }
}

// MARK: - Distance Calculation
extension Location {
    func distance(to other: Location) -> CLLocationDistance {
        let thisLocation = CLLocation(latitude: latitude, longitude: longitude)
        let otherLocation = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return thisLocation.distance(from: otherLocation)
    }
    
    func distanceInMiles(to other: Location) -> Double {
        let meters = distance(to: other)
        return meters * 0.000621371 // Convert meters to miles
    }
} 