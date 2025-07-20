import SwiftUI

struct LoginView: View {
    @StateObject private var auth = AuthViewModel()

    var body: some View {
        VStack(spacing: 20) {
            Text("📱 Verify Your Number")
                .font(.title)
                .bold()

            TextField("Phone Number", text: $auth.phoneNumber)
                .keyboardType(.phonePad)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)

            if auth.hasSentCode {
                TextField("Verification Code", text: $auth.verificationCode)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)

                Button("Verify Code") {
                    auth.verifyCode()
                }
                .disabled(auth.isVerifying)
            } else {
                Button("Send Code") {
                    auth.sendCode()
                }
                .disabled(auth.isVerifying || auth.phoneNumber.isEmpty)
            }

            if let error = auth.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
}

