import Foundation
import Stripe
import StripeApplePay
import StripeCardScan
import StripeConnect
import StripeFinancialConnections
import PassKit
import Combine

// MARK: - Models
struct PaymentTransaction: Identifiable, Codable {
    let id: String
    let amount: Double
    let currency: String
    let status: String
    let timestamp: Date
    let description: String?
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}



// MARK: - Backend Data Models
struct BackendPaymentIntent {
    let paymentIntentId: String
    let clientSecret: String
}

struct BackendPaymentResponse {
    let id: String
    let amount: Int
    let currency: String
    let status: String
}

struct BackendRefundResponse {
    let id: String
    let amount: Double
    let status: String
}

// MARK: - Payment Models
struct PaymentResult {
    let success: Bool
    let transactionId: String
    let amount: Double
    let currency: String
    let status: String
}

struct RefundResult {
    let success: Bool
    let refundId: String
    let amount: Double
    let status: String
}

// MARK: - Payment Errors
enum PaymentError: LocalizedError {
    case paymentFailed
    case paymentCancelled
    case insufficientFunds
    case cardDeclined
    case networkError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .paymentFailed:
            return "Payment processing failed. Please try again."
        case .paymentCancelled:
            return "Payment was cancelled."
        case .insufficientFunds:
            return "Insufficient funds. Please check your account balance."
        case .cardDeclined:
            return "Your card was declined. Please try a different payment method."
        case .networkError:
            return "Network error. Please check your connection and try again."
        case .unknown:
            return "An unknown error occurred. Please try again."
        }
    }
}

class PaymentService: NSObject, ObservableObject, STPAuthenticationContext {
    static let shared = PaymentService()
    
    @Published var isProcessing = false
    @Published var paymentStatus: PaymentStatus = .pending
    @Published var errorMessage: String?
    @Published var lastTransaction: PaymentTransaction?
    
    // Real API service configuration
    private let baseURL = "http://localhost:3000/api"
    private var cancellables = Set<AnyCancellable>()
    
    private override init() {
        super.init()
        setupStripe()
        validateConfiguration()
    }
    
    // MARK: - Configuration Methods
    private func setupStripe() {
        // Configure Stripe with environment-based publishable key
        #if DEBUG
        // Use test key for development
        StripeAPI.defaultPublishableKey = "pk_test_51RxiiPL8qxdTvImxtSLycaHvcSeJhKx3ckurU5eQCvfYqK60zifYgt6ofCIUeysY4FqOBLUzTsPdRAEi1sjxk0jQ00k8qCQ3cu"
        #else
        // Use production key for release builds
        StripeAPI.defaultPublishableKey = "pk_live_your_production_key_here"
        #endif
        
        // Validate Stripe configuration
        guard let publishableKey = StripeAPI.defaultPublishableKey,
              !publishableKey.contains("your_") else {
            fatalError("⚠️ CRITICAL: Replace placeholder Stripe keys with actual keys!")
        }
        
        print("✅ Stripe configured with key: \(String(publishableKey.prefix(20)))...")
    }
    
    private func isApplePayAvailable() -> Bool {
        // Check if device supports Apple Pay
        let isSupported = StripeAPI.deviceSupportsApplePay()
        
        // Additional validation
        if isSupported {
            print("✅ Apple Pay is available on this device")
        } else {
            print("❌ Apple Pay is not available on this device")
        }
        
        return isSupported
    }
    
    private func logPaymentEvent(_ event: String, details: [String: Any] = [:]) {
        let timestamp = Date()
        let logEntry: [String: Any] = [
            "timestamp": timestamp,
            "event": event,
            "details": details
        ]
        
        print("📊 Payment Event: \(event) - \(details)")
        
        // TODO: Send to analytics service (Firebase, Mixpanel, etc.)
        // analyticsService.trackPaymentEvent(event, properties: details)
    }
    
    private func validateConfiguration() {
        // Validate Stripe configuration
        guard let publishableKey = StripeAPI.defaultPublishableKey else {
            print("⚠️ WARNING: Stripe publishable key is not set!")
            return
        }
        
        guard !publishableKey.contains("your_") else {
            print("⚠️ WARNING: Stripe keys not configured - payments will fail!")
            return
        }
        
        // Validate Apple Pay configuration
        if isApplePayAvailable() {
            print("✅ Apple Pay is properly configured")
        } else {
            print("ℹ️ Apple Pay is not available on this device")
        }
        
        // Log configuration status
        #if DEBUG
        let environment = "debug"
        #else
        let environment = "release"
        #endif
        
        logPaymentEvent("configuration_loaded", details: [
            "stripe_configured": !publishableKey.contains("your_"),
            "apple_pay_available": isApplePayAvailable(),
            "environment": environment
        ])
    }
    
