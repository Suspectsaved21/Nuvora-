# Nuvora - Real-time Social Rooms App

Nuvora is a modern iOS SwiftUI application that enables users to create and join real-time social rooms with different moods and live presence tracking. Built with Supabase for backend services and real-time functionality.

## Features

### 🔐 Authentication
- Phone number + SMS OTP authentication
- Secure session management
- Auto-refresh tokens
- Keychain integration for secure storage

### 🏠 Room Management
- Create custom rooms with different moods
- Join/leave rooms with real-time participant tracking
- Room search and filtering capabilities
- Mood-based room categorization
- Private and public room support

### 🎭 Room Moods
- **😌 Chill**: Relax and unwind
- **🔥 Hype**: High energy vibes
- **📚 Study**: Focus and productivity
- **🎤 Karaoke**: Sing and have fun

### 🌐 Real-time Features
- Live presence tracking
- Real-time participant updates
- Mood changes in real-time
- Custom room events
- WebSocket-based communication

### 🎨 Modern UI/UX
- SwiftUI-based interface
- Responsive design for all iOS devices
- Dark/Light mode support
- Smooth animations and transitions
- Confetti effects for celebrations

## Architecture

### 📱 App Structure
```
Nuvora/
├── App/
│   └── NuvoraApp.swift          # App entry point
├── Models/
│   └── Room.swift               # Room data models
├── Views/
│   ├── Auth/                    # Authentication views
│   │   ├── LoginView.swift
│   │   ├── PhoneInputView.swift
│   │   └── OTPVerificationView.swift
│   └── CreateRoomDialog.swift   # Room creation UI
├── ViewModels/
│   ├── AuthViewModel.swift      # Authentication logic
│   └── RoomViewModel.swift      # Room management logic
├── Services/
│   ├── SupabaseManager.swift    # Supabase client management
│   ├── AuthService.swift        # Authentication service
│   ├── RealtimeService.swift    # Real-time functionality
│   ├── RoomService.swift        # Room CRUD operations
│   └── LivePresenceManager.swift # Presence tracking
├── Extensions/
│   └── String+Extensions.swift  # Utility extensions
└── Resources/
    └── Assets.xcassets          # App assets
```

### 🏗️ Service Architecture
- **SupabaseManager**: Central Supabase client management
- **AuthService**: Handles authentication flow and session management
- **RoomService**: Manages room CRUD operations with real-time updates
- **RealtimeService**: WebSocket connections and real-time events
- **LivePresenceManager**: User presence tracking in rooms

## Setup Instructions

### Prerequisites
- Xcode 15.0+
- iOS 17.0+
- Swift 5.9+
- Supabase account

### 1. Clone the Repository
```bash
git clone https://github.com/Suspectsaved21/Nuvora-.git
cd Nuvora
```

### 2. Configure Supabase
1. Create a new project at [supabase.com](https://supabase.com)
2. Copy the example configuration:
   ```bash
   cp Config.example.xcconfig Config.xcconfig
   ```
3. Update `Config.xcconfig` with your Supabase credentials:
   ```
   SUPABASE_URL = https://your-project-id.supabase.co
   SUPABASE_ANON_KEY = your-supabase-anon-key
   ```

### 3. Database Setup
Create the following table in your Supabase database:

```sql
-- Create rooms table
CREATE TABLE rooms (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    participants INTEGER DEFAULT 0,
    max_participants INTEGER DEFAULT 10,
    is_private BOOLEAN DEFAULT false,
    mood TEXT NOT NULL,
    description TEXT,
    tags TEXT[],
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE rooms ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Anyone can view public rooms" ON rooms
    FOR SELECT USING (NOT is_private);

CREATE POLICY "Users can create rooms" ON rooms
    FOR INSERT WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update their own rooms" ON rooms
    FOR UPDATE USING (auth.uid() = created_by);

CREATE POLICY "Users can delete their own rooms" ON rooms
    FOR DELETE USING (auth.uid() = created_by);

-- Enable real-time
ALTER PUBLICATION supabase_realtime ADD TABLE rooms;
```

### 4. Authentication Setup
1. Enable Phone authentication in Supabase Dashboard
2. Configure your SMS provider (Twilio recommended)
3. Update phone authentication settings

### 5. Build and Run
1. Open `Nuvora.xcodeproj` in Xcode
2. Select your target device/simulator
3. Build and run the project (⌘+R)

## Configuration

### Environment Variables
The app uses `Info.plist` for configuration. Key variables:

- `SUPABASE_URL`: Your Supabase project URL
- `SUPABASE_ANON_KEY`: Your Supabase anonymous key
- `TWILIO_ACCOUNT_SID`: Twilio account SID (optional)
- `TWILIO_AUTH_TOKEN`: Twilio auth token (optional)
- `TWILIO_PHONE_NUMBER`: Twilio phone number (optional)

### Security
- All sensitive configuration is stored in `Config.xcconfig` (gitignored)
- API keys are loaded from `Info.plist` at runtime
- No hardcoded credentials in source code
- Secure keychain storage for user sessions

## Development

### Package Dependencies
- **Supabase Swift SDK 2.8.0+**: Backend services
  - Auth: Authentication
  - Realtime: WebSocket connections
  - PostgREST: Database operations
  - Storage: File storage (if needed)
  - Functions: Edge functions (if needed)

### Key Features Implementation

#### Authentication Flow
1. User enters phone number
2. OTP sent via SMS
3. User verifies OTP
4. Session created and stored securely
5. Auto-refresh on app launch

#### Room Management
1. Create room with mood and settings
2. Real-time participant tracking
3. Live presence updates
4. Mood changes broadcast to all participants
5. Automatic cleanup on user disconnect

#### Real-time Features
- WebSocket connection management
- Presence tracking with heartbeat
- Custom event broadcasting
- Connection recovery and retry logic

### Testing
```bash
# Run tests
xcodebuild test -scheme Nuvora -destination 'platform=iOS Simulator,name=iPhone 15'

# Build for device
xcodebuild -scheme Nuvora -destination 'generic/platform=iOS' build
```

## Deployment

### App Store Preparation
1. Update version numbers in `Info.plist`
2. Configure signing certificates
3. Build for release
4. Upload to App Store Connect

### Backend Deployment
- Supabase handles backend infrastructure
- Configure production environment variables
- Set up monitoring and analytics

## Contributing

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

## Troubleshooting

### Common Issues

#### Build Errors
- Ensure Xcode 15.0+ is installed
- Clean build folder (⌘+Shift+K)
- Reset package cache
- Check Swift Package Manager dependencies

#### Authentication Issues
- Verify Supabase configuration
- Check phone number format (E.164)
- Ensure SMS provider is configured
- Check network connectivity

#### Real-time Connection Issues
- Verify WebSocket connectivity
- Check Supabase real-time settings
- Ensure proper authentication
- Monitor connection logs

### Debug Logging
Enable debug logging by setting:
```swift
// In Config.swift
static let isDebug = true
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Create an issue on GitHub
- Check the documentation
- Review Supabase documentation

## Acknowledgments

- [Supabase](https://supabase.com) for backend services
- [SwiftUI](https://developer.apple.com/xcode/swiftui/) for the UI framework
- The iOS development community

---

**Built with ❤️ using SwiftUI and Supabase**