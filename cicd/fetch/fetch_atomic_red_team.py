#!/usr/bin/env python3
"""
Fetch Atomic Red Team macOS index YAML and write trimmed standby copies.

This script **only fetches and organizes** upstream ART YAML into
`attackmacos/standby/AtomicRedTeam/`. It does **not** convert atomics into
attack-macOS procedures, merge `base.sh` / `base.js`, or emit runnable TTP scripts.
Output stays ART-shaped (not procedure.schema.json).

Full pipeline for executable procedures: maintainers edit `attackmacos/core/config/`
then run `cicd/build/procedure_shell.py` / `procedure_jxa.py`.

Source:
  https://raw.githubusercontent.com/redcanaryco/atomic-red-team/refs/heads/master/atomics/Indexes/macos-index.yaml

Run with no arguments → help.

Modes:
  --all               Fetch index → write macos-index.yaml, atomics/, index_summary.json
  --list-executors    Print distinct ART executor.name values on macOS-listed tests (then exit)
  --search PATTERN    Query table (fnmatch * ?)
  --ttp ID            One technique
  --tactic NAME       Index tactic key (lowercase)

Optional filter (macOS tests only):
  --executor NAME     Repeat or commas: --executor sh,bash --executor powershell

Output queries: --format table|json|csv
Audit: -l / --log → logs/cicd/fetch_atomic_red_team_<timestamp>.log
"""

from __future__ import annotations

import argparse
import csv
import fnmatch
import io
import json
import re
import shutil
import sys
import urllib.error
import urllib.request
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable

_CICD_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(_CICD_ROOT))
import validate_input  # noqa: E402

import yaml

REPO = Path(__file__).resolve().parents[2]
DEFAULT_OUT = REPO / "attackmacos" / "standby" / "AtomicRedTeam" / "atomics"
DEFAULT_INDEX_FILE = REPO / "attackmacos" / "standby" / "AtomicRedTeam" / "macos-index.yaml"
DEFAULT_SUMMARY_FILE = REPO / "attackmacos" / "standby" / "AtomicRedTeam" / "index_summary.json"
DEFAULT_INDEX_URL = (
    "https://raw.githubusercontent.com/redcanaryco/atomic-red-team/"
    "refs/heads/master/atomics/Indexes/macos-index.yaml"
)
DEFAULT_LOG_DIR = REPO / "logs" / "cicd"

TID_RE = re.compile(r"^T[0-9]+(?:\.[0-9]+)?$", re.IGNORECASE)
_NAME_SLUG_MAX = 200

HEADER = """# macOS-listed Atomic Red Team tests only (normalized from macos-index.yaml).
# Upstream: https://github.com/redcanaryco/atomic-red-team
# License: MIT — see upstream LICENSE. Human review required before promotion.
"""


def supports_macos(test: dict[str, Any]) -> bool:
    platforms = test.get("supported_platforms")
    if not isinstance(platforms, list):
        return False
    for platform in platforms:
        if isinstance(platform, str) and platform.strip().lower() == "macos":
            return True
    return False


def executor_name(test: dict[str, Any]) -> str:
    executor = test.get("executor")
    if not isinstance(executor, dict):
        return ""
    name = executor.get("name")
    if not isinstance(name, str):
        return ""
    return name.strip().lower()


def normalize_tests(
    tests: Any,
    executors: set[str] | None,
) -> list[dict[str, Any]]:
    if not isinstance(tests, list):
        return []
    kept: list[dict[str, Any]] = []
    for test in tests:
        if not isinstance(test, dict):
            continue
        if not supports_macos(test):
            continue
        if executors is not None:
            en = executor_name(test)
            if en not in executors:
                continue
        kept.append(test)
    return kept


def parse_executor_filter(raw: list[str] | None) -> set[str] | None:
    if not raw:
        return None
    out: set[str] = set()
    for chunk in raw:
        for piece in chunk.split(","):
            if not piece.strip():
                continue
            out.add(validate_input.validate_atomic_red_team_executor_name_token(piece))
    return out if out else None


def _atomic_test_command_blob(test: dict[str, Any]) -> str:
    ex = test.get("executor")
    if not isinstance(ex, dict):
        return ""
    return "\n".join(
        [
            str(ex.get("command", "")),
            str(ex.get("cleanup_command", "")),
        ]
    )


def _atomic_test_dependencies_blob(test: dict[str, Any]) -> str:
    deps = test.get("dependencies")
    if not isinstance(deps, list):
        return ""
    parts: list[str] = []
    for dep in deps:
        if not isinstance(dep, dict):
            continue
        for key in ("get_prereq_command", "prereq_command", "description", "prereq_description"):
            val = dep.get(key)
            if val is not None:
                parts.append(str(val))
    return "\n".join(parts)


