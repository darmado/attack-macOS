ObjC.import('Cocoa');
ObjC.import('CoreGraphics');
ObjC.import('AppKit');
ObjC.import('Security');
ObjC.import('AppleScriptObjC');
ObjC.import('CoreServices');
ObjC.bindFunction('CFMakeCollectable', ['id', ['void *']]);

// Set includeStandardAdditions for the entire script
Application.currentApplication().includeStandardAdditions = true;

// display help information
function displayHelp() {
    const helpText = `
$ osascript -l JavaScript ./safariJXA.js [options] [arguments...]

DISCOVER:
    -listTabs                    List all open tabs in Safari
    -listURLs                    List the URLs of the current active tabs in all windows
    -listWindows                 List all open Safari windows
    -listPageTitles              List the titles of the current active tabs in all windows
    -listReadingList             List Safari's reading list
    -listDownloads               List current downloads in Safari
    -listExtensions              List installed Safari extensions
    -listHistory                 List Safari's browsing history

OPEN:
    -launch                      Launch Safari with a 1x1 window
    -openWIndow                   Open a new Safari window with a 1x1 size
    -openURL <url>               Open a URL in Safari
    -mailto <email>              Uses mail.app to open the default email client with the specified email
    -sms <number>                Open the default SMS app with the specified number
    -tel <number>                Open the default phone app with the specified number
    -openTab <url1> [url2] ...   Open one or more new tabs with the specified URLs (max 25)

MANAGE:
    -closeTab <index>            Close a tab by its index or URL
    -closeWindow <index>         Close a Safari window by its index
    -closeSafari                 Quit Safari
    -reloadTab                   Reload the current active tab
    -navigateToURL <url>         Navigate the current tab to a specified URL

EXECUTE:
    -execJS <script>             Execute JavaScript in the current tab

SEARCH:
    -searchGoogle <query>        Search Google in a new tab
    -searchDDG <query>           Search DuckDuckGo in a new tab

SETTINGS:
    -disableImages               Disable image loading in Safari

HELP:
    -help                        Display this help message
    -closeWindow <index>  Close a Safari window by its index
    `;
    
    console.log(helpText);
}


// Improved argument parser function to handle various input formats
function parseArguments() {
    const args = $.NSProcessInfo.processInfo.arguments;
    const parsedArgs = {};
    for (let i = 4; i < args.count; i++) {
        const arg = ObjC.unwrap(args.objectAtIndex(i)).toLowerCase(); // Convert to lowercase
        if (arg.startsWith("-")) {
            const key = arg.substring(1);
            if (key === 'opentab') {
                parsedArgs[key] = [];
                while (i + 1 < args.count && !ObjC.unwrap(args.objectAtIndex(i + 1)).startsWith("-")) {
                    i++;
                    parsedArgs[key].push(ObjC.unwrap(args.objectAtIndex(i)));
                }
            } else {
                const value = (i + 1 < args.count && !ObjC.unwrap(args.objectAtIndex(i + 1)).startsWith("-")) 
                    ? ObjC.unwrap(args.objectAtIndex(i + 1)) 
                    : true;
                parsedArgs[key] = value;
                if (value !== true) i++; // Skip the next argument if it's a value
            }
        }
    }
    return parsedArgs;
}

//function getOpenWindows() {
//    var options = 0; // No special options
//    var windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID);
//    return windowList; // This returns an array of dictionaries with window info
//}

//var windows = getOpenWindows();
//console.log(windows);



// Utility function to check if Safari is open
function isSafariOpen() {
    try {
        var workspace = $.NSWorkspace.sharedWorkspace;
        var apps = workspace.runningApplications;
        for (var i = 0; i < apps.count; i++) {
            var app = apps.objectAtIndex(i);
            if (app.bundleIdentifier.js === "com.apple.Safari") {
                return true;
            }
        }
        return false;
    } catch (error) {
        console.log("Error checking if Safari is open: " + error);
        return false;
    }
}

