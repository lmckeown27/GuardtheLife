import Foundation
import UIKit
import UserNotifications
import FirebaseMessaging
import Combine

@MainActor
class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()
    
    @Published var isAuthorized = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var fcmToken: String?
    @Published var notifications: [AppNotification] = []
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private var cancellables = Set<AnyCancellable>()
    
    private override init() {
        super.init()
        setupNotificationCenter()
        setupFirebaseMessaging()
    }
    
    // MARK: - Setup
    private func setupNotificationCenter() {
        notificationCenter.delegate = self
        
        // Check current authorization status
        notificationCenter.getNotificationSettings { [weak self] settings in
            Task { @MainActor in
                self?.authorizationStatus = settings.authorizationStatus
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    private func setupFirebaseMessaging() {
        Messaging.messaging().delegate = self
        
        // Get FCM token
        Messaging.messaging().token { [weak self] token, error in
            if let error = error {
                print("Error fetching FCM token: \(error)")
            } else if let token = token {
                Task { @MainActor in
                    self?.fcmToken = token
                }
                self?.sendTokenToServer(token)
            }
        }
    }
    
    // MARK: - Permission Request
    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .badge, .sound, .provisional]
            )
            
            self.isAuthorized = granted
            
            return granted
        } catch {
            print("Error requesting notification permission: \(error)")
            return false
        }
    }
    
    // MARK: - Local Notifications
    func scheduleLocalNotification(
        title: String,
        body: String,
        identifier: String,
        timeInterval: TimeInterval = 0,
        repeats: Bool = false,
        userInfo: [String: Any] = [:]
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = userInfo
        content.categoryIdentifier = "GENERAL"
        
        let trigger: UNNotificationTrigger
        
        if timeInterval > 0 {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: repeats)
        } else {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        }
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    func scheduleEmergencyNotification(
        type: EmergencyType,
        location: Location,
        description: String
    ) {
        let content = UNMutableNotificationContent()
        content.title = "Emergency Alert"
        content.body = "\(type.displayName): \(description)"
        content.sound = .defaultCritical
        content.userInfo = [
            "type": "emergency",
            "emergencyType": type.rawValue,
            "latitude": location.latitude,
            "longitude": location.longitude
        ]
        content.categoryIdentifier = "EMERGENCY"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "emergency_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling emergency notification: \(error)")
            }
        }
    }
    
    func scheduleBookingNotification(
        booking: Booking,
        type: BookingNotificationType
    ) {
        let content = UNMutableNotificationContent()
        
        switch type {
        case .confirmed:
            content.title = "Booking Confirmed"
            content.body = "Your lifeguard service with \(booking.lifeguard.displayName) has been confirmed"
        case .reminder:
            content.title = "Service Reminder"
            content.body = "Your lifeguard service starts in 1 hour"
        case .completed:
            content.title = "Service Completed"
            content.body = "Your lifeguard service has been completed. Please rate your experience."
        case .cancelled:
            content.title = "Booking Cancelled"
            content.body = "Your lifeguard service has been cancelled"
        }
        
        content.sound = .default
        content.userInfo = [
            "type": "booking",
            "bookingId": booking.id,
            "notificationType": type.rawValue
        ]
        content.categoryIdentifier = "BOOKING"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "booking_\(booking.id)_\(type.rawValue)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling booking notification: \(error)")
            }
        }
    }
    
    // MARK: - Notification Categories
    func setupNotificationCategories() {
        let generalCategory = UNNotificationCategory(
            identifier: "GENERAL",
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        
        let emergencyCategory = UNNotificationCategory(
            identifier: "EMERGENCY",
            actions: [
                UNNotificationAction(
                    identifier: "VIEW_EMERGENCY",
                    title: "View Details",
                    options: [.foreground]
                ),
                UNNotificationAction(
                    identifier: "CALL_911",
                    title: "Call 911",
                    options: [.foreground]
                )
            ],
            intentIdentifiers: [],
            options: []
        )
        
        let bookingCategory = UNNotificationCategory(
            identifier: "BOOKING",
            actions: [
                UNNotificationAction(
                    identifier: "VIEW_BOOKING",
                    title: "View Booking",
                    options: [.foreground]
                ),
                UNNotificationAction(
                    identifier: "RATE_SERVICE",
                    title: "Rate Service",
                    options: [.foreground]
                )
            ],
            intentIdentifiers: [],
            options: []
        )
        
        notificationCenter.setNotificationCategories([
            generalCategory,
            emergencyCategory,
            bookingCategory
        ])
    }
    
    // MARK: - FCM Token Management
    private func sendTokenToServer(_ token: String) {
        // Send FCM token to your backend
        guard let user = AuthService.shared.currentUser else { return }
        
        Task {
            do {
                try await APIService.shared.updateFCMToken(token: token)
                print("FCM token sent to server successfully")
            } catch {
                print("Failed to send FCM token to server: \(error)")
            }
        }
    }
    
    // MARK: - Notification Management
    func removeAllPendingNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    func removeNotification(withIdentifier identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [identifier])
    }
    
    func getDeliveredNotifications() {
        notificationCenter.getDeliveredNotifications { [weak self] notifications in
            let appNotifications = notifications.map { notification in
                AppNotification(
                    id: notification.request.identifier,
                    title: notification.request.content.title,
                    body: notification.request.content.body,
                    timestamp: notification.date,
                    userInfo: notification.request.content.userInfo
                )
            }
            
            DispatchQueue.main.async {
                self?.notifications = appNotifications
            }
        }
    }
    
    // MARK: - Badge Management
    func setBadgeCount(_ count: Int) {
        UNUserNotificationCenter.current().setBadgeCount(count) { error in
            if let error = error {
                print("Error setting badge count: \(error)")
            }
        }
    }
    
    func clearBadge() {
        setBadgeCount(0)
    }
    
    // MARK: - Cleanup
    deinit {
        cancellables.removeAll()
    }
    
    // MARK: - Notification Handlers
    private func handleEmergencyNotification(_ userInfo: [AnyHashable: Any]) {
        // Navigate to emergency details
        print("Handling emergency notification: \(userInfo)")
    }
    
    private func callEmergencyServices() {
        // Call 911 or emergency services
        if let url = URL(string: "tel://911") {
            UIApplication.shared.open(url)
        }
    }
    
    private func handleBookingNotification(_ userInfo: [AnyHashable: Any]) {
        // Navigate to booking details
        print("Handling booking notification: \(userInfo)")
    }
    
    private func handleRateServiceNotification(_ userInfo: [AnyHashable: Any]) {
        // Navigate to rating screen
        print("Handling rate service notification: \(userInfo)")
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        // Handle notification actions
        Task { @MainActor in
            switch response.actionIdentifier {
            case "VIEW_EMERGENCY":
                self.handleEmergencyNotification(userInfo)
            case "CALL_911":
                self.callEmergencyServices()
            case "VIEW_BOOKING":
                self.handleBookingNotification(userInfo)
            case "RATE_SERVICE":
                self.handleRateServiceNotification(userInfo)
            default:
                break
            }
        }
        
        completionHandler()
    }
}

// MARK: - MessagingDelegate
extension NotificationService: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        
        DispatchQueue.main.async {
            self.fcmToken = token
        }
        
        sendTokenToServer(token)
    }
}

// MARK: - Models
struct AppNotification: Identifiable {
    let id: String
    let title: String
    let body: String
    let timestamp: Date
    let userInfo: [AnyHashable: Any]
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .short
        return formatter.string(from: timestamp)
    }
}

enum BookingNotificationType: String, CaseIterable {
    case confirmed = "confirmed"
    case reminder = "reminder"
    case completed = "completed"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .confirmed: return "Confirmed"
        case .reminder: return "Reminder"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }
} 