# Display Help

### Purpose
Outputs a help message using `cat` with heredoc syntax, displaying usage instructions, option descriptions, and notes. Includes dynamic variable substitution for script name, TTP ID, tactic, and configuration values.

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

HELP:
  -h, --help                    Display this help message
  -d, --debug                   Enable debug output (includes verbose output)

SCRIPT:
# PLACEHOLDER_HELP_TEXT

EXECUTION:
  --isolated                    Enable memory isolation mode (spawns isolated processes)

Output Options:
  --format TYPE                 
                                - json: Structured JSON output
                                - csv: Comma-separated values
                                - raw: Default pipe-delimited text

ENCODING/OBFUSCATION
  --encode TYPE                
                                - base64/b64: Base64 encoding using base64 command
                                - hex/xxd: Hexadecimal encoding using xxd command
                                - perl_b64: Perl Base64 implementation using perl
                                - perl_utf8: Perl UTF8 encoding using perl

  --steganography              Hide output in image file using native macOS tools
  --steg-extract [FILE]        Extract hidden data from steganography image (default: ./hidden_data.png)

ENCRYPTION:
  --encrypt TYPE               
                                - aes: AES-256-CBC encryption using openssl command
                                - gpg: GPG symmetric encryption using gpg command
                                - xor: XOR encryption with cyclic key (custom implementation)

EXFILTRATION:
  --exfil-dns DOMAIN            Exfiltrate data via DNS queries using dig command
                                Data is automatically base64 encoded and chunked

  --exfil-http URL              Exfiltrate data via HTTP POST using curl command
                                Data is sent in the request body
                                Data is automatically chunked to avoid URL length limits

  --chunk-size SIZE           Size of chunks for DNS/HTTP exfiltration (default: $CHUNK_SIZE bytes)
  --proxy URL                 Use proxy for HTTP requests (format: protocol://host:port)

  LOGGING:

  -l, --log                     Create a log file (creates logs in ./logs directory)

Notes:
- When using encryption with exfiltration, keys are automatically sent via DNS TXT records
- JSON output includes metadata about execution context
- Log files are automatically rotated when they exceed ${LOG_MAX_SIZE} bytes
- Exfiltration is enabled automatically when specifying any exfil method
- DNS exfiltration automatically chunks data and sends start/end signals
- Steganography uses native macOS image manipulation without external dependencies
EOF
}
```

</details> 