//
//  NuvoraApp.swift
//  Nuvora
//
//  Main app entry point with Supabase configuration
//

import SwiftUI

@main
struct NuvoraApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(SupabaseManager.shared)
        }
    }
}