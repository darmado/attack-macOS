#!/usr/bin/env python3
"""
Build JXA (.js) procedures from YAML definitions, merged with attackmacos/core/base/base.js.

Models cicd/build/build_shell_procedure.py: validate YAML, substitute placeholders, write under
attackmacos/ttp/<tactic>/jxa/, then run osascript smoke test and cicd/audit/audit_jxa.py.

Author: @darmado | https://x.com/darmad0
License: Apache 2.0
"""

from __future__ import annotations

import importlib.util
import shutil
import subprocess
import tempfile
import sys
from pathlib import Path


def _load_shell_builder():
    """Load sibling build_shell_procedure without package import path issues."""
    here = Path(__file__).resolve().parent
    spec = importlib.util.spec_from_file_location(
        "build_shell_procedure", here / "build_shell_procedure.py"
    )
    mod = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(mod)
    return mod


BSP = _load_shell_builder()
read_yaml = BSP.read_yaml
validate_yaml = BSP.validate_yaml
ProcedureData = BSP.ProcedureData
get_tactic_directory = BSP.get_tactic_directory
option_to_var = BSP.option_to_var
build_help_text = BSP.build_help_text
generate_and_update_guid = BSP.generate_and_update_guid

BOLD = BSP.BOLD
RED = BSP.RED
GREEN = BSP.GREEN
YELLOW = BSP.YELLOW
RESET = BSP.RESET

_here = Path(__file__).resolve().parent
_pm_spec = importlib.util.spec_from_file_location(
    "procedure_metadata", str(_here / "procedure_metadata.py")
)
procedure_metadata = importlib.util.module_from_spec(_pm_spec)
assert _pm_spec.loader is not None
_pm_spec.loader.exec_module(procedure_metadata)


def _js_quote(s: str) -> str:
    return "'" + s.replace("\\", "\\\\").replace("'", "\\'").replace("\n", "\\n") + "'"


def jxa_functions_only(proc_data: ProcedureData):
    out = []
    for func in proc_data.functions:
        langs = func.get("language") or []
        if "jxa" in langs or "javascript" in langs:
            out.append(func)
    return out


def build_flag_vars_jxa(proc_data: ProcedureData) -> str:
    lines = []
    for arg in proc_data.arguments:
        var_name = option_to_var(arg["option"])
        has_input = arg.get("type") in ["string", "integer"] or arg.get("input_required", False)
        has_execution = arg.get("execute_function", [])
        if has_input and has_execution:
            lines.append(f'        opts.INPUT_{var_name} = "";')
            lines.append(f"        opts.{var_name} = false;")
        elif has_input:
            lines.append(f'        opts.INPUT_{var_name} = "";')
        elif has_execution:
            lines.append(f"        opts.{var_name} = false;")
    return "\n".join(lines)


def build_global_vars_jxa(proc_data: ProcedureData) -> str:
    lines = []
    for var in proc_data.global_vars:
        name = var["name"]
        var_type = var["type"]
        default = var["default_value"]
        if var_type == "string":
            lines.append(f'        opts.{name} = {_js_quote(str(default))};')
        elif var_type == "boolean":
            low = str(default).lower()
            val = "true" if low in ("true", "1", "yes") else "false"
            lines.append(f"        opts.{name} = {val};")
        elif var_type == "integer":
            lines.append(f"        opts.{name} = {int(default)};")
        else:
            lines.append(f'        opts.{name} = {_js_quote(str(default))};')
    return "\n".join(lines)


def _option_tokens(option: str) -> list[str]:
    opt = option.strip()
    if "|" in opt:
        a, b = opt.split("|", 1)
        return [a.strip(), b.strip()]
    return [opt]


def build_parse_argv_body(proc_data: ProcedureData) -> str:
    """Emit JavaScript inside parseArgv after opts = { help: false }."""
    lines: list[str] = []
    lines.append("        var i = 0;")
    lines.append("        while (i < raw.length) {")
    lines.append("            var a = raw[i];")
    lines.append(
        "            if (a === '-h' || a === '--help') { opts.help = true; i++; continue; }"
    )

    for arg in proc_data.arguments:
        var_name = option_to_var(arg["option"])
        tokens = _option_tokens(arg["option"])
        has_input = arg.get("type") in ["string", "integer"] or arg.get("input_required", False)
        conds = " || ".join(f"a === {_js_quote(t)}" for t in tokens)

        if has_input:
            lines.append(f"            if ({conds}) {{")
            lines.append("                if (i + 1 >= raw.length) { i++; continue; }")
            lines.append(f"                opts.INPUT_{var_name} = raw[i + 1];")
            if arg.get("execute_function"):
                lines.append(f"                opts.{var_name} = true;")
            lines.append("                i += 2;")
            lines.append("                continue;")
            lines.append("            }")
        else:
            lines.append(f"            if ({conds}) {{")
            lines.append(f"                opts.{var_name} = true;")
            lines.append("                i++;")
            lines.append("                continue;")
            lines.append("            }")

    lines.append("            i++;")
    lines.append("        }")
    return "\n".join(lines)