def heuristic_remote_or_prereq_signals(test: dict[str, Any]) -> list[str]:
    """Conservative flags for maintainer review; not a guarantee of malicious or non-native intent."""
    blob = (_atomic_test_command_blob(test) + "\n" + _atomic_test_dependencies_blob(test)).lower()
    signals: list[str] = []
    if "curl " in blob or "\ncurl" in blob:
        signals.append("curl")
    if "wget " in blob or "\nwget" in blob:
        signals.append("wget")
    if "invoke-webrequest" in blob or "iwr " in blob or "invoke-restmethod" in blob:
        signals.append("powershell_web")
    if "git clone" in blob:
        signals.append("git_clone")
    if "http://" in blob or "https://" in blob:
        signals.append("url_literal")
    if isinstance(test.get("dependencies"), list) and test.get("dependencies"):
        signals.append("dependencies_block")
    return signals


def summarize_remote_heuristics(outputs: dict[str, Any]) -> tuple[int, dict[str, int]]:
    flagged_tests = 0
    by_signal: dict[str, int] = {}
    for payload in outputs.values():
        tests = payload.get("atomic_tests")
        if not isinstance(tests, list):
            continue
        for test in tests:
            if not isinstance(test, dict):
                continue
            sigs = heuristic_remote_or_prereq_signals(test)
            if not sigs:
                continue
            flagged_tests += 1
            for s in sigs:
                by_signal[s] = by_signal.get(s, 0) + 1
    return flagged_tests, by_signal


def download_text(url: str) -> str:
    req = urllib.request.Request(
        url,
        headers={
            "User-Agent": "attack-macOS-art-index-fetch",
            "Accept": "text/yaml,text/plain,*/*",
        },
    )
    with urllib.request.urlopen(req, timeout=120) as resp:
        return resp.read().decode("utf-8")


def parse_index(doc: Any) -> Iterable[tuple[str, str, dict[str, Any]]]:
    if not isinstance(doc, dict):
        raise ValueError("macos-index root must be a mapping")
    for tactic_name, tactic_map in doc.items():
        if not isinstance(tactic_map, dict):
            continue
        for tid, entry in tactic_map.items():
            if not isinstance(tid, str) or not TID_RE.match(tid):
                continue
            if not isinstance(entry, dict):
                continue
            yield tactic_name, tid, entry


def normalize_tid(raw: str) -> str | None:
    s = raw.strip().upper()
    return s if TID_RE.match(s) else None


def technique_yaml_filename(ttp_id: str, display_name: str) -> str:
    raw = (display_name or "").strip() or "technique"
    s = re.sub(r'[\\/:*?"<>|]', " ", raw)
    s = re.sub(r"\s+", "_", s)
    s = re.sub(r"[^0-9A-Za-z._-]+", "_", s)
    s = re.sub(r"_+", "_", s).strip("._-")
    if not s:
        s = "technique"
    s = s[:_NAME_SLUG_MAX]
    return f"{ttp_id}_{s}.yaml"


@dataclass
class Row:
    tactic: str
    ttp: str
    name: str
    macos_tests: int


def pattern_match(pattern: str, *fields: str) -> bool:
    pat = pattern.strip().lower()
    for f in fields:
        if not f:
            continue
        if fnmatch.fnmatch(f.lower(), pat):
            return True
    return False


def matches_search(
    pattern: str,
    tactic: str,
    tid: str,
    display_name: str,
    kept_tests: list[dict[str, Any]],
) -> bool:
    if pattern_match(pattern, tid, tactic.lower(), display_name):
        return True
    for test in kept_tests:
        if not isinstance(test, dict):
            continue
        nm = test.get("name")
        if isinstance(nm, str) and pattern_match(pattern, nm):
            return True
    return False


def format_rows_table(rows: list[Row]) -> str:
    if not rows:
        return "(no matching techniques)\n"
    ttp_w = max(len(r.ttp) for r in rows)
    ttp_w = max(ttp_w, len("TTP"))
    tac_w = max(len(r.tactic) for r in rows)
    tac_w = max(tac_w, len("tactic"))
    lines = [
        f"{'TTP'.ljust(ttp_w)}  {'tactic'.ljust(tac_w)}  name (macOS tests)",
        f"{'-' * ttp_w}  {'-' * tac_w}  {'-' * 40}",
    ]
    for r in rows:
        nm = f"{r.name} ({r.macos_tests})" if r.name else f"({r.macos_tests})"
        lines.append(f"{r.ttp.ljust(ttp_w)}  {r.tactic.ljust(tac_w)}  {nm}")
    return "\n".join(lines) + "\n"


