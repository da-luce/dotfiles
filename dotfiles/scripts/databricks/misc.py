"""Cross-language hygiene checks on touched files and added lines."""

from __future__ import annotations

import datetime as dt
import re
from pathlib import Path

from databricks.git import AddedLine, changed_files, parse_diff, read_repo_file
from databricks.types import Finding

MODULE = "databricks.misc"

# Unambiguous debug leftovers only. Bare `print(` is intentionally excluded:
# it is legitimate in Python CLIs and produces too much noise.
DEBUG_LEFTOVER = re.compile(
    r"("
    r"\bprintln\s*\(|"           # Scala / Java / Kotlin
    r"\bSystem\.out\.print|"     # Java
    r"\bconsole\.(?:log|debug|trace)\s*\(|"  # JS / TS
    r"\bdebugger\b|"             # JS
    r"\bdbg!\s*\(|"              # Rust
    r"\beprintln!\s*\(|"         # Rust
    r"\bpdb\.set_trace\s*\(|"    # Python
    r"\bbreakpoint\s*\(\s*\)"    # Python
    r")"
)
COPYRIGHT_YEAR = re.compile(r"Copyright[^\d]*(20\d{2})")
SOURCE_EXTS = (".scala", ".java", ".kt", ".rs", ".py", ".go", ".ts", ".tsx")


def _source_touched(files: list[str]) -> list[str]:
    return [path for path in files if path.endswith(SOURCE_EXTS)]


def check_debug_leftovers(
    added: list[AddedLine],
    touched: list[str],
    cwd: Path | None = None,
) -> list[Finding]:
    findings: list[Finding] = []
    seen: set[tuple[str, int]] = set()

    for line in added:
        if not line.file.endswith(SOURCE_EXTS):
            continue
        if not DEBUG_LEFTOVER.search(line.text):
            continue
        key = (line.file, line.line)
        if key in seen:
            continue
        seen.add(key)
        findings.append(
            Finding(
                rule="debug_leftover",
                file=line.file,
                line=line.line,
                severity="error",
                message="debug leftover on added line",
                module=MODULE,
            )
        )

    for path in _source_touched(touched):
        try:
            content = read_repo_file(path, cwd=cwd)
        except OSError:
            continue
        for lineno, raw in enumerate(content.splitlines(), start=1):
            if not DEBUG_LEFTOVER.search(raw):
                continue
            key = (path, lineno)
            if key in seen:
                continue
            seen.add(key)
            findings.append(
                Finding(
                    rule="debug_leftover",
                    file=path,
                    line=lineno,
                    severity="error",
                    message="debug leftover in touched file",
                    module=MODULE,
                )
            )
    return findings


def check_copyright_year(touched: list[str], cwd: Path | None = None) -> list[Finding]:
    current_year = str(dt.date.today().year)
    findings: list[Finding] = []
    for path in _source_touched(touched):
        try:
            content = read_repo_file(path, cwd=cwd)
        except OSError:
            continue
        if "Copyright" not in content:
            continue
        for lineno, raw in enumerate(content.splitlines(), start=1):
            match = COPYRIGHT_YEAR.search(raw)
            if not match:
                continue
            year = match.group(1)
            if year == current_year:
                continue
            findings.append(
                Finding(
                    rule="copyright_year",
                    file=path,
                    line=lineno,
                    severity="warn",
                    message=f"copyright year {year}; expected {current_year}",
                    module=MODULE,
                )
            )
    return findings


def run(base_ref: str, cwd: Path | None = None) -> list[Finding]:
    added, _removed = parse_diff(base_ref, cwd=cwd)
    touched = changed_files(base_ref, cwd=cwd)
    return [
        *check_debug_leftovers(added, touched, cwd=cwd),
        *check_copyright_year(touched, cwd=cwd),
    ]
