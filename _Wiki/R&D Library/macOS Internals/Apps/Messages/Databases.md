# Messages Database Structure

## Research Progress

### Completed
- ✅ Basic schema enumeration
- ✅ Table relationships mapping
- ✅ Index identification
- ✅ Trigger documentation
- ✅ Cross-database relationships

### In Progress
- 🔄 Sample data analysis
- 🔄 BLOB data structure analysis
- 🔄 kvtable key-value mapping

### Todo
- ⏳ Message state transition analysis
- ⏳ CloudKit sync mechanism documentation
- ⏳ Attachment file path resolution
- ⏳ Collaboration notice format analysis
- ⏳ Nickname resolution chain verification

### Interesting Findings
1. Security Features:
   - Message detonation (disappearing messages)
   - Communication safety checks
   - Spam detection system
   - Message integrity verification

2. Undocumented Features:
   - `is_stewie` flag (purpose unknown)
   - `is_kt_verified` (possibly Known Traveler verification)
   - Complex message threading system

3. Performance Optimizations:
   - Extensive indexing on message status
   - Cached room names
   - Optimized one-to-one iMessage queries

## Overview
macOS Messages app uses multiple SQLite databases to store different aspects of messaging data:
- Main chat database (chat.db)
- Nickname cache (nickNameKeyStore.db)
- Handle sharing preferences (handleSharingPreferences.db)
- Collaboration notices (collaborationNotices.db)

## 1. Main Database (chat.db)
Location: `~/Library/Messages/chat.db`

### Tables

#### message
| Column | Type | Nullable | Default | Key | How We Use It |
|--------|------|----------|---------|-----|---------------|
| ROWID | INTEGER | No | - | PRIMARY KEY AUTOINCREMENT | Unique identifier for direct message lookups |
| guid | TEXT | No | - | UNIQUE | Cross-reference identifier across databases |
| text | TEXT | Yes | - | - | Raw message content for analysis |
| replace | INTEGER | Yes | 0 | - | Tracks message edits/replacements |
| service_center | TEXT | Yes | - | - | SMS routing information |
| handle_id | INTEGER | Yes | 0 | - | Links to contact record |
| subject | TEXT | Yes | - | - | Message subject line if present |
| country | TEXT | Yes | - | - | Geographic origin indicator |
| attributedBody | BLOB | Yes | - | - | Rich text formatting data |
| version | INTEGER | Yes | 0 | - | Message format version tracking |
| type | INTEGER | Yes | 0 | - | Message type classification |
| service | TEXT | Yes | - | - | Communication service used |
| account | TEXT | Yes | - | - | Sender account identifier |
| account_guid | TEXT | Yes | - | - | Sender Apple ID reference |
| error | INTEGER | Yes | 0 | - | Delivery error tracking |
| date | INTEGER | Yes | - | - | Message timestamp |
| date_read | INTEGER | Yes | - | - | Read receipt timestamp |
| date_delivered | INTEGER | Yes | - | - | Delivery confirmation time |
| is_delivered | INTEGER | Yes | 0 | - | Delivery status flag |
| is_finished | INTEGER | Yes | 0 | - | Message completion status |
| is_emote | INTEGER | Yes | 0 | - | Identifies reaction messages |
| is_from_me | INTEGER | Yes | 0 | - | if int is `0` message was not sent from me. |
| is_empty | INTEGER | Yes | 0 | - | Empty message detection |
| is_delayed | INTEGER | Yes | 0 | - | Delayed delivery tracking |
| is_auto_reply | INTEGER | Yes | 0 | - | Auto-response detection |
| is_prepared | INTEGER | Yes | 0 | - | Message preparation state |
| is_read | INTEGER | Yes | 0 | - | Read status tracking |
| is_system_message | INTEGER | Yes | 0 | - | System notification flag |
| is_sent | INTEGER | Yes | 0 | - | Transmission status |
| has_dd_results | INTEGER | Yes | 0 | - | Data detection results presence |
| is_service_message | INTEGER | Yes | 0 | - | Service notification flag |
| is_forward | INTEGER | Yes | 0 | - | Forward status tracking |
| was_downgraded | INTEGER | Yes | 0 | - | Service fallback indicator |
| is_archive | INTEGER | Yes | 0 | - | Archive status tracking |
| cache_has_attachments | INTEGER | Yes | 0 | - | Attachment presence cache |
| cache_roomnames | TEXT | Yes | - | - | Group chat name cache |
| was_data_detected | INTEGER | Yes | 0 | - | Content analysis flag |
| was_deduplicated | INTEGER | Yes | 0 | - | Duplicate message handling |
| is_audio_message | INTEGER | Yes | 0 | - | Voice message identifier |
| is_played | INTEGER | Yes | 0 | - | Audio playback tracking |
| date_played | INTEGER | Yes | - | - | Audio playback timestamp |
| item_type | INTEGER | Yes | 0 | - | Message content type |
| other_handle | INTEGER | Yes | 0 | - | Secondary contact reference |
| group_title | TEXT | Yes | - | - | Group chat title storage |
| group_action_type | INTEGER | Yes | 0 | - | Group event classifier |
| share_status | INTEGER | Yes | 0 | - | Content sharing state |
| share_direction | INTEGER | Yes | 0 | - | Share flow direction |
| is_expirable | INTEGER | Yes | 0 | - | Disappearing message flag |
| expire_state | INTEGER | Yes | 0 | - | Expiration status tracking |
| message_action_type | INTEGER | Yes | 0 | - | Message action classifier |
| message_source | INTEGER | Yes | 0 | - | Origin tracking |
| associated_message_guid | TEXT | Yes | - | - | Reply thread linking |
| associated_message_type | INTEGER | Yes | 0 | - | Reply type tracking |
| balloon_bundle_id | TEXT | Yes | - | - | Message effect identifier |
| payload_data | BLOB | Yes | - | - | Rich content storage |
| expressive_send_style_id | TEXT | Yes | - | - | Message effect type |
| associated_message_range_location | INTEGER | Yes | 0 | - | Reply text selection start |
| associated_message_range_length | INTEGER | Yes | 0 | - | Reply text selection length |
| time_expressive_send_played | INTEGER | Yes | - | - | Effect playback time |
| message_summary_info | BLOB | Yes | - | - | Preview data storage |
| ck_sync_state | INTEGER | Yes | 0 | - | CloudKit sync status |
| ck_record_id | TEXT | Yes | - | - | CloudKit record reference |
| ck_record_change_tag | TEXT | Yes | - | - | CloudKit change tracking |
| destination_caller_id | TEXT | Yes | - | - | Recipient identifier |
| is_corrupt | INTEGER | Yes | 0 | - | Data integrity flag |
| reply_to_guid | TEXT | Yes | - | - | Parent message reference |
| sort_id | INTEGER | Yes | - | - | Display order tracking |
| is_spam | INTEGER | Yes | 0 | - | Spam detection flag |
| has_unseen_mention | INTEGER | Yes | 0 | - | Mention notification state |
| thread_originator_guid | TEXT | Yes | - | - | Thread starter reference |
| thread_originator_part | TEXT | Yes | - | - | Thread context data |
| syndication_ranges | TEXT | Yes | - | - | Shared content ranges |
| synced_syndication_ranges | TEXT | Yes | - | - | Sync status for ranges |
| was_delivered_quietly | INTEGER | Yes | 0 | - | Silent delivery tracking |
| did_notify_recipient | INTEGER | Yes | 0 | - | Notification status |
| date_retracted | INTEGER | Yes | - | - | Message recall timestamp |
| date_edited | INTEGER | Yes | - | - | Edit history tracking |
| was_detonated | INTEGER | Yes | 0 | - | Self-destruct status |
| part_count | INTEGER | Yes | - | - | Message segment counter |
| is_stewie | INTEGER | Yes | 0 | - | Internal feature flag |
| is_kt_verified | INTEGER | Yes | 0 | - | Known Traveler status |

