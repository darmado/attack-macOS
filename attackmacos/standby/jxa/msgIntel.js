/**
 * Script Name: msgIntel.js
 * Description: Extracts message data from macOS Messages app databases
 * MITRE ATT&CK Technique: T1005 - Data from Local System
 * Platform: macOS
 * 
 * Author: Daniel Acevedo
 * Date: 2024DEC19
 * Version: 0.8.0
 * License: Apache 2.0
 * 
 * Copyright 2024 Daniel Acevedo
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

(() => {
    'use strict';
    
    ObjC.import('Foundation');
    ObjC.import('CoreServices');

    // At the top level, after imports
    const VALID_OUTPUT_FORMATS = [
        'json',  // Default
        'line',
        'csv',
        'column',
        'html',
        'insert',
        'list'
    ];

    // 1. Add debug flag
    let DEBUG = false;

    // 2. Standard debug function
    function debug(message) {
        if (DEBUG) {
            console.log("[DEBUG] " + message);
        }
    }

    // Utility class for constants and shared functions
    class MsgIntelUtils {
        static SQLITE_BIN = '/usr/bin/sqlite3';
        static USER_INFO = {
            username: $.NSUserName().js,
            homeDir: $.NSHomeDirectory().js
        };
        
        static DBS = {
            chat: `${this.USER_INFO.homeDir}/Library/Messages/chat.db`,
            nicknames: `${this.USER_INFO.homeDir}/Library/Messages/NickNameCache/nickNameKeyStore.db`,
            collaborationNotices: `${this.USER_INFO.homeDir}/Library/Messages/CollaborationNoticeCache/collaborationNotices.db`,
            handleSharingPreferences: `${this.USER_INFO.homeDir}/Library/Messages/NickNameCache/handleSharingPreferences.db`,
            handledNicknamesKeyStore: `${this.USER_INFO.homeDir}/Library/Messages/NickNameCache/handledNicknamesKeyStore.db`,
            pendingNicknamesKeyStore: `${this.USER_INFO.homeDir}/Library/Messages/NickNameCache/pendingNicknamesKeyStore.db`,
            prewarmsg: `${this.USER_INFO.homeDir}/Library/Messages/prewarmsg.db`
        };

        // Add output format getter
        static get OUTPUT_FORMAT() {
            return VALID_OUTPUT_FORMATS;
        }

        // Add valid formats getter
        static get VALID_FORMATS() {
            return VALID_OUTPUT_FORMATS;
        }

        static mapCommunication(msg, handleData, destHandleData) {
            const isEmail = (id) => id && id.includes('@');
            
            return {
                sender: msg.is_from_me === 0 ? {
                    phone_number: isEmail(handleData?.id) ? null : handleData?.id,
                    email: isEmail(handleData?.id) ? handleData?.id : null,
                    country: handleData?.country,
                    handle_id: msg.handle_id
                } : {
                    phone_number: isEmail(msg.destination_caller_id) ? null : msg.destination_caller_id,
                    email: isEmail(msg.destination_caller_id) ? msg.destination_caller_id : null,
                    country: destHandleData?.country,
                    handle_id: null
                },
                receiver: msg.is_from_me === 1 ? {
                    phone_number: isEmail(handleData?.id) ? null : handleData?.id,
                    email: isEmail(handleData?.id) ? handleData?.id : null,
                    country: handleData?.country,
                    handle_id: msg.handle_id
                } : {
                    phone_number: isEmail(msg.destination_caller_id) ? null : msg.destination_caller_id || handleData?.id,
                    email: isEmail(msg.destination_caller_id) ? msg.destination_caller_id : null,
                    country: destHandleData?.country || handleData?.country,
                    handle_id: msg.handle_id
                }
            };
        }

        static convertAppleDate(timestamp) {
            if (!timestamp) return null;
            
            // Case 1: Cocoa timestamp (nanoseconds since 2001)
            if (timestamp > 1000000000000) {
                const unixTimestamp = Math.floor(timestamp / 1000000000 + 978307200);
                return new Date(unixTimestamp * 1000).toISOString();
            }
            
            // Case 2: Attachment timestamps (seconds since 2001)
            if (timestamp < 1000000000) {
                return new Date((timestamp + 978307200) * 1000).toISOString();
            }
            
            // Case 3: Standard Unix timestamp
            return new Date(timestamp * 1000).toISOString();
        }

        static formatOutput(data, format = 'json') {
            // Default to JSON
            if (!format || format === 'json') {
                return JSON.stringify(data, null, 2);
            }
            
            // Otherwise pass format directly to sqlite
            return data;
        }

        static createJobMetadata(dbPath, type) {
            return {
                job_id: `JOB-${$.NSProcessInfo.processInfo.processIdentifier}`,
                user: MsgIntelUtils.USER_INFO.username,
                executor: "osascript",
                language: "jxa",
                imports: ["Foundation", "CoreServices"],
                binaries: ["sqlite3"],
                pid: $.NSProcessInfo.processInfo.processIdentifier,
                query: {
                    timestamp: new Date().toISOString(),
                    source_db: dbPath,
                    type: type
                }
            };
        }

        static getHandles(db) {
            const sql = `SELECT ROWID, id, country FROM handle;`;
            const results = db.query(sql);
            return {
                byRowId: new Map(results.map(h => [h.ROWID, h])),
                byId: new Map(results.map(h => [h.id, h]))
            };
        }

        static processDraftOutput(results, options = {}) {
            const {
                dbPath = this.DBS.chat,
                format = 'json'
            } = options;

            if (format !== 'json') return results;
            if (!results) return { data: { drafts: {} }};

            return {
                job: this.createJobMetadata(dbPath, "drafts"),
                drafts: results.reduce((acc, draft) => {
                    const draftId = `DRAFT-${$.NSUUID.UUID.UUIDString.js}`;
                    
                    // Get intended recipient from directory name
                    const recipientId = draft.directory !== 'Pending' ? draft.directory : null;
                    const recipientHandle = recipientId ? this.handles?.byId?.get(recipientId) : null;

                    acc[draftId] = {
                        job_id: `JOB-${$.NSUUID.UUID.UUIDString.js}`,
                        source: {
                            type: 'plist',
                            directory: draft.directory || 'Pending',
                            path: draft.path || `${MsgIntelUtils.USER_INFO.homeDir}/Library/Messages/Drafts/Pending/composition.plist`
                        },
                        communication: {
                            channel: {
                                service: recipientHandle?.service || 'SMS',
                                version: 0,
                                is_from_me: 1,
                                chat_identifier: recipientId || 'Pending',
                                thread: {
                                    reply_to_guid: $GUID
                                    originator_guid: $GUID
                                    associated_guid: $GUID
                                }
                            },
                            sender: {
                                phone_number: null,
                                email: null,
                                country: null,
                                handle_id: null
                            },
                            receiver: {
                                phone_number: recipientId?.includes('@') ? null : recipientId,
                                email: recipientId?.includes('@') ? recipientId : null,
                                country: recipientHandle?.country,
                                handle_id: recipientHandle?.ROWID
                            }
                        },
                        content: {
                            data: {
                                text: this.decodeDraftText(draft.text),
                                format: 'NSKeyedArchiver',
                                encoding_method: 'base64',
                                mime_type: 'application/x-plist',
                                data_length: draft.text?.length || 0,
                                encoded_data: draft.text
                            },
                            attachments: draft.attachments || []
                        },
                        status: {
                            delivery: {
                                is_pending: true,
                                is_delivered: false,
                                is_sent: false,
                                is_read: false,
                                is_played: false,
                                is_prepared: false,
                                is_finished: false,
                                was_delivered_quietly: false,
                                did_notify_recipient: false,
                                was_downgraded: false,
                                was_detonated: false,
                                is_delayed: false
                            },
                            state: {
                                has_attachments: Boolean(draft.has_attachments),
                                created: this.convertAppleDate(draft.created_date),
                                last_modified: this.convertAppleDate(draft.modified_date)
                            }
                        }
                    };
                    return acc;
                }, {})
            };
        }

        // Helper to decode draft text from base64 plist
        static decodeDraftText(base64Text) {
            if (!base64Text) return '';
            try {
                const data = $.NSData.alloc.initWithBase64EncodedStringOptions(base64Text, 0);
                const plist = $.NSPropertyListSerialization.propertyListWithDataOptionsFormatError(
                    data, 0, null, null
                );
                const rawContent = ObjC.deepUnwrap(plist);
                return rawContent.$objects.find(obj => obj?.['NS.string'])?.['NS.string'] || '';
            } catch (e) {
                return base64Text;
            }
        }

        static processMessageOutput(results, options = {}) {
            const {
                dbPath = this.DBS.chat,
                format = 'json',
                handles = null  // Pass handles cache from Messages class
            } = options;

            if (format !== 'json') return results;
            if (!results) return { data: { messages: [] }};

            return {
                job: this.createJobMetadata(dbPath, "messages"),
                data: {
                    messages: results.map(msg => ({
                        message: {
                            guid: $GUID
                            timestamps: {
                                date: this.convertAppleDate(msg.date),
                                date_read: this.convertAppleDate(msg.date_read),
                                date_delivered: this.convertAppleDate(msg.date_delivered),
                                date_played: this.convertAppleDate(msg.date_played),
                                date_retracted: this.convertAppleDate(msg.date_retracted),
                                date_edited: this.convertAppleDate(msg.date_edited)
                            },
                            type: {
                                is_empty: Boolean(msg.is_empty),
                                is_archive: Boolean(msg.is_archive),
                                is_spam: Boolean(msg.is_spam),
                                is_corrupt: Boolean(msg.is_corrupt),
                                is_expirable: Boolean(msg.is_expirable),
                                is_system: Boolean(msg.is_system_message),
                                is_service: Boolean(msg.is_service_message),
                                is_forward: Boolean(msg.is_forward),
                                is_audio: Boolean(msg.is_audio_message),
                                is_emote: Boolean(msg.is_emote)
                            },
                            state: {
                                is_delivered: Boolean(msg.is_delivered),
                                is_read: Boolean(msg.is_read),
                                is_sent: Boolean(msg.is_sent),
                                is_played: Boolean(msg.is_played),
                                is_prepared: Boolean(msg.is_prepared),
                                is_finished: Boolean(msg.is_finished),
                                is_empty: Boolean(msg.is_empty),
                                was_data_detected: Boolean(msg.was_data_detected),
                                was_delivered_quietly: Boolean(msg.was_delivered_quietly),
                                was_detonated: Boolean(msg.was_detonated)
                            },
                            communication: {
                                channel: {
                                    service: msg.service,
                                    version: msg.version,
                                    is_from_me: msg.is_from_me,
                                    chat_identifier: msg.chat_identifier,
                                    thread: {
                                        reply_to_guid: $GUID
                                        originator_guid: $GUID
                                        associated_guid: $GUID
                                    }
                                },
                                sender: msg.is_from_me === 0 ? {
                                    phone_number: handles?.byRowId.get(msg.handle_id)?.id.includes('@') ? null : handles?.byRowId.get(msg.handle_id)?.id,
                                    email: handles?.byRowId.get(msg.handle_id)?.id.includes('@') ? handles?.byRowId.get(msg.handle_id)?.id : null,
                                    country: handles?.byRowId.get(msg.handle_id)?.country,
                                    handle_id: msg.handle_id
                                } : {
                                    phone_number: msg.destination_caller_id?.includes('@') ? null : msg.destination_caller_id,
                                    email: msg.destination_caller_id?.includes('@') ? msg.destination_caller_id : null,
                                    country: handles?.byId.get(msg.destination_caller_id)?.country,
                                    handle_id: null
                                },
                                receiver: msg.is_from_me === 1 ? {
                                    phone_number: handles?.byRowId.get(msg.handle_id)?.id.includes('@') ? null : handles?.byRowId.get(msg.handle_id)?.id,
                                    email: handles?.byRowId.get(msg.handle_id)?.id.includes('@') ? handles?.byRowId.get(msg.handle_id)?.id : null,
                                    country: handles?.byRowId.get(msg.handle_id)?.country,
                                    handle_id: msg.handle_id
                                } : {
                                    phone_number: msg.destination_caller_id?.includes('@') ? null : msg.destination_caller_id,
                                    email: msg.destination_caller_id?.includes('@') ? msg.destination_caller_id : null,
                                    country: handles?.byId.get(msg.destination_caller_id)?.country,
                                    handle_id: null
                                }
                            },
                            content: {
                                text: msg.text,
                                subject: msg.subject,
                                group_title: msg.group_title
                            },
                            icloud: {
                                ck_sync_state: msg.ck_sync_state,
                                ck_record_id: msg.ck_record_id,
                                ck_record_change_tag: msg.ck_record_change_tag
                            }
                        }
                    }))
                }
            };
        }
    }

    // TCC Check Function
    function Check() {
        ObjC.import('CoreServices')
        ObjC.bindFunction('CFMakeCollectable', ['id', ['void *']])
        
        const homeDir = $.NSHomeDirectory().js;
        const tccDbPath = `${homeDir}/Library/Application Support/com.apple.TCC/TCC.db`;
        const queryString = "kMDItemDisplayName = *TCC.db";
        
        let query = $.MDQueryCreate($(), $(queryString), $(), $());
        let queryExecuteResult = $.MDQueryExecute(query, 1);
        let resultCount = $.MDQueryGetResultCount(query);
        
        const status = {
            tcc: {
                granted: false,
                path: tccDbPath,
                query_success: queryExecuteResult,
                query_results: resultCount
            },
            process: {
                name: $.NSProcessInfo.processInfo.processName.js,
                pid: $.NSProcessInfo.processInfo.processIdentifier
            }
        };

        if (queryExecuteResult) {
            for (var i = 0; i < resultCount; i++) {
                var mdItem = $.MDQueryGetResultAtIndex(query, i);
                var mdAttrs1 = $.MDItemCopyAttribute($.CFMakeCollectable(mdItem), $.kMDItemPath)
                var mdAttrs = ObjC.deepUnwrap(mdAttrs1);
                if (mdAttrs === tccDbPath) {
                    status.tcc.granted = true;
                    break;
                }
            }
        }

        console.log(JSON.stringify(status, null, 2));
        return status.tcc.granted;
    }

    // Base Database Class
    class BaseDB {
        constructor(dbPath) {
            this.dbPath = dbPath;
            this.task = $.NSTask.alloc.init;
            this.pipe = $.NSPipe.pipe;
        }

        query(sql, format = 'json') {
            try {
                const task = $.NSTask.alloc.init;
                task.launchPath = MsgIntelUtils.SQLITE_BIN;
                
                // Pass format directly to sqlite
                task.arguments = [this.dbPath, `-${format}`, sql];
                
                const pipe = $.NSPipe.pipe;
                task.standardOutput = pipe;
                task.standardError = pipe;
                
                task.launch;
                const data = pipe.fileHandleForReading.readDataToEndOfFile;
                const output = $.NSString.alloc.initWithDataEncoding(data, $.NSUTF8StringEncoding).js;
                
                // Only parse if JSON
                return format === 'json' ? JSON.parse(output) : output;
            } catch(e) {
                return null;
            }
        }
    }

    // Messages Class
    class Messages extends BaseDB {
        constructor() {
            super(MsgIntelUtils.DBS.chat);
            this.handles = MsgIntelUtils.getHandles(this);
        }

        getMessages(format = 'json') {
            const sql = `SELECT 
                m.ROWID, m.guid, m.text, m.service, m.handle_id, 
                m.is_from_me, m.destination_caller_id,
                m.service_center, m.version, m.account, m.account_guid,
                m.date, m.date_played, m.date_retracted, m.date_edited,
                m.subject, m.group_title,
                m.associated_message_guid, m.reply_to_guid, m.thread_originator_guid,
                m.is_delivered, m.is_read, m.is_sent, m.is_played, m.is_prepared, m.is_finished,
                m.is_empty, m.is_archive, m.is_spam, m.is_corrupt, m.is_expirable,
                m.is_system_message, m.is_service_message, m.is_forward, m.is_audio_message, m.is_emote,
                m.was_data_detected, m.was_delivered_quietly, m.was_detonated,
                m.ck_sync_state, m.ck_record_id, m.ck_record_change_tag,
                c.chat_identifier
            FROM message m
            LEFT JOIN chat_message_join cmj ON m.ROWID = cmj.message_id
            LEFT JOIN chat c ON cmj.chat_id = c.ROWID
            WHERE m.text IS NOT NULL;`;

            if (format !== 'json') {
                return this.query(sql, format);
            }

            const messages = this.query(sql);
            return MsgIntelUtils.processMessageOutput(messages, {
                dbPath: this.dbPath,
                format,
                handles: this.handles
            });
        }

        getContacts() {
            const sql = `SELECT h.ROWID, h.id, h.service, h.uncanonicalized_id, COUNT(m.ROWID) as message_count FROM handle h LEFT JOIN message m ON h.ROWID = m.handle_id GROUP BY h.ROWID;`;
            return this.query(sql);
        }

        getThreads() {
            const sql = `SELECT c.ROWID, c.guid, c.style, COUNT(cm.message_id) as message_count, MAX(m.date) as last_message_date FROM chat c LEFT JOIN chat_message_join cm ON c.ROWID = cm.chat_id LEFT JOIN message m ON cm.message_id = m.ROWID GROUP BY c.ROWID;`;
            return this.query(sql);
        }
    }

    // Attachments Class
    class Attachments extends BaseDB {
        constructor() {
            super(MsgIntelUtils.DBS.chat);
            this.handles = MsgIntelUtils.getHandles(this);
        }

        getAttachments(format = 'json') {
            const sql = `SELECT 
                a.ROWID,
                a.guid,
                a.created_date,
                a.filename,
                a.mime_type,
                a.transfer_state,
                a.is_outgoing,
                a.is_sticker,
                a.hide_attachment,
                a.is_commsafety_sensitive,
                a.ck_sync_state,
                a.original_guid,
                a.ck_record_id,
                m.handle_id,
                m.is_from_me,
                m.destination_caller_id,
                m.is_delivered,
                m.is_read,
                m.is_sent,
                m.is_spam,
                m.is_kt_verified,
                m.service,
                m.version
            FROM attachment a
            LEFT JOIN message_attachment_join maj ON a.ROWID = maj.attachment_id
            LEFT JOIN message m ON maj.message_id = m.ROWID
            ORDER BY a.ROWID ASC;`;

            // For non-JSON formats, return raw sqlite output
            if (format !== 'json') {
                return this.query(sql, format);
            }

            const attachments = this.query(sql);
            if (!attachments) return { data: { attachments: [] }};

            return {
                job: {
                    job_id: `JOB-${$.NSProcessInfo.processInfo.processIdentifier}`,
                    user: MsgIntelUtils.USER_INFO.username,
                    executor: "osascript",
                    language: "jxa",
                    imports: ["Foundation", "CoreServices"],
                    binaries: ["sqlite3"],
                    pid: $.NSProcessInfo.processInfo.processIdentifier,
                    query: {
                        timestamp: new Date().toISOString(),
                        source_db: this.dbPath,
                        type: "discover"
                    }
                },
                data: {
                    attachments: attachments.map(att => ({
                        attachment: {
                            guid: $GUID
                            created_date: MsgIntelUtils.convertAppleDate(att.created_date),
                            file_metadata: {
                                filename: att.filename,
                                mime_type: att.mime_type,
                                uti: att.uti,
                                transfer_name: att.transfer_name,
                                total_bytes: att.total_bytes
                            },
                            status: {
                                transfer_state: att.transfer_state,
                                is_outgoing: att.is_outgoing,
                                is_sticker: att.is_sticker,
                                hide_attachment: att.hide_attachment,
                                is_commsafety_sensitive: att.is_commsafety_sensitive
                            },
                            message: {
                                guid: $GUID
                                communication: {
                                    channel: {
                                        service: att.service,
                                        version: att.version,
                                        is_from_me: att.is_from_me
                                    },
                                    ...MsgIntelUtils.mapCommunication(att, 
                                        this.handles.byRowId.get(att.handle_id),
                                        this.handles.byId.get(att.destination_caller_id))
                                },
                                state: {
                                    is_delivered: Boolean(att.is_delivered),
                                    is_read: Boolean(att.is_read),
                                    is_sent: Boolean(att.is_sent),
                                    is_spam: Boolean(att.is_spam),
                                    is_kt_verified: Boolean(att.is_kt_verified)
                                }
                            },
                            icloud: {
                                ck_sync_state: att.ck_sync_state,
                                ck_record_id: att.ck_record_id,
                                ck_record_change_tag: att.ck_record_change_tag
                            }
                        }
                    }))
                }
            };
        }
    }

    // Search Class
    class Search extends BaseDB {
        constructor() {
            super(MsgIntelUtils.DBS.chat);
            this.handles = MsgIntelUtils.getHandles(this);
        }

        searchAll(inputStr, format = 'json') {
            const escapedInputStr = inputStr.replace(/_/g, '\\_').replace(/%/g, '\\%');

            const msgSql = `SELECT 
                m.ROWID, m.guid, m.text, m.service, m.handle_id,
                m.is_from_me, m.destination_caller_id,
                m.service_center, m.version,
                m.date, m.date_read, m.date_delivered, m.date_played, m.date_retracted, m.date_edited,
                m.subject, m.group_title,
                m.associated_message_guid, m.reply_to_guid, m.thread_originator_guid,
                m.is_delivered, m.is_read, m.is_sent, m.is_played, m.is_prepared, m.is_finished,
                m.is_empty, m.is_archive, m.is_spam, m.is_corrupt, m.is_expirable,
                m.is_system_message, m.is_service_message, m.is_forward, m.is_audio_message, m.is_emote,
                m.was_data_detected, m.was_delivered_quietly, m.was_detonated,
                m.ck_sync_state, m.ck_record_id, m.ck_record_change_tag,
                c.chat_identifier
            FROM message m 
            LEFT JOIN chat_message_join cmj ON m.ROWID = cmj.message_id
            LEFT JOIN chat c ON cmj.chat_id = c.ROWID
            LEFT JOIN handle h ON m.handle_id = h.ROWID
            WHERE m.text LIKE '%${escapedInputStr}%'
            OR m.guid LIKE '%${escapedInputStr}%'
            OR h.id LIKE '%${escapedInputStr}%'
            OR m.destination_caller_id LIKE '%${escapedInputStr}%';`;

            // For non-JSON formats, return raw sqlite output
            if (format !== 'json') {
                return this.query(msgSql, format);
            }

            const messages = this.query(msgSql);
            if (!messages) return { data: { messages: [] }};

            return {
                job: {
                    job_id: `JOB-${$.NSProcessInfo.processInfo.processIdentifier}`,
                    user: MsgIntelUtils.USER_INFO.username,
                    executor: "osascript",
                    language: "jxa",
                    imports: ["Foundation", "CoreServices"],
                    binaries: ["sqlite3"],
                    pid: $.NSProcessInfo.processInfo.processIdentifier,
                    query: {
                        timestamp: new Date().toISOString(),
                        source_db: this.dbPath,
                        type: "search",
                        inputStr: inputStr
                    }
                },
                data: {
                    messages: messages.map(msg => ({
                        message: {
                            guid: $GUID
                            timestamps: {
                                date: MsgIntelUtils.convertAppleDate(msg.date),
                                date_read: MsgIntelUtils.convertAppleDate(msg.date_read),
                                date_delivered: MsgIntelUtils.convertAppleDate(msg.date_delivered),
                                date_played: MsgIntelUtils.convertAppleDate(msg.date_played),
                                date_retracted: MsgIntelUtils.convertAppleDate(msg.date_retracted),
                                date_edited: MsgIntelUtils.convertAppleDate(msg.date_edited)
                            },
                            type: {
                                is_empty: Boolean(msg.is_empty),
                                is_archive: Boolean(msg.is_archive),
                                is_spam: Boolean(msg.is_spam),
                                is_corrupt: Boolean(msg.is_corrupt),
                                is_expirable: Boolean(msg.is_expirable),
                                is_system: Boolean(msg.is_system_message),
                                is_service: Boolean(msg.is_service_message),
                                is_forward: Boolean(msg.is_forward),
                                is_audio: Boolean(msg.is_audio_message),
                                is_emote: Boolean(msg.is_emote)
                            },
                            state: {
                                is_delivered: Boolean(msg.is_delivered),
                                is_read: Boolean(msg.is_read),
                                is_sent: Boolean(msg.is_sent),
                                is_played: Boolean(msg.is_played),
                                is_prepared: Boolean(msg.is_prepared),
                                is_finished: Boolean(msg.is_finished),
                                is_empty: Boolean(msg.is_empty),
                                was_data_detected: Boolean(msg.was_data_detected),
                                was_delivered_quietly: Boolean(msg.was_delivered_quietly),
                                was_detonated: Boolean(msg.was_detonated)
                            },
                            communication: {
                                channel: {
                                    service: msg.service,
                                    version: msg.version,
                                    is_from_me: msg.is_from_me,
                                    chat_identifier: msg.chat_identifier,
                                    thread: {
                                        reply_to_guid: $GUID
                                        originator_guid: $GUID
                                        associated_guid: $GUID
                                    }
                                },
                                sender: msg.is_from_me === 0 ? {
                                    phone_number: this.handles.byRowId.get(msg.handle_id)?.id.includes('@') ? null : this.handles.byRowId.get(msg.handle_id)?.id,
                                    email: this.handles.byRowId.get(msg.handle_id)?.id.includes('@') ? this.handles.byRowId.get(msg.handle_id)?.id : null,
                                    country: this.handles.byRowId.get(msg.handle_id)?.country,
                                    handle_id: msg.handle_id
                                } : {
                                    phone_number: msg.destination_caller_id?.includes('@') ? null : msg.destination_caller_id,
                                    email: msg.destination_caller_id?.includes('@') ? msg.destination_caller_id : null,
                                    country: this.handles.byId.get(msg.destination_caller_id)?.country,
                                    handle_id: null
                                },
                                receiver: msg.is_from_me === 1 ? {
                                    phone_number: this.handles.byRowId.get(msg.handle_id)?.id.includes('@') ? null : this.handles.byRowId.get(msg.handle_id)?.id,
                                    email: this.handles.byRowId.get(msg.handle_id)?.id.includes('@') ? this.handles.byRowId.get(msg.handle_id)?.id : null,
                                    country: this.handles.byRowId.get(msg.handle_id)?.country,
                                    handle_id: msg.handle_id
                                } : {
                                    phone_number: msg.destination_caller_id?.includes('@') ? null : msg.destination_caller_id,
                                    email: msg.destination_caller_id?.includes('@') ? msg.destination_caller_id : null,
                                    country: this.handles.byId.get(msg.destination_caller_id)?.country,
                                    handle_id: null
                                }
                            },
                            content: {
                                text: msg.text,
                                subject: msg.subject,
                                group_title: msg.group_title
                            },
                            icloud: {
                                ck_sync_state: msg.ck_sync_state,
                                ck_record_id: msg.ck_record_id,
                                ck_record_change_tag: msg.ck_record_change_tag
                            }
                        }
                    }))
                }
            };
        }

        searchByDate(startDate, endDate) {
            const sql = `SELECT m.ROWID, m.text, m.date, m.service, h.id as contact_id 
                FROM message m 
                LEFT JOIN handle h ON m.handle_id = h.ROWID 
                WHERE m.date BETWEEN ${startDate} AND ${endDate};`;
            return this.query(sql);
        }
    }

    // Drafts Class
    class Drafts extends BaseDB {
        constructor() {
            super(MsgIntelUtils.DBS.chat);
            this.fileManager = $.NSFileManager.defaultManager;
            this.draftsPath = `${MsgIntelUtils.USER_INFO.homeDir}/Library/Messages/Drafts`;
        }

        getDrafts(format = 'json') {
            try {
                if (!this.fileManager.fileExistsAtPath(this.draftsPath)) {
                    return MsgIntelUtils.processDraftOutput([], {format});
                }

                const accounts = ObjC.deepUnwrap(this.fileManager.contentsOfDirectoryAtPathError(this.draftsPath, null));
                const drafts = [];

                accounts.forEach(account => {
                    const plistPath = `${this.draftsPath}/${account}/composition.plist`;
                    if (this.fileManager.fileExistsAtPath(plistPath)) {
                        const stat = $.NSFileManager.defaultManager.attributesOfItemAtPathError(plistPath, null);
                        const modDate = ObjC.deepUnwrap(stat.fileModificationDate);
                        const creationDate = ObjC.deepUnwrap(stat.creationDate);

                        const task = $.NSTask.alloc.init;
                        task.launchPath = '/usr/bin/plutil';
                        task.arguments = ['-convert', 'xml1', '-o', '-', plistPath];
                        
                        const pipe = $.NSPipe.pipe;
                        task.standardOutput = pipe;
                        task.standardError = pipe;
                        
                        task.launch;
                        task.waitUntilExit;
                        
                        const data = pipe.fileHandleForReading.readDataToEndOfFile;
                        const output = $.NSString.alloc.initWithDataEncoding(data, $.NSUTF8StringEncoding).js;

                        const dataMatch = output.match(/<data>\s*(.*?)\s*<\/data>/s);
                        const base64Data = dataMatch ? dataMatch[1].replace(/\s+/g, '') : '';

                        drafts.push({
                            guid: $GUID
                            created_date: creationDate,
                            modified_date: modDate,
                            text: base64Data,
                            is_audio_message: false,
                            is_empty: base64Data.length === 0
                        });
                    }
                });

                return MsgIntelUtils.processDraftOutput(drafts, {format});

            } catch (error) {
                console.log(`Error reading drafts: ${error}`);
                return MsgIntelUtils.processDraftOutput([], {format});
            }
        }
    }

    // HiddenMessages Class
    class HiddenMessages extends BaseDB {
        constructor() {
            super(MsgIntelUtils.DBS.chat);
            this.handles = MsgIntelUtils.getHandles(this);
        }

        getHiddenMessages(format = 'json') {
            const sql = `SELECT 
                -- Timeline Context
                crm.delete_date,
                m.date as message_date,
                m.date_retracted,
                
                -- Message Context
                m.guid,
                m.text,
                m.service,
                m.is_from_me,
                m.subject,
                m.group_title,
                m.handle_id,
                m.destination_caller_id,
                m.version,
                
                -- Thread Context
                m.associated_message_guid,
                m.reply_to_guid,
                
                -- Chat Context
                c.chat_identifier,
                c.service_name,
                
                -- Participant Context
                h.id,
                h.service as handle_service,
                h.country
            FROM chat_recoverable_message_join crm
            JOIN chat c ON crm.chat_id = c.ROWID
            JOIN message m ON crm.message_id = m.ROWID
            LEFT JOIN handle h ON m.handle_id = h.ROWID
            WHERE m.text IS NOT NULL
            ORDER BY crm.delete_date DESC;`;

            // For non-JSON formats, return raw sqlite output
            if (format !== 'json') {
                return this.query(sql, format);
            }

            const messages = this.query(sql);
            if (!messages) return {
                job: {
                    job_id: `JOB-${$.NSProcessInfo.processInfo.processIdentifier}`,
                    user: MsgIntelUtils.USER_INFO.username,
                    executor: "osascript",
                    language: "jxa",
                    imports: ["Foundation", "CoreServices"],
                    binaries: ["sqlite3"],
                    pid: $.NSProcessInfo.processInfo.processIdentifier,
                    query: {
                        timestamp: new Date().toISOString(),
                        source_db: this.dbPath,
                        type: "hidden_messages"
                    }
                },
                data: { 
                    hidden_messages: [] 
                }
            };

            return {
                job: {
                    job_id: `JOB-${$.NSProcessInfo.processInfo.processIdentifier}`,
                    user: MsgIntelUtils.USER_INFO.username,
                    executor: "osascript",
                    language: "jxa",
                    imports: ["Foundation", "CoreServices"],
                    binaries: ["sqlite3"],
                    pid: $.NSProcessInfo.processInfo.processIdentifier,
                    query: {
                        timestamp: new Date().toISOString(),
                        source_db: this.dbPath,
                        type: "hidden_messages"
                    }
                },
                data: {
                    hidden_messages: messages.map(msg => ({
                        message: {
                            guid: $GUID
                            timeline: {
                                delete_date: MsgIntelUtils.convertAppleDate(msg.delete_date),
                                date: MsgIntelUtils.convertAppleDate(msg.message_date),
                                date_retracted: MsgIntelUtils.convertAppleDate(msg.date_retracted)
                            },
                            communication: {
                                channel: {
                                    service: msg.service,
                                    version: msg.version,
                                    is_from_me: msg.is_from_me,
                                    chat_identifier: msg.chat_identifier
                                },
                                ...MsgIntelUtils.mapCommunication(msg, 
                                    this.handles.byRowId.get(msg.handle_id),
                                    this.handles.byId.get(msg.destination_caller_id))
                            },
                            content: {
                                text: msg.text,
                                subject: msg.subject,
                                group_title: msg.group_title
                            },
                            thread: {
                                associated_guid: $GUID
                                reply_to_guid: $GUID
                            }
                        }
                    }))
                }
            };
        }
    }

    // Analyze Class
    class Analyze extends BaseDB {
        constructor() {
            super(MsgIntelUtils.DBS.chat);
        }

        getAnalytics(format = 'json') {
            const sql = `
                WITH monthly_stats AS (
                    SELECT 
                        h.ROWID as handle_id,
                        strftime('%Y-%m', datetime(m.date/1000000000 + 978307200, 'unixepoch')) as month,
                        COUNT(*) as count
                    FROM handle h
                    LEFT JOIN message m ON h.ROWID = m.handle_id
                    WHERE m.date IS NOT NULL
                    GROUP BY h.ROWID, month
                )
                SELECT 
                    h.ROWID,
                    h.id,
                    h.service,
                    h.country,
                    h.uncanonicalized_id,
                    h.person_centric_id,
                    COUNT(DISTINCT m.ROWID) as message_count,
                    COUNT(DISTINCT c.ROWID) as chat_count,
                    MIN(m.date) as first_message_date,
                    MAX(m.date) as last_message_date,
                    SUM(m.is_from_me) as sent_count,
                    SUM(CASE WHEN m.is_from_me = 0 THEN 1 ELSE 0 END) as received_count,
                    -- Monthly message counts
                    GROUP_CONCAT(ms.month || ':' || ms.count) as monthly_counts,
                    -- Message type counts
                    SUM(CASE WHEN m.is_audio_message = 1 THEN 1 ELSE 0 END) as audio_count,
                    SUM(CASE WHEN m.is_empty = 0 AND m.text IS NULL THEN 1 ELSE 0 END) as attachment_count,
                    SUM(CASE WHEN m.is_emote = 1 THEN 1 ELSE 0 END) as emoji_count,
                    SUM(CASE WHEN m.was_downgraded = 1 THEN 1 ELSE 0 END) as downgraded_count,
                    SUM(CASE WHEN m.is_delayed = 1 THEN 1 ELSE 0 END) as delayed_count,
                    SUM(CASE WHEN m.is_auto_reply = 1 THEN 1 ELSE 0 END) as auto_reply_count,
                    SUM(CASE WHEN m.is_spam = 1 THEN 1 ELSE 0 END) as spam_count,
                    SUM(CASE WHEN m.is_system_message = 1 THEN 1 ELSE 0 END) as system_count,
                    SUM(CASE WHEN m.is_forward = 1 THEN 1 ELSE 0 END) as forward_count,
                    SUM(CASE WHEN m.is_archive = 1 THEN 1 ELSE 0 END) as archive_count,
                    SUM(CASE WHEN m.is_expirable = 1 THEN 1 ELSE 0 END) as expirable_count,
                    -- Chat relationships
                    GROUP_CONCAT(DISTINCT c.chat_identifier) as shared_chats,
                    GROUP_CONCAT(DISTINCT c.style) as chat_styles,
                    GROUP_CONCAT(DISTINCT c.service_name) as services_used,
                    GROUP_CONCAT(DISTINCT c.room_name) as group_chats,
                    SUM(c.is_blackholed) as blocked_count,
                    SUM(c.is_archived) as archived_count
                FROM handle h
                LEFT JOIN message m ON h.ROWID = m.handle_id
                LEFT JOIN chat_handle_join chj ON h.ROWID = chj.handle_id
                LEFT JOIN chat c ON chj.chat_id = c.ROWID
                LEFT JOIN monthly_stats ms ON h.ROWID = ms.handle_id
                GROUP BY h.ROWID
                ORDER BY h.id;`;

            // For non-JSON formats, return raw sqlite output
            if (format !== 'json') {
                return this.query(sql, format);
            }

            const handles = this.query(sql);
            if (!handles) return { handles: [] };

            return {
                handles: handles.map(h => ({
                    handle: {
                        contact_info: {
                            id: h.id,
                            phone_number: h.id.includes('@') ? null : h.id,
                            email: h.id.includes('@') ? h.id : null,
                            country: h.country,
                            service: h.service,
                            uncanonicalized_id: h.uncanonicalized_id,
                            person_centric_id: h.person_centric_id
                        },
                        timeline: {
                            first_message: MsgIntelUtils.convertAppleDate(h.first_message_date),
                            last_message: MsgIntelUtils.convertAppleDate(h.last_message_date),
                            monthly_activity: h.monthly_counts ? 
                                Object.fromEntries(
                                    h.monthly_counts.split(',')
                                    .map(pair => pair.split(':'))
                                    .map(([month, count]) => [month, parseInt(count)])
                                ) : {}
                        },
                        stats: {
                            message_count: h.message_count,
                            chat_count: h.chat_count,
                            sent_count: h.sent_count,
                            received_count: h.received_count,
                            types: {
                                audio: h.audio_count,
                                attachment: h.attachment_count,
                                emoji: h.emoji_count,
                                downgraded: h.downgraded_count,
                                delayed: h.delayed_count,
                                auto_reply: h.auto_reply_count,
                                spam: h.spam_count,
                                system: h.system_count,
                                forward: h.forward_count,
                                archive: h.archive_count,
                                expirable: h.expirable_count
                            }
                        },
                        relationships: {
                            shared_chats: h.shared_chats ? h.shared_chats.split(',') : [],
                            chat_styles: h.chat_styles ? h.chat_styles.split(',').map(Number) : [],
                            services_used: h.services_used ? h.services_used.split(',') : [],
                            group_chats: h.group_chats ? h.group_chats.split(',').filter(Boolean) : [],
                            blocked_count: h.blocked_count,
                            archived_count: h.archived_count
                        }
                    }
                }))
            };
        }
    }

    // AnalyzeContact Class
    class AnalyzeContact extends BaseDB {
        constructor() {
            super(MsgIntelUtils.DBS.chat);
        }

        getAnalytics(inputStr, format = 'json') {
            debug("Entering getAnalytics");
            debug("Input: " + inputStr + ", Format: " + format);

            const escapeInput = (input) => {
                debug("Escaping input: " + input);
                return input.replace(/_/g, '\\_').replace(/%/g, '\\%');
            };
            
            const cleanPhoneNumber = (number) => {
                debug("Cleaning phone number: " + number);
                return number.replace(/\D/g, '');
            };
            
            const escapedInputStr = escapeInput(inputStr);
            const cleanedInput = cleanPhoneNumber(inputStr);
            
            debug("Escaped input: " + escapedInputStr);
            debug("Cleaned input: " + cleanedInput);

            const sql = `
                WITH monthly_stats AS (
                    SELECT 
                        h.ROWID as handle_id,
                        strftime('%Y-%m', datetime(m.date/1000000000 + 978307200, 'unixepoch')) as month,
                        COUNT(*) as count
                    FROM handle h
                    LEFT JOIN message m ON h.ROWID = m.handle_id
                    WHERE m.date IS NOT NULL
                    AND (
                        h.id = '${escapedInputStr}' 
                        OR h.uncanonicalized_id = '${escapedInputStr}'
                        OR REPLACE(REPLACE(REPLACE(h.id, '+', ''), '-', ''), ' ', '') = '${cleanedInput}'
                    )
                    GROUP BY h.ROWID, month
                )
                SELECT 
                    h.ROWID,
                    h.id,
                    h.service,
                    h.country,
                    h.uncanonicalized_id,
                    h.person_centric_id,
                    COUNT(DISTINCT m.ROWID) as message_count,
                    COUNT(DISTINCT c.ROWID) as chat_count,
                    MIN(m.date) as first_message_date,
                    MAX(m.date) as last_message_date,
                    SUM(m.is_from_me) as sent_count,
                    SUM(CASE WHEN m.is_from_me = 0 THEN 1 ELSE 0 END) as received_count,
                    -- Monthly message counts
                    GROUP_CONCAT(ms.month || ':' || ms.count) as monthly_counts,
                    -- Message type counts
                    SUM(CASE WHEN m.is_audio_message = 1 THEN 1 ELSE 0 END) as audio_count,
                    SUM(CASE WHEN m.is_empty = 0 AND m.text IS NULL THEN 1 ELSE 0 END) as attachment_count,
                    SUM(CASE WHEN m.is_emote = 1 THEN 1 ELSE 0 END) as emoji_count,
                    SUM(CASE WHEN m.was_downgraded = 1 THEN 1 ELSE 0 END) as downgraded_count,
                    SUM(CASE WHEN m.is_delayed = 1 THEN 1 ELSE 0 END) as delayed_count,
                    SUM(CASE WHEN m.is_auto_reply = 1 THEN 1 ELSE 0 END) as auto_reply_count,
                    SUM(CASE WHEN m.is_spam = 1 THEN 1 ELSE 0 END) as spam_count,
                    SUM(CASE WHEN m.is_system_message = 1 THEN 1 ELSE 0 END) as system_count,
                    SUM(CASE WHEN m.is_forward = 1 THEN 1 ELSE 0 END) as forward_count,
                    SUM(CASE WHEN m.is_archive = 1 THEN 1 ELSE 0 END) as archive_count,
                    SUM(CASE WHEN m.is_expirable = 1 THEN 1 ELSE 0 END) as expirable_count,
                    -- Chat relationships
                    GROUP_CONCAT(DISTINCT c.chat_identifier) as shared_chats,
                    GROUP_CONCAT(DISTINCT c.style) as chat_styles,
                    GROUP_CONCAT(DISTINCT c.service_name) as services_used,
                    GROUP_CONCAT(DISTINCT c.room_name) as group_chats,
                    SUM(c.is_blackholed) as blocked_count,
                    SUM(c.is_archived) as archived_count
                FROM handle h
                LEFT JOIN message m ON h.ROWID = m.handle_id
                LEFT JOIN chat_handle_join chj ON h.ROWID = chj.handle_id
                LEFT JOIN chat c ON chj.chat_id = c.ROWID
                LEFT JOIN monthly_stats ms ON h.ROWID = ms.handle_id
                WHERE (
                    h.id = '${escapedInputStr}' 
                    OR h.uncanonicalized_id = '${escapedInputStr}'
                    OR REPLACE(REPLACE(REPLACE(h.id, '+', ''), '-', ''), ' ', '') = '${cleanedInput}'
                    OR h.id LIKE '%${escapedInputStr}%'
                    OR h.uncanonicalized_id LIKE '%${escapedInputStr}%'
                )
                GROUP BY h.ROWID
                ORDER BY h.id;`;

            // For non-JSON formats, return raw sqlite output
            if (format !== 'json') {
                return this.query(sql, format);
            }

            const handles = this.query(sql);
            if (!handles) return { handles: [] };

            // Add message search
            const search = new Search();
            const messages = search.searchAll(inputStr);

            debug("Exiting getAnalytics");
            return {
                job: MsgIntelUtils.createJobMetadata(this.dbPath, "analyze_contact"),
                data: {
                    handles: handles.map(h => ({
                        handle: {
                            contact_info: {
                                id: h.id,
                                phone_number: h.id.includes('@') ? null : h.id,
                                email: h.id.includes('@') ? h.id : null,
                                country: h.country,
                                service: h.service,
                                uncanonicalized_id: h.uncanonicalized_id,
                                person_centric_id: h.person_centric_id
                            },
                            timeline: {
                                first_message: MsgIntelUtils.convertAppleDate(h.first_message_date),
                                last_message: MsgIntelUtils.convertAppleDate(h.last_message_date),
                                monthly_activity: h.monthly_counts ? 
                                    Object.fromEntries(
                                        h.monthly_counts.split(',')
                                        .map(pair => pair.split(':'))
                                        .map(([month, count]) => [month, parseInt(count)])
                                    ) : {}
                            },
                            stats: {
                                message_count: h.message_count,
                                chat_count: h.chat_count,
                                sent_count: h.sent_count,
                                received_count: h.received_count,
                                types: {
                                    audio: h.audio_count,
                                    attachment: h.attachment_count,
                                    emoji: h.emoji_count,
                                    downgraded: h.downgraded_count,
                                    delayed: h.delayed_count,
                                    auto_reply: h.auto_reply_count,
                                    spam: h.spam_count,
                                    system: h.system_count,
                                    forward: h.forward_count,
                                    archive: h.archive_count,
                                    expirable: h.expirable_count
                                }
                            },
                            messages: messages.data.messages
                        }
                    }))
                }
            };
        }
    }

    // 1. Rename class to Contacts
    class Contacts extends BaseDB {
        constructor() {
            super(MsgIntelUtils.DBS.chat);
        }

        getAll(format = 'json') {
            debug("Entering getAll");
            
            const sql = `
                SELECT 
                    h.id as contact_id,
                    h.service,
                    h.country,
                    COUNT(DISTINCT m.ROWID) as message_count,
                    MIN(datetime(m.date/1000000000 + 978307200, 'unixepoch')) as first_seen,
                    MAX(datetime(m.date/1000000000 + 978307200, 'unixepoch')) as last_seen,
                    COUNT(DISTINCT c.ROWID) as chat_count,
                    COUNT(DISTINCT CASE WHEN c.style = 43 THEN c.ROWID END) as group_chat_count
                FROM handle h
                LEFT JOIN message m ON h.ROWID = m.handle_id
                LEFT JOIN chat_handle_join chj ON h.ROWID = chj.handle_id
                LEFT JOIN chat c ON chj.chat_id = c.ROWID
                GROUP BY h.id
                ORDER BY message_count DESC;`;

            try {
                if (format !== 'json') {
                    return this.query(sql, format);
                }

                const contacts = this.query(sql);
                if (!contacts || contacts.length === 0) {
                    debug("No contacts found");
                    return {
                        job: MsgIntelUtils.createJobMetadata(this.dbPath, "list_contacts"),
                        data: { contacts: [] }
                    };
                }

                return {
                    job: MsgIntelUtils.createJobMetadata(this.dbPath, "list_contacts"),
                    data: {
                        contacts: contacts.map(c => ({
                            id: c.contact_id,
                            service: c.service,
                            country: c.country,
                            activity: {
                                messages: c.message_count,
                                chats: c.chat_count,
                                groups: c.group_chat_count,
                                first_seen: c.first_seen,
                                last_seen: c.last_seen
                            }
                        }))
                    }
                };
            } catch (error) {
                debug(`Error in getAll: ${error}`);
                return {
                    job: MsgIntelUtils.createJobMetadata(this.dbPath, "list_contacts"),
                    data: { contacts: [] },
                    error: error.toString()
                };
            }
        }
    }

    // Deleted Class
    class Deleted extends BaseDB {
        constructor() {
            super(MsgIntelUtils.DBS.chat);
            this.handleCache = {};
        }

        getDeletedMessages(format = 'json') {
            const sql = `
                SELECT 
                    d.ROWID,
                    d.guid,
                    d.recordID,
                    h.id as handle_id,
                    h.service,
                    h.country
                FROM sync_deleted_messages d
                LEFT JOIN handle h ON d.handle_id = h.ROWID
                UNION ALL
                SELECT 
                    d.ROWID,
                    d.guid,
                    NULL as recordID,
                    h.id as handle_id,
                    h.service,
                    h.country
                FROM deleted_messages d
                LEFT JOIN handle h ON d.handle_id = h.ROWID;`;

            return this.query(sql, format);
        }

        getDeletedChats(format = 'json') {
            const sql = `
                SELECT c.ROWID, c.guid, c.recordID
                FROM sync_deleted_chats c;`;

            return this.query(sql, format);
        }

        getDeletedAttachments(format = 'json') {
            const sql = `
                SELECT a.ROWID, a.guid, a.recordID
                FROM sync_deleted_attachments a;`;

            return this.query(sql, format);
        }

        getAll(format = 'json') {
            debug("Entering Deleted.getAll");

            try {
                if (format !== 'json') {
                    return this.query(sql, format);
                }

                const results = {
                    job: MsgIntelUtils.createJobMetadata(this.dbPath, "list_deleted"),
                    data: {
                        deleted: {
                            messages: [],
                            chats: [],
                            attachments: []
                        }
                    }
                };

                // Get deleted messages with handle info
                const messages = this.getDeletedMessages();
                if (messages && messages.length > 0) {
                    results.data.deleted.messages = messages.map(m => ({
                        rowid: m.ROWID,
                        guid: $GUID
                        record_id: m.recordID,
                        handle: m.handle_id ? {
                            id: m.handle_id,
                            service: m.service,
                            country: m.country
                        } : null
                    }));
                }

                // Get deleted chats
                const chats = this.getDeletedChats();
                if (chats && chats.length > 0) {
                    results.data.deleted.chats = chats.map(c => ({
                        rowid: c.ROWID,
                        guid: $GUID
                        record_id: c.recordID
                    }));
                }

                // Get deleted attachments
                const attachments = this.getDeletedAttachments();
                if (attachments && attachments.length > 0) {
                    results.data.deleted.attachments = attachments.map(a => ({
                        rowid: a.ROWID,
                        guid: $GUID
                        record_id: a.recordID
                    }));
                }

                return results;

            } catch (error) {
                debug(`Error in getAll: ${error.toString()}`);
                return {
                    job: MsgIntelUtils.createJobMetadata(this.dbPath, "list_deleted"),
                    data: { deleted: { messages: [], chats: [], attachments: [] } },
                    error: error.toString()
                };
            }
        }
    }

    // SearchMsg Class
    class SearchMsg extends BaseDB {
        constructor() {
            super(MsgIntelUtils.DBS.chat);
            this.handles = MsgIntelUtils.getHandles(this);
        }

        searchAll(inputStr, format = 'json') {
            const escapedInputStr = inputStr.replace(/_/g, '\\_').replace(/%/g, '\\%');

            const msgSql = `SELECT 
                m.ROWID, m.guid, m.text, m.service, m.handle_id,
                m.is_from_me, m.destination_caller_id,
                m.service_center, m.version,
                m.date, m.date_read, m.date_delivered, m.date_played, m.date_retracted, m.date_edited,
                m.subject, m.group_title,
                m.associated_message_guid, m.reply_to_guid, m.thread_originator_guid,
                m.is_delivered, m.is_read, m.is_sent, m.is_played, m.is_prepared, m.is_finished,
                m.is_empty, m.is_archive, m.is_spam, m.is_corrupt, m.is_expirable,
                m.is_system_message, m.is_service_message, m.is_forward, m.is_audio_message, m.is_emote,
                m.was_data_detected, m.was_delivered_quietly, m.was_detonated,
                m.ck_sync_state, m.ck_record_id, m.ck_record_change_tag,
                c.chat_identifier
            FROM message m 
            LEFT JOIN chat_message_join cmj ON m.ROWID = cmj.message_id
            LEFT JOIN chat c ON cmj.chat_id = c.ROWID
            LEFT JOIN handle h ON m.handle_id = h.ROWID
            WHERE m.text LIKE '%${escapedInputStr}%'`;

            // For non-JSON formats, return raw sqlite output
            if (format !== 'json') {
                return this.query(msgSql, format);
            }

            const messages = this.query(msgSql);
            if (!messages) return { data: { messages: [] }};

            return {
                job: {
                    job_id: `JOB-${$.NSProcessInfo.processInfo.processIdentifier}`,
                    user: MsgIntelUtils.USER_INFO.username,
                    executor: "osascript",
                    language: "jxa",
                    imports: ["Foundation", "CoreServices"],
                    binaries: ["sqlite3"],
                    pid: $.NSProcessInfo.processInfo.processIdentifier,
                    query: {
                        timestamp: new Date().toISOString(),
                        source_db: this.dbPath,
                        type: "searchMsg",
                        inputStr: inputStr
                    }
                },
                data: {
                    messages: messages.map(msg => ({
                        message: {
                            guid: $GUID
                            timestamps: {
                                date: MsgIntelUtils.convertAppleDate(msg.date),
                                date_read: MsgIntelUtils.convertAppleDate(msg.date_read),
                                date_delivered: MsgIntelUtils.convertAppleDate(msg.date_delivered),
                                date_played: MsgIntelUtils.convertAppleDate(msg.date_played),
                                date_retracted: MsgIntelUtils.convertAppleDate(msg.date_retracted),
                                date_edited: MsgIntelUtils.convertAppleDate(msg.date_edited)
                            },
                            type: {
                                is_empty: Boolean(msg.is_empty),
                                is_archive: Boolean(msg.is_archive),
                                is_spam: Boolean(msg.is_spam),
                                is_corrupt: Boolean(msg.is_corrupt),
                                is_expirable: Boolean(msg.is_expirable),
                                is_system: Boolean(msg.is_system_message),
                                is_service: Boolean(msg.is_service_message),
                                is_forward: Boolean(msg.is_forward),
                                is_audio: Boolean(msg.is_audio_message),
                                is_emote: Boolean(msg.is_emote)
                            },
                            state: {
                                is_delivered: Boolean(msg.is_delivered),
                                is_read: Boolean(msg.is_read),
                                is_sent: Boolean(msg.is_sent),
                                is_played: Boolean(msg.is_played),
                                is_prepared: Boolean(msg.is_prepared),
                                is_finished: Boolean(msg.is_finished),
                                is_empty: Boolean(msg.is_empty),
                                was_data_detected: Boolean(msg.was_data_detected),
                                was_delivered_quietly: Boolean(msg.was_delivered_quietly),
                                was_detonated: Boolean(msg.was_detonated)
                            },
                            communication: {
                                channel: {
                                    service: msg.service,
                                    version: msg.version,
                                    is_from_me: msg.is_from_me,
                                    chat_identifier: msg.chat_identifier,
                                    thread: {
                                        reply_to_guid: $GUID
                                        originator_guid: $GUID
                                        associated_guid: $GUID
                                    }
                                },
                                sender: msg.is_from_me === 0 ? {
                                    phone_number: this.handles.byRowId.get(msg.handle_id)?.id.includes('@') ? null : this.handles.byRowId.get(msg.handle_id)?.id,
                                    email: this.handles.byRowId.get(msg.handle_id)?.id.includes('@') ? this.handles.byRowId.get(msg.handle_id)?.id : null,
                                    country: this.handles.byRowId.get(msg.handle_id)?.country,
                                    handle_id: msg.handle_id
                                } : {
                                    phone_number: msg.destination_caller_id?.includes('@') ? null : msg.destination_caller_id,
                                    email: msg.destination_caller_id?.includes('@') ? msg.destination_caller_id : null,
                                    country: this.handles.byId.get(msg.destination_caller_id)?.country,
                                    handle_id: null
                                },
                                receiver: msg.is_from_me === 1 ? {
                                    phone_number: this.handles.byRowId.get(msg.handle_id)?.id.includes('@') ? null : this.handles.byRowId.get(msg.handle_id)?.id,
                                    email: this.handles.byRowId.get(msg.handle_id)?.id.includes('@') ? this.handles.byRowId.get(msg.handle_id)?.id : null,
                                    country: this.handles.byRowId.get(msg.handle_id)?.country,
                                    handle_id: msg.handle_id
                                } : {
                                    phone_number: msg.destination_caller_id?.includes('@') ? null : msg.destination_caller_id,
                                    email: msg.destination_caller_id?.includes('@') ? msg.destination_caller_id : null,
                                    country: this.handles.byId.get(msg.destination_caller_id)?.country,
                                    handle_id: null
                                }
                            },
                            content: {
                                text: msg.text,
                                subject: msg.subject,
                                group_title: msg.group_title
                            },
                            icloud: {
                                ck_sync_state: msg.ck_sync_state,
                                ck_record_id: msg.ck_record_id,
                                ck_record_change_tag: msg.ck_record_change_tag
                            }
                        }
                    }))
                }
            };
        }

        searchByDate(startDate, endDate) {
            const sql = `SELECT m.ROWID, m.text, m.date, m.service, h.id as contact_id 
                FROM message m 
                LEFT JOIN handle h ON m.handle_id = h.ROWID 
                WHERE m.date BETWEEN ${startDate} AND ${endDate};`;
            return this.query(sql);
        }
    }
    // After the class definitions but before the main execution:

    function parseArgs() {
        const args = $.NSProcessInfo.processInfo.arguments;
        const options = {
            debug: false,  // Add debug option
            messages: false,
            attachments: false,
            analyze: false,
            threads: false,
            search: null,
            date: null,
            hidden: false,
            drafts: false,
            all: false,
            output: null,
            contacts: false,  // Rename from handles
            analyzeContact: null,
            deleted: false,  // Add deleted option
            searchMsg: null,  // Add new option
        };

        for (let i = 2; i < args.count; i++) {
            const arg = ObjC.unwrap(args.objectAtIndex(i)).toLowerCase();
            switch(arg) {
                case '--debug':
                    options.debug = true;
                    DEBUG = true;  // Set global debug flag
                    break;
                case '--analyze':
                    options.analyze = true;
                    break;
                case '--analyzecontact':
                    if (i + 1 < args.count) {
                        options.analyzeContact = ObjC.unwrap(args.objectAtIndex(++i));
                        debug("AnalyzeContact input: " + options.analyzeContact);
                    }
                    break;
                case '--messages':
                    options.messages = true;
                    break;
                case '--attachments':
                    options.attachments = true;
                    break;
                case '--threads':
                    options.threads = true; 
                    break;
                case '--hidden':
                    options.hidden = true;
                    break;
                case '--drafts':
                    options.drafts = true;
                    break;
                case '--all':
                    options.all = true;
                    break;
                case '--search':
                    if (i + 1 < args.count) {
                        options.search = ObjC.unwrap(args.objectAtIndex(++i));
                    }
                    break;
                case '--date':
                    if (i + 2 < args.count) {
                        options.date = {
                            start: ObjC.unwrap(args.objectAtIndex(++i)),
                            end: ObjC.unwrap(args.objectAtIndex(++i))
                        };
                    }
                    break;
                case '--contacts':  // Rename from --handles
                    options.contacts = true;
                    break;
                case '--deleted':
                    options.deleted = true;
                    break;
                case '--searchmsg':
                    if (i + 1 < args.count) {
                        options.searchMsg = ObjC.unwrap(args.objectAtIndex(++i));
                    }
                    break;
                case '--help':
                    showHelp();
                    return options;
                case '--output':
                    if (i + 1 < args.count) {
                        const format = ObjC.unwrap(args.objectAtIndex(++i));
                        if (VALID_OUTPUT_FORMATS.includes(format)) {
                            options.output = format;
                        } else {
                            console.log(`Invalid output format: ${format}`);
                            console.log(`Valid formats: ${VALID_OUTPUT_FORMATS.join(', ')}`);
                            return options;
                        }
                    }
                    break;
            }
        }

        // If no valid options specified, show help and exit
        if (!Object.values(options).some(x => x !== null && x !== false)) {
            showHelp();
            return options;
        }

        return options;
    }

    // Separate help function to avoid duplication
    function showHelp() {
        console.log(`
Usage: osascript -l JavaScript msgIntel.js [options]

Options:
    --messages       Get all messages
    --attachments   Get all attachments
    --analyze       Get message analytics
    --threads       Get all chat threads
    --hidden        Get hidden/recoverable messages
    --deleted       List deleted items
    --search <term> Search messages
    --date <start> <end> Get messages between dates
    --contacts      List all contacts
    --analyzeContact <contactId> Get analytics for specific contact
    --drafts        Get draft messages
    --output <format> Output format (json, csv, etc)
    --debug         Enable debug output
    --help         Show this help
    --searchMsg <text>  Search message text content
    `);
    }

    // Main execution
    if (typeof $ !== 'undefined') {
        const options = parseArgs();
        // TODO: add to --debug
        // console.log("DEBUG 2: After parseArgs - options:", JSON.stringify(options, null, 2));
        
        if (options.help) {
            return;
        }

        const format = options.output || 'json';
        
        // Add drafts handler
        if (options.drafts) {
            const drafts = new Drafts();
            const results = drafts.getDrafts(format);
            console.log(JSON.stringify(results, null, 2));
            return;
        }

        // Main block with access check
        if (options.messages || options.attachments || options.analyze || 
            options.threads || options.search || options.date || options.all ||
            options.analyzeContact || options.contacts || options.deleted) {
            
            // TODO: add to --debug
            // console.log("DEBUG 3: Before main block - analyzeContact:", options.analyzeContact);
            
            const access = Check();
            // TODO: add to --debug
            // console.log("DEBUG 5: Access check result:", access);
            
            if (access) {
                // TODO: add to --debug
                // console.log("DEBUG 6: Inside access block");
                
                const messages = new Messages();
                const attachments = new Attachments();
                const search = new Search();
                const analytics = new AnalyzeContact();
                
                // Search handlerf
                if (options.search) {
                    const searchResults = search.searchAll(options.search, format);
                    if (format !== 'json') {
                        console.log(searchResults);
                    } else {
                        console.log(JSON.stringify(searchResults, null, 2));
                    }
                    return;
                }

                // AnalyzeContact handler
                if (options.analyzeContact) {
                    // TODO: add to --debug
                    // debug("Inside analyzeContact handler");
                    // debug(`Contact value: ${options.analyzeContact}`);
                    
                    const analyzeResults = analytics.getAnalytics(options.analyzeContact, format);
                    // TODO: add to --debug
                    // debug(`Results: ${JSON.stringify(analyzeResults, null, 2)}`);
                    
                    if (format !== 'json') {
                        console.log(analyzeResults);
                    } else {
                        console.log(JSON.stringify(analyzeResults, null, 2));
                    }
                    return;
                }

                // Move contacts handler here with other handlers
                if (options.contacts) {
                    debug("Listing all contacts");
                    const contacts = new Contacts();
                    const contactList = contacts.getAll(format);
                    if (format !== 'json') {
                        console.log(contactList);
                    } else {
                        console.log(JSON.stringify(contactList, null, 2));
                    }
                    return;
                }

                // Add deleted handler
                if (options.deleted) {
                    debug("Listing deleted items");
                    const deleted = new Deleted();
                    const deletedList = deleted.getAll(format);
                    if (format !== 'json') {
                        console.log(deletedList);
                    } else {
                        console.log(JSON.stringify(deletedList, null, 2));
                    }
                    return;
                }

                const results = {
                    job: {
                        job_id: `JOB-${$.NSProcessInfo.processInfo.processIdentifier}`,
                        user: MsgIntelUtils.USER_INFO.username,
                        executor: "osascript",
                        language: "jxa",
                        imports: ["Foundation", "CoreServices"],
                        binaries: ["sqlite3"],
                        pid: $.NSProcessInfo.processInfo.processIdentifier,
                        query: {
                            timestamp: new Date().toISOString(),
                            source_db: MsgIntelUtils.DBS.chat
                        }
                    },
                    data: {
                        messages: options.messages ? messages.getMessages(format) : undefined,
                        analyze: options.analyze ? (new Analyze()).getAnalytics(format) : undefined,
                        threads: options.threads ? messages.getThreads(format) : undefined,
                        attachments: options.attachments ? attachments.getAttachments(format) : undefined
                    }
                };
                
                if (format !== VALID_OUTPUT_FORMATS[0]) {
                    let result = '';
                    for (const [key, value] of Object.entries(results.data)) {
                        if (value) result += value + '\n';
                    }
                    console.log(result.trim());
                } else {
                    console.log(JSON.stringify(results, null, 2));
                }

                // Move all other handlers inside here
                if (options.hidden) {
                    const hidden = new HiddenMessages();
                    const hiddenResults = hidden.getHiddenMessages(format);
                    if (format !== VALID_OUTPUT_FORMATS[0]) {
                        console.log(hiddenResults);
                    } else {
                        console.log(JSON.stringify(hiddenResults, null, 2));
                    }
                    return;
                }
            }
        }

        // Add searchMsg handler
        if (options.searchMsg) {
            const msgSearch = new SearchMsg();
            const results = msgSearch.searchAll(options.searchMsg, format);
            if (format !== 'json') {
                console.log(results);
            } else {
                console.log(JSON.stringify(results, null, 2));
            }
            return;
        }

        // Move class exports here
        return { 
            MsgIntelUtils, 
            Messages, 
            Attachments, 
            Check, 
            Search, 
            Drafts, 
            HiddenMessages,
            Analyze,
            AnalyzeContact,
            Contacts,
            Deleted,
            SearchMsg
        };
    }
})();
