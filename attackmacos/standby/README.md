# Standby — upstream staging and conversion

Use this area for **third-party catalogs** and **pre-schema** artifacts before promoting YAML into `attackmacos/core/config/` as full procedures.

## Status (LOOBins YAML → config)

Per-binary `*.yml` files here were **bulk-promoted** to `attackmacos/core/config/` using `convert_loobin_to_procedure.py --promote-all` with MITRE mapping from `TTP_OVERLAY.yml` / built-in inference (`cicd/sync/convert_loobin_to_procedure.py`). **`screencapture`** and **`security`** were skipped (superseded by `screen_capture.yml` and `keychains.yml`). Refine individual techniques in config YAML as needed.

## LOOBins (`attackmacos/standby/LOOBins/`)

| Artifact | Role |
|----------|------|
| `loobins.json` | Full catalog snapshot from [LOOBins](https://www.loobins.io/) (synced via script below). |
| `*.yml` | Per-binary snippets maintained alongside or derived from the project (examples: `defaults.yml`, `ioreg.yml`). |
| `staging/` | Output from `cicd/sync/convert_loobin_to_procedure.py` — **draft** procedure YAML for human review (not production until moved + `ttp_id` fixed). |

### Sync latest JSON from LOOBins

From the repository root:

```bash
bash cicd/sync/sync_loobins_json.sh
```

Uses `curl` to fetch `https://www.loobins.io/loobins.json` into `attackmacos/standby/LOOBins/loobins.json`. Override the URL:

```bash
LOOBINS_JSON_URL='https://www.loobins.io/loobins.json' bash cicd/sync/sync_loobins_json.sh
```

### Convert one LOOBin YAML → procedure-shaped YAML

Per-binary files (for example `attackmacos/standby/LOOBins/defaults.yml`) can be converted toward `attackmacos/core/schemas/procedure.schema.json`:

```bash
cicd/venv/bin/python3 cicd/sync/convert_loobin_to_procedure.py attackmacos/standby/LOOBins/defaults.yml
```

Draft output is written to `attackmacos/standby/LOOBins/staging/<binary>.yml`. Edit **`ttp_id`** (placeholder `T9999`), **`intent`**, and functions, then copy or merge into `attackmacos/core/config/` and run **`python3 cicd/build/build_shell_procedure.py`**.

**Batch (preferred — same tool, discoverable via `--help` pattern):**

```bash
cicd/venv/bin/python3 cicd/sync/convert_loobin_to_procedure.py --all-standby
```

This processes every `*.yml` in `attackmacos/standby/LOOBins/` (skips failures per file with a message). No separate `stage_all_loobins.sh` — logic stays in the converter.

Fallback (shell loop from repo root):

```bash
for f in attackmacos/standby/LOOBins/*.yml; do
  cicd/venv/bin/python3 cicd/sync/convert_loobin_to_procedure.py "$f" || exit 1
done
```

Field mapping reference: [docs/CICD/LOOBins_to_Procedure_Mapping.md](../../docs/CICD/LOOBins_to_Procedure_Mapping.md).

### Relation to “add a TTP”

1. Sync JSON (optional) → refresh local catalog.  
2. Convert per-binary YAML → staging procedure YAML.  
3. Finish metadata + MITRE IDs → move to `attackmacos/core/config/`.  
4. Build (`python3 cicd/build/build_shell_procedure.py`) — **lint is already included** (`sh -n`, same as `--lint-local`).  

Future UI (“sync LOOBins to my project”) can wrap steps 1–4.

## Other folders

- **`jxa/`** — JXA utilities and experiments (not all are built procedures).  
- **`shell/`** — Misc shell drafts.
