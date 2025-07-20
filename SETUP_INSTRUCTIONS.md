# Nuvora Setup Instructions

Detailed setup guide for configuring the Nuvora iOS app with Supabase.

## Prerequisites

- Xcode 15.0 or later
- iOS 16.0+ deployment target
- Active Supabase account
- Basic knowledge of iOS development

## Step 1: Supabase Project Setup

### 1.1 Create a New Supabase Project
1. Go to [supabase.com](https://supabase.com)
2. Sign in to your account
3. Click "New Project"
4. Choose your organization
5. Enter project name: "Nuvora"
6. Generate a secure database password
7. Select your preferred region
8. Click "Create new project"

### 1.2 Enable Realtime
1. In your Supabase dashboard, go to "Settings" > "API"
2. Scroll down to "Realtime" section
3. Ensure Realtime is enabled
4. Note your project URL and anon key

## Step 2: Database Configuration

### 2.1 Create Required Tables
Run the following SQL in your Supabase SQL editor:

```sql
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Chat messages table
CREATE TABLE IF NOT EXISTS chat_messages (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    content TEXT NOT NULL,
    sender_id UUID NOT NULL,
    room_id TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User profiles table (optional, for extended user info)
CREATE TABLE IF NOT EXISTS user_profiles (
    id UUID REFERENCES auth.users(id) PRIMARY KEY,
    email TEXT,
    display_name TEXT,
    avatar_url TEXT,
    status TEXT DEFAULT 'offline',
    last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Video call rooms table (optional, for persistent rooms)
CREATE TABLE IF NOT EXISTS video_rooms (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name TEXT NOT NULL,
    created_by UUID REFERENCES auth.users(id),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 2.2 Enable Realtime for Tables
```sql
-- Enable realtime for chat messages
ALTER PUBLICATION supabase_realtime ADD TABLE chat_messages;

-- Enable realtime for user profiles (if created)
ALTER PUBLICATION supabase_realtime ADD TABLE user_profiles;

-- Enable realtime for video rooms (if created)
ALTER PUBLICATION supabase_realtime ADD TABLE video_rooms;
```

### 2.3 Set Up Row Level Security (RLS)
```sql
-- Enable RLS on tables
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE video_rooms ENABLE ROW LEVEL SECURITY;

-- Chat messages policies
CREATE POLICY "Users can read all chat messages" ON chat_messages
    FOR SELECT USING (true);

CREATE POLICY "Users can insert their own messages" ON chat_messages
    FOR INSERT WITH CHECK (auth.uid() = sender_id);

-- User profiles policies
CREATE POLICY "Users can read all profiles" ON user_profiles
    FOR SELECT USING (true);

CREATE POLICY "Users can update their own profile" ON user_profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile" ON user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Video rooms policies
CREATE POLICY "Users can read all active rooms" ON video_rooms
    FOR SELECT USING (is_active = true);

CREATE POLICY "Users can create rooms" ON video_rooms
    FOR INSERT WITH CHECK (auth.uid() = created_by);
```

## Step 3: iOS Project Configuration

### 3.1 Environment Variables
Create a `Config.xcconfig` file in your project root:

```
// Config.xcconfig
SUPABASE_URL = https://your-project-id.supabase.co
SUPABASE_ANON_KEY = your-anon-key-here
```

### 3.2 Update Info.plist
Add the following to your `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Nuvora needs camera access for video calls</string>
<key>NSMicrophoneUsageDescription</key>
<string>Nuvora needs microphone access for video calls</string>
```

### 3.3 Configure App Transport Security
If needed, add to `Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>supabase.co</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <false/>
            <key>NSExceptionMinimumTLSVersion</key>
            <string>TLSv1.2</string>
        </dict>
    </dict>
</dict>
```

## Step 4: Testing the Setup

### 4.1 Build and Run
1. Open `Nuvora.xcodeproj` in Xcode
2. Select your target device or simulator
3. Build and run the project (⌘+R)

### 4.2 Test Authentication
1. Launch the app
2. Try signing up with a test email
3. Check your Supabase Auth dashboard for the new user

### 4.3 Test Realtime Connection
1. Sign in to the app
2. Check the connection status indicator
3. Open Supabase Realtime logs to verify connection

## Step 5: Advanced Configuration

### 5.1 Custom Realtime Channels
Modify `RealtimeService.swift` to add custom channels:

```swift
private func setupCustomChannel() async {
    let customChannel = supabase.realtimeV2.channel("custom-channel")
    
    try await customChannel.subscribe()
    
    // Listen for custom events
    for await message in customChannel.broadcastStream(event: "custom-event") {
        // Handle custom events
    }
}
```

### 5.2 Database Functions
Create custom database functions for complex operations:

```sql
-- Function to update user status
CREATE OR REPLACE FUNCTION update_user_status(user_status TEXT)
RETURNS void AS $$
BEGIN
    UPDATE user_profiles 
    SET status = user_status, 
        last_seen = NOW(),
        updated_at = NOW()
    WHERE id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

## Troubleshooting

### Common Issues

1. **"target 'Nuvora' referenced in product 'Nuvora' is empty"**
   - This has been fixed in the current project configuration
   - Ensure all Swift files are properly added to the target

2. **Realtime connection fails**
   - Check your Supabase URL and anon key
   - Verify Realtime is enabled in your project
   - Check network connectivity

3. **Authentication errors**
   - Verify your Supabase anon key has the correct permissions
   - Check if email confirmation is required in Auth settings

4. **Build errors**
   - Clean build folder (⌘+Shift+K)
   - Reset package caches
   - Verify iOS deployment target is 16.0+

### Debug Mode
Enable debug logging in `SupabaseManager.swift`:

```swift
self.supabase = SupabaseClient(
    supabaseURL: supabaseURL,
    supabaseKey: supabaseKey,
    options: SupabaseClientOptions(
        // ... other options
        global: SupabaseClientOptions.GlobalOptions(
            logger: ConsoleLogger(level: .debug)
        )
    )
)
```

## Security Considerations

1. **Never commit API keys to version control**
2. **Use environment variables or secure configuration**
3. **Implement proper RLS policies**
4. **Validate user input on both client and server**
5. **Use HTTPS for all communications**

## Next Steps

1. **Customize the UI** to match your brand
2. **Add push notifications** for better user engagement
3. **Implement file sharing** for enhanced chat experience
4. **Add video recording** capabilities
5. **Integrate analytics** for usage insights

## Support

If you encounter issues:
1. Check the [Supabase documentation](https://supabase.com/docs)
2. Review the [Supabase Swift SDK](https://github.com/supabase/supabase-swift)
3. Open an issue in this repository
4. Join the [Supabase Discord](https://discord.supabase.com) for community support