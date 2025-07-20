import Foundation
import Supabase

/// Enhanced SupabaseManager with comprehensive error handling and logging
class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    private(set) var client: SupabaseClient?
    
    @Published var isInitialized: Bool = false
    @Published var initializationError: String?
    
    private init() {
        initialize()
    }
    
    func initialize() {
        guard client == nil else { 
            print("⚠️ SupabaseManager already initialized")
            return 
        }
        
        // Validate configuration
        guard Config.validateConfiguration() else {
            let error = "❌ Failed to initialize Supabase: Invalid configuration"
            print(error)
            DispatchQueue.main.async {
                self.initializationError = error
                self.isInitialized = false
            }
            return
        }
        
        guard let url = URL(string: Config.supabaseURL) else {
            let error = "❌ Failed to initialize Supabase: Invalid URL"
            print(error)
            DispatchQueue.main.async {
                self.initializationError = error
                self.isInitialized = false
            }
            return
        }
        
        do {
            client = SupabaseClient(
                supabaseURL: url,
                supabaseKey: Config.supabaseAnonKey,
                options: SupabaseClientOptions(
                    db: SupabaseClientOptions.DatabaseOptions(
                        schema: "public"
                    ),
                    auth: SupabaseClientOptions.AuthOptions(
                        autoRefreshToken: true,
                        persistSession: true,
                        detectSessionInUrl: false
                    ),
                    realtime: SupabaseClientOptions.RealtimeOptions(
                        heartbeatIntervalMs: 30000,
                        reconnectAfterMs: { tries in
                            return min(tries * 1000, 10000)
                        }
                    )
                )
            )
            
            DispatchQueue.main.async {
                self.isInitialized = true
                self.initializationError = nil
            }
            
            print("✅ Supabase initialized successfully")
            
            // Setup auth state listener
            setupAuthStateListener()
            
        } catch {
            let errorMessage = "❌ Failed to initialize Supabase: \(error.localizedDescription)"
            print(errorMessage)
            DispatchQueue.main.async {
                self.initializationError = errorMessage
                self.isInitialized = false
            }
        }
    }
    
    private func setupAuthStateListener() {
        guard let client = client else { return }
        
        Task {
            for await state in client.auth.authStateChanges {
                print("🔐 Auth state changed: \(state.event)")
                
                switch state.event {
                case .signedIn:
                    if let user = state.session?.user {
                        print("✅ User signed in: \(user.id)")
                    }
                case .signedOut:
                    print("👋 User signed out")
                case .tokenRefreshed:
                    print("🔄 Token refreshed")
                default:
                    break
                }
            }
        }
    }
    
    // MARK: - Convenience Methods
    
    var auth: AuthClient? {
        return client?.auth
    }
    
    var database: PostgrestClient? {
        return client?.database
    }
    
    var realtime: RealtimeClient? {
        return client?.realtime
    }
    
    var storage: StorageClient? {
        return client?.storage
    }
    
    // MARK: - Health Check
    
    func healthCheck() async -> Bool {
        guard let client = client else {
            print("❌ Health check failed: Client not initialized")
            return false
        }
        
        do {
            // Simple database query to check connectivity
            let _: [String: Any] = try await client.database
                .from("health_check")
                .select("*")
                .limit(1)
                .execute()
                .value
            
            print("✅ Supabase health check passed")
            return true
        } catch {
            print("❌ Supabase health check failed: \(error.localizedDescription)")
            return false
        }
    }
}