def build_help_lines_jxa(proc_data: ProcedureData) -> str:
    ht = build_help_text(proc_data)
    if not ht.strip():
        return "        lines.push(" + _js_quote("  (no options)") + ");"
    out = []
    for line in ht.split("\n"):
        out.append("        lines.push(" + _js_quote(line) + ");")
    return "\n".join(out)


def build_functions_jxa(proc_data: ProcedureData, jxa_funcs: list) -> str:
    blocks = []
    for func in jxa_funcs:
        blocks.append(f"    // Function: {func['name']} (JXA)")
        blocks.append(func.get("code", "").rstrip())
        blocks.append("")
    return "\n".join(blocks)


def collect_dispatch_names(proc_data: ProcedureData) -> list[str]:
    seen: list[str] = []
    for arg in proc_data.arguments:
        for fn in arg.get("execute_function", []):
            if fn not in seen:
                seen.append(fn)
    return seen


def build_dispatch_body(proc_data: ProcedureData) -> str:
    names = collect_dispatch_names(proc_data)
    if not names:
        return '        return "";'
    lines = ["        switch (fnName) {"]
    for n in names:
        lines.append(f'        case {_js_quote(n)}:')
        lines.append(f"            return typeof {n} === 'function' ? {n}() : '';")
    lines.append("        default:")
    lines.append('            return "";')
    lines.append("        }")
    return "\n".join(lines)


def build_main_body(proc_data: ProcedureData) -> str:
    lines = [
        "        if (opts.help) {",
        "            printHelp();",
        "            return;",
        "        }",
        "        var rawOut = '';",
        "        var any = false;",
    ]
    for arg in proc_data.arguments:
        ex = arg.get("execute_function", [])
        if not ex:
            continue
        var_name = option_to_var(arg["option"])
        lines.append(f"        if (opts.{var_name}) {{")
        lines.append("            any = true;")
        for fn in ex:
            lines.append(f"            rawOut += dispatchProcedure({_js_quote(fn)});")
        lines.append("        }")
    lines.extend(
        [
            "        if (!any) {",
            "            printHelp();",
            "            return;",
            "        }",
            "        writeStdout(rawOut);",
        ]
    )
    return "\n".join(lines)


def find_next_version_jxa(output_dir: Path, base_filename: str) -> tuple[str, int]:
    base_name = base_filename.replace(".js", "")
    version = 1
    while True:
        candidate = f"{base_name}_v{version}.js"
        if not (output_dir / candidate).exists():
            return candidate, version
        version += 1


def validate_generated_jxa(script_path: Path) -> tuple[bool, str]:
    try:
        r = subprocess.run(
            ["osascript", "-l", "JavaScript", str(script_path), "-h"],
            capture_output=True,
            text=True,
            timeout=20,
        )
        if r.returncode == 0:
            return True, ""
        msg = (r.stderr or r.stdout or "").strip() or f"exit {r.returncode}"
        return False, msg
    except Exception as e:
        return False, str(e)


def run_audit_jxa(repo_root: Path, script_path: Path) -> tuple[bool, str]:
    audit = repo_root / "cicd" / "audit" / "audit_jxa.py"
    if not audit.is_file():
        return True, ""
    try:
        r = subprocess.run(
            [sys.executable, str(audit), str(script_path)],
            capture_output=True,
            text=True,
            timeout=60,
            cwd=str(repo_root),
        )
        if r.returncode == 0:
            return True, ""
        return False, (r.stdout + "\n" + r.stderr).strip()
    except Exception as e:
        return False, str(e)


