# Nuvora - Real-time Social Video Chat App

Nuvora is a modern iOS SwiftUI application that enables users to create and join real-time video chat rooms with seamless communication features. Built with Supabase for backend services and WebRTC for video calling.

## 🚀 Features

### 📱 Core Functionality
- **Real-time Video Calls**: High-quality video communication using WebRTC
- **Room Management**: Create and join video chat rooms
- **Live Chat**: Text messaging during video calls
- **User Authentication**: Secure sign-in and account management
- **Real-time Presence**: See who's online and in rooms

### 🎯 Key Highlights
- **Supabase V2 Integration**: Latest Supabase Realtime APIs
- **Swift Concurrency**: Modern async/await patterns throughout
- **WebRTC Support**: Native video calling capabilities
- **Responsive UI**: SwiftUI-based interface with smooth animations
- **Real-time Updates**: Live participant tracking and messaging

## 🏗️ Architecture

### Project Structure
```
Nuvora/
├── NuvoraApp.swift          # App entry point
├── ContentView.swift        # Main app interface
├── VideoCallView.swift      # Video calling interface
├── ChatView.swift           # Real-time chat
├── SupabaseManager.swift    # Backend integration
├── RealtimeService.swift    # Real-time functionality
└── Package.swift            # Swift Package dependencies
```

### 🔧 Technical Stack
- **Frontend**: SwiftUI, iOS 17+
- **Backend**: Supabase (Database, Auth, Realtime)
- **Video**: WebRTC for peer-to-peer communication
- **Real-time**: Supabase Realtime V2 with WebSocket connections
- **Concurrency**: Swift async/await patterns

## 📋 Recent Updates

### Supabase V2 Migration
- ✅ Updated to latest Supabase Realtime APIs
- ✅ Improved connection management and error handling
- ✅ Enhanced presence tracking with heartbeat system
- ✅ Better reconnection logic for network interruptions

### Architecture Improvements
- ✅ Streamlined project structure
- ✅ Consolidated services for better maintainability
- ✅ Modern Swift concurrency patterns
- ✅ Improved error handling throughout the app

### Enhanced Features
- ✅ Real-time video calling with WebRTC
- ✅ Live chat during video calls
- ✅ Participant management and presence tracking
- ✅ Connection status indicators
- ✅ Responsive UI with smooth animations

## 🛠️ Setup Instructions

### Prerequisites
- Xcode 15.0+
- iOS 17.0+
- Swift 5.9+
- Supabase account

### 1. Clone the Repository
```bash
git clone https://github.com/Suspectsaved21/Nuvora-.git
cd Nuvora-
```

### 2. Configure Supabase
1. Create a new project at [supabase.com](https://supabase.com)
2. Update `SupabaseManager.swift` with your credentials:
   ```swift
   guard let url = URL(string: "https://your-project-id.supabase.co"),
         let anonKey = "your-supabase-anon-key" as String? else {
       fatalError("Missing Supabase configuration")
   }
   ```

### 3. Database Setup
Create the following tables in your Supabase database:

```sql
-- Rooms table
CREATE TABLE rooms (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    max_participants INTEGER DEFAULT 10,
    is_private BOOLEAN DEFAULT false
);

-- Messages table
CREATE TABLE messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    room_id UUID REFERENCES rooms(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id),
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Room participants table
CREATE TABLE room_participants (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    room_id UUID REFERENCES rooms(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id),
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE room_participants ENABLE ROW LEVEL SECURITY;

-- Enable real-time
ALTER PUBLICATION supabase_realtime ADD TABLE rooms;
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
ALTER PUBLICATION supabase_realtime ADD TABLE room_participants;
```

### 4. Build and Run
1. Open the project in Xcode
2. Select your target device/simulator
3. Build and run the project (⌘+R)

## 🎮 Usage

### Getting Started
1. **Sign In**: Use the demo credentials or create an account
2. **Browse Rooms**: View available video chat rooms
3. **Create Room**: Start your own video chat room
4. **Join Calls**: Enter video calls with other participants
5. **Chat**: Send messages during video calls

### Video Calling
- **Join Room**: Tap "Join" on any room card
- **Controls**: Mute/unmute, enable/disable video, end call
- **Chat**: Access live chat during calls
- **Participants**: See all participants in the call

## 🔧 Development

### Key Components

#### SupabaseManager
- Centralized Supabase client management
- Authentication handling
- Database operations (CRUD for rooms, messages)
- Real-time subscriptions

#### RealtimeService
- WebSocket connection management
- Real-time event handling
- Presence tracking
- Message broadcasting

#### VideoCallView
- WebRTC integration
- Video call interface
- Participant management
- Call controls

### Swift Concurrency
The app uses modern Swift concurrency patterns:

```swift
// Async/await for database operations
func loadRooms() async {
    do {
        let rooms = try await supabaseManager.fetchRooms()
        await MainActor.run {
            self.rooms = rooms
        }
    } catch {
        print("Error: \(error)")
    }
}

// MainActor for UI updates
@MainActor
class SupabaseManager: ObservableObject {
    // UI-safe operations
}
```

## 🚀 Deployment

### App Store Preparation
1. Update version numbers
2. Configure signing certificates
3. Build for release
4. Upload to App Store Connect

### Backend Configuration
- Configure Supabase production environment
- Set up proper RLS policies
- Configure authentication providers
- Set up monitoring and analytics

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

### Code Style
- Follow Swift naming conventions
- Use SwiftUI best practices
- Document public APIs
- Write meaningful commit messages
- Use @MainActor for UI-related classes

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and questions:
- Create an issue on GitHub
- Check the documentation
- Review the setup instructions

---

**Nuvora** - Connecting people through real-time video experiences 🎥✨
