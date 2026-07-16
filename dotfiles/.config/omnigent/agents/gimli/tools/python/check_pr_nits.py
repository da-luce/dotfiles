"""Omnigent tools: mechanical PR nit checks for gimli.

Auto-discovered from tools/python/. Each @tool-decorated function is exposed to
gimli by its function name (check_pr_nits, check_pr_nits_scala,
check_pr_nits_commit). The heavy lifting lives in the dotfiles `databricks`
package; these are thin, tainted entry points.
"""

from __future__ import annotations

import os
import sys
from pathlib import Path
from typing import Optional

from omnigent.tools import tool


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


def _run(base_ref: Optional[str], modules: Optional[list]) -> list:
    scripts = _scripts_dir()
    if str(scripts) not in sys.path:
        sys.path.insert(0, str(scripts))

    from databricks.runner import run_all

    findings = run_all(base_ref=base_ref, cwd=Path.cwd(), modules=modules)
    return [finding.to_dict() for finding in findings]


@tool
def check_pr_nits(base_ref: Optional[str] = None) -> list:
    """Run all mechanical PR nit checks on the current branch.

    Returns structured findings (rule, file, line, severity, message, module).
    Run this before dispatching agent_d_databricks and pass the output to that
    reviewer so it focuses on subjective /databricks-review items only.

    Args:
        base_ref: Base ref to diff against. Defaults to the branch's merge base.
    """
    return _run(base_ref, None)


@tool
def check_pr_nits_scala(base_ref: Optional[str] = None) -> list:
    """Run only the databricks.scala mechanical checks on the current branch.

    Args:
        base_ref: Base ref to diff against. Defaults to the branch's merge base.
    """
    return _run(base_ref, ["databricks.scala"])


@tool
def check_pr_nits_commit(base_ref: Optional[str] = None) -> list:
    """Run only the databricks.commit mechanical checks on the current branch.

    Args:
        base_ref: Base ref to diff against. Defaults to the branch's merge base.
    """
    return _run(base_ref, ["databricks.commit"])