def build_jxa_script(yaml_path: str, force: bool = False):
    yaml_file = Path(yaml_path).resolve()
    yaml_data = read_yaml(str(yaml_file))
    if not validate_yaml(yaml_data, str(yaml_file)):
        return None

    proc_data = ProcedureData(yaml_data)
    jxa_funcs = jxa_functions_only(proc_data)
    if not jxa_funcs:
        print(f"{BOLD}{RED}No JXA functions:{RESET} add language: [jxa] on at least one function.")
        return None

    build_dir = Path(__file__).resolve().parent
    repo_root = build_dir.parent.parent
    base_path = repo_root / "attackmacos" / "core" / "base" / "base.js"
    content = base_path.read_text(encoding="utf-8")

    flag_init = build_flag_vars_jxa(proc_data)
    global_init = build_global_vars_jxa(proc_data)
    merged_flags = flag_init
    if global_init:
        merged_flags = (flag_init + "\n" if flag_init else "") + global_init

    parse_inner = build_parse_argv_body(proc_data)
    parse_block = (merged_flags + "\n" if merged_flags else "") + parse_inner

    replacements = {
        "// PLACEHOLDER_EXTRA_IMPORTS": "",
        "// PLACEHOLDER_FLAG_VARIABLES": "",
        "// PLACEHOLDER_GLOBAL_VARIABLES": "",
        "// PLACEHOLDER_FUNCTIONS": build_functions_jxa(proc_data, jxa_funcs),
        "// PLACEHOLDER_HELP_TEXT": build_help_lines_jxa(proc_data),
        "// PLACEHOLDER_PARSE_ARGV_BODY": parse_block,
        "// PLACEHOLDER_DISPATCH_BODY": build_dispatch_body(proc_data),
        "// PLACEHOLDER_MAIN_BODY": build_main_body(proc_data),
    }
    for old, new in replacements.items():
        if old not in content:
            print(f"{BOLD}{RED}BUILD FAILED:{RESET} missing placeholder {old} in base.js")
            return None
        content = content.replace(old, new)

    content = content.replace('PROCEDURE_NAME = ""', f'PROCEDURE_NAME = {_js_quote(proc_data.name)}')
    content = content.replace('TACTIC = ""', f'TACTIC = {_js_quote(yaml_data.get("tactic", ""))}')
    content = content.replace('TTP_ID = ""', f'TTP_ID = {_js_quote(yaml_data.get("ttp_id", ""))}')
    content = content.replace('PROJECT_ROOT = ""', f'PROJECT_ROOT = {_js_quote(str(repo_root))}')

    content = content.replace("[PROCEDURE_NAME]", proc_data.name)
    content = content.replace("[TACTIC]", yaml_data.get("tactic", "Discovery"))
    content = content.replace("[TTP_ID]", yaml_data.get("ttp_id", "T1082"))
    content = content.replace("[INTENT]", yaml_data.get("intent", "Security technique implementation"))
    content = content.replace(
        "[AUTHOR]",
        yaml_data.get("author", procedure_metadata.DEFAULT_PROCEDURE_AUTHOR),
    )
    content = content.replace(
        "[CREDIT_LINE_JS]",
        procedure_metadata.jxa_credit_header_line(yaml_data),
    )
    content = content.replace("[CREATED]", yaml_data.get("created", "2025-05-30"))
    content = content.replace("[UPDATED]", yaml_data.get("updated", yaml_data.get("created", "2025-05-30")))
    content = content.replace("[VERSION]", yaml_data.get("version", "1.0.0"))

    guid_value = yaml_data.get("guid", "PLACEHOLDER_GUID")
    if guid_value == "$GUID":
        content = content.replace("[GUID]", "[GUID]")
    else:
        content = content.replace("[GUID]", guid_value)

    tactic_dir = get_tactic_directory(yaml_data.get("tactic", "Discovery"))
    output_dir = repo_root / "attackmacos" / "ttp" / tactic_dir / "jxa"
    output_dir.mkdir(parents=True, exist_ok=True)

    base_filename = f"{proc_data.name}.js"
    base_output = output_dir / base_filename

    if force:
        output_file = base_output
        if base_output.exists():
            print(f"{BOLD}Force overwriting:{RESET} {output_file}")
        else:
            print(f"{BOLD}Creating:{RESET} {output_file}")
    else:
        if base_output.exists():
            vf, ver = find_next_version_jxa(output_dir, base_filename)
            output_file = output_dir / vf
            print(f"{BOLD}Creating version {ver}:{RESET} {output_file}")
        else:
            output_file = base_output
            print(f"{BOLD}Creating new script:{RESET} {output_file}")

    output_file.write_text(content, encoding="utf-8")

    ok, err = validate_generated_jxa(output_file)
    if not ok:
        print(f"{BOLD}{RED}BUILD FAILED:{RESET} osascript smoke test (-h)")
        print(err)
        output_file.unlink(missing_ok=True)
        return None

    audit_ok, audit_err = run_audit_jxa(repo_root, output_file)
    if not audit_ok:
        print(f"{BOLD}{RED}BUILD FAILED:{RESET} audit_jxa.py")
        print(audit_err)
        output_file.unlink(missing_ok=True)
        return None

    if not generate_and_update_guid(str(yaml_file), str(output_file), yaml_data, force):
        print(f"{BOLD}{YELLOW}WARNING:{RESET} GUID update failed; script is still written.")

    print(f"{BOLD}{GREEN}BUILD SUCCESS:{RESET} {output_file.name}")
    print(f"{BOLD}Location:{RESET} {output_file}")
    print(f"{BOLD}Test:{RESET} osascript -l JavaScript (smoke: -h); audit_jxa.py clean")
    return str(output_file)


