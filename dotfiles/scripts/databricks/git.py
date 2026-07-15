"""Git diff and commit helpers shared across check modules."""

from __future__ import annotations

import re
import subprocess
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class AddedLine:
    file: str
    line: int
    text: str


@dataclass(frozen=True)
class RemovedLine:
    file: str
    line: int
    text: str


def _run_git(args: list[str], cwd: Path | None = None) -> str:
    result = subprocess.run(
        ["git", *args],
        cwd=cwd,
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or f"git {' '.join(args)} failed")
    return result.stdout


def resolve_base_ref(base_ref: str | None, cwd: Path | None = None) -> str:
    if base_ref:
        return base_ref
    for candidate in ("origin/HEAD", "origin/main", "origin/master", "main", "master"):
        try:
            _run_git(["rev-parse", "--verify", candidate], cwd=cwd)
            if candidate == "origin/HEAD":
                ref = _run_git(["symbolic-ref", "refs/remotes/origin/HEAD"], cwd=cwd).strip()
                return ref.removeprefix("refs/remotes/")
            return candidate
        except RuntimeError:
            continue
    raise RuntimeError("could not resolve base ref; pass --base explicitly")


def merge_base(base_ref: str, cwd: Path | None = None) -> str:
    return _run_git(["merge-base", "HEAD", base_ref], cwd=cwd).strip()


def changed_files(base_ref: str, cwd: Path | None = None) -> list[str]:
    out = _run_git(["diff", "--name-only", f"{base_ref}...HEAD"], cwd=cwd)
    return [line for line in out.splitlines() if line.strip()]


def parse_diff(base_ref: str, cwd: Path | None = None) -> tuple[list[AddedLine], list[RemovedLine]]:
    diff = _run_git(["diff", "--unified=0", f"{base_ref}...HEAD"], cwd=cwd)
    added: list[AddedLine] = []
    removed: list[RemovedLine] = []
    current_file: str | None = None
    new_line = 0

    hunk_new = re.compile(r"^@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@")

    for raw in diff.splitlines():
        if raw.startswith("+++ b/"):
            current_file = raw[6:]
            continue
        if raw.startswith("+++ /dev/null") or raw.startswith("--- "):
            continue
        match = hunk_new.match(raw)
        if match:
            new_line = int(match.group(1))
            continue
        if current_file is None or not raw:
            continue
        if raw.startswith("+") and not raw.startswith("+++"):
            added.append(AddedLine(current_file, new_line, raw[1:]))
            new_line += 1
        elif raw.startswith("-") and not raw.startswith("---"):
            removed.append(RemovedLine(current_file, new_line, raw[1:]))
        elif raw.startswith(" "):
            new_line += 1

    return added, removed


def commit_messages(base_ref: str, cwd: Path | None = None) -> list[tuple[str, str]]:
    """Return (sha, subject) for each commit in base_ref..HEAD."""
    out = _run_git(
        ["log", "--format=%H%x09%s", f"{base_ref}..HEAD"],
        cwd=cwd,
    )
    commits: list[tuple[str, str]] = []
    for line in out.splitlines():
        if not line.strip():
            continue
        sha, subject = line.split("\t", 1)
        commits.append((sha, subject))
    return commits


def merge_commits(base_ref: str, cwd: Path | None = None) -> list[tuple[str, str]]:
    out = _run_git(
        ["log", "--merges", "--format=%H%x09%s", f"{base_ref}..HEAD"],
        cwd=cwd,
    )
    commits: list[tuple[str, str]] = []
    for line in out.splitlines():
        if not line.strip():
            continue
        sha, subject = line.split("\t", 1)
        commits.append((sha, subject))
    return commits


def commit_bodies(base_ref: str, cwd: Path | None = None) -> list[tuple[str, str]]:
    out = _run_git(
        ["log", "--format=%H%x09%B", f"{base_ref}..HEAD"],
        cwd=cwd,
    )
    blocks = [b for b in out.split("\n\n") if b.strip()]
    commits: list[tuple[str, str]] = []
    for block in blocks:
        sha, _, body = block.partition("\n")
        sha = sha.strip()
        if "\t" in sha:
            sha, first_line = sha.split("\t", 1)
            body = first_line + ("\n" + body if body else "")
        commits.append((sha, body))
    return commits


def read_repo_file(path: str, cwd: Path | None = None) -> str:
    root = cwd or Path.cwd()
    return (root / path).read_text(encoding="utf-8", errors="replace")