#### chat
| Column | Type | Nullable | Default | Key | How We Use It |
|--------|------|----------|---------|-----|---------------|
| ROWID | INTEGER | No | - | PRIMARY KEY AUTOINCREMENT | Unique chat identifier |
| guid | TEXT | No | - | UNIQUE | Cross-reference chat ID |
| style | INTEGER | Yes | - | - | Chat display format |
| state | INTEGER | Yes | - | - | Chat status tracking |
| account_id | TEXT | Yes | - | - | User account linking |
| properties | BLOB | Yes | - | - | Chat settings storage |
| chat_identifier | TEXT | Yes | - | - | Chat address/number |
| service_name | TEXT | Yes | - | - | Platform identifier |
| room_name | TEXT | Yes | - | - | Group chat name |
| account_login | TEXT | Yes | - | - | User credential link |
| is_archived | INTEGER | Yes | 0 | - | Archive status flag |
| last_addressed_handle | TEXT | Yes | - | - | Recent contact tracking |
| display_name | TEXT | Yes | - | - | Custom chat name |
| group_id | TEXT | Yes | - | - | Group chat identifier |
| is_filtered | INTEGER | Yes | 0 | - | Spam filter status |
| successful_query | INTEGER | Yes | - | - | Search result tracking |
| engram_id | TEXT | Yes | - | - | Memory reference ID |
| server_change_token | TEXT | Yes | - | - | Sync change tracking |
| ck_sync_state | INTEGER | Yes | 0 | - | CloudKit sync status |
| original_group_id | TEXT | Yes | - | - | Initial group reference |
| last_read_message_timestamp | INTEGER | Yes | 0 | - | Read position tracking |
| cloudkit_record_id | TEXT | Yes | - | - | CloudKit reference |
| last_addressed_sim_id | TEXT | Yes | - | - | SIM card tracking |
| is_blackholed | INTEGER | Yes | 0 | - | Blocked status flag |
| syndication_date | INTEGER | Yes | 0 | - | Share timestamp |
| syndication_type | INTEGER | Yes | 0 | - | Share type classifier |
| is_recovered | INTEGER | Yes | 0 | - | Recovery status flag |

#### handle
| Column | Type | Nullable | Default | Key | How We Use It |
|--------|------|----------|---------|-----|---------------|
| ROWID | INTEGER | No | - | PRIMARY KEY AUTOINCREMENT | Unique contact identifier |
| id | TEXT | No | - | - | Contact address/number |
| country | TEXT | Yes | - | - | Geographic location |
| service | TEXT | No | - | - | Communication platform |
| uncanonicalized_id | TEXT | Yes | - | - | Raw contact format |
| person_centric_id | TEXT | Yes | - | - | Contact correlation ID |

#### attachment
| Column | Type | Nullable | Default | Key | How We Use It |
|--------|------|----------|---------|-----|---------------|
| ROWID | INTEGER | No | - | PRIMARY KEY AUTOINCREMENT | Unique file identifier |
| guid | TEXT | No | - | UNIQUE | Cross-reference file ID |
| created_date | INTEGER | Yes | 0 | - | Creation timestamp |
| start_date | INTEGER | Yes | 0 | - | Transfer start time |
| filename | TEXT | Yes | - | - | File path storage |
| uti | TEXT | Yes | - | - | File type identifier |
| mime_type | TEXT | Yes | - | - | Content type tracking |
| transfer_state | INTEGER | Yes | 0 | - | Download status |
| is_outgoing | INTEGER | Yes | 0 | - | Transfer direction |
| user_info | BLOB | Yes | - | - | Metadata storage |
| transfer_name | TEXT | Yes | - | - | Display filename |
| total_bytes | INTEGER | Yes | 0 | - | File size tracking |
| is_sticker | INTEGER | Yes | 0 | - | Sticker identifier |
| sticker_user_info | BLOB | Yes | - | - | Sticker metadata |
| attribution_info | BLOB | Yes | - | - | Source tracking |
| hide_attachment | INTEGER | Yes | 0 | - | Visibility control |
| ck_sync_state | INTEGER | Yes | 0 | - | CloudKit sync status |
| ck_server_change_token_blob | BLOB | Yes | - | - | Sync change data |
| ck_record_id | TEXT | Yes | - | - | CloudKit reference |
| original_guid | TEXT | No | - | UNIQUE | Original file reference |
| is_commsafety_sensitive | INTEGER | Yes | 0 | - | Safety flag status |



--------------
-- Schema for /Users/darmado/Library/Messages/chat.db

-- Core tables
```sql
CREATE TABLE _SqliteDatabaseProperties (
    key TEXT,
    value TEXT,
    UNIQUE(key)
);
```

```sql
CREATE TABLE chat (
    ROWID INTEGER PRIMARY KEY AUTOINCREMENT,
    guid TEXT UNIQUE NOT NULL,
    style INTEGER,
    state INTEGER, 
    account_id TEXT,
    properties BLOB,
    chat_identifier TEXT,
    service_name TEXT,
    room_name TEXT,
    account_login TEXT,
    is_archived INTEGER DEFAULT 0,
    last_addressed_handle TEXT,
    display_name TEXT,
    group_id TEXT,
    is_filtered INTEGER DEFAULT 0,
    successful_query INTEGER,
    engram_id TEXT,
    server_change_token TEXT,
    ck_sync_state INTEGER DEFAULT 0,
    original_group_id TEXT,
    last_read_message_timestamp INTEGER DEFAULT 0,
    cloudkit_record_id TEXT,
    last_addressed_sim_id TEXT,
    is_blackholed INTEGER DEFAULT 0,
    syndication_date INTEGER DEFAULT 0,
    syndication_type INTEGER DEFAULT 0,
    is_recovered INTEGER DEFAULT 0
    );
```

```sql
CREATE TABLE message (
    ROWID INTEGER PRIMARY KEY AUTOINCREMENT,
    guid TEXT UNIQUE NOT NULL,
    text TEXT,
    replace INTEGER DEFAULT 0,
    service_center TEXT,
    handle_id INTEGER DEFAULT 0,
    subject TEXT,
    country TEXT,
    attributedBody BLOB,
    version INTEGER DEFAULT 0,
    type INTEGER DEFAULT 0,
    service TEXT,
    account TEXT,
    account_guid TEXT,
    error INTEGER DEFAULT 0,
    date INTEGER,
    date_read INTEGER,
    date_delivered INTEGER,
    is_delivered INTEGER DEFAULT 0,
    is_finished INTEGER DEFAULT 0,
    is_emote INTEGER DEFAULT 0,
    is_from_me INTEGER DEFAULT 0,
    is_empty INTEGER DEFAULT 0,
    is_delayed INTEGER DEFAULT 0,
    is_auto_reply INTEGER DEFAULT 0,
    is_prepared INTEGER DEFAULT 0,
    is_read INTEGER DEFAULT 0,
    is_system_message INTEGER DEFAULT 0,
    is_sent INTEGER DEFAULT 0,
    has_dd_results INTEGER DEFAULT 0,
    is_service_message INTEGER DEFAULT 0,
    is_forward INTEGER DEFAULT 0,
    was_downgraded INTEGER DEFAULT 0,
    is_archive INTEGER DEFAULT 0,
    cache_has_attachments INTEGER DEFAULT 0,
    cache_roomnames TEXT,
    was_data_detected INTEGER DEFAULT 0,
    was_deduplicated INTEGER DEFAULT 0,
    is_audio_message INTEGER DEFAULT 0,
    is_played INTEGER DEFAULT 0,
    date_played INTEGER,
    item_type INTEGER DEFAULT 0,
    other_handle INTEGER DEFAULT 0,
    group_title TEXT,
    group_action_type INTEGER DEFAULT 0,
    share_status INTEGER DEFAULT 0,
    share_direction INTEGER DEFAULT 0,
    is_expirable INTEGER DEFAULT 0,
    expire_state INTEGER DEFAULT 0,
    message_action_type INTEGER DEFAULT 0,
    message_source INTEGER DEFAULT 0,
    associated_message_guid TEXT,
    associated_message_type INTEGER DEFAULT 0,
    balloon_bundle_id TEXT,
    payload_data BLOB,
    expressive_send_style_id TEXT,
    associated_message_range_location INTEGER DEFAULT 0,
    associated_message_range_length INTEGER DEFAULT 0,
    time_expressive_send_played INTEGER,
    message_summary_info BLOB,
    ck_sync_state INTEGER DEFAULT 0,
    ck_record_id TEXT,
    ck_record_change_tag TEXT,
    destination_caller_id TEXT,
    is_corrupt INTEGER DEFAULT 0,
    reply_to_guid TEXT,
    sort_id INTEGER,
    is_spam INTEGER DEFAULT 0,
    has_unseen_mention INTEGER DEFAULT 0,
    thread_originator_guid TEXT,
    thread_originator_part TEXT,
    syndication_ranges TEXT,
    synced_syndication_ranges TEXT,
    was_delivered_quietly INTEGER DEFAULT 0,
    did_notify_recipient INTEGER DEFAULT 0,
    date_retracted INTEGER,
    date_edited INTEGER,
    was_detonated INTEGER DEFAULT 0,
    part_count INTEGER,
    is_stewie INTEGER DEFAULT 0,
    is_kt_verified INTEGER DEFAULT 0
);
```

