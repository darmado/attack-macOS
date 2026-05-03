#!/bin/sh
# Local QA before opening a PR (no GitHub Actions required).
# Run from repository root: sh cicd/qa/run_local_qa.sh
#
# Steps: procedure inventory (strict) → validate all shell YAML → JXA static
# audit → optional JXA builder self-test on macOS only.
#
# Environment:
#   PYTHON  Python interpreter (default: python3)
#   SKIP_JXA_SELFTEST  set to 1 to skip osascript self-test even on Darwin

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
PYTHON="${PYTHON:-python3}"
cd "$ROOT"

echo "== attack-macOS local QA (repo root: $ROOT) =="

if ! "$PYTHON" -c "import yaml, jsonschema" 2>/dev/null; then
	echo "Install deps: $PYTHON -m pip install pyyaml jsonschema" >&2
	exit 1
fi

echo "== 1/4 Procedure inventory (strict) =="
"$PYTHON" cicd/audit/audit_procedure_inventory.py --strict

echo "== 2/4 Validate all shell procedure YAML =="
ok=0
fail=0
for y in attackmacos/core/config/*.yml; do
	if ! "$PYTHON" cicd/build/build_shell_procedure.py --validate "$y" >/dev/null 2>&1; then
		echo "FAIL: $y" >&2
		"$PYTHON" cicd/build/build_shell_procedure.py --validate "$y" || true
		fail=$((fail + 1))
	else
		ok=$((ok + 1))
	fi
done
echo "Validated OK: $ok  Failed: $fail"
if [ "$fail" -gt 0 ]; then
	exit 1
fi

echo "== 3/4 JXA static audit (full tree) =="
"$PYTHON" cicd/audit/audit_jxa.py --full

if [ "${SKIP_JXA_SELFTEST:-0}" != 1 ]; then
	case "$(uname -s)" in
	Darwin)
		echo "== 4/4 JXA builder self-test (macOS) =="
		"$PYTHON" cicd/build/build_jxa_procedure.py --self-test
		;;
	*)
		echo "== 4/4 Skipped JXA self-test (not macOS; set SKIP_JXA_SELFTEST=0 on Darwin to run) =="
		;;
	esac
else
	echo "== 4/4 Skipped JXA self-test (SKIP_JXA_SELFTEST=1) =="
fi

echo "== Local QA finished successfully =="
