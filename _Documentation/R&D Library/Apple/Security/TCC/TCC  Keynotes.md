## TCC (Transparency, Consent, and Control)

TCC is Apple's privacy protection system that manages app access to certain protected resources and user data. It requires user consent before allowing apps to access sensitive information or features.

##

#### Key Points:

1. **Purpose**: TCC ensures that apps only access sensitive data or features with explicit user consent.

2. **Protected Resources**: Include camera, microphone, photos, contacts, calendars, reminders, and location services.

3. **User Consent**: Apps must request permission through system dialogs before accessing protected resources.

4. **Persistence**: User choices are remembered and can be managed in System Preferences/Settings.

5. **App Usage Descriptions**: Apps must provide clear explanations for why they need access to protected resources.

6. **Programmatic Checks**: Developers can use APIs to check current authorization status and request access.

7. **Full Disk Access**: Some operations require Full Disk Access, which is a higher level of permission.

8. **Automation**: Scripts and command-line tools may also be subject to TCC restrictions.

##

### References

**TCC Documentation from Apple**
- [Protecting User Privacy](https://developer.apple.com/documentation/security/protecting_user_privacy)
- [Privacy Best Practices](https://developer.apple.com/documentation/uikit/protecting_the_user_s_privacy)


**macOS TCC.db Deep Dive**
- [Rain Forest - TCC Deep Deive](https://www.rainforestqa.com/blog/macos-tcc-db-deep-dive)
 
