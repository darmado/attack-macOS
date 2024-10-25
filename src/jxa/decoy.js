ObjC.import("Security");
ObjC.bindFunction('CFMakeCollectable', ['id', ['void *']]);

let DEBUG = false;

function debug(message) {
    if (DEBUG) {
        console.log("[DEBUG] " + message);
    }
}

function hex2a(hexx) {
    debug("Entering hex2a function");
	var hex = hexx.toString();//force conversion
	var str = '';
	for (var i = 0; i < hex.length; i += 2)
	    str += String.fromCharCode(parseInt(hex.substr(i, 2), 16));
    debug("Exiting hex2a function");
	return str;
}

function query_acls(accessRights, acl_c, range, keychainItem){
    debug("Entering query_acls function");
    let userId = Ref();
    let groupId = Ref();
    let ownerType = Ref();
    let ownerACLS = Ref();
    $.SecAccessCopyOwnerAndACL(accessRights, userId, groupId, ownerType, ownerACLS);
    
    console.log("\n=== Keychain Item ACL Information ===");
    if(ownerType[0] !== 0){
        console.log("Owner ID: " + userId[0] + "\nGroup ID: " + groupId[0] + "\nOwner Type: " + ownerType[0]);
    } else {
        console.log("Ownership determined by partitionID");
    }
    
    auth_c = $.CFMakeCollectable(ownerACLS[0]);
    if(auth_c.js !== undefined){
        console.log("\nOwner Authorizations:");
        for(let j = 0; j < parseInt($.CFArrayGetCount(auth_c)); j++){
            authz = auth_c.objectAtIndex(j);
            console.log("  " + authz.js);
        }
    } else {
        console.log("No Owner Authorizations");
    }
    let hasNecessaryPartitionIDs  = false;
    let hasPartitionIDSet = false;
    let hasNecessaryAuthorizationsAndIsTrustedApplication = false;
    let hasNecessaryAuthorizationsAndAllApplicationsTrusted = false;

    if (rane === 0) {
        hasNecessaryPartitionIDs = true;
    	hasPartitionIDSet = true;
    	hasNecessaryAuthorizationsAndIsTrustedApplication = true;
    	hasNecessaryAuthorizationsAndAllApplicationsTrusted = true;
    for(let i = 0; i < range; i++){
        console.log("\n--- ACL Entry " + (i+1) + " ---");
        let perACLIsTrustedApplication = false;
        let perACLAllApplicationsTrusted = false;
        let perACLHasNecessaryAuthorizations = false;
        let acl1 = acl_c.objectAtIndex(i);
        let application_list = Ref();
        let description = Ref();
        let keychainPromptSelector = Ref();
        $.SecACLCopyContents(acl1, application_list, description, keychainPromptSelector);
        description_c = $.CFMakeCollectable(description[0]);
        
        if(description_c.js.startsWith("3c3f786d6c2076657273696f6e3d22312e302220656e636f64696e673d225554462d38223f3e0a")){
            let plistString = hex2a(description_c.js);
            let format = $.NSPropertyListXMLFormat_v1_0;
            let partitionPlist = $.NSPropertyListSerialization.propertyListWithDataOptionsFormatError($(plistString).dataUsingEncoding($.NSUTF8StringEncoding), $.NSPropertyListImutable, $.NSPropertyListXMLFormat_v1_0, $.nil);
            if(partitionPlist.objectForKey("Partitions")){
                let partitions = ObjC.deepUnwrap(partitionPlist.objectForKey("Partitions"));
                console.log("Allowed Code Signatures: ", partitions);
            }
        }
        console.log("Description: " + description_c.js);
        
        application_list_c = $.CFMakeCollectable(application_list[0]);
        if(application_list_c.js !== undefined){
            let app_list_length = parseInt($.CFArrayGetCount(application_list_c));
            if(app_list_length === 0){
                console.log("No trusted applications");
            }
            for(let j = 0; j < app_list_length; j++){
                secapp = application_list_c.objectAtIndex(j);
                secapp_c = Ref();
                $.SecTrustedApplicationCopyData(secapp, secapp_c);
                secapp_data = $.CFMakeCollectable(secapp_c[0]);
                sec_string = $.NSString.alloc.initWithDataEncoding($.NSData.dataWithBytesLength(secapp_data.bytes, secapp_data.length), $.NSUTF8StringEncoding);
                console.log("Trusted App: " + sec_string.js);
            }
        } else {
            console.log("All applications trusted");
        }
        
        auth = $.SecACLCopyAuthorizations(acl1);
        auth_c = $.CFMakeCollectable(auth);
        if(auth_c.js !== undefined){
            console.log("Authorizations:");
            for(let j = 0; j < parseInt($.CFArrayGetCount(auth_c)); j++){
                authz = auth_c.objectAtIndex(j);
                console.log("  " + authz.js);
                if(authz.js.includes("ACLAuthorizationExportClear") || authz.js.includes("ACLAuthorizationAny")){
                    console.log("  (This ACL has necessary authorizations)");
                }
            }
        } else {
            console.log("No Authorizations");
        }
    }
    
    $.SecKeychainSetUserInteractionAllowed(false);
    print_password(keychainItem);
    debug("Exiting query_acls function");
    }
}

