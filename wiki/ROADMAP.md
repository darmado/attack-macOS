# attack-macOS Project Roadmap

This document outlines the planned features and improvements for the attack-macOS project.



## Core Built-in Shell Script Functions

| Function | Status | Description | Documentation |
|----------|--------|-------------|---------------|
| core_get_timestamp | ✅ | Generate consistent timestamp strings | [Get Timestamp.md](R&D%20Library/Functions/Shell/Get%20Timestamp.md) |
| core_generate_job_id | ✅ | Create unique 8-character hex job tracking IDs | [Generate Job Id.md](R&D%20Library/Functions/Shell/Generate%20Job%20Id.md) |
| core_parse_args | ✅ | Parse command-line arguments with validation | [Parse Args.md](R&D%20Library/Functions/Shell/Parse%20Args.md) |
| core_validate_input | ✅ | Input validation for strings, domains, URLs, file paths | [Input Validation.md](R&D%20Library/Functions/Shell/Input%20Validation.md) |
| core_log_output | ✅ | File logging with rotation and syslog integration | [Log Output.md](R&D%20Library/Functions/Shell/Log%20Output.md) |
| core_format_output | ✅ | Output formatting (JSON, CSV, raw) | [Format Output.md](R&D%20Library/Functions/Shell/Format%20Output.md) |
| core_encode_output | ✅ | Data encoding (base64, hex, perl_b64, perl_utf8) | [Encode Output.md](R&D%20Library/Functions/Shell/Encode%20Output.md) |
| core_encrypt_output | ✅ | Data encryption (AES-256-CBC, GPG symmetric, XOR) | [Encrypt Output.md](R&D%20Library/Functions/Shell/Encrypt%20Output.md) |
| core_exfiltrate_data | ✅ | Data exfiltration (HTTP POST/GET, DNS queries) | [Exfiltrate Data.md](R&D%20Library/Functions/Shell/Exfiltrate%20Data.md) |
| core_process_output | ✅ | Pipeline processing (format → encode → encrypt → steganography) | [Process Output.md](R&D%20Library/Functions/Shell/Process%20Output.md) |
| core_transform_output | ✅ | Final output delivery (logging, exfiltration, display) | [Transform Output.md](R&D%20Library/Functions/Shell/Transform%20Output.md) |
| core_apply_steganography | ✅ | Hide data in PNG images using native macOS tools | [Steganography.md](R&D%20Library/Functions/Shell/Steganography.md) |
| core_check_fda | ✅ | Full Disk Access permission verification | [Check Fda.md](R&D%20Library/Functions/Shell/Check%20Fda.md) |
| core_check_db_lock | ✅ | SQLite database lock detection | [Check Db Lock.md](R&D%20Library/Functions/Shell/Check%20Db%20Lock.md) |
| core_check_perms | ✅ | File permission validation (read/write/execute) | [Check Perms.md](R&D%20Library/Functions/Shell/Check%20Perms.md) |

## Other tasks

| Feature | Status | Priority | Description |
|---------|--------|----------|-------------|
| Community Contribution Workflow | Planned | High | Streamlined community contribution worflow |
| Additional Techniques | Planned | Medium | Implement more MITRE ATT&CK techniques |
| Testing Framework | Planned | Medium | Basic testing for scripts |
