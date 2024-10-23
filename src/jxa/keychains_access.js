ObjC.import("Security");

function run(args) {
    $.SecKeychainSetUserInteractionAllowed(false);

    if (args.length === 0 || args.includes('-help')) {
        displayHelp();
        return;
    }

    if (args.includes('-list-internetpasswords')) {
        listInternetPasswords();
    } else {
        console.log("Error: No valid command provided. Use -help for usage information.");
    }
}

function displayHelp() {
    console.log("Usage: osascript -l JavaScript keychains_access.js [OPTIONS]");
    console.log("Options:");
    console.log("  -help                    Show this help message");
    console.log("  -list-internetpasswords  List all internet passwords from the keychain");
}

function listInternetPasswords() {
    let query = $.CFDictionaryCreateMutable($.kCFAllocatorDefault, 0, $.kCFTypeDictionaryKeyCallBacks, $.kCFTypeDictionaryValueCallBacks);
    $.CFDictionarySetValue(query, $.kSecClass, $.kSecClassInternetPassword);
    $.CFDictionarySetValue(query, $.kSecReturnAttributes, $.kCFBooleanTrue);
    $.CFDictionarySetValue(query, $.kSecReturnData, $.kCFBooleanTrue);
    $.CFDictionarySetValue(query, $.kSecMatchLimit, $.kSecMatchLimitAll);

    let result = Ref();
    let resultCode = $.SecItemCopyMatching(query, result);

    if (resultCode === 0) {
        let items = ObjC.deepUnwrap($.CFMakeCollectable(result[0]));
        console.log(`Found ${items.length} internet password(s)`);
        items.forEach((item, index) => {
            console.log(`\nItem ${index + 1}:`);
            console.log(`  Account: ${item.acct || 'N/A'}`);
            console.log(`  Server: ${item.srvr || 'N/A'}`);
            console.log(`  Protocol: ${item.ptcl || 'N/A'}`);
            if (item.v_Data) {
                let password = $.NSString.alloc.initWithDataEncoding(item.v_Data, $.NSUTF8StringEncoding);
                console.log(`  Password: ${password.js}`);
            } else {
                console.log(`  Password: Unable to retrieve`);
            }
        });
    } else {
        console.log(`Error accessing internet passwords: ${resultCode}`);
    }
}

function main() {
    run($.ARGV);
}

main();
