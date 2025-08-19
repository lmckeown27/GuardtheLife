import SwiftUI
import Stripe

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
        lifeguardId: "lifeguard_789",
        startTime: Date(),
        endTime: Date().addingTimeInterval(3600),
        location: "Beach Location",
        totalAmount: 75.00,
        status: "pending"
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
                    Text(booking.location)
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
                    "location": booking.location
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
                paymentSheet = PaymentSheet(paymentIntentClientSecret: clientSecret)
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
}

// PaymentSheet presentation
extension PaymentSheetExample {
    func presentPaymentSheet() {
        guard let paymentSheet = paymentSheet else { return }
        
        paymentSheet.present(from: UIApplication.shared.windows.first?.rootViewController ?? UIViewController()) { result in
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

// Payment errors
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

// Preview
struct PaymentSheetExample_Previews: PreviewProvider {
    static var previews: some View {
        PaymentSheetExample()
    }
} 