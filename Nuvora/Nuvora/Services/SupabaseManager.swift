import Foundation
import Supabase

class SupabaseManager {
    static let shared = SupabaseManager()

    private(set) var client: SupabaseClient?

    var isInitialized: Bool {
        client != nil
    }

    func initialize() {
        guard client == nil else { return } // Prevent double initialization
        
        // Validate configuration
        guard Config.validateConfiguration() else {
            print("❌ Failed to initialize Supabase: Invalid configuration")
            return
        }
        
        guard let url = URL(string: Config.supabaseURL) else {
            print("❌ Failed to initialize Supabase: Invalid URL")
            return
        }
        
        client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: Config.supabaseAnonKey
        )
        
        print("✅ Supabase initialized successfully")
    }
}