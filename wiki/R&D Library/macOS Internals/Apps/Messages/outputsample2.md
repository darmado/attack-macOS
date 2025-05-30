# Message Sample Data Analysis

## SQLite Query
```sql
sqlite> "SELECT ROWID, service, service_center, version, type, error, destination_caller_id, message_source, is_auto_reply, is_system_message, is_service_message, is_forward, is_emote, is_audio_message, item_type, message_action_type, account, account_guid, handle_id, country, text, subject, attributedBody, message_summary_info, payload_data, balloon_bundle_id, cache_roomnames, part_count, is_delivered, is_sent, is_read, is_played, is_prepared, is_finished, was_delivered_quietly, did_notify_recipient, was_downgraded, was_detonated, is_delayed, is_empty, is_archive, is_spam, is_corrupt, is_expirable, expire_state, replace, reply_to_guid, thread_originator_guid, thread_originator_part, associated_message_guid, associated_message_type, associated_message_range_location, associated_message_range_length, share_status, share_direction, group_action_type, ck_sync_state, sort_id, date, date_read, date_delivered, date_played, date_retracted, date_edited, time_expressive_send_played FROM message where guid='BBE5511E-C8E1-4180-878F-8FDBFD149B81';"

ROWID                                  service   service_center  version  type  error  destination_caller_id  message_source  guid                                  is_auto_reply  is_system_message  is_service_message  is_forward  is_emote  is_audio_message  item_type  message_action_type  account             account_guid                          handle_id  country  text                                                          subject  attributedBody             message_summary_info  payload_data  balloon_bundle_id  cache_roomnames  part_count  is_delivered  is_sent  is_read  is_played  is_prepared  is_finished  was_delivered_quietly  did_notify_recipient  was_downgraded  was_detonated  is_delayed  is_empty  is_archive  is_spam  is_corrupt  is_expirable  expire_state  replace  reply_to_guid  thread_originator_guid  thread_originator_part  associated_message_guid  associated_message_type  associated_message_range_location  associated_message_range_length  share_status  share_direction  group_action_type  ck_sync_state  sort_id  date                date_read  date_delivered  date_played  date_retracted  date_edited  time_expressive_send_played
-----  ------------------------------------  --------  --------------  -------  ----  -----  ---------------------  --------------  ------------------------------------  -------------  -----------------  ------------------  ----------  --------  ----------------  ---------  -------------------  ------------------  ------------------------------------  ---------  -------  ------------------------------------------------------------  -------  -------------------------  --------------------  ------------  -----------------  ---------------  ----------  ------------  -------  -------  ---------  -----------  -----------  ---------------------  --------------------  --------------  -------------  ----------  --------  ----------  -------  ----------  ------------  ------------  -------  -------------  ----------------------  ----------------------  -----------------------  -----------------------  ---------------------------------  -------------------------------  ------------  ---------------  -----------------  -------------  -------  ------------------  ---------  --------------  -----------  --------------  -----------  ---------------------------
9476|BBE5511E-C8E1-4180-878F-8FDBFD149B81|Hello, we noticed that your background and resume have been recommended by several online recruitment agencies, so we are willing to offer you a part-time job that you can do in your free time. Our job is simple and there is dedicated training. The working time is 1 hour per day and the working location is flexible. The daily salary is between 200 and 3000 US dollars, and all wages are paid on the same day.
This job can bring a good income to the family, with a minimum monthly income of 10,000 US dollars. Regular employees enjoy 10-20 days of paid annual leave. We sincerely invite you to join our team. If you are interested, please contact us by adding WhatsApp: +13802547512|0||79|||
```

## Raw Query Output

