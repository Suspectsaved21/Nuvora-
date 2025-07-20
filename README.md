# Nuvora - Social Video Chat iOS App

A modern iOS application for social video chatting with real-time communication features.

## 🚀 Features

- **Phone Authentication**: SMS-based OTP verification using Supabase + Twilio
- **Real-time Video Calls**: High-quality video communication
- **Chat Rooms**: Create and join video chat rooms
- **Social Features**: Connect with friends and discover new people
- **Modern UI**: SwiftUI-based interface with smooth animations

## 📱 Requirements

- iOS 15.0+
- Xcode 14.0+
- Swift 5.7+

## 🛠 Setup Instructions

### 1. Clone the Repository
```bash
git clone https://github.com/Suspectsaved21/Nuvora-.git
cd Nuvora
```

### 2. Install Dependencies
The project uses Swift Package Manager. Dependencies will be automatically resolved when you open the project in Xcode.

### 3. Configure Credentials
**Important**: You need to set up credentials to run the app.

#### Option A: Quick Setup (Recommended)
See [SETUP_CREDENTIALS.md](SETUP_CREDENTIALS.md) for detailed instructions with the provided credentials.

#### Option B: Use Your Own Credentials
1. Create a `Config.xcconfig` file in the root directory
2. Add your Supabase and Twilio credentials
3. Link the config file in Xcode build settings

### 4. Build and Run
1. Open `Nuvora.xcodeproj` in Xcode
2. Select your target device or simulator
3. Press `Cmd + R` to build and run

## 🔧 Architecture

### Core Services
- **SupabaseManager**: Database and authentication backend
- **EnhancedAuthService**: Phone authentication with OTP
- **TwilioService**: SMS delivery service
- **RealtimeService**: Real-time communication handling

### Key Components
- **Config.swift**: Centralized configuration management
- **Info.plist**: iOS permissions and app settings
- **ContentView**: Main app interface
- **VideoCallView**: Video calling interface
- **ChatView**: Text messaging interface

## 🔐 Security

### Development vs Production
- **Current Status**: ✅ Secure credential management via Config.xcconfig
- **Production**: Requires moving credentials to iOS Keychain (see [SECURITY.md](SECURITY.md))

### Security Features
- OTP expiration (10 minutes)
- Rate limiting (3 attempts max)
- Session management
- TLS 1.2+ enforcement
- App Transport Security enabled
- Secure credential management

## 📋 iOS Permissions

The app requests the following permissions:
- **Camera**: For video calls and photo sharing
- **Microphone**: For voice and video calls
- **Photo Library**: For sharing images in rooms
- **Contacts**: For finding friends (optional)
- **Location**: For nearby rooms feature (optional)

## 🔄 Authentication Flow

1. **Phone Entry**: User enters phone number
2. **OTP Delivery**: SMS sent via Twilio + Supabase
3. **Verification**: User enters 6-digit code
4. **Session Creation**: Secure session established
5. **App Access**: Full app functionality unlocked

## 🎯 Key Features Implementation

### Real-time Communication
- WebRTC for video calls
- Supabase Realtime for instant messaging
- Background audio support for VoIP

### User Experience
- Smooth onboarding flow
- Intuitive room creation/joining
- Modern SwiftUI interface
- Responsive design for all iPhone sizes

## 🚀 Deployment

### Development
The app is ready to run in development mode with secure credential management.

### Production Checklist
Before App Store submission:
- [ ] Move credentials to Keychain (see SECURITY.md)
- [ ] Configure production Supabase environment
- [ ] Set up proper error tracking
- [ ] Implement analytics
- [ ] Add App Store metadata

## 📚 Dependencies

- **Supabase Swift**: Backend services and authentication
- **WebRTC**: Video calling functionality
- **Foundation**: Core iOS frameworks
- **SwiftUI**: Modern UI framework
- **Combine**: Reactive programming

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For technical support or questions:
- Check the [SETUP_CREDENTIALS.md](SETUP_CREDENTIALS.md) for credential setup
- Review the [SECURITY.md](SECURITY.md) for security-related questions
- Review the setup instructions above
- Contact the development team

## 🔄 Recent Updates

### v1.0.0 (July 2025)
- ✅ Complete iOS configuration with secure credential management
- ✅ Supabase integration ready for development
- ✅ Twilio SMS authentication service
- ✅ Enhanced security features and documentation
- ✅ Production-ready architecture
- ✅ Comprehensive setup and security documentation

---

**Built with ❤️ for seamless social video communication**