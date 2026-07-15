"""Rust-specific checks on added lines."""

from __future__ import annotations

import re
from pathlib import Path

from databricks.git import AddedLine, parse_diff
from databricks.types import Finding

MODULE = "databricks.rust"

UNWRAP = re.compile(r"\.unwrap\(\)")


def _rust_added(added: list[AddedLine]) -> list[AddedLine]:
    return [line for line in added if line.file.endswith(".rs")]


def check_unwrap(added: list[AddedLine]) -> list[Finding]:
    findings: list[Finding] = []
    for line in _rust_added(added):
        if not UNWRAP.search(line.text):
            continue
        findings.append(
            Finding(
                rule="rust_unwrap",
                file=line.file,
                line=line.line,
                severity="warn",
                message=".unwrap() on added line; prefer explicit error handling",
                module=MODULE,
            )
        )
    return findings


def run(base_ref: str, cwd: Path | None = None) -> list[Finding]:
    added, _removed = parse_diff(base_ref, cwd=cwd)
    return check_unwrap(added)
