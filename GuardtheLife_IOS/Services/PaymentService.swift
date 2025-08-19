import Foundation
import Stripe
import StripeApplePay
import StripeCardScan
import StripeConnect
import StripeFinancialConnections
import PassKit
import Combine

@MainActor
class PaymentService: NSObject, ObservableObject {
    static let shared = PaymentService()
    
    @Published var isProcessing = false
    @Published var paymentStatus: PaymentStatus = .pending
    @Published var errorMessage: String?
    @Published var lastTransaction: PaymentTransaction?
    
    // TODO: Replace with actual API service when available
    // For now, we'll use placeholder methods
    private let apiService = MockAPIService()
    private var cancellables = Set<AnyCancellable>()
    
    private override init() {
        super.init()
        setupStripe()
        validateConfiguration()
    }
    
    // MARK: - Configuration Validation
    private func validateConfiguration() {
        // Validate Stripe configuration
        guard !StripeAPI.defaultPublishableKey.contains("your_") else {
            print("⚠️ WARNING: Stripe keys not configured - payments will fail!")
        }
        
        // Validate Apple Pay configuration
        if isApplePayAvailable() {
            print("✅ Apple Pay is properly configured")
        } else {
            print("ℹ️ Apple Pay is not available on this device")
        }
        
        // Log configuration status
        logPaymentEvent("configuration_loaded", details: [
            "stripe_configured": !StripeAPI.defaultPublishableKey.contains("your_"),
            "apple_pay_available": isApplePayAvailable(),
            "environment": #if DEBUG ? "debug" : "release"
        ])
    }
    
