import SwiftUI
import Supabase

struct ContentView: View {
    @StateObject private var supabaseManager = SupabaseManager.shared
    @StateObject private var realtimeService = RealtimeService.shared
    @State private var rooms: [Room] = []
    @State private var isLoading = false
    @State private var showingCreateRoom = false
    @State private var selectedRoom: Room?
    @State private var showingVideoCall = false
    @State private var connectionStatus: ConnectionStatus = .disconnected
    
    var body: some View {
        NavigationView {
            VStack {
                // Connection Status Banner
                if connectionStatus != .connected {
                    ConnectionStatusBanner(status: connectionStatus)
                }
                
                // Main Content
                if supabaseManager.isSignedIn {
                    roomsView
                } else {
                    authView
                }
            }
            .navigationTitle("Nuvora")
            .onAppear {
                setupRealtimeConnection()
            }
        }
    }
    
    private var authView: some View {
        VStack(spacing: 20) {
            Image(systemName: "video.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Welcome to Nuvora")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Connect with friends in real-time video rooms")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 12) {
                Button("Sign In") {
                    signInDemo()
                }
                .buttonStyle(PrimaryButtonStyle())
                
                Button("Create Account") {
                    signUpDemo()
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .padding(.top, 20)
        }
        .padding()
    }
    
    private var roomsView: some View {
        VStack {
            // Header with Create Room Button
            HStack {
                Text("Active Rooms")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { showingCreateRoom = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            // Rooms List
            if isLoading {
                ProgressView("Loading rooms...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if rooms.isEmpty {
                emptyRoomsView
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(rooms) { room in
                            RoomCard(room: room) {
                                joinRoom(room)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .refreshable {
            await loadRooms()
        }
        .onAppear {
            Task {
                await loadRooms()
            }
        }
        .sheet(isPresented: $showingCreateRoom) {
            CreateRoomView { room in
                Task {
                    await createRoom(room)
                }
            }
        }
        .fullScreenCover(item: $selectedRoom) { room in
            VideoCallView(room: room) {
                selectedRoom = nil
            }
        }
    }
    
    private var emptyRoomsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Active Rooms")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create a room to start connecting with friends")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Create First Room") {
                showingCreateRoom = true
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Functions
    
    private func setupRealtimeConnection() {
        realtimeService.onConnectionStatusChanged = { status in
            Task { @MainActor in
                connectionStatus = status
            }
        }
        
        Task {
            await realtimeService.connect()
        }
    }
    
    private func signInDemo() {
        Task {
            do {
                try await supabaseManager.signIn(email: "demo@nuvora.app", password: "demo123")
            } catch {
                print("Sign in error: \(error)")
            }
        }
    }
    
    private func signUpDemo() {
        Task {
            do {
                try await supabaseManager.signUp(email: "demo@nuvora.app", password: "demo123")
            } catch {
                print("Sign up error: \(error)")
            }
        }
    }
    
    private func loadRooms() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let fetchedRooms = try await supabaseManager.fetchRooms()
            await MainActor.run {
                self.rooms = fetchedRooms
            }
        } catch {
            print("Error loading rooms: \(error)")
        }
    }
    
    private func createRoom(_ room: Room) async {
        do {
            let createdRoom = try await supabaseManager.createRoom(room)
            await MainActor.run {
                rooms.insert(createdRoom, at: 0)
                showingCreateRoom = false
            }
        } catch {
            print("Error creating room: \(error)")
        }
    }
    
    private func joinRoom(_ room: Room) {
        selectedRoom = room
        
        Task {
            do {
                if let userId = supabaseManager.currentUser?.id.uuidString {
                    try await supabaseManager.joinRoom(roomId: room.id, userId: userId)
                }
            } catch {
                print("Error joining room: \(error)")
            }
        }
    }
}

// MARK: - Supporting Views

struct ConnectionStatusBanner: View {
    let status: ConnectionStatus
    
    var body: some View {
        HStack {
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)
            
            Text(status.description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
    }
}

struct RoomCard: View {
    let room: Room
    let onJoin: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(room.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if let description = room.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                VStack {
                    Image(systemName: room.isPrivate ? "lock.fill" : "globe")
                        .foregroundColor(room.isPrivate ? .orange : .green)
                    
                    Text("\(0)/\(room.maxParticipants)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Text("Created \(room.createdAt, style: .relative) ago")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Join") {
                    onJoin()
                }
                .buttonStyle(PrimaryButtonStyle(size: .small))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
        )
    }
}

struct CreateRoomView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var roomName = ""
    @State private var roomDescription = ""
    @State private var maxParticipants = 10
    @State private var isPrivate = false
    
    let onCreate: (Room) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section("Room Details") {
                    TextField("Room Name", text: $roomName)
                    TextField("Description (Optional)", text: $roomDescription, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Settings") {
                    Stepper("Max Participants: \(maxParticipants)", value: $maxParticipants, in: 2...50)
                    Toggle("Private Room", isOn: $isPrivate)
                }
            }
            .navigationTitle("Create Room")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createRoom()
                    }
                    .disabled(roomName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func createRoom() {
        let room = Room(
            id: UUID().uuidString,
            name: roomName.trimmingCharacters(in: .whitespacesAndNewlines),
            description: roomDescription.isEmpty ? nil : roomDescription,
            createdBy: SupabaseManager.shared.currentUser?.id.uuidString ?? "unknown",
            createdAt: Date(),
            maxParticipants: maxParticipants,
            isPrivate: isPrivate
        )
        
        onCreate(room)
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    enum Size {
        case normal, small
        
        var padding: EdgeInsets {
            switch self {
            case .normal:
                return EdgeInsets(top: 12, leading: 24, bottom: 12, trailing: 24)
            case .small:
                return EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
            }
        }
        
        var font: Font {
            switch self {
            case .normal:
                return .headline
            case .small:
                return .subheadline
            }
        }
    }
    
    let size: Size
    
    init(size: Size = .normal) {
        self.size = size
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(size.font)
            .foregroundColor(.white)
            .padding(size.padding)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue)
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.blue)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.blue, lineWidth: 2)
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Connection Status

enum ConnectionStatus {
    case connected
    case connecting
    case disconnected
    case error
    
    var description: String {
        switch self {
        case .connected:
            return "Connected"
        case .connecting:
            return "Connecting..."
        case .disconnected:
            return "Disconnected"
        case .error:
            return "Connection Error"
        }
    }
    
    var color: Color {
        switch self {
        case .connected:
            return .green
        case .connecting:
            return .orange
        case .disconnected:
            return .gray
        case .error:
            return .red
        }
    }
}

#Preview {
    ContentView()
}
