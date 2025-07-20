# Nuvora Security Guidelines

## Overview
This document outlines security best practices and configurations for the Nuvora iOS application.

## Current Configuration Status
✅ **Development Ready** - The app is configured with secure credential management for development and testing.

⚠️ **Production Security Required** - Before App Store submission, credentials must be moved to iOS Keychain.

## Credential Management

### Current Setup (Development)
- Credentials are managed via `Config.xcconfig` file (not committed to Git)
- Info.plist uses build configuration variables
- This is secure for development and prevents credential leaks

### Production Security Requirements

#### 1. Move Credentials to iOS Keychain
```swift
// Example: Create a SecureCredentialManager
class SecureCredentialManager {
    static func storeCredential(key: String, value: String) {
        let data = value.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        SecItemAdd(query as CFDictionary, nil)
    }
    
    static func getCredential(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let data = result as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
}
```

#### 2. Environment-Based Configuration
Create separate configurations for different environments:

```swift
enum Environment {
    case development
    case staging
    case production
    
    var supabaseURL: String {
        switch self {
        case .development:
            return SecureCredentialManager.getCredential(key: "dev_supabase_url") ?? ""
        case .staging:
            return SecureCredentialManager.getCredential(key: "staging_supabase_url") ?? ""
        case .production:
            return SecureCredentialManager.getCredential(key: "prod_supabase_url") ?? ""
        }
    }
}
```

#### 3. Remove Credentials from Build Configuration
Before production deployment:
1. Remove Config.xcconfig file
2. Update `Config.swift` to use Keychain instead
3. Use Xcode's build configurations for environment management

## Security Features Implemented

### 1. Authentication Security
- **OTP Expiration**: 10-minute timeout for verification codes
- **Rate Limiting**: Maximum 3 OTP attempts before lockout
- **Resend Protection**: 60-second cooldown between OTP requests
- **Session Management**: Automatic token refresh and validation

### 2. Network Security
- **TLS 1.2+**: Enforced minimum TLS version
- **Certificate Pinning**: Configured for Supabase domains
- **No Arbitrary Loads**: ATS (App Transport Security) enabled

### 3. Data Protection
- **Background App Refresh**: Configured for VoIP and audio
- **Keychain Integration**: Ready for secure credential storage
- **Biometric Authentication**: Can be added for app unlock

## Privacy Permissions

### Required Permissions
- **Camera**: Video calls and photo sharing
- **Microphone**: Voice and video calls
- **Photo Library**: Image sharing in rooms
- **Contacts**: Friend discovery (optional)
- **Location**: Nearby rooms feature (optional)

### Permission Descriptions
All permission requests include clear, user-friendly descriptions explaining why access is needed.

## Security Checklist for Production

### Before App Store Submission
- [ ] Move all credentials from Config.xcconfig to Keychain
- [ ] Implement certificate pinning for API endpoints
- [ ] Add biometric authentication option
- [ ] Enable code obfuscation
- [ ] Implement jailbreak detection
- [ ] Add network request encryption
- [ ] Set up crash reporting with privacy compliance
- [ ] Implement proper session timeout handling
- [ ] Add device binding for enhanced security
- [ ] Configure proper backup exclusion for sensitive data

### Code Security
- [ ] Remove all hardcoded secrets
- [ ] Implement proper error handling without exposing sensitive info
- [ ] Add input validation for all user inputs
- [ ] Implement proper memory management for sensitive data
- [ ] Use secure random number generation for OTPs
- [ ] Implement proper logging without sensitive data

### Infrastructure Security
- [ ] Configure Supabase Row Level Security (RLS)
- [ ] Set up proper database permissions
- [ ] Implement API rate limiting
- [ ] Configure CORS properly
- [ ] Set up monitoring and alerting
- [ ] Implement backup and disaster recovery

## Compliance Considerations

### GDPR/Privacy
- User data minimization
- Right to deletion implementation
- Data portability features
- Clear privacy policy

### App Store Guidelines
- Proper permission usage descriptions
- No private API usage
- Secure credential management
- User data protection

## Incident Response

### Security Breach Protocol
1. Immediately revoke compromised credentials
2. Notify users if personal data is affected
3. Update app with security patches
4. Review and improve security measures
5. Document lessons learned

### Monitoring
- Set up alerts for unusual authentication patterns
- Monitor API usage for anomalies
- Track failed authentication attempts
- Log security-relevant events

## Contact
For security concerns or questions, contact the development team.

---
**Last Updated**: July 2025
**Version**: 1.0