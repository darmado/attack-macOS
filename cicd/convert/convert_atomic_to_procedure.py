#!/usr/bin/env python3
"""
Name: convert_atomic_to_procedure.py
Author: @darmado | https://x.com/darmad0
License: Apache 2.0
Repository: https://github.com/armadoinc/attack-macOS
Description: Convert Atomic Red Team YAML tests into attack-macOS procedure YAML drafts.

Usage:
  python3 cicd/convert/convert_atomic_to_procedure.py \
    attackmacos/standby/AtomicRedTeam/atomics/T1005/T1005_Data_from_Local_System.yaml
"""

from __future__ import annotations

import argparse
import importlib.util
import sys
from datetime import datetime
from pathlib import Path
from typing import Any
from uuid import uuid4

import yaml

from convert_common import (
    ART_PROJECT_URL,
    ART_TECHNIQUE_DOC_URL_FMT,
    clean_slug,
    compact_template_sections,
    input_var_name,
    load_yaml,
    normalize_tactic,
    option_name,
    save_yaml,
    wrap_command_with_cmd_var,
)

# --- ART YAML / procedure bridge (single place for literals used in this converter)
REPO = Path(__file__).resolve().parents[2]
TEMPLATE_PATH = REPO / "attackmacos" / "core" / "templates" / "procedure.yml"
DEFAULT_INDEX = REPO / "attackmacos" / "standby" / "AtomicRedTeam" / "macos-index.yaml"
DEFAULT_STAGING = REPO / "attackmacos" / "standby" / "AtomicRedTeam" / "staging"

DEFAULT_TACTIC_FALLBACK = "Discovery"
KEY_ATOMIC_TESTS = "atomic_tests"
KEY_ATTACK_TECHNIQUE = "attack_technique"
KEY_AUTO_GENERATED_GUID = "auto_generated_guid"
KEY_DISPLAY_NAME = "display_name"
KEY_INPUT_ARGUMENTS = "input_arguments"
KEY_EXECUTOR = "executor"
KEY_COMMAND = "command"
KEY_CLEANUP_COMMAND = "cleanup_command"

ART_INPUT_INTEGER_TYPES: frozenset[str] = frozenset({"integer"})

PROCEDURE_VERSION_DEFAULT = "1.0.0"
PROCEDURE_INTENT_MAX_LEN = 500
ARG_DESCRIPTION_MAX_LEN = 100
RUN_OPTION_DESCRIPTION_PREFIX = "Run Atomic test:"

_BUILD_DIR = REPO / "cicd" / "build"
_pm_spec = importlib.util.spec_from_file_location(
    "procedure_metadata", str(_BUILD_DIR / "procedure_metadata.py")
)
procedure_metadata = importlib.util.module_from_spec(_pm_spec)
assert _pm_spec.loader is not None
_pm_spec.loader.exec_module(procedure_metadata)


def parse_tactic_from_index(ttp_id: str, index_path: Path) -> str:
    if not index_path.is_file():
        return DEFAULT_TACTIC_FALLBACK
    try:
        index_doc = load_yaml(index_path)
    except yaml.YAMLError:
        return DEFAULT_TACTIC_FALLBACK
    if not isinstance(index_doc, dict):
        return DEFAULT_TACTIC_FALLBACK
    for tactic_name, tactic_map in index_doc.items():
        if not isinstance(tactic_map, dict):
            continue
        if ttp_id in tactic_map:
            return tactic_name
    return DEFAULT_TACTIC_FALLBACK


def select_test(doc: dict[str, Any], test_guid: str | None, test_name: str | None, test_index: int | None) -> dict[str, Any]:
    tests = doc.get(KEY_ATOMIC_TESTS)
    if not isinstance(tests, list) or not tests:
        raise ValueError(f"{KEY_ATOMIC_TESTS} is empty or invalid")
    if test_guid:
        for test in tests:
            if isinstance(test, dict) and str(test.get(KEY_AUTO_GENERATED_GUID, "")).strip() == test_guid:
                return test
        raise ValueError(f"No atomic test with guid {test_guid}")
    if test_name:
        needle = test_name.strip().lower()
        for test in tests:
            name = str(test.get("name", "")).lower()
            if needle in name:
                return test
        raise ValueError(f"No atomic test matching name {test_name!r}")
    if test_index is not None:
        if test_index < 0 or test_index >= len(tests):
            raise ValueError(f"--test-index out of range: {test_index}")
        test = tests[test_index]
        if not isinstance(test, dict):
            raise ValueError(f"{KEY_ATOMIC_TESTS}[{test_index}] is not an object")
        return test
    first = tests[0]
    if not isinstance(first, dict):
        raise ValueError(f"{KEY_ATOMIC_TESTS}[0] is not an object")
    return first


