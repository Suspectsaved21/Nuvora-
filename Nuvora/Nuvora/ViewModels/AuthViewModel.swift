import Foundation
import Supabase
import SwiftUI

class AuthViewModel: ObservableObject {
    @Published var phoneNumber = ""
    @Published var verificationCode = ""
    @Published var isVerifying = false
    @Published var isAuthenticated = false
    @Published var hasSentCode = false
    @Published var errorMessage: String?

    // Make client a computed property that’s always up to date and optional
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

        Task {
            guard let client = client else {
                DispatchQueue.main.async {
                    self.errorMessage = "Supabase client is not available."
                    self.isVerifying = false
                }
                return
            }
            do {
                try await client.auth.signInWithOTP(phone: phoneNumber)
                DispatchQueue.main.async {
                    self.hasSentCode = true
                    self.isVerifying = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isVerifying = false
                }
            }
        }
    }

    func verifyCode() {
        isVerifying = true
        errorMessage = nil

        Task {
            guard let client = client else {
                DispatchQueue.main.async {
                    self.errorMessage = "Supabase client is not available."
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
                    self.isVerifying = false
                }
            }
        }
    }

    func signOut() {
        Task {
            guard let client = client else {
                DispatchQueue.main.async {
                    self.errorMessage = "Supabase client is not available."
                }
                return
            }
            do {
                try await client.auth.signOut()
                DispatchQueue.main.async {
                    self.isAuthenticated = false
                    self.phoneNumber = ""
                    self.verificationCode = ""
                    self.hasSentCode = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
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

