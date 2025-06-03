# Global Variables Blueprint

## Overview
This document defines the standard structure and organization of global variables in attack-macOS scripts.

## Variable Categories

### 1. TTP Information
| Variable | Type | Example | Description | Used By |
|----------|------|---------|-------------|---------|
| `TTP_ID` | string | `"T1217"` | MITRE ATT&CK technique ID | `log_output()`, `init_logging()` |
| `TACTIC` | string | `"Discovery"` | MITRE ATT&CK tactic | `log_output()` |
| `SUBTECHNIQUE_ID` | string | `"T1217.001"` | MITRE ATT&CK sub-technique ID | `log_output()` |
| `NAME` | string | `"browser_history"` | Script identifier | `init_logging()`, `log_output()` |

### 2. System Commands
| Variable | Type | Example | Description | Used By |
|----------|------|---------|-------------|---------|
| `CMD_SQLITE3` | string | `"sqlite3"` | SQLite3 command | `query_browser_db()` |
| `CMD_OPENSSL` | string | `"openssl"` | OpenSSL command | `encrypt_data()`, `generate_random_key()` |
| `CMD_BASE64` | string | `"base64"` | Base64 command | `encode_output()` |
| `CMD_CURL` | string | `"curl"` | HTTP client command | `exfiltrate_http()` |
| `CMD_DIG` | string | `"dig"` | DNS lookup command | `exfiltrate_dns()` |
| `CMD_GPG` | string | `"gpg"` | GPG command | `encrypt_data()` |
| `CMD_XXD` | string | `"xxd"` | Hex dump command | `encode_output()` |
| `CMD_UUENCODE` | string | `"uuencode"` | UU encoding command | `encode_output()` |
| `CMD_PERL` | string | `"perl"` | Perl interpreter | `encode_output()` |

### 3. Command Options
| Variable | Type | Example | Description | Used By |
|----------|------|---------|-------------|---------|
| `CMD_SQLITE3_OPTS` | string | `"-separator '\|'"` | SQLite3 options | `query_browser_db()` |
| `CMD_GPG_OPTS` | string | `"--batch --yes"` | GPG options | `encrypt_data()` |
| `CMD_CURL_OPTS` | string | `"-s -X POST"` | cURL options | `exfiltrate_http()` |
| `CMD_CURL_TIMEOUT` | string | `"--connect-timeout 5"` | cURL timeout settings | `exfiltrate_http()` |
| `CMD_CURL_SECURITY` | string | `"--fail-with-body --insecure"` | cURL security settings | `exfiltrate_http()` |

### 4. Input Parameters
| Variable | Type | Default | Description | Source | Used By |
|----------|------|---------|-------------|---------|---------|
| `INPUT_SEARCH` | string | `""` | Search term for history | --search flag | `safari_history()`, `query_chrome_hdb()`, `query_firefox_hdb()`, `query_brave_hdb()` |
| `INPUT_DAYS` | integer | `7` | Days of history to fetch | --last flag | `safari_history()`, `query_chrome_hdb()`, `query_firefox_hdb()`, `query_brave_hdb()` |
| `INPUT_START_TIME` | string | `""` | Start time filter | --starttime flag | `safari_history()`, `query_chrome_hdb()`, `query_firefox_hdb()`, `query_brave_hdb()` |
| `INPUT_END_TIME` | string | `""` | End time filter | --endtime flag | `safari_history()`, `query_chrome_hdb()`, `query_firefox_hdb()`, `query_brave_hdb()` |
| `INPUT_EXFIL_METHOD` | string | `""` | Exfiltration method | --exfilhttp/--exfildns flag | `main()` |
| `INPUT_EXFIL_URI` | string | `""` | Exfiltration destination | --exfilhttp/--exfildns value | `exfiltrate_http()`, `exfiltrate_dns()` |
| `INPUT_PROXY` | string | `""` | HTTP proxy setting | --proxy flag | `exfiltrate_http()` |

### 5. Browser Database Paths
| Variable | Type | Default | Description | Used By |
|----------|------|---------|-------------|---------|
| `SAFARI_DB` | string | `"$HOME/Library/Safari/History.db"` | Safari history DB path | `safari_history()` |
| `CHROME_DB` | string | `"$HOME/Library/Application Support/Google/Chrome/Default/History"` | Chrome history DB path | `query_chrome_hdb()` |
| `FIREFOX_PROFILE` | string | `"~/Library/Application Support/Firefox/Profiles/*.default-release"` | Firefox profile path | `query_firefox_hdb()` |
| `FIREFOX_DB` | string | `"${FIREFOX_PROFILE}/places.sqlite"` | Firefox history DB path | `query_firefox_hdb()` |
| `BRAVE_DB` | string | `"$HOME/Library/Application Support/BraveSoftware/Brave-Browser/Default/History"` | Brave history DB path | `query_brave_hdb()` |