def map_metadata(template: dict[str, Any], atomic_doc: dict[str, Any], test: dict[str, Any], tactic: str) -> tuple[str, str, str, str]:
    ttp_id = str(atomic_doc.get(KEY_ATTACK_TECHNIQUE, "")).strip().upper()
    if not ttp_id:
        raise ValueError(f"Missing {KEY_ATTACK_TECHNIQUE}")
    technique_name = str(atomic_doc.get(KEY_DISPLAY_NAME, "")).strip() or ttp_id
    test_name = str(test.get("name", "")).strip() or "atomic_test"
    guid = str(test.get(KEY_AUTO_GENERATED_GUID, "")).strip()
    desc = str(test.get("description", "")).strip()

    proc_name = clean_slug(f"{ttp_id}_{test_name}")
    source_link = ART_TECHNIQUE_DOC_URL_FMT.format(ttp_id=ttp_id)

    template["procedure_name"] = proc_name
    template["tactic"] = tactic
    template["ttp_id"] = ttp_id
    template["intent"] = (desc or f"Execute Atomic Red Team test: {test_name}")[:500]
    template["author"] = procedure_metadata.DEFAULT_PROCEDURE_AUTHOR
    template["credit"] = f"Atomic Red Team ({guid})" if guid else "Atomic Red Team"
    template["guid"] = str(uuid4())
    template["created"] = datetime.now().strftime("%Y-%m-%d")
    template["version"] = PROCEDURE_VERSION_DEFAULT
    template["platform"] = ["darwin"]
    return ttp_id, technique_name, test_name, source_link


def map_optional_sections(template: dict[str, Any], ttp_id: str, technique_name: str, source_link: str) -> None:
    resources = template.get("resources") if isinstance(template.get("resources"), list) else []
    template["resources"] = [
        {"link": source_link, "description": f"Atomic Red Team {ttp_id}: {technique_name}"},
        {"link": ART_PROJECT_URL, "description": "Atomic Red Team project"},
    ] + [r for r in resources if isinstance(r, dict)]


def map_arguments(test: dict[str, Any], func_main: str) -> tuple[list[dict[str, Any]], list[dict[str, Any]], str, str]:
    executor = test.get(KEY_EXECUTOR) if isinstance(test.get(KEY_EXECUTOR), dict) else {}
    command = str(executor.get(KEY_COMMAND, "")).strip()
    cleanup = str(executor.get(KEY_CLEANUP_COMMAND, "")).strip()
    if not command:
        raise ValueError(f"Atomic test executor.{KEY_COMMAND} is missing")

    args: list[dict[str, Any]] = [
        {
            "option": "--run",
            "description": f"{RUN_OPTION_DESCRIPTION_PREFIX} {str(test.get('name', 'atomic_test'))[:70]}",
            "execute_function": [func_main],
        }
    ]
    globals_list: list[dict[str, Any]] = []
    input_args = test.get("input_arguments") if isinstance(test.get("input_arguments"), dict) else {}
    for key, row in input_args.items():
        if not isinstance(row, dict):
            continue
        in_type = str(row.get("type", "")).strip().lower()
        arg_type = "integer" if in_type in ART_INPUT_INTEGER_TYPES else "string"
        var_name = input_var_name(str(key))
        default = row.get("default", "")
        default_s = "" if default is None else str(default)
        args.append(
            {
                "option": option_name(str(key)),
                "description": str(row.get("description", f"Atomic input: {key}"))[:ARG_DESCRIPTION_MAX_LEN],
                "type": arg_type,
                "input_required": True,
                "execute_function": [func_main],
            }
        )
        globals_list.append(
            {
                "name": var_name,
                "type": "integer" if arg_type == "integer" else "string",
                "default_value": default_s,
            }
        )
        command = command.replace(f"#{{{key}}}", f"${{{var_name}}}")
        if cleanup:
            cleanup = cleanup.replace(f"#{{{key}}}", f"${{{var_name}}}")
    return args, globals_list, command, cleanup


def _shell_function_with_capture(func_name: str, cmd_expr: str) -> str:
    # Assemble with f-strings only for the function name line; inject cmd_expr in one
    # interpolation so Atomic `command` strings that contain "{" or "}" do not break str.format.
    return (
        f"{func_name}() {{\n"
        "    local result\n"
        f"    result=$({cmd_expr} 2>&1)\n"
        '    $CMD_PRINTF "RESULT|%s\\n" "$result"\n'
        "    return 0\n"
        "}"
    )


