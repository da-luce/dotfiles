"""Refactor regression checks (TODO preservation, etc.)."""

from __future__ import annotations

import re
from pathlib import Path

from databricks.git import parse_diff
from databricks.types import Finding

MODULE = "databricks.refactor"

TODO_MARK = re.compile(r"\b(?:TODO|FIXME|XXX)\b", re.IGNORECASE)


def check_dropped_todos(base_ref: str, cwd: Path | None = None) -> list[Finding]:
    added, removed = parse_diff(base_ref, cwd=cwd)
    removed_marks = [
        line for line in removed if TODO_MARK.search(line.text)
    ]
    if not removed_marks:
        return []

    added_text = "\n".join(line.text for line in added)
    findings: list[Finding] = []
    for line in removed_marks:
        mark = TODO_MARK.search(line.text)
        if not mark:
            continue
        token = mark.group(0)
        # Same mark text re-added somewhere in the diff?
        if token in added_text and line.text.strip() in added_text:
            continue
        findings.append(
            Finding(
                rule="todo_dropped_in_refactor",
                file=line.file,
                line=line.line,
                severity="warn",
                message=f"removed `{token}` not clearly re-added in diff: {line.text.strip()[:120]}",
                module=MODULE,
            )
        )
    return findings


def run(base_ref: str, cwd: Path | None = None) -> list[Finding]:
    return check_dropped_todos(base_ref, cwd=cwd)
