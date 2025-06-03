# MsgIntel Code Logic

## Core Principles
1. Every message has a handle_id that references handle.ROWID
2. handle.id contains the actual identifier (phone/email)
3. is_from_me only determines if we place the handle data in sender or receiver

## Message Flow Logic
```javascript
communication: {
    sender: { 
        phone_number: handle.id,      // From handle table using message.handle_id
        email: handle.id,             // Same field - could be email instead of phone
        country: handle.country,      // From handle table using message.handle_id
        handle_id: msg.handle_id      // Direct from message table
    },
    receiver: {               
        phone_number: handle.id,      // From handle table using message.handle_id
        email: handle.id,             // Same field - could be email instead of phone
        country: handle.country,      // From handle table using message.handle_id
        handle_id: msg.handle_id      // Direct from message table
    }
}
```

## Field Mapping Rules
1. message.handle_id → handle.ROWID → handle.id (actual identifier)
2. handle.id can be either phone number or email
3. handle.country comes from the same handle table lookup
4. is_from_me determines if handle data goes to sender or receiver section

## Standardized JSON Schema

| JSON Object | Fields | Description | DB Source | Messages | Search | Hidden | Contacts | Attachments |
|------------|---------|-------------|-----------|----------|---------|---------|-----------|------------|
| job |  |  |  | | | | | |
| | job_id | Unique job identifier | Generated | ✓ | ✓ | ✓ | ✓ | ✓ |
| | user | System username | System | ✓ | ✓ | ✓ | ✓ | ✓ |
| | executor | Script executor | Static | ✓ | ✓ | ✓ | ✓ | ✓ |
| | language | Script language | Static | ✓ | ✓ | ✓ | ✓ | ✓ |
| | imports | Required imports | Static | ✓ | ✓ | ✓ | ✓ | ✓ |
| | binaries | Required binaries | Static | ✓ | ✓ | ✓ | ✓ | ✓ |
| | pid | Process ID | System | ✓ | ✓ | ✓ | ✓ | ✓ |
| | query.timestamp | Execution time | Generated | ✓ | ✓ | ✓ | ✓ | ✓ |
| | query.source_db | Database path | Static | ✓ | ✓ | ✓ | ✓ | ✓ |
| | query.type | Operation type | Static | ✓ | ✓ | ✓ | ✓ | ✓ |
| | query.inputStr | Search input | User input | - | ✓ | - | - | - |
| message |  |  |  | | | | | |
| | guid | Message identifier | message.guid | ✓ | ✓ | ✓ | - | ✓ |
| timestamps |  |  |  | | | | | |
| | date | Message timestamp | message.date | ✓ | ✓ | ✓ | - | - |
| | date_read | Read timestamp | message.date_read | ✓ | ✓ | ✓ | - | - |
| | date_delivered | Delivery timestamp | message.date_delivered | ✓ | ✓ | ✓ | - | - |
| | date_played | Media played timestamp | message.date_played | ✓ | ✓ | - | - | - |
| | date_retracted | Retraction timestamp | message.date_retracted | ✓ | ✓ | ✓ | - | - |
| | date_edited | Edit timestamp | message.date_edited | ✓ | ✓ | - | - | - |
| type |  |  |  | | | | | |
| | is_empty | Empty message flag | message.is_empty | ✓ | ✓ | - | - | - |
| | is_archive | Archive flag | message.is_archive | ✓ | ✓ | - | - | - |
| | is_spam | Spam flag | message.is_spam | ✓ | ✓ | - | - | - |
| | is_corrupt | Corruption flag | message.is_corrupt | ✓ | ✓ | - | - | - |
| | is_expirable | Expiry flag | message.is_expirable | ✓ | ✓ | - | - | - |
| | is_system | System message flag | message.is_system_message | ✓ | ✓ | - | - | - |
| | is_service | Service message flag | message.is_service_message | ✓ | ✓ | - | - | - |
| | is_forward | Forward flag | message.is_forward | ✓ | ✓ | - | - | - |
| | is_audio | Audio message flag | message.is_audio_message | ✓ | ✓ | - | ✓ | - |
| | is_emote | Emote flag | message.is_emote | ✓ | ✓ | - | ✓ | - |
| state |  |  |  | | | | | |
| | is_delivered | Delivery status | message.is_delivered | ✓ | ✓ | - | - | ✓ |
| | is_read | Read status | message.is_read | ✓ | ✓ | - | - | ✓ |
| | is_sent | Send status | message.is_sent | ✓ | ✓ | - | - | ✓ |
| | is_played | Media played status | message.is_played | ✓ | ✓ | - | - | - |
| | is_prepared | Preparation status | message.is_prepared | ✓ | ✓ | - | - | - |
| | is_finished | Completion status | message.is_finished | ✓ | ✓ | - | - | ✓ |
| | is_empty | Empty message flag | message.is_empty | ✓ | ✓ | - | - | - |
| | was_data_detected | Data detection flag | message.was_data_detected | ✓ | ✓ | - | - | - |
| | was_delivered_quietly | Quiet delivery flag | message.was_delivered_quietly | ✓ | ✓ | - | - | - |
| | was_detonated | Detonation flag | message.was_detonated | ✓ | ✓ | - | - | - |
| communication |  |  |  | | | | | |
| | channel.service | Communication protocol | message.service | ✓ | ✓ | ✓ | - | - |
| | channel.version | Protocol version | message.version | ✓ | ✓ | - | - | - |
| | channel.is_from_me | Direction flag | message.is_from_me | ✓ | ✓ | ✓ | - | ✓ |
| | channel.chat_identifier | Chat ID | chat.chat_identifier | ✓ | ✓ | ✓ | - | - |
| | channel.thread.reply_to_guid | Reply reference | message.reply_to_guid | ✓ | ✓ | ✓ | - | - |
| | channel.thread.originator_guid | Thread originator | message.thread_originator_guid | ✓ | ✓ | ✓ | - | - |
| | channel.thread.associated_guid | Associated message | message.associated_message_guid | ✓ | ✓ | ✓ | - | - |
| | sender.phone_number | Sender phone | handle.id | ✓ | ✓ | ✓ | - | ✓ |
| | sender.email | Sender email | handle.id | ✓ | ✓ | ✓ | - | ✓ |
| | sender.country | Sender country | handle.country | ✓ | ✓ | ✓ | - | ✓ |
| | sender.handle_id | Sender reference | message.handle_id | ✓ | ✓ | ✓ | - | ✓ |
| | receiver.phone_number | Receiver phone | handle.id | ✓ | ✓ | ✓ | - | ✓ |
| | receiver.email | Receiver email | handle.id | ✓ | ✓ | ✓ | - | ✓ |
| | receiver.country | Receiver country | handle.country | ✓ | ✓ | ✓ | - | ✓ |
| | receiver.handle_id | Receiver reference | message.handle_id | ✓ | ✓ | ✓ | - | ✓ |
| content |  |  |  | | | | | |
| | text | Message text | message.text | ✓ | ✓ | ✓ | - | - |
| | subject | Message subject | message.subject | ✓ | - | ✓ | - | - |
| | group_title | Group chat title | message.group_title | ✓ | - | ✓ | - | - |
| icloud |  |  |  | | | | | |
| | ck_sync_state | Sync status | message.ck_sync_state | ✓ | ✓ | - | - | ✓ |
| | ck_record_id | Record ID | message.ck_record_id | ✓ | ✓ | - | - | ✓ |
| | ck_record_change_tag | Change tag | message.ck_record_change_tag | ✓ | ✓ | - | - | ✓ |