```sql
CREATE TABLE attachment (
    ROWID INTEGER PRIMARY KEY AUTOINCREMENT,
    guid TEXT UNIQUE NOT NULL,
    created_date INTEGER DEFAULT 0,
    start_date INTEGER DEFAULT 0,
    filename TEXT,
    uti TEXT,
    mime_type TEXT,
    transfer_state INTEGER DEFAULT 0,
    is_outgoing INTEGER DEFAULT 0,
    user_info BLOB,
    transfer_name TEXT,
    total_bytes INTEGER DEFAULT 0,
    is_sticker INTEGER DEFAULT 0,
    sticker_user_info BLOB,
    attribution_info BLOB,
    hide_attachment INTEGER DEFAULT 0,
    ck_sync_state INTEGER DEFAULT 0,
    ck_server_change_token_blob BLOB,
    ck_record_id TEXT,
    original_guid TEXT UNIQUE NOT NULL,
    is_commsafety_sensitive INTEGER DEFAULT 0
);
```

```sql
CREATE TABLE chat_message_join (
    chat_id INTEGER REFERENCES chat (ROWID) ON DELETE CASCADE,
    message_id INTEGER REFERENCES message (ROWID) ON DELETE CASCADE,
    message_date INTEGER DEFAULT 0,
    PRIMARY KEY (chat_id, message_id)
);
```

```sql
CREATE TABLE chat_handle_join (
    chat_id INTEGER REFERENCES chat (ROWID) ON DELETE CASCADE,
    handle_id INTEGER REFERENCES handle (ROWID) ON DELETE CASCADE,
    UNIQUE(chat_id, handle_id)
);

```sql
CREATE TABLE message_attachment_join (
    message_id INTEGER REFERENCES message (ROWID) ON DELETE CASCADE,
    attachment_id INTEGER REFERENCES attachment (ROWID) ON DELETE CASCADE,
    UNIQUE(message_id, attachment_id)
);
```

```sql
-- Sync and deleted item tables
CREATE TABLE deleted_messages (
    ROWID INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE,
    guid TEXT NOT NULL
);
```

```sql
CREATE TABLE sync_deleted_chats (
    ROWID INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE,
    guid TEXT NOT NULL,
    recordID TEXT,
    timestamp INTEGER
);
```

```sql
CREATE TABLE sync_deleted_attachments (
    ROWID INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE,
    guid TEXT NOT NULL,
    recordID TEXT
);
```

```sql
CREATE TABLE sync_deleted_messages (
    ROWID INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE,
    guid TEXT NOT NULL,
    recordID TEXT
);
```

```sql
-- Other tables
CREATE TABLE handle (
    ROWID INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE,
    id TEXT NOT NULL,
    country TEXT,
    service TEXT NOT NULL,
    uncanonicalized_id TEXT,
    person_centric_id TEXT,
    UNIQUE (id, service)
);
```

```sql
CREATE TABLE kvtable (
    ROWID INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE,
    key TEXT UNIQUE NOT NULL,
    value BLOB NOT NULL
);
```

```sql
CREATE TABLE message_processing_task (
    ROWID INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE,
    guid TEXT NOT NULL,
    task_flags INTEGER NOT NULL
);
```

```sql
CREATE TABLE recoverable_message_part (
    chat_id INTEGER REFERENCES chat (ROWID) ON DELETE CASCADE,
    message_id INTEGER REFERENCES message (ROWID) ON DELETE CASCADE,
    part_index INTEGER,
    delete_date INTEGER,
    part_text BLOB NOT NULL,
    ck_sync_state INTEGER DEFAULT 0,
    PRIMARY KEY (chat_id, message_id, part_index),
    CHECK (delete_date != 0)
);
```

```sql
CREATE TABLE chat_recoverable_message_join (
    chat_id INTEGER REFERENCES chat (ROWID) ON DELETE CASCADE,
    message_id INTEGER REFERENCES message (ROWID) ON DELETE CASCADE,
    delete_date INTEGER,
    ck_sync_state INTEGER DEFAULT 0,
    PRIMARY KEY (chat_id, message_id),
    CHECK (delete_date != 0)
);
```

```sql
CREATE TABLE unsynced_removed_recoverable_messages (
    ROWID INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE,
    chat_guid TEXT NOT NULL,
    message_guid TEXT NOT NULL,
    part_index INTEGER
);
```

-- Indexes

```sql
CREATE INDEX message_attachment_join_idx_message_id ON message_attachment_join(message_id);
```

```sql
CREATE INDEX chat_idx_chat_identifier_service_name ON chat(chat_identifier, service_name);
CREATE INDEX chat_handle_join_idx_handle_id ON chat_handle_join(handle_id);
CREATE INDEX message_attachment_join_idx_attachment_id ON message_attachment_join(attachment_id);
CREATE INDEX message_idx_date ON message(date);
CREATE INDEX attachment_idx_purged_attachments_v2 ON attachment(hide_attachment,ck_sync_state,transfer_state) 
    WHERE hide_attachment=0 AND (ck_sync_state=1 OR ck_sync_state=4) AND transfer_state=0;
CREATE INDEX message_idx_thread_originator_guid ON message(thread_originator_guid);
CREATE INDEX message_idx_handle ON message(handle_id, date);
CREATE INDEX message_idx_handle_id ON message(handle_id);
CREATE INDEX message_idx_is_sent_is_from_me_error ON message(is_sent, is_from_me, error);
CREATE INDEX chat_message_join_idx_message_id_only ON chat_message_join(message_id);
CREATE INDEX message_idx_associated_message ON message(associated_message_guid);
CREATE INDEX chat_idx_chat_identifier ON chat(chat_identifier);
CREATE INDEX message_processing_task_idx_guid_task_flags ON message_processing_task(guid, task_flags);
CREATE INDEX message_idx_undelivered_one_to_one_imessage ON message(cache_roomnames,service,is_sent,is_delivered,was_downgraded,item_type) 
    WHERE cache_roomnames IS NULL AND service = 'iMessage' AND is_sent = 1 AND is_delivered = 0 AND was_downgraded = 0 AND item_type == 0;
