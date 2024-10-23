// This JXA script extracts data from the chat database and outputs specific messages.
// macOS Ventura (13.6.7) compatible. Utilizing NSPipe, NSTask, and POSIX as much as possible.

ObjC.import('Foundation');
ObjC.import('AppKit');

// Define the path to the Messages database.
const dbPath = '/Users/darmado/Library/Messages/chat.db';

// Create a task to execute the SQLite command using NSTask.
let task = $.NSTask.alloc.init;
task.launchPath = '/usr/bin/sqlite3';

task.arguments = [
    dbPath,
    `
    SELECT guid, text, handle_id, service, is_from_me, 
           datetime((date / 1000000000) + 978307200, 'unixepoch', 'localtime') AS readable_date 
    FROM message 
    ORDER BY date DESC 
    LIMIT 10;
    `
];

// Create pipes for the standard output and error.
let outputPipe = $.NSPipe.pipe;
let errorPipe = $.NSPipe.pipe;

task.standardOutput = outputPipe;
task.standardError = errorPipe;

// Launch the task.
task.launch;
task.waitUntilExit;

// Read data from the output pipe.
let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile;
let outputString = $.NSString.alloc.initWithDataEncoding(outputData, $.NSUTF8StringEncoding).js;

// Read data from the error pipe (if any).
let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile;
let errorString = $.NSString.alloc.initWithDataEncoding(errorData, $.NSUTF8StringEncoding).js;

// Print the output or handle errors.
if (task.terminationStatus === 0) {
    console.log('Query Output:');
    console.log(outputString);
} else {
    console.log('Error Occurred:');
    console.log(errorString);
}

// Handle system popup permissions using AppleScript via JXA.
const safariPermissionScript = `
    tell application "System Events"
        tell process "SecurityAgent"
            if exists window 1 then
                click button "OK" of window 1
            end if
        end tell
    end tell
`;

// Execute the AppleScript to handle the popup.
const script = $.NSAppleScript.alloc.initWithSource(safariPermissionScript);
script.executeAndReturnError(Ref());

// Optional: Use notifications to alert the user when the script is complete.
const app = Application.currentApplication();
app.includeStandardAdditions = true;
app.displayNotification('JXA Script Completed', {
    withTitle: 'JXA Chat Extractor',
    subtitle: 'The chat extraction has finished.'
});