// Mark functions that likely need admin privileges

// [ADMIN] This function may require admin privileges
function launchSafari() {
    try {
        if (!isSafariOpen()) {
            const safariApp = Application('Safari');
            safariApp.includeStandardAdditions = true;
            safariApp.launch();
            delay(1); // Give Safari a moment to launch
            
            // Check again if we can control Safari after launching
            if (isSafariOpen()) {
                safariApp.windows[0].bounds = {x: 0, y: 0, width: 1, height: 1};
                const safariDetails = {
                    name: safariApp.name(),
                    version: safariApp.version(),
                    windows: safariApp.windows.length
                };
                console.log(`Safari launched: ${JSON.stringify(safariDetails, null, 2)}`);
                return safariDetails;
            } else {
                console.log("Safari launched, but unable to control it. Please grant automation permissions and try again.");
            }
        } else {
            console.log("Safari is already running. Did you mean to open a new window? [-openWIndow].");
        }
    } catch (error) {
        console.log('Error launching Safari: ' + error);
    }
}

// [ADMIN] This function may require admin privileges
function handleMailto(email) {
    return executeNonInteractive(() => {
        try {
            const mailApp = Application('Mail');
            
            // Check if Mail.app is installed
            if (!mailApp.exists()) {
                throw new Error("Mail.app is not installed on this system.");
            }
            
            // Launch Mail.app in the background
            mailApp.launch();
            delay(1); // Give Mail a moment to launch
            
            // Check if Mail.app is running
            if (!mailApp.running()) {
                throw new Error("Failed to launch Mail.app.");
            }
            
            // Create a new message
            const newMessage = mailApp.OutgoingMessage().make();
            if (!newMessage) {
                throw new Error("Failed to create a new message.");
            }
            
            newMessage.toRecipients.push(mailApp.Recipient({address: email}));
            
            // Don't make the message visible
            newMessage.visible = false;
            
            console.log(`Created new email draft for: ${email}`);
            
            // Return the message ID
            return newMessage.id();
        } catch (error) {
            console.log(`Error handling mailto: ${error.message}`);
            console.log(`Stack trace: ${error.stack}`);
            return null;
        }
    });
}

// [ADMIN] This function may require admin privileges
function handleSms(number) {
    try {
        const safariApp = Application('Safari');
        safariApp.includeStandardAdditions = true;
        safariApp.doShellScript(`open "sms:${number}"`);
        console.log(`Opened SMS app for: ${number}`);
    } catch (error) {
        console.log('Error handling sms: ' + error);
    }
}

// [ADMIN] This function may require admin privileges
function handleTel(number) {
    try {
        const safariApp = Application('Safari');
        safariApp.includeStandardAdditions = true;
        safariApp.doShellScript(`open "tel:${number}"`);
        console.log(`Opened phone app for: ${number}`);
    } catch (error) {
        console.log('Error handling tel: ' + error);
    }
}

// fetch Safari tabs using JXA.
function tabs() {
    try {
        if (isSafariOpen()) {
            const safariApp = Application('Safari');
            safariApp.includeStandardAdditions = true;

            let tabInfo = [];

            // Retrieve the current tabs in Safari.
            safariApp.windows().forEach(window => {
                window.tabs().forEach(tab => {
                    tabInfo.push({
                        url: tab.url(),
                        title: tab.name()
                    });
                });
            });

            console.log(JSON.stringify(tabInfo, null, 2));
            return tabInfo;
        } else {
            console.log("Safari is not open. Please launch Safari first.");
        }
    } catch (error) {
        console.log('Error fetching tabs: ' + error);
    }
}

// get the URL of the current active tab.
function getCurrentURL() {
    try {
        if (isSafariOpen()) {
            const safariApp = Application('Safari');
            safariApp.includeStandardAdditions = true;

            const currentWindow = safariApp.windows[0];
            const currentTab = currentWindow.currentTab();
            const currentURL = currentTab.url();
            console.log(currentURL);
            return currentURL;
        } else {
            const message = "Safari is not open. Please launch Safari first.";
            console.log(message);
            return message;
        }
    } catch (error) {
        console.log('Error getting current URL: ' + error);
    }
}

