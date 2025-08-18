import Foundation
import SocketIO
import Combine

class SocketService: ObservableObject {
    static let shared = SocketService()
    
    private var manager: SocketManager?
    private var socket: SocketIOClient?
    
    @Published var isConnected = false
    @Published var connectionStatus = "Disconnected"
    
    // Real-time data streams
    @Published var lifeguardUpdates: [Lifeguard] = []
    @Published var bookingUpdates: [Booking] = []
    @Published var emergencyAlerts: [EmergencyAlert] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupSocket()
    }
    
    // MARK: - Socket Setup
    private func setupSocket() {
        guard let url = URL(string: "http://localhost:3000") else { return }
        
        manager = SocketManager(socketURL: url, config: [
            .log(true),
            .compress,
            .forceNew(true)
        ])
        
        socket = manager?.defaultSocket
        
        setupEventHandlers()
    }
    
    private func setupEventHandlers() {
        guard let socket = socket else { return }
        
        // Connection events
        socket.on(clientEvent: .connect) { [weak self] data, ack in
            DispatchQueue.main.async {
                self?.isConnected = true
                self?.connectionStatus = "Connected"
            }
            print("Socket connected")
        }
        
        socket.on(clientEvent: .disconnect) { [weak self] data, ack in
            DispatchQueue.main.async {
                self?.isConnected = false
                self?.connectionStatus = "Disconnected"
            }
            print("Socket disconnected")
        }
        
        socket.on(clientEvent: .error) { [weak self] data, ack in
            DispatchQueue.main.async {
                self?.isConnected = false
                self?.connectionStatus = "Error"
            }
            print("Socket error: \(data)")
        }
        
        // Custom events
        socket.on("lifeguard_update") { [weak self] data, ack in
            self?.handleLifeguardUpdate(data)
        }
        
        socket.on("booking_update") { [weak self] data, ack in
            self?.handleBookingUpdate(data)
        }
        
        socket.on("emergency_alert") { [weak self] data, ack in
            self?.handleEmergencyAlert(data)
        }
        
        socket.on("location_update") { [weak self] data, ack in
            self?.handleLocationUpdate(data)
        }
        
        socket.on("notification") { [weak self] data, ack in
            self?.handleNotification(data)
        }
    }
    
    // MARK: - Connection Management
    func connect() {
        socket?.connect()
    }
    
    func disconnect() {
        socket?.disconnect()
    }
    
    func connectWithAuth(token: String) {
        socket?.emit("authenticate", ["token": token])
        socket?.connect()
    }
    
    // MARK: - Event Handlers
    private func handleLifeguardUpdate(_ data: [Any]) {
        guard let first = data.first,
              let jsonData = try? JSONSerialization.data(withJSONObject: first),
              let lifeguard = try? JSONDecoder().decode(Lifeguard.self, from: jsonData) else {
            return
        }
        
        DispatchQueue.main.async {
            if let index = self.lifeguardUpdates.firstIndex(where: { $0.id == lifeguard.id }) {
                self.lifeguardUpdates[index] = lifeguard
            } else {
                self.lifeguardUpdates.append(lifeguard)
            }
        }
    }
    
    private func handleBookingUpdate(_ data: [Any]) {
        guard let first = data.first,
              let jsonData = try? JSONSerialization.data(withJSONObject: first),
              let booking = try? JSONDecoder().decode(Booking.self, from: jsonData) else {
            return
        }
        
        DispatchQueue.main.async {
            if let index = self.bookingUpdates.firstIndex(where: { $0.id == booking.id }) {
                self.bookingUpdates[index] = booking
            } else {
                self.bookingUpdates.append(booking)
            }
        }
    }
    
    private func handleEmergencyAlert(_ data: [Any]) {
        guard let first = data.first,
              let jsonData = try? JSONSerialization.data(withJSONObject: first),
              let alert = try? JSONDecoder().decode(EmergencyAlert.self, from: jsonData) else {
            return
        }
        
        DispatchQueue.main.async {
            self.emergencyAlerts.append(alert)
        }
    }
    
    private func handleLocationUpdate(_ data: [Any]) {
        // Handle location updates from other users
        print("Location update received: \(data)")
    }
    
    private func handleNotification(_ data: [Any]) {
        // Handle general notifications
        print("Notification received: \(data)")
    }
    
    // MARK: - Emit Events
    func emitLocationUpdate(latitude: Double, longitude: Double) {
        let locationData: [String: Any] = [
            "latitude": latitude,
            "longitude": longitude,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        socket?.emit("location_update", locationData)
    }
    
    func emitBookingRequest(booking: CreateBookingRequest) {
        let bookingData: [String: Any] = [
            "lifeguardId": booking.lifeguardId,
            "serviceType": booking.serviceType.rawValue,
            "startTime": booking.startTime.timeIntervalSince1970,
            "endTime": booking.endTime.timeIntervalSince1970,
            "location": [
                "latitude": booking.location.latitude,
                "longitude": booking.location.longitude
            ]
        ]
        
        socket?.emit("booking_request", bookingData)
    }
    
    func emitEmergencySignal(location: Location, description: String) {
        let emergencyData: [String: Any] = [
            "location": [
                "latitude": location.latitude,
                "longitude": location.longitude
            ],
            "description": description,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        socket?.emit("emergency_signal", emergencyData)
    }
    
    func emitTypingIndicator(conversationId: String, isTyping: Bool) {
        let typingData: [String: Any] = [
            "conversationId": conversationId,
            "isTyping": isTyping
        ]
        
        socket?.emit("typing_indicator", typingData)
    }
    
    // MARK: - Room Management
    func joinRoom(_ roomId: String) {
        socket?.emit("join_room", roomId)
    }
    
    func leaveRoom(_ roomId: String) {
        socket?.emit("leave_room", roomId)
    }
    
    // MARK: - Cleanup
    deinit {
        disconnect()
        cancellables.removeAll()
    }
}

// MARK: - Emergency Alert Model
struct EmergencyAlert: Codable, Identifiable {
    let id: String
    let type: EmergencyType
    let location: Location
    let description: String
    let severity: EmergencySeverity
    let timestamp: Date
    let isActive: Bool
}

enum EmergencyType: String, Codable {
    case medical = "medical"
    case drowning = "drowning"
    case injury = "injury"
    case weather = "weather"
    case other = "other"
}

enum EmergencySeverity: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
    
    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "yellow"
        case .high: return "orange"
        case .critical: return "red"
        }
    }
} 