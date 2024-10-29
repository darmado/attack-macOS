# Endpoint Security Vendors for macOS

## Overview
This table lists common endpoint security vendors and their associated processes and file paths on macOS systems. It supports security software discovery scripts like `security_software.sh` and `swiftbelt.js`.

## Purpose
- Provide a reference for identifying installed security software on macOS
- Aid in the development and maintenance of security assessment tools
- Support threat hunting and incident response activities

## Assumptions
- Paths and process names are current as of the last update
- Some vendors may use different paths or process names in newer versions
- Not all listed software may be present on a given system
- Installation links may change; always verify before use

| ✅ | Vendor | Processes | Paths | Installation Link |
|---|--------|-----------|-------|-------------------|
| ✅ | Avast | AvastUI, com.avast.daemon | /Applications/Avast.app, /Library/Application Support/Avast/ | |
| ✅ | AVG | AVGDaemon, AVGAntiVirus | /Applications/AVG AntiVirus.app, /Library/Application Support/AVG/ | |
| ✅ | Avira | avguard, avscan | /Applications/Avira.app, /Library/Application Support/Avira/ | |
| ✅ | Bitdefender | bdservicehost, BitdefenderAgent | /Applications/Bitdefender.app, /Library/Bitdefender/ | |
|  | BlockBlock | BlockBlock | /Applications/BlockBlock Helper.app | |
| ✅ | Carbon Black | CbOsxSensorService, CbDefense | /Applications/CarbonBlack/CbOsxSensorService, /Applications/Confer.app | |
| ✅ | CrowdStrike Falcon | falconctl, falcon-sensor | /Library/CS/falcond, /Applications/Falcon.app | |
| ✅ | Cylance | CylanceSvc, CylanceUI | /Library/Application Support/Cylance/Desktop, /Applications/Cylance/ | |
| ✅ | ESET | esets_daemon, eset_service | /Applications/ESET.app, /Library/Application Support/ESET/ | |
| ✅ | F-Secure | fsavd, F-Secure XFENCE | /Library/Application Support/F-Secure/, /Applications/F-Secure SAFE.app | |
|  | FileMonitor | FileMonitor | /Applications/FileMonitor.app | |
| ✅ | FireEye HX | xagt, xagtnotif | /Library/FireEye/xagt, /Applications/FireEye Endpoint Security.app | |
| ✅ | G DATA | GDAVServer, GDClient | /Applications/G DATA AntiVirus.app, /Library/Application Support/G DATA/ | |
| ✅ | JAMF | jamf, JamfDaemon | /usr/local/jamf/bin/jamf, /Library/Application Support/JAMF/ | |
| ✅ | Kandji | kandji-agent | /Library/Kandji/, /Applications/Kandji Self Service.app | |
| ✅ | Kaspersky | AVP, kav | /Applications/Kaspersky.app, /Library/Application Support/Kaspersky Lab/ | |
|  | KnockKnock | KnockKnock | /Applications/KnockKnock.app | |
|  | LuLu | LuLu | /Library/Objective-See/LuLu, /Applications/LuLu.app | |
| ✅ | Malwarebytes | Malwarebytes, mbam | /Applications/Malwarebytes.app, /Library/Application Support/Malwarebytes | |
| ✅ | McAfee | masvc, MFEFirewall | /Library/McAfee/agent/bin, /Applications/McAfee Endpoint Security for Mac.app | |
| ✅ | Microsoft Defender | MsMpEngCP, msmpeng | /Library/Application Support/Microsoft/Defender/, /Applications/Microsoft Defender.app | |
|  | Netiquette | Netiquette | /Applications/Netiquette.app | |
| ✅ | Norton | NortonDaemon, NortonSecurity | /Applications/Norton 360.app, /Library/Application Support/Norton/ | |
|  | OverSight | OverSight | /Applications/OverSight.app | |
| ✅ | Panda | AVENGINE, PandaAgent | /Applications/Panda Dome.app, /Library/Application Support/Panda Security/ | |
|  | ProcessMonitor | ProcessMonitor | /Applications/ProcessMonitor.app | |
| ✅ | Quick Heal | RepMgr, ScanEngine | /Applications/Quick Heal Total Security.app, /Library/Application Support/Quick Heal/ | |
|  | Red Canary Mac Monitor | Red Canary Mac Monitor, com.redcanary.agent.securityextension | /Applications/Red Canary Mac Monitor.app, /Library/SystemExtensions/533BA4C2-AF4A-4B4E-900E-9EA8F71CF089/com.redcanary.agent.securityextension.systemextension | |
|  | ReiKey | ReiKey | /Applications/ReiKey.app | |
| ✅ | SentinelOne | SentinelAgent, SentinelCtl | /Applications/SentinelOne/SentinelAgent.app, /Library/Sentinel/ | |
| ✅ | Sophos | SophosScanD, SophosServiceManager | /Library/Sophos Anti-Virus/, /Applications/Sophos/ | |
| ✅ | Symantec | SymDaemon, Norton | /Applications/Symantec Solutions/, /Library/Application Support/Symantec/ | |
| ✅ | Total Defense | TDAgent, TDScanner | /Applications/Total Defense Essential Anti-Virus.app, /Library/Application Support/Total Defense/ | |
| ✅ | TotalAV | TotalAVDaemon, TotalAVScanner | /Applications/TotalAV.app, /Library/Application Support/TotalAV/ | |
| ✅ | Trend Micro | iCoreService, tmsm | /Library/Application Support/TrendMicro, /Applications/Trend Micro Security.app | |

