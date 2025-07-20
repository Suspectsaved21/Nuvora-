//
//  AuthViewModel.swift
//  Nuvora
//
//  Enhanced AuthViewModel using the new AuthService with comprehensive error handling
//

import Foundation
import Supabase
import SwiftUI
import Combine

class AuthViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var phoneNumber = ""
    @Published var phoneNumberE164: String?
    @Published var verificationCode = ""
    @Published var isLoading = false
    @Published var isAuthenticated = false
    @Published var hasSentCode = false
    @Published var showError: Bool = false
    @Published var errorMessage: String?
    @Published var currentUser: User?
    
    // MARK: - Computed Properties
    var isPhoneNumberValid: Bool {
        let cleaned = phoneNumber.numericOnly
        return cleaned.count == 10 || (cleaned.count == 11 && cleaned.hasPrefix("1"))
    }
    
    var canSendCode: Bool {
        return isPhoneNumberValid && !isLoading
    }
    
    var isVerifying: Bool {
        get { isLoading }
        set { isLoading = newValue }
    }
    
    // MARK: - Private Properties
    private var authService: AuthService {
        AuthService.shared
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupAuthServiceBindings()
        Task {
            await checkAuthState()
        }
    }
    
    private func setupAuthServiceBindings() {
        // Bind auth service properties to view model
        authService.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .assign(to: \.isAuthenticated, on: self)
            .store(in: &cancellables)
        
        authService.$currentUser
            .receive(on: DispatchQueue.main)
            .assign(to: \.currentUser, on: self)
            .store(in: &cancellables)
        
        authService.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)
        
        authService.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorMessage in
                self?.errorMessage = errorMessage
                self?.showError = errorMessage != nil
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Authentication Methods
    
    /// Send verification code to phone number
    func sendVerificationCode() async {
        guard isPhoneNumberValid else {
            await MainActor.run {
                self.errorMessage = "Please enter a valid phone number"
                self.showError = true
            }
            return
        }
        
        do {
            phoneNumberE164 = phoneNumber.toE164Format()
            try await authService.sendOTP(to: phoneNumber)
            
            await MainActor.run {
                self.hasSentCode = true
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.showError = true
            }
        }
    }
    
    /// Legacy method for compatibility
    func sendCode() {
        Task {
            await sendVerificationCode()
        }
    }
    
    /// Verify OTP code
    func verifyCode() async {
        guard !verificationCode.isEmpty else {
            await MainActor.run {
                self.errorMessage = "Please enter the verification code"
                self.showError = true
            }
            return
        }
        
        do {
            try await authService.verifyOTP(phoneNumber: phoneNumber, code: verificationCode)
            
            await MainActor.run {
                self.verificationCode = ""
                self.hasSentCode = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.showError = true
            }
        }
    }
    
    /// Verify OTP with completion handler (for compatibility)
    func verifyOTP(code: String, completion: @escaping (Bool) -> Void) {
        verificationCode = code
        
        Task {
            do {
                try await authService.verifyOTP(phoneNumber: phoneNumber, code: code)
                await MainActor.run {
                    completion(true)
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                    completion(false)
                }
            }
        }
    }
    
    /// Resend OTP code
    func resendOTP(completion: @escaping (Bool) -> Void) {
        Task {
            do {
                try await authService.sendOTP(to: phoneNumber)
                await MainActor.run {
                    completion(true)
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                    completion(false)
                }
            }
        }
    }
    
    /// Sign out current user
    func signOut() {
        Task {
            do {
                try await authService.signOut()
                
                await MainActor.run {
                    self.phoneNumber = ""
                    self.phoneNumberE164 = nil
                    self.verificationCode = ""
                    self.hasSentCode = false
                    self.showError = false
                    self.errorMessage = nil
                }
                
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                }
            }
        }
    }
    
    /// Check current authentication state
    func checkAuthState() async {
        await authService.checkAuthState()
    }
    
    /// Clear error state
    func clearError() {
        errorMessage = nil
        showError = false
    }
    
    /// Reset form state
    func resetForm() {
        phoneNumber = ""
        phoneNumberE164 = nil
        verificationCode = ""
        hasSentCode = false
        clearError()
    }
}