CREATE INDEX chat_message_join_idx_chat_id ON chat_message_join(chat_id);
CREATE INDEX message_idx_cache_has_attachments ON message(cache_has_attachments);
CREATE INDEX chat_idx_chat_room_name_service_name ON chat(room_name, service_name);
CREATE INDEX message_idx_other_handle ON message(other_handle);
CREATE INDEX message_idx_was_downgraded ON message(was_downgraded);
CREATE INDEX chat_idx_is_archived ON chat(is_archived);
CREATE INDEX chat_idx_group_id ON chat(group_id);
CREATE INDEX message_idx_expire_state ON message(expire_state);
CREATE INDEX chat_message_join_idx_message_date_id_chat_id ON chat_message_join(chat_id, message_date, message_id);
CREATE INDEX message_idx_is_read ON message(is_read, is_from_me, is_finished);
CREATE INDEX message_idx_isRead_isFromMe_itemType ON message(is_read, is_from_me, item_type);
CREATE INDEX message_idx_failed ON message(is_finished, is_from_me, error);
```

-- Triggers

```sql
CREATE TRIGGER after_delete_on_chat_message_join AFTER DELETE ON chat_message_join 
BEGIN
    UPDATE message
    SET cache_roomnames = (
        SELECT group_concat(c.room_name)
        FROM chat c
        INNER JOIN chat_message_join j ON c.ROWID = j.chat_id
        WHERE j.message_id = OLD.message_id
    )
    WHERE message.ROWID = OLD.message_id;
    
    DELETE FROM message 
    WHERE message.ROWID = OLD.message_id 
    AND OLD.message_id NOT IN (
        SELECT chat_message_join.message_id 
        FROM chat_message_join 
        WHERE chat_message_join.message_id = OLD.message_id 
        LIMIT 1
    ) 
    AND OLD.message_id NOT IN (
        SELECT chat_recoverable_message_join.message_id 
        FROM chat_recoverable_message_join 
        WHERE chat_recoverable_message_join.message_id = OLD.message_id 
        LIMIT 1
    );
END;
```

```sql
CREATE TRIGGER after_delete_on_attachment AFTER DELETE ON attachment 
BEGIN
    SELECT delete_attachment_path(OLD.filename);
END;
```

```sql
CREATE TRIGGER after_insert_on_message_attachment_join AFTER INSERT ON message_attachment_join 
BEGIN
    UPDATE message
    SET cache_has_attachments = 1
    WHERE message.ROWID = NEW.message_id;
END;
```

```sql
CREATE TRIGGER after_delete_on_chat_handle_join AFTER DELETE ON chat_handle_join 
BEGIN
    DELETE FROM handle
    WHERE handle.ROWID = OLD.handle_id
    AND (SELECT 1 FROM chat_handle_join WHERE handle_id = OLD.handle_id LIMIT 1) IS NULL
    AND (SELECT 1 FROM message WHERE handle_id = OLD.handle_id LIMIT 1) IS NULL
    AND (SELECT 1 FROM message WHERE other_handle = OLD.handle_id LIMIT 1) IS NULL;
END;
```

```sql
CREATE TRIGGER after_insert_on_chat_message_join AFTER INSERT ON chat_message_join 
BEGIN
    UPDATE message
    SET cache_roomnames = (
        SELECT group_concat(c.room_name)
        FROM chat c
        INNER JOIN chat_message_join j ON c.ROWID = j.chat_id
        WHERE j.message_id = NEW.message_id
    )
    WHERE message.ROWID = NEW.message_id;
    END;
```

```sql
CREATE TRIGGER after_delete_on_message AFTER DELETE ON message 
BEGIN
    DELETE FROM handle
    WHERE handle.ROWID = OLD.handle_id
    AND (SELECT 1 FROM chat_handle_join WHERE handle_id = OLD.handle_id LIMIT 1) IS NULL
    AND (SELECT 1 FROM message WHERE handle_id = OLD.handle_id LIMIT 1) IS NULL
    AND (SELECT 1 FROM message WHERE other_handle = OLD.handle_id LIMIT 1) IS NULL;
END;
```

```sql
CREATE TRIGGER update_message_date_after_update_on_message AFTER UPDATE OF date ON message 
BEGIN 
    UPDATE chat_message_join 
    SET message_date = NEW.date 
    WHERE message_id = NEW.ROWID AND message_date != NEW.date;
END;
```

```sql
CREATE TRIGGER after_delete_on_message_plugin AFTER DELETE ON message 
WHEN OLD.balloon_bundle_id IS NOT NULL 
BEGIN
    SELECT after_delete_message_plugin(OLD.ROWID, OLD.guid);
END;
```

```sql  
CREATE TRIGGER add_to_sync_deleted_messages AFTER DELETE ON message 
BEGIN
    INSERT INTO sync_deleted_messages (guid, recordID) 
    VALUES (OLD.guid, OLD.ck_record_id);
END;
```

```sql
CREATE TRIGGER after_delete_on_chat_recoverable_message_join AFTER DELETE ON chat_recoverable_message_join 
BEGIN
    UPDATE message
    SET cache_roomnames = (
        SELECT group_concat(c.room_name)
        FROM chat c
        INNER JOIN chat_message_join j ON c.ROWID = j.chat_id
        WHERE j.message_id = OLD.message_id
    )
    WHERE message.ROWID = OLD.message_id;
    
    DELETE FROM message 
    WHERE message.ROWID = OLD.message_id 
    AND OLD.message_id NOT IN (
        SELECT chat_message_join.message_id 
        FROM chat_message_join 
        WHERE chat_message_join.message_id = OLD.message_id 
        LIMIT 1
    ) 
    AND OLD.message_id NOT IN (
        SELECT chat_recoverable_message_join.message_id 
        FROM chat_recoverable_message_join 
        WHERE chat_recoverable_message_join.message_id = OLD.message_id 
        LIMIT 1
    );
END;
```

```sql  
CREATE TRIGGER after_delete_on_chat AFTER DELETE ON chat 
BEGIN 
    DELETE FROM chat_message_join WHERE chat_id = OLD.ROWID;
END;
```

```sql
CREATE TRIGGER before_delete_on_attachment BEFORE DELETE ON attachment 
BEGIN
    SELECT before_delete_attachment_path(OLD.ROWID, OLD.guid);
END;
```

```sql  
CREATE TRIGGER add_to_sync_deleted_attachments AFTER DELETE ON attachment 
BEGIN
    INSERT INTO sync_deleted_attachments (guid, recordID) 
    VALUES (OLD.guid, OLD.ck_record_id);
END;
```

```sql
CREATE TRIGGER delete_associated_messages_after_delete_on_message AFTER DELETE ON message 
BEGIN 
    DELETE FROM message 
    WHERE (OLD.associated_message_guid IS NULL AND associated_message_guid IS NOT NULL AND guid = OLD.associated_message_guid);
END;
```

```sql
CREATE TRIGGER add_to_deleted_messages AFTER DELETE ON message 
BEGIN
    INSERT INTO deleted_messages (guid) VALUES (OLD.guid);
END;
```

```sql
CREATE TRIGGER after_delete_on_message_attachment_join AFTER DELETE ON message_attachment_join 
BEGIN
    DELETE FROM attachment
    WHERE attachment.ROWID = OLD.attachment_id
    AND (SELECT 1 FROM message_attachment_join WHERE attachment_id = OLD.attachment_id LIMIT 1) IS NULL;
END;
```

```sql
CREATE TRIGGER update_last_failed_message_date AFTER UPDATE OF error ON message 
WHEN NEW.error != 0 AND NEW.date > COALESCE((SELECT value FROM kvtable WHERE key = 'lastFailedMessageDate'), 0)
BEGIN
    INSERT OR REPLACE INTO kvtable (key, value) VALUES ('lastFailedMessageDate', NEW.date);
    INSERT OR REPLACE INTO kvtable (key, value) VALUES ('lastFailedMessageRowID', NEW.rowID);
