//
//  ContentView.swift
//  Nuvora
//
//  Main app interface with navigation and realtime status
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var supabaseManager: SupabaseManager
    @State private var selectedTab = 0
    
    var body: some View {
        Group {
            if supabaseManager.isAuthenticated {
                MainTabView(selectedTab: $selectedTab)
            } else {
                AuthenticationView()
            }
        }
        .onAppear {
            // Any initial setup can go here
        }
    }
}

struct MainTabView: View {
    @Binding var selectedTab: Int
    @EnvironmentObject private var supabaseManager: SupabaseManager
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home/Dashboard
            DashboardView()
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
                .tag(0)
            
            // Chat
            NavigationView {
                ChatView(roomId: nil)
            }
            .tabItem {
                Image(systemName: "message")
                Text("Chat")
            }
            .tag(1)
            
            // Video Call
            VideoCallLobbyView()
                .tabItem {
                    Image(systemName: "video")
                    Text("Video")
                }
                .tag(2)
            
            // Profile
            ProfileView()
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
                .tag(3)
        }
        .overlay(
            // Realtime connection status indicator
            RealtimeStatusIndicator(),
            alignment: .topTrailing
        )
    }
}

struct DashboardView: View {
    @EnvironmentObject private var supabaseManager: SupabaseManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome back!")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if let user = supabaseManager.currentUser {
                            Text(user.email ?? "User")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Active users section
                    ActiveUsersSection()
                    
                    // Quick actions
                    QuickActionsSection()
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Nuvora")
        }
    }
}

struct ActiveUsersSection: View {
    @EnvironmentObject private var supabaseManager: SupabaseManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Users")
                .font(.headline)
            
            if let realtimeService = supabaseManager.realtime {
                if realtimeService.activeUsers.isEmpty {
                    Text("No other users online")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 150))
                    ], spacing: 12) {
                        ForEach(Array(realtimeService.activeUsers.values), id: \.userId) { user in
                            UserPresenceCard(user: user)
                        }
                    }
                }
            } else {
                Text("Connecting...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct UserPresenceCard: View {
    let user: UserPresence
    
    var body: some View {
        HStack {
            Circle()
                .fill(statusColor(for: user.status))
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(user.email.components(separatedBy: "@").first ?? "User")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(user.status.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    private func statusColor(for status: UserStatus) -> Color {
        switch status {
        case .online:
            return .green
        case .away:
            return .yellow
        case .busy:
            return .red
        case .offline:
            return .gray
        }
    }
}

struct QuickActionsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickActionButton(
                    title: "Start Video Call",
                    icon: "video.circle",
                    color: .blue
                ) {
                    // Navigate to video call
                }
                
                QuickActionButton(
                    title: "Open Chat",
                    icon: "message.circle",
                    color: .green
                ) {
                    // Navigate to chat
                }
                
                QuickActionButton(
                    title: "Share Screen",
                    icon: "rectangle.on.rectangle.circle",
                    color: .purple
                ) {
                    // Start screen sharing
                }
                
                QuickActionButton(
                    title: "Settings",
                    icon: "gear.circle",
                    color: .gray
                ) {
                    // Open settings
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct VideoCallLobbyView: View {
    @State private var roomId = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Join or Start a Video Call")
                    .font(.title2)
                    .fontWeight(.bold)
                
                TextField("Enter Room ID", text: $roomId)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                NavigationLink(
                    destination: VideoCallView(roomId: roomId.isEmpty ? UUID().uuidString : roomId)
                ) {
                    Text(roomId.isEmpty ? "Start New Call" : "Join Call")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Video Call")
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject private var supabaseManager: SupabaseManager
    @State private var showingSignOutAlert = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    if let user = supabaseManager.currentUser {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.title)
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading) {
                                Text(user.email ?? "User")
                                    .font(.headline)
                                
                                Text("ID: \(user.id.uuidString.prefix(8))...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section("Status") {
                    StatusSelectionView()
                }
                
                Section("Settings") {
                    Label("Notifications", systemImage: "bell")
                    Label("Privacy", systemImage: "lock")
                    Label("Help & Support", systemImage: "questionmark.circle")
                }
                
                Section {
                    Button("Sign Out") {
                        showingSignOutAlert = true
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Profile")
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    Task {
                        try? await supabaseManager.signOut()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
}

struct StatusSelectionView: View {
    @EnvironmentObject private var supabaseManager: SupabaseManager
    @State private var selectedStatus: UserStatus = .online
    
    var body: some View {
        Picker("Status", selection: $selectedStatus) {
            ForEach(UserStatus.allCases, id: \.self) { status in
                HStack {
                    Circle()
                        .fill(statusColor(for: status))
                        .frame(width: 12, height: 12)
                    Text(status.rawValue.capitalized)
                }
                .tag(status)
            }
        }
        .pickerStyle(MenuPickerStyle())
        .onChange(of: selectedStatus) { newStatus in
            Task {
                try? await supabaseManager.realtime?.updateUserStatus(newStatus)
            }
        }
    }
    
    private func statusColor(for status: UserStatus) -> Color {
        switch status {
        case .online: return .green
        case .away: return .yellow
        case .busy: return .red
        case .offline: return .gray
        }
    }
}

struct RealtimeStatusIndicator: View {
    @EnvironmentObject private var supabaseManager: SupabaseManager
    
    var body: some View {
        if let realtimeService = supabaseManager.realtime {
            HStack(spacing: 4) {
                Circle()
                    .fill(realtimeService.isConnected ? .green : .red)
                    .frame(width: 8, height: 8)
                
                Text(realtimeService.isConnected ? "Connected" : "Disconnected")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
            .padding()
        }
    }
}

struct AuthenticationView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    @EnvironmentObject private var supabaseManager: SupabaseManager
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Nuvora")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Social Video Chat")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 16) {
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                Button(action: authenticate) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(isSignUp ? "Sign Up" : "Sign In")
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
                .disabled(isLoading || email.isEmpty || password.isEmpty)
                
                Button(action: { isSignUp.toggle() }) {
                    Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            
            Spacer()
        }
        .padding()
    }
    
    private func authenticate() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                if isSignUp {
                    try await supabaseManager.signUp(email: email, password: password)
                } else {
                    try await supabaseManager.signIn(email: email, password: password)
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SupabaseManager.shared)
}