### JOB Output
```json
{
  "job": {
    "job_id": "JOB-95382",
    "user": "user",
    "executor": "osascript",
    "language": "jxa",
    "imports": [
      "Foundation",
      "CoreServices"
    ],
    "binaries": [
      "sqlite3"
    ],
    "pid": 95382,
    "query": {
      "timestamp": "2024-12-14T10:21:31.184Z",
      "source_db": "/Users/user/Library/Messages/chat.db",
      "type": "search",
      "inputStr": " front ID as well as a photo of you"
    }
  }
}
```

### Messages Output
```json
           {
            "message": {
              "guid": "E2E639E6-E612-4A08-A5E8-6692579B8B39",
              "timestamps": {
                "date": "2024-04-25T00:23:38.000Z",
                "date_read": null,
                "date_delivered": null,
                "date_played": null,
                "date_retracted": null,
                "date_edited": null
              },
              "type": {
                "is_empty": false,
                "is_archive": false,
                "is_spam": false,
                "is_corrupt": false,
                "is_expirable": false,
                "is_system": false,
                "is_service": false,
                "is_forward": false,
                "is_audio": false,
                "is_emote": false
              },
              "state": {
                "is_delivered": false,
                "is_read": true,
                "is_sent": true,
                "is_played": false,
                "is_prepared": false,
                "is_finished": true,
                "is_empty": false,
                "was_data_detected": true,
                "was_delivered_quietly": false,
                "was_detonated": false
              },
              "communication": {
                "channel": {
                  "service": "SMS",
                  "version": 10,
                  "is_from_me": 1,
                  "chat_identifier": "+1111111111",
                  "thread": {
                    "reply_to_guid": null,
                    "originator_guid": null,
                    "associated_guid": null
                  }
                },
                "sender": {
                  "phone_number": "+2222222222",
                  "email": null,
                  "country": "US",
                  "handle_id": null
                },
                "receiver": {
                  "email": null,
                  "handle_id": 0
                }
              },
              "content": {
                "text": "Some text message",
                "subject": null,
                "group_title": null
              },
              "icloud": {
                "ck_sync_state": 1,
                "ck_record_id": "a99bcfca58a526aff148641605752426af822f04057fa65072d762831e4118bb",
                "ck_record_change_tag": "23ix"
              }
            }
          }
```

