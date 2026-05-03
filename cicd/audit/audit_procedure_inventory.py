#!/usr/bin/env python3
"""
Cross-check attackmacos/core/config/*.yml against built shell scripts under
attackmacos/ttp/<tactic>/shell/<procedure_name>.sh.

Exit 0 by default (report only). Use --strict to exit 1 when there are orphans
or missing builds.

Author: attack-macOS maintainers
License: Apache 2.0
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    print("Error: PyYAML required (pip install pyyaml)", file=sys.stderr)
    sys.exit(2)

_CICD_AUDIT_DIR = Path(__file__).resolve().parent
_REPO_ROOT = _CICD_AUDIT_DIR.parent.parent
_CONFIG_DIR = _REPO_ROOT / "attackmacos" / "core" / "config"
_TTP_ROOT = _REPO_ROOT / "attackmacos" / "ttp"

_TACTIC_MAP = {
    "Discovery": "discovery",
    "Defense Evasion": "defense_evasion",
    "Persistence": "persistence",
    "Collection": "collection",
    "Credential Access": "credential_access",
    "Execution": "execution",
    "Initial Access": "initial_access",
    "Lateral Movement": "lateral_movement",
    "Privilege Escalation": "privilege_escalation",
    "Command and Control": "command_and_control",
    "Exfiltration": "exfiltration",
    "Impact": "impact",
}


def tactic_directory(tactic: str) -> str:
    t = (tactic or "").strip()
    return _TACTIC_MAP.get(t, t.lower().replace(" ", "_"))


def load_procedure_meta(path: Path) -> tuple[str, str, Path] | None:
    """Return (procedure_name, tactic, yaml_path) or None if unusable."""
    try:
        with path.open(encoding="utf-8") as f:
            data = yaml.safe_load(f)
    except (OSError, yaml.YAMLError) as e:
        print(f"WARN: skip {path}: {e}", file=sys.stderr)
        return None
    if not isinstance(data, dict):
        return None
    name = data.get("procedure_name")
    tactic = data.get("tactic")
    if not name or not tactic:
        return None
    return str(name), str(tactic), path


def expected_shell_path(procedure_name: str, tactic: str) -> Path:
    return _TTP_ROOT / tactic_directory(tactic) / "shell" / f"{procedure_name}.sh"


def load_allowlist(path: Path) -> set[str]:
    if not path.is_file():
        return set()
    out: set[str] = set()
    for line in path.read_text(encoding="utf-8").splitlines():
        s = line.strip()
        if not s or s.startswith("#"):
            continue
        out.add(s)
    return out


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--strict",
        action="store_true",
        help="Exit 1 if any shell script has no matching YAML or any YAML has no expected .sh",
    )
    parser.add_argument(
        "--no-inventory-allowlist",
        action="store_true",
        help="With --strict, ignore cicd/audit/inventory_allowlist.txt (fail on any orphan shell)",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Print machine-readable summary as JSON (stdout)",
    )
    args = parser.parse_args()
    allow_path = _CICD_AUDIT_DIR / "inventory_allowlist.txt"
    allow_stems = set() if args.no_inventory_allowlist else load_allowlist(allow_path)

    yml_files = sorted(_CONFIG_DIR.glob("*.yml"))
    from_yaml: dict[str, tuple[str, str, Path]] = {}
    yaml_stem_mismatch: list[tuple[Path, str]] = []

    for ypath in yml_files:
        meta = load_procedure_meta(ypath)
        if meta is None:
            continue
        proc, tactic, src = meta
        from_yaml[proc] = (tactic, str(src.relative_to(_REPO_ROOT)), src)
        if ypath.stem != proc:
            yaml_stem_mismatch.append((ypath, proc))

    shell_paths = sorted(_TTP_ROOT.glob("**/shell/*.sh"))
    from_shell = {p.stem: p for p in shell_paths}

    missing_sh: list[tuple[str, str, str]] = []
    for proc, (tactic, rel, _) in sorted(from_yaml.items()):
        exp = expected_shell_path(proc, tactic)
        if not exp.is_file():
            alt = from_shell.get(proc)
            if alt is not None and alt.resolve() != exp.resolve():
                missing_sh.append(
                    (
                        proc,
                        rel,
                        f"missing {exp.relative_to(_REPO_ROOT)}; found {alt.relative_to(_REPO_ROOT)}",
                    )
                )
            else:
                missing_sh.append((proc, rel, f"missing {exp.relative_to(_REPO_ROOT)}"))

    orphan_sh: list[Path] = []
    orphan_sh_allowed: list[Path] = []
    for stem, path in sorted(from_shell.items()):
        if stem not in from_yaml:
            if stem in allow_stems:
                orphan_sh_allowed.append(path)
            else:
                orphan_sh.append(path)

    if args.json:
        import json

        out = {
            "config_yml_count": len(yml_files),
            "procedures_from_yaml": len(from_yaml),
            "shell_scripts_under_ttp": len(shell_paths),
            "missing_expected_shell": [
                {"procedure_name": a, "yaml": b, "detail": c} for a, b, c in missing_sh
            ],
            "orphan_shell_no_yaml_procedure_name": [
                str(p.relative_to(_REPO_ROOT)) for p in orphan_sh
            ],
            "orphan_shell_allowlisted": [
                str(p.relative_to(_REPO_ROOT)) for p in orphan_sh_allowed
            ],
            "yaml_filename_stem_differs_from_procedure_name": [
                {"file": str(p.relative_to(_REPO_ROOT)), "procedure_name": proc}
                for p, proc in yaml_stem_mismatch
            ],
        }
        print(json.dumps(out, indent=2))
    else:
        print(f"Config dir: {_CONFIG_DIR.relative_to(_REPO_ROOT)}")
        print(f"YAML files: {len(yml_files)}; procedures parsed: {len(from_yaml)}")
        print(f"Shell under ttp/**/shell: {len(shell_paths)}")
        if yaml_stem_mismatch:
            print("\n--- YAML filename != procedure_name (informational) ---")
            for p, proc in yaml_stem_mismatch:
                print(f"  {p.name} -> procedure_name: {proc}")
        if missing_sh:
            print("\n--- Expected shell missing (from YAML tactic + procedure_name) ---")
            for proc, rel, detail in missing_sh:
                print(f"  {proc}  ({rel})\n    {detail}")
        if orphan_sh_allowed:
            print("\n--- Orphan shell scripts (allowlisted; see inventory_allowlist.txt) ---")
            for p in orphan_sh_allowed:
                print(f"  {p.relative_to(_REPO_ROOT)}")
        if orphan_sh:
            print("\n--- Shell scripts with no matching procedure_name in any YAML ---")
            for p in orphan_sh:
                print(f"  {p.relative_to(_REPO_ROOT)}")
        if not missing_sh and not orphan_sh:
            extra = ""
            if orphan_sh_allowed:
                extra = f" ({len(orphan_sh_allowed)} allowlisted orphan(s))"
            if not yaml_stem_mismatch:
                print(f"\nOK: no missing expected shells and no unlisted orphan shell scripts.{extra}")
            else:
                print(
                    f"\nOK: no missing expected shells and no unlisted orphan shell scripts.{extra}"
                    "\n    (YAML filename / procedure_name mismatches listed above.)"
                )

    bad = bool(missing_sh or orphan_sh)
    if args.strict and bad:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
