"""Orchestrate all PR nit check modules."""

from __future__ import annotations

import json
from pathlib import Path

from databricks import comments, commit, misc, refactor, rust, scala
from databricks.git import merge_base, resolve_base_ref
from databricks.types import Finding

MODULES = (
    ("databricks.commit", commit.run),
    ("databricks.scala", scala.run),
    ("databricks.rust", rust.run),
    ("databricks.comments", comments.run),
    ("databricks.refactor", refactor.run),
    ("databricks.misc", misc.run),
)


def run_all(
    base_ref: str | None = None,
    cwd: Path | str | None = None,
    modules: list[str] | None = None,
) -> list[Finding]:
    root = Path(cwd) if cwd else Path.cwd()
    resolved = resolve_base_ref(base_ref, cwd=root)
    base = merge_base(resolved, cwd=root)

    selected = {name for name, _ in MODULES}
    if modules:
        selected = set(modules)

    findings: list[Finding] = []
    for name, runner in MODULES:
        if name not in selected:
            continue
        findings.extend(runner(base, cwd=root))
    return findings


def to_json(findings: list[Finding]) -> str:
    return json.dumps([f.to_dict() for f in findings], indent=2)
