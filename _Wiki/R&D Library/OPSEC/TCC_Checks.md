# TCC Permission Checks in JXA

## Overview

This document outlines methods for checking Transparency, Consent, and Control (TCC) permissions using JavaScript for Automation (JXA) on macOS. These methods focus on OPSEC considerations and minimal system interaction.

## Core Methods

### MDQuery Detection
Check for TCC.db files without direct access:

```javascript
function checkFullDiskAccess() {
    ObjC.import('CoreServices');
    const queryString = "kMDItemDisplayName = *TCC.db";
    let query = $.MDQueryCreate($(), $(queryString), $(), $());
    
    if ($.MDQueryExecute(query, 1)) {
        let resultCount = $.MDQueryGetResultCount(query);
        return resultCount === 2; // 2 results indicate FDA
    }
    return false;
}
```

### Permission Validation
Implement checks from least to most privileged:

```javascript
function validatePermissions() {
    const fileManager = $.NSFileManager.defaultManager;
    const homeDir = $.NSHomeDirectory().js;
    const tccPath = `${homeDir}/Library/Application Support/com.apple.TCC`;
    
    if (fileManager.fileExistsAtPath(tccPath)) {
        if (checkFullDiskAccess()) {
            return true;
        }
    }
    return false;
}
```

### Error Handling
Handle TCC restrictions gracefully:

```javascript
function safeFileAccess(path) {
    try {
        const fileManager = $.NSFileManager.defaultManager;
        return fileManager.contentsAtPath(path);
    } catch (error) {
        if (error.message.includes("Operation not permitted")) {
            // Handle TCC restriction
        }
        return null;
    }
}
```

## OPSEC Considerations

1. **Minimal Interaction**
   - Limit the frequency of TCC checks
   - Use indirect methods where possible
   - Avoid repeated failed access attempts

2. **System Integration**
   - Blend checks with normal system operations
   - Maintain consistent access patterns
   - Avoid suspicious timing patterns

3. **Error Management**
   - Handle permissions gracefully
   - Log minimally and appropriately
   - Maintain stable operation on failure

## Implementation Notes

1. **Permission Levels**
   - User Consent
   - Admin Consent
   - MDM Managed

2. **Key Areas**
   - Full Disk Access
   - Accessibility
   - Camera/Microphone
   - Location Services
   - Contacts/Calendar
   - Photos/Media

## Example Usage

```javascript
// Basic permission check implementation
function checkPermissions() {
    if (validatePermissions()) {
        console.log("Required permissions available");
        return true;
    }
    console.log("Insufficient permissions");
    return false;
}

// Safe file access with error handling
function accessFile(path) {
    return safeFileAccess(path) || "Access denied";
}
```

## References

- Apple TCC Documentation
- macOS Security Guide
- JXA Development Reference
