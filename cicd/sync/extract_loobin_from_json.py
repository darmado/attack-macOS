#!/usr/bin/env python3
"""
Extract one LOOBin record from attackmacos/standby/LOOBins/loobins.json into a
per-binary YAML file for convert_loobin_to_procedure.py.

The JSON catalog matches the shape used on https://www.loobins.io/ (same project
as https://github.com/infosecB/LOOBins). Refresh JSON first:

  bash cicd/sync/sync_loobins_json.sh

Usage (from repo root):
  python3 cicd/sync/extract_loobin_from_json.py log
  python3 cicd/sync/extract_loobin_from_json.py dns-sd --stdout
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import yaml

_REPO = Path(__file__).resolve().parents[2]
_DEFAULT_JSON = _REPO / "attackmacos" / "standby" / "LOOBins" / "loobins.json"
_DEFAULT_OUT_DIR = _REPO / "attackmacos" / "standby" / "LOOBins"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "binary",
        help="LOOBin name field to extract (e.g. log, defaults, dns-sd)",
    )
    parser.add_argument(
        "--json-path",
        type=Path,
        default=_DEFAULT_JSON,
        help=f"Path to loobins.json (default: {_DEFAULT_JSON})",
    )
    parser.add_argument(
        "--out-dir",
        type=Path,
        default=_DEFAULT_OUT_DIR,
        help=f"Directory for <name>.yml (default: {_DEFAULT_OUT_DIR})",
    )
    parser.add_argument(
        "--stdout",
        action="store_true",
        help="Print YAML to stdout instead of writing a file",
    )
    args = parser.parse_args()

    if not args.json_path.is_file():
        print(f"Error: JSON not found: {args.json_path}", file=sys.stderr)
        print("Run: bash cicd/sync/sync_loobins_json.sh", file=sys.stderr)
        return 1

    with args.json_path.open(encoding="utf-8") as f:
        catalog = json.load(f)
    if not isinstance(catalog, list):
        print("Error: expected loobins.json to be a JSON array", file=sys.stderr)
        return 1

    want = args.binary.strip()
    found = None
    for entry in catalog:
        if isinstance(entry, dict) and entry.get("name") == want:
            found = entry
            break
    if found is None:
        names = sorted(
            e.get("name")
            for e in catalog
            if isinstance(e, dict) and isinstance(e.get("name"), str)
        )
        print(f"Error: no LOOBin named {want!r} in {args.json_path}", file=sys.stderr)
        print(f"Hint: {len(names)} entries; examples: {', '.join(names[:12])}…", file=sys.stderr)
        return 1

    text = yaml.dump(
        found,
        default_flow_style=False,
        sort_keys=False,
        allow_unicode=True,
        width=120,
    )

    if args.stdout:
        sys.stdout.write(text)
        return 0

    args.out_dir.mkdir(parents=True, exist_ok=True)
    out_path = args.out_dir / f"{want}.yml"
    out_path.write_text(text, encoding="utf-8")
    print(f"Wrote {out_path.relative_to(_REPO)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