def format_rows_csv(rows: list[Row]) -> str:
    buf = io.StringIO()
    w = csv.writer(buf)
    w.writerow(["ttp", "tactic", "name", "macos_tests"])
    for r in rows:
        w.writerow([r.ttp, r.tactic, r.name, r.macos_tests])
    return buf.getvalue()


def format_rows_json(rows: list[Row]) -> str:
    data = [
        {
            "ttp": r.ttp,
            "tactic": r.tactic,
            "name": r.name,
            "macos_tests": r.macos_tests,
        }
        for r in rows
    ]
    return json.dumps(data, indent=2, sort_keys=True) + "\n"


def emit_formatted(rows: list[Row], fmt: str) -> str:
    fmt = fmt.strip().lower()
    if fmt in ("table", "text", "raw"):
        return format_rows_table(rows)
    if fmt == "json":
        return format_rows_json(rows)
    if fmt == "csv":
        return format_rows_csv(rows)
    raise ValueError(f"Unknown format: {fmt}")


class AuditLog:
    def __init__(self, path: Path | None) -> None:
        self.path = path
        self._fh = path.open("a", encoding="utf-8") if path else None

    def write(self, text: str) -> None:
        if self._fh:
            self._fh.write(text)
            self._fh.flush()

    def close(self) -> None:
        if self._fh:
            self._fh.close()
            self._fh = None


def open_audit_log(enabled: bool) -> AuditLog:
    if not enabled:
        return AuditLog(None)
    DEFAULT_LOG_DIR.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    path = DEFAULT_LOG_DIR / f"fetch_atomic_red_team_{stamp}.log"
    print(f"Audit log: {path}", file=sys.stderr)
    log = AuditLog(path)
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    log.write(f"[{ts}] fetch_atomic_red_team.py {' '.join(sys.argv[1:])}\n")
    log.write(f"[{ts}] repo_root={REPO}\n")
    return log


def print_and_log(line: str, log: AuditLog, *, nl: bool = True) -> None:
    sys.stdout.write(line + ("\n" if nl else ""))
    sys.stdout.flush()
    log.write(line + ("\n" if nl else ""))


def load_index_bytes(args: argparse.Namespace) -> tuple[str, Any]:
    if getattr(args, "local", False):
        if not args.index_file.is_file():
            print(
                f"Error: --local requires cached index at {args.index_file}",
                file=sys.stderr,
            )
            raise SystemExit(1)
        raw = args.index_file.read_text(encoding="utf-8")
    else:
        try:
            raw = download_text(args.index_url)
        except urllib.error.HTTPError as exc:
            print(f"HTTP error downloading index: {exc}", file=sys.stderr)
            raise SystemExit(1) from exc
        except urllib.error.URLError as exc:
            print(f"Network error downloading index: {exc}", file=sys.stderr)
            raise SystemExit(1) from exc

    try:
        doc = yaml.safe_load(raw)
    except yaml.YAMLError as exc:
        print(f"Failed to parse index YAML: {exc}", file=sys.stderr)
        raise SystemExit(1) from exc
    return raw, doc


def build_outputs(
    index_doc: Any,
    executors: set[str] | None,
) -> tuple[dict[str, Any], dict[str, int], int, int, int, int]:
    total_techniques = 0
    kept_techniques = 0
    total_tests = 0
    kept_tests = 0
    by_tactic: dict[str, int] = {}
    outputs: dict[str, Any] = {}

    for tactic_name, tid, entry in parse_index(index_doc):
        total_techniques += 1
        tests = entry.get("atomic_tests")
        if isinstance(tests, list):
            total_tests += len(tests)
        kept = normalize_tests(tests, executors)
        kept_tests += len(kept)
        if not kept:
            continue
        kept_techniques += 1
        technique = entry.get("technique") if isinstance(entry.get("technique"), dict) else {}
        display_name = technique.get("name") if isinstance(technique.get("name"), str) else ""
        outputs[tid] = {
            "attack_technique": tid,
            "display_name": display_name,
            "atomic_tests": kept,
        }
        by_tactic[tactic_name] = by_tactic.get(tactic_name, 0) + 1

    return outputs, by_tactic, total_techniques, kept_techniques, total_tests, kept_tests


