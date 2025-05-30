# Parse Args

### Purpose
Processes command-line arguments using a `while` loop and `case` statement to set global flag variables. Handles argument values, tracks unknown arguments and missing values, but performs no validation. Reports warnings for unknown/missing arguments but continues execution.

### Dependencies
| Type | Name | Value |
|------|------|-------|
| Global Variable | `SHOW_HELP` | `false` |
| Global Variable | `DEBUG` | `false` |
| Global Variable | `LOG_ENABLED` | `false` |
| Global Variable | `LIST_FILES` | `false` |
| Global Variable | `FORMAT` | `"raw"` |
| Global Variable | `ENCODE` | `"none"` |
| Global Variable | `ENCODING_TYPE` | `"none"` |
| Global Variable | `ENCRYPT` | `"none"` |
| Global Variable | `ENCRYPTION_TYPE` | `"none"` |
| Global Variable | `EXFIL` | `false` |
| Global Variable | `EXFIL_METHOD` | `"none"` |
| Global Variable | `EXFIL_TYPE` | `"none"` |
| Global Variable | `EXFIL_URI` | `""` |
| Global Variable | `CHUNK_SIZE` | `50` |
| Global Variable | `PROXY_URL` | `""` |
| Global Variable | `STEG_TRANSFORM` | `false` |
| Global Variable | `STEG_MESSAGE` | `""` |
| Global Variable | `STEG_EXTRACT_FILE` | `""` |
| Global Variable | `STEG_CARRIER_IMAGE` | `""` |
| Global Variable | `STEG_OUTPUT_IMAGE` | `""` |
| Global Variable | `STEG_EXTRACT` | `false` |
| Global Variable | `UNKNOWN_ARGS` | `""` |
| Global Variable | `MISSING_VALUES` | `""` |
| Global Variable | `CMD_PRINTF` | `"printf"` |
| Global Variable | `CMD_GREP` | `"grep"` |
| Function | `core_debug_print()` | For debug logging |
| Function | `core_get_timestamp()` | For timestamp in warnings |

<details>