// navigate the current tab to a specified URL.
function navigateToURL(url) {
    try {
        if (isSafariOpen()) {
            const safariApp = Application('Safari');
            safariApp.includeStandardAdditions = true;

            const validatedUrl = validateAndFormatURL(url);

            const currentWindow = safariApp.windows[0];
            if (currentWindow.tabs.length > 0) {
                const currentTab = currentWindow.currentTab();
                //currentTab.url = validatedUrl;
                //console.log(`Navigated to ${validatedUrl}`);
                
            } else {
                console.log("No tabs are open. Please open a tab first.");
            }
        } else {
            console.log("Safari is not open. Please launch Safari first.");
        }
    } catch (error) {
        console.log('Error navigating to URL: ' + error);
    }
}

// open a new tab and navigate to a URL in Safari.
function openTab(...urls) {
    try {
        if (isSafariOpen()) {
            const safariApp = Application('Safari');
            safariApp.includeStandardAdditions = true;

            const window = safariApp.windows[0];
            const windowIndex = 0; // Using the first window by default

            let successCount = 0;
            let failureCount = 0;

            urls.forEach((url, index) => {
                if (index >= 25) {
                    console.log(`Reached maximum limit of 25 tabs. Ignoring remaining URLs.`);
                    return;
                }

                try {
                    const validatedUrl = validateAndFormatURL(url);
                    const newTab = safariApp.Tab({ url: validatedUrl });
                    window.tabs.push(newTab);
                    
                    // Check if the tab was actually created
                    if (newTab.exists()) {
                        console.log(`Opened new tab with URL: ${validatedUrl} in window ${windowIndex}`);
                        successCount++;
                    } else {
                        throw new Error("Failed to create tab");
                    }
                } catch (error) {
                    console.log(`Error opening tab for URL ${url}: ${error.message}`);
                    failureCount++;
                }
            });

            if (successCount > 0) {
                window.currentTab = window.tabs[window.tabs.length - 1];
            }

            console.log(`Summary: Successfully opened ${successCount} tab(s), failed to open ${failureCount} tab(s).`);
        } else {
            console.log("Safari is not open. Please launch Safari first.");
        }
    } catch (error) {
        console.log('Error opening tab(s): ' + error);
    }
}

// validate and format a URL.
function validateAndFormatURL(url) {
    // Regular expression to match a domain name
    const domainRegex = /^([a-zA-Z0-9]+(-[a-zA-Z0-9]+)*\.)+[a-zA-Z]{2,}$/;
    
    // If the input is just a domain name, prepend 'http://'
    if (domainRegex.test(url)) {
        return 'http://' + url;
    }
    
    // If the URL doesn't start with a protocol, assume 'http://'
    if (!/^[a-zA-Z]+:\/\//.test(url)) {
        return 'http://' + url;
    }
    
    // If it's already a full URL, return it as is
    return url;
}

// list all open Safari windows and their tabs.
function listWindows() {
    try {
        const safariApp = Application('Safari');
        safariApp.includeStandardAdditions = true;

        if (!safariApp.running()) {
            console.log("Safari is not running. Please launch Safari first.");
            return;
        }

        let windowInfo = [];

        safariApp.windows().forEach((window, index) => {
            if (window.tabs) {
                let tabs = [];
                window.tabs().forEach(tab => {
                    tabs.push({
                        url: tab.url(),
                        title: tab.name()
                    });
                });
                windowInfo.push({
                    windowIndex: index,
                    tabs: tabs
                });
            } else {
                console.log(`Window ${index} has no tabs or is inaccessible.`);
            }
        });

        console.log(JSON.stringify(windowInfo, null, 2));
        return windowInfo;
    } catch (error) {
        console.log('Error listing windows: ' + error);
    }
}

