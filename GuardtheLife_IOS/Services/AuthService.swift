import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine
import KeychainAccess

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
    private func setupAuthStateListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                if let user = user {
                    self?.handleFirebaseUser(user)
                } else {
                    self?.handleSignOut()
                }
            }
        }
    }
    
    private func handleFirebaseUser(_ firebaseUser: FirebaseAuth.User) {
        // Get additional user data from Firestore
        let db = Firestore.firestore()
        db.collection("users").document(firebaseUser.uid).getDocument { [weak self] document, error in
            DispatchQueue.main.async {
                if let document = document, document.exists {
                    do {
                        let userData = try document.data(as: User.self)
                        self?.currentUser = userData
                        self?.isAuthenticated = true
                        self?.storeCredentials(firebaseUser: firebaseUser, userData: userData)
                    } catch {
                        print("Error decoding user data: \(error)")
                        self?.errorMessage = "Failed to load user profile"
                    }
                } else {
                    print("User document does not exist")
                    self?.errorMessage = "User profile not found"
                }
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
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            // First authenticate with Firebase
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            
            // Then get user data from your backend
            let loginResponse = try await apiService.login(email: email, password: password)
            
            // Set the auth token for API calls
            apiService.setAuthToken(loginResponse.token)
            
            // Update the current user
            DispatchQueue.main.async {
                self.currentUser = loginResponse.user
                self.isAuthenticated = true
                self.isLoading = false
            }
            
            // Connect to Socket.IO with authentication
            SocketService.shared.connectWithAuth(token: loginResponse.token)
            
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func signUp(email: String, password: String, firstName: String, lastName: String, role: UserRole, phoneNumber: String?) async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            // First create Firebase user
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            
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
            DispatchQueue.main.async {
                self.currentUser = loginResponse.user
                self.isAuthenticated = true
                self.isLoading = false
            }
            
            // Connect to Socket.IO with authentication
            SocketService.shared.connectWithAuth(token: loginResponse.token)
            
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
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
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            DispatchQueue.main.async {
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
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
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            // Update in Firestore
            let db = Firestore.firestore()
            try await db.collection("users").document(userId).updateData([
                "firstName": firstName,
                "lastName": lastName,
                "phoneNumber": phoneNumber ?? "",
                "updatedAt": Date()
            ])
            
            // Update local user object
            DispatchQueue.main.async {
                self.currentUser?.firstName = firstName
                self.currentUser?.lastName = lastName
                self.currentUser?.phoneNumber = phoneNumber
                self.isLoading = false
            }
            
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func deleteAccount() async {
        guard let user = Auth.auth().currentUser else { return }
        
        DispatchQueue.main.async {
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
            DispatchQueue.main.async {
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
    deinit {
        cancellables.removeAll()
    }
} 