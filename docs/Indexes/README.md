# Documentation indexes

## Purpose

Describe the human-maintained **index** pages under `docs/Indexes/` (procedures, tools, global variables, functions) and how they relate to automation and runtime sources.

## Notes

- **Git path casing:** The repository uses lowercase **`docs/`**. On a default case-insensitive macOS volume, some tools may display the same folder as `Docs/`; it is still one directory.
- **Source of truth:** Runtime shell behavior is defined in **`attackmacos/core/base/base.sh`**. **`attackmacos/core/global/variables.yml`** documents shared `CMD_*` defaults. **`attackmacos/core/global/functions.yml`** lists `core_*` names for diffing (the builder does not load it yet). Per-function narrative is under **`docs/Functions/Shell/`** (see **`cicd/sync/sync_function_docs.py`**).
- **Indexes vs machine export:** Markdown tables are for navigation. If you add CI-driven coverage, prefer generating **`docs/Indexes/*.md`** (or a sibling JSON/YAML) from `base.sh` / inventory scripts so tables do not drift.

## Index files

| File | Role |
|------|------|
| [Function Index.md](Function%20Index.md) | Auto-generated table of `core_*` names from `functions.yml` + links to `docs/Functions/Shell/` (see `cicd/sync/sync_function_docs.py --write-function-index-only`). |
| [Global Variables Index.md](Global%20Variables%20Index.md) | Overview of globals patterns. |
| [Procedure Index.md](Procedure%20Index.md) | Procedure / technique coverage map. |
| [Tool Index.md](Tool%20Index.md) | Native tools / LOLBins references. |

## References

- `docs/Standards/README.md`
- `attackmacos/core/global/variables.yml`
- `attackmacos/core/global/functions.yml`
- `cicd/sync/sync_function_docs.py`

---

Last modified: 2026-05-15  
Last modified by: Documentation maintainers  
Version: 1.0.0
