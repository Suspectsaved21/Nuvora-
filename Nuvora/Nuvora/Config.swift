import Foundation

struct Config {
    // MARK: - Supabase Configuration
    static let supabaseURL = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String ?? "https://your-project-id.supabase.co"
    static let supabaseAnonKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String ?? "your-anon-key"
    
    // MARK: - Twilio Configuration (for SMS)
    static let twilioAccountSID = Bundle.main.object(forInfoDictionaryKey: "TWILIO_ACCOUNT_SID") as? String ?? "your-twilio-account-sid"
    static let twilioAuthToken = Bundle.main.object(forInfoDictionaryKey: "TWILIO_AUTH_TOKEN") as? String ?? "your-twilio-auth-token"
    static let twilioPhoneNumber = Bundle.main.object(forInfoDictionaryKey: "TWILIO_PHONE_NUMBER") as? String ?? "your-twilio-phone-number"
    
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
    
    // MARK: - Validation
    static func validateConfiguration() -> Bool {
        guard !supabaseURL.contains("your-project-id"),
              !supabaseAnonKey.contains("your-anon-key") else {
            print("⚠️ Warning: Supabase configuration not set. Please update your Info.plist with proper values.")
            return false
        }
        return true
    }
}