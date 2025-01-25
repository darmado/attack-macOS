// Disable the macOS firewall through NSUserDefaults
ObjC.import('Foundation');

// Function to check the status of the macOS firewall
function checkFirewallStatus() {
    var userDefaults = $.NSUserDefaults.standardUserDefaults;
    var firewallStatus = userDefaults.objectForKey($.NSKeyedArchiverArchivedDataWithRootObject);
    console.log(`Firewall status before disable: ${firewallStatus ? 'Enabled' : 'Disabled'}`);
}

// Function to disable the macOS firewall
function disableFirewall() {
    var userDefaults = $.NSUserDefaults.standardUserDefaults;
    
    // Turn off the firewall setting
    userDefaults.setObject_forKey($.false, $.NSKeyedArchiverArchivedDataWithRootObject);
    userDefaults.synchronize();
}

// Check and disable the firewall
checkFirewallStatus();
disableFirewall();