END;
```

## Tables

## Table: _SqliteDatabaseProperties

### Table: _SqliteDatabaseProperties
| Column | Type | Nullable | Default | Primary Key |
|--------|------|----------|----------|-------------|
| key | TEXT | Yes | | No |
| value | TEXT | Yes | | No |

Indexes:
- sqlite_autoindex__SqliteDatabaseProperties_1 (unique)

### Table: chat_message_join
| Column | Type | Nullable | Default | Primary Key |
|--------|------|----------|----------|-------------|
| chat_id | INTEGER | Yes | | Yes |
| message_id | INTEGER | Yes | | No |
| message_date | INTEGER | Yes | 0 | No |

Indexes:
- chat_message_join_idx_message_date_id_chat_id
- chat_message_join_idx_chat_id  
- chat_message_join_idx_message_id_only
- sqlite_autoindex_chat_message_join_1 (primary key)

Foreign Keys:
- message_id references message(ROWID) ON DELETE CASCADE
- chat_id references chat(ROWID) ON DELETE CASCADE

### Table: deleted_messages
| Column | Type | Nullable | Default | Primary Key |
|--------|------|----------|----------|-------------|
| ROWID | INTEGER | Yes | | Yes |
| guid | TEXT | No | | No |

Indexes:
- sqlite_autoindex_deleted_messages_1 (unique)

### Table: sqlite_sequence
| Column | Type | Nullable | Default | Primary Key |
|--------|------|----------|----------|-------------|
| name | | Yes | | No |
| seq | | Yes | | No |

### Table: chat_recoverable_message_join
| Column | Type | Nullable | Default | Primary Key |
|--------|------|----------|----------|-------------|
| chat_id | INTEGER | Yes | | Yes |
| message_id | INTEGER | Yes | | No |
| delete_date | INTEGER | Yes | | No |
| ck_sync_state | INTEGER | Yes | 0 | No |

Indexes:
- sqlite_autoindex_chat_recoverable_message_join_1 (primary key)

Foreign Keys:
- message_id references message(ROWID) ON DELETE CASCADE
- chat_id references chat(ROWID) ON DELETE CASCADE

### Table: handle
| Column | Type | Nullable | Default | Primary Key |
|--------|------|----------|----------|-------------|
| ROWID | INTEGER | Yes | | Yes |
| id | TEXT | No | | No |
| country | TEXT | Yes | | No |
| service | TEXT | No | | No |
| uncanonicalized_id | TEXT | Yes | | No |
| person_centric_id | TEXT | Yes | | No |

Indexes:
- sqlite_autoindex_handle_2 (unique)
- sqlite_autoindex_handle_1 (unique)

### Table: sync_deleted_chats
| Column | Type | Nullable | Default | Primary Key |
|--------|------|----------|----------|-------------|
| ROWID | INTEGER | Yes | | Yes |
| guid | TEXT | No | | No |
| recordID | TEXT | Yes | | No |
| timestamp | INTEGER | Yes | | No |

Indexes:
- sqlite_autoindex_sync_deleted_chats_1 (unique)

### Table: kvtable
| Column | Type | Nullable | Default | Primary Key |
|--------|------|----------|----------|-------------|
| ROWID | INTEGER | Yes | | Yes |
| key | TEXT | No | | No |
| value | BLOB | No | | No |

Indexes:
- sqlite_autoindex_kvtable_2 (unique)
- sqlite_autoindex_kvtable_1 (unique)

### Table: sync_deleted_attachments
| Column | Type | Nullable | Default | Primary Key |
|--------|------|----------|----------|-------------|
| ROWID | INTEGER | Yes | | Yes |
| guid | TEXT | No | | No |
| recordID | TEXT | Yes | | No |

Indexes:
- sqlite_autoindex_sync_deleted_attachments_1 (unique)

### Table: sync_deleted_messages
| Column | Type | Nullable | Default | Primary Key |
|--------|------|----------|----------|-------------|
| ROWID | INTEGER | Yes | | Yes |
| guid | TEXT | No | | No |
| recordID | TEXT | Yes | | No |

Indexes:
- sqlite_autoindex_sync_deleted_messages_1 (unique)

### Table: unsynced_removed_recoverable_messages
| Column | Type | Nullable | Default | Primary Key |
|--------|------|----------|----------|-------------|
| ROWID | INTEGER | Yes | | Yes |
| chat_guid | TEXT | No | | No |
| message_guid | TEXT | No | | No |
| part_index | INTEGER | Yes | | No |

Indexes:
- sqlite_autoindex_unsynced_removed_recoverable_messages_1 (unique)

### Table: recoverable_message_part
| Column | Type | Nullable | Default | Primary Key |
|--------|------|----------|----------|-------------|
| chat_id | INTEGER | Yes | | Yes |
| message_id | INTEGER | Yes | | No |
| part_index | INTEGER | Yes | | No |
| delete_date | INTEGER | Yes | | No |
| part_text | BLOB | No | | No |
| ck_sync_state | INTEGER | Yes | 0 | No |

Indexes:
- sqlite_autoindex_recoverable_message_part_1 (primary key)

Foreign Keys:
- message_id references message(ROWID) ON DELETE CASCADE
- chat_id references chat(ROWID) ON DELETE CASCADE

### Table: chat_handle_join
| Column | Type | Nullable | Default | Primary Key |
|--------|------|----------|----------|-------------|
| chat_id | INTEGER | Yes | | No |
| handle_id | INTEGER | Yes | | No |

Indexes:
- chat_handle_join_idx_handle_id
- sqlite_autoindex_chat_handle_join_1 (unique)

Foreign Keys:
- handle_id references handle(ROWID) ON DELETE CASCADE
- chat_id references chat(ROWID) ON DELETE CASCADE

### Table: message_attachment_join
| Column | Type | Nullable | Default | Primary Key |
|--------|------|----------|----------|-------------|
| message_id | INTEGER | Yes | | No |
| attachment_id | INTEGER | Yes | | No |

Indexes:
- message_attachment_join_idx_attachment_id
- message_attachment_join_idx_message_id
- sqlite_autoindex_message_attachment_join_1 (unique)

Foreign Keys:
- attachment_id references attachment(ROWID) ON DELETE CASCADE
- message_id references message(ROWID) ON DELETE CASCADE

### Table: message_processing_task
| Column | Type | Nullable | Default | Primary Key |
|--------|------|----------|----------|-------------|
| ROWID | INTEGER | Yes | | Yes |
| guid | TEXT | No | | No |
| task_flags | INTEGER | No | | No |

Indexes:
- message_processing_task_idx_guid_task_flags
- sqlite_autoindex_message_processing_task_1 (unique)

### Table: message
| Column | Type | Nullable | Default | Primary Key |
|--------|------|----------|----------|-------------|
| ROWID | INTEGER | Yes | | Yes |
| guid | TEXT | No | | No |
| text | TEXT | Yes | | No |
| replace | INTEGER | Yes | 0 | No |
| service_center | TEXT | Yes | | No |
| handle_id | INTEGER | Yes | 0 | No |
| subject | TEXT | Yes | | No |
| country | TEXT | Yes | | No |
| attributedBody | BLOB | Yes | | No |
| version | INTEGER | Yes | 0 | No |
| type | INTEGER | Yes | 0 | No |
| service | TEXT | Yes | | No |
| account | TEXT | Yes | | No |
| account_guid | TEXT | Yes | | No |
| error | INTEGER | Yes | 0 | No |
| date | INTEGER | Yes | | No |
| date_read | INTEGER | Yes | | No |
| date_delivered | INTEGER | Yes | | No |
| is_delivered | INTEGER | Yes | 0 | No |
| is_finished | INTEGER | Yes | 0 | No |
| is_emote | INTEGER | Yes | 0 | No |
| is_from_me | INTEGER | Yes | 0 | No |
| is_empty | INTEGER | Yes | 0 | No |
| is_delayed | INTEGER | Yes | 0 | No |
| is_auto_reply | INTEGER | Yes | 0 | No |
| is_prepared | INTEGER | Yes | 0 | No |
| is_read | INTEGER | Yes | 0 | No |
| is_system_message | INTEGER | Yes | 0 | No |
| is_sent | INTEGER | Yes | 0 | No |
| has_dd_results | INTEGER | Yes | 0 | No |
| is_service_message | INTEGER | Yes | 0 | No |
| is_forward | INTEGER | Yes | 0 | No |
| was_downgraded | INTEGER | Yes | 0 | No |
| is_archive | INTEGER | Yes | 0 | No |
| cache_has_attachments | INTEGER | Yes | 0 | No |
| cache_roomnames | TEXT | Yes | | No |
| was_data_detected | INTEGER | Yes | 0 | No |
| was_deduplicated | INTEGER | Yes | 0 | No |
| is_audio_message | INTEGER | Yes | 0 | No |
| is_played | INTEGER | Yes | 0 | No |
| date_played | INTEGER | Yes | | No |
| item_type | INTEGER | Yes | 0 | No |
| other_handle | INTEGER | Yes | 0 | No |
| group_title | TEXT | Yes | | No |
| group_action_type | INTEGER | Yes | 0 | No |
| share_status | INTEGER | Yes | 0 | No |
| share_direction | INTEGER | Yes | 0 | No |
| is_expirable | INTEGER | Yes | 0 | No |
| expire_state | INTEGER | Yes | 0 | No |
| message_action_type | INTEGER | Yes | 0 | No |
| message_source | INTEGER | Yes | 0 | No |
| associated_message_guid | TEXT | Yes | | No |
| associated_message_type | INTEGER | Yes | 0 | No |
| balloon_bundle_id | TEXT | Yes | | No |
| payload_data | BLOB | Yes | | No |
| expressive_send_style_id | TEXT | Yes | | No |
| associated_message_range_location | INTEGER | Yes | 0 | No |
| associated_message_range_length | INTEGER | Yes | 0 | No |
| time_expressive_send_played | INTEGER | Yes | | No |
| message_summary_info | BLOB | Yes | | No |
| ck_sync_state | INTEGER | Yes | 0 | No |
| ck_record_id | TEXT | Yes | | No |
| ck_record_change_tag | TEXT | Yes | | No |
| destination_caller_id | TEXT | Yes | | No |
| is_corrupt | INTEGER | Yes | 0 | No |
| reply_to_guid | TEXT | Yes | | No |
| sort_id | INTEGER | Yes | | No |
| is_spam | INTEGER | Yes | 0 | No |
| has_unseen_mention | INTEGER | Yes | 0 | No |
| thread_originator_guid | TEXT | Yes | | No |
| thread_originator_part | TEXT | Yes | | No |
| syndication_ranges | TEXT | Yes | | No |
| synced_syndication_ranges | TEXT | Yes | | No |
| was_delivered_quietly | INTEGER | Yes | 0 | No |
| did_notify_recipient | INTEGER | Yes | 0 | No |
| date_retracted | INTEGER | Yes | | No |
| date_edited | INTEGER | Yes | | No |
| was_detonated | INTEGER | Yes | 0 | No |
| part_count | INTEGER | Yes | | No |
| is_stewie | INTEGER | Yes | 0 | No |
| is_kt_verified | INTEGER | Yes | 0 | No |

Indexes:
- message_idx_failed
- message_idx_isRead_isFromMe_itemType
- message_idx_is_read
- message_idx_expire_state
- message_idx_was_downgraded
- message_idx_other_handle
- message_idx_cache_has_attachments
- message_idx_undelivered_one_to_one_imessage
- message_idx_associated_message
- message_idx_is_sent_is_from_me_error
- message_idx_handle_id
- message_idx_handle
- message_idx_thread_originator_guid
- message_idx_date
- sqlite_autoindex_message_1 (unique)

### Table: chat
| Column | Type | Nullable | Default | Primary Key |
|--------|------|----------|----------|-------------|
| ROWID | INTEGER | Yes | | Yes |
| guid | TEXT | No | | No |
| style | INTEGER | Yes | | No |
| state | INTEGER | Yes | | No |
| account_id | TEXT | Yes | | No |
| properties | BLOB | Yes | | No |
| chat_identifier | TEXT | Yes | | No |
| service_name | TEXT | Yes | | No |
| room_name | TEXT | Yes | | No |
| account_login | TEXT | Yes | | No |
| is_archived | INTEGER | Yes | 0 | No |
| last_addressed_handle | TEXT | Yes | | No |
| display_name | TEXT | Yes | | No |
| group_id | TEXT | Yes | | No |
| is_filtered | INTEGER | Yes | 0 | No |
| successful_query | INTEGER | Yes | | No |
| engram_id | TEXT | Yes | | No |
| server_change_token | TEXT | Yes | | No |
| ck_sync_state | INTEGER | Yes | 0 | No |
| original_group_id | TEXT | Yes | | No |
| last_read_message_timestamp | INTEGER | Yes | 0 | No |
| cloudkit_record_id | TEXT | Yes | | No |
| last_addressed_sim_id | TEXT | Yes | | No |
| is_blackholed | INTEGER | Yes | 0 | No |
| syndication_date | INTEGER | Yes | 0 | No |
| syndication_type | INTEGER | Yes | 0 | No |
| is_recovered | INTEGER | Yes | 0 | No |

Indexes:
- chat_idx_group_id
- chat_idx_is_archived
- chat_idx_chat_room_name_service_name
- chat_idx_chat_identifier
- chat_idx_chat_identifier_service_name
- sqlite_autoindex_chat_1 (unique)

### Table: attachment
| Column | Type | Nullable | Default | Primary Key |
|--------|------|----------|----------|-------------|
| ROWID | INTEGER | Yes | | Yes |
| guid | TEXT | No | | No |
| created_date | INTEGER | Yes | 0 | No |
| start_date | INTEGER | Yes | 0 | No |
| filename | TEXT | Yes | | No |
| uti | TEXT | Yes | | No |
| mime_type | TEXT | Yes | | No |
| transfer_state | INTEGER | Yes | 0 | No |
| is_outgoing | INTEGER | Yes | 0 | No |
| user_info | BLOB | Yes | | No |
| transfer_name | TEXT | Yes | | No |
| total_bytes | INTEGER | Yes | 0 | No |
| is_sticker | INTEGER | Yes | 0 | No |
| sticker_user_info | BLOB | Yes | | No |
| attribution_info | BLOB | Yes | | No |
| hide_attachment | INTEGER | Yes | 0 | No |
| ck_sync_state | INTEGER | Yes | 0 | No |
| ck_server_change_token_blob | BLOB | Yes | | No |
| ck_record_id | TEXT | Yes | | No |
| original_guid | TEXT | No | | No |
| is_commsafety_sensitive | INTEGER | Yes | 0 | No |

Indexes:
- attachment_idx_purged_attachments_v2
- sqlite_autoindex_attachment_2 (unique)
- sqlite_autoindex_attachment_1 (unique)

### Table: sqlite_stat1
| Column | Type | Nullable | Default | Primary Key |
|--------|------|----------|----------|-------------|
| tbl | | Yes | | No |
| idx | | Yes | | No |
| stat | | Yes | | No |




Enumerating nicknames database at /Users/darmado/Library/Messages/NickNameCache/nickNameKeyStore.db

Schema for /Users/darmado/Library/Messages/NickNameCache/nickNameKeyStore.db:
```sql
CREATE TABLE _SqliteDatabaseProperties (key TEXT, value TEXT, UNIQUE(key));
CREATE TABLE kvtable (ROWID INTEGER PRIMARY KEY AUTOINCREMENT, key TEXT UNIQUE NOT NULL, value BLOB NOT NULL, value_type INTEGER, date INTEGER);
CREATE TABLE sqlite_sequence(name,seq);
CREATE INDEX idx_key ON kvtable (key);
```

### Table: _SqliteDatabaseProperties

| Column | Type | Nullable | Default | Primary Key |
|--------|------|----------|----------|-------------|
| key | TEXT | 0 | | 0 |
| value | TEXT | 0 | | 0 |

Indexes:
- sqlite_autoindex__SqliteDatabaseProperties_1 (unique)



Table: kvtable

| Column | Type | Nullable | Default | Primary Key |
|--------|------|----------|----------|-------------|
| ROWID | INTEGER | 0 | | 1 |
| key | TEXT | 1 | | 0 |
| value | BLOB | 1 | | 0 |
| value_type | INTEGER | 0 | | 0 |
| date | INTEGER | 0 | | 0 |

Indexes:
- idx_key
- sqlite_autoindex_kvtable_1 (unique)



Table: sqlite_sequence

| Column | Type | Nullable | Default | Primary Key |
|--------|------|----------|----------|-------------|
| name | | 0 | | 0 |
| seq | | 0 | | 0 |




Enumerating sharing database at /Users/darmado/Library/Messages/NickNameCache/handleSharingPreferences.db

Schema for /Users/darmado/Library/Messages/NickNameCache/handleSharingPreferences.db:
```sql
CREATE TABLE _SqliteDatabaseProperties (key TEXT, value TEXT, UNIQUE(key));
CREATE TABLE kvtable (ROWID INTEGER PRIMARY KEY AUTOINCREMENT, key TEXT UNIQUE NOT NULL, value BLOB NOT NULL, value_type INTEGER, date INTEGER);
CREATE TABLE sqlite_sequence(name,seq);
CREATE INDEX idx_key ON kvtable (key);
```

Table: _SqliteDatabaseProperties

| Column | Type | Nullable | Default | Primary Key |
|--------|------|----------|----------|-------------|
| key | TEXT | 0 | | 0 |
| value | TEXT | 0 | | 0 |

Indexes:
- sqlite_autoindex__SqliteDatabaseProperties_1 (unique)



Table: kvtable

| Column | Type | Nullable | Default | Primary Key |
|--------|------|----------|----------|-------------|
| ROWID | INTEGER | 0 | | 1 |
| key | TEXT | 1 | | 0 |
| value | BLOB | 1 | | 0 |
| value_type | INTEGER | 0 | | 0 |
| date | INTEGER | 0 | | 0 |

Indexes:
- idx_key
- sqlite_autoindex_kvtable_1 (unique)



Table: sqlite_sequence

| Column | Type | Nullable | Default | Primary Key |
|--------|------|----------|----------|-------------|
| name | | 0 | | 0 |
| seq | | 0 | | 0 |




## 4. Collaboration Database (collaborationNotices.db)
Location: `/Users/darmado/Library/Messages/CollaborationNoticeCache/collaborationNotices.db`

Schema for /Users/darmado/Library/Messages/CollaborationNoticeCache/collaborationNotices.db:
```sql
CREATE TABLE ZNOTICE ( Z_PK INTEGER PRIMARY KEY, Z_ENT INTEGER, Z_OPT INTEGER, ZVERSION INTEGER, ZDATE TIMESTAMP, ZDATEVIEWED TIMESTAMP, ZGUIDSTRING VARCHAR, ZSENDERHANDLE VARCHAR, ZURL VARCHAR, ZMETADATA BLOB );
CREATE TABLE Z_PRIMARYKEY (Z_ENT INTEGER PRIMARY KEY, Z_NAME VARCHAR, Z_SUPER INTEGER, Z_MAX INTEGER);
CREATE TABLE Z_METADATA (Z_VERSION INTEGER PRIMARY KEY, Z_UUID VARCHAR(255), Z_PLIST BLOB);
CREATE TABLE Z_MODELCACHE (Z_CONTENT BLOB);
```

Table: ZNOTICE

| Column | Type | Nullable | Default | Primary Key |
|--------|------|----------|----------|-------------|
| Z_PK | INTEGER | 0 | | 1 |
| Z_ENT | INTEGER | 0 | | 0 |
| Z_OPT | INTEGER | 0 | | 0 |
| ZVERSION | INTEGER | 0 | | 0 |
| ZDATE | TIMESTAMP | 0 | | 0 |
| ZDATEVIEWED | TIMESTAMP | 0 | | 0 |
| ZGUIDSTRING | VARCHAR | 0 | | 0 |
| ZSENDERHANDLE | VARCHAR | 0 | | 0 |
| ZURL | VARCHAR | 0 | | 0 |
| ZMETADATA | BLOB | 0 | | 0 |




Table: Z_PRIMARYKEY

| Column | Type | Nullable | Default | Primary Key |
|--------|------|----------|----------|-------------|
| Z_ENT | INTEGER | 0 | | 1 |
| Z_NAME | VARCHAR | 0 | | 0 |
| Z_SUPER | INTEGER | 0 | | 0 |
| Z_MAX | INTEGER | 0 | | 0 |




Table: Z_METADATA

| Column | Type | Nullable | Default | Primary Key |
|--------|------|----------|----------|-------------|
| Z_VERSION | INTEGER | 0 | | 1 |
| Z_UUID | VARCHAR(255) | 0 | | 0 |
| Z_PLIST | BLOB | 0 | | 0 |




Table: Z_MODELCACHE

    | Column | Type | Nullable | Default | Primary Key |
|--------|------|----------|----------|-------------|
| Z_CONTENT | BLOB | 0 | | 0 |




## 5. Handled Nicknames (handledNicknamesKeyStore.db)
Location: `~/Library/Messages/NickNameCache/handledNicknamesKeyStore.db`

## 6. Pending Nicknames (pendingNicknamesKeyStore.db)
Location: `~/Library/Messages/NickNameCache/pendingNicknamesKeyStore.db`

## 7. Prewarm Database (prewarm.db)
Location: `~/Library/Messages/prewarm.db`

## Database Locations Summary
```javascript
const DB_PATHS = {
    main: '~/Library/Messages/chat.db',
    nicknames: '~/Library/Messages/NickNameCache/nickNameKeyStore.db',
    sharing: '~/Library/Messages/NickNameCache/handleSharingPreferences.db',
    collab: '~/Library/Messages/CollaborationNoticeCache/collaborationNotices.db',
    handledNicknames: '~/Library/Messages/NickNameCache/handledNicknamesKeyStore.db',
    pendingNicknames: '~/Library/Messages/NickNameCache/pendingNicknamesKeyStore.db',
    prewarm: '~/Library/Messages/prewarm.db'
};
```

## Key Relationships & Queries

### Primary Relationships

1. Message-Handle Relationship
```sql
message.handle_id -> handle.ROWID
message.other_handle -> handle.ROWID
```

2. Message-Chat Relationship (via join table)
```sql
chat_message_join.message_id -> message.ROWID
chat_message_join.chat_id -> chat.ROWID
```

3. Message-Attachment Relationship (via join table)
```sql
message_attachment_join.message_id -> message.ROWID
message_attachment_join.attachment_id -> attachment.ROWID
```

4. Chat-Handle Relationship (via join table)
```sql
chat_handle_join.chat_id -> chat.ROWID
chat_handle_join.handle_id -> handle.ROWID
```

### Common Query Patterns

1. Get Messages with Sender Info
```sql
SELECT m.*, h.id, h.service 
FROM message m 
JOIN handle h ON m.handle_id = h.ROWID
```

2. Get Chat Messages with Participants
```sql
SELECT c.chat_identifier, m.text, h.id
FROM chat c
JOIN chat_message_join cmj ON c.ROWID = cmj.chat_id
JOIN message m ON cmj.message_id = m.ROWID
JOIN handle h ON m.handle_id = h.ROWID
```

3. Get Messages with Attachments
```sql
SELECT m.text, a.filename, a.mime_type
FROM message m
JOIN message_attachment_join maj ON m.ROWID = maj.message_id
JOIN attachment a ON maj.attachment_id = a.ROWID
```

### Extended Relationships & Queries

### Direct Table Relationships

1. Message Core Relationships
```sql
message.handle_id -> handle.ROWID                     # Primary sender
message.other_handle -> handle.ROWID                  # Secondary participant
message.associated_message_guid -> message.guid       # Related messages
message.reply_to_guid -> message.guid                 # Reply chains
message.thread_originator_guid -> message.guid        # Thread tracking
```

2. Chat Relationships
```sql
chat.last_addressed_handle -> handle.id               # Last active participant
chat.original_group_id -> chat.group_id              # Group chat history
chat.account_id -> message.account                    # Account linking
```

3. Attachment Relationships
```sql
attachment.guid -> message_attachment_join.attachment_id  # Attachment linking
attachment.original_guid -> attachment.guid              # Original file reference
```

4. Recovery & Sync Relationships
```sql
chat_recoverable_message_join.message_id -> message.ROWID    # Recoverable messages
chat_recoverable_message_join.chat_id -> chat.ROWID         # Recovery context
recoverable_message_part.message_id -> message.ROWID        # Message parts
sync_deleted_messages.guid -> message.guid                  # Deletion tracking
sync_deleted_attachments.guid -> attachment.guid           # Attachment cleanup
sync_deleted_chats.guid -> chat.guid                      # Chat removal
```

### Complex Relationships

1. Message Threading
```sql
-- Get full message thread
SELECT m2.*
FROM message m1
JOIN message m2 ON (
    m2.thread_originator_guid = m1.guid OR
    m2.associated_message_guid = m1.guid OR
    m2.reply_to_guid = m1.guid
)
WHERE m1.ROWID = ?
```

2. Chat Participant History
```sql
-- Get all participants in a chat over time
SELECT DISTINCT h.* 
FROM chat c
JOIN chat_handle_join chj ON c.ROWID = chj.chat_id
JOIN handle h ON chj.handle_id = h.ROWID
WHERE c.ROWID = ?
UNION
SELECT h.* 
FROM chat c
JOIN chat_message_join cmj ON c.ROWID = cmj.chat_id
JOIN message m ON cmj.message_id = m.ROWID
JOIN handle h ON m.handle_id = h.ROWID
WHERE c.ROWID = ?
```

3. Message Recovery Chain
```sql
-- Get recoverable message parts
SELECT m.*, rmp.part_text, rmp.delete_date
FROM message m
JOIN chat_recoverable_message_join crmj ON m.ROWID = crmj.message_id
JOIN recoverable_message_part rmp ON (
    crmj.chat_id = rmp.chat_id AND
    crmj.message_id = rmp.message_id
)
```

4. Attachment History
```sql
-- Get attachment history with sync status
SELECT a.*, 
    sda.recordID as sync_record,
    m.date as message_date
