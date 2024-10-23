#!/usr/bin/env osascript -l JavaScript

ObjC.import('sqlite3');
ObjC.import('Foundation');

const DB_PATH = "/Users/darmado/Library/Safari/History.db";
const QUERY = "SELECT * FROM history_items LIMIT 5;";

function testSQLite() {
    console.log("Testing SQLite3 library via ObjC bridge:");
    console.log(`Attempting to query database: ${DB_PATH}`);
    console.log(`Query: ${QUERY}`);

    let db = Ref();
    let stmt = Ref();

    try {
        console.log("SQLite version:", $.sqlite3_libversion());
        
        let rc = $.sqlite3_open(DB_PATH, db);
        console.log("sqlite3_open result code:", rc);
        
        if (rc !== $.SQLITE_OK) {
            throw new Error(`Unable to open database: ${$.sqlite3_errmsg(db[0])} (Error code: ${rc})`);
        }

        console.log("Database opened successfully");

        rc = $.sqlite3_prepare_v2(db[0], QUERY, -1, stmt, null);
        console.log("sqlite3_prepare_v2 result code:", rc);
        
        if (rc !== $.SQLITE_OK) {
            throw new Error(`Unable to prepare statement: ${$.sqlite3_errmsg(db[0])} (Error code: ${rc})`);
        }

        console.log("SQL statement prepared successfully");

        while ($.sqlite3_step(stmt[0]) === $.SQLITE_ROW) {
            let rowData = [];
            for (let i = 0; i < $.sqlite3_column_count(stmt[0]); i++) {
                rowData.push(ObjC.unwrap($.sqlite3_column_text(stmt[0], i)) || "NULL");
            }
            console.log(rowData.join(" | "));
        }

        console.log("Query executed successfully");
    } catch (error) {
        console.log(`Error: ${error.message}`);
        if (db[0]) {
            console.log(`SQLite error code: ${$.sqlite3_errcode(db[0])}`);
            console.log(`SQLite error message: ${$.sqlite3_errmsg(db[0])}`);
        }
    } finally {
        if (stmt[0]) {
            $.sqlite3_finalize(stmt[0]);
            console.log("Statement finalized");
        }
        if (db[0]) {
            $.sqlite3_close(db[0]);
            console.log("Database closed");
        }
    }
}

function testNSTask() {
    console.log("Testing NSTask to run sqlite3 command:");
    try {
        var task = $.NSTask.alloc.init;
        task.executableURL = $.NSURL.fileURLWithPath("/usr/bin/sqlite3");
        task.arguments = [DB_PATH, QUERY];

        var pipe = $.NSPipe.pipe;
        task.standardOutput = pipe;
        task.standardError = pipe;

        task.launch;
        task.waitUntilExit;

        var data = pipe.fileHandleForReading.readDataToEndOfFile;
        var output = $.NSString.alloc.initWithDataEncoding(data, $.NSUTF8StringEncoding).js;

        console.log(output);
    } catch (error) {
        console.log(`Error: ${error}`);
    }
}

console.log("SQLite3 Test Script");
console.log("==================");
testSQLite();
console.log("\n==================\n");
testNSTask();
