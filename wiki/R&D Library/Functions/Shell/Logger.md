# Logger Documentation

## Overview

The attack-macOS framework includes comprehensive logging capabilities through the `core_log_output` function in `base.sh`. Logging captures execution details, function metadata, and output data for analysis and detection engineering.

## Logging Features

- **File Logging**: Detailed logs written to rotating log files
- **Syslog Integration**: Key execution data sent to system logs
- **Debug Output**: Real-time debug information to stderr
- **Language Tracking**: Captures programming languages used in functions
- **Automatic Rotation**: Log files rotated when size exceeds 5MB

## Enabling Logging

### Command Line
```bash
# Enable file logging
./script.sh --log --option

# Enable debug output (includes logging)
./script.sh --debug --option

# Both logging and debug
./script.sh --log --debug --option
```

### Global Variables
```bash
LOG_ENABLED=true        # Enable file logging
DEBUG=true             # Enable debug output and logging
LOG_DIR="./logs"       # Log directory path
LOG_MAX_SIZE=5242880   # 5MB rotation threshold
```

## Log Output Formats

### File Log Format
```
[2025-01-27 10:30:15] [info] [PID:1234] [job:a1b2c3d4] owner=user parent=zsh ttp_id=T1087 tactic=Discovery format=raw encoding=none encryption=none exfil=none language=shell status=info
command: ./find_account_info.sh --email-search
data:
SEARCH_TYPE|COMMAND|RESULT
EMAIL|defaults find EmailAddress|Found: /Users/user/Library/Preferences/...
---
```

### Syslog Format
```
user@hostname attack-macos[1234]: job=a1b2c3d4 status=info ttp_id=T1087 tactic=Discovery exfil=none encoding=none encryption=none language=shell cmd="./find_account_info.sh --email-search"
```

## Log Fields Reference

| Field | Description | Example Values |
|-------|-------------|----------------|
| **timestamp** | Execution timestamp | `2025-01-27 10:30:15` |
| **status** | Log entry type | `info`, `error`, `started`, `output` |
| **PID** | Process ID | `1234` |
| **job** | Unique job identifier | `a1b2c3d4` |
| **owner** | User executing script | `user` |
| **parent** | Parent process | `zsh`, `bash`, `Terminal` |
| **ttp_id** | MITRE ATT&CK technique | `T1087`, `T1087.001` |
| **tactic** | MITRE ATT&CK tactic | `Discovery`, `Collection` |
| **format** | Output format | `raw`, `json`, `csv` |
| **encoding** | Data encoding method | `none`, `base64`, `hex` |
| **encryption** | Data encryption method | `none`, `aes`, `gpg` |
| **exfil** | Exfiltration method | `none`, `dns`, `http` |
| **language** | Function languages used | `shell`, `shell,python`, `jxa` |
| **command** | Full command executed | `./script.sh --option` |

## Language Field Details

The `language` field captures which programming/scripting languages are used in each function execution:

### Single Language Functions
```bash
# Pure shell function
language=shell

# Python-only function  
language=python

# JXA function
language=jxa
```

### Multi-Language Functions
```bash
# Shell with Python processing
language=shell,python

# Shell with JXA automation
language=shell,jxa
```

### Detection Engineering Benefits
- **Pattern Recognition**: Identify scripts using specific language combinations
- **Behavioral Analysis**: Understand execution patterns across languages
- **Threat Hunting**: Search for unusual language combinations
- **Rule Creation**: Build detection rules based on language usage

## Log File Management

### Automatic Rotation
- Log files rotate when exceeding 5MB (configurable)
- Rotated files use timestamp suffix: `T1087_find_account_info.log.20250127103015`
- No automatic cleanup - manual maintenance required

### Log Directory Structure
```
./logs/
├── T1087_find_account_info.log           # Current log
├── T1087_find_account_info.log.20250127103015  # Rotated log
└── T1518_security_software.log          # Other technique logs
```

