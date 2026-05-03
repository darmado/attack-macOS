#!/usr/bin/env python3
"""
Static audit for JXA under attackmacos/ttp/**/jxa/*.js

Enforces project rules: native macOS automation via ObjC bridge, no subprocess shell-out
patterns that LLM-authored JXA often regress into.

Usage:
  python3 cicd/audit/audit_jxa.py                 # default: attackmacos/ttp/collection/jxa/*.js only
  python3 cicd/audit/audit_jxa.py --full          # all attackmacos/ttp/**/jxa/*.js (legacy may fail)
  python3 cicd/audit/audit_jxa.py --verbose path/to/file.js

Exit 0 if clean; exit 1 on any violation.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


# Lines whose first non-whitespace is // are ignored for substring rules (doc only).
def _strip_line_comments(text: str) -> str:
    out = []
    for line in text.splitlines():
        s = line.lstrip()
        if s.startswith("//"):
            continue
        out.append(line)
    return "\n".join(out)


def _strip_block_comments(text: str) -> str:
    return re.sub(r"/\*.*?\*/", "", text, flags=re.DOTALL)


FORBIDDEN = [
    # AppleScript / StandardAdditions shell execution
    (re.compile(r"doShellScript", re.IGNORECASE), "doShellScript (StandardAdditions shell-out)"),
    (re.compile(r"do\s+shell\s+script", re.IGNORECASE), "do shell script"),
    (
        re.compile(r"includeStandardAdditions\s*=\s*true", re.IGNORECASE),
        "includeStandardAdditions=true (enables doShellScript and other non-ObjC bridges)",
    ),
    (re.compile(r"\bNSAppleScript\b"), "NSAppleScript (embedded AppleScript runner)"),
    (re.compile(r"\.runAppleScript\b", re.IGNORECASE), "runAppleScript (AppleScript execution from JXA)"),
    # Objective-C task / posix spawn patterns
    (re.compile(r"\bNSTask\b"), "NSTask"),
    (re.compile(r"\bNSConcreteTask\b"), "NSConcreteTask"),
    (re.compile(r"\bposix_spawn\b"), "posix_spawn"),
    (re.compile(r"\bsystem\s*\("), "system()"),
    (re.compile(r"\bpopen\s*\("), "popen()"),
    # Common shell paths in strings (heuristic; reduces accidental sh -c)
    (re.compile(r"['\"]\s*/bin/(?:ba)?sh\b"), "explicit /bin/sh or /bin/bash string"),
    (re.compile(r"['\"]\s*/usr/bin/(?:sudo|open|bash|zsh)\b"), "explicit /usr/bin/{sudo,open,bash,zsh} string"),
    (re.compile(r"['\"]\s*/bin/zsh\b"), "explicit /bin/zsh string"),
]

# At least one ObjC bridge import in each audited file under ttp/.
REQUIRE_OBJC = re.compile(r"ObjC\.import\s*\(\s*['\"]Foundation['\"]\s*\)")


def audit_file(path: Path, text: str) -> list[str]:
    errors: list[str] = []
    body = _strip_line_comments(_strip_block_comments(text))
    for rx, label in FORBIDDEN:
        if rx.search(body):
            errors.append(f"{path}: forbidden pattern: {label}")
    if not REQUIRE_OBJC.search(text):
        errors.append(f"{path}: missing ObjC.import('Foundation') (required for ttp JXA)")
    return errors


def default_collection_jxa(repo_root: Path) -> list[Path]:
    """Shell-twin JXA variants land under collection/jxa first; keep default CI scope green."""
    d = repo_root / "attackmacos" / "ttp" / "collection" / "jxa"
    if not d.is_dir():
        return []
    return sorted(d.glob("*.js"))


def default_all_ttp_jxa(repo_root: Path) -> list[Path]:
    ttp = repo_root / "attackmacos" / "ttp"
    if not ttp.is_dir():
        return []
    return sorted(ttp.glob("**/jxa/*.js"))


def main() -> int:
    parser = argparse.ArgumentParser(description="Audit JXA files for project shell-out rules.")
    parser.add_argument(
        "paths",
        nargs="*",
        type=Path,
        help="Specific .js files or directories (overrides --full default)",
    )
    parser.add_argument(
        "--full",
        action="store_true",
        help="Scan all attackmacos/ttp/**/jxa/*.js (legacy persistence JXA may fail until refactored)",
    )
    parser.add_argument("--verbose", "-v", action="store_true", help="Print scanned paths")
    args = parser.parse_args()

    repo_root = Path(__file__).resolve().parent.parent.parent
    if args.paths:
        files: list[Path] = []
        for p in args.paths:
            p = p.resolve() if p.exists() else repo_root / p
            if p.is_file() and p.suffix == ".js":
                files.append(p)
            elif p.is_dir():
                files.extend(sorted(p.rglob("*.js")))
            else:
                print(f"audit_jxa: skip missing path: {p}", file=sys.stderr)
    elif args.full:
        files = default_all_ttp_jxa(repo_root)
    else:
        files = default_collection_jxa(repo_root)

    if not files:
        print("audit_jxa: no JXA files found", file=sys.stderr)
        return 0

    all_errors: list[str] = []
    for f in files:
        if args.verbose:
            print(f"scan: {f.relative_to(repo_root)}", file=sys.stderr)
        try:
            text = f.read_text(encoding="utf-8")
        except OSError as e:
            all_errors.append(f"{f}: read error: {e}")
            continue
        all_errors.extend(audit_file(f, text))

    if all_errors:
        print("JXA audit FAILED:\n", file=sys.stderr)
        for e in all_errors:
            print(e, file=sys.stderr)
        return 1

    print(f"audit_jxa: OK ({len(files)} file(s))", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
