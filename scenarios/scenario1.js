ObjC.import("Security");
ObjC.bindFunction('CFMakeCollectable', ['id', ['void *'] ]);

function hex2a(hexx) {
	var hex = hexx.toString();//force conversion
	var str = '';
	for (var i = 0; i < hex.length; i += 2)
	    str += String.fromCharCode(parseInt(hex.substr(i, 2), 16));
	return str;
}

print_acls = function(accessRights, acl_c, range, keychainItem){
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
    
    for(let i = 0; i < range; i++){
        console.log("\n--- ACL Entry " + (i+1) + " ---");
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
}
print_password = function(keychainItem){
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
}
process_query = function(query){
	let items = Ref();
	let status = $.SecItemCopyMatching(query, items);
	if(status === 0){
		let item_o_c = $.CFMakeCollectable(items[0]).js;
		console.log("[+] Successfully searched, found " + item_o_c.length + " items")
		for(let i = 0; i < item_o_c.length; i++){
			let item = item_o_c[i];
			//$.CFShow(item);
			console.log("==================================================");
			console.log("Account:     " + item.objectForKey("acct").js);
			console.log("Create Date: " + item.objectForKey("cdat").js);
			//console.log(item.objectForKey("gena").js);
			console.log("Label:       " + item.objectForKey("labl").js);
			console.log("Modify Date: " + item.objectForKey("mdat").js);
			console.log("Service:     " + item.objectForKey("svce").js);
			console.log("KeyClass:    " + item.objectForKey("class").js);
			if( item.objectForKey("gena").js !== undefined){
				console.log("General:     " + item.objectForKey("gena").base64EncodedStringWithOptions(0).js);
			}

			let access_rights2 = Ref();
			$.SecKeychainItemCopyAccess(item.objectForKey("v_Ref"), access_rights2);
			let acl2 = Ref()
			$.SecAccessCopyACLList(access_rights2[0], acl2)
			range2 = parseInt($.CFArrayGetCount(acl2[0]));
			acl_c2 = $.CFMakeCollectable(acl2[0]);
			print_acls(access_rights2[0], acl_c2, range2, item.objectForKey("v_Ref"));
			// we can get the data and try to decrypt below
			//let dataContent = Ref();
			//let dataContentLength = Ref();
			//let attributeList = Ref();
			//status = $.SecKeychainItemCopyContent(item_o_c, 0, attributeList, dataContentLength, dataContent);
			//console.log(status);
			//console.log(dataContentLength[0]);
			//let nsdata = $.NSData.alloc.initWithBytesLength(dataContent[0], dataContentLength[0]);
			//console.log(nsdata.base64EncodedStringWithOptions(0).js);
		}
		
	}else{
		console.log("[-] Failed to search keychain with error: " + status);
	}
}
list_all_key_of_type = function(key_type){
	let items = Ref();
	let query = $.CFDictionaryCreateMutable($.kCFAllocatorDefault, 0, $.kCFTypeDictionaryKeyCallBacks, $.kCFTypeDictionaryValueCallBacks);
    $.CFDictionarySetValue(query, $.kSecClass, key_type);
	$.CFDictionarySetValue(query, $.kSecMatchLimit, $.kSecMatchLimitAll);
	$.CFDictionarySetValue(query, $.kSecReturnAttributes, $.kCFBooleanTrue);
	$.CFDictionarySetValue(query, $.kSecReturnRef, $.kCFBooleanTrue);
	//$.CFDictionarySetValue(query, $.kSecReturnData, $.kCFBooleanTrue);
	process_query(query);
}
list_all_attr_of_key_by_account = function(account){
	let query = $.CFDictionaryCreateMutable($.kCFAllocatorDefault, 0, $.kCFTypeDictionaryKeyCallBacks, $.kCFTypeDictionaryValueCallBacks);
    $.CFDictionarySetValue(query, $.kSecClass, $.kSecClassGenericPassword);
	$.CFDictionarySetValue(query, $.kSecAttrAccount, $.CFStringCreateWithCString($.kCFAllocatorDefault, account, $.kCFStringEncodingUTF8));
	$.CFDictionarySetValue(query, $.kSecMatchLimit, $.kSecMatchLimitAll);
	$.CFDictionarySetValue(query, $.kSecReturnAttributes, $.kCFBooleanTrue);
	$.CFDictionarySetValue(query, $.kSecReturnData, $.kCFBooleanFalse);
	$.CFDictionarySetValue(query, $.kSecReturnRef, $.kCFBooleanTrue);
	process_query(query);
}
list_all_attr_of_key_by_label_genp = function(label){
	let query = $.CFDictionaryCreateMutable($.kCFAllocatorDefault, 0, $.kCFTypeDictionaryKeyCallBacks, $.kCFTypeDictionaryValueCallBacks);
    $.CFDictionarySetValue(query, $.kSecClass, $.kSecClassGenericPassword);
	$.CFDictionarySetValue(query, $.kSecAttrLabel, $.CFStringCreateWithCString($.kCFAllocatorDefault, label, $.kCFStringEncodingUTF8));
	$.CFDictionarySetValue(query, $.kSecMatchLimit, $.kSecMatchLimitAll);
	$.CFDictionarySetValue(query, $.kSecReturnAttributes, $.kCFBooleanTrue);
	$.CFDictionarySetValue(query, $.kSecReturnData, $.kCFBooleanFalse);
	$.CFDictionarySetValue(query, $.kSecReturnRef, $.kCFBooleanTrue);
	process_query(query);
}
list_all_attr_of_key_by_label_key = function(label){
	let items = Ref();
	let query = $.CFDictionaryCreateMutable($.kCFAllocatorDefault, 0, $.kCFTypeDictionaryKeyCallBacks, $.kCFTypeDictionaryValueCallBacks);
    $.CFDictionarySetValue(query, $.kSecClass, $.kSecClassKey);
	$.CFDictionarySetValue(query, $.kSecAttrLabel, $.CFStringCreateWithCString($.kCFAllocatorDefault, label, $.kCFStringEncodingUTF8));
	$.CFDictionarySetValue(query, $.kSecMatchLimit, $.kSecMatchLimitAll);
	$.CFDictionarySetValue(query, $.kSecReturnAttributes, $.kCFBooleanTrue);
	$.CFDictionarySetValue(query, $.kSecReturnData, $.kCFBooleanFalse);
	$.CFDictionarySetValue(query, $.kSecReturnRef, $.kCFBooleanTrue);
	process_query(query);
}
//list_all_key_of_type($.kSecClassGenericPassword);
//list_all_key_of_type($.kSecClassKey);
//list_all_key_of_type($.kSecClassInternetPassword);
//list_all_key_of_type($.kSecClassCertificate);
//list_all_attr_of_key_by_account("test account");

function main() {
    const args = parseArguments();
    
    if (Object.keys(args).length === 0 || args.help) {
        displayHelp();
        return;
    }

    $.SecKeychainSetUserInteractionAllowed(false);

    if (args.scenario) {
        practicalScenario();
    } else if (args.listtypes) {
        listKeychainTypes();
    } else if (args.listaccounts) {
        listAccounts();
    } else if (args.listlabels) {
        listLabels();
    } else if (args.listallkeys) {
        list_all_key_of_type(args.listallkeys);
    } else if (args.listbyaccount) {
        list_all_attr_of_key_by_account(args.listbyaccount);
    } else if (args.listbylabel) {
        list_all_attr_of_key_by_label_genp(args.listbylabel);
    } else if (args.listbylabelkey) {
        list_all_attr_of_key_by_label_key(args.listbylabelkey);
    } else {
        console.log("Error: No valid command provided. Use -help for usage information.");
    }
}

function displayHelp() {
    console.log("Usage: osascript -l JavaScript keychains_access.js [OPTIONS]");
    console.log("Options:");
    console.log("  -help                        Show this help message");
    console.log("  -scenario                    Run a practical scenario");
    console.log("  -listtypes                   List keychain types");
    console.log("  -listaccounts                List all accounts");
    console.log("  -listlabels                  List all labels");
    console.log("  -listallkeys                 List all keychain items");
    console.log("  -listbyaccount -account ACCT List items by account");
    console.log("  -listbylabel -label LBL      List items by label (generic password)");
    console.log("  -listbylabelkey -label LBL   List items by label (key)");
}

function parseArguments() {
    const args = $.NSProcessInfo.processInfo.arguments;
    const parsedArgs = {};
    for (let i = 4; i < args.count; i++) {
        const arg = ObjC.unwrap(args.objectAtIndex(i));
        if (arg.startsWith("-")) {
            const key = arg.substring(1);
            if (i + 1 < args.count && !args.objectAtIndex(i + 1).startsWith("-")) {
                parsedArgs[key] = ObjC.unwrap(args.objectAtIndex(i + 1));
                i++;
            } else {
                parsedArgs[key] = true;
            }
        }
    }
    return parsedArgs;
}

function practicalScenario() {
    console.log("Starting practical scenario...");

    // 1. List all keychain types
    console.log("\n1. Listing all keychain types:");
    listKeychainTypes();

    // 2. List all generic passwords
    console.log("\n2. Listing all generic passwords:");
    let genericPasswords = findGenericPassword();
    
    if (genericPasswords.length === 0) {
        console.log("No generic passwords found. Exiting scenario.");
        return;
    }

    // 3. Find a specific generic password (let's say the first one)
    console.log("\n3. Finding a specific generic password:");
    let targetPassword = genericPasswords[0];
    console.log(`Target password: Account: ${targetPassword.acct}, Service: ${targetPassword.svce}`);

    // 4. Attempt to decrypt the found password
    console.log("\n4. Attempting to decrypt the found password:");
    attemptDecrypt(targetPassword.v_Ref);
}

function listKeychainTypes() {
    console.log("Available keychain types:");
    console.log("  $.kSecClassGenericPassword");
    console.log("  $.kSecClassInternetPassword");
    console.log("  $.kSecClassCertificate");
    console.log("  $.kSecClassKey");
    console.log("  $.kSecClassIdentity");
}

function listAccounts() {
    let query = $.CFDictionaryCreateMutable($.kCFAllocatorDefault, 0, $.kCFTypeDictionaryKeyCallBacks, $.kCFTypeDictionaryValueCallBacks);
    $.CFDictionarySetValue(query, $.kSecClass, $.kSecClassGenericPassword);
    $.CFDictionarySetValue(query, $.kSecReturnAttributes, $.kCFBooleanTrue);
    $.CFDictionarySetValue(query, $.kSecMatchLimit, $.kSecMatchLimitAll);

    let result = Ref();
    let resultCode = $.SecItemCopyMatching(query, result);

    if (resultCode === 0) {
        let items = ObjC.deepUnwrap($.CFMakeCollectable(result[0]));
        console.log("Available accounts:");
        items.forEach(item => {
            if (item.acct) {
                console.log("  " + item.acct);
            }
        });
    } else {
        console.log("Error accessing keychain: " + resultCode);
    }
}

function listLabels() {
    let query = $.CFDictionaryCreateMutable($.kCFAllocatorDefault, 0, $.kCFTypeDictionaryKeyCallBacks, $.kCFTypeDictionaryValueCallBacks);
    $.CFDictionarySetValue(query, $.kSecClass, $.kSecClassGenericPassword);
    $.CFDictionarySetValue(query, $.kSecReturnAttributes, $.kCFBooleanTrue);
    $.CFDictionarySetValue(query, $.kSecMatchLimit, $.kSecMatchLimitAll);

    let result = Ref();
    let resultCode = $.SecItemCopyMatching(query, result);

    if (resultCode === 0) {
        let items = ObjC.deepUnwrap($.CFMakeCollectable(result[0]));
        console.log("Available labels:");
        items.forEach(item => {
            if (item.labl) {
                console.log("  " + item.labl);
            }
        });
    } else {
        console.log("Error accessing keychain: " + resultCode);
    }
}

function findGenericPassword() {
    let query = $.CFDictionaryCreateMutable($.kCFAllocatorDefault, 0, $.kCFTypeDictionaryKeyCallBacks, $.kCFTypeDictionaryValueCallBacks);
    $.CFDictionarySetValue(query, $.kSecClass, $.kSecClassGenericPassword);
    $.CFDictionarySetValue(query, $.kSecReturnAttributes, $.kCFBooleanTrue);
    $.CFDictionarySetValue(query, $.kSecReturnRef, $.kCFBooleanTrue);
    $.CFDictionarySetValue(query, $.kSecMatchLimit, $.kSecMatchLimitAll);

    let result = Ref();
    let resultCode = $.SecItemCopyMatching(query, result);

    if (resultCode === 0) {
        let items = ObjC.deepUnwrap($.CFMakeCollectable(result[0]));
        console.log(`[+] Successfully found ${items.length} generic password item(s)`);
        items.forEach((item, index) => {
            console.log(`\n==== Generic Password Item ${index + 1} ====`);
            console.log(`Account:     ${item.acct || 'N/A'}`);
            console.log(`Service:     ${item.svce || 'N/A'}`);
            console.log(`Create Date: ${item.cdat || 'N/A'}`);
            console.log(`Modify Date: ${item.mdat || 'N/A'}`);
            console.log(`Description: ${item.desc || 'N/A'}`);
            console.log(`Label:       ${item.labl || 'N/A'}`);
            console.log(`Comment:     ${item.icmt || 'N/A'}`);
            console.log(`Creator:     ${item.crtr || 'N/A'}`);
            console.log(`Type:        ${item.type || 'N/A'}`);
            console.log(`Invisible:   ${item.invi ? 'Yes' : 'No'}`);
            console.log(`Negative:    ${item.nega ? 'Yes' : 'No'}`);
            console.log(`Custom Icon: ${item.cusi ? 'Yes' : 'No'}`);
            console.log(`Protected:   ${item.prot ? 'Yes' : 'No'}`);

            printACLs(item.v_Ref);
        });
        return items;
    } else {
        console.log(`[-] Failed to search keychain with error: ${resultCode}`);
        return [];
    }
}

function printACLs(keychainItemRef) {
    let accessRef = Ref();
    let status = $.SecKeychainItemCopyAccess(keychainItemRef, accessRef);
    
    if (status !== 0) {
        console.log(`Failed to get access information. Error code: ${status}`);
        return;
    }
    
    let aclList = Ref();
    status = $.SecAccessCopyACLList(accessRef[0], aclList);
    
    if (status !== 0) {
        console.log(`Failed to get ACL list. Error code: ${status}`);
        return;
    }
    
    console.log("\n=== Keychain Item ACL Information ===");
    let aclListArray = ObjC.deepUnwrap($.CFMakeCollectable(aclList[0]));
    
    aclListArray.forEach((acl, index) => {
        console.log(`\n--- ACL Entry ${index + 1} ---`);
        let applicationList = Ref();
        let description = Ref();
        $.SecACLCopyContents(acl, applicationList, description, null);
        
        let desc = ObjC.deepUnwrap($.CFMakeCollectable(description[0]));
        console.log(`Description: ${desc}`);
        
        let apps = ObjC.deepUnwrap($.CFMakeCollectable(applicationList[0]));
        if (apps && apps.length > 0) {
            console.log("Trusted Applications:");
            apps.forEach(app => console.log(`  ${app}`));
        } else {
            console.log("All applications trusted");
        }
        
        let auths = ObjC.deepUnwrap($.CFMakeCollectable($.SecACLCopyAuthorizations(acl)));
        if (auths && auths.length > 0) {
            console.log("Authorizations:");
            auths.forEach(auth => console.log(`  ${auth}`));
        } else {
            console.log("No Authorizations");
        }
    });
}

function attemptDecrypt(keychainItemRef) {
    $.SecKeychainSetUserInteractionAllowed(false);
    
    let accessRef = Ref();
    let status = $.SecKeychainItemCopyAccess(keychainItemRef, accessRef);
    
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
        if (auths && auths.includes("ACLAuthorizationDecrypt")) {
            hasDecryptPermission = true;
            break;
        }
    }
    
    if (!hasDecryptPermission) {
        console.log("No decrypt permission for this item.");
        $.SecKeychainSetUserInteractionAllowed(true);
        return;
    }
    
    let dataContent = Ref();
    let dataContentLength = Ref();
    let attributeList = Ref();
    
    status = $.SecKeychainItemCopyContent(keychainItemRef, 0, attributeList, dataContentLength, dataContent);
    
    if (status === 0) {
        let nsdata = $.NSData.alloc.initWithBytesLength(dataContent[0], dataContentLength[0]);
        console.log("Secret Data: ", $.NSString.alloc.initWithDataEncoding(nsdata, $.NSUTF8StringEncoding).js);
    } else {
        console.log("Failed to decrypt with error code:", status);
    }
    
    $.SecKeychainSetUserInteractionAllowed(true);
}

main();