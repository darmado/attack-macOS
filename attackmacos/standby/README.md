# Standby — upstream staging and conversion

Use this area for **third-party catalogs** and **pre-schema** artifacts before promoting YAML into `attackmacos/core/config/` as full procedures.

**Queue vs production:** treat `attackmacos/standby/` (especially `standby/LOOBins/`) as the **incoming queue** — nothing here is a shipped procedure until a maintainer moves YAML into `attackmacos/core/config/`, fixes MITRE metadata, and runs the builders. That promotion step is the **human gate** (review, legal/compliance context, and ATT&CK alignment are not automated).

## Status (LOOBins YAML → config)

Per-binary `*.yml` files here were **bulk-promoted** to `attackmacos/core/config/` using `convert_loobin_to_procedure.py --promote-all` with MITRE mapping from `TTP_OVERLAY.yml` / built-in inference (`cicd/convert/convert_loobin_to_procedure.py`). **`screencapture`** and **`security`** were skipped (superseded by `screen_capture.yml` and `keychains.yml`). Refine individual techniques in config YAML as needed.

## LOOBins (`attackmacos/standby/LOOBins/`)

| Artifact | Role |
|----------|------|
| `loobins.json` | Full catalog snapshot from [LOOBins](https://www.loobins.io/) (synced via script below). |
| `*.yml` | Per-binary snippets maintained alongside or derived from the project (examples: `defaults.yml`, `ioreg.yml`). |
| `staging/` | Output from `cicd/convert/convert_loobin_to_procedure.py` — **draft** procedure YAML for human review (not production until moved + `ttp_id` fixed). |

### Sync latest JSON from LOOBins

From the repository root:

```bash
python3 cicd/fetch/fetch_loobins.py catalog
```

Fetches `https://www.loobins.io/loobins.json` into `attackmacos/standby/LOOBins/loobins.json` (urllib; no shell). Override the URL:

```bash
python3 cicd/fetch/fetch_loobins.py catalog --url 'https://www.loobins.io/loobins.json'
```

The catalog is the same “Living off the Orchard” content indexed on [loobins.io/binaries](https://www.loobins.io/binaries/) and maintained in [infosecB/LOOBins](https://github.com/infosecB/LOOBins).

### Get one binary as YAML (pick one path)

**A — From synced JSON (good when you already ran `fetch_loobins.py catalog`):**

```bash
python3 cicd/extract/extract_loobin_from_json.py <name>
# writes attackmacos/standby/LOOBins/<name>.yml
```

`<name>` must match the JSON `name` field (e.g. `log`, `dns-sd`, `sw_vers`).

**B — From GitHub raw (canonical per-file YAML):**

```bash
python3 cicd/fetch/fetch_loobins.py binary <name>
# downloads https://raw.githubusercontent.com/infosecB/LOOBins/main/LOOBins/<name>.yml
```

Use the exact upstream filename (case-sensitive), e.g. `GetFileInfo`, not `getfileinfo`.

### Convert one LOOBin YAML → procedure-shaped YAML

Per-binary files (for example `attackmacos/standby/LOOBins/defaults.yml`) can be converted toward `attackmacos/core/schemas/procedure.schema.json`:

```bash
cicd/venv/bin/python3 cicd/convert/convert_loobin_to_procedure.py attackmacos/standby/LOOBins/defaults.yml
```

Draft output is written to `attackmacos/standby/LOOBins/staging/<binary>.yml`. Edit **`ttp_id`** (placeholder `T9999`), **`intent`**, and functions, then copy or merge into `attackmacos/core/config/` and run **`python3 cicd/build/procedure_shell.py`**.

**Batch (preferred — same tool, discoverable via `--help` pattern):**

```bash
cicd/venv/bin/python3 cicd/convert/convert_loobin_to_procedure.py --all-standby
```

This processes every `*.yml` in `attackmacos/standby/LOOBins/` (skips failures per file with a message). No separate `stage_all_loobins.sh` — logic stays in the converter.

Fallback (shell loop from repo root):

```bash
for f in attackmacos/standby/LOOBins/*.yml; do
  cicd/venv/bin/python3 cicd/convert/convert_loobin_to_procedure.py "$f" || exit 1
done
```

Field mapping reference: [docs/CICD/LOOBins_to_Procedure_Mapping.md](../../docs/CICD/LOOBins_to_Procedure_Mapping.md).

### Relation to “add a TTP”

1. Fetch catalog (optional) → `python3 cicd/fetch/fetch_loobins.py catalog`.  
2. Obtain per-binary LOOBin YAML in `standby/LOOBins/` — copy from your notes, **`extract_loobin_from_json.py`**, or **`fetch_loobins.py binary <name>`**.  
3. Convert → staging procedure YAML (`convert_loobin_to_procedure.py`).  
4. Finish metadata + MITRE IDs → move to `attackmacos/core/config/`.  
5. Build (`python3 cicd/build/procedure_shell.py …`) — **lint is already included** (`sh -n`, same as `--lint-local`).  
6. Before a PR, run **`sh cicd/qa/run_local_qa.sh`** (see `cicd/README.md`). GitHub Actions can wrap the same steps later.

Future UI (“sync LOOBins to my project”) can wrap steps 1–5.

## Atomic Red Team (`attackmacos/standby/AtomicRedTeam/`)

| Artifact | Role |
|----------|------|
| `macos-index.yaml` | Cached upstream index downloaded from Atomic Red Team. |
| `index_summary.json` | Counts from the last **`fetch_atomic_red_team.py --all`** run. |
| `atomics/` | Per-technique YAML with only macOS-supported tests (`python3 cicd/fetch/fetch_atomic_red_team.py --all`; **gitignored**). Files: `atomics/<TTP>/<TTP>_<mitre_name>.yaml`. |

```sh
python3 cicd/fetch/fetch_atomic_red_team.py --all
python3 cicd/fetch/fetch_atomic_red_team.py --tactic discovery --format table
python3 cicd/fetch/fetch_atomic_red_team.py --local --ttp T1049 --format json
```

Details and license note: [AtomicRedTeam/README.md](AtomicRedTeam/README.md). Porting guide: [docs/CICD/ART_to_Procedure.md](../../docs/CICD/ART_to_Procedure.md).

## Other folders

- **`jxa/`** — JXA utilities and experiments (not all are built procedures).  
- **`shell/`** — Misc shell drafts.
