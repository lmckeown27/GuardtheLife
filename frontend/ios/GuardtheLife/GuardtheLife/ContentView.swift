import SwiftUI

struct ContentView: View {
    @State private var isAuthenticated = false
    @State private var selectedTab = 0
    
    var body: some View {
        if isAuthenticated {
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
            LoginView(isAuthenticated: $isAuthenticated)
        }
    }
}

struct HomeView: View {
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
    var body: some View {
        NavigationView {
            VStack {
                Text("Available Lifeguards")
                    .font(.title)
                    .padding()
                
                List {
                    ForEach(0..<5) { index in
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title2)
                            
                            VStack(alignment: .leading) {
                                Text("Lifeguard \(index + 1)")
                                    .fontWeight(.semibold)
                                Text("Available • 5.0 ★")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("Book") {
                                // Booking action
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.vertical, 5)
                    }
                }
            }
            .navigationTitle("Lifeguards")
        }
    }
}

struct BookingView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Your Bookings")
                    .font(.title)
                    .padding()
                
                List {
                    ForEach(0..<3) { index in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Booking #\(index + 1)")
                                    .fontWeight(.semibold)
                                Spacer()
                                Text("Confirmed")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            
                            Text("Lifeguard: John Doe")
                                .font(.subheadline)
                            Text("Date: Aug 18, 2024")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 5)
                    }
                }
            }
            .navigationTitle("Bookings")
        }
    }
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
    @Binding var isAuthenticated: Bool
    @State private var email = ""
    @State private var password = ""
    
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
                    // Simple authentication for demo
                    if !email.isEmpty && !password.isEmpty {
                        isAuthenticated = true
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(email.isEmpty || password.isEmpty)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 