// list all open tabs in all Safari windows.
function listTabs() {
    try {
        if (isSafariOpen()) {
            const safariApp = Application('Safari');
            safariApp.includeStandardAdditions = true;

            let allTabs = [];

            safariApp.windows().forEach(window => {
                window.tabs().forEach(tab => {
                    allTabs.push({
                        url: tab.url(),
                        title: tab.name()
                    });
                });
            });

            console.log(JSON.stringify(allTabs, null, 2));
            return allTabs;
        } else {
            console.log("Safari is not open. Please launch Safari first.");
        }
    } catch (error) {
        console.log('Error listing tabs: ' + error);
    }
}

// get the URL of the current active tab in all windows.
function listURLs() {
    try {
        if (isSafariOpen()) {
            const safariApp = Application('Safari');
            safariApp.includeStandardAdditions = true;

            let urls = [];

            safariApp.windows().forEach(window => {
                const currentTab = window.currentTab();
                urls.push(currentTab.url());
            });

            console.log(JSON.stringify(urls, null, 2));
            return urls;
        } else {
            const message = "Safari is not open. Please launch Safari first.";
            console.log(message);
            return message;
        }
    } catch (error) {
        console.log('Error getting current URLs: ' + error);
    }
}

// get the page titles of the current active tabs in all windows.
function listPageTitles() {
    try {
        if (isSafariOpen()) {
            const safariApp = Application('Safari');
            safariApp.includeStandardAdditions = true;

            let titles = [];

            safariApp.windows().forEach(window => {
                const currentTab = window.currentTab();
                titles.push(currentTab.name());
            });

            console.log(JSON.stringify(titles, null, 2));
            return titles;
        } else {
            console.log("Safari is not open. Please launch Safari first.");
        }
    } catch (error) {
        console.log('Error getting page titles: ' + error);
    }
}

// close a tab by index in a specific window.
function closeTab(windowIndex, tabIndex) {
    try {
        if (isSafariOpen()) {
            const safariApp = Application('Safari');
            safariApp.includeStandardAdditions = true;

            const window = safariApp.windows[windowIndex];
            window.tabs[tabIndex].close();
            console.log(`Closed tab ${tabIndex} in window ${windowIndex}.`);
        } else {
            console.log("Safari is not open. Please launch Safari first.");
        }
    } catch (error) {
        console.log('Error closing tab: ' + error);
    }
}

// Placeholder for reloading the current tab.
function reloadTab() {
    try {
        if (isSafariOpen()) {
            const safariApp = Application('Safari');
            safariApp.includeStandardAdditions = true;

            const currentWindow = safariApp.windows[0];
            const currentTab = currentWindow.currentTab();
            currentTab.reload();
            console.log("Current tab reloaded.");
        } else {
            console.log("Safari is not open. Please launch Safari first.");
        }
    } catch (error) {
        console.log('Error reloading tab: ' + error);
    }
}

// get the page title of the current active tab.
function getPageTitle() {
    try {
        if (isSafariOpen()) {
            const safariApp = Application('Safari');
            safariApp.includeStandardAdditions = true;

            const currentWindow = safariApp.windows[0];
            const currentTab = currentWindow.currentTab();
            const pageTitle = currentTab.name();
            console.log(`Page title: ${pageTitle}`);
            return pageTitle;
        } else {
            console.log("Safari is not open. Please launch Safari first.");
        }
    } catch (error) {
        console.log('Error getting page title: ' + error);
    }
}

// get Safari's reading list.
function listReadingList() {
    try {
        const safariApp = Application('Safari');
        safariApp.includeStandardAdditions = true;

        // Access the reading list (Note: This is a placeholder; actual access may vary)
        const readingList = safariApp.documents.whose({name: "Reading List"}).tabs;

        let items = [];
        readingList.forEach(item => {
            items.push({
                title: item.name(),
                url: item.url()
            });
        });

        console.log(JSON.stringify(items, null, 2));
        return items;
    } catch (error) {
        console.log('Error getting reading list: ' + error);
    }
}


