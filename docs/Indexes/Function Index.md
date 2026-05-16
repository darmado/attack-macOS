# Function index

## Purpose

- List **`core_*` functions** registered in **`attackmacos/core/global/functions.yml`** (aligned with **`attackmacos/core/base/base.sh`**) and link to prose under **`docs/Functions/Shell/`**.
- **Procedure-local** shell functions (blocks emitted from procedure YAML) are **not** enumerated here; they are built under **`attackmacos/ttp/<tactic>/shell/`**. Use **`python3 cicd/audit/audit_procedure_inventory.py --strict`** for YAML ↔ script parity.

> **Regenerate:** `python3 cicd/sync/sync_function_docs.py --write-function-index-only`

## Runtime framework (`core_*`)

| Function | Documentation |
|----------|-----------------|
| `core_apply_steganography` | [Apply Steganography.md](../Functions/Shell/Apply%20Steganography.md) |
| `core_check_db_lock` | [Check Db Lock.md](../Functions/Shell/Check%20Db%20Lock.md) |
| `core_check_fda` | [Check Fda.md](../Functions/Shell/Check%20Fda.md) |
| `core_check_perms` | [Check Perms.md](../Functions/Shell/Check%20Perms.md) |
| `core_debug_print` | [Debugger.md](../Functions/Shell/Debugger.md) |
| `core_display_help` | [Display Help.md](../Functions/Shell/Display%20Help.md) |
| `core_dns_safe_encode` | [Dns Safe Encode.md](../Functions/Shell/Dns%20Safe%20Encode.md) |
| `core_emit_error_json_stdout` | [Emit Error Json Stdout.md](../Functions/Shell/Emit%20Error%20Json%20Stdout.md) |
| `core_encode_output` | [Encode Output.md](../Functions/Shell/Encode%20Output.md) |
| `core_encrypt_output` | [Encrypt Output.md](../Functions/Shell/Encrypt%20Output.md) |
| `core_exec_cmd` | [Exec Cmd.md](../Functions/Shell/Exec%20Cmd.md) |
| `core_exec_cmd_construct` | [Exec Cmd Construct.md](../Functions/Shell/Exec%20Cmd%20Construct.md) |
| `core_exec_cmd_herestring` | [Exec Cmd Herestring.md](../Functions/Shell/Exec%20Cmd%20Herestring.md) |
| `core_exec_keychain_obfuscated` | [Exec Keychain Obfuscated.md](../Functions/Shell/Exec%20Keychain%20Obfuscated.md) |
| `core_execute_function` | [Execute Function.md](../Functions/Shell/Execute%20Function.md) |
| `core_execute_main_logic` | [Execute Main Logic.md](../Functions/Shell/Execute%20Main%20Logic.md) |
| `core_exfil_dns` | [Exfil Dns.md](../Functions/Shell/Exfil%20Dns.md) |
| `core_exfil_http_get` | [Exfil Http Get.md](../Functions/Shell/Exfil%20Http%20Get.md) |
| `core_exfil_http_post` | [Exfil Http Post.md](../Functions/Shell/Exfil%20Http%20Post.md) |
| `core_exfiltrate_data` | [Exfiltrate Data.md](../Functions/Shell/Exfiltrate%20Data.md) |
| `core_extract_domain` | [Extract Domain.md](../Functions/Shell/Extract%20Domain.md) |
| `core_extract_domain_from_url` | [Extract Domain From Url.md](../Functions/Shell/Extract%20Domain%20From%20Url.md) |
| `core_extract_steganography` | [Extract Steganography.md](../Functions/Shell/Extract%20Steganography.md) |
| `core_format_as_csv` | [Format As Csv.md](../Functions/Shell/Format%20As%20Csv.md) |
| `core_format_as_json` | [Format As Json.md](../Functions/Shell/Format%20As%20Json.md) |
| `core_format_output` | [Format Output.md](../Functions/Shell/Format%20Output.md) |
| `core_generate_encryption_key` | [Generate Encryption Key.md](../Functions/Shell/Generate%20Encryption%20Key.md) |
| `core_generate_job_id` | [Generate Job Id.md](../Functions/Shell/Generate%20Job%20Id.md) |
| `core_generate_json_payload` | [Generate Json Payload.md](../Functions/Shell/Generate%20Json%20Payload.md) |
| `core_get_content_type` | [Get Content Type.md](../Functions/Shell/Get%20Content%20Type.md) |
| `core_get_log_filename` | [Get Log Filename.md](../Functions/Shell/Get%20Log%20Filename.md) |
| `core_get_timestamp` | [Get Timestamp.md](../Functions/Shell/Get%20Timestamp.md) |
| `core_get_user_agent` | [Get User Agent.md](../Functions/Shell/Get%20User%20Agent.md) |
| `core_handle_error` | [Error Handler.md](../Functions/Shell/Error%20Handler.md) |
| `core_json_escape_minimal` | [Json Escape Minimal.md](../Functions/Shell/Json%20Escape%20Minimal.md) |
| `core_log_output` | [Log Output.md](../Functions/Shell/Log%20Output.md) |
| `core_main` | [Main.md](../Functions/Shell/Main.md) |
| `core_normalize_uri` | [Normalize Uri.md](../Functions/Shell/Normalize%20Uri.md) |
| `core_parse_args` | [Parse Args.md](../Functions/Shell/Parse%20Args.md) |
| `core_prepare_exfil_data` | [Prepare Exfil Data.md](../Functions/Shell/Prepare%20Exfil%20Data.md) |
| `core_prepare_proxy_arg` | [Prepare Proxy Arg.md](../Functions/Shell/Prepare%20Proxy%20Arg.md) |
| `core_process_output` | [Process Output.md](../Functions/Shell/Process%20Output.md) |
| `core_send_key_via_dns` | [Send Key Via Dns.md](../Functions/Shell/Send%20Key%20Via%20Dns.md) |
| `core_steganography` | [Steganography.md](../Functions/Shell/Steganography.md) |
| `core_transform_output` | [Transform Output.md](../Functions/Shell/Transform%20Output.md) |
| `core_url_safe_encode` | [Url Safe Encode.md](../Functions/Shell/Url%20Safe%20Encode.md) |
| `core_validate_command` | [Validate Command.md](../Functions/Shell/Validate%20Command.md) |
| `core_validate_domain` | [Validate Domain.md](../Functions/Shell/Validate%20Domain.md) |
| `core_validate_input` | [Input Validation.md](../Functions/Shell/Input%20Validation.md) |
| `core_validate_parsed_args` | [Validate Parsed Args.md](../Functions/Shell/Validate%20Parsed%20Args.md) |

---

Last modified: 2026-05-15
Version: 1.0.0