def map_functions(func_main: str, func_cleanup: str, args: list[dict[str, Any]], globals_list: list[dict[str, Any]], command: str, cleanup: str) -> list[dict[str, Any]]:
    command, main_cmd_var = wrap_command_with_cmd_var(command)
    if main_cmd_var is not None:
        globals_list.append(main_cmd_var)
    if cleanup:
        cleanup, cleanup_cmd_var = wrap_command_with_cmd_var(cleanup)
        if cleanup_cmd_var is not None and cleanup_cmd_var["name"] != (main_cmd_var or {}).get("name"):
            globals_list.append(cleanup_cmd_var)

    code_main = _shell_function_with_capture(func_main, command)
    functions = [
        {
            "name": func_main,
            "type": "main",
            "language": ["shell"],
            "opsec": {"check_fda": {"enabled": False, "exit_on_failure": True}},
            "code": code_main,
        }
    ]
    if cleanup:
        args.append(
            {
                "option": "--cleanup",
                "description": "Run Atomic cleanup command",
                "execute_function": [func_cleanup],
            }
        )
        code_cleanup = _shell_function_with_capture(func_cleanup, cleanup)
        functions.append(
            {
                "name": func_cleanup,
                "type": "helper",
                "language": ["shell"],
                "opsec": {"check_fda": {"enabled": False, "exit_on_failure": True}},
                "code": code_cleanup,
            }
        )
    return functions


def map_global_variables(template: dict[str, Any], globals_list: list[dict[str, Any]]) -> None:
    template["procedure"]["global_variable"] = globals_list


def convert(atomic_doc: dict[str, Any], test: dict[str, Any], tactic: str) -> dict[str, Any]:
    template = load_yaml(TEMPLATE_PATH)
    if not isinstance(template, dict):
        raise ValueError("Invalid procedure template")

    ttp_id, technique_name, test_name, source_link = map_metadata(template, atomic_doc, test, tactic)
    func_main = f"execute_{clean_slug(test_name)}"
    func_cleanup = f"cleanup_{clean_slug(test_name)}"
    map_optional_sections(template, ttp_id, technique_name, source_link)
    args, globals_list, command, cleanup = map_arguments(test, func_main)
    functions = map_functions(func_main, func_cleanup, args, globals_list, command, cleanup)
    template["procedure"]["arguments"] = args
    map_global_variables(template, globals_list)
    template["procedure"]["functions"] = functions
    compact_template_sections(template)
    return template


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("atomic_yaml", type=Path, help="Path to a standby Atomic YAML file")
    parser.add_argument("--test-guid", default=None, help="Atomic test auto_generated_guid to select")
    parser.add_argument("--test-name", default=None, help="Substring match for atomic test name")
    parser.add_argument("--test-index", type=int, default=None, help="Zero-based atomic test index")
    parser.add_argument("--tactic", default=None, help="Override tactic (defaults to index-inferred value)")
    parser.add_argument("--index-file", type=Path, default=DEFAULT_INDEX, help="macos-index.yaml path for tactic inference")
    parser.add_argument("--out", type=Path, default=None, help="Output procedure YAML path")
    args = parser.parse_args()

    if not args.atomic_yaml.is_file():
        print(f"File not found: {args.atomic_yaml}", file=sys.stderr)
        return 1

    doc = load_yaml(args.atomic_yaml)
    if not isinstance(doc, dict):
        print("Invalid atomic YAML structure", file=sys.stderr)
        return 1
    try:
        selected = select_test(doc, args.test_guid, args.test_name, args.test_index)
        ttp_id = str(doc.get(KEY_ATTACK_TECHNIQUE, "")).strip().upper()
        tactic = normalize_tactic(args.tactic or parse_tactic_from_index(ttp_id, args.index_file))
        out_data = convert(doc, selected, tactic)
    except (ValueError, yaml.YAMLError) as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1

    if args.out is None:
        proc_name = str(out_data.get("procedure_name", "atomic_procedure")).strip() or "atomic_procedure"
        out_path = DEFAULT_STAGING / f"{proc_name}.yml"
    else:
        out_path = args.out
    save_yaml(out_path, out_data)
    print(f"Wrote draft procedure YAML: {out_path}")
    print("Next: review output, then run python3 cicd/build/procedure_shell.py <draft.yml>")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