// list installed Safari extensions.
function listExtensions() {
    try {
        console.log("Function getExtensions is not yet implemented.");
    } catch (error) {
        console.log('Error getting extensions: ' + error);
    }
}

// Add this new function to query Safari history
function queryHistory(limit = 25) {
    const homeDir = $.NSHomeDirectory().js;
    const historyDbPath = `${homeDir}/Library/Safari/History.db`;
    const query = `SELECT history_items.id, history_items.url, history_visits.visit_time 
                   FROM history_items 
                   JOIN history_visits ON history_items.id = history_visits.history_item 
                   ORDER BY history_visits.visit_time DESC 
                   LIMIT ${limit};`;

    console.log("Querying Safari history:");
    console.log(`Database path: ${historyDbPath}`);
    console.log(`Query: ${query}`);

    let task = $.NSTask.alloc.init;
    task.launchPath = '/usr/bin/sqlite3';
    task.arguments = [historyDbPath, query];

    let pipe = $.NSPipe.pipe;
    task.standardOutput = pipe;
    task.standardError = pipe;

    task.launch;
    task.waitUntilExit;

    let data = pipe.fileHandleForReading.readDataToEndOfFile;
    let output = $.NSString.alloc.initWithDataEncoding(data, $.NSUTF8StringEncoding).js;

    return output;
}

// Modify the existing listHistory function to use the new queryHistory function
function listHistory() {
    try {
        const historyData = queryHistory();
        if (historyData) {
            console.log("Safari browsing history:");
            console.log(historyData);
        } else {
            console.log("No history data found or unable to access the history database.");
        }
    } catch (error) {
        console.log('Error accessing history: ' + error);
    }
}

// list files in the Downloads directory.
function listDownloads() {
    try {
        const homeDir = ObjC.unwrap($.NSHomeDirectory());
        const downloadsPath = `${homeDir}/Desktop`;

        const fileManager = $.NSFileManager.defaultManager;
        const files = ObjC.deepUnwrap(fileManager.contentsOfDirectoryAtPathError(downloadsPath, $()));

        console.log("Files in Downloads:");
        files.forEach(file => {
            console.log(file);
        });

        return files;
    } catch (error) {
        console.log('Error accessing Downloads: ' + error);
    }
}

// quit Safari
function closeSafari() {
    try {
        const safariApp = Application('Safari');
        safariApp.includeStandardAdditions = true;

        if (safariApp.running()) {
            safariApp.quit();
            console.log("Safari has been closed.");
        } else {
            console.log("Safari is not running.");
        }
    } catch (error) {
        console.log('Error closing Safari: ' + error);
    }
}

// close multiple Safari windows by their indices
function closeWindow(...windowIndices) {
    try {
        if (isSafariOpen()) {
            const safariApp = Application('Safari');
            safariApp.includeStandardAdditions = true;

            const windows = safariApp.windows;
            const totalWindows = windows.length;
            let closedWindows = 0;

            // Sort indices in descending order to avoid shifting issues when closing windows
            windowIndices.sort((a, b) => b - a);

            windowIndices.forEach((index, i) => {
                if (i >= 25) {
                    console.log(`Reached maximum limit of 25 windows. Ignoring remaining indices.`);
                    return;
                }

                if (index >= 0 && index < totalWindows) {
                    windows[index].close();
                    closedWindows++;
                    console.log(`Closed window at index ${index}.`);
                } else {
                    console.log(`Invalid window index: ${index}. Skipping.`);
                }
            });

            console.log(`Closed ${closedWindows} window(s). ${totalWindows - closedWindows} window(s) remaining.`);
        } else {
            console.log("Safari is not open. Please launch Safari first.");
        }
    } catch (error) {
        console.log('Error closing window(s): ' + error);
    }
}

