import SwiftUI

struct ContentView: View {
    @StateObject private var authService = AuthService.shared
    @StateObject private var locationService = LocationService.shared
    @StateObject private var socketService = SocketService.shared
    @StateObject private var notificationService = NotificationService.shared
    @State private var selectedTab = 0
    
    var body: some View {
        if authService.isAuthenticated {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }
                    .tag(0)
                
                LifeguardView()
                    .tabItem {
                        Image(systemName: "person.2.fill")
                        Text("Lifeguards")
                    }
                    .tag(1)
                
                BookingView()
                    .tabItem {
                        Image(systemName: "calendar.badge.plus")
                        Text("Bookings")
                    }
                    .tag(2)
                
                ProfileView()
                    .tabItem {
                        Image(systemName: "person.circle.fill")
                        Text("Profile")
                    }
                    .tag(3)
            }
            .accentColor(.blue)
        } else {
            LoginView()
        }
    }
}

struct HomeView: View {
    @StateObject private var locationService = LocationService.shared
    @StateObject private var socketService = SocketService.shared
    @StateObject private var notificationService = NotificationService.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("GuardtheLife")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                Text("Your safety is our priority")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 15) {
                    Button(action: {
                        // Request lifeguard action
                        locationService.requestLocationPermission()
                    }) {
                        HStack {
                            Image(systemName: "person.2.circle.fill")
                                .foregroundColor(.white)
                            Text("Request Lifeguard")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        // Emergency action
                        if let location = locationService.getEmergencyLocation() {
                            socketService.emitEmergencySignal(location: location, description: "Emergency assistance needed")
                            notificationService.scheduleEmergencyNotification(
                                type: .medical,
                                location: location,
                                description: "Emergency assistance requested"
                            )
                        }
                    }) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.white)
                            Text("Emergency")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Home")
            .navigationBarHidden(true)
        }
    }
}

struct LifeguardView: View {
    @State private var showingBookingFlow = false
    @State private var selectedLifeguardId = ""
    @State private var selectedLifeguardName = ""
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Available Lifeguards")
                    .font(.title)
                    .padding()
                
                List {
                    ForEach(0..<5) { index in
                        LifeguardRow(
                            lifeguardId: "lg_\(index + 1)",
                            name: "Lifeguard \(index + 1)",
                            rating: 5.0,
                            status: "Available",
                            hourlyRate: 75.0
                        ) {
                            selectedLifeguardId = "lg_\(index + 1)"
                            selectedLifeguardName = "Lifeguard \(index + 1)"
                            showingBookingFlow = true
                        }
                    }
                }
            }
            .navigationTitle("Lifeguards")
        }
        .sheet(isPresented: $showingBookingFlow) {
            BookingFlowView(
                lifeguardId: selectedLifeguardId,
                lifeguardName: selectedLifeguardName
            )
        }
    }
}

struct LifeguardRow: View {
    let lifeguardId: String
    let name: String
    let rating: Double
    let status: String
    let hourlyRate: Double
    let onBook: () -> Void
    
