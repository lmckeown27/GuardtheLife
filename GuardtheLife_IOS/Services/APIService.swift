import Foundation
import Alamofire
import SwiftyJSON

class APIService: ObservableObject {
    static let shared = APIService()
    
    private let baseURL = "http://localhost:3000/api/v1"
    private var authToken: String?
    
    private init() {}
    
    // MARK: - Authentication
    func setAuthToken(_ token: String) {
        self.authToken = token
    }
    
    func clearAuthToken() {
        self.authToken = nil
    }
    
    private var headers: HTTPHeaders {
        var headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        
        if let token = authToken {
            headers["Authorization"] = "Bearer \(token)"
        }
        
        return headers
    }
    
    // MARK: - Generic Request Method
    private func request<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        responseType: T.Type
    ) async throws -> T {
        
        let url = "\(baseURL)\(endpoint)"
        
        return try await withCheckedThrowingContinuation { continuation in
            AF.request(url, method: method, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
                .validate()
                .responseDecodable(of: T.self) { response in
                    switch response.result {
                    case .success(let value):
                        continuation.resume(returning: value)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
        }
    }
    
    // MARK: - User Authentication
    func login(email: String, password: String) async throws -> LoginResponse {
        let parameters: Parameters = [
            "email": email,
            "password": password
        ]
        
        return try await request(
            endpoint: "/auth/login",
            method: .post,
            parameters: parameters,
            responseType: LoginResponse.self
        )
    }
    
    func register(registerData: RegisterRequest) async throws -> LoginResponse {
        let parameters: Parameters = [
            "email": registerData.email,
            "password": registerData.password,
            "firstName": registerData.firstName,
            "lastName": registerData.lastName,
            "role": registerData.role.rawValue,
            "phoneNumber": registerData.phoneNumber ?? ""
        ]
        
        return try await request(
            endpoint: "/auth/register",
            method: .post,
            parameters: parameters,
            responseType: LoginResponse.self
        )
    }
    
    func getCurrentUser() async throws -> User {
        return try await request(
            endpoint: "/auth/me",
            responseType: User.self
        )
    }
    
    // MARK: - Lifeguards
    func getLifeguards(latitude: Double? = nil, longitude: Double? = nil, radius: Double? = nil) async throws -> [Lifeguard] {
        var endpoint = "/lifeguards"
        var parameters: Parameters = [:]
        
        if let lat = latitude, let lon = longitude {
            parameters["latitude"] = lat
            parameters["longitude"] = lon
            if let rad = radius {
                parameters["radius"] = rad
            }
        }
        
        return try await request(
            endpoint: endpoint,
            parameters: parameters.isEmpty ? nil : parameters,
            responseType: [Lifeguard].self
        )
    }
    
    func getLifeguard(id: String) async throws -> Lifeguard {
        return try await request(
            endpoint: "/lifeguards/\(id)",
            responseType: Lifeguard.self
        )
    }
    
    func updateLifeguardAvailability(isAvailable: Bool) async throws -> Lifeguard {
        let parameters: Parameters = [
            "isAvailable": isAvailable
        ]
        
        return try await request(
            endpoint: "/lifeguards/availability",
            method: .patch,
            parameters: parameters,
            responseType: Lifeguard.self
        )
    }
    
    func updateLifeguardLocation(latitude: Double, longitude: Double) async throws -> Lifeguard {
        let parameters: Parameters = [
            "latitude": latitude,
            "longitude": longitude
        ]
        
        return try await request(
            endpoint: "/lifeguards/location",
            method: .patch,
            parameters: parameters,
            responseType: Lifeguard.self
        )
    }
    
    // MARK: - Bookings
    func createBooking(bookingData: CreateBookingRequest) async throws -> Booking {
        let parameters: Parameters = [
            "lifeguardId": bookingData.lifeguardId,
            "serviceType": bookingData.serviceType.rawValue,
            "startTime": ISO8601DateFormatter().string(from: bookingData.startTime),
            "endTime": ISO8601DateFormatter().string(from: bookingData.endTime),
            "location": [
                "latitude": bookingData.location.latitude,
                "longitude": bookingData.location.longitude,
                "address": bookingData.location.address ?? ""
            ],
            "specialInstructions": bookingData.specialInstructions ?? ""
        ]
        
        return try await request(
            endpoint: "/bookings",
            method: .post,
            parameters: parameters,
            responseType: Booking.self
        )
    }
    
    func getBookings(status: BookingStatus? = nil) async throws -> [Booking] {
        var endpoint = "/bookings"
        var parameters: Parameters = [:]
        
        if let status = status {
            parameters["status"] = status.rawValue
        }
        
        return try await request(
            endpoint: endpoint,
            parameters: parameters.isEmpty ? nil : parameters,
            responseType: [Booking].self
        )
    }
    
    func getBooking(id: String) async throws -> Booking {
        return try await request(
            endpoint: "/bookings/\(id)",
            responseType: Booking.self
        )
    }
    
    func updateBookingStatus(id: String, status: BookingStatus) async throws -> Booking {
        let parameters: Parameters = [
            "status": status.rawValue
        ]
        
        return try await request(
            endpoint: "/bookings/\(id)/status",
            method: .patch,
            parameters: parameters,
            responseType: Booking.self
        )
    }
    
    // MARK: - Payments
    func createPaymentIntent(bookingId: String, amount: Int) async throws -> PaymentIntentResponse {
        let parameters: Parameters = [
            "bookingId": bookingId,
            "amount": amount
        ]
        
        return try await request(
            endpoint: "/payments/create-intent",
            method: .post,
            parameters: parameters,
            responseType: PaymentIntentResponse.self
        )
    }
    
    func confirmPayment(bookingId: String, paymentIntentId: String) async throws -> PaymentResponse {
        let parameters: Parameters = [
            "paymentIntentId": paymentIntentId
        ]
        
        return try await request(
            endpoint: "/payments/\(bookingId)/confirm",
            method: .post,
            parameters: parameters,
            responseType: PaymentResponse.self
        )
    }
    
    // MARK: - FCM Token Management
    func updateFCMToken(token: String) async throws {
        let parameters: Parameters = [
            "fcmToken": token
        ]
        
        _ = try await request(
            endpoint: "/users/fcm-token",
            method: .post,
            parameters: parameters,
            responseType: EmptyResponse.self
        )
    }
}

// MARK: - Request/Response Models
struct CreateBookingRequest {
    let lifeguardId: String
    let serviceType: ServiceType
    let startTime: Date
    let endTime: Date
    let location: Location
    let specialInstructions: String?
}

struct PaymentIntentResponse: Codable {
    let clientSecret: String
    let paymentIntentId: String
}

struct PaymentResponse: Codable {
    let id: String
    let status: String
    let amount: Int
    let currency: String
}

struct EmptyResponse: Codable {
    // Empty response for endpoints that don't return data
} 