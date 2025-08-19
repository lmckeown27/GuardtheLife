import SwiftUI
import Stripe
import StripePaymentSheet

struct PaymentSheetExample: View {
    @State private var isPresentingPaymentSheet = false
    @State private var paymentSheet: PaymentSheet?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    // Example booking data
    let booking = Booking(
        id: "booking_123",
        clientId: "client_456",
        client: User(
            id: "client_456",
            email: "client@example.com",
            firstName: "John",
            lastName: "Doe",
            role: .client,
            phoneNumber: nil,
            profileImage: nil,
            isVerified: true,
            createdAt: Date(),
            updatedAt: Date()
        ),
        lifeguardId: "lifeguard_789",
        lifeguard: Lifeguard(
            id: "lifeguard_789",
            firstName: "Jane",
            lastName: "Smith",
            email: "jane@example.com",
            phoneNumber: "+1234567890",
            isVerified: true,
            isAvailable: true,
            rating: 4.8,
            totalBookings: 100,
            specializations: ["pool_supervision"],
            hourlyRate: 75.0,
            profileImageURL: nil,
            location: nil,
            bio: nil,
            certifications: [],
            experience: 3,
            createdAt: Date()
        ),
        serviceType: .poolSupervision,
        status: .pending,
        startTime: Date(),
        endTime: Date().addingTimeInterval(3600),
        duration: 60,
        location: Location(
            latitude: 37.7749,
            longitude: -122.4194,
            address: "Beach Location",
            city: "San Francisco",
            state: "CA",
            country: "USA"
        ),
        specialInstructions: nil,
        totalAmount: 75.00,
        paymentStatus: .pending,
        createdAt: Date(),
        updatedAt: Date()
    )
    
    var body: some View {
        VStack(spacing: 20) {
            // Booking summary
            VStack(alignment: .leading, spacing: 10) {
                Text("Booking Summary")
                    .font(.title2)
                    .fontWeight(.bold)
                
                HStack {
                    Text("Location:")
                    Spacer()
                    Text(booking.location.formattedAddress)
                }
                
                HStack {
                    Text("Duration:")
                    Spacer()
                    Text("1 hour")
                }
                
                HStack {
                    Text("Total:")
                    Spacer()
                    Text("$\(String(format: "%.2f", booking.totalAmount))")
                        .fontWeight(.bold)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            // Payment button
            Button(action: {
                Task {
                    await createPaymentIntent()
                }
            }) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "creditcard.fill")
                    }
                    Text("Pay $\(String(format: "%.2f", booking.totalAmount))")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
            }
            .disabled(isLoading)
            
            // Error message
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Success message
            if let successMessage = successMessage {
                Text(successMessage)
                    .foregroundColor(.green)
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Payment")
        .onAppear {
            // Ensure Stripe is configured
            guard StripeConfig.isConfigured else {
                errorMessage = "Stripe is not properly configured"
                return
            }
        }
    }
    
    // Create payment intent on your backend
    private func createPaymentIntent() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            // Create the request body
            let requestBody: [String: Any] = [
                "amount": booking.totalAmount,
                "bookingId": booking.id,
                "metadata": [
                    "clientId": booking.clientId,
                    "lifeguardId": booking.lifeguardId,
                    "location": booking.location.formattedAddress
                ]
            ]
            
            // Convert to JSON data
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
            
            // Create URL request
            guard let url = URL(string: "http://localhost:3000/api/payments/create-payment-intent") else {
                throw PaymentError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            
            // Make the request
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check response status
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw PaymentError.serverError
            }
            
            // Parse response
            let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            guard let success = responseDict?["success"] as? Bool,
                  success == true,
                  let dataDict = responseDict?["data"] as? [String: Any],
                  let clientSecret = dataDict["clientSecret"] as? String else {
                throw PaymentError.invalidResponse
            }
            
            // Create and present PaymentSheet
            await MainActor.run {
                let configuration = PaymentSheet.Configuration()
                paymentSheet = PaymentSheet(paymentIntentClientSecret: clientSecret, configuration: configuration)
                isPresentingPaymentSheet = true
            }
            
        } catch {
            await MainActor.run {
                errorMessage = "Failed to create payment: \(error.localizedDescription)"
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    // Payment errors - defined inside the struct for proper scope
    enum PaymentError: LocalizedError {
        case invalidURL
        case serverError
        case invalidResponse
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid server URL"
            case .serverError:
                return "Server error occurred"
            case .invalidResponse:
                return "Invalid response from server"
            }
        }
    }
}

// PaymentSheet presentation
extension PaymentSheetExample {
    func presentPaymentSheet() {
        guard let paymentSheet = paymentSheet else { return }
        
        // Get the current window scene for proper presentation
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            paymentSheet.present(from: window.rootViewController ?? UIViewController()) { result in
                switch result {
                case .completed:
                    successMessage = "Payment completed successfully!"
                    errorMessage = nil
                    
                case .canceled:
                    errorMessage = "Payment was cancelled"
                    successMessage = nil
                    
                case .failed(let error):
                    errorMessage = "Payment failed: \(error.localizedDescription)"
                    successMessage = nil
                }
            }
        }
    }
}



// Preview
struct PaymentSheetExample_Previews: PreviewProvider {
    static var previews: some View {
        PaymentSheetExample()
    }
} 