### Search Output
```json
  "data": {
    "messages": [
      {
        "message": {
          "guid": "A1BF946A-D334-4256-962F-1A3F8C447483",
          "is_from_me": 0,
          "type": {
            "is_empty": false,
            "is_archive": false,
            "is_spam": false,
            "is_corrupt": false,
            "is_expirable": false,
            "expire_state": 0,
            "replace": 0
          },
          "communication": {
            "sender": {
              "phone_number": "+19514098899",
              "email": null,
              "country": "US",
              "handle_id": 212
            },
            "receiver": {
              "phone_number": "+14086395605",
              "email": null,
              "country": "US",
              "handle_id": null
            }
          },
          "content": {
            "data": {
              "text": "Hello friend for first time patient please send a photo of your front ID as well as a photo of you holding your ID as a selfie picture  🤳and as well as you’re full address for delivery🙏🏼"
            }
          },
          "status": {
            "delivery": {
              "is_delivered": true,
              "is_sent": false,
              "is_read": true,
              "is_played": false,
              "is_prepared": false,
              "is_finished": true
            }
          },
          "timestamps": {
            "date": "2024-01-26T04:05:18.000Z",
            "date_read": "2024-01-26T04:05:44.000Z",
            "date_delivered": null
          }
        }
      }
    ],
    "attachments": []
  }

```

### HiddenMessages Output
```json
{
    "message": {
        "guid": "45346869-2D4F-4416-8FA3-100FD6109181",
        "timeline": {
            "delete_date": "2024-12-02T04:19:58.000Z",
            "date": "2024-01-26T04:07:30.000Z",
            "date_retracted": null
        },
        "communication": {
            "channel": {
                "service": "iMessage",
                "version": 10,
                "is_from_me": 1,
                "chat_identifier": "+19514098899"
            },
            "sender": {
                "phone_number": "+14086395605",
                "email": null,
                "country": "US",
                "handle_id": null
            },
            "receiver": {
                "email": null,
                "handle_id": 0
            }
        },
        "content": {
            "text": "It's passed the ETA. \nPlease cancel the order.\n\nThanks !",
            "subject": null,
            "group_title": null
        },
        "thread": {
            "associated_guid": null,
            "reply_to_guid": null
        }
    }
}
```

