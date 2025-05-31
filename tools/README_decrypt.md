# Attack-macOS Decryption Tool

A tool used to decrypt your output data.
## Features

- **AES-256-CBC decryption** (via OpenSSL subprocess)
- **GPG symmetric decryption** (via GPG subprocess)
- **XOR decryption** (native Python implementation)
- **Auto-detection** of encryption methods
- **JSON parsing** for attack-macOS script output
- **Interactive mode** for easy use
- **Verbose logging** for debugging

## Requirements

- Python 3.6+
- OpenSSL (for AES decryption)
- GPG (for GPG decryption)
- No third-party Python packages required

## Installation

The tool is ready to use - just make it executable:

## Usage

### Command Line Mode

```bash
# Basic usage with auto-detection
python3 decrypt.py --method auto --key "your_key" --data "encrypted_data"

# Decrypt AES data
python3 decrypt.py --method aes --key "your_key" --data "U2FsdGVkX1..."

# Decrypt from file
python3 decrypt.py --method aes --key "your_key" --file encrypted.txt

# Decrypt JSON output from attack-macOS scripts
python3 decrypt.py --method auto --key "your_key" --file output.json --json

# Verbose mode for debugging
python3 decrypt.py --method auto --key "your_key" --data "encrypted_data" --verbose
```

### Interactive Mode

```bash
python3 decrypt.py --interactive
```

Interactive mode provides a user-friendly interface where you can:
- Choose encryption method (or use auto-detection)
- Enter decryption key
- Paste encrypted data
- View decrypted results
- Process multiple items in sequence

### Supported Encryption Methods

#### AES-256-CBC
- Uses OpenSSL for decryption
- Expects base64-encoded data
- Compatible with `openssl enc -aes-256-cbc` output

#### GPG Symmetric
- Uses GPG for decryption
- Expects GPG armored format
- Compatible with `gpg --symmetric --cipher-algo AES256` output

#### XOR
- Native Python implementation
- Supports hex-encoded data
- Compatible with attack-macOS XOR encryption

#### Auto-Detection
- Automatically detects encryption method based on data format
- GPG: Detects `-----BEGIN PGP MESSAGE-----` header
- XOR: Detects `XOR-ENCRYPTED:` prefix
- AES: Detects base64 format (fallback)

## Examples

### Decrypt AES Data
```bash
# Example with the provided test data
python3 decrypt.py --method aes \
  --key "7a7911a37cdc2615e81e2aa89559510b1d87acf389084631672d2f0e9a9db922" \
  --file test_encrypted_data.txt
```

### Decrypt XOR Data
```bash
python3 decrypt.py --method xor \
  --key "testkey" \
  --data "3c001f1804452e1b171f104b030b1b08532c243759110b100612150d1d0a1d55"
```

### Process JSON Output
```bash
# If your attack-macOS script outputs JSON with encrypted data
python3 decrypt.py --method auto \
  --key "your_key" \
  --file script_output.json \
  --json \
  --verbose
```

## JSON Format Support

The tool can parse JSON output from attack-macOS scripts with this structure:

```json
{
  "timestamp": "2024-08-21T23:06:41Z",
  "command": "1217_browser_history.sh",
  "jobId": "abc12345",
  "procedure": "1217_browser_history",
  "data": ["encrypted_line_1", "encrypted_line_2"],
  "encryption": {
    "method": "aes",
    "key_hint": "sha256_hash"
  }
}
```

## Error Handling

The tool provides clear error messages for common issues:

- **Missing dependencies**: OpenSSL or GPG not found
- **Invalid keys**: Wrong decryption key provided
- **Malformed data**: Invalid base64, hex, or GPG format
- **Auto-detection failure**: Cannot determine encryption method

## Security Notes

- Keys are passed as command-line arguments (visible in process list)
- For sensitive operations, use interactive mode
- Decrypted data is output to stdout - redirect carefully
- No key validation is performed - wrong keys may produce garbage output

## Integration with Attack-macOS

This tool is designed to work seamlessly with the attack-macOS framework:

1. **Generate encrypted data** using attack-macOS scripts
2. **Extract the encryption key** from script output or logs
3. **Decrypt the data** using this tool
4. **Analyze the results** for your security research

## Troubleshooting

### OpenSSL Errors
```bash
# Ensure OpenSSL is installed
which openssl
openssl version
```

### GPG Errors
```bash
# Ensure GPG is installed
which gpg
gpg --version
```

### Python Errors
```bash
# Ensure Python 3.6+ is available
python3 --version
```

### Verbose Mode
Use `--verbose` flag to see detailed debugging information:
```bash
python3 decrypt.py --method auto --key "key" --data "data" --verbose
```

## Contributing

This tool follows the attack-macOS coding principles:
- Clean, modular code
- Single responsibility functions
- Comprehensive error handling
- No third-party dependencies
- Shell compatibility across macOS environments

## License

Part of the attack-macOS framework. See main project license. 