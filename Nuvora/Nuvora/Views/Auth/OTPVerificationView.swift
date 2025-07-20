//
//  OTPVerificationView.swift
//  Nuvora
//
//  Created by Nuvora Team
//

import SwiftUI

struct OTPVerificationView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @State private var otpCode: String = ""
    @State private var isLoading: Bool = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 16) {
                Text("Verify Your Phone")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("We've sent a verification code to")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                // Fixed Line 26: Proper binding access to phoneNumberE164
                Text(authViewModel.phoneNumberE164 ?? "")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .padding(.top, 40)
            
            // OTP Input Field
            VStack(spacing: 16) {
                TextField("Enter verification code", text: $otpCode)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .focused($isTextFieldFocused)
                    .onChange(of: otpCode) { newValue in
                        // Fixed Line 167: Proper number validation
                        let filtered = newValue.filter { $0.isNumber }
                        if filtered.count <= 6 {
                            otpCode = filtered
                        } else {
                            otpCode = String(filtered.prefix(6))
                        }
                    }
                
                Button(action: {
                    verifyOTP()
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text(isLoading ? "Verifying..." : "Verify Code")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(otpCode.count == 6 ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(otpCode.count != 6 || isLoading)
            }
            .padding(.horizontal, 24)
            
            // Resend Code
            VStack(spacing: 12) {
                Text("Didn't receive the code?")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    resendCode()
                }) {
                    Text("Resend Code")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
                .disabled(isLoading)
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            isTextFieldFocused = true
        }
        // Fixed Lines 146, 148: Proper binding access to showError
        .alert("Verification Error", isPresented: $authViewModel.showError) {
            Button("OK") {
                authViewModel.showError = false
            }
        } message: {
            Text(authViewModel.errorMessage ?? "An error occurred during verification")
        }
    }
    
    private func verifyOTP() {
        guard otpCode.count == 6 else { return }
        
        isLoading = true
        authViewModel.verifyOTP(code: otpCode) { success in
            DispatchQueue.main.async {
                isLoading = false
                if !success {
                    otpCode = ""
                    isTextFieldFocused = true
                }
            }
        }
    }
    
    private func resendCode() {
        isLoading = true
        authViewModel.resendOTP { success in
            DispatchQueue.main.async {
                isLoading = false
            }
        }
    }
}

#Preview {
    OTPVerificationView(authViewModel: AuthViewModel())
}
