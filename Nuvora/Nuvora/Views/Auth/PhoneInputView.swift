import SwiftUI

/// Enhanced phone number input view with validation and formatting
struct PhoneInputView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @FocusState private var isPhoneFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "phone.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Enter Your Phone Number")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("We'll send you a verification code")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 20)
            
            // Phone Input Section
            VStack(spacing: 16) {
                // Phone Number Field
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        // Country Code Indicator
                        HStack(spacing: 4) {
                            Text("🇺🇸")
                                .font(.title3)
                            Text("+1")
                                .font(.body)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        
                        // Phone Number Input
                        TextField("(555) 123-4567", text: $authViewModel.phoneNumber)
                            .keyboardType(.phonePad)
                            .textContentType(.telephoneNumber)
                            .focused($isPhoneFieldFocused)
                            .font(.body)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                authViewModel.isPhoneNumberValid ? Color.green :
                                                (authViewModel.phoneNumber.isEmpty ? Color.gray.opacity(0.3) : Color.red),
                                                lineWidth: 1
                                            )
                                    )
                            )
                    }
                    
                    // Validation Message
                    if !authViewModel.phoneNumber.isEmpty && !authViewModel.isPhoneNumberValid {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                            Text("Please enter a valid phone number")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .transition(.opacity)
                    }
                    
                    // Success Message
                    if authViewModel.isPhoneNumberValid {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text("Valid phone number")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        .transition(.opacity)
                    }
                }
                
                // Send Code Button
                Button(action: {
                    isPhoneFieldFocused = false
                    Task {
                        await authViewModel.sendVerificationCode()
                    }
                }) {
                    HStack {
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "paperplane.fill")
                        }
                        
                        Text(authViewModel.isLoading ? "Sending..." : "Send Verification Code")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(authViewModel.canSendCode ? Color.blue : Color.gray.opacity(0.3))
                    )
                    .foregroundColor(.white)
                }
                .disabled(!authViewModel.canSendCode)
                .animation(.easeInOut(duration: 0.2), value: authViewModel.canSendCode)
            }
            
            // Info Section
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "shield.checkered")
                        .foregroundColor(.blue)
                    Text("Your phone number is encrypted and secure")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.blue)
                    Text("Verification code expires in 10 minutes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 20)
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .onAppear {
            isPhoneFieldFocused = true
        }
        .alert("Error", isPresented: $authViewModel.showError) {
            Button("OK") {
                authViewModel.showError = false
            }
        } message: {
            Text(authViewModel.errorMessage ?? "An error occurred")
        }
    }
}

// MARK: - Preview
struct PhoneInputView_Previews: PreviewProvider {
    static var previews: some View {
        PhoneInputView(authViewModel: AuthViewModel())
    }
}