def find_yamls_with_jxa() -> list[Path]:
    build_dir = Path(__file__).resolve().parent
    config_dir = build_dir.parent.parent / "attackmacos" / "core" / "config"
    out: list[Path] = []
    for pattern in ("*.yml", "*.yaml"):
        for yml in config_dir.glob(pattern):
            try:
                data = read_yaml(str(yml))
                proc = data.get("procedure", {})
                for fn in proc.get("functions", []):
                    langs = fn.get("language") or []
                    if "jxa" in langs or "javascript" in langs:
                        out.append(yml)
                        break
            except Exception:
                continue
    return sorted(set(out))


def build_all_jxa(force: bool = False) -> list[str]:
    yamls = find_yamls_with_jxa()
    print(f"\n{BOLD}Found {len(yamls)} YAML file(s) with JXA functions{RESET}")
    built = []
    for y in yamls:
        p = build_jxa_script(str(y), force=force)
        if p:
            built.append(p)
    return built


def self_test() -> bool:
    here = Path(__file__).resolve().parent
    fixture = here / "fixtures" / "jxa_procedure_minimal.yml"
    if not fixture.is_file():
        print(f"{RED}Missing fixture {fixture}{RESET}")
        return False
    td = Path(tempfile.mkdtemp(prefix="attackmacos_jxa_selftest_"))
    tmp_yaml = td / "jxa_procedure_minimal.yml"
    shutil.copy(fixture, tmp_yaml)
    print(f"{BOLD}Self-test:{RESET} build temp copy of {fixture.name} --force")
    out = build_jxa_script(str(tmp_yaml), force=True)
    if not out:
        shutil.rmtree(td, ignore_errors=True)
        return False
    try:
        r = subprocess.run(
            ["osascript", "-l", "JavaScript", out, "--hello"],
            capture_output=True,
            text=True,
            timeout=20,
        )
        if r.returncode != 0:
            print(f"{RED}osascript --hello failed:{RESET} {r.stderr}")
            return False
        if "JXA_FIXTURE_OK" not in (r.stdout or ""):
            print(f"{RED}Expected JXA_FIXTURE_OK in stdout{RESET}")
            return False
    finally:
        Path(out).unlink(missing_ok=True)
        shutil.rmtree(td, ignore_errors=True)
    print(f"{GREEN}Self-test passed.{RESET}")
    return True


def show_usage() -> None:
    print(f"\n{BOLD}Attack-macOS JXA Build Tool{RESET}")
    print("Build JXA scripts from YAML (language: [jxa]) merged with core/base/base.js")
    print(f"\n{BOLD}USAGE:{RESET}")
    print("  python3 cicd/build/build_jxa_procedure.py <yaml_file>     Build one procedure")
    print("  python3 cicd/build/build_jxa_procedure.py --all           Build all config YAMLs with JXA")
    print("  python3 cicd/build/build_jxa_procedure.py --all --force   Overwrite outputs")
    print("  python3 cicd/build/build_jxa_procedure.py --validate <f> Validate YAML (schema)")
    print("  python3 cicd/build/build_jxa_procedure.py --self-test     Build fixture + osascript check")
    print("  python3 cicd/build/build_jxa_procedure.py --help")
    print()


def main() -> None:
    argv = [a for a in sys.argv[1:] if a != "--force"]
    force = "--force" in sys.argv[1:]

    if len(argv) == 0:
        show_usage()
        sys.exit(1)
    if argv[0] == "--help":
        show_usage()
        return
    if argv[0] == "--self-test":
        sys.exit(0 if self_test() else 1)
    if argv[0] == "--all":
        build_all_jxa(force=force)
        return
    if len(argv) == 2 and argv[0] == "--validate":
        yml = argv[1]
        data = read_yaml(yml)
        if validate_yaml(data, yml):
            jf = jxa_functions_only(ProcedureData(data))
            if not jf:
                print(f"{YELLOW}Valid YAML but no JXA functions (language: [jxa]).{RESET}")
            print(f"\n{BOLD}{GREEN}VALIDATION PASSED:{RESET} {Path(yml).name}")
        else:
            sys.exit(1)
        return

    if argv[0].startswith("--"):
        print(f"{RED}Unknown option:{RESET} {argv[0]}")
        show_usage()
        sys.exit(1)

    build_jxa_script(argv[0], force=force)


if __name__ == "__main__":
    main()
