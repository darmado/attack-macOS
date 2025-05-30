# msgIntel

msgIntel reads, correlates, searches, and extracts data between all databases used by the Messages desktop application.

##

### Features

- Extract recent messages and associated metadata
- Retrieve contact information and nicknames
- Access collaboration notices and handle sharing preferences
- Analyze communication patterns and social networks
- Search messages for specific keywords or topics
- Generate reports and visualizations of communication data

##

### Overview
A JXA-based tool for extracting data from macOS Messages databases. Focuses on database access and data correlation using native macOS APIs.

##

### Database Locations
```javascript
     /Users/${USER}/Library/Messages/chat.db
    /Users/${USER}/Library/Messages/NickNameCache/nickNameKeyStore.db
    /Users/${USER}/Library/Messages/NickNameCache/handleSharingPreferences.db
    /Users/${USER}/Library/Messages/CollaborationNoticeCache/collaborationNotices.db
```

##

### Usage 

```bash
$ osascript -l JavaScript ./msgIntel.js [options] [arguments...]

DISCOVER:
    -messages               List recent messages
    -chats                  List all chats
    -drafts                 List all drafts
    -handles                List all contacts/handles
    -attachments            List message attachments
    -threads                List message threads
    -deleted                List deleted messages
    -spam                   List spam messages
    -sensitive              List sensitive content

TIME-BASED:
    -last <days>            Show messages from last N days
    -since <timestamp>      Show messages since timestamp
    -between <start> <end>  Show messages between timestamps

SEARCH:
    -text <query>          Search message text
    -sender <id>           Search by sender
    -service <type>        Search by service type (iMessage, SMS)
    -type <type>           Search by attachment type

DEBUG:
    -debug                 Enable debug output
    -schema                Show database schema
    -pragma                Show PRAGMA information
    -help                  Display this help message
```



### Limitations
- Requires Full Disk Access or 
- Database schema changes between macOS versions may break queries
- Message attachments require additional permissions
- Max query batch limit: 100 messages

##

### References
- macOS Messages Framework
- JXA Development Guide