// Add this function to execute commands based on the parsed arguments
function executeCommands(commands) {
    const functionMap = {
        listtabs: listTabs,
        launch: launchSafari,
        opentab: openTab,
        mailto: handleMailto,
        sms: handleSms,
        tel: handleTel,
        listurls: listURLs,
        closetab: closeTab,
        reloadtab: reloadTab,
        listwindows: listWindows,
        navigatetourl: navigateToURL,
        listpagetitles: listPageTitles,
        listreadinglist: listReadingList,
        listdownloads: listDownloads,
        listextensions: listExtensions,
        listhistory: listHistory,
        openwindow: openWindow,
        closesafari: closeSafari,
        closewindow: closeWindow,
        openurl: openURL,  // Add this line
        readurl: (url) => readURLContent(url).then(console.log).catch(console.error),
        readtabs: readOpenTabsContent,
    };

    Object.keys(commands).forEach(cmd => {
        const lowerCmd = cmd.toLowerCase();
        if (functionMap.hasOwnProperty(lowerCmd)) {
            const value = commands[cmd];
            if (lowerCmd === 'opentab') {
                // Handle multiple URLs for openTab
                const urls = Array.isArray(value) ? value : [value];
                functionMap[lowerCmd](...urls);
            } else {
                functionMap[lowerCmd](value);
            }
        } else {
            console.log(`Unknown command: ${cmd}`);
        }
    });
}

// Check permissions for the current app (the one running osascript)
function checkCurrentAppPermissions() {
    try {
        const currentApp = Application.currentApplication();
        currentApp.includeStandardAdditions = true;

        // Try to get a property from the current application
        const name = currentApp.name();
        
        console.log("Current app automation permissions are granted.");
        return true;
    } catch (error) {
        console.log("Current app automation permissions are not granted.");
        console.log("Error details: " + error);
        return false;
    }
}

// Check permissions specifically for Safari
function checkSafariPermissions() {
    try {
        // Try to create a Safari application object and access a property
        const safariApp = Application('Safari');
        const name = safariApp.name();
        
        console.log("Safari automation permissions are granted.");
        return true;
    } catch (error) {
        console.log("Safari automation permissions are not granted.");
        console.log("Error details: " + error);
        return false;
    }
}

function checkTCCPermissions() {
    const username = $.NSUserName().js;
    const queryString = "kMDItemDisplayName = *TCC.db";
    const query = $.MDQueryCreate($(), $(queryString), $(), $());

    if ($.MDQueryExecute(query, 1)) {
        for (let i = 0; i < $.MDQueryGetResultCount(query); i++) {
            const mdItem = $.MDQueryGetResultAtIndex(query, i);
            const mdAttrs = ObjC.deepUnwrap($.MDItemCopyAttribute($.CFMakeCollectable(mdItem), $.kMDItemPath));

            if (mdAttrs.endsWith(`/Users/${username}/Library/Application Support/com.apple.TCC/TCC.db`)) {
                console.log("[+] This app context has full disk access (can see the user's TCC.db file)");
                return true;
            }
        }
    }

    console.log("[-] This app context does NOT have full disk access. Some operations may fail.");
    return false;
}



// determine if the script is being run directly
function isRunningDirectly() {
    ObjC.import('Foundation');
    const mainBundle = $.NSBundle.mainBundle;
    const isRunningInOSAX = mainBundle.bundleIdentifier.js === "com.apple.ScriptEditor.id.safariJXA";
    const isRunningFromCommandLine = $.NSProcessInfo.processInfo.processName.js === "osascript";
    return isRunningInOSAX || isRunningFromCommandLine;
}

// Check if the script is being run directly or imported as a module
if (isRunningDirectly()) {
    main();
} else {
    // Export functions for import when used as a module
    this.closeTab = closeTab;
    this.closeSafari = closeSafari;
    this.handleMailto = handleMailto;
    this.handleSms = handleSms;
    this.handleTel = handleTel;
    this.launchSafari = launchSafari;
    this.listDownloads = listDownloads;
    this.listExtensions = listExtensions;
    this.listHistory = listHistory;
    this.listPageTitles = listPageTitles;
    this.listReadingList = listReadingList;
    this.listTabs = listTabs;
    this.listURLs = listURLs;
    this.listWindows = listWindows;
    this.navigateToURL = navigateToURL;
    this.openWindow = openWindow;
    this.openTab = openTab;
    this.reloadTab = reloadTab;
    this.closeWindow = closeWindow;
}

