# Telemetry Managment
When writin code, assume the operator will make mistakes.  But dont overcompensate by writin bullet-proof scripts. Instead, Use good messaging, capture exceptions, reeturn error codes, and prioiritize telemtry.

**Less is better **
A simple way to measure telemetry volume is by using tools like Red Canary's [Mac Monitor](https://github.com/redcanaryco/mac-monitor), or the built-in `log` utility.

## Real World use case
1. You used the teemplate
2. Added your functions
3. Then decided to et fancy and modifty main ()  ** we lla do it lol** 


The operator runs your script without a `--help`  or any arguments.

```sh
osascript -l JavaScript keychain.js
keychain.js: execution error: Error: Error: exception raised by object: *** __boundsFail: index 4 beyond bounds [0 .. 3] (-2700)
```
**Telemetry Details with No Ars**
 
<details> 

Link to fofler: logs: file: telemtry_help_ar.log 

</details> 

##

## No Big deal   right?  
operator:  "Yo, keychain.js barffed. Look "
you: `--help` 


The operator proceeds to pass the `--help`
```sh
 osascript -l JavaScript keychain.js --help

Usage: osascript -l JavaScript keychain.js [OPTION]

Options:
  --list-all-generic         List all generic passwords
  --list-all-keys            List all keys
  --list-all-internet        List all internet passwords
  --list-all-certificates    List all certificates
  --list-by-account <name>   List items by account name
  --list-by-label-genp <label> List generic password items by label
  --list-by-label-key <label>  List key items by label
  --include-acls             Include ACL information in the output
  --query-acls              Query ACLs for all generic password items
  --query-acls-dev    Query ACLs using the original dev function
  --help                     Show this help message
╭─darmado@MBPRO02-DA001 ~/Opensource/armadoinc/attack-ma
```

**Telemetry Details from `--help`** 
<details> 

Link to fofler: logs: file: telemtry_help_ar.log 

</details> 


## **Problem solved?**

**Engaement type: TA emulation:** 
- opesec: increases proabability of detection
- telemetry produced: excess footprint 
- trade offs: you left a foot print and did not get any value from it

**Enagement type: Purple Team**
- opsec: NA
- telemtry: maybe useful, but introduces more clutter? 
- - trade offs: while the eneric telemtry can help invoke correlation events, it can also  cintribute to false positives. Depends on thhe customer's priorities, bandwidth, security policy enforcement on endpoints, and capabiltiies to effectively manageg false positives. Also dosrn't look profesional. It's best to isolate this type of  low-value telemtry with a seperate tool. 

**Enagement type: Red Team**
- opsec: You're f***c*d 
- telemetry produced: excess footprint 
- trade offs: you left a foot print and did not get any value from it


## How To Monitor YOur Telemetry
Personally, I like to use Apple's built-in login utilities. You have other options  though.

- [log](https://ss64.com/mac/log.html)
-  [Mac Monitor](https://github.com/redcanaryco/mac-monitor)


Write it to a log
```sh  
log stream --process osascript --debug > osascript.log;  wc -l osascript.log; echo '' > osascript.log
```

live
```sh
 log stream --process osascript --debug
```