FROM attachment a
LEFT JOIN sync_deleted_attachments sda ON a.guid = sda.guid
JOIN message_attachment_join maj ON a.ROWID = maj.attachment_id
JOIN message m ON maj.message_id = m.ROWID
```

### Cross-Database Relationships

1. Nickname Resolution
```sql
-- Linking handles to nicknames across databases
handle.id -> nickNameKeyStore.db:kvtable.key
handle.id -> handleSharingPreferences.db:kvtable.key
```

2. Collaboration Tracking
```sql
-- Linking collaboration notices to messages
collaborationNotices.db:ZNOTICE.ZGUIDSTRING -> message.guid
collaborationNotices.db:ZNOTICE.ZSENDERHANDLE -> handle.id
```

## Additional Complex Relationships

### Message State Tracking
```sql
-- Track message state changes across delivery/read/edit
message.guid -> {
    message.date_delivered,
    message.date_read,
    message.date_edited,
    message.date_retracted,
    message.date_played
}

-- Track failed message history
message.error -> kvtable.key['lastFailedMessageDate']
message.ROWID -> kvtable.key['lastFailedMessageRowID']
```

### Message Threading & References
```sql
-- Full message reference chain
message.guid -> {
    message.associated_message_guid,
    message.reply_to_guid,
    message.thread_originator_guid,
    message.thread_originator_part
}

