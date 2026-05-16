# build_jxa_procedure.py

Builds JXA (JavaScript for Automation) procedures from the same YAML schema as the shell builder, merged with **`attackmacos/core/base/base.js`**.

## Purpose

- **ObjC bridge first:** Generated scripts use `ObjC.import('Foundation')`, stdout via `NSFileHandle`, and argv via `NSProcessInfo`—aligned with [JXA Script Blueprint.md](../Functions/Shell/JXA%20Script%20Blueprint.md) and **`cicd/audit/audit_jxa.py`** (no `doShellScript`, `includeStandardAdditions`, `NSTask`, etc.).
- **Parity intent:** Same `procedure_name`, tactic, arguments, and `execute_function` wiring as shell procedures, but only functions whose `language` list includes **`jxa`** (or `javascript`) are emitted into the `.js` output.

## When YAML is built

- At least one function under `procedure.functions` must include **`jxa`** in `language`.
- Function `code` must be valid JXA: typically full `function technique_name() { ... }` bodies that return strings (the template concatenates return values and writes them with `writeStdout`).

**Mixed shell + JXA in one YAML:** The shell builder still emits **all** function bodies into `.sh`. Do not put raw JXA into a function that is only meant for shell unless you also maintain a **separate YAML** for the JXA twin (recommended until the shell builder skips non-shell languages).

## Usage

```bash
# Schema validation only (same jsonschema as build_shell_procedure)
python3 cicd/build/procedure_jxa.py --validate attackmacos/core/config/<name>.yml

# Build one procedure (writes attackmacos/ttp/<tactic>/jxa/<procedure_name>.js)
python3 cicd/build/procedure_jxa.py attackmacos/core/config/<name>.yml
python3 cicd/build/procedure_jxa.py --force attackmacos/core/config/<name>.yml

# All config YAMLs that declare at least one JXA function
python3 cicd/build/procedure_jxa.py --all
python3 cicd/build/procedure_jxa.py --all --force

# CI fixture: temp YAML copy, build, osascript --hello, delete artifact
python3 cicd/build/procedure_jxa.py --self-test
```

## Post-build checks

1. **`osascript -l JavaScript <out>.js -h`** — must exit 0 (smoke parse/run).
2. **`python3 cicd/audit/audit_jxa.py <out>.js`** — static rules for ObjC-first JXA.

Failures remove the incomplete output file (same idea as `sh -n` for shell builds).

## Related files

| Path | Role |
|------|------|
| `attackmacos/core/base/base.js` | Template with placeholders (`PLACEHOLDER_*`) |
| `cicd/build/procedure_shell.py` | Shared: `read_yaml`, `validate_yaml`, `ProcedureData`, `get_tactic_directory`, GUID bump |
| `cicd/audit/audit_jxa.py` | Post-build static audit |
| `cicd/build/fixtures/jxa_procedure_minimal.yml` | `--self-test` input |

## Optional: CI snippet

```yaml
- name: JXA builder self-test (macOS)
  run: python3 cicd/build/procedure_jxa.py --self-test
```

Use a **macOS** runner; Linux CI cannot execute `osascript`.