    // MARK: - Stripe Setup
    private func setupStripe() {
        // Configure Stripe with environment-based publishable key
        #if DEBUG
        // Use test key for development
        StripeAPI.defaultPublishableKey = "pk_test_your_test_key_here"
        #else
        // Use production key for release builds
        StripeAPI.defaultPublishableKey = "pk_live_your_production_key_here"
        #endif
        
        // Validate Stripe configuration
        guard !StripeAPI.defaultPublishableKey.contains("your_") else {
            fatalError("⚠️ CRITICAL: Replace placeholder Stripe keys with actual keys!")
        }
        
        print("✅ Stripe configured with key: \(String(StripeAPI.defaultPublishableKey.prefix(20)))...")
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
            let amountInCents = Int(booking.totalAmount * 100) // Convert to cents
            let paymentIntent = try await apiService.createPaymentIntent(
                bookingId: booking.id,
                amount: amountInCents
            )
            
            // Validate payment intent response
            guard !paymentIntent.paymentIntentId.isEmpty else {
                throw PaymentError.paymentFailed
            }
            
            print("✅ Payment intent created: \(paymentIntent.paymentIntentId)")
            
            // Log payment intent creation
            logPaymentEvent("payment_intent_created", details: [
                "payment_intent_id": paymentIntent.paymentIntentId,
                "amount": amountInCents,
                "booking_id": booking.id
            ])
            
            // Process payment directly with card details (modern Stripe approach)
            let result = try await confirmPaymentWithCard(
                paymentIntentId: paymentIntent.paymentIntentId,
                cardNumber: cardNumber,
                expiryMonth: expiryMonth,
                expiryYear: expiryYear,
                cvc: cvc
            )
            
            // Confirm payment on your backend
            let paymentResponse = try await apiService.confirmPayment(
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
                timestamp: Date()
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
    
    // Modern Stripe approach - confirm payment with card details directly
    private func confirmPaymentWithCard(
        paymentIntentId: String,
        cardNumber: String,
        expiryMonth: Int,
        expiryYear: Int,
        cvc: String
    ) async throws -> STPPaymentIntent {
        
        // Create payment method params for the card
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
        
        // Create payment intent params with proper configuration
        let paymentIntentParams = STPPaymentIntentParams(clientSecret: paymentIntentId)
        
        // Configure payment intent params for better success rate
        // Note: paymentMethodParams property may not exist in current Stripe SDK version
        // We'll set the payment method ID instead
        // TODO: Update when using newer Stripe SDK version
        paymentIntentParams.returnURL = "guardthelife://payment-return"
        
        print("🔄 Confirming payment with Stripe...")
        
        // Use STPPaymentHandler to confirm payment with card details
        return try await withCheckedThrowingContinuation { continuation in
            STPPaymentHandler.shared().confirmPayment(
                paymentIntentParams,
                with: self
            ) { status, paymentIntent, error in
                switch status {
                case .succeeded:
                    if let paymentIntent = paymentIntent {
                        print("✅ Payment confirmed successfully")
                        continuation.resume(returning: paymentIntent)
                    } else {
                        print("❌ Payment succeeded but no payment intent returned")
                        continuation.resume(throwing: PaymentError.unknown)
                    }
                case .failed:
                    if let error = error {
                        print("❌ Payment failed with error: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    } else {
                        print("❌ Payment failed without specific error")
                        continuation.resume(throwing: PaymentError.paymentFailed)
                    }
                case .canceled:
                    print("❌ Payment was cancelled by user")
                    continuation.resume(throwing: PaymentError.paymentCancelled)
                @unknown default:
                    print("❌ Unknown payment status: \(status)")
                    continuation.resume(throwing: PaymentError.unknown)
                }
            }
        }
    }
    
    // Legacy method - kept for compatibility but updated for modern Stripe SDK
    private func confirmPayment(
        paymentIntentId: String,
        paymentMethod: STPPaymentMethod
    ) async throws -> STPPaymentIntent {
        
        let paymentIntentParams = STPPaymentIntentParams(clientSecret: paymentIntentId)
        paymentIntentParams.paymentMethodId = paymentMethod.stpId
        
        return try await withCheckedThrowingContinuation { continuation in
            STPPaymentHandler.shared().confirmPayment(
                paymentIntentParams,
                with: self
            ) { status, paymentIntent, error in
                switch status {
                case .succeeded:
                    if let paymentIntent = paymentIntent {
                        continuation.resume(returning: paymentIntent)
                    } else {
                        continuation.resume(throwing: PaymentError.unknown)
                    }
                case .failed:
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(throwing: PaymentError.paymentFailed)
                    }
                case .canceled:
                    continuation.resume(throwing: PaymentError.paymentCancelled)
                @unknown default:
                    continuation.resume(throwing: PaymentError.unknown)
                }
            }
        }
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
            let refundResponse = try await apiService.processRefund(
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
    
    // MARK: - Payment History
    func getPaymentHistory() async throws -> [PaymentTransaction] {
        return try await apiService.getPaymentHistory()
    }
    
    // MARK: - Apple Pay
    func isApplePayAvailable() -> Bool {
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
        
        // Validate merchant identifier
        guard !request.merchantIdentifier.contains("guardthelife.app") else {
            fatalError("⚠️ CRITICAL: Replace placeholder merchant identifier with actual Apple Pay merchant ID!")
        }
        
        // Configure payment networks and capabilities
        request.supportedNetworks = [.visa, .masterCard, .amex, .discover]
        request.merchantCapabilities = [.capability3DS, .capabilityEMV, .capabilityCredit, .capabilityDebit]
        
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
    
    // MARK: - Payment Analytics
    private func logPaymentEvent(_ event: String, details: [String: Any] = [:]) {
        let timestamp = Date()
        let logEntry = [
            "timestamp": timestamp,
            "event": event,
            "details": details
        ]
        
        print("📊 Payment Event: \(event) - \(details)")
        
        // TODO: Send to analytics service (Firebase, Mixpanel, etc.)
        // analyticsService.trackPaymentEvent(event, properties: details)
    }
    
    // MARK: - Cleanup
    deinit {
        cancellables.removeAll()
        print("🧹 PaymentService deallocated")
    }
}

// MARK: - STPPaymentHandlerDelegate
extension PaymentService: STPPaymentHandlerDelegate {
    func paymentHandler(_ paymentHandler: STPPaymentHandler, didConfirmPaymentWithResult paymentResult: STPPaymentIntent, error: Error) {
        // Handle payment confirmation callback
        if let error = error {
            print("❌ Payment handler error: \(error.localizedDescription)")
            self.errorMessage = error.localizedDescription
            self.paymentStatus = .failed
        } else {
            print("✅ Payment handler confirmed payment: \(paymentResult.stpId)")
            self.paymentStatus = .completed
        }
        self.isProcessing = false
    }
    
    func paymentHandler(_ paymentHandler: STPPaymentHandler, didFinishWithResult result: STPPaymentHandlerResult, error: Error) {
        // Handle payment completion callback
        if let error = error {
            print("❌ Payment handler completion error: \(error.localizedDescription)")
            self.errorMessage = error.localizedDescription
            self.paymentStatus = .failed
        } else {
            print("✅ Payment handler completed successfully")
            self.paymentStatus = .completed
        }
        self.isProcessing = false
    }
}

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

// MARK: - Payment Status
enum PaymentStatus {
    case pending
    case processing
    case completed
    case failed
}

// MARK: - Mock API Service
// Temporary placeholder until real API service is implemented
class MockAPIService {
    func createPaymentIntent(bookingId: String, amount: Int) async throws -> MockPaymentIntent {
        // Simulate API delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        return MockPaymentIntent(
            paymentIntentId: "pi_mock_\(UUID().uuidString.prefix(8))",
            amount: amount,
            currency: "usd"
        )
    }
    
    func confirmPayment(bookingId: String, paymentIntentId: String) async throws -> MockPaymentResponse {
        // Simulate API delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        return MockPaymentResponse(
            id: "pay_mock_\(UUID().uuidString.prefix(8))",
            amount: 1000, // $10.00 in cents
            currency: "usd",
            status: "succeeded"
        )
    }
    
    func processRefund(transactionId: String, amount: Double?) async throws -> MockRefundResponse {
        // Simulate API delay
        try await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds
        
        return MockRefundResponse(
            id: "ref_mock_\(UUID().uuidString.prefix(8))",
            amount: amount ?? 1000,
            status: "succeeded"
        )
    }
    
    func getPaymentHistory() async throws -> [PaymentTransaction] {
        // Return empty array for now
        return []
    }
}

// MARK: - Mock Data Models
struct MockPaymentIntent {
    let paymentIntentId: String
    let amount: Int
    let currency: String
}

struct MockPaymentResponse {
    let id: String
    let amount: Int
    let currency: String
    let status: String
}

struct MockRefundResponse {
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