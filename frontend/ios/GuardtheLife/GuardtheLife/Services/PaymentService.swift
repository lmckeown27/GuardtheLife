import Foundation
import Stripe
import Combine

class PaymentService: NSObject, ObservableObject {
    static let shared = PaymentService()
    
    @Published var isProcessing = false
    @Published var paymentStatus: PaymentStatus = .pending
    @Published var errorMessage: String?
    @Published var lastTransaction: PaymentTransaction?
    
    private let apiService = APIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private override init() {
        super.init()
        setupStripe()
    }
    
    // MARK: - Stripe Setup
    private func setupStripe() {
        // Configure Stripe with your publishable key
        StripeAPI.defaultPublishableKey = "pk_test_your_publishable_key_here"
        
        // Set up payment configuration
        let configuration = STPPaymentConfiguration.shared
        configuration.requiredBillingAddressFields = .postalCode
        configuration.requiredShippingAddressFields = .postalCode
        configuration.shippingType = .delivery
    }
    
    // MARK: - Payment Methods
    func createPaymentMethod(
        cardNumber: String,
        expiryMonth: Int,
        expiryYear: Int,
        cvc: String
    ) async throws -> STPPaymentMethod {
        
        let cardParams = STPCardParams()
        cardParams.number = cardNumber
        cardParams.expMonth = UInt(expiryMonth)
        cardParams.expYear = UInt(expiryYear)
        cardParams.cvc = cvc
        
        return try await withCheckedThrowingContinuation { continuation in
            STPPaymentMethod.create(with: cardParams) { paymentMethod, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let paymentMethod = paymentMethod {
                    continuation.resume(returning: paymentMethod)
                } else {
                    continuation.resume(throwing: PaymentError.unknown)
                }
            }
        }
    }
    
    // MARK: - Payment Processing
    func processPayment(
        for booking: Booking,
        paymentMethod: STPPaymentMethod
    ) async throws -> PaymentResult {
        
        DispatchQueue.main.async {
            self.isProcessing = true
            self.paymentStatus = .processing
            self.errorMessage = nil
        }
        
        do {
            // Create payment intent on your backend
            let amountInCents = Int(booking.totalAmount * 100) // Convert to cents
            let paymentIntent = try await apiService.createPaymentIntent(
                bookingId: booking.id,
                amount: amountInCents
            )
            
            // Confirm the payment with Stripe
            let result = try await confirmPayment(
                paymentIntentId: paymentIntent.paymentIntentId,
                paymentMethod: paymentMethod
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
            
            DispatchQueue.main.async {
                self.isProcessing = false
                self.paymentStatus = .completed
                self.lastTransaction = PaymentTransaction(
                    id: paymentResult.transactionId,
                    amount: paymentResult.amount,
                    currency: paymentResult.currency,
                    status: paymentResult.status,
                    timestamp: Date()
                )
            }
            
            return paymentResult
            
        } catch {
            DispatchQueue.main.async {
                self.isProcessing = false
                self.paymentStatus = .failed
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
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
        
        DispatchQueue.main.async {
            self.isProcessing = true
        }
        
        do {
            // Process refund through your backend
            let refundResponse = try await apiService.processRefund(
                transactionId: transactionId,
                amount: amount
            )
            
            let refundResult = RefundResult(
                success: true,
                refundId: refundResponse.id,
                amount: refundResponse.amount,
                status: refundResponse.status
            )
            
            DispatchQueue.main.async {
                self.isProcessing = false
            }
            
            return refundResult
            
        } catch {
            DispatchQueue.main.async {
                self.isProcessing = false
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    // MARK: - Payment History
    func getPaymentHistory() async throws -> [PaymentTransaction] {
        return try await apiService.getPaymentHistory()
    }
    
    // MARK: - Apple Pay
    func isApplePayAvailable() -> Bool {
        return StripeAPI.deviceSupportsApplePay()
    }
    
    func createApplePayPaymentRequest(for booking: Booking) -> PKPaymentRequest {
        let request = PKPaymentRequest()
        request.merchantIdentifier = "merchant.com.guardthelife.app"
        request.supportedNetworks = [.visa, .masterCard, .amex]
        request.merchantCapabilities = .capability3DS
        request.countryCode = "US"
        request.currencyCode = "USD"
        
        // Add payment summary items
        let serviceItem = PKPaymentSummaryItem(
            label: "Lifeguard Service",
            amount: NSDecimalNumber(value: booking.totalAmount)
        )
        
        let totalItem = PKPaymentSummaryItem(
            label: "GuardtheLife",
            amount: NSDecimalNumber(value: booking.totalAmount)
        )
        
        request.paymentSummaryItems = [serviceItem, totalItem]
        
        return request
    }
    
    // MARK: - Error Handling
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Cleanup
    deinit {
        cancellables.removeAll()
    }
}

// MARK: - STPPaymentHandlerDelegate
extension PaymentService: STPPaymentHandlerDelegate {
    func paymentHandler(_ paymentHandler: STPPaymentHandler, didConfirmPaymentWithResult paymentResult: STPPaymentIntent, error: Error) {
        // This is handled in the async/await wrapper
    }
    
    func paymentHandler(_ paymentHandler: STPPaymentHandler, didFinishWithResult result: STPPaymentHandlerResult, error: Error) {
        // This is handled in the async/await wrapper
    }
}

// MARK: - Models
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