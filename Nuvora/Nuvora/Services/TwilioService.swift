import Foundation

/// Twilio SMS service for sending verification codes
class TwilioService {
    static let shared = TwilioService()
    
    private let accountSID: String
    private let authToken: String
    private let messageServiceSID: String
    
    private init() {
        self.accountSID = Config.twilioAccountSID
        self.authToken = Config.twilioAuthToken
        self.messageServiceSID = Config.twilioMessageServiceSID
    }
    
    /// Send SMS verification code using Twilio
    func sendVerificationSMS(to phoneNumber: String, code: String) async throws {
        let formattedPhone = phoneNumber.toE164Format()
        let message = "Your Nuvora verification code is: \(code). This code will expire in 10 minutes."
        
        try await sendSMS(to: formattedPhone, message: message)
    }
    
    /// Send SMS message using Twilio REST API
    private func sendSMS(to phoneNumber: String, message: String) async throws {
        guard let url = URL(string: "https://api.twilio.com/2010-04-01/Accounts/\(accountSID)/Messages.json") else {
            throw TwilioError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Basic authentication
        let credentials = "\(accountSID):\(authToken)"
        let credentialsData = credentials.data(using: .utf8)!
        let base64Credentials = credentialsData.base64EncodedString()
        request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // Request body
        let bodyParameters = [
            "To": phoneNumber,
            "MessagingServiceSid": messageServiceSID,
            "Body": message
        ]
        
        let bodyString = bodyParameters
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
        
        request.httpBody = bodyString.data(using: .utf8)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TwilioError.invalidResponse
            }
            
            if httpResponse.statusCode == 201 {
                print("✅ SMS sent successfully to \(phoneNumber)")
                
                // Parse response for debugging
                if let responseData = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("📱 Twilio Response: \(responseData)")
                }
            } else {
                // Parse error response
                if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorMessage = errorData["message"] as? String {
                    throw TwilioError.apiError(errorMessage)
                } else {
                    throw TwilioError.httpError(httpResponse.statusCode)
                }
            }
            
        } catch {
            print("❌ Failed to send SMS: \(error)")
            throw error
        }
    }
}

// MARK: - Twilio Errors

enum TwilioError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case apiError(String)
    case configurationMissing
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Twilio API URL"
        case .invalidResponse:
            return "Invalid response from Twilio"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .apiError(let message):
            return "Twilio API error: \(message)"
        case .configurationMissing:
            return "Twilio configuration is missing"
        }
    }
}