### Contacts Output (Current)
```json
          {
            "contact_info": {
              "id": "urn:biz:6431449c-701a-432c-8a47-275b730ac559",
              "phone_number": "urn:biz:6431449c-701a-432c-8a47-275b730ac559",
              "email": null,
              "country": "US",
              "service": "iMessage",
              "uncanonicalized_id": null
            },
            "stats": {
              "message_count": 25,
              "chat_count": 1,
              "types": {
                "audio": 0,
                "attachment": 25,
                "emoji": 0,
                "downgraded": 0,
                "delayed": 0,
                "auto_reply": 0,
                "spam": 0,
                "system": 0,
                "forward": 0,
                "archive": 0,
                "expirable": 0
              }
            },
            "relationships": {
              "shared_chats": [
                "urn:biz:6431449c-701a-432c-8a47-275b730ac559"
              ],
              "chat_styles": [
                45
              ]
            }
          }
```

### Attachments Output
```json
 {
          "attachment": {
            "guid": "at_0_84049A54-FC1E-42BD-8554-21ECDA5934EF",
            "created_date": "2024-12-05T20:20:06.000Z",
            "metadata": {
              "filename": "~/Library/Messages/Attachments/e4/04/at_0_B7D12C9E-A483-47F5-9C31-8F5EA4D76C12/img_7bc94d31-e5a8-49f6-b2c8-d39f452ae1c3.jpeg",
              "mime_type": "image/jpeg"
            },
            "status": {
              "transfer_state": 5,
              "is_outgoing": 0,
              "is_sticker": 0,
              "hide_attachment": 0,
              "is_commsafety_sensitive": 0,
              "ck_sync_state": 4
            },
            "message": {
              "guid": "84049A54-FC1E-42BD-8554-21ECDA5934EF",
              "is_from_me": 0,
              "communication": {
                "sender": {
                  "phone_number": "+18332578518",
                  "email": null,
                  "country": "us",
                  "handle_id": 667
                },
                "receiver": {
                  "phone_number": "+14086395605",
                  "email": null,
                  "country": "US",
                  "handle_id": null
                }
              },
              "state": {
                "is_delivered": true,
                "is_read": true,
                "is_sent": false,
                "is_spam": false,
                "is_kt_verified": false
              }
            }
          }
 }
```

### Threads Output
```json
  {
        "ROWID": 715,
        "guid": "iMessage;-;+1111111111",
        "style": 45,
        "message_count": 2,
    "last_message_date": 755447175095000000
  }
```

## Database to JSON Mapping

### Message Table Columns
| DB Column | JSON Path | Messages | Search | Hidden | Contacts | Attachments |
|-----------|-----------|----------|---------|---------|-----------|------------|
| ROWID | - | - | - | - | - | - |
| guid | message.guid | ✓ | ✓ | ✓ | - | ✓ |
| text | content.data.text | ✓ | ✓ | ✓ | - | - |
| service | context.service | ✓ | ✓ | ✓ | - | - |
| handle_id | communication.*.handle_id | ✓ | ✓ | ✓ | - | ✓ |
| subject | content.subject | ✓ | - | ✓ | - | - |
| date | timeline.date | ✓ | ✓ | ✓ | - | - |
| date_read | timeline.date_read | ✓ | ✓ | - | - | - |
| date_delivered | timeline.date_delivered | ✓ | ✓ | - | - | - |
| is_from_me | message.is_from_me | ✓ | ✓ | ✓ | - | ✓ |
| is_empty | type.is_empty | - | ✓ | - | - | - |
| is_delivered | status.delivery.is_delivered | ✓ | ✓ | - | - | ✓ |
| is_finished | status.delivery.is_finished | ✓ | ✓ | - | - | ✓ |
| is_emote | type.is_emote | - | ✓ | - | ✓ | - |
| is_audio_message | type.is_audio | - | - | - | ✓ | - |
| is_played | status.delivery.is_played | ✓ | ✓ | - | - | - |
| is_sent | status.delivery.is_sent | ✓ | ✓ | - | - | ✓ |
| is_system_message | type.is_system | - | - | - | ✓ | - |
| is_service_message | type.is_service | - | - | - | ✓ | - |
| is_forward | type.is_forward | - | - | - | ✓ | - |
| is_archive | type.is_archive | - | ✓ | - | ✓ | - |
| is_spam | type.is_spam | - | ✓ | - | ✓ | - |
| is_expirable | type.is_expirable | - | ✓ | - | ✓ | - |
| expire_state | type.expire_state | - | ✓ | - | - | - |
| message_source | context.source | ✓ | - | - | - | - |

