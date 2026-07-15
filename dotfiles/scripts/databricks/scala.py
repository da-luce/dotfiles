"""Scala-specific checks on added lines and touched .scala files."""

from __future__ import annotations

import re
from pathlib import Path

from databricks.git import AddedLine, changed_files, parse_diff, read_repo_file
from databricks.types import Finding

MODULE = "databricks.scala"

PLAIN_STRING_LOG = re.compile(
    r"\b(logError|logWarning|logInfo|logDebug|logTrace)\(\s*(s?[\"'])",
)
UNNECESSARY_BRACE_INTERP = re.compile(r"\$\{([A-Za-z_][A-Za-z0-9_]*)\}(?![\w.])")
VAL_FUNCTION_DEF = re.compile(r"^\s*val\s+\w+\s*[:=].*=>")
CONSTANT_LIKE_VAL = re.compile(
    r"^\s*val\s+([a-z][a-zA-Z0-9]*)\s*[:=]\s*"
    r"(?:\d+|true|false|null|\".*\"|'.*'|\d+\.\w+|Duration\.|TimeUnit\.)",
)
FQCN_IN_BODY = re.compile(r"\b(?:com\.databricks\.|org\.apache\.spark\.)\w+")
OPTION_GET = re.compile(r"\.(?:get|getOrElse)\s*\(")
WILDCARD_IMPORT = re.compile(r"^\s*import\s+.+(?:\._|\{[^}]*,[^}]*\})\s*$")
IMPORT_LINE = re.compile(r"^\s*import\s+(.+)$")


def _scala_added(added: list[AddedLine]) -> list[AddedLine]:
    return [line for line in added if line.file.endswith(".scala")]


def _scala_touched(files: list[str]) -> list[str]:
    return [path for path in files if path.endswith(".scala")]


def check_plain_string_logging(added: list[AddedLine]) -> list[Finding]:
    findings: list[Finding] = []
    for line in _scala_added(added):
        if not PLAIN_STRING_LOG.search(line.text):
            continue
        findings.append(
            Finding(
                rule="plain_string_logging",
                file=line.file,
                line=line.line,
                severity="error",
                message="logging call uses plain string; use structured log interpolator",
                module=MODULE,
            )
        )
    return findings


def check_unnecessary_brace_interpolation(added: list[AddedLine]) -> list[Finding]:
    findings: list[Finding] = []
    for line in _scala_added(added):
        for match in UNNECESSARY_BRACE_INTERP.finditer(line.text):
            var = match.group(1)
            findings.append(
                Finding(
                    rule="unnecessary_brace_interpolation",
                    file=line.file,
                    line=line.line,
                    severity="warn",
                    message=f"unnecessary brace interpolation around {var}; use ${var}",
                    module=MODULE,
                )
            )
    return findings


def check_val_function_defs(added: list[AddedLine]) -> list[Finding]:
    findings: list[Finding] = []
    for line in _scala_added(added):
        if not VAL_FUNCTION_DEF.match(line.text):
            continue
        findings.append(
            Finding(
                rule="val_function_def",
                file=line.file,
                line=line.line,
                severity="warn",
                message="function defined as val; prefer def unless required for FP patterns",
                module=MODULE,
            )
        )
    return findings


def check_constant_naming(added: list[AddedLine]) -> list[Finding]:
    findings: list[Finding] = []
    for line in _scala_added(added):
        match = CONSTANT_LIKE_VAL.match(line.text)
        if not match:
            continue
        name = match.group(1)
        findings.append(
            Finding(
                rule="constant_not_all_caps",
                file=line.file,
                line=line.line,
                severity="warn",
                message=f'constant-like val `{name}` should be ALL_CAPS',
                module=MODULE,
            )
        )
    return findings