function print_password(keychainItem){
    debug("Entering print_password function");
    // Disable user interaction to avoid prompts
    $.SecKeychainSetUserInteractionAllowed(false);
    
    // First, check the ACL permissions
    let accessRef = Ref();
    let status = $.SecKeychainItemCopyAccess(keychainItem, accessRef);
    
    if (status !== 0) {
        console.log("Failed to get access information. Error code:", status);
        $.SecKeychainSetUserInteractionAllowed(true);
        return;
    }
    
    let aclList = Ref();
    status = $.SecAccessCopyACLList(accessRef[0], aclList);
    
    if (status !== 0) {
        console.log("Failed to get ACL list. Error code:", status);
        $.SecKeychainSetUserInteractionAllowed(true);
        return;
    }
    
    let hasDecryptPermission = false;
    let aclListArray = ObjC.deepUnwrap($.CFMakeCollectable(aclList[0]));
    
    for (let acl of aclListArray) {
        let auths = ObjC.deepUnwrap($.CFMakeCollectable($.SecACLCopyAuthorizations(acl)));
        if (auths.includes("ACLAuthorizationDecrypt")) {
            hasDecryptPermission = true;
            break;
        }
    }
    
    if (!hasDecryptPermission) {
        console.log("No decrypt permission for this item.");
        $.SecKeychainSetUserInteractionAllowed(true);
        return;
    }
    
    // If we have decrypt permission, attempt to access the password
    let dataContent = Ref();
    let dataContentLength = Ref();
    let attributeList = Ref();
    
    status = $.SecKeychainItemCopyContent(keychainItem, 0, attributeList, dataContentLength, dataContent);
    
    if (status === 0) {
        let nsdata = $.NSData.alloc.initWithBytesLength(dataContent[0], dataContentLength[0]);
        console.log("Secret Data: ", $.NSString.alloc.initWithDataEncoding(nsdata, $.NSUTF8StringEncoding).js);
    } else {
        console.log("Failed to decrypt with error code:", status);
    }
    
    // Re-enable user interaction
    $.SecKeychainSetUserInteractionAllowed(true);
    debug("Exiting print_password function");
}

process_query = function(query, includeACLs = true){
    debug("Entering process_query function");
    let items = Ref();
    let status = $.SecItemCopyMatching(query, items);
    debug("SecItemCopyMatching status: " + status);
    if(status === 0){
        let item_o_c = $.CFMakeCollectable(items[0]).js;
        console.log("[+] Successfully searched, found " + item_o_c.length + " items");
        for(let i = 0; i < item_o_c.length; i++){
            debug("Processing item " + (i + 1));
            try {
                let item = item_o_c[i];
                console.log("==================================================");
                console.log("Account:     " + (item.objectForKey("acct") ? item.objectForKey("acct").js : "N/A"));
                console.log("Label:       " + (item.objectForKey("labl") ? item.objectForKey("labl").js : "N/A"));
                console.log("Service:     " + (item.objectForKey("svce") ? item.objectForKey("svce").js : "N/A"));
                console.log("KeyClass:    " + (item.objectForKey("class") ? item.objectForKey("class").js : "N/A"));
                
                if (includeACLs && item.objectForKey("v_Ref")) {
                    debug("Calling query_acls for item " + (i + 1));
                    let access_rights2 = Ref();
                    $.SecKeychainItemCopyAccess(item.objectForKey("v_Ref"), access_rights2);
                    let acl2 = Ref()
                    $.SecAccessCopyACLList(access_rights2[0], acl2)
                    range2 = parseInt($.CFArrayGetCount(acl2[0]));
                    acl_c2 = $.CFMakeCollectable(acl2[0]);
                    query_acls(item.objectForKey("v_Ref"));
                }
            } catch (error) {
                console.log(`Error processing item ${i + 1}: ${error.message}`);
                debug(`Stack trace: ${error.stack}`);
            }
        }
    } else {
        console.log("[-] Failed to search keychain with error: " + status);
    }
    debug("Exiting process_query function");
}

