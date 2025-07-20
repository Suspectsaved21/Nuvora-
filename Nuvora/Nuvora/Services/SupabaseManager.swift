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
        client = SupabaseClient(
            supabaseURL: URL(string: "https://your-project-id.supabase.co")!,
            supabaseKey: "your-anon-or-service-role-key"
        )
    }
}

