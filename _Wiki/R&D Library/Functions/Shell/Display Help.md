# Display Help

### Purpose
Outputs a comprehensive help message using `cat` with heredoc syntax, displaying usage instructions, option descriptions, and notes. Includes dynamic variable substitution for script name, TTP ID, tactic, and configuration values.

### Dependencies
| Type | Name | Value |
|------|------|-------|
| Global Variable | `TTP_ID` | `""` |
| Global Variable | `TACTIC` | `""` |
| Global Variable | `LOG_DIR` | `"./logs"` |
| Global Variable | `CHUNK_SIZE` | `50` |
| Global Variable | `LOG_MAX_SIZE` | `5242880` |

<details>

```shell
core_display_help() {
    cat << EOF
Usage: ${0##*/} [OPTIONS]

Description: Base script for ATT&CK macOS techniques
MITRE ATT&CK: ${TTP_ID} - ${TACTIC}

Basic Options:
  -h, --help           Display this help message
  -v, --verbose        Enable verbose output with execution details
  -d, --debug          Enable debug output (includes verbose output)
  -a, --all            Process all available data (technique-specific)
  -l, --log            Enable logging to file (logs stored in $LOG_DIR)
  --ls                 List files in the current directory
  --steganography        Transform output using steganography (hide in image file)
  --steg-message TEXT    Text message to hide (used when --steg-input not specified)
  --steg-input FILE      File containing data to hide
  --steg-carrier FILE    Carrier image file (default: system desktop picture)
  --steg-output FILE     Output image file (default: ./hidden_data.png)
  --steg-extract [FILE]  Extract hidden data from steganography image (default: ./hidden_data.png)
# PLACEHOLDER_HELP_TEXT

Output Options:
  -f, --format TYPE    Output format: 
                        - json: Structured JSON output
                        - csv: Comma-separated values
                        - raw: Default pipe-delimited text

Encoding Options:
  --encode TYPE        Encode output using:
                        - base64/b64: Base64 encoding
                        - hex/xxd: Hexadecimal encoding
                        - perl_b64: Perl Base64 implementation
                        - perl_utf8: Perl UTF8 encoding

Encryption Options:
  --encrypt TYPE       Encrypt output using:
                        - aes: AES-256-CBC encryption (key sent via DNS)
                        - gpg: GPG symmetric encryption (key sent via DNS)
                        - xor: XOR encryption with cyclic key

Exfiltration Options:
  --exfil-dns DOMAIN   Exfiltrate data via DNS queries to specified domain
                        Data is automatically base64 encoded and chunked
  --exfil-http URL     Exfiltrate data via HTTP POST to specified URL
                        Data is sent in the request body
  --exfil-uri URL      Legacy parameter - Exfiltrate via HTTP GET with URL params
                        Data is automatically chunked to avoid URL length limits
  --chunk-size SIZE    Size of chunks for DNS/HTTP exfiltration (default: $CHUNK_SIZE bytes)
  --proxy URL          Use proxy for HTTP requests (format: protocol://host:port)
  --exfil-method METHOD Exfiltrate data using specified method


Notes:
- When using encryption with exfiltration, keys are automatically sent via DNS TXT records
- JSON output includes metadata about execution context
- Log files are automatically rotated when they exceed ${LOG_MAX_SIZE} bytes
- Exfiltration is enabled automatically when specifying any exfil method
- DNS exfiltration automatically chunks data and sends start/end signals
EOF
}
```

</details> 