//
//  AuthViewModel.swift
//  Nuvora
//
//  Updated to include required @Published properties for OTPVerificationView
//

import Foundation
import Supabase
import SwiftUI

class AuthViewModel: ObservableObject {
    @Published var phoneNumber = ""
    @Published var phoneNumberE164: String? // Added for OTPVerificationView compatibility
    @Published var verificationCode = ""
    @Published var isVerifying = false
    @Published var isAuthenticated = false
    @Published var hasSentCode = false
    @Published var showError: Bool = false // Added for OTPVerificationView compatibility
    @Published var errorMessage: String?

    // Make client a computed property that's always up to date and optional
    private var client: SupabaseClient? {
        SupabaseManager.shared.client
    }

    init() {
        Task {
            await checkAuthState()
        }
    }

    func sendCode() {
        isVerifying = true
        errorMessage = nil
        showError = false

        Task {
            guard let client = client else {
                DispatchQueue.main.async {
                    self.errorMessage = "Supabase client is not available."
                    self.showError = true
                    self.isVerifying = false
                }
                return
            }
            do {
                // Store the E164 formatted phone number
                self.phoneNumberE164 = phoneNumber.toE164Format()
                try await client.auth.signInWithOTP(phone: phoneNumber)
                DispatchQueue.main.async {
                    self.hasSentCode = true
                    self.isVerifying = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                    self.isVerifying = false
                }
            }
        }
    }

    func verifyCode() {
        isVerifying = true
        errorMessage = nil
        showError = false

        Task {
            guard let client = client else {
                DispatchQueue.main.async {
                    self.errorMessage = "Supabase client is not available."
                    self.showError = true
                    self.isVerifying = false
                }
                return
            }
            do {
                try await client.auth.verifyOTP(phone: phoneNumber, token: verificationCode, type: .sms)
                DispatchQueue.main.async {
                    self.isAuthenticated = true
                    self.isVerifying = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                    self.isVerifying = false
                }
            }
        }
    }
    
    // Added method for OTPVerificationView compatibility
    func verifyOTP(code: String, completion: @escaping (Bool) -> Void) {
        verificationCode = code
        isVerifying = true
        errorMessage = nil
        showError = false

        Task {
            guard let client = client else {
                DispatchQueue.main.async {
                    self.errorMessage = "Supabase client is not available."
                    self.showError = true
                    self.isVerifying = false
                    completion(false)
                }
                return
            }
            do {
                try await client.auth.verifyOTP(phone: phoneNumber, token: code, type: .sms)
                DispatchQueue.main.async {
                    self.isAuthenticated = true
                    self.isVerifying = false
                    completion(true)
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                    self.isVerifying = false
                    completion(false)
                }
            }
        }
    }
    
    // Added method for OTPVerificationView compatibility
    func resendOTP(completion: @escaping (Bool) -> Void) {
        sendCode()
        // Since sendCode is async, we'll simulate completion for now
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            completion(true)
        }
    }

    func signOut() {
        Task {
            guard let client = client else {
                DispatchQueue.main.async {
                    self.errorMessage = "Supabase client is not available."
                    self.showError = true
                }
                return
            }
            do {
                try await client.auth.signOut()
                DispatchQueue.main.async {
                    self.isAuthenticated = false
                    self.phoneNumber = ""
                    self.phoneNumberE164 = nil
                    self.verificationCode = ""
                    self.hasSentCode = false
                    self.showError = false
                    self.errorMessage = nil
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                }
            }
        }
    }

    private func checkAuthState() async {
        guard let client = client else { return }
        if let _ = client.auth.currentUser {
            DispatchQueue.main.async {
                self.isAuthenticated = true
            }
        }
    }
}
