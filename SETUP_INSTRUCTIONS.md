# 🚀 Nuvora iOS App - Setup & Testing Instructions

## 📱 Overview
Nuvora is a Houseparty-like social iOS app built with SwiftUI, featuring real-time rooms, SMS phone authentication, and live presence management. The app uses Supabase as the backend and supports Twilio for SMS authentication.

## ✅ Repository Status
- ✅ **Main branch ready** - All fixes merged successfully
- ✅ **Xcode project configured** - Ready for immediate development
- ✅ **Production-ready code** - All critical bugs fixed
- ✅ **SMS Authentication** - Complete phone auth system
- ✅ **Environment configuration** - Centralized config management

## 🛠 Prerequisites
- **Xcode 15.0+** (iOS 15.0+ deployment target)
- **macOS Monterey 12.0+**
- **Active Apple Developer Account** (for device testing)
- **Supabase Project** (for backend services)
- **Twilio Account** (for SMS authentication)

## 📥 Quick Start Guide

### 1. Clone the Repository
```bash
git clone https://github.com/Suspectsaved21/Nuvora-.git
cd Nuvora-
```

### 2. Open in Xcode
```bash
# Open the Xcode project
open Nuvora/Nuvora.xcodeproj
```

### 3. Configure Environment Variables
Edit `Nuvora/Nuvora/Info.plist` and replace the placeholder values:

```xml
<!-- Supabase Configuration -->
<key>SUPABASE_URL</key>
<string>https://your-actual-project-id.supabase.co</string>
<key>SUPABASE_ANON_KEY</key>
<string>your-actual-supabase-anon-key</string>

<!-- Twilio Configuration (for SMS) -->
<key>TWILIO_ACCOUNT_SID</key>
<string>your-actual-twilio-account-sid</string>
<key>TWILIO_AUTH_TOKEN</key>
<string>your-actual-twilio-auth-token</string>
<key>TWILIO_PHONE_NUMBER</key>
<string>your-actual-twilio-phone-number</string>
```

### 4. Build and Run
1. **Select Target**: Choose "Nuvora" scheme in Xcode
2. **Select Simulator**: Pick iPhone 15 Pro or your preferred simulator
3. **Build**: Press `Cmd + B` to build the project
4. **Run**: Press `Cmd + R` to run on simulator

## 🔧 Backend Setup

### Supabase Configuration
1. **Create Supabase Project**: Visit [supabase.com](https://supabase.com)
2. **Get Project URL**: Found in Project Settings → API
3. **Get Anon Key**: Found in Project Settings → API
4. **Database Schema**: The app expects these tables:
   - `users` - User profiles and authentication
   - `rooms` - Room information and metadata
   - `room_participants` - Room membership tracking

### Twilio Configuration
1. **Create Twilio Account**: Visit [twilio.com](https://twilio.com)
2. **Get Account SID**: Found in Console Dashboard
3. **Get Auth Token**: Found in Console Dashboard
4. **Get Phone Number**: Purchase a phone number for SMS

## 📱 Testing Guide

### SMS Authentication Testing
1. **Launch App**: Open the app in simulator
2. **Enter Phone Number**: Use a real phone number you can access
3. **Receive SMS**: Check your phone for the verification code
4. **Enter Code**: Input the 6-digit code in the app
5. **Success**: You should be logged in and see the main interface

### Room Features Testing
1. **Create Room**: Tap the "+" button to create a new room
2. **Join Room**: Enter a room code or select from available rooms
3. **Live Presence**: Verify real-time user presence updates
4. **Audio Features**: Test ambient sound management

### Simulator Limitations
- **SMS Testing**: Use a real device for full SMS testing
- **Camera/Microphone**: Limited functionality in simulator
- **Push Notifications**: Require physical device

## 🏗 Project Structure

```
Nuvora/
├── Nuvora/
│   ├── App/                    # App configuration and delegates
│   ├── Views/                  # SwiftUI views and components
│   │   ├── Auth/              # Authentication screens
│   │   ├── Components/        # Reusable UI components
│   │   └── Rooms/             # Room-related views
│   ├── Services/              # Backend services and managers
│   │   ├── SupabaseManager.swift
│   │   ├── KeychainHelper.swift
│   │   └── LivePresenceManager.swift
│   ├── Models/                # Data models
│   ├── ViewModels/            # MVVM view models
│   ├── Resources/             # Themes and utilities
│   ├── Config.swift           # Environment configuration
│   ├── Info.plist            # App configuration and keys
│   └── NuvoraApp.swift       # Main app entry point
└── Nuvora.xcodeproj/         # Xcode project files
```

## 🔍 Key Features

### ✅ Implemented Features
- **SMS Phone Authentication** - Complete Twilio integration
- **Real-time Rooms** - Live room creation and joining
- **User Presence** - Real-time presence tracking
- **Ambient Sounds** - Background audio management
- **Secure Storage** - Keychain integration for tokens
- **Error Handling** - Comprehensive error management
- **Memory Management** - Leak-free implementation

### 🎯 Core Functionality
- **Login Flow**: Phone → SMS → Verification → Main App
- **Room Management**: Create, join, leave rooms
- **Live Updates**: Real-time participant tracking
- **Audio System**: Ambient sound controls
- **Secure Auth**: Token-based authentication with refresh

## 🚨 Troubleshooting

### Common Issues

#### Build Errors
```bash
# Clean build folder
Product → Clean Build Folder (Cmd + Shift + K)

# Reset simulator
Device → Erase All Content and Settings
```

#### Configuration Issues
- **Check Info.plist**: Ensure all placeholder values are replaced
- **Verify Supabase**: Test connection in Supabase dashboard
- **Validate Twilio**: Check phone number format and account status

#### Runtime Issues
- **Check Console**: Look for configuration validation messages
- **Network Issues**: Verify internet connection and API endpoints
- **Permissions**: Ensure proper iOS permissions are granted

### Debug Mode
The app includes debug logging. Check Xcode console for:
- `✅ Supabase initialized successfully`
- `⚠️ Warning: Supabase configuration not set`
- `❌ Failed to initialize Supabase: Invalid configuration`

## 📞 Support

### Getting Help
1. **Check Console Logs**: Most issues show detailed error messages
2. **Verify Configuration**: Double-check all API keys and URLs
3. **Test on Device**: Some features require physical device testing
4. **Backend Status**: Check Supabase and Twilio service status

### Development Tips
- **Use Real Device**: For full SMS and camera testing
- **Check Permissions**: iOS requires explicit permission grants
- **Monitor Network**: Use Network Link Conditioner for testing
- **Debug Builds**: Enable debug mode for detailed logging

## 🎉 Ready to Go!

Your Nuvora iOS app is now ready for development and testing! The repository includes:
- ✅ Complete SMS authentication system
- ✅ Production-ready Xcode project
- ✅ All critical bug fixes applied
- ✅ Proper iOS app configuration
- ✅ Environment-based configuration management

Simply clone, configure your API keys, and start testing! 🚀