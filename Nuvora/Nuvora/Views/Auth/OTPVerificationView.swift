import SwiftUI

/// OTP verification view with enhanced UX and validation
struct OTPVerificationView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @FocusState private var isOTPFieldFocused: Bool
    @State private var otpDigits: [String] = Array(repeating: "", count: 6)
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "message.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                Text("Verify Your Phone")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                VStack(spacing: 4) {
                    Text("We sent a 6-digit code to")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(authViewModel.phoneNumberE164 ?? authViewModel.phoneNumber)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Button("Change number") {
                        authViewModel.hasSentCode = false
                        authViewModel.verificationCode = ""
                        otpDigits = Array(repeating: "", count: 6)
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.top, 4)
                }
            }
            .padding(.top, 20)
            
            // OTP Input Section
            VStack(spacing: 20) {
                // OTP Digit Fields
                HStack(spacing: 12) {
                    ForEach(0..<6, id: \.self) { index in
                        OTPDigitField(
                            digit: $otpDigits[index],
                            isActive: index == getCurrentActiveIndex(),
                            onDigitEntered: { digit in
                                handleDigitInput(at: index, digit: digit)
                            },
                            onBackspace: {
                                handleBackspace(at: index)
                            }
                        )
                    }
                }
                .focused($isOTPFieldFocused)
                
                // Attempts Remaining
                if authViewModel.attemptsRemaining < 3 {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("\(authViewModel.attemptsRemaining) attempts remaining")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                // Verify Button
                Button(action: {
                    isOTPFieldFocused = false
                    Task {
                        await authViewModel.verifyCode()
                    }
                }) {
                    HStack {
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark.shield.fill")
                        }
                        
                        Text(authViewModel.isLoading ? "Verifying..." : "Verify Code")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(authViewModel.canVerifyCode ? Color.green : Color.gray.opacity(0.3))
                    )
                    .foregroundColor(.white)
                }
                .disabled(!authViewModel.canVerifyCode)
                .animation(.easeInOut(duration: 0.2), value: authViewModel.canVerifyCode)
            }
            
            // Resend Section
            VStack(spacing: 12) {
                if authViewModel.canResendCode {
                    Button("Resend Code") {
                        Task {
                            await authViewModel.resendCode()
                        }
                        // Clear OTP fields
                        otpDigits = Array(repeating: "", count: 6)
                        authViewModel.verificationCode = ""
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                } else if authViewModel.resendCountdown > 0 {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.secondary)
                        Text("Resend code in \(authViewModel.resendCountdown)s")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Help Text
                Text("Didn't receive the code? Check your messages or try resending.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            .padding(.top, 20)
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .onAppear {
            isOTPFieldFocused = true
        }
        .onChange(of: otpDigits) { _ in
            updateVerificationCode()
        }
        .alert("Error", isPresented: $authViewModel.showError) {
            Button("OK") {
                authViewModel.showError = false
            }
        } message: {
            Text(authViewModel.errorMessage ?? "An error occurred")
        }
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentActiveIndex() -> Int {
        for (index, digit) in otpDigits.enumerated() {
            if digit.isEmpty {
                return index
            }
        }
        return otpDigits.count - 1
    }
    
    private func handleDigitInput(at index: Int, digit: String) {
        guard !digit.isEmpty, digit.count == 1, digit.isNumber else { return }
        
        otpDigits[index] = digit
        
        // Move to next field if not the last one
        if index < otpDigits.count - 1 {
            // Focus will automatically move to next empty field
        }
    }
    
    private func handleBackspace(at index: Int) {
        if !otpDigits[index].isEmpty {
            otpDigits[index] = ""
        } else if index > 0 {
            otpDigits[index - 1] = ""
        }
    }
    
    private func updateVerificationCode() {
        authViewModel.verificationCode = otpDigits.joined()
    }
}

// MARK: - OTP Digit Field Component
struct OTPDigitField: View {
    @Binding var digit: String
    let isActive: Bool
    let onDigitEntered: (String) -> Void
    let onBackspace: () -> Void
    
    var body: some View {
        TextField("", text: $digit)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .font(.title2)
            .fontWeight(.semibold)
            .frame(width: 45, height: 55)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isActive ? Color.blue :
                                (!digit.isEmpty ? Color.green : Color.gray.opacity(0.3)),
                                lineWidth: isActive ? 2 : 1
                            )
                    )
            )
            .onChange(of: digit) { newValue in
                // Handle input
                if newValue.count > 1 {
                    // Take only the last character if multiple are entered
                    let lastChar = String(newValue.last ?? Character(""))
                    digit = lastChar
                    onDigitEntered(lastChar)
                } else if newValue.count == 1 {
                    onDigitEntered(newValue)
                } else if newValue.isEmpty {
                    onBackspace()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)) { obj in
                if let textField = obj.object as? UITextField {
                    textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
                }
            }
    }
}

// MARK: - Preview
struct OTPVerificationView_Previews: PreviewProvider {
    static var previews: some View {
        OTPVerificationView(authViewModel: {
            let vm = AuthViewModel()
            vm.hasSentCode = true
            vm.phoneNumber = "+1234567890"
            return vm
        }())
    }
}