-- Message range references
message.associated_message_range_location + 
message.associated_message_range_length -> message.text
```

### Chat State Management
```sql
-- Chat synchronization chain
chat.guid -> {
    chat.server_change_token,
    chat.cloudkit_record_id,
    chat.ck_sync_state
}

-- Group chat evolution
chat.group_id -> chat.original_group_id
chat.room_name -> message.cache_roomnames
```

### Attachment Lifecycle
```sql
-- Attachment state tracking
attachment.guid -> {
    attachment.original_guid,
    attachment.ck_record_id,
    attachment.ck_server_change_token_blob
}

-- Attachment cleanup chain
attachment.filename -> {
    before_delete_attachment_path(),
    delete_attachment_path()
}
```

### Recovery & Deletion Tracking
```sql
-- Message recovery chain
message.ROWID -> {
    chat_recoverable_message_join.message_id,
    recoverable_message_part.message_id,
    unsynced_removed_recoverable_messages.message_guid
}

-- Deletion tracking across databases
message.guid -> {
    deleted_messages.guid,
    sync_deleted_messages.guid,
    sync_deleted_messages.recordID
}
```

### Handle (Contact) Relationships
```sql
-- Contact identity chain
handle.id -> {
    handle.uncanonicalized_id,
    handle.person_centric_id
}