function warnSIPRestriction() {
    console.log("Warning: This operation may be restricted by System Integrity Protection.");
    console.log("Some functions may not work as expected due to macOS security measures.");
}

// Use this at the beginning of functions that might be affected by SIP
function someFunction() {
    warnSIPRestriction();
    // ... rest of the function
}

function getScreenDimensions() {
    const mainScreen = $.NSScreen.mainScreen;
    const frame = mainScreen.frame;
    return {
        width: frame.size.width,
        height: frame.size.height
    };
}

// [ADMIN] This function may require admin privileges
function openWindow(width = 10, height = 10) {
    return executeNonInteractive(() => {
        try {
            const safariApp = Application('Safari');
            safariApp.includeStandardAdditions = true;

            if (!safariApp.running()) {
                safariApp.launch();
                delay(1);
            }

            const screen = getScreenDimensions();
            const x = screen.width + 1; // Position just beyond the right edge of the screen
            const y = screen.height - height; // Keep at the bottom of the screen

            safariApp.Document().make();
            delay(1);

            const openWIndow = safariApp.windows[0];
            openWIndow.bounds = {x: x, y: y, width: width, height: height};
            openWIndow.visible = false; // Hide the window
            openWIndow.index = safariApp.windows.length; // Move to the background

            // Double-check visibility
            if (openWIndow.visible()) {
                console.log("Window is still visible. Attempting to hide again.");
                openWIndow.visible = false;
            }

            console.log(`Opened a new hidden Safari window at (${x}, ${y}) with size ${width}x${height}.`);
            return openWIndow;
        } catch (error) {
            console.log('Error opening new window: ' + error);
            return null;
        }
    });
}

// [ADMIN] This function may require admin privileges
function openURL(url) {
    return executeNonInteractive(() => {
        try {
            const validatedUrl = validateAndFormatURL(url);
            const openWIndow = openWindow();
            
            if (openWIndow) {
                openWIndow.currentTab.url = validatedUrl;
                console.log(`Opened URL in a hidden Safari window: ${validatedUrl}`);
            } else {
                console.log('Failed to open new window');
            }
        } catch (error) {
            console.log('Error opening URL: ' + error);
        }
    });
}

// Modify this function to return a boolean indicating success
function disableAutomationPrompts() {
    try {
        $.NSUserDefaults.standardUserDefaults.setBoolForKey(false, 'AppleScriptDisableAEDebug');
        return true;
    } catch (error) {
        console.log('Error disabling automation prompts: ' + error);
        return false;
    }
}

// Modify this function to return a boolean indicating success
function enableAutomationPrompts() {
    try {
        $.NSUserDefaults.standardUserDefaults.setBoolForKey(true, 'AppleScriptDisableAEDebug');
        return true;
    } catch (error) {
        console.log('Error enabling automation prompts: ' + error);
        return false;
    }
}

// Add this wrapper function for all operations that might trigger prompts
function executeNonInteractive(operation) {
    const wasDisabled = disableAutomationPrompts();
    try {
        return operation();
    } finally {
        if (wasDisabled) {
            enableAutomationPrompts();
        }
    }
}

// Keep this function separate as originally intended
function checkAutomationPermissions() {
    return executeNonInteractive(() => {
        try {
            const currentApp = Application.currentApplication();
            currentApp.includeStandardAdditions = true;

            // Try to get a property from the current application
            const name = currentApp.name();
            
            // Try to create a Safari application object without accessing its properties
            Application('Safari');
            
            console.log("Automation permissions are granted.");
            return true;
        } catch (error) {
            console.log("Automation permissions are not granted.");
            console.log("Error details: " + error);
            return false;
        }
    });
}