### Handle Table Columns
| DB Column | JSON Path | Messages | Search | Hidden | Contacts | Attachments |
|-----------|-----------|----------|---------|---------|-----------|------------|
| ROWID | - | - | - | - | - | - |
| id | communication.*.phone_number/email | ✓ | ✓ | ✓ | ✓ | ✓ |
| country | communication.*.country | ✓ | ✓ | ✓ | ✓ | ✓ |
| service | communication.*.service | ✓ | ✓ | ✓ | ✓ | ✓ |
| uncanonicalized_id | contact_info.uncanonicalized_id | - | - | - | ✓ | - |

### Attachment Table Columns
| DB Column | JSON Path | Messages | Search | Hidden | Contacts | Attachments |
|-----------|-----------|----------|---------|---------|-----------|------------|
| ROWID | - | - | - | - | - | - |
| guid | attachment.guid | - | ✓ | - | - | ✓ |
| created_date | attachment.created_date | - | ✓ | - | - | ✓ |
| filename | metadata.filename | - | ✓ | - | - | ✓ |
| mime_type | metadata.mime_type | - | ✓ | - | - | ✓ |
| transfer_state | status.transfer_state | - | ✓ | - | - | ✓ |
| is_outgoing | status.is_outgoing | - | ✓ | - | - | ✓ |
| is_sticker | status.is_sticker | - | ✓ | - | - | ✓ |
| hide_attachment | status.hide_attachment | - | ✓ | - | - | ✓ |
| ck_sync_state | status.ck_sync_state | - | ✓ | - | - | ✓ |

## JSON INVENTORY TABLE 

