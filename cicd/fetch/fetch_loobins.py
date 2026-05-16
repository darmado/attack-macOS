#!/usr/bin/env python3
"""
Name: fetch_loobins.py
Author: @darmado | https://x.com/darmad0
License: Apache 2.0
Repository: https://github.com/armadoinc/attack-macOS
Description: Fetch LOOBins catalog JSON and/or per-binary YAML into attackmacos standby.

Examples:
  python3 cicd/fetch/fetch_loobins.py catalog
  python3 cicd/fetch/fetch_loobins.py catalog --url https://www.loobins.io/loobins.json
  python3 cicd/fetch/fetch_loobins.py binary log
  python3 cicd/fetch/fetch_loobins.py binary GetFileInfo --branch main

Security conventions for CLI tools: docs/CICD/python_cli_security.md
"""

from __future__ import annotations

import argparse
import sys
import urllib.error
import urllib.request
from pathlib import Path

_CICD_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(_CICD_ROOT))
import validate_input  # noqa: E402

REPO = Path(__file__).resolve().parents[2]

LOOBINS_CATALOG_DEFAULT_URL = "https://www.loobins.io/loobins.json"
LOOBINS_CATALOG_DEFAULT_OUT = REPO / "attackmacos" / "standby" / "LOOBins" / "loobins.json"

LOOBINS_GITHUB_RAW_YAML_FMT = "https://raw.githubusercontent.com/infosecB/LOOBins/{branch}/LOOBins/{name}.yml"
LOOBINS_BINARY_DEFAULT_BRANCH = "main"
LOOBINS_BINARY_DEFAULT_OUT_DIR = REPO / "attackmacos" / "standby" / "LOOBins"


def fetch_bytes(url: str, *, user_agent: str, accept: str) -> bytes:
    req = urllib.request.Request(
        url,
        headers={
            "User-Agent": user_agent,
            "Accept": accept,
        },
    )
    with urllib.request.urlopen(req, timeout=120) as resp:
        return resp.read()


def cmd_catalog(args: argparse.Namespace) -> int:
    merged = (args.url or LOOBINS_CATALOG_DEFAULT_URL).strip()
    try:
        ok_url = validate_input.validate_http_https_url_with_host(merged)
    except argparse.ArgumentTypeError as exc:
        print(f"Error: invalid catalog URL (--url): {exc}", file=sys.stderr)
        return 1

    out = args.out or LOOBINS_CATALOG_DEFAULT_OUT
    try:
        body = fetch_bytes(
            ok_url,
            user_agent="attack-macOS-fetch-loobins",
            accept="application/json,text/plain,*/*",
        )
    except urllib.error.HTTPError as exc:
        print(f"HTTP error downloading {merged}: {exc}", file=sys.stderr)
        return 1
    except urllib.error.URLError as exc:
        print(f"Network error downloading {merged}: {exc}", file=sys.stderr)
        return 1

    out.parent.mkdir(parents=True, exist_ok=True)
    tmp = out.with_suffix(out.suffix + ".part")
    tmp.write_bytes(body)
    tmp.replace(out)
    print(f"Wrote {out} ({len(body)} bytes)")
    return 0


def cmd_binary(args: argparse.Namespace) -> int:
    stem = args.name
    branch_raw = args.branch or LOOBINS_BINARY_DEFAULT_BRANCH
    try:
        branch_ok = validate_input.validate_git_ref_fragment(branch_raw)
    except argparse.ArgumentTypeError as exc:
        print(f"Error: invalid --branch: {exc}", file=sys.stderr)
        return 1

    url = LOOBINS_GITHUB_RAW_YAML_FMT.format(branch=branch_ok, name=stem)
    try:
        ok_url = validate_input.validate_http_https_url_with_host(url)
    except argparse.ArgumentTypeError:
        print("Error: constructed download URL invalid.", file=sys.stderr)
        return 1

    out_dir = args.out_dir or LOOBINS_BINARY_DEFAULT_OUT_DIR

    try:
        body = fetch_bytes(
            ok_url,
            user_agent="attack-macOS-fetch-loobins",
            accept="text/yaml,text/plain,*/*",
        )
    except urllib.error.HTTPError as exc:
        print(f"HTTP error downloading {url}: {exc}", file=sys.stderr)
        print("Check that name matches the LOOBins YAML filename on GitHub (case-sensitive).", file=sys.stderr)
        return 1
    except urllib.error.URLError as exc:
        print(f"Network error downloading {url}: {exc}", file=sys.stderr)
        return 1

    out_dir.mkdir(parents=True, exist_ok=True)
    out = out_dir / f"{stem}.yml"
    tmp = out.with_suffix(".yml.part")
    tmp.write_bytes(body)
    tmp.replace(out)
    print(f"Wrote {out}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Fetch LOOBins catalog JSON or one upstream binary YAML into standby.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Subcommands choose what to fetch (run only what you need):\n"
            "  catalog — full loobins.json (refresh often).\n"
            "  binary  — one canonical .yml from GitHub (when you want upstream file parity).\n"
            "See docs/CICD/python_cli_security.md for input validation expectations."
        ),
    )
    subs = parser.add_subparsers(dest="command", required=True)

    cat = subs.add_parser("catalog", help="Download full LOOBins JSON catalog")
    cat.add_argument("--url", default=None, help=f"Catalog JSON URL (default: {LOOBINS_CATALOG_DEFAULT_URL})")
    cat.add_argument(
        "--out",
        type=Path,
        default=None,
        help=f"Output JSON path (default: {LOOBINS_CATALOG_DEFAULT_OUT})",
    )
    cat.set_defaults(func=cmd_catalog)

    yn = subs.add_parser("binary", help="Download one LOOBin YAML from GitHub raw")
    yn.add_argument(
        "name",
        type=validate_input.validate_loobin_binary_stem,
        help="LOOBin file stem (case-sensitive, e.g. log, GetFileInfo)",
    )
    yn.add_argument("--branch", default=None, help=f"LOOBins Git branch/tag (default: {LOOBINS_BINARY_DEFAULT_BRANCH})")
    yn.add_argument(
        "--out-dir",
        type=Path,
        default=None,
        help=f"Output directory (default: {LOOBINS_BINARY_DEFAULT_OUT_DIR})",
    )
    yn.set_defaults(func=cmd_binary)

    args = parser.parse_args()
    return int(args.func(args))


if __name__ == "__main__":
    raise SystemExit(main())