def run_fetch(args: argparse.Namespace, log: AuditLog, executors: set[str] | None) -> int:
    raw, index_doc = load_index_bytes(args)
    outputs, by_tactic, total_techniques, kept_techniques, total_tests, kept_tests = build_outputs(
        index_doc, executors
    )

    remote_flagged, remote_counts = summarize_remote_heuristics(outputs)
    summary = {
        "index_url": args.index_url,
        "total_techniques": total_techniques,
        "kept_techniques": kept_techniques,
        "total_tests": total_tests,
        "kept_tests": kept_tests,
        "executors_filter": sorted(executors) if executors else None,
        "by_tactic": dict(sorted(by_tactic.items())),
        "kept_tests_heuristic_remote_or_prereq_signals": remote_flagged,
        "heuristic_remote_signal_counts": dict(sorted(remote_counts.items())),
        "heuristic_remote_signal_version": "art-standby-1",
        "heuristic_note": (
            "Substring scan of executor commands, cleanup, and ART dependency/prereq fields. "
            "url_literal includes benign URLs. attack-macOS shipped procedures remain native-tooling-first; "
            "review before promoting standby into core/config/."
        ),
    }
    summary_json = json.dumps(summary, indent=2, sort_keys=True) + "\n"

    print_and_log(f"Index techniques scanned: {total_techniques}", log)
    print_and_log(f"Techniques with macOS tests (after filters): {kept_techniques}", log)
    print_and_log(f"Atomic tests scanned: {total_tests}", log)
    print_and_log(f"macOS atomic tests retained: {kept_tests}", log)
    print_and_log(
        f"Heuristic: kept tests with possible remote/prereq signals (see index_summary.json): {remote_flagged}",
        log,
    )

    if args.dry_run:
        print_and_log("Dry-run: no files written.", log)
        print_and_log("--- index_summary (preview) ---", log)
        print_and_log(summary_json.rstrip(), log)
        return 0

    if args.out.exists():
        shutil.rmtree(args.out)
    args.out.mkdir(parents=True, exist_ok=True)
    args.index_file.parent.mkdir(parents=True, exist_ok=True)
    args.index_file.write_text(raw, encoding="utf-8")

    for tid, payload in sorted(outputs.items()):
        dname = payload.get("display_name")
        name_str = dname if isinstance(dname, str) else ""
        leaf = technique_yaml_filename(tid, name_str)
        out_path = args.out / tid / leaf
        out_path.parent.mkdir(parents=True, exist_ok=True)
        body = yaml.safe_dump(
            payload,
            sort_keys=False,
            allow_unicode=True,
            default_flow_style=False,
            width=120,
        )
        out_path.write_text(HEADER + "\n" + body, encoding="utf-8")

    args.summary_file.parent.mkdir(parents=True, exist_ok=True)
    args.summary_file.write_text(summary_json, encoding="utf-8")

    print_and_log(f"Wrote index snapshot: {args.index_file}", log)
    print_and_log(f"Wrote summary: {args.summary_file}", log)
    print_and_log(f"Wrote {kept_techniques} technique YAML file(s) under {args.out}", log)
    print_and_log("--- index_summary.json ---", log)
    print_and_log(summary_json.rstrip(), log)
    return 0


def query_rows(
    index_doc: Any,
    executors: set[str] | None,
    *,
    tactic: str | None,
    search: str | None,
    ttp: str | None,
) -> list[Row]:
    rows: list[Row] = []
    want_tactic = tactic.strip().lower() if tactic else None
    search_p = search.strip() if search else None

    for tactic_name, tid, entry in parse_index(index_doc):
        if want_tactic is not None and tactic_name.lower() != want_tactic:
            continue
        if ttp is not None and tid.upper() != ttp.upper():
            continue
        kept = normalize_tests(entry.get("atomic_tests"), executors)
        if not kept:
            continue
        technique = entry.get("technique") if isinstance(entry.get("technique"), dict) else {}
        display_name = technique.get("name") if isinstance(technique.get("name"), str) else ""
        if search_p and not matches_search(search_p, tactic_name, tid, display_name, kept):
            continue
        rows.append(
            Row(
                tactic=tactic_name,
                ttp=tid,
                name=display_name,
                macos_tests=len(kept),
            )
        )
    rows.sort(key=lambda r: (r.tactic, r.ttp))
    return rows


def run_query(args: argparse.Namespace, log: AuditLog, executors: set[str] | None) -> int:
    _, index_doc = load_index_bytes(args)

    ttp_f = normalize_tid(args.ttp) if args.ttp else None
    if args.ttp and not ttp_f:
        print(f"Invalid --ttp value: {args.ttp!r}", file=sys.stderr)
        return 1

    filtered = query_rows(
        index_doc,
        executors,
        tactic=args.tactic,
        search=args.search,
        ttp=ttp_f,
    )

    text = emit_formatted(filtered, args.format)
    print_and_log(text.rstrip(), log)
    return 0


