# Nuvora - Social Video Chat App

A modern iOS social video chat application built with SwiftUI and Supabase, featuring real-time presence management, video calling, and chat functionality.

## Features

- **Real-time Presence**: Track online users with live status updates
- **Video Calling**: Multi-participant video calls with camera/microphone controls
- **Real-time Chat**: Instant messaging with live message delivery
- **User Authentication**: Secure sign-up and sign-in with Supabase Auth
- **Modern UI**: Clean SwiftUI interface optimized for iOS 16+

## Architecture

### Supabase Integration
- **RealtimeChannelV2**: Modern realtime channel management
- **PresenceV2**: Advanced presence tracking with CRDT-backed state
- **Auth**: Secure user authentication and session management
- **Database**: PostgreSQL with real-time subscriptions

### Key Components

#### RealtimeService
The core service managing all real-time functionality:
- Connection management with automatic reconnection
- Presence tracking for user status and video call participants
- Real-time chat message handling
- Video call event broadcasting

#### SupabaseManager
Centralized Supabase client management:
- Authentication state handling
- Automatic realtime service initialization
- Session persistence and token refresh

#### UI Components
- **ContentView**: Main app navigation and authentication flow
- **VideoCallView**: Multi-participant video call interface
- **ChatView**: Real-time messaging interface
- **DashboardView**: User presence and quick actions

## Fixed Issues

### Xcode Target Configuration
This version resolves the "target 'Nuvora' referenced in product 'Nuvora' is empty" error by:
- Properly configuring the project.pbxproj file
- Ensuring all Swift source files are correctly linked to the target
- Setting up proper build phases and dependencies
- Configuring correct file references and build settings

## Requirements

- iOS 16.0+
- Xcode 15.0+
- Swift 5.9+
- Supabase project with Realtime enabled

## Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/Suspectsaved21/Nuvora-.git
   cd Nuvora-
   ```

2. **Configure Supabase**
   - Create a new Supabase project
   - Enable Realtime in your project settings
   - Set up the following environment variables:
     ```
     SUPABASE_URL=https://your-project.supabase.co
     SUPABASE_ANON_KEY=your-anon-key
     ```

3. **Database Schema**
   Create the following tables in your Supabase database:
   
   ```sql
   -- Chat messages table
   CREATE TABLE chat_messages (
       id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
       content TEXT NOT NULL,
       sender_id UUID NOT NULL,
       room_id TEXT,
       created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
       updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
   );
   
   -- Enable realtime for chat messages
   ALTER PUBLICATION supabase_realtime ADD TABLE chat_messages;
   ```

4. **Install Dependencies**
   The project uses Swift Package Manager. Dependencies will be resolved automatically when you open the project in Xcode.

5. **Build and Run**
   Open `Nuvora.xcodeproj` in Xcode and run the project.

## Usage

### Authentication
Users can sign up or sign in using email and password. The app automatically manages session persistence and token refresh.

### Presence Tracking
- Users are automatically tracked as online when authenticated
- Status can be updated (online, away, busy, offline)
- Real-time updates show other users' presence status

### Video Calling
- Start a new call or join an existing room
- Real-time participant tracking
- Camera, microphone, and screen sharing controls
- Automatic presence management for call participants

### Chat
- Real-time messaging with instant delivery
- Support for room-based conversations
- Message history and timestamps

## Project Structure

```
Nuvora/
├── Nuvora.xcodeproj/          # Xcode project configuration
│   ├── project.pbxproj         # Fixed project configuration
│   └── project.xcworkspace/    # Workspace settings
├── Nuvora/                     # Source code
│   ├── NuvoraApp.swift        # App entry point
│   ├── ContentView.swift      # Main UI and navigation
│   ├── ChatView.swift         # Chat interface
│   ├── VideoCallView.swift    # Video call interface
│   ├── RealtimeService.swift  # Supabase realtime integration
│   ├── SupabaseManager.swift  # Supabase client management
│   └── Assets.xcassets/       # App assets and icons
├── Package.swift              # Swift Package Manager
└── README.md                  # This file
```

## Error Handling

The app includes comprehensive error handling for:
- Network connectivity issues
- Authentication failures
- Realtime connection problems
- Database operation errors

## Performance Considerations

- Efficient presence state management
- Automatic reconnection with exponential backoff
- Memory-efficient message handling
- Optimized UI updates with @MainActor

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:
- Check the [Supabase Swift SDK documentation](https://github.com/supabase/supabase-swift)
- Open an issue in this repository
- Review the setup instructions in SETUP_INSTRUCTIONS.md