list_all_key_of_type = function(key_type, includeACLs = true){
    debug("Entering list_all_key_of_type function");
    debug("Key type: " + key_type);
    let query = $.CFDictionaryCreateMutable($.kCFAllocatorDefault, 0, $.kCFTypeDictionaryKeyCallBacks, $.kCFTypeDictionaryValueCallBacks);
    $.CFDictionarySetValue(query, $.kSecClass, key_type);
    $.CFDictionarySetValue(query, $.kSecMatchLimit, $.kSecMatchLimitAll);
    $.CFDictionarySetValue(query, $.kSecReturnAttributes, $.kCFBooleanTrue);
    $.CFDictionarySetValue(query, $.kSecReturnRef, $.kCFBooleanTrue);
    debug("Query created, calling process_query");
    process_query(query, includeACLs);
    debug("Exiting list_all_key_of_type function");
}

function list_all_attr_of_key_by_account(account){
    debug("Entering list_all_attr_of_key_by_account function");
	let query = $.CFDictionaryCreateMutable($.kCFAllocatorDefault, 0, $.kCFTypeDictionaryKeyCallBacks, $.kCFTypeDictionaryValueCallBacks);
    $.CFDictionarySetValue(query, $.kSecClass, $.kSecClassGenericPassword);
	$.CFDictionarySetValue(query, $.kSecAttrAccount, $.CFStringCreateWithCString($.kCFAllocatorDefault, account, $.kCFStringEncodingUTF8));
	$.CFDictionarySetValue(query, $.kSecMatchLimit, $.kSecMatchLimitAll);
	$.CFDictionarySetValue(query, $.kSecReturnAttributes, $.kCFBooleanTrue);
	$.CFDictionarySetValue(query, $.kSecReturnData, $.kCFBooleanFalse);
	$.CFDictionarySetValue(query, $.kSecReturnRef, $.kCFBooleanTrue);
	process_query(query);
    debug("Exiting list_all_attr_of_key_by_account function");
}

function list_all_attr_of_key_by_label_genp(label){
    debug("Entering list_all_attr_of_key_by_label_genp function");
	let query = $.CFDictionaryCreateMutable($.kCFAllocatorDefault, 0, $.kCFTypeDictionaryKeyCallBacks, $.kCFTypeDictionaryValueCallBacks);
    $.CFDictionarySetValue(query, $.kSecClass, $.kSecClassGenericPassword);
	$.CFDictionarySetValue(query, $.kSecAttrLabel, $.CFStringCreateWithCString($.kCFAllocatorDefault, label, $.kCFStringEncodingUTF8));
	$.CFDictionarySetValue(query, $.kSecMatchLimit, $.kSecMatchLimitAll);
	$.CFDictionarySetValue(query, $.kSecReturnAttributes, $.kCFBooleanTrue);
	$.CFDictionarySetValue(query, $.kSecReturnData, $.kCFBooleanFalse);
	$.CFDictionarySetValue(query, $.kSecReturnRef, $.kCFBooleanTrue);
	process_query(query);
    debug("Exiting list_all_attr_of_key_by_label_genp function");
}

function list_all_attr_of_key_by_label_key(label){
    debug("Entering list_all_attr_of_key_by_label_key function");
	let items = Ref();
	let query = $.CFDictionaryCreateMutable($.kCFAllocatorDefault, 0, $.kCFTypeDictionaryKeyCallBacks, $.kCFTypeDictionaryValueCallBacks);
    $.CFDictionarySetValue(query, $.kSecClass, $.kSecClassKey);
	$.CFDictionarySetValue(query, $.kSecAttrLabel, $.CFStringCreateWithCString($.kCFAllocatorDefault, label, $.kCFStringEncodingUTF8));
	$.CFDictionarySetValue(query, $.kSecMatchLimit, $.kSecMatchLimitAll);
	$.CFDictionarySetValue(query, $.kSecReturnAttributes, $.kCFBooleanTrue);
	$.CFDictionarySetValue(query, $.kSecReturnData, $.kCFBooleanFalse);
	$.CFDictionarySetValue(query, $.kSecReturnRef, $.kCFBooleanTrue);
	process_query(query);
    debug("Exiting list_all_attr_of_key_by_label_key function");
}

