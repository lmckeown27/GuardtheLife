import Foundation
import CoreLocation

struct Lifeguard: Codable, Identifiable {
    let id: String
    let firstName: String
    let lastName: String
    let email: String
    let phoneNumber: String?
    let isVerified: Bool
    let isAvailable: Bool
    let rating: Double
    let totalBookings: Int
    let specializations: [String]
    let hourlyRate: Double
    let profileImageURL: String?
    let location: Location?
    let bio: String?
    let certifications: [Certification]  // ✅ Added back for verification
    let experience: Int  // ✅ Years of experience
    let createdAt: Date
    let updatedAt: Date?
    
    // Computed properties for convenience
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    var displayName: String {
        fullName
    }
    
    var isOnline: Bool {
        isAvailable && location != nil
    }
    
    // ✅ Certification verification computed properties
    var hasValidCPR: Bool {
        certifications.contains { cert in
            cert.type == .cprAED && !cert.isExpired
        }
    }
    
    var hasValidLifeguarding: Bool {
        certifications.contains { cert in
            cert.type == .lifeguarding && !cert.isExpired
        }
    }
    
    var isFullyCertified: Bool {
        hasValidCPR && hasValidLifeguarding
    }
    
    var activeCertifications: [Certification] {
        certifications.filter { !$0.isExpired }
    }
    
    var expiredCertifications: [Certification] {
        certifications.filter { $0.isExpired }
    }
    
    // Custom coding keys to handle different API response formats
    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case phoneNumber = "phone_number"
        case isVerified = "is_verified"
        case isAvailable = "is_available"
        case rating
        case totalBookings = "total_bookings"
        case specializations
        case hourlyRate = "hourly_rate"
        case profileImageURL = "profile_image_url"
        case location
        case bio
        case certifications
        case experience
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // Custom initializer for creating from API data
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        firstName = try container.decode(String.self, forKey: .firstName)
        lastName = try container.decode(String.self, forKey: .lastName)
        email = try container.decode(String.self, forKey: .email)
        phoneNumber = try container.decodeIfPresent(String.self, forKey: .phoneNumber)
        isVerified = try container.decode(Bool.self, forKey: .isVerified)
        isAvailable = try container.decode(Bool.self, forKey: .isAvailable)
        rating = try container.decode(Double.self, forKey: .rating)
        totalBookings = try container.decode(Int.self, forKey: .totalBookings)
        specializations = try container.decode([String].self, forKey: .specializations)
        hourlyRate = try container.decode(Double.self, forKey: .hourlyRate)
        profileImageURL = try container.decodeIfPresent(String.self, forKey: .profileImageURL)
        location = try container.decodeIfPresent(Location.self, forKey: .location)
        bio = try container.decodeIfPresent(String.self, forKey: .bio)
        certifications = try container.decode([Certification].self, forKey: .certifications)
        experience = try container.decode(Int.self, forKey: .experience)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }
    
    // Custom initializer for creating instances programmatically
    init(id: String, firstName: String, lastName: String, email: String, phoneNumber: String?, isVerified: Bool, isAvailable: Bool, rating: Double, totalBookings: Int, specializations: [String], hourlyRate: Double, profileImageURL: String?, location: Location?, bio: String?, certifications: [Certification], experience: Int, createdAt: Date, updatedAt: Date? = nil) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phoneNumber = phoneNumber
        self.isVerified = isVerified
        self.isAvailable = isAvailable
        self.rating = rating
        self.totalBookings = totalBookings
        self.specializations = specializations
        self.hourlyRate = hourlyRate
        self.profileImageURL = profileImageURL
        self.location = location
        self.bio = bio
        self.certifications = certifications
        self.experience = experience
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// ✅ Enhanced Certification system for real-world verification
struct Certification: Codable, Identifiable {
    let id: String
    let type: CertificationType
    let name: String
    let issuingOrganization: String
    let certificateNumber: String?  // For verification purposes
    let issueDate: Date
    let expiryDate: Date?
    let isActive: Bool
    let verificationStatus: VerificationStatus
    let verificationDate: Date?
    let verifiedBy: String?  // Who verified this certification
    
    var isExpired: Bool {
        guard let expiryDate = expiryDate else { return false }
        return Date() > expiryDate
    }
    
    var daysUntilExpiry: Int? {
        guard let expiryDate = expiryDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: expiryDate)
        return components.day
    }
    
    var isExpiringSoon: Bool {
        guard let daysUntilExpiry = daysUntilExpiry else { return false }
        return daysUntilExpiry <= 30 && daysUntilExpiry > 0
    }
    
    var statusColor: String {
        if isExpired { return "red" }
        if isExpiringSoon { return "orange" }
        if verificationStatus == .verified { return "green" }
        if verificationStatus == .pending { return "yellow" }
        return "gray"
    }
}

// ✅ Comprehensive certification types for lifeguards
enum CertificationType: String, Codable, CaseIterable {
    case cprAED = "cpr_aed"
    case lifeguarding = "lifeguarding"
    case firstAid = "first_aid"
    case waterSafety = "water_safety"
    case poolOperator = "pool_operator"
    case instructor = "instructor"
    case advancedLifeguarding = "advanced_lifeguarding"
    case waterfrontLifeguarding = "waterfront_lifeguarding"
    case shallowWaterAttendant = "shallow_water_attendant"
    case aquaticAttractionLifeguarding = "aquatic_attraction_lifeguarding"
    
    var displayName: String {
        switch self {
        case .cprAED: return "CPR/AED for Professional Rescuers"
        case .lifeguarding: return "Lifeguarding"
        case .firstAid: return "First Aid"
        case .waterSafety: return "Water Safety Instructor"
        case .poolOperator: return "Pool Operator"
        case .instructor: return "Lifeguard Instructor"
        case .advancedLifeguarding: return "Advanced Lifeguarding"
        case .waterfrontLifeguarding: return "Waterfront Lifeguarding"
        case .shallowWaterAttendant: return "Shallow Water Attendant"
        case .aquaticAttractionLifeguarding: return "Aquatic Attraction Lifeguarding"
        }
    }
    
    var isRequired: Bool {
        switch self {
        case .cprAED, .lifeguarding:
            return true
        default:
            return false
        }
    }
    
    var validityPeriod: Int? {  // in months
        switch self {
        case .cprAED: return 24  // 2 years
        case .lifeguarding: return 24  // 2 years
        case .firstAid: return 24  // 2 years
        case .waterSafety: return 36  // 3 years
        case .poolOperator: return 60  // 5 years
        case .instructor: return 36  // 3 years
        case .advancedLifeguarding: return 24  // 2 years
        case .waterfrontLifeguarding: return 24  // 2 years
        case .shallowWaterAttendant: return 24  // 2 years
        case .aquaticAttractionLifeguarding: return 24  // 2 years
        }
    }
}

// ✅ Verification status for certification authenticity
enum VerificationStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case verified = "verified"
    case failed = "failed"
    case expired = "expired"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending Verification"
        case .verified: return "Verified"
        case .failed: return "Verification Failed"
        case .expired: return "Expired"
        }
    }
    
    var color: String {
        switch self {
        case .pending: return "yellow"
        case .verified: return "green"
        case .failed: return "red"
        case .expired: return "red"
        }
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