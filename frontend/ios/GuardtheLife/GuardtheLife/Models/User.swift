import Foundation

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let firstName: String
    let lastName: String
    let role: UserRole
    let phoneNumber: String?
    let profileImage: String?
    let isVerified: Bool
    let createdAt: Date
    let updatedAt: Date
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
}

enum UserRole: String, Codable, CaseIterable {
    case client = "client"
    case lifeguard = "lifeguard"
    case admin = "admin"
    
    var displayName: String {
        switch self {
        case .client: return "Client"
        case .lifeguard: return "Lifeguard"
        case .admin: return "Administrator"
        }
    }
}

// MARK: - Authentication
struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct LoginResponse: Codable {
    let user: User
    let token: String
    let refreshToken: String
}

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let firstName: String
    let lastName: String
    let role: UserRole
    let phoneNumber: String?
} 