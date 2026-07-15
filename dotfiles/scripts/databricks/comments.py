"""Comment and documentation quality checks."""

from __future__ import annotations

import re
from pathlib import Path

from databricks.git import AddedLine, parse_diff
from databricks.types import Finding

MODULE = "databricks.comments"

SCALADOC_START = re.compile(r"/\*\*")
EM_DASH = re.compile(r"[—–]")
SEMICOLON_IN_COMMENT = re.compile(r"//.*;|/\*.*;")
CURLY_QUOTES = re.compile(r"[\u201c\u201d\u2018\u2019]")

MAX_SCALADOC_CHARS = 400
MAX_SCALADOC_LINES = 8


def _comment_like_paths(added: list[AddedLine]) -> list[AddedLine]:
    exts = (".scala", ".java", ".kt", ".rs", ".py", ".md")
    return [line for line in added if line.file.endswith(exts)]


def check_overlong_scaladoc(added: list[AddedLine]) -> list[Finding]:
    findings: list[Finding] = []
    for line in added:
        if not line.file.endswith((".scala", ".java")):
            continue
        if not SCALADOC_START.search(line.text):
            continue
        text = line.text.strip()
        if len(text) > MAX_SCALADOC_CHARS:
            findings.append(
                Finding(
                    rule="overlong_scaladoc",
                    file=line.file,
                    line=line.line,
                    severity="warn",
                    message=f"scaladoc block start exceeds {MAX_SCALADOC_CHARS} chars on one line",
                    module=MODULE,
                )
            )
    return findings


def check_scaladoc_blocks_in_diff(added: list[AddedLine]) -> list[Finding]:
    """Flag added scaladoc blocks that span many lines in the diff."""
    findings: list[Finding] = []
    by_file: dict[str, list[AddedLine]] = {}
    for line in added:
        if line.file.endswith((".scala", ".java")):
            by_file.setdefault(line.file, []).append(line)

    for path, lines in by_file.items():
        block: list[AddedLine] = []
        for line in sorted(lines, key=lambda item: item.line):
            if "/**" in line.text or block:
                block.append(line)
            if block and "*/" in line.text:
                if len(block) > MAX_SCALADOC_LINES or sum(len(l.text) for l in block) > MAX_SCALADOC_CHARS:
                    findings.append(
                        Finding(
                            rule="overlong_scaladoc",
                            file=path,
                            line=block[0].line,
                            severity="warn",
                            message=(
                                f"added scaladoc block is {len(block)} lines / "
                                f"{sum(len(l.text) for l in block)} chars; keep docs concise"
                            ),
                            module=MODULE,
                        )
                    )
                block = []
    return findings


def check_em_dash_in_comments(added: list[AddedLine]) -> list[Finding]:
    findings: list[Finding] = []
    for line in _comment_like_paths(added):
        stripped = line.text.strip()
        if not (stripped.startswith("//") or stripped.startswith("*") or stripped.startswith("/*")):
            continue
        if not EM_DASH.search(line.text):
            continue
        findings.append(
            Finding(
                rule="em_dash_in_comment",
                file=line.file,
                line=line.line,
                severity="warn",
                message="em dash in comment; prefer plain punctuation",
                module=MODULE,
            )
        )
    return findings


def check_semicolon_in_comments(added: list[AddedLine]) -> list[Finding]:
    findings: list[Finding] = []
    for line in _comment_like_paths(added):
        stripped = line.text.strip()
        if not (stripped.startswith("//") or stripped.startswith("*") or stripped.startswith("/*")):
            continue
        if not SEMICOLON_IN_COMMENT.search(line.text):
            continue
        findings.append(
            Finding(
                rule="semicolon_in_comment",
                file=line.file,
                line=line.line,
                severity="warn",
                message="semicolon in comment",
                module=MODULE,
            )
        )
    return findings


def check_curly_quotes(added: list[AddedLine]) -> list[Finding]:
    findings: list[Finding] = []
    for line in added:
        if not CURLY_QUOTES.search(line.text):
            continue
        findings.append(
            Finding(
                rule="curly_quotes",
                file=line.file,
                line=line.line,
                severity="warn",
                message="curly quote character in added line; use straight quotes",
                module=MODULE,
            )
        )
    return findings


def run(base_ref: str, cwd: Path | None = None) -> list[Finding]:
    added, _removed = parse_diff(base_ref, cwd=cwd)
    return [
        *check_overlong_scaladoc(added),
        *check_scaladoc_blocks_in_diff(added),
        *check_em_dash_in_comments(added),
        *check_semicolon_in_comments(added),
        *check_curly_quotes(added),
    ]