    // MARK: - Payment Methods
    // Modern Stripe SDK approach - create payment method using STPPaymentMethodParams
    
    func createPaymentMethod(
        cardNumber: String,
        expiryMonth: Int,
        expiryYear: Int,
        cvc: String
    ) async throws -> STPPaymentMethod {
        
        // Validate input parameters
        guard isValidCardNumber(cardNumber) else {
            throw PaymentError.cardDeclined
        }
        
        guard isValidExpiryDate(month: expiryMonth, year: expiryYear) else {
            throw PaymentError.cardDeclined
        }
        
        guard isValidCVC(cvc) else {
            throw PaymentError.cardDeclined
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            // Create payment method params with card details
            let cardParams = STPPaymentMethodCardParams()
            cardParams.number = cardNumber
            cardParams.expMonth = NSNumber(value: UInt(expiryMonth))
            cardParams.expYear = NSNumber(value: UInt(expiryYear))
            cardParams.cvc = cvc
            
            let paymentMethodParams = STPPaymentMethodParams(
                card: cardParams,
                billingDetails: nil,
                metadata: nil
            )
            
            // Use the modern Stripe API to create payment method
            // Note: This approach may vary based on your specific Stripe SDK version
            // For now, we'll create a mock payment method for testing
            // TODO: Replace with actual Stripe API call when available
            
            // Note: STPPaymentMethod initializer is not accessible due to @_spi protection
            // For now, we'll throw an error indicating this needs proper implementation
            // TODO: Implement using actual Stripe API when available
            continuation.resume(throwing: PaymentError.paymentFailed)
        }
    }
    
    // MARK: - Input Validation
    private func isValidCardNumber(_ cardNumber: String) -> Bool {
        let cleaned = cardNumber.replacingOccurrences(of: " ", with: "")
        return cleaned.count >= 13 && cleaned.count <= 19 && cleaned.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }
    
    private func isValidExpiryDate(month: Int, year: Int) -> Bool {
        let currentDate = Date()
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: currentDate)
        let currentMonth = calendar.component(.month, from: currentDate)
        