### Referenced Fields
| Object | Field | Description | Value | Index |
|--------|-------|-------------|--------|--------|
| job | job_id | Unique job identifier | JOB-iMessage | - |
| job | user | Username | USER_INFO.username | - |
| job | executor | Script executor | osascript | - |
| job | language | Script language | jxa | - |
| job | imports | Required imports | ["Foundation", "CoreServices"] | - |
| job | binaries | Required binaries | ["sqlite3"] | - |
| job | pid | Process ID | NSProcessInfo.processIdentifier | - |
| job | host | Host name | NSHost.currentHost.localizedName | - |
| job | syscall | System call number | 1 | - |
| job.query | timestamp | Query timestamp | ISO timestamp | - |
| job.query | source_db | Database path | DB_PATHS.main | - |
| job.query | type | Query type | discover | - |
| job.query | ROWID | Row identifier | 9476 | 0 |
| app | service | Service type | iMessage | 1 |
| app | service_center | Service center | NULL | 2 |
| app | version | Version number | 10 | 3 |
| app | type | Message type | 0 | 4 |
| app | error | Error code | 0 | 5 |
| app | destination_caller_id | Destination ID | +14086395605 | 6 |
| app | message_source | Message source | 0 | 7 |
| message.type | is_auto_reply | Auto reply flag | 0 | 9 |
| message.type | is_system_message | System message flag | 0 | 10 |
| message.type | is_service_message | Service message flag | 0 | 11 |
| message.type | is_forward | Forward flag | 0 | 12 |
| message.type | is_emote | Emote flag | 0 | 13 |
| message.type | is_audio_message | Audio message flag | 0 | 14 |
| message.type | item_type | Item type | 0 | 15 |
| message.type | message_action_type | Action type | 0 | 16 |
| message.communication.sender | account | Sender account | E:daniel@armado.io | 17 |
| message.communication.sender | account_guid | Sender GUID | E8384767-85AE-4754-9EFC-8FDE4F542A86 | 18 |
| message.communication.sender | handle_id | Handle ID | 79 | 19 |
| message.communication.sender | country | Country code | NULL | 20 |
| message.content.data | text | Message text | Hello, we noticed that... | 27 |
| message.content.data | subject | Message subject | NULL | 28 |
| message.content.attachments | payload_data | Attachment data | bplist00SamcSust | 29 |
| message.content.attachments | balloon_bundle_id | Bundle ID | NULL | 30 |
| message.content.attachments | cache_roomnames | Room names | NULL | 31 |
| message.content | part_count | Number of parts | 1 | 32 |
| message.status.delivery | is_delivered | Delivery status | 1 | 33 |
| message.status.delivery | is_sent | Sent status | 0 | 34 |
| message.status.delivery | is_read | Read status | 0 | 35 |
| message.status.delivery | is_played | Played status | 0 | 36 |
| message.status.delivery | is_prepared | Prepared status | 0 | 37 |
| message.status.delivery | is_finished | Finished status | 1 | 38 |
| message.status.delivery | was_delivered_quietly | Quiet delivery | 0 | 39 |
| message.status.delivery | did_notify_recipient | Notification status | 0 | 40 |
| message.status.delivery | was_downgraded | Downgrade status | 0 | 41 |
| message.status.delivery | was_detonated | Detonation status | 0 | 42 |
| message.status.delivery | is_delayed | Delay status | 0 | 43 |
| message.status.state | is_empty | Empty status | 0 | 44 |
| message.status.state | is_archive | Archive status | 0 | 45 |
| message.status.state | is_spam | Spam status | 0 | 46 |
| message.status.state | is_corrupt | Corrupt status | 0 | 47 |
| message.status.state | is_expirable | Expirable status | 0 | 48 |
| message.status.state | expire_state | Expiration state | 0 | 49 |
| message.status.state | replace | Replace status | 0 | 50 |
| message.threading | reply_to_guid | Reply GUID | NULL | 51 |
| message.threading | thread_originator_guid | Thread GUID | NULL | 52 |
| message.threading | thread_originator_part | Thread part | NULL | 53 |
| message.threading.associated_message | guid | Associated GUID | NULL | 54 |
| message.threading.associated_message | type | Associated type | 0 | 55 |
| message.threading.associated_message | range_location | Range location | 0 | 56 |
| message.threading.associated_message | range_length | Range length | 0 | 57 |
| message.sharing | share_status | Share status | 0 | 58 |
| message.sharing | share_direction | Share direction | 0 | 59 |
| message.sharing | group_action_type | Group action | 0 | 60 |
| message.sync | ck_sync_state | Sync state | 0 | 61 |
| message.sync | sort_id | Sort ID | 0 | 62 |
| message.timestamps | date | Creation date | 750604936604725376 | 63 |
| message.timestamps | date_read | Read date | 0 | 64 |
| message.timestamps | date_delivered | Delivery date | 0 | 65 |
| message.timestamps | date_played | Played date | 0 | 66 |
| message.timestamps | date_retracted | Retraction date | 0 | 67 |
| message.timestamps | date_edited | Edit date | 0 | 68 |
| message.timestamps | time_expressive_send_played | Expression play time | 0 | 69 |

##

### Additional Fields from Query - that aren't part of the JSON OUTPUT 
| Index | Field | Type | How To use |
|-------|--------|------|------------|
| - | is_from_me | Boolean | use as loical field. If retuens 0, then the account, is theh recipient, if 1, then the account is the sender. |
| - | has_dd_results | Boolean | |
| - | cache_has_attachments | Boolean | |
| - | was_data_detected | Boolean | |
| - | was_deduplicated | Boolean | |
| - | other_handle | String | |
| - | group_title | String | |
| - | expressive_send_style_id | Integer | |
| - | ck_record_id | String | |
| - | ck_record_change_tag | String | |
| - | has_unseen_mention | Boolean | |
| - | syndication_ranges | String | |
| - | synced_syndication_ranges | String | |
| - | is_stewie | Boolean | |
| - | is_kt_verified | Boolean | |


# Current Output
```json

```

