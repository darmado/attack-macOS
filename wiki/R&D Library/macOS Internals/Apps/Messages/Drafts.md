# Messages.app Draft System Analysis

## Overview
Messages.app maintains drafts in a file-based system outside the main SQLite database, using property lists and a structured directory hierarchy.

## File System Structure
```bash
~/Library/Messages/Drafts/
├── {account_id}/             # Service-specific directories
│   ├── composition.plist     # Draft content and metadata
│   └── Attachments/         # Optional media storage
│       └── {UUID}/         # Unique ID per attachment
└── Pending/                 # Staging directory for drafts
```

## Draft Storage Format

### Property List Structure
- Location: `composition.plist` in each account directory
- Format: Binary plist (Apple's property list)
- Primary Key: 'text'
- Data Format: Base64 encoded NSKeyedArchiver data

### Content Encoding Chain
1. **User Input** → NSAttributedString
2. **Storage** → NSKeyedArchiver → Base64 → Binary Plist
3. **Retrieval** → Binary Plist → Base64 → NSKeyedArchiver → NSAttributedString

### NSKeyedArchiver Data Structure
```json
{
    "$version": 100000,
    "$archiver": "NSKeyedArchiver",
    "$objects": [
        "$null",
        {
            "NSString": {},
            "NSAttributeInfo": {},
            "NSAttributes": {},
            "$class": {}
        },
        {
            "NS.string": "draft message content",
            "$class": {}
        }
    ],
    "$top": {
        "root": {}
    }
}
```

## Attachment Handling
1. **Storage Location**:
   - Path: `Attachments/{UUID}/`
   - UUID: Unique per attachment
   - Referenced in plist via CKCompositionFileURL

2. **Reference Format**:
   ```
   file:///Users/username/Library/Messages/Drafts/{account}/Attachments/{UUID}/{filename}
   ```

3. **Lifecycle**:
   - Directory created when attachment added
   - Removed when attachment removed
   - Persists until draft sent/deleted

## State Management

### Draft States
1. **Active**:
   - Stored in account-specific directory
   - Immediately available for editing
   - Synced with iCloud when possible

2. **Pending**:
   - Moved to Pending directory
   - Awaiting further action
   - May require app restart to process

### Filesystem Events
1. **Creation**:
   - New composition.plist created
   - Timestamps initialized
   - Directory structure established

2. **Updates**:
   - Plist content modified
   - last_modified timestamp updated
   - No change to creation timestamp

3. **Sync Requirements**:
   - Messages.app restart needed for some changes
   - iCloud sync required for cross-device availability
   - Local changes cached until sync possible

## Technical Constraints
1. **File Access**:
   - Read operations don't modify timestamps
   - Write operations update last_modified
   - Directory permissions follow Messages.app standards

2. **Data Integrity**:
   - NSKeyedArchiver ensures structured data
   - Base64 encoding preserves binary data
   - Plist format maintains Apple standards

3. **Performance Considerations**:
   - File-based system for quick access
   - Separate from SQLite to prevent blocking
   - Attachment references vs embedding

## Permissions & Security

### File System Permissions
```bash
# Draft Directory
~/Library/Messages/Drafts/
Owner: {username}
Group: staff
Mode: 700 (drwx------)

# Composition Files
composition.plist
Owner: {username}
Group: staff
Mode: 600 (-rw-------)

# Attachments Directory
Attachments/
Owner: {username}
Group: staff
Mode: 700 (drwx------)
```

### System Protections
1. **TCC (Transparency Consent & Control)**:
   - Messages.app requires Full Disk Access
   - Third-party apps need explicit permissions
   - Protected by `com.apple.messages.plist` entitlement

2. **SIP (System Integrity Protection)**:
   - Draft directory not SIP protected
   - Allows user-level modifications
   - Maintains user data ownership

3. **Sandbox Constraints**:
   - Messages.app has explicit entitlements
   - Container access: `~/Library/Messages`
   - Requires `com.apple.security.files.user-selected.read-write`

4. **Access Control**:
   - Limited to owner account only
   - No group or world access
   - Maintains privacy even on multi-user systems

## Draft States & Workflow

### Pending State
1. **No Recipient State**:
   - Draft created without recipient
   - Stored in `~/Library/Messages/Drafts/Pending/`
   - Single composition.plist
   - No attachments support in pending state

2. **State Transition**:
   ```
   Start typing → Pending/composition.plist
   Select recipient → {recipient}/composition.plist
   ```

3. **Technical Process**:
   - Messages.app creates Pending directory if needed
   - Moves draft to recipient directory when selected
   - Maintains same content structure
   - Updates file timestamps on move
