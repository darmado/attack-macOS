ObjC.import('Security');

var firewallStatus = $.SecKeychainCopyStatus($("com.apple.security.firewall")).status;

if (firewallStatus === 1) {
  console.log("Firewall is enabled");
} else {
  console.log("Firewall is disabled");
}