| JSON Object | JSON Fields | Messages | Search | Hidden | Contacts | Attachments |
|------------|-------------|----------|---------|---------|-----------|------------|
| job | job_id | ✅ | ✅ | ✅ | ✅ | ✅ |
| | user | ✅ | ✅ | ✅ | ✅ | ✅ |
| | executor | ✅ | ✅ | ✅ | ✅ | ✅ |
| | language | ✅ | ✅ | ✅ | ✅ | ✅ |
| | imports | ✅ | ✅ | ✅ | ✅ | ✅ |
| | binaries | ✅ | ✅ | ✅ | ✅ | ✅ |
| | pid | ✅ | ✅ | ✅ | ✅ | ✅ |
| | query.timestamp | ✅ | ✅ | ✅ | ✅ | ✅ |
| | query.source_db | ✅ | ✅ | ✅ | ✅ | ✅ |
| | query.type | ✅ | ✅ | ✅ | ✅ | ✅ |
| | query.inputStr | | ✅ | | | |
| message | guid | ✅ | ✅ | ✅ | | ✅ |
| | is_from_me | ✅ | ✅ | ✅ | | ✅ |
| | date | ✅ | | | | |
| | date_played | ✅ | | | | |
| | date_retracted | ✅ | | | | |
| | date_edited | ✅ | | | | |
| | type.is_empty | | ✅ | | | |
| | type.is_archive | | ✅ | | | |
| | type.is_spam | | ✅ | | | |
| | type.is_corrupt | | ✅ | | | |
| | type.is_expirable | | ✅ | | | |
| | type.expire_state | | ✅ | | | |
| | type.replace | | ✅ | | | |
| | timestamps.date | | ✅ | | | |
| | timestamps.date_read | | ✅ | | | |
| | timestamps.date_delivered | | ✅ | | | |
| | timeline.delete_date | | | ✅ | | |
| | timeline.date | | | ✅ | | |
| | timeline.date_retracted | | | ✅ | | |
| communication | sender.phone_number | ✅ | ✅ | ✅ | | ✅ |
| | sender.email | ✅ | ✅ | ✅ | | ✅ |
| | sender.country | ✅ | ✅ | ✅ | | ✅ |
| | sender.handle_id | ✅ | ✅ | ✅ | | ✅ |
| | receiver.phone_number | ✅ | ✅ | ✅ | | ✅ |
| | receiver.email | ✅ | ✅ | ✅ | | ✅ |
| | receiver.country | ✅ | ✅ | ✅ | | ✅ |
| | receiver.handle_id | ✅ | ✅ | ✅ | | ✅ |
| content | data.text | ✅ | ✅ | ✅ | | |
| | text | | | ✅ | | |
| | subject | | | ✅ | | |
| | group_title | | | ✅ | | |
| status | delivery.is_delivered | | ✅ | | | |
| | delivery.is_sent | | ✅ | | | |
| | delivery.is_read | | ✅ | | | |
| | delivery.is_played | | ✅ | | | |
| | delivery.is_prepared | | ✅ | | | |
| | delivery.is_finished | | ✅ | | | |
| state | is_delivered | | | | | ✅ |
| | is_read | | | | | ✅ |
| | is_sent | | | | | ✅ |
| | is_spam | | | | | ✅ |
| | is_kt_verified | | | | | ✅ |
| contact_info | id | | | | ✅ | |
| | phone_number | | | | ✅ | |
| | email | | | | ✅ | |
| | country | | | | ✅ | |
| | service | | | | ✅ | |
| | uncanonicalized_id | | | | ✅ | |
| stats | message_count | | | | ✅ | |
| | chat_count | | | | ✅ | |
| | types.audio | | | | ✅ | |
| | types.attachment | | | | ✅ | |
| | types.emoji | | | | ✅ | |
| | types.downgraded | | | | ✅ | |
| | types.delayed | | | | ✅ | |
| | types.auto_reply | | | | ✅ | |
| | types.spam | | | | ✅ | |
| | types.system | | | | ✅ | |
| | types.forward | | | | ✅ | |
| | types.archive | | | | ✅ | |
| | types.expirable | | | | ✅ | |
| relationships | shared_chats | | | | ✅ | |
| | chat_styles | | | | ✅ | |
| thread | associated_guid | | | ✅ | | |
| | reply_to_guid | | | ✅ | | |
| context | chat_identifier | | | ✅ | | |
| | service | | | ✅ | | |
| | service_name | | | ✅ | | |
| metadata | filename | | | | | ✅ |
| | mime_type | | | | | ✅ |
| status | transfer_state | | | | | ✅ |
| | is_outgoing | | | | | ✅ |
| | is_sticker | | | | | ✅ |
| | hide_attachment | | | | | ✅ |
| | is_commsafety_sensitive | | | | | ✅ |
| | ck_sync_state | | | | | ✅ |

## Attachments Output Structure
| JSON Object | Fields | Description | DB Source |
|------------|---------|-------------|-----------|
| attachment |  |  |  |
| | guid | Attachment identifier | attachment.guid |
| | created_date | Creation timestamp | attachment.created_date |
| file_metadata |  |  |  |
| | filename | File path | attachment.filename |
| | mime_type | Content type | attachment.mime_type |
| status |  |  |  |
| | transfer_state | Transfer status | attachment.transfer_state |
| | is_outgoing | Direction flag | attachment.is_outgoing |
| | is_sticker | Sticker flag | attachment.is_sticker |
| | hide_attachment | Hidden flag | attachment.hide_attachment |
| | is_commsafety_sensitive | Safety flag | attachment.is_commsafety_sensitive |
| message |  |  |  |
| | guid | Message identifier | message.guid |
| | communication.channel |  |  |
| | | service | Protocol type | message.service |
| | | version | Protocol version | message.version |
| | | is_from_me | Direction flag | message.is_from_me |
| | communication.sender |  |  |
| | | phone_number | Sender phone | handle.id |
| | | email | Sender email | handle.id |
| | | country | Sender country | handle.country |
| | | handle_id | Sender reference | message.handle_id |
| | communication.receiver |  |  |
| | | phone_number | Receiver phone | handle.id |
| | | email | Receiver email | handle.id |
| | | country | Receiver country | handle.country |
| | | handle_id | Receiver reference | message.handle_id |
| | state |  |  |
| | | is_delivered | Delivery status | message.is_delivered |
| | | is_read | Read status | message.is_read |
| | | is_sent | Send status | message.is_sent |
| | | is_spam | Spam flag | message.is_spam |
| | | is_kt_verified | Verification flag | message.is_kt_verified |
| icloud |  |  |  |
| | ck_sync_state | Sync status | attachment.ck_sync_state |
| | ck_record_id | Record ID | attachment.ck_record_id |