def check_fqcn_in_body(added: list[AddedLine]) -> list[Finding]:
    findings: list[Finding] = []
    for line in _scala_added(added):
        stripped = line.text.strip()
        if stripped.startswith("import "):
            continue
        if not FQCN_IN_BODY.search(line.text):
            continue
        findings.append(
            Finding(
                rule="fully_qualified_name_in_body",
                file=line.file,
                line=line.line,
                severity="warn",
                message="inline fully-qualified name; prefer import",
                module=MODULE,
            )
        )
    return findings


def check_option_get(added: list[AddedLine]) -> list[Finding]:
    findings: list[Finding] = []
    for line in _scala_added(added):
        if not OPTION_GET.search(line.text):
            continue
        findings.append(
            Finding(
                rule="option_get_or_get_or_else",
                file=line.file,
                line=line.line,
                severity="warn",
                message=".get or .getOrElse on Option; prefer pattern matching or safer accessors",
                module=MODULE,
            )
        )
    return findings


def check_companion_before_class(touched: list[str], cwd: Path | None = None) -> list[Finding]:
    findings: list[Finding] = []
    for path in _scala_touched(touched):
        try:
            content = read_repo_file(path, cwd=cwd)
        except OSError:
            continue
        for name in _type_names(content):
            class_line = _first_line_for(content, rf"^\s*(?:final\s+)?class\s+{re.escape(name)}\b")
            object_line = _first_line_for(content, rf"^\s*object\s+{re.escape(name)}\b")
            if class_line and object_line and object_line < class_line:
                findings.append(
                    Finding(
                        rule="companion_before_class",
                        file=path,
                        line=object_line,
                        severity="warn",
                        message=f"companion object `{name}` appears before class; declare class first",
                        module=MODULE,
                    )
                )
    return findings


def check_wildcard_imports(added: list[AddedLine]) -> list[Finding]:
    findings: list[Finding] = []
    for line in _scala_added(added):
        if not WILDCARD_IMPORT.match(line.text):
            continue
        findings.append(
            Finding(
                rule="wildcard_import",
                file=line.file,
                line=line.line,
                severity="warn",
                message="wildcard or multi-symbol import added",
                module=MODULE,
            )
        )
    return findings


def check_duplicate_imports(touched: list[str], cwd: Path | None = None) -> list[Finding]:
    findings: list[Finding] = []
    for path in _scala_touched(touched):
        try:
            content = read_repo_file(path, cwd=cwd)
        except OSError:
            continue
        seen: dict[str, int] = {}
        for lineno, raw in enumerate(content.splitlines(), start=1):
            match = IMPORT_LINE.match(raw)
            if not match:
                continue
            stmt = match.group(1).strip()
            if stmt in seen:
                findings.append(
                    Finding(
                        rule="duplicate_import",
                        file=path,
                        line=lineno,
                        severity="warn",
                        message=f"duplicate import `{stmt}` (first at line {seen[stmt]})",
                        module=MODULE,
                    )
                )
            else:
                seen[stmt] = lineno
    return findings


def _type_names(content: str) -> set[str]:
    names: set[str] = set()
    for pattern in (r"^\s*(?:final\s+)?class\s+(\w+)", r"^\s*object\s+(\w+)"):
        for line in content.splitlines():
            match = re.match(pattern, line)
            if match:
                names.add(match.group(1))
    return names


def _first_line_for(content: str, pattern: str) -> int | None:
    compiled = re.compile(pattern)
    for lineno, line in enumerate(content.splitlines(), start=1):
        if compiled.match(line):
            return lineno
    return None


def run(base_ref: str, cwd: Path | None = None) -> list[Finding]:
    added, _removed = parse_diff(base_ref, cwd=cwd)
    touched = changed_files(base_ref, cwd=cwd)
    return [
        *check_plain_string_logging(added),
        *check_unnecessary_brace_interpolation(added),
        *check_val_function_defs(added),
        *check_constant_naming(added),
        *check_fqcn_in_body(added),
        *check_option_get(added),
        *check_wildcard_imports(added),
        *check_companion_before_class(touched, cwd=cwd),
        *check_duplicate_imports(touched, cwd=cwd),
    ]
