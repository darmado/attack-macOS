# Notes
Living doc, used to track observations and improvements for each project component. 



### src/jxa/keychains_access.js
<details>

### Notes
- Implements keychain access functionality using JavaScript for Automation (JXA)
- Includes functions for listing, finding, and manipulating keychain items

### Observations
- Current implementation may not handle all error cases
- Some functions might trigger user prompts, which could be problematic for automation
- Attempt to bypass password prompts by disabling user interaction

### Potential Improvements
- Implement more robust error handling
- Find ways to minimize or eliminate user prompts
- Add more comprehensive logging for debugging purposes
- Further investigate methods to access protected keychain items without prompts

</details>

##

### src/jxa/security.js
<details>

### Notes

### Observations

### Potential Improvements

</details>

##

### src/applescript/keychains_access.js
<details>

### Notes

### Observations

### Potential Improvements

</details>

##

### src/jxa/locksmith.js
<details>

### Notes
- Original script from the LockSmith project
- Provides comprehensive keychain access functionality

### Observations
- Contains more detailed implementation of keychain access compared to our custom script
- May have features we haven't fully utilized yet

### Potential Improvements
- Integrate more of LockSmith's functionality into our custom script
- Analyze LockSmith's approach to avoiding user prompts

</details>

##

### ttp/credential_access/keychain.sh
<details>

### Notes
- Bash script for keychain credential access
- Implements various keychain operations using the `security` command-line tool

### Observations
- Current implementation may not cover all possible keychain operations
- Error handling could be improved

### Potential Improvements
- Add more keychain operations to align with the `security` tool's capabilities
- Implement more robust error handling and logging
- Consider integrating with the JXA script for enhanced functionality

</details>

##

### util/_templates/utility_functions.sh
<details>

### Notes
- Template script for utility functions used across different scripts
- Includes common operations like logging, encoding, and data exfiltration

### Observations
- Provides a good base for consistent functionality across scripts
- May need updates as new common requirements are identified

### Potential Improvements
- Regularly review and update based on needs of other scripts
- Consider creating a library of utility functions that can be sourced by other scripts

</details>

##

### src/jxa/swiftbelt.js
<details>

### Notes
- Implements various discovery and enumeration techniques for macOS systems
- Uses JavaScript for Automation (JXA) for system interaction
- Designed to work both as a standalone script and with Mythic C2

### Observations
- Modular structure with separate functions for different checks
- Includes checks for TCC, security tools, system info, credentials, running apps, history, Slack data, installed apps, Firefox cookies, screen lock status, sticky notes, and TextEdit autosave
- Uses a main `Discover` function to orchestrate the execution of individual checks
- Implements argument parsing for both command-line and Mythic C2 usage

### Potential Improvements
- Implement better error handling and permissions checking
- Enhance Slack data extraction to include more comprehensive checks (preferences, cache, shared files)
- Add browser enumeration functionality
- Improve running apps list to provide more detailed information
- Expand history check to include bash and zsh history for all users (including root when possible)
- Add functionality to list launch agents and daemons

### SwiftBelt Comparison: Original vs New Version

| Feature/Change | swiftbeltORI.js | swiftbelt.js | Notes |
|----------------|-----------------|--------------|-------|
| Argument Parsing | Basic string parsing | More robust parsing using `parseArguments()` | New version supports multiple arguments and flags |
| Error Handling | Basic try/catch | More comprehensive error handling | New version provides more detailed error messages |
| Modularity | Monolithic functions | More modular design | New version splits functionality into smaller, focused functions |
| Debug Mode | Not present | Implemented with `DEBUG` flag | Allows for more detailed logging when needed |
| Security Tools Check | Limited set of tools | Expanded list of security tools | New version checks for more security products |
| POSIX Permissions | Not used | Implemented `checkPOSIXAccess()` | More efficient and granular permission checks |
| Code Signing Checks | Not present | Implemented `checkCodeSigningAPI()` | New feature to verify application integrity |
| Safari History | Not present | Implemented `SafariHistory()` | New feature to access Safari browsing history |
| Firefox Cookies | Basic implementation | Enhanced with SQLite and NSTask methods | More robust cookie extraction, handles potential access issues |
| Command-line Interface | Limited | Expanded with more options | New version supports more operations from command line |

#### Code Snippet Comparisons:

1. Argument Parsing:
   
   swiftbeltORI.js:
   ```javascript
   if (options == "All") {
       // Run all checks
   } else if (options.includes("TCCCheck")) {
       // Run specific check
   }
   ```

   swiftbelt.js:
   ```javascript
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
   ```

2. Security Tools Check:

   swiftbeltORI.js:
   ```javascript
   if ((allapps.includes("CbOsxSensorService")) || (fileMan.fileExistsAtPath("/Applications/CarbonBlack/CbOsxSensorService"))) {
       results += "[+] Carbon Black Sensor installed.\n";
   }
   ```

   swiftbelt.js:
   ```javascript
   var securityTools = [
       {name: "Carbon Black", processes: ["CbOsxSensorService", "CbDefense"], paths: ["/Applications/CarbonBlack/CbOsxSensorService", "/Applications/Confer.app"]},
       // ... more tools
   ];

   securityTools.forEach((tool) => {
       var isInstalled = tool.paths.some(path => checkPOSIXAccess(path, 'r'));
       var isRunning = runningProcesses.some(proc => tool.processes.includes(proc.name));
       // ... check and report
   });
   ```

3. POSIX Access Check:

   swiftbelt.js (new feature):
   ```javascript
   function checkPOSIXAccess(filepath, mode) {
       var access = 0;
       switch(mode) {
           case 'r': access = 4; break;  // POSIX R_OK
           case 'w': access = 2; break;  // POSIX W_OK
           case 'x': access = 1; break;  // POSIX X_OK
           default: return false;
       }
       return $.access(filepath, access) === 0;
   }
   ```

These changes represent significant improvements in functionality, robustness, and extensibility of the SwiftBelt tool.

</details>

##