-- Service mapping
handle.service + handle.id -> UNIQUE constraint
```

### Cross-Database State Management
```sql
-- Nickname resolution chain
handle.id -> {
    nickNameKeyStore.db:kvtable.key,
    handledNicknamesKeyStore.db:kvtable.key,
    pendingNicknamesKeyStore.db:kvtable.key
}

-- Collaboration tracking
message.guid -> collaborationNotices.db:ZNOTICE.ZGUIDSTRING
handle.id -> collaborationNotices.db:ZNOTICE.ZSENDERHANDLE
```

### Implicit Relationships Through Triggers
```sql
-- Message cleanup cascade
DELETE message -> {
    chat_message_join cleanup,
    handle cleanup,
    attachment cleanup
}

-- Chat cleanup cascade
DELETE chat -> chat_message_join cleanup

-- Attachment cleanup cascade
DELETE attachment -> {
    filename cleanup,
    sync state update
}
```

### Metadata & System Tables
```sql
-- System property tracking
_SqliteDatabaseProperties.key -> _SqliteDatabaseProperties.value

-- Statistics and optimization
sqlite_stat1.tbl + sqlite_stat1.idx -> table/index statistics
```

### Processing & Task Management
```sql
-- Message processing workflow
message_processing_task.guid -> message.guid
message_processing_task.task_flags -> processing state
```

### Security & Safety Features
```sql
-- Communication safety
attachment.is_commsafety_sensitive -> filtering state
message.is_spam -> filtering state
```

### Message Flags & States
```sql
-- Message Lifecycle States
is_prepared:         -- Message ready for sending
is_sent:            -- Transmission completed
is_delivered:       -- Recipient received message
is_read:            -- Recipient viewed message
is_played:          -- Audio/media was played
is_finished:        -- Message processing complete

-- Timestamps for State Changes
date:               -- Original message time
date_delivered:     -- Delivery confirmation time
date_read:          -- Read receipt time
date_played:        -- Media playback time
date_edited:        -- Last edit timestamp
date_retracted:     -- Message recall time

-- Security & Safety States
is_kt_verified:     -- Known Traveler verification
is_corrupt:         -- Data integrity compromised
is_spam:           -- Spam detection flag
was_downgraded:    -- Service fallback occurred

-- Safety Features
is_commsafety_sensitive:  -- Content safety flag
was_delivered_quietly:    -- Silent delivery
did_notify_recipient:     -- Notification tracking
has_unseen_mention:      -- Mention alert status

-- Special Message Types
is_stewie:          -- Internal Apple flag (purpose unknown)
is_expirable:       -- Self-destructing message
was_detonated:      -- Self-destruct completed
is_auto_reply:      -- Automated response
is_service_message: -- System/service notification
is_forward:         -- Forwarded content

-- Content Type Indicators
is_audio_message:   -- Voice message
is_emote:          -- Reaction/expression
is_empty:          -- No content
cache_has_attachments: -- Has media/files
was_data_detected: -- Contains detectable data (links, dates)
```

### Index Analysis
```sql
-- Performance Optimizations
message_idx_undelivered_one_to_one_imessage  -- Track undelivered direct messages
message_idx_isRead_isFromMe_itemType         -- Quick message status lookup
message_idx_failed                           -- Failed message tracking
message_idx_thread_originator_guid           -- Thread organization
message_idx_cache_has_attachments            -- Attachment presence check
message_idx_expire_state                     -- Expiring message tracking

-- Complex Conditions
attachment_idx_purged_attachments_v2         -- Complex cleanup condition
WHERE hide_attachment=0 
  AND (ck_sync_state=1 OR ck_sync_state=4) 
  AND transfer_state=0
```

### BLOB Data Structures
```sql
-- Message BLOBs
message.attributedBody           -- Rich text formatting
message.payload_data            -- Message-specific data
message.message_summary_info    -- Preview/summary data

-- Attachment BLOBs
attachment.user_info           -- Attachment metadata
attachment.sticker_user_info   -- Sticker-specific data
attachment.attribution_info    -- Source/copyright info
attachment.ck_server_change_token_blob -- Sync state

-- Chat BLOB
chat.properties               -- Chat settings/properties

-- Collaboration BLOB
ZNOTICE.ZMETADATA           -- Collaboration data
Z_METADATA.Z_PLIST          -- Core Data metadata
Z_MODELCACHE.Z_CONTENT      -- Cache data
```