    var body: some View {
        HStack {
            // Profile image
            AsyncImage(url: URL(string: "https://via.placeholder.com/50")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .fontWeight(.semibold)
                
                HStack {
                    Text(status)
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 2) {
                        Text(String(format: "%.1f", rating))
                            .font(.caption)
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }
                
                Text("$\(String(format: "%.0f", hourlyRate))/hour")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Book Now") {
                onBook()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(.vertical, 8)
    }
}

struct BookingView: View {
    @StateObject private var apiService = APIService.shared
    @StateObject private var paymentService = PaymentService.shared
    @State private var bookings: [Booking] = []
    @State private var isLoading = false
    @State private var showingPaymentHistory = false
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading bookings...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if bookings.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Bookings Yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Book your first lifeguard service from the Lifeguards tab")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(bookings) { booking in
                            BookingCard(booking: booking)
                        }
                    }
                }
            }
            .navigationTitle("Your Bookings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Payment History") {
                        showingPaymentHistory = true
                    }
                    .font(.caption)
                }
            }
        }
        .sheet(isPresented: $showingPaymentHistory) {
            PaymentHistoryView()
        }
        .task {
            await loadBookings()
        }
        .refreshable {
            await loadBookings()
        }
    }
    
    @MainActor
    private func loadBookings() async {
        isLoading = true
        do {
            bookings = try await apiService.getBookings()
        } catch {
            print("Failed to load bookings: \(error)")
            // For demo purposes, show some sample bookings
            bookings = createSampleBookings()
        }
        isLoading = false
    }
    
    private func createSampleBookings() -> [Booking] {
        // Sample bookings for demo
        return [
            Booking(
                id: "booking_1",
                clientId: "client_1",
                client: User(id: "client_1", email: "user@example.com", firstName: "John", lastName: "Doe", role: .client, phoneNumber: nil, isVerified: true, createdAt: Date(), profileImageURL: nil),
                lifeguardId: "lg_1",
                lifeguard: Lifeguard(id: "lg_1", firstName: "Jane", lastName: "Smith", email: "jane@example.com", phoneNumber: "+1234567890", isVerified: true, isAvailable: true, rating: 4.8, totalBookings: 150, specializations: [.poolSupervision], hourlyRate: 75.0, profileImageURL: nil, location: nil, bio: nil, createdAt: Date()),
                serviceType: .poolSupervision,
                status: .confirmed,
                startTime: Date().addingTimeInterval(86400), // Tomorrow
                endTime: Date().addingTimeInterval(90000), // Tomorrow + 1 hour
                duration: 60,
                location: LocationModel(latitude: 37.7749, longitude: -122.4194, address: "Pool Area, Hotel XYZ"),
                specialInstructions: "Adult swimming supervision needed",
                totalAmount: 80.0,
                paymentStatus: .completed,
                createdAt: Date().addingTimeInterval(-3600),
                updatedAt: Date()
            )
        ]
    }
}

struct BookingCard: View {
    let booking: Booking
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text(booking.serviceType.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("with \(booking.lifeguard.firstName) \(booking.lifeguard.lastName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                StatusBadge(status: booking.status)
            }
            
            // Date and time
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
                Text(DateFormatter.bookingDate.string(from: booking.startTime))
                    .font(.subheadline)
                
                Spacer()
                
                Image(systemName: "clock")
                    .foregroundColor(.blue)
                Text(booking.formattedTimeRange)
                    .font(.subheadline)
            }
            
            // Location
            HStack {
                Image(systemName: "location")
                    .foregroundColor(.blue)
                Text(booking.location.address ?? "Location not specified")
                    .font(.subheadline)
                    .lineLimit(1)
            }
            
