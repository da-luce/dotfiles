"""Omnigent tool: mechanical PR nit checks for gimli."""

from __future__ import annotations

import os
import sys
from pathlib import Path


def _scripts_dir() -> Path:
    env = os.environ.get("DOTFILES_SCRIPTS")
    if env:
        return Path(env)

    for parent in Path(__file__).resolve().parents:
        candidate = parent / "scripts" / "databricks" / "runner.py"
        if candidate.is_file():
            return parent / "scripts"

    fallback = Path.home() / ".dotfiles" / "dotfiles" / "scripts"
    if (fallback / "databricks" / "runner.py").is_file():
        return fallback

    raise RuntimeError(
        "could not locate dotfiles/scripts; set DOTFILES_SCRIPTS to the scripts directory"
    )


def _run(base_ref: str | None = None, modules: list[str] | None = None) -> list[dict]:
    scripts = _scripts_dir()
    if str(scripts) not in sys.path:
        sys.path.insert(0, str(scripts))

    from databricks.runner import run_all

    findings = run_all(base_ref=base_ref, cwd=Path.cwd(), modules=modules)
    return [finding.to_dict() for finding in findings]


def check_pr_nits(base_ref: str | None = None) -> list[dict]:
    """Run all mechanical PR nit checks on the current branch.

    Returns structured findings (rule, file, line, severity, message, module).
    Run this before dispatching agent_d_databricks; pass the output to that
    reviewer so it can focus on subjective /databricks-review items only.
    """
    return _run(base_ref=base_ref)


def check_pr_nits_scala(base_ref: str | None = None) -> list[dict]:
    """Run databricks.scala mechanical checks only."""
    return _run(base_ref=base_ref, modules=["databricks.scala"])


def check_pr_nits_commit(base_ref: str | None = None) -> list[dict]:
    """Run databricks.commit mechanical checks only."""
    return _run(base_ref=base_ref, modules=["databricks.commit"])