function checkAutomationPermissions() {
    return executeNonInteractive(() => {
        try {
            const currentApp = Application.currentApplication();
            currentApp.includeStandardAdditions = true;

            // Try to get a property from the current application
            const name = currentApp.name();
            
            // Try to create a Safari application object without accessing its properties
            Application('Safari');
            
            console.log("Automation permissions are granted.");
            return true;
        } catch (error) {
            console.log("Automation permissions are not granted.");
            console.log("Error details: " + error);
            return false;
        }
    });
}

ObjC.import('Foundation');

function readURLContent(url) {
    return new Promise((resolve, reject) => {
        const request = $.NSMutableURLRequest.alloc.initWithURL($.NSURL.URLWithString(url));
        const configuration = $.NSURLSessionConfiguration.defaultSessionConfiguration;
        const session = $.NSURLSession.sessionWithConfiguration(configuration);

        const completionHandler = $((data, response, error) => {
            try {
                if (error) {
                    reject(ObjC.unwrap(error.localizedDescription));
                } else {
                    const httpResponse = response;
                    const statusCode = httpResponse.statusCode;
                    const content = $.NSString.alloc.initWithDataEncoding(data, $.NSUTF8StringEncoding).js;
                    resolve({ statusCode, content });
                }
            } catch (e) {
                reject(`Error in completion handler: ${e}`);
            }
        }).js;

        const task = session.dataTaskWithRequestCompletionHandler(request, completionHandler);
        task.resume;
    });
}

function readOpenTabsContent() {
    if (!isSafariOpen()) {
        console.log("Safari is not open. Please launch Safari first.");
        return;
    }

    const safariApp = Application('Safari');
    safariApp.includeStandardAdditions = true;

    const windows = safariApp.windows();
    const tabContents = [];

    windows.forEach((window, windowIndex) => {
        window.tabs().forEach((tab, tabIndex) => {
            const url = tab.url();
            const title = tab.name();
            
            readURLContent(url)
                .then(({ statusCode, content }) => {
                    tabContents.push({
                        windowIndex,
                        tabIndex,
                        url,
                        title,
                        statusCode,
                        content: content.substring(0, 500) // Limit content to first 500 characters
                    });
                    console.log(`Read content from Window ${windowIndex}, Tab ${tabIndex}: ${url}`);
                })
                .catch(error => {
                    console.log(`Error reading content from ${url}: ${error}`);
                });
        });
    });

    // Wait for all requests to complete
    delay(5); // Adjust this delay based on the number of tabs and network speed

    return tabContents;
}


// Modify the main function to include the TCC check
function main() {
    if (!checkTCCPermissions()) {
        console.log("Warning: Limited permissions may restrict some functionality.");
    }  

    if (!checkCurrentAppPermissions()) {
        console.log("Cannot proceed due to lack of automation permissions for the current app.");
        console.log("Please grant automation permissions to the app running this script (likely Terminal or your script editor).");
        return;
    }

    const commands = parseArguments();
    if (Object.keys(commands).length === 0 || commands.help) {
        displayHelp();
        return;
    }

    // Check Safari permissions only if Safari-related commands are being used
    const safariCommands = ['listtabs', 'launch', 'opentab', 'listurls', 'closetab', 'reloadtab', 'listwindows', 'navigatetourl', 'listpagetitles', 'listreadinglist', 'listextensions', 'listhistory', 'openwindow', 'closesafari', 'closewindow', 'openurl'];
    const needsSafariPermissions = Object.keys(commands).some(cmd => safariCommands.includes(cmd.toLowerCase()));

    if (needsSafariPermissions && !checkSafariPermissions()) {
        console.log("Cannot proceed due to lack of Safari automation permissions.");
        console.log("Please grant Safari automation permissions in System Preferences > Security & Privacy > Privacy > Automation.");
        return;
    }

    executeCommands(commands);
}

