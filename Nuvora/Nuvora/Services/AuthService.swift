import Foundation
import Supabase
import Combine

/// Comprehensive authentication service with phone/SMS OTP support
class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private var client: SupabaseClient? {
        SupabaseManager.shared.client
    }
    
    private init() {
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        guard let client = client else { return }
        
        Task {
            for await state in client.auth.authStateChanges {
                await MainActor.run {
                    switch state.event {
                    case .signedIn:
                        self.isAuthenticated = true
                        self.currentUser = state.session?.user
                        print("✅ User authenticated: \(state.session?.user.id ?? "unknown")")
                        
                    case .signedOut:
                        self.isAuthenticated = false
                        self.currentUser = nil
                        print("👋 User signed out")
                        
                    case .tokenRefreshed:
                        self.currentUser = state.session?.user
                        print("🔄 Token refreshed")
                        
                    default:
                        break
                    }
                }
            }
        }
    }
    
    // MARK: - Phone Authentication
    
    /// Send OTP to phone number
    func sendOTP(to phoneNumber: String) async throws {
        guard let client = client else {
            throw AuthError.clientNotInitialized
        }
        
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            let formattedPhone = phoneNumber.toE164Format()
            try await client.auth.signInWithOTP(phone: formattedPhone)
            
            await MainActor.run {
                self.isLoading = false
            }
            
            print("✅ OTP sent to \(formattedPhone)")
            
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    /// Verify OTP code
    func verifyOTP(phoneNumber: String, code: String) async throws {
        guard let client = client else {
            throw AuthError.clientNotInitialized
        }
        
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            let formattedPhone = phoneNumber.toE164Format()
            try await client.auth.verifyOTP(
                phone: formattedPhone,
                token: code,
                type: .sms
            )
            
            await MainActor.run {
                self.isLoading = false
            }
            
            print("✅ OTP verified successfully")
            
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    /// Sign out current user
    func signOut() async throws {
        guard let client = client else {
            throw AuthError.clientNotInitialized
        }
        
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            try await client.auth.signOut()
            
            await MainActor.run {
                self.isLoading = false
            }
            
            print("✅ User signed out successfully")
            
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    // MARK: - Session Management
    
    /// Get current session
    var currentSession: Session? {
        return client?.auth.currentSession
    }
    
    /// Refresh current session
    func refreshSession() async throws {
        guard let client = client else {
            throw AuthError.clientNotInitialized
        }
        
        try await client.auth.refreshSession()
        print("✅ Session refreshed")
    }
    
    /// Check if user is authenticated
    func checkAuthState() async {
        guard let client = client else { return }
        
        if let session = client.auth.currentSession {
            await MainActor.run {
                self.isAuthenticated = true
                self.currentUser = session.user
            }
        } else {
            await MainActor.run {
                self.isAuthenticated = false
                self.currentUser = nil
            }
        }
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case clientNotInitialized
    case invalidPhoneNumber
    case invalidOTPCode
    case sessionExpired
    
    var errorDescription: String? {
        switch self {
        case .clientNotInitialized:
            return "Authentication service is not initialized"
        case .invalidPhoneNumber:
            return "Invalid phone number format"
        case .invalidOTPCode:
            return "Invalid OTP code"
        case .sessionExpired:
            return "Session has expired"
        }
    }
}