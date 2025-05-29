# TCC Permission Checking Techniques in JXA

## Overview

This document outlines advanced techniques for checking Transparency, Consent, and Control (TCC) permissions, particularly Full Disk Access (FDA), using JavaScript for Automation (JXA) on macOS. These methods prioritize stealth and OPSEC considerations.

## Indirect TCC.db Detection

Use MDQuery to indirectly detect TCC.db files without accessing them directly:

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

This method avoids direct file system access, reducing the risk of detection.

## Gradual Permission Checks

Implement a series of increasingly privileged checks:

```javascript
function gradualPermissionCheck() {
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

This approach mimics legitimate application behavior by starting with less privileged operations.

## Plausible Deniability in Permission Checks

Embed TCC checks within seemingly benign operations:

```javascript
function checkSystemPreferences() {
    const prefPanes = listSystemPreferencePanes();
    const hasFullDiskAccess = checkFullDiskAccess(); // Hidden TCC check
    return { prefPanes, hasFullDiskAccess };
}

function listSystemPreferencePanes() {
    // Actual implementation to list preference panes
    // ...
}
```

This method obscures the true intent of the TCC check within normal system operations.

## Handling TCC Prompts

When performing operations that might trigger TCC prompts, use error handling to detect and manage these situations:

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

This approach allows for graceful handling of TCC restrictions without alerting the user or system.

## OPSEC Considerations

- Minimize the frequency of TCC checks to avoid detection.
- Vary the methods used for TCC checks to prevent pattern recognition.
- Always have a plausible cover for why your script might be checking permissions.
- Consider the broader context of the system and user activity when interpreting results.

## Conclusion

These techniques provide stealthy methods for checking TCC permissions in JXA. Always prioritize minimal system interaction and plausible deniability in your operations.