## Expected Structured JSON Output
```json                   
    job: {
        job_id: `JOB-${fields[1]}`,                                  
        user: USER_INFO.username,                                    
        executor: "osascript",                                          
        language: "jxa",                                              
        imports: ["Foundation", "CoreServices"],                       
        binaries: ["sqlite3"],                                        
        pid: $.NSProcessInfo.processInfo.processIdentifier,            
        host: $.NSHost.currentHost.localizedName,                    
        syscall: 1,                                                    
        query: {
            timestamp: new Date().toISOString(),                     
            source_db: DB_PATHS.main,                                  
            type: "discover",                                          
            ROWID: parseInt(fields[0])                                  // 0
        }
    },
    app: {
            service: fields[1],                                        // 1 
            service_center: fields[2],                                 // 2
            version: parseInt(fields[3]) || 0,                         // 3
            type: parseInt(fields[4]) || 0,                           // 4
            error: parseInt(fields[5]) || 0,                          // 5
            destination_caller_id: fields[6],                         // 6
            message_source: parseInt(fields[7]) || 0                  // 7
        },
    message: {
        guid: fields[8],                                              // 8
        type: {
            is_auto_reply: fields[9] === '1',                         // 9
            is_system_message: fields[10] === '1',                     // 10
            is_service_message: fields[11] === '1',                    // 11
            is_forward: fields[12] === '1',                            // 12
            is_emote: fields[13] === '1',                             // 13
            is_audio_message: fields[14] === '1',                      // 14
            item_type: parseInt(fields[15]) || 0,                      // 15
            message_action_type: parseInt(fields[16]) || 0             // 16
        },
        communication: {
            sender: {
                account: fields[17],                                    // 17
                account_guid: fields[18],                               // 18
                phone_number: fields[19],                               // 19
                country: fields[20],                                    // 20
                uncanonicalized_id: null,                              
                person_centric_id: null,                               
                handle_id: parseInt(fields[21]) || null                 // 21
            },
            receiver: {
                handle_id: parseInt(fields[22]) || null,                // 22
                account: fields[23],                                    // 23
                account_guid: fields[24],                               // 24
                phone_number: fields[25],                               // 25
                country: fields[26],                                    // 26
                uncanonicalized_id: null,                              
                person_centric_id: null                                
            }
        },
        content: {
            data: {
                text: fields[27],                                       // 27
                subject: fields[28],                                    // 28
            },
            attachments: {
                payload_data: fields[29],                               // 29
                balloon_bundle_id: fields[30],                          // 30
                cache_roomnames: fields[31]                             // 31
            },
            part_count: parseInt(fields[32]) || 1                       // 32
        },
        status: {
            delivery: {
                is_delivered: fields[33] === '1',                       // 33
                is_sent: fields[34] === '1',                           // 34
                is_read: fields[35] === '1',                           // 35
                is_played: fields[36] === '1',                         // 36
                is_prepared: fields[37] === '1',                       // 37
                is_finished: fields[38] === '1',                       // 38
                was_delivered_quietly: fields[39] === '1',             // 39
                did_notify_recipient: fields[40] === '1',              // 40
                was_downgraded: fields[41] === '1',                    // 41
                was_detonated: fields[42] === '1',                     // 42
                is_delayed: fields[43] === '1'                         // 43
            },
            state: {
                is_empty: fields[44] === '1',                          // 44
                is_archive: fields[45] === '1',                        // 45
                is_spam: fields[46] === '1',                           // 46
                is_corrupt: fields[47] === '1',                        // 47
                is_expirable: fields[48] === '1',                      // 48
                expire_state: parseInt(fields[49]) || 0,               // 49
                replace: parseInt(fields[50]) || 0                      // 50
            }
        },
        threading: {
            reply_to_guid: fields[51],                                 // 51
            thread_originator_guid: fields[52],                        // 52
            thread_originator_part: fields[53],                        // 53
            associated_message: {
                guid: fields[54],                                      // 54
                type: parseInt(fields[55]) || 0,                       // 55
                range_location: parseInt(fields[56]) || 0,             // 56
                range_length: parseInt(fields[57]) || 0                // 57
            }
        },
        sharing: {
            share_status: parseInt(fields[58]) || 0,                   // 58
            share_direction: parseInt(fields[59]) || 0,                // 59
            group_action_type: parseInt(fields[60]) || 0               // 60
        },
        sync: {
            ck_sync_state: parseInt(fields[61]) || 0,                  // 61
            sort_id: parseInt(fields[62]) || 0                         // 62
        },
        timestamps: {
            date: parseInt(fields[63]) || 0,                           // 63
            date_read: parseInt(fields[64]) || 0,                      // 64
            date_delivered: parseInt(fields[65]) || 0,                 // 65
            date_played: parseInt(fields[66]) || 0,                    // 66
            date_retracted: parseInt(fields[67]) || 0,                 // 67
            date_edited: parseInt(fields[68]) || 0,                    // 68
            time_expressive_send_played: parseInt(fields[69]) || 0     // 69
        },
    },   
    analysis: {
        behavior_patterns: {
            delivery_anomaly: fields[28] === '0' && fields[18] === '1' ? "received_not_sent" : null,
            temporal_anomaly: !parseInt(fields[16]) && !parseInt(fields[17]) ? "missing_auxiliary_timestamps" : null,
            sync_anomaly: parseInt(fields[57]) === 0 ? "local_only_message" : null
        },
        threat_indicators: {
            pattern_match: "recruitment_scam",
            confidence: "high",
            indicators: [
                "suspicious_contact_pattern",
                "financial_lure",
                "external_platform_redirect"
            ]
        }
    }

```