### HandleAnalytics Output
```json
{
    "handle": {
        "contact_info": {
            "id": "daniel@armado.io",
            "phone_number": null,
            "email": "daniel@armado.io",
            "country": "US",
            "service": "iMessage",
            "uncanonicalized_id": null,
            "person_centric_id": null
        },
        "timeline": {
            "first_message": "2024-01-01T00:00:00.000Z",
            "last_message": "2024-12-29T23:05:47.222Z"
        },
        "stats": {
            "message_count": 118,
            "chat_count": 2,
            "sent_count": 50,
            "received_count": 68,
            "types": {
                "audio": 0,
                "attachment": 66,
                "emoji": 0,
                "downgraded": 0,
                "delayed": 0,
                "auto_reply": 0,
                "spam": 0,
                "system": 0,
                "forward": 0,
                "archive": 0,
                "expirable": 0
            }
        },
        "relationships": {
            "shared_chats": [
                "daniel@armado.io",
                "chat153752519437314627"
            ],
            "chat_styles": [45, 43],
            "services_used": ["iMessage", "SMS"],
            "group_chats": ["Project Chat", "Team Chat"],
            "blocked_count": 0,
            "archived_count": 0
        }
    }
}
```

## Input Handling Pattern

### Search Class Pattern
The Search class demonstrates the standard input handling pattern used across msgIntel:

1. Argument Parsing:
```javascript
// In parseArgs()
case '--search':
    if (i + 1 < args.count) {
        options.search = ObjC.unwrap(args.objectAtIndex(++i));
    }
    break;
```

2. Input Sanitization:
```javascript
// In Search class
searchAll(inputStr, format = 'json') {
    // Escape special characters
    const escapedInputStr = inputStr.replace(/_/g, '\\_').replace(/%/g, '\\%');
    
    // Use escaped input in SQL
    const sql = `WHERE m.text LIKE '%${escapedInputStr}%'`;
}
```

3. Main Execution Flow:
```javascript
// Inside main access block
if (options.search) {
    const searchResults = search.searchAll(options.search, format);
    if (format !== 'json') {
        console.log(searchResults);
    } else {
        console.log(JSON.stringify(searchResults, null, 2));
    }
    return;
}
```

### Key Components
1. **Argument Parsing**
   - Check for additional argument: `i + 1 < args.count`
   - Unwrap ObjC argument: `ObjC.unwrap(args.objectAtIndex(++i))`
   - Store in options object

2. **Input Sanitization**
   - Escape special characters
   - Prevent SQL injection
   - Handle edge cases

3. **Execution Context**
   - Inside main access block with permissions check
   - Access to format variable
   - Consistent output handling

4. **Output Format**
   - Respect format parameter
   - Consistent JSON structure
   - Include job metadata

### Implementation Requirements
1. All input handlers must:
   - Be inside main access block
   - Follow sanitization pattern
   - Use consistent output format
   - Include job metadata
   - Handle errors gracefully

2. Input validation must:
   - Check argument count
   - Sanitize special characters
   - Validate input format
   - Handle empty/null cases

3. Output must include:
   - Job metadata
   - Query information
   - Formatted results
   - Error handling
