import Foundation
import Supabase
import Combine

/// Enhanced authentication service with Twilio SMS integration
class EnhancedAuthService: ObservableObject {
    static let shared = EnhancedAuthService()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var otpSent = false
    @Published var verificationInProgress = false
    
    private var cancellables = Set<AnyCancellable>()
    private var client: SupabaseClient? {
        SupabaseManager.shared.client
    }
    
    private var pendingPhoneNumber: String?
    private var otpAttempts = 0
    private var otpSentTime: Date?
    
    private init() {
        setupAuthStateListener()
        
        // Validate configuration on init
        if Config.validateConfiguration() {
            print("✅ Enhanced Auth Service initialized successfully")
        } else {
            print("⚠️ Enhanced Auth Service initialized with incomplete configuration")
        }
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
                        self.resetOTPState()
                        print("✅ User authenticated: \(state.session?.user.id ?? "unknown")")
                        
                    case .signedOut:
                        self.isAuthenticated = false
                        self.currentUser = nil
                        self.resetOTPState()
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
    
    // MARK: - Enhanced Phone Authentication with Twilio
    
    /// Send OTP using both Supabase and Twilio for redundancy
    func sendOTP(to phoneNumber: String) async throws {
        guard let client = client else {
            throw AuthError.clientNotInitialized
        }
        
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
            self.verificationInProgress = true
        }
        
        do {
            let formattedPhone = phoneNumber.toE164Format()
            self.pendingPhoneNumber = formattedPhone
            
            // Generate custom OTP for Twilio backup
            let customOTP = generateOTP()
            
            // Primary: Use Supabase OTP
            try await client.auth.signInWithOTP(phone: formattedPhone)
            
            // Backup: Send custom OTP via Twilio (for fallback scenarios)
            do {
                try await TwilioService.shared.sendVerificationSMS(to: formattedPhone, code: customOTP)
                print("📱 Backup SMS sent via Twilio")
            } catch {
                print("⚠️ Twilio backup SMS failed: \(error)")
                // Don't fail the entire process if Twilio fails
            }
            
            await MainActor.run {
                self.isLoading = false
                self.otpSent = true
                self.otpSentTime = Date()
                self.otpAttempts = 0
            }
            
            print("✅ OTP sent to \(formattedPhone)")
            
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
                self.verificationInProgress = false
            }
            throw error
        }
    }
    
    /// Verify OTP code with enhanced error handling
    func verifyOTP(code: String) async throws {
        guard let client = client,
              let phoneNumber = pendingPhoneNumber else {
            throw AuthError.clientNotInitialized
        }
        
        guard otpAttempts < Config.maxOTPAttempts else {
            throw AuthError.tooManyAttempts
        }
        
        // Check if OTP is expired
        if let sentTime = otpSentTime,
           Date().timeIntervalSince(sentTime) > TimeInterval(Config.otpExpirationMinutes * 60) {
            throw AuthError.otpExpired
        }
        
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            try await client.auth.verifyOTP(
                phone: phoneNumber,
                token: code,
                type: .sms
            )
            
            await MainActor.run {
                self.isLoading = false
                self.resetOTPState()
            }
            
            print("✅ OTP verified successfully")
            
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.otpAttempts += 1
                self.errorMessage = error.localizedDescription
                
                if self.otpAttempts >= Config.maxOTPAttempts {
                    self.resetOTPState()
                }
            }
            throw error
        }
    }
    
    /// Resend OTP with rate limiting
    func resendOTP() async throws {
        guard let phoneNumber = pendingPhoneNumber else {
            throw AuthError.noPhoneNumberPending
        }
        
        // Rate limiting: prevent resend within 60 seconds
        if let sentTime = otpSentTime,
           Date().timeIntervalSince(sentTime) < 60 {
            throw AuthError.resendTooSoon
        }
        
        try await sendOTP(to: phoneNumber)
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
                self.resetOTPState()
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
    
    // MARK: - Helper Methods
    
    private func resetOTPState() {
        otpSent = false
        verificationInProgress = false
        pendingPhoneNumber = nil
        otpAttempts = 0
        otpSentTime = nil
    }
    
    private func generateOTP() -> String {
        return String(format: "%06d", Int.random(in: 100000...999999))
    }
    
    // MARK: - Session Management
    
    var currentSession: Session? {
        return client?.auth.currentSession
    }
    
    func refreshSession() async throws {
        guard let client = client else {
            throw AuthError.clientNotInitialized
        }
        
        try await client.auth.refreshSession()
        print("✅ Session refreshed")
    }
    
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

// MARK: - Enhanced Auth Errors

enum AuthError: LocalizedError {
    case clientNotInitialized
    case invalidPhoneNumber
    case invalidOTPCode
    case sessionExpired
    case tooManyAttempts
    case otpExpired
    case noPhoneNumberPending
    case resendTooSoon
    
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
        case .tooManyAttempts:
            return "Too many failed attempts. Please try again later."
        case .otpExpired:
            return "OTP code has expired. Please request a new one."
        case .noPhoneNumberPending:
            return "No phone number verification in progress"
        case .resendTooSoon:
            return "Please wait before requesting another code"
        }
    }
}