import Foundation

struct Config {
    // MARK: - Supabase Configuration
    static let supabaseURL = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String ?? "https://your-project.supabase.co"
    static let supabaseAnonKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String ?? "your-anon-key"
    
    // MARK: - Twilio Configuration (for SMS)
    static let twilioAccountSID = Bundle.main.object(forInfoDictionaryKey: "TWILIO_ACCOUNT_SID") as? String ?? ""
    static let twilioAuthToken = Bundle.main.object(forInfoDictionaryKey: "TWILIO_AUTH_TOKEN") as? String ?? ""
    static let twilioMessageServiceSID = Bundle.main.object(forInfoDictionaryKey: "TWILIO_MESSAGE_SERVICE_SID") as? String ?? ""
    
    // MARK: - App Configuration
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    // MARK: - Debug Configuration
    static let isDebug: Bool = {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }()
    
    // MARK: - Security Configuration
    static let maxOTPAttempts = 3
    static let otpExpirationMinutes = 10
    static let sessionTimeoutMinutes = 60
    
    // MARK: - Validation
    static func validateConfiguration() -> Bool {
        guard !supabaseURL.contains("your-project"),
              !supabaseAnonKey.contains("your-anon-key"),
              !twilioAccountSID.isEmpty,
              !twilioAuthToken.isEmpty,
              !twilioMessageServiceSID.isEmpty else {
            print("⚠️ Warning: Configuration not complete. Please check your Config.xcconfig file.")
            return false
        }
        
        print("✅ Configuration validated successfully")
        return true
    }
    
    // MARK: - Environment Detection
    static var isProduction: Bool {
        return !isDebug
    }
    
    // MARK: - API Endpoints
    static var supabaseAPIURL: String {
        return "\(supabaseURL)/rest/v1"
    }
    
    static var supabaseRealtimeURL: String {
        return supabaseURL.replacingOccurrences(of: "https://", with: "wss://") + "/realtime/v1"
    }
}

// MARK: - Configuration Extensions

extension Config {
    /// Print current configuration (without sensitive data)
    static func printConfiguration() {
        print("🔧 Nuvora Configuration:")
        print("   App Version: \(appVersion) (\(buildNumber))")
        print("   Environment: \(isDebug ? "Debug" : "Production")")
        print("   Supabase URL: \(supabaseURL)")
        print("   Supabase Key: \(supabaseAnonKey.prefix(20))...")
        print("   Twilio SID: \(twilioAccountSID.prefix(10))...")
        print("   Configuration Valid: \(validateConfiguration())")
    }
}