# Messages Database Column Relationships

## Table Relationship Patterns

### Join Table Pattern
Tables ending with "_join" serve as relationship tables between primary data tables:

```sql
-- List of Join Tables
chat_message_join              -- Links chats to messages
chat_handle_join              -- Links chats to handles (participants)
message_attachment_join       -- Links messages to attachments
chat_recoverable_message_join -- Links chats to recoverable messages
```

### Primary Tables
Core tables that store the primary data:
```sql
message      -- Core message data
chat         -- Conversation/group data
handle       -- Contact/participant data
attachment   -- File/media data
```

### Example Relationships
```sql
-- Messages to Attachments
message_attachment_join:
   message_id = 22        -- References message.ROWID
attachment_id = 1         -- References attachment.ROWID

-- Chats to Messages
chat_message_join:
     chat_id = 1         -- References chat.ROWID
  message_id = 1         -- References message.ROWID
message_date = 737495747236437504
```

### Complete Table List
```sql
_SqliteDatabaseProperties              message
attachment                             message_attachment_join
chat                                   message_processing_task
chat_handle_join                       recoverable_message_part
chat_message_join                      sync_deleted_attachments
chat_recoverable_message_join          sync_deleted_chats
deleted_messages                       sync_deleted_messages
handle                                 unsynced_removed_recoverable_messages
```

## Table Structure Examples

### Chat Table Structure
```sql
sqlite> SELECT * FROM chat LIMIT 1;
                      ROWID = 1
                       guid = iMessage;-;+55555555555
                      style = 45
                      state = 3
                 account_id = E8384767-85AE-4754-9EFC-8FDE4F542A86
                 properties = bplist00Rpv_numberOfTimesRespondedtoThreadTLSMD_shouldForceToSMS
            chat_identifier = +55555555555
               service_name = iMessage
                  room_name =
              account_login = E:random@random.com
                is_archived = 0
      last_addressed_handle = +55555555555
               display_name =
                   group_id = 401571F0-563A-44F4-ACB4-7E6D72488DE8
                is_filtered = 0
           successful_query = 1
                  engram_id =
        server_change_token =
              ck_sync_state = 0
          original_group_id = 401571F0-563A-44F4-ACB4-7E6D72488DE8
last_read_message_timestamp = 744935947025035648
         cloudkit_record_id =
      last_addressed_sim_id =
              is_blackholed = 0
           syndication_date = 0
           syndication_type = 0
               is_recovered = 0
```

### Message Table Structure
```sql
sqlite> SELECT * FROM message LIMIT 1;
[Message table structure as shown in example...]
```

### Key Observations:
1. Tables ending in "_join" are relationship tables
2. Column names ending in "_id" reference ROWID of another table
3. Primary tables (message, chat, handle, attachment) store core data
4. Join tables maintain relationships with minimal additional data
5. Each join table clearly indicates its purpose in its name

# Message Recovery Relationships

## chat_recoverable_message_join
Links deleted but recoverable messages to their chats:

- chat_id -> chat.ROWID
- message_id -> message.ROWID
- delete_date: Timestamp when message was deleted
- ck_sync_state: CloudKit sync status

This table acts as a recovery index for messages that were deleted but could potentially be recovered. The relationships are:

1. chat_id references chat.ROWID
   - Identifies which conversation the deleted message belonged to
   - One chat can have many recoverable messages

2. message_id references message.ROWID  
   - Points to the actual deleted message content
   - One message can only be in one recovery record

The delete_date field helps track when messages were deleted and could be used to implement time-based recovery windows.

# Deletion-Related Relationships

## Primary Tables
1. deleted_messages -> message
   ```sql
   deleted_messages.guid -> message.guid
   ```

2. sync_deleted_messages -> message
   ```sql
   sync_deleted_messages.guid -> message.guid
   sync_deleted_messages.recordID -> message.ck_record_id
   ```

3. chat_recoverable_message_join
   ```sql
   chat_recoverable_message_join.message_id -> message.ROWID
   chat_recoverable_message_join.chat_id -> chat.ROWID
   ```

## Deletion States
Messages can be in multiple deletion states:
1. Soft-deleted: Present in chat_recoverable_message_join
2. Pending sync: In unsynced_removed_recoverable_messages
3. Synced deletion: In sync_deleted_messages
4. Local deletion: In deleted_messages