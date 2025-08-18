import Foundation

struct Booking: Codable, Identifiable {
    let id: String
    let clientId: String
    let client: User
    let lifeguardId: String
    let lifeguard: Lifeguard
    let serviceType: ServiceType
    let status: BookingStatus
    let startTime: Date
    let endTime: Date
    let duration: Int // minutes
    let location: Location
    let specialInstructions: String?
    let totalAmount: Double
    let paymentStatus: PaymentStatus
    let createdAt: Date
    let updatedAt: Date
    
    var isActive: Bool {
        status == .confirmed || status == .inProgress
    }
    
    var formattedDuration: String {
        let hours = duration / 60
        let minutes = duration % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
    }
}

enum ServiceType: String, Codable, CaseIterable {
    case poolSupervision = "pool_supervision"
    case beachPatrol = "beach_patrol"
    case eventSecurity = "event_security"
    case emergencyResponse = "emergency_response"
    case training = "training"
    case consultation = "consultation"
    
    var displayName: String {
        switch self {
        case .poolSupervision: return "Pool Supervision"
        case .beachPatrol: return "Beach Patrol"
        case .eventSecurity: return "Event Security"
        case .emergencyResponse: return "Emergency Response"
        case .training: return "Training"
        case .consultation: return "Consultation"
        }
    }
    
    var icon: String {
        switch self {
        case .poolSupervision: return "drop.fill"
        case .beachPatrol: return "beach.umbrella.fill"
        case .eventSecurity: return "person.3.fill"
        case .emergencyResponse: return "exclamationmark.triangle.fill"
        case .training: return "book.fill"
        case .consultation: return "message.fill"
        }
    }
}

enum BookingStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case confirmed = "confirmed"
    case inProgress = "in_progress"
    case completed = "completed"
    case cancelled = "cancelled"
    case rejected = "rejected"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .confirmed: return "Confirmed"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        case .rejected: return "Rejected"
        }
    }
    
    var color: String {
        switch self {
        case .pending: return "orange"
        case .confirmed: return "blue"
        case .inProgress: return "green"
        case .completed: return "gray"
        case .cancelled: return "red"
        case .rejected: return "red"
        }
    }
}

enum PaymentStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
    case refunded = "refunded"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .processing: return "Processing"
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .refunded: return "Refunded"
        }
    }
} 