        return month >= 1 && month <= 12 && year >= currentYear && (year > currentYear || month >= currentMonth)
    }
    
    private func isValidCVC(_ cvc: String) -> Bool {
        return cvc.count >= 3 && cvc.count <= 4 && cvc.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }
    
    // MARK: - Payment Processing
    // Updated for modern Stripe SDK - payment methods are handled differently
    func processPayment(
        for booking: Booking,
        cardNumber: String,
        expiryMonth: Int,
        expiryYear: Int,
        cvc: String
    ) async throws -> PaymentResult {
        
        self.isProcessing = true
        self.paymentStatus = .processing
        self.errorMessage = nil
        
        do {
            // Validate booking amount
            guard booking.totalAmount > 0 else {
                throw PaymentError.insufficientFunds
            }
            
            // Create payment intent on your backend
            let paymentIntent = try await createPaymentIntentOnBackend(
                bookingId: booking.id,
                amount: booking.totalAmount
            )
            
            // Validate payment intent response
            guard !paymentIntent.paymentIntentId.isEmpty else {
                throw PaymentError.paymentFailed
            }
            
            print("✅ Payment intent created: \(paymentIntent.paymentIntentId)")
            
            // Log payment intent creation
            logPaymentEvent("payment_intent_created", details: [
                "payment_intent_id": paymentIntent.paymentIntentId,
                "amount": booking.totalAmount,
                "booking_id": booking.id
            ])
            
            // Process payment with PaymentSheet (modern Stripe approach)
            let result = try await presentPaymentSheet(
                clientSecret: paymentIntent.clientSecret
            )
            
            // Confirm payment on your backend
            let paymentResponse = try await confirmPaymentOnBackend(
                bookingId: booking.id,
                paymentIntentId: paymentIntent.paymentIntentId
            )
            
            let paymentResult = PaymentResult(
                success: true,
                transactionId: paymentResponse.id,
                amount: Double(paymentResponse.amount) / 100.0,
                currency: paymentResponse.currency,
                status: paymentResponse.status
            )
            
            self.isProcessing = false
            self.paymentStatus = .completed
            self.lastTransaction = PaymentTransaction(
                id: paymentResult.transactionId,
                amount: paymentResult.amount,
                currency: paymentResult.currency,
                status: paymentResult.status,
                timestamp: Date(),
                description: "Payment for booking \(booking.id)"
            )
            
            // Log successful payment
            logPaymentEvent("payment_successful", details: [
                "transaction_id": paymentResult.transactionId,
                "amount": paymentResult.amount,
                "currency": paymentResult.currency,
                "booking_id": booking.id
            ])
            
            return paymentResult
            
        } catch {
            self.isProcessing = false
            self.paymentStatus = .failed
            self.errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // Modern Stripe PaymentSheet approach
    private func presentPaymentSheet(clientSecret: String) async throws -> STPPaymentIntent {
        
        print("🔄 Presenting PaymentSheet with Stripe...")
        
        return try await withCheckedThrowingContinuation { continuation in
            // This should be called from the main thread with a proper view controller
            // For now, we'll throw an error indicating this needs UI integration
            // TODO: Integrate with actual view controller
            continuation.resume(throwing: PaymentError.paymentFailed)
        }
    }
    
    // Legacy method - kept for compatibility but updated for modern Stripe SDK
    private func confirmPayment(
        paymentIntentId: String,
        paymentMethod: STPPaymentMethod
    ) async throws -> STPPaymentIntent {
        
        // Note: This method is kept for compatibility but STPPaymentHandler is deprecated
        // In modern Stripe SDK, use PaymentSheet or direct API calls instead
        // For now, we'll throw an error indicating this needs to be updated
        
        throw PaymentError.paymentFailed
    }
    
    // MARK: - Refunds
    func processRefund(
        for transactionId: String,
        amount: Double? = nil
    ) async throws -> RefundResult {
        
        // Validate transaction ID
        guard !transactionId.isEmpty else {
            throw PaymentError.unknown
        }
        
        // Validate amount if provided
        if let amount = amount, amount <= 0 {
            throw PaymentError.insufficientFunds
        }
        
        self.isProcessing = true
        self.errorMessage = nil
        
        do {
            print("🔄 Processing refund for transaction: \(transactionId)")
            
            // Process refund through your backend
            let refundResponse = try await processRefundOnBackend(
                transactionId: transactionId,
                amount: amount
            )
            
            // Validate refund response
            guard !refundResponse.id.isEmpty else {
                throw PaymentError.unknown
            }
            
            let refundResult = RefundResult(
                success: true,
                refundId: refundResponse.id,
                amount: refundResponse.amount,
                status: refundResponse.status
            )
            
            self.isProcessing = false
            print("✅ Refund processed successfully: \(refundResponse.id)")
            
            return refundResult
            
        } catch {
            self.isProcessing = false
            self.errorMessage = error.localizedDescription
            print("❌ Refund failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Backend Integration
    private func createPaymentIntentOnBackend(bookingId: String, amount: Double) async throws -> BackendPaymentIntent {
        guard let url = URL(string: "\(baseURL)/payments/create-payment-intent") else {
            throw PaymentError.networkError
        }
        
        let requestBody: [String: Any] = [
            "amount": amount,
            "bookingId": bookingId,
            "metadata": [
                "platform": "ios",
                "version": "1.0"
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw PaymentError.networkError
        }
        
        let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let success = responseDict?["success"] as? Bool,
              success == true,
              let dataDict = responseDict?["data"] as? [String: Any],
              let clientSecret = dataDict["clientSecret"] as? String,
              let paymentIntentId = dataDict["paymentIntentId"] as? String else {
            throw PaymentError.paymentFailed
        }
        
        return BackendPaymentIntent(
            paymentIntentId: paymentIntentId,
            clientSecret: clientSecret
        )
    }
    
    private func confirmPaymentOnBackend(bookingId: String, paymentIntentId: String) async throws -> BackendPaymentResponse {
        guard let url = URL(string: "\(baseURL)/payments/confirm-payment") else {
            throw PaymentError.networkError
        }
        
        let requestBody: [String: Any] = [
            "paymentIntentId": paymentIntentId,
            "bookingId": bookingId
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw PaymentError.networkError
        }
        
        let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let success = responseDict?["success"] as? Bool,
              success == true,
              let dataDict = responseDict?["data"] as? [String: Any],
              let paymentIntentId = dataDict["paymentIntentId"] as? String,
              let amount = dataDict["amount"] as? Int,
              let currency = dataDict["currency"] as? String,
              let status = dataDict["status"] as? String else {
            throw PaymentError.paymentFailed
        }
        
        return BackendPaymentResponse(
            id: paymentIntentId,
            amount: amount,
            currency: currency,
            status: status
        )
    }
    
    private func processRefundOnBackend(transactionId: String, amount: Double?) async throws -> BackendRefundResponse {
        guard let url = URL(string: "\(baseURL)/payments/refund") else {
            throw PaymentError.networkError
        }
        
        var requestBody: [String: Any] = [
            "paymentIntentId": transactionId
        ]
        
        if let amount = amount {
            requestBody["amount"] = amount
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw PaymentError.networkError
        }
        
        let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let success = responseDict?["success"] as? Bool,
              success == true,
              let dataDict = responseDict?["data"] as? [String: Any],
              let refundId = dataDict["refundId"] as? String,
              let refundAmount = dataDict["amount"] as? Double,
              let status = dataDict["status"] as? String else {
            throw PaymentError.paymentFailed
        }
        
        return BackendRefundResponse(
            id: refundId,
            amount: refundAmount,
            status: status
        )
    }
    
    // MARK: - Payment History
    func getPaymentHistory() async throws -> [PaymentTransaction] {
        // TODO: Implement real payment history fetching
        return []
    }
    
    // MARK: - Apple Pay
    
    func createApplePayPaymentRequest(for booking: Booking) -> PKPaymentRequest {
        // Validate Apple Pay availability first
        guard isApplePayAvailable() else {
            fatalError("Apple Pay is not available on this device")
        }
        
        let request = PKPaymentRequest()
        
        // Configure merchant identifier (replace with your actual merchant ID)
        #if DEBUG
        request.merchantIdentifier = "merchant.com.guardthelife.app.test"
        #else
        request.merchantIdentifier = "merchant.com.guardthelife.app"
        #endif
        
        // Validate merchant identifier - ensure it's properly formatted
        guard request.merchantIdentifier.hasPrefix("merchant.") else {
            fatalError("⚠️ CRITICAL: Invalid merchant identifier format! Must start with 'merchant.'")
        }
        
        // Configure payment networks and capabilities
        request.supportedNetworks = [.visa, .masterCard, .amex, .discover]
        request.merchantCapabilities = [.threeDSecure, .emv, .credit, .debit]
        
        // Configure locale and currency
        request.countryCode = "US"
        request.currencyCode = "USD"
        
        // Add payment summary items with proper validation
        guard booking.totalAmount > 0 else {
            fatalError("Invalid booking amount for Apple Pay")
        }
        
        let serviceItem = PKPaymentSummaryItem(
            label: "Lifeguard Service",
            amount: NSDecimalNumber(value: booking.totalAmount)
        )
        
        let totalItem = PKPaymentSummaryItem(
            label: "GuardtheLife",
            amount: NSDecimalNumber(value: booking.totalAmount)
        )
        
        request.paymentSummaryItems = [serviceItem, totalItem]
        
        print("✅ Apple Pay request configured for amount: $\(booking.totalAmount)")
        
        return request
    }
    
    // MARK: - Error Handling
    func clearError() {
        errorMessage = nil
    }
    
    // Enhanced error handling with retry logic
    private func handlePaymentError(_ error: Error, retryCount: Int = 0) -> PaymentError {
        let maxRetries = 3
        
        // Check if we should retry
        if retryCount < maxRetries && isRetryableError(error) {
            print("🔄 Retrying payment (attempt \(retryCount + 1)/\(maxRetries))")
            return .networkError // Allow retry
        }
        
        // Map specific errors to user-friendly messages
        // Note: Stripe SDK doesn't expose StripeError enum directly
        // We'll handle errors based on error descriptions instead
        
        // Handle network errors
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet, NSURLErrorTimedOut, NSURLErrorNetworkConnectionLost:
                return .networkError
            default:
                break
            }
        }
        
        // Default to unknown error
        return .unknown
    }
    
    private func isRetryableError(_ error: Error) -> Bool {
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            let retryableCodes: [Int] = [
                NSURLErrorTimedOut,
                NSURLErrorNetworkConnectionLost,
                NSURLErrorCannotConnectToHost
            ]
            return retryableCodes.contains(nsError.code)
        }
        return false
    }
    
    // Note: Stripe SDK doesn't expose StripeError enum directly
    // Error handling is done through error descriptions and NSError codes
    

    
    // MARK: - STPAuthenticationContext Implementation
    func authenticationPresentingViewController() -> UIViewController {
        // This should return the current view controller for authentication
        // For now, we'll return a placeholder - this needs to be properly implemented
        // TODO: Return the actual view controller from the app's navigation stack
        return UIViewController()
    }
    
    // MARK: - Cleanup
    deinit {
        cancellables.removeAll()
        print("🧹 PaymentService deallocated")
    }
}

 