### 6. Control Switches
| Variable | Type | Default | Description | Used By |
|----------|------|---------|-------------|---------|
| `DEBUG` | boolean | `false` | Enable debug output | `debug_print()`, `main()`, `encode_output()`, `encrypt_data()`, `exfiltrate_dns()`, `exfiltrate_http()` |
| `LOG_ENABLED` | boolean | `false` | Enable logging | `log_output()`, `init_logging()`, `main()` |
| `EXFIL` | boolean | `false` | Enable data exfiltration | `main()` |
| `ALL` | boolean | `false` | Process all browsers | `main()` |
| `SAFARI` | boolean | `false` | Process Safari history | `main()` |
| `CHROME` | boolean | `false` | Process Chrome history | `main()` |
| `FIREFOX` | boolean | `false` | Process Firefox history | `main()` |
| `BRAVE` | boolean | `false` | Process Brave history | `main()` |
| `HAS_FDA_ACCESS` | boolean | `false` | Full Disk Access status | `check_perms_tcc()`, `safari_history()` |
| `HAS_TCC_SYS_ACCESS` | boolean | `false` | System TCC DB access | `check_perms_tcc()` |
| `HAS_TCC_USER_ACCESS` | boolean | `false` | User TCC DB access | `check_perms_tcc()` |

### 7. Processing States
| Variable | Type | Default | Valid Values | Description | Used By |
|----------|------|---------|--------------|-------------|---------|
| `ENCODE` | string | `"none"` | none, b64/base64, hex/xxd, perl_b64, perl_utf8 | Output encoding mode | `encode_output()`, `main()`, `exfiltrate_dns()` |
| `ENCRYPT` | string | `"none"` | none, aes, gpg | Output encryption mode | `encrypt_data()`, `main()`, `prepare_encryption()` |
| `FORMAT` | string | `""` | "", json, csv | Output format type | `format_output()`, `main()`, `log_output()` |
| `EXFIL_METHOD` | string | `""` | "", http, dns | Selected exfiltration method | `main()`, `exfiltrate_http()`, `exfiltrate_dns()` |
| `EXFIL_TYPE` | string | `"none"` | none, http, dns | Active exfiltration type | `log_output()`, `main()` |
| `ENCRYPTION_TYPE` | string | `"none"` | none, aes, gpg | Active encryption type | `log_output()`, `exfiltrate_http()` |
| `ENCODING_TYPE` | string | `"none"` | none, base64, hex, perl_base64, perl_utf8 | Active encoding type | `log_output()`, `exfiltrate_http()` |

### 8. Job Control
| Variable | Type | Example | Description | Used By |
|----------|------|---------|-------------|---------|
| `JOB_ID` | string | `"a1b2c3d4"` | Unique job identifier | `core_generate_job_id()`, `log_output()` |
| `SCRIPT_STATUS` | string | `"running"` | Current script status | `log_output()`, `main()` |
| `SCRIPT_CMD` | string | `"$0 $*"` | Full command line | `log_output()` |
| `OWNER` | string | `"$USER"` | Script owner | `log_output()` |
| `PARENT_PROCESS` | string | `"$(ps -p $PPID -o comm=)"` | Parent process name | `log_output()` |

### 9. Logging Configuration
| Variable | Type | Example | Description | Used By |
|----------|------|---------|-------------|---------|
| `LOG_DIR` | string | `"$(dirname "$0")/../../logs"` | Log directory path | `init_logging()`, `log_output()` |
| `LOG_FILE_NAME` | string | `"${TTP_ID}_${NAME}.log"` | Log file name | `init_logging()`, `log_output()` |
| `LOG_MAX_SIZE` | integer | `5242880` | Max log size (5MB) | `init_logging()` |
| `SYSLOG_TAG` | string | `"browser_history"` | Syslog identifier | `log_output()` |

## Variable Naming Conventions

| Type | Convention | Example | Description |
|------|------------|---------|-------------|
| Constants | UPPERCASE | `CMD_SQLITE3` | Immutable values |
| Feature Flags | UPPERCASE | `DEBUG` | Boolean controls |
| Input Parameters | INPUT_PREFIX | `INPUT_SEARCH` | User inputs |
| Status Variables | UPPERCASE | `SCRIPT_STATUS` | State tracking |
| Command Options | CMD_PREFIX | `CMD_CURL_OPTS` | Command configurations |
| File Paths | UPPERCASE | `LOG_DIR` | Directory/file locations |
| Temporary Variables | lowercase | `temp_value` | Function-local variables |