### Custom Log Configuration
```bash
# Custom log directory
LOG_DIR="/var/log/attack-macos"

# Custom rotation size (10MB)
LOG_MAX_SIZE=$((10 * 1024 * 1024))

# Custom log file naming
LOG_FILE_NAME="${TTP_ID}_custom_name.log"
```

## Debug Output

When `DEBUG=true`, real-time information is printed to stderr:

```bash
[DEBUG] [2025-01-27 10:30:15] Arguments parsed: DEBUG=true, FORMAT=, ENCODE=none, ENCRYPT=none
[DEBUG] [2025-01-27 10:30:16] Executing shell function: find_email_addresses
[DEBUG] [2025-01-27 10:30:17] Function language: shell
[INFO] [2025-01-27 10:30:18] Data processed: 3 records found
```

## Syslog Integration

Logs automatically integrate with macOS system logs:

### Viewing Syslog Entries
```bash
# View recent attack-macos logs
log show --predicate 'senderImagePath CONTAINS "attack-macos"' --last 1h

# View specific technique logs
log show --predicate 'eventMessage CONTAINS "ttp_id=T1087"' --last 1h

# View by language usage
log show --predicate 'eventMessage CONTAINS "language=python"' --last 1h
```

### Console App Filtering
1. Open Console.app
2. Filter by: `senderImagePath CONTAINS "attack-macos"`
3. Or filter by: `eventMessage CONTAINS "ttp_id=T1087"`

## Error Handling

### Log Directory Creation
- Automatically creates log directory if missing
- Graceful degradation if directory creation fails
- Warning message printed to stderr on failure

### Permission Issues
- Continues execution if logging fails
- Error messages sent to stderr
- Core functionality unaffected

### Disk Space Management
- No automatic cleanup of old logs
- Monitor disk usage manually
- Consider logrotate integration for production

## Integration Examples

### Detection Engineering Queries

**Splunk Query - Find Multi-Language Executions:**
```splunk
index=macos sourcetype=syslog "attack-macos" language="*,*"
| stats count by ttp_id, language, tactic
```

**ElasticSearch Query - Track Exfiltration:**
```json
{
  "query": {
    "bool": {
      "must": [
        {"match": {"program": "attack-macos"}},
        {"bool": {"must_not": {"match": {"exfil": "none"}}}}
      ]
    }
  }
}
```

**Log Analysis Script:**
```bash
#!/bin/bash
# Analyze language usage patterns
grep "language=" ./logs/*.log | \
  sed 's/.*language=\([^ ]*\).*/\1/' | \
  sort | uniq -c | sort -nr
```

### Monitoring Setup

**Real-time Monitoring:**
```bash
# Monitor new log entries
tail -f ./logs/*.log

# Monitor syslog for attack-macos
log stream --predicate 'senderImagePath CONTAINS "attack-macos"'
```

**Automated Analysis:**
```bash
#!/bin/bash
# Daily log analysis
find ./logs -name "*.log" -newermt "1 day ago" | \
  xargs grep -h "status=error" | \
  mail -s "Attack-macOS Errors" admin@company.com
```

## Best Practices

### Development
- Always test with `--debug` during development
- Use `--log` for production deployment tracking
- Monitor log file sizes in automated environments

### Detection Engineering
- Correlate `language` field with process execution logs
- Monitor for unusual language combinations
- Track exfiltration attempts via `exfil` field
- Use `job` field to correlate related activities

### Operations
- Implement log rotation policies
- Monitor disk space usage
- Backup important execution logs
- Regular log analysis for anomalies

## Troubleshooting

### No Log Output
1. Check `LOG_ENABLED=true` is set
2. Verify log directory permissions
3. Check available disk space
4. Review stderr for error messages

### Missing Language Information
1. Ensure YAML includes `language` field
2. Verify build system processes language correctly
3. Check `FUNCTOIN_LANG` variable

### Syslog Missing
1. Verify `logger` command availability
2. Check syslog daemon status
3. Review system log configuration

### Debug Output Issues
1. Confirm `DEBUG=true` is set
2. Check stderr redirection
3. Verify terminal supports stderr output
