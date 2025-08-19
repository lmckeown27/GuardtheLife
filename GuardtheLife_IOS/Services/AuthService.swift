import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine
import KeychainAccess

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let keychain = Keychain(service: "com.guardthelife.app")
    private let apiService = APIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupAuthStateListener()
        loadStoredCredentials()
    }
    
    // MARK: - Firebase Auth State Listener
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    private func setupAuthStateListener() {
        let listener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                if let user = user {
                    self?.handleFirebaseUser(user)
                } else {
                    self?.handleSignOut()
                }
            }
        }
        self.authStateListener = listener
    }
    
    private func handleFirebaseUser(_ firebaseUser: FirebaseAuth.User) {
        // Get additional user data from Firestore
        let db = Firestore.firestore()
        Task {
            do {
                let document = try await db.collection("users").document(firebaseUser.uid).getDocument()
                if document.exists {
                    let userData = try document.data(as: User.self)
                    self.currentUser = userData
                    self.isAuthenticated = true
                    self.storeCredentials(firebaseUser: firebaseUser, userData: userData)
                } else {
                    print("User document does not exist")
                    self.errorMessage = "User profile not found"
                }
            } catch {
                print("Error decoding user data: \(error)")
                self.errorMessage = "Failed to load user profile"
            }
        }
    }
    
    private func handleSignOut() {
        currentUser = nil
        isAuthenticated = false
        clearStoredCredentials()
        apiService.clearAuthToken()
    }
    
    // MARK: - Authentication Methods
    func signIn(email: String, password: String) async {
        self.isLoading = true
        self.errorMessage = nil
        
        do {
            // First authenticate with Firebase
            _ = try await Auth.auth().signIn(withEmail: email, password: password)
            
            // Then get user data from your backend
            let loginResponse = try await apiService.login(email: email, password: password)
            
            // Set the auth token for API calls
            apiService.setAuthToken(loginResponse.token)
            
            // Update the current user
            self.currentUser = loginResponse.user
            self.isAuthenticated = true
            self.isLoading = false
            
            // Connect to Socket.IO with authentication
            SocketService.shared.connectWithAuth(token: loginResponse.token)
            
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
    
    func signUp(email: String, password: String, firstName: String, lastName: String, role: UserRole, phoneNumber: String?) async {
        self.isLoading = true
        self.errorMessage = nil
        
        do {
            // First create Firebase user
            _ = try await Auth.auth().createUser(withEmail: email, password: password)
            
            // Then register with your backend
            let registerRequest = RegisterRequest(
                email: email,
                password: password,
                firstName: firstName,
                lastName: lastName,
                role: role,
                phoneNumber: phoneNumber
            )
            
            let loginResponse = try await apiService.register(registerData: registerRequest)
            
            // Set the auth token for API calls
            apiService.setAuthToken(loginResponse.token)
            
            // Update the current user
            self.currentUser = loginResponse.user
            self.isAuthenticated = true
            self.isLoading = false
            
            // Connect to Socket.IO with authentication
            SocketService.shared.connectWithAuth(token: loginResponse.token)
            
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            // handleSignOut() will be called by the auth state listener
        } catch {
            print("Error signing out: \(error)")
        }
    }
    
    func resetPassword(email: String) async {
        self.isLoading = true
        self.errorMessage = nil
        
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            self.isLoading = false
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
    
    // MARK: - Credential Storage
    private func storeCredentials(firebaseUser: FirebaseAuth.User, userData: User) {
        do {
            try keychain.set(firebaseUser.uid, key: "firebase_uid")
            try keychain.set(userData.id, key: "user_id")
            try keychain.set(userData.email, key: "user_email")
        } catch {
            print("Error storing credentials: \(error)")
        }
    }
    
    private func loadStoredCredentials() {
        // This could be used to restore session state
        // For now, we'll rely on Firebase's auth state listener
    }
    
    private func clearStoredCredentials() {
        do {
            try keychain.remove("firebase_uid")
            try keychain.remove("user_id")
            try keychain.remove("user_email")
        } catch {
            print("Error clearing credentials: \(error)")
        }
    }
    
    // MARK: - User Profile Management
    func updateProfile(firstName: String, lastName: String, phoneNumber: String?) async {
        guard let userId = currentUser?.id else { return }
        
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            // Update in Firestore
            let db = Firestore.firestore()
            var updateData: [String: Any] = [
                "firstName": firstName,
                "lastName": lastName,
                "updatedAt": Date()
            ]
            
            if let phone = phoneNumber {
                updateData["phoneNumber"] = phone
            } else {
                updateData["phoneNumber"] = ""
            }
            
            try await db.collection("users").document(userId).updateData(updateData)
            
            // Update local user object
            await MainActor.run {
                self.currentUser?.firstName = firstName
                self.currentUser?.lastName = lastName
                self.currentUser?.phoneNumber = phoneNumber
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func deleteAccount() async {
        guard let user = Auth.auth().currentUser else { return }
        
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            // Delete from Firestore
            let db = Firestore.firestore()
            try await db.collection("users").document(user.uid).delete()
            
            // Delete Firebase user
            try await user.delete()
            
            // handleSignOut() will be called by the auth state listener
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Session Validation
    func validateSession() async -> Bool {
        guard let user = Auth.auth().currentUser else { return false }
        
        do {
            // Verify the user's ID token
            let result = try await user.getIDTokenResult(forcingRefresh: true)
            return result.claims["user_id"] != nil
        } catch {
            print("Session validation failed: \(error)")
            return false
        }
    }
    
    // MARK: - Error Handling
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Cleanup
    func cleanup() {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
            authStateListener = nil
        }
        cancellables.removeAll()
    }
    
    private func removeAuthStateListener() {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
            authStateListener = nil
        }
    }
    
    deinit {
        // Note: Firebase listener cleanup will happen automatically when the app terminates
        // We can't safely call main actor methods from deinit in Swift 6
        cancellables.removeAll()
    }
} 