```shell
core_parse_args() {
    # Track unknown arguments and missing values for error reporting
    UNKNOWN_ARGS=""
    MISSING_VALUES=""
    
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -h|--help)
                SHOW_HELP=true
                ;;
            -d|--debug)
                DEBUG=true
                ;;
            -l|--log)
                LOG_ENABLED=true
                ;;
            --ls)
                LIST_FILES=true
                ;;
            -f|--format|--output-format)
                if [ -n "$2" ] && [ "$2" != "${2#-}" ]; then
                    # Next arg starts with -, so no value provided
                    MISSING_VALUES="$MISSING_VALUES $1"
                elif [ -n "$2" ]; then
                    FORMAT="$2"
                    shift
                else
                    MISSING_VALUES="$MISSING_VALUES $1"
                fi
                ;;
            --encode)
                if [ -n "$2" ] && [ "$2" != "${2#-}" ]; then
                    MISSING_VALUES="$MISSING_VALUES $1"
                elif [ -n "$2" ]; then
                    ENCODE="$2"
                    ENCODING_TYPE="$2"
                    shift
                else
                    MISSING_VALUES="$MISSING_VALUES $1"
                fi
                ;;
            --encrypt)
                if [ -n "$2" ] && [ "$2" != "${2#-}" ]; then
                    MISSING_VALUES="$MISSING_VALUES $1"
                elif [ -n "$2" ]; then
                    ENCRYPT="$2"
                    ENCRYPTION_TYPE="$2"
                    shift
                else
                    MISSING_VALUES="$MISSING_VALUES $1"
                fi
                ;;
            --exfil-dns)
                if [ -n "$2" ] && [ "$2" != "${2#-}" ]; then
                    MISSING_VALUES="$MISSING_VALUES $1"
                elif [ -n "$2" ]; then
                    EXFIL=true
                    EXFIL_METHOD="dns"
                    EXFIL_TYPE="dns"
                    EXFIL_URI="$2"
                    shift
                else
                    MISSING_VALUES="$MISSING_VALUES $1"
                fi
                ;;
            --exfil-http)
                if [ -n "$2" ] && [ "$2" != "${2#-}" ]; then
                    MISSING_VALUES="$MISSING_VALUES $1"
                elif [ -n "$2" ]; then
                    EXFIL=true
                    EXFIL_METHOD="http"
                    EXFIL_TYPE="http"
                    EXFIL_URI="$2"
                    shift
                else
                    MISSING_VALUES="$MISSING_VALUES $1"
                fi
                ;;
            --exfil-uri)
                if [ -n "$2" ] && [ "$2" != "${2#-}" ]; then
                    MISSING_VALUES="$MISSING_VALUES $1"
                elif [ -n "$2" ]; then
                    EXFIL=true
                    EXFIL_TYPE="uri"
                    EXFIL_URI="$2"
                    # Determine method based on URI format (will be validated later)
                    if "$CMD_PRINTF"  "$2" | $CMD_GREP -q "^http"; then
                        EXFIL_METHOD="http"
                    else
                        EXFIL_METHOD="dns"
                    fi
                    shift
                else
                    MISSING_VALUES="$MISSING_VALUES $1"
                fi
                ;;
            --chunk-size)
                if [ -n "$2" ] && [ "$2" != "${2#-}" ]; then
                    MISSING_VALUES="$MISSING_VALUES $1"
                elif [ -n "$2" ]; then
                    CHUNK_SIZE="$2"
                    shift
                else
                    MISSING_VALUES="$MISSING_VALUES $1"
                fi
                ;;
            --proxy)
                if [ -n "$2" ] && [ "$2" != "${2#-}" ]; then
                    MISSING_VALUES="$MISSING_VALUES $1"
                elif [ -n "$2" ]; then
                    PROXY_URL="$2"
                    shift
                else
                    MISSING_VALUES="$MISSING_VALUES $1"
                fi
                ;;
            --exfil-method)
                if [ -n "$2" ] && [ "$2" != "${2#-}" ]; then
                    MISSING_VALUES="$MISSING_VALUES $1"
                elif [ -n "$2" ]; then
                    EXFIL_METHOD="$2"
                    EXFIL_TYPE="$2"
                    shift
                else
                    MISSING_VALUES="$MISSING_VALUES $1"
                fi
                ;;
            --steganography)
                STEG_TRANSFORM=true
                ;;
            --steg-message)
                if [ -n "$2" ] && [ "$2" != "${2#-}" ]; then
                    MISSING_VALUES="$MISSING_VALUES $1"
                elif [ -n "$2" ]; then
                    STEG_MESSAGE="$2"
                    shift
                else
                    MISSING_VALUES="$MISSING_VALUES $1"
                fi
                ;;
            --steg-input)
                if [ -n "$2" ] && [ "$2" != "${2#-}" ]; then
                    MISSING_VALUES="$MISSING_VALUES $1"
                elif [ -n "$2" ]; then
                    STEG_EXTRACT_FILE="$2"
                    shift
                else
                    MISSING_VALUES="$MISSING_VALUES $1"
                fi
                ;;
            --steg-carrier)
                if [ -n "$2" ] && [ "$2" != "${2#-}" ]; then
                    MISSING_VALUES="$MISSING_VALUES $1"
                elif [ -n "$2" ]; then
                    STEG_CARRIER_IMAGE="$2"
                    shift
                else
                    MISSING_VALUES="$MISSING_VALUES $1"
                fi
                ;;
            --steg-output)
                if [ -n "$2" ] && [ "$2" != "${2#-}" ]; then
                    MISSING_VALUES="$MISSING_VALUES $1"
                elif [ -n "$2" ]; then
                    STEG_OUTPUT_IMAGE="$2"
                    shift
                else
                    MISSING_VALUES="$MISSING_VALUES $1"
                fi
                ;;
            --steg-extract)
                STEG_EXTRACT=true
                if [ -n "$2" ] && [ ! "$2" = "${2#-}" ]; then
                    STEG_EXTRACT_FILE="./hidden_data.png"
                elif [ -n "$2" ]; then
                    STEG_EXTRACT_FILE="$2"
                    shift
                else
                    STEG_EXTRACT_FILE="./hidden_data.png"
                fi
                ;;
# We need to  accomidate the unknown rgs condiuton for the new args we add from the yaml
# PLACEHOLDER_ARGUMENT_PARSER_OPTIONS
            *)
                # Collect unknown arguments for error reporting
                if [ -z "$UNKNOWN_ARGS" ]; then
                    UNKNOWN_ARGS="$1"
                else
                    UNKNOWN_ARGS="$UNKNOWN_ARGS $1"
                fi
                ;;
        esac
        shift
    done
    
    core_debug_print "Arguments parsed: VERBOSE=$VERBOSE, DEBUG=$DEBUG, FORMAT=$FORMAT, ENCODE=$ENCODE, ENCRYPT=$ENCRYPT"
    
    # Report unknown arguments as warnings but don't exit
    if [ -n "$UNKNOWN_ARGS" ]; then
        "$CMD_PRINTF"  "[WARNING] [%s] Unknown arguments: %s\n" "$(core_get_timestamp)" "$UNKNOWN_ARGS" >&2
    fi
    
    # Report missing values as warnings but don't exit
    if [ -n "$MISSING_VALUES" ]; then
        "$CMD_PRINTF"  "[WARNING] [%s] Arguments missing required values: %s\n" "$(core_get_timestamp)" "$MISSING_VALUES" >&2
    fi
}
```

</details> 