def run_list_executors(args: argparse.Namespace, log: AuditLog) -> int:
    """Distinct executor.name values on macOS-listed tests (no --executor filter)."""
    _, index_doc = load_index_bytes(args)
    names: set[str] = set()
    for _, _, entry in parse_index(index_doc):
        for test in normalize_tests(entry.get("atomic_tests"), None):
            ex = executor_name(test)
            if ex:
                names.add(ex)
    for n in sorted(names):
        print_and_log(n, log)
    print_and_log(f"Distinct executors (macOS tests): {len(names)}", log)
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--index-url",
        default=DEFAULT_INDEX_URL,
        help="macOS index YAML URL",
    )
    parser.add_argument(
        "--local",
        action="store_true",
        help="Use cached index at --index-file only (no HTTP); file must exist",
    )
    parser.add_argument("--out", type=Path, default=DEFAULT_OUT, help=f"Output atomics root (default: {DEFAULT_OUT})")
    parser.add_argument(
        "--index-file",
        type=Path,
        default=DEFAULT_INDEX_FILE,
        help=f"Cached index snapshot path (default: {DEFAULT_INDEX_FILE})",
    )
    parser.add_argument(
        "--summary-file",
        type=Path,
        default=DEFAULT_SUMMARY_FILE,
        help=f"Summary JSON path (default: {DEFAULT_SUMMARY_FILE})",
    )
    parser.add_argument(
        "--executor",
        action="append",
        dest="executors",
        metavar="NAME",
        help="Keep only tests whose ART executor.name matches (repeat or comma-list). Examples: "
        "--executor sh --executor bash  OR  --executor sh,bash,powershell",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="With --all: counts + summary preview only; no writes under atomics/",
    )
    parser.add_argument(
        "-l",
        "--log",
        action="store_true",
        help=f"Write audit log under {DEFAULT_LOG_DIR}/fetch_atomic_red_team_<timestamp>.log",
    )
    parser.add_argument(
        "--format",
        "--output-format",
        dest="format",
        default="table",
        choices=("table", "text", "json", "csv"),
        help="Query output format (default: table)",
    )

    parser.add_argument(
        "--all",
        action="store_true",
        help="Fetch index and write standby YAML + summaries (does not build runnable TTP scripts)",
    )
    parser.add_argument(
        "--list-executors",
        action="store_true",
        help="List distinct executor.name values seen on macOS atomic tests (then exit)",
    )
    parser.add_argument(
        "--search",
        metavar="PATTERN",
        default=None,
        type=validate_input.validate_atomic_red_team_index_search_fnmatch_pattern,
        help="Match TTP id, technique name, tactic, or atomic test name (* and ? wildcards)",
    )
    parser.add_argument("--ttp", metavar="ID", default=None, help="Single technique id (e.g. T1049)")
    parser.add_argument(
        "--tactic",
        metavar="NAME",
        default=None,
        type=validate_input.validate_atomic_red_team_macos_index_tactic_key,
        help="Index tactic key (lowercase, e.g. discovery, stealth)",
    )

    args = parser.parse_args()
    try:
        args.index_url = validate_input.validate_http_https_url_with_host(args.index_url.strip())
    except argparse.ArgumentTypeError as exc:
        parser.error(f"--index-url: {exc}")

    try:
        executors = parse_executor_filter(args.executors)
    except argparse.ArgumentTypeError as exc:
        parser.error(str(exc))

    if len(sys.argv) <= 1:
        parser.print_help()
        return 0

    log = open_audit_log(args.log)
    try:
        has_action = bool(
            args.all or args.list_executors or args.search or args.ttp or args.tactic
        )
        if not has_action:
            parser.print_help()
            return 0

        if args.list_executors:
            if args.all or args.search or args.ttp or args.tactic:
                print(
                    "Error: --list-executors cannot combine with --all, --search, --ttp, or --tactic",
                    file=sys.stderr,
                )
                return 1
            return run_list_executors(args, log)

        if args.all:
            if args.search or args.ttp or args.tactic:
                print(
                    "Error: --all cannot be combined with --search, --ttp, or --tactic",
                    file=sys.stderr,
                )
                return 1
            return run_fetch(args, log, executors)

        return run_query(args, log, executors)
    finally:
        log.close()


if __name__ == "__main__":
    raise SystemExit(main())
