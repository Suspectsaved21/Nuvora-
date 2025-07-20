//
//  SupabaseManager.swift
//  Nuvora
//
//  Supabase client configuration and management
//

import Foundation
import Supabase

@MainActor
class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    
    private let supabase: SupabaseClient
    private var realtimeService: RealtimeService?
    
    private init() {
        // Initialize Supabase client
        guard let supabaseURL = URL(string: ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? ""),
              let supabaseKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] else {
            fatalError("Supabase configuration missing. Please set SUPABASE_URL and SUPABASE_ANON_KEY environment variables.")
        }
        
        self.supabase = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey,
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
                    reconnectDelayMs: 1000,
                    timeoutMs: 10000
                )
            )
        )
        
        // Listen for auth state changes
        Task {
            for await state in supabase.auth.authStateChanges {
                await handleAuthStateChange(state)
            }
        }
    }
    
    var client: SupabaseClient {
        return supabase
    }
    
    var realtime: RealtimeService? {
        return realtimeService
    }
    
    // MARK: - Authentication
    func signIn(email: String, password: String) async throws {
        try await supabase.auth.signIn(email: email, password: password)
    }
    
    func signUp(email: String, password: String) async throws {
        try await supabase.auth.signUp(email: email, password: password)
    }
    
    func signOut() async throws {
        // Disconnect realtime before signing out
        if let realtimeService = realtimeService {
            await realtimeService.disconnect()
            self.realtimeService = nil
        }
        
        try await supabase.auth.signOut()
    }
    
    func resetPassword(email: String) async throws {
        try await supabase.auth.resetPasswordForEmail(email)
    }
    
    // MARK: - Private Methods
    private func handleAuthStateChange(_ state: AuthChangeEvent) async {
        switch state {
        case .signedIn(let session):
            self.currentUser = session.user
            self.isAuthenticated = true
            await setupRealtimeService()
            
        case .signedOut:
            self.currentUser = nil
            self.isAuthenticated = false
            if let realtimeService = realtimeService {
                await realtimeService.disconnect()
                self.realtimeService = nil
            }
            
        case .passwordRecovery:
            break
            
        case .tokenRefreshed(let session):
            self.currentUser = session.user
            
        case .userUpdated(let user):
            self.currentUser = user
        }
    }
    
    private func setupRealtimeService() async {
        guard let user = currentUser else { return }
        
        // Disconnect existing service if any
        if let existingService = realtimeService {
            await existingService.disconnect()
        }
        
        // Create new realtime service
        realtimeService = RealtimeService(
            supabase: supabase,
            userId: user.id.uuidString,
            userEmail: user.email ?? ""
        )
        
        // Connect to realtime
        do {
            try await realtimeService?.connect()
        } catch {
            print("Failed to connect to realtime: \(error)")
        }
    }
}