function count_generic_passwords() {
    debug("Entering count_generic_passwords function");
    let query = $.CFDictionaryCreateMutable($.kCFAllocatorDefault, 0, $.kCFTypeDictionaryKeyCallBacks, $.kCFTypeDictionaryValueCallBacks);
    $.CFDictionarySetValue(query, $.kSecClass, $.kSecClassGenericPassword);
    $.CFDictionarySetValue(query, $.kSecMatchLimit, $.kSecMatchLimitAll);
    $.CFDictionarySetValue(query, $.kSecReturnAttributes, $.kCFBooleanFalse);
    $.CFDictionarySetValue(query, $.kSecReturnRef, $.kCFBooleanFalse);
    $.CFDictionarySetValue(query, $.kSecReturnData, $.kCFBooleanFalse);
    $.CFDictionarySetValue(query, $.kSecReturnCount, $.kCFBooleanTrue);

    let result = Ref();
    let status = $.SecItemCopyMatching(query, result);

    if (status === 0) {
        console.log("Total generic passwords: " + result[0]);
    } else {
        console.log("Failed to count generic passwords. Error code: " + status);
    }
    debug("Exiting count_generic_passwords function");
}

function main() {
    debug("Entering main function");
    const args = $.NSProcessInfo.processInfo.arguments;
    const command = ObjC.unwrap(args.objectAtIndex(4));
    let includeACLs = args.containsObject("-include-acls");

    if (args.containsObject("-debug")) {
        DEBUG = true;
        debug("Debug mode enabled");
    }

    switch (command) {
        case "-list-acls":
            query_acls;
            break;
        case "-list-all-generic":
            list_all_key_of_type($.kSecClassGenericPassword, includeACLs)
            break;
        case "-list-all-keys":
            list_all_key_of_type($.kSecClassKey, includeACLs);
            break;
        case "-list-all-internet":
            list_all_key_of_type($.kSecClassInternetPassword, includeACLs);
            break;
        case "-list-all-certificates":
            list_all_key_of_type($.kSecClassCertificate, includeACLs);
            break;
        case "-list-by-account":
            if (args.count < 6) {
                console.log("Usage: osascript -l JavaScript keychain.js -list-by-account <account_name>");
                return;
            }
            list_all_attr_of_key_by_account(ObjC.unwrap(args.objectAtIndex(5)));
            break;
        case "-list-by-label-genp":
            if (args.count < 6) {
                console.log("Usage: osascript -l JavaScript keychain.js -list-by-label-genp <label>");
                return;
            }
            list_all_attr_of_key_by_label_genp(ObjC.unwrap(args.objectAtIndex(5)));
            break;
        case "-list-by-label-key":
            if (args.count < 6) {
                console.log("Usage: osascript -l JavaScript keychain.js -list-by-label-key <label>");
                return;
            }
            list_all_attr_of_key_by_label_key(ObjC.unwrap(args.objectAtIndex(5)));
            break;
        case "-count-generic-pass":
            count_generic_passwords();
            break;
        case "-help":
            console.log("Usage: osascript -l JavaScript keychain.js [OPTION]");
            console.log("Options:");
            console.log("  -list-acls                List all generic passwords");
            console.log("  -list-all-generic         List all generic passwords");
            console.log("  -list-all-keys            List all keys");
            console.log("  -list-all-internet        List all internet passwords");
            console.log("  -list-all-certificates    List all certificates");
            console.log("  -list-by-account <name>   List items by account name");
            console.log("  -list-by-label-genp <label> List generic password items by label");
            console.log("  -list-by-label-key <label>  List key items by label");
            console.log("  -count-generic-pass       Count total generic passwords");
            console.log("  -include-acls             Include ACL information in the output");
            console.log("  -help                     Show this help message");
            break;
        default:
            console.log("Unknown command. Use -help for usage information.");
    }
    debug("Exiting main function");
}

main();