            // Payment info
            HStack {
                Text(String(format: "$%.2f", booking.totalAmount))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                
                Spacer()
                
                PaymentStatusBadge(status: booking.paymentStatus)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct StatusBadge: View {
    let status: BookingStatus
    
    var body: some View {
        Text(status.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundColor(.white)
            .cornerRadius(6)
    }
    
    private var backgroundColor: Color {
        switch status {
        case .pending: return .orange
        case .confirmed: return .blue
        case .inProgress: return .green
        case .completed: return .gray
        case .cancelled, .rejected: return .red
        }
    }
}

struct PaymentStatusBadge: View {
    let status: PaymentStatus
    
    var body: some View {
        Text(status.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(backgroundColor.opacity(0.2))
            .foregroundColor(backgroundColor)
            .cornerRadius(4)
    }
    
    private var backgroundColor: Color {
        switch status {
        case .pending: return .orange
        case .processing: return .blue
        case .completed: return .green
        case .failed: return .red
        case .refunded: return .purple
        }
    }
}

struct PaymentHistoryView: View {
    @StateObject private var paymentService = PaymentService.shared
    @State private var transactions: [PaymentTransaction] = []
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(transactions) { transaction in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(transaction.formattedAmount)
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Text(transaction.status.capitalized)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(transaction.status == "succeeded" ? Color.green : Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(6)
                        }
                        
                        Text(transaction.formattedDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let description = transaction.description {
                            Text(description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Payment History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await loadPaymentHistory()
        }
    }
    
    private func loadPaymentHistory() async {
        do {
            transactions = try await paymentService.getPaymentHistory()
        } catch {
            print("Failed to load payment history: \(error)")
        }
    }
}

extension DateFormatter {
    static let bookingDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}

// MARK: - BookingFlowView

struct BookingFlowView: View {
    let lifeguardId: String
    let lifeguardName: String
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var paymentService = PaymentService.shared
    @StateObject private var apiService = APIService.shared
    
    @State private var currentStep: BookingStep = .details
    @State private var selectedDate = Date()
    @State private var selectedDuration: Int = 60 // minutes
    @State private var selectedServiceType: ServiceType = .poolSupervision
    @State private var specialInstructions = ""
    @State private var location = LocationModel(latitude: 37.7749, longitude: -122.4194, address: "Pool Area")
    @State private var isProcessing = false
    @State private var showingPaymentSheet = false
    @State private var paymentClientSecret: String?
    
    private var totalAmount: Double {
        let hourlyRate: Double = 75.0 // This should come from the lifeguard data
        return Double(selectedDuration) / 60.0 * hourlyRate
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress indicator
                ProgressView(value: progressValue)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .padding()
                
                // Step content
                switch currentStep {
                case .details:
                    bookingDetailsView
                case .summary:
                    bookingSummaryView
                case .payment:
                    paymentView
                case .confirmation:
                    confirmationView
                }
                
                Spacer()
                
                // Navigation buttons
                navigationButtons
            }
            .navigationTitle("Book \(lifeguardName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingPaymentSheet) {
            if let clientSecret = paymentClientSecret {
                PaymentSheetView(clientSecret: clientSecret) { result in
                    handlePaymentResult(result)
                }
            }
        }
    }
    
    // MARK: - Step Views
    
    private var bookingDetailsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Date and Time
                VStack(alignment: .leading, spacing: 8) {
                    Text("Date & Time")
                        .font(.headline)
                    
                    DatePicker("Select Date", selection: $selectedDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                }
                
                // Duration
                VStack(alignment: .leading, spacing: 8) {
                    Text("Duration")
                        .font(.headline)
                    
                    Picker("Duration", selection: $selectedDuration) {
                        Text("30 minutes").tag(30)
                        Text("1 hour").tag(60)
                        Text("1.5 hours").tag(90)
                        Text("2 hours").tag(120)
                        Text("3 hours").tag(180)
                        Text("4 hours").tag(240)
                    }
                    .pickerStyle(.menu)
                }
                
                // Service Type
                VStack(alignment: .leading, spacing: 8) {
                    Text("Service Type")
                        .font(.headline)
                    
                    Picker("Service Type", selection: $selectedServiceType) {
                        ForEach(ServiceType.allCases, id: \.self) { serviceType in
                            Text(serviceType.displayName).tag(serviceType)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                // Special Instructions
                VStack(alignment: .leading, spacing: 8) {
                    Text("Special Instructions")
                        .font(.headline)
                    
                    TextField("Any special requirements or notes...", text: $specialInstructions, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                }
            }
            .padding()
        }
    }
    
    private var bookingSummaryView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Lifeguard Info
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading) {
                        Text(lifeguardName)
                            .font(.headline)
                        Text("Professional Lifeguard")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                
                // Booking Details
                VStack(alignment: .leading, spacing: 12) {
                    Text("Booking Details")
                        .font(.headline)
                    
                    DetailRow(title: "Date", value: DateFormatter.bookingDate.string(from: selectedDate))
                    DetailRow(title: "Time", value: DateFormatter.bookingTime.string(from: selectedDate))
                    DetailRow(title: "Duration", value: "\(selectedDuration) minutes")
                    DetailRow(title: "Service", value: selectedServiceType.displayName)
                    
                    if !specialInstructions.isEmpty {
                        DetailRow(title: "Instructions", value: specialInstructions)
                    }
                }
                
                // Pricing
                VStack(alignment: .leading, spacing: 12) {
                    Text("Pricing")
                        .font(.headline)
                    
                    HStack {
                        Text("Rate")
                        Spacer()
                        Text("$75.00/hour")
                    }
                    
                    HStack {
                        Text("Duration")
                        Spacer()
                        Text("\(String(format: "%.1f", Double(selectedDuration) / 60.0)) hours")
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Total")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(String(format: "$%.2f", totalAmount))
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding()
        }
    }
    
    private var paymentView: some View {
        VStack(spacing: 20) {
            Image(systemName: "creditcard.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Payment")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Total Amount: \(String(format: "$%.2f", totalAmount))")
                .font(.headline)
                .foregroundColor(.blue)
            
            Text("Click 'Process Payment' to continue with Stripe PaymentSheet")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if isProcessing {
                ProgressView("Processing...")
            } else {
                Button("Process Payment") {
                    Task {
                        await processPayment()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isProcessing)
            }
        }
        .padding()
    }
    
    private var confirmationView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Booking Confirmed!")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Your lifeguard service has been booked successfully.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    // MARK: - Navigation
    
    private var navigationButtons: some View {
        HStack {
            if currentStep != .details {
                Button("Back") {
                    withAnimation {
                        currentStep = previousStep
                    }
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
            
            if currentStep != .confirmation {
                Button(nextButtonTitle) {
                    withAnimation {
                        if currentStep == .payment {
                            Task {
                                await processPayment()
                            }
                        } else {
                            currentStep = nextStep
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isProcessing)
            }
        }
        .padding()
    }
    
    // MARK: - Helper Methods
    
    private var progressValue: Double {
        switch currentStep {
        case .details: return 0.25
        case .summary: return 0.5
        case .payment: return 0.75
        case .confirmation: return 1.0
        }
    }
    
    private var nextButtonTitle: String {
        switch currentStep {
        case .details: return "Next"
        case .summary: return "Continue to Payment"
        case .payment: return "Process Payment"
        case .confirmation: return "Done"
        }
    }
    
    private var nextStep: BookingStep {
        switch currentStep {
        case .details: return .summary
        case .summary: return .payment
        case .payment: return .confirmation
        case .confirmation: return .confirmation
        }
    }
    
    private var previousStep: BookingStep {
        switch currentStep {
        case .details: return .details
        case .summary: return .details
        case .payment: return .summary
        case .confirmation: return .payment
        }
    }
    
    // MARK: - Payment Processing
    
    private func processPayment() async {
        isProcessing = true
        
        do {
            // Create booking first
            let booking = try await createBooking()
            
            // Create payment intent on backend
            let paymentIntent = try await createPaymentIntent(for: booking)
            
            // Store client secret for PaymentSheet
            paymentClientSecret = paymentIntent.clientSecret
            
            // Show PaymentSheet
            showingPaymentSheet = true
            
        } catch {
            print("Payment processing failed: \(error)")
            // Handle error appropriately
        }
        
        isProcessing = false
    }
    
    private func createBooking() async throws -> Booking {
        // This would typically call your backend API
        // For now, we'll create a mock booking
        return Booking(
            id: UUID().uuidString,
            clientId: "client_1", // This should come from user authentication
            client: User(id: "client_1", email: "user@example.com", firstName: "John", lastName: "Doe", role: .client, phoneNumber: nil, isVerified: true, createdAt: Date(), profileImageURL: nil),
            lifeguardId: lifeguardId,
            lifeguard: Lifeguard(id: lifeguardId, firstName: lifeguardName, lastName: "", email: "", phoneNumber: "", isVerified: true, isAvailable: true, rating: 5.0, totalBookings: 100, specializations: [selectedServiceType], hourlyRate: 75.0, profileImageURL: nil, location: nil, bio: nil, createdAt: Date()),
            serviceType: selectedServiceType,
            status: .pending,
            startTime: selectedDate,
            endTime: selectedDate.addingTimeInterval(TimeInterval(selectedDuration * 60)),
            duration: selectedDuration,
            location: location,
            specialInstructions: specialInstructions.isEmpty ? nil : specialInstructions,
            totalAmount: totalAmount,
            paymentStatus: .pending,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    private func createPaymentIntent(for booking: Booking) async throws -> BackendPaymentIntent {
        // This would call your backend API to create a Stripe payment intent
        // For now, we'll return a mock response
        return BackendPaymentIntent(
            paymentIntentId: "pi_\(UUID().uuidString)",
            clientSecret: "pi_\(UUID().uuidString)_secret_\(UUID().uuidString)"
        )
    }
    
    private func handlePaymentResult(_ result: PaymentSheetResult) {
        switch result {
        case .completed:
            withAnimation {
                currentStep = .confirmation
            }
        case .canceled:
            // User canceled payment
            break
        case .failed(let error):
            print("Payment failed: \(error)")
            // Handle payment failure
            break
        }
    }
}

// MARK: - Supporting Views

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct PaymentSheetView: UIViewControllerRepresentable {
    let clientSecret: String
    let onResult: (PaymentSheetResult) -> Void
    
    func makeUIViewController(context: Context) -> UIViewController {
        let paymentSheet = PaymentSheet(paymentIntentClientSecret: clientSecret)
        let viewController = UIViewController()
        
        paymentSheet.present(from: viewController) { result in
            onResult(result)
        }
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

// MARK: - Enums

enum BookingStep {
    case details
    case summary
    case payment
    case confirmation
}

enum PaymentSheetResult {
    case completed
    case canceled
    case failed(Error)
}

// MARK: - Extensions

extension DateFormatter {
    static let bookingTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

struct ProfileView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("John Doe")
                    .font(.title)
                    .fontWeight(.semibold)
                
                Text("john.doe@example.com")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 15) {
                    Button("Edit Profile") {
                        // Edit profile action
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Settings") {
                        // Settings action
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Logout") {
                        // Logout action
                    }
                    .buttonStyle(.borderedProminent)
                    .foregroundColor(.red)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Profile")
            .navigationBarHidden(true)
        }
    }
}

struct LoginView: View {
    @StateObject private var authService = AuthService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var showingSignUp = false
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 15) {
                Text("GuardtheLife")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                Text("Sign in to continue")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 20) {
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Sign In") {
                    Task {
                        await authService.signIn(email: email, password: password)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(email.isEmpty || password.isEmpty || authService.isLoading)
                
                if authService.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
                
                if let errorMessage = authService.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }
                
                Button("Create Account") {
                    showingSignUp = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showingSignUp) {
            SignUpView()
        }
    }
}

struct SignUpView: View {
    @StateObject private var authService = AuthService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var phoneNumber = ""
    @State private var selectedRole: UserRole = .client
    
    var body: some View {
        NavigationView {
            Form {
                Section("Personal Information") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Phone Number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                }
                
                Section("Account Details") {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $password)
                    SecureField("Confirm Password", text: $confirmPassword)
                }
                
                Section("Role") {
                    Picker("Select Role", selection: $selectedRole) {
                        ForEach(UserRole.allCases, id: \.self) { role in
                            Text(role.displayName).tag(role)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section {
                    Button("Create Account") {
                        Task {
                            await authService.signUp(
                                email: email,
                                password: password,
                                firstName: firstName,
                                lastName: lastName,
                                role: selectedRole,
                                phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber
                            )
                            
                            if authService.isAuthenticated {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!isFormValid || authService.isLoading)
                    
                    if authService.isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    }
                    
                    if let errorMessage = authService.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Create Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && password == confirmPassword &&
        !firstName.isEmpty && !lastName.isEmpty && password.count >= 6
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 