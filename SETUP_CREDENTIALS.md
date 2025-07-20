# Nuvora Credentials Setup

## Quick Setup for Development

### 1. Create Config.xcconfig File
Create a file named `Config.xcconfig` in the root directory with your actual credentials:

```
// Supabase Configuration
SUPABASE_URL = https://your-project.supabase.co
SUPABASE_ANON_KEY = your-supabase-anon-key

// Twilio Configuration  
TWILIO_ACCOUNT_SID = your-twilio-account-sid
TWILIO_AUTH_TOKEN = your-twilio-auth-token
TWILIO_MESSAGE_SERVICE_SID = your-twilio-message-service-sid
```

### 2. Configure Xcode Project
1. Open `Nuvora.xcodeproj` in Xcode
2. Select the project in the navigator
3. Select the "Nuvora" target
4. Go to "Build Settings"
5. Find "Configuration Settings File"
6. Set it to `Config.xcconfig` for both Debug and Release

### 3. Build and Run
The app will now use your credentials from the Config.xcconfig file.

## Security Notes

⚠️ **Important**: The `Config.xcconfig` file is already added to `.gitignore` to prevent accidental commits.

✅ **For Production**: Move credentials to iOS Keychain before App Store submission (see SECURITY.md).

## Credentials Required

### Supabase
- **Project URL**: Your Supabase project URL
- **Anon Key**: Your Supabase anonymous key

### Twilio
- **Account SID**: Your Twilio account SID
- **Auth Token**: Your Twilio auth token
- **Message Service ID**: Your Twilio messaging service SID

**Note**: The actual credentials have been provided separately for security reasons.

## Troubleshooting

If you encounter issues:
1. Verify the Config.xcconfig file is properly linked in Xcode
2. Clean and rebuild the project (Cmd+Shift+K, then Cmd+B)
3. Check that all credentials are correctly formatted
4. Ensure no extra spaces or characters in the configuration file