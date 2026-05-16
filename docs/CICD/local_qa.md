# Local QA (before a pull request)

## Purpose

List the local checks contributors run before opening a pull request so CI and maintainer review see fewer avoidable failures.

GitHub Actions are optional later. Today, contributors run the same checks locally so maintainers see fewer surprise failures in review.

## One command

From the repository root (after `pip install pyyaml jsonschema` or your `cicd/venv`):

```bash
sh cicd/qa/run_local_qa.sh
```

What it does:

1. **`audit_procedure_inventory.py --strict`** — every `attackmacos/core/config/*.yml` has a matching built shell under `attackmacos/ttp/<tactic>/shell/<procedure_name>.sh`, and orphan scripts are only those allowlisted in `cicd/audit/inventory_allowlist.txt`.
2. **`procedure_shell.py --validate`** on **each** `core/config/*.yml` — schema and builder rules without writing scripts.
3. **`audit_jxa.py --full`** — static JXA rules on all `attackmacos/ttp/**/jxa/*.js`.
4. **On macOS only** — `procedure_jxa.py --self-test` (osascript smoke). Set `SKIP_JXA_SELFTEST=1` to skip. On Linux, step 4 is skipped automatically.

Override Python: `PYTHON=/path/to/python3 sh cicd/qa/run_local_qa.sh`.

## Where new work lives before `core/config/` (human gate)

| Location | Role |
|----------|------|
| `attackmacos/standby/LOOBins/` | **Queue:** upstream JSON snapshot (`loobins.json`), per-binary LOOBin YAML, `TTP_OVERLAY.yml`, and tooling output — **not** production procedures until you promote. |
| `attackmacos/standby/LOOBins/staging/` | **Draft** procedure YAML from `convert_loobin_to_procedure.py` — edit `ttp_id`, intent, functions, then **you** copy or merge into `attackmacos/core/config/`. |
| `attackmacos/core/config/` | **Production** procedure definitions consumed by the builders. |

The **human gate** is intentional: automated conversion does not replace MITRE verification, detection text, or OPSEC review. See [Add a Procedure from MITRE ATT&CK.md](../Guides/How%20To/Add%20a%20Procedure%20from%20MITRE%20ATT&CK.md) and [LOOBins_to_Procedure_Mapping.md](LOOBins_to_Procedure_Mapping.md).

## Related

- [cicd/README.md](../../cicd/README.md) — full tool index and quick start.
- [attackmacos/standby/README.md](../../attackmacos/standby/README.md) — LOOBins sync and convert flow.
- [test_script_options.md](test_script_options.md) — optional deeper script checks.
