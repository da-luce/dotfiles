"""Omnigent tool: mechanical PR nit checks for gimli.

Auto-discovered from tools/python/. A single @tool-decorated function is
exposed (this build's local dispatch registers one tool per file, keyed by
filename, so extra module-level @tool functions here would not be dispatchable).
The heavy lifting lives in the dotfiles `databricks` package; this is a thin,
tainted entry point.
"""

from __future__ import annotations

import os
import sys
from pathlib import Path
from typing import Optional

from omnigent_client import tool


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


def _require_repo(repo_root: Optional[str]) -> Path:
    # The tool subprocess does NOT inherit gimli's worktree cwd (it launches from
    # the omnigent tool-runner's dir, e.g. the home dir), so we cannot infer the
    # checkout from Path.cwd(). gimli passes its worktree root explicitly, taken
    # from the preflight's `git rev-parse --show-toplevel`.
    root = Path(repo_root).expanduser() if repo_root else Path.cwd()
    if not (root / ".git").exists():
        raise RuntimeError(
            f"{root} is not a git checkout; pass repo_root=<the ticket's "
            f"worktree root> (gimli takes this from the roster preflight's "
            f"`git rev-parse --show-toplevel`). The tool subprocess does not "
            f"inherit gimli's cwd, so repo_root cannot be defaulted reliably."
        )
    return root


@tool(strict=False)
def check_pr_nits(
    repo_root: str,
    base_ref: Optional[str] = None,
    modules: Optional[list[str]] = None,
) -> list[dict]:
    """Run mechanical PR nit checks on a git worktree and return findings.

    Runs against ``repo_root``, which must be the ticket's git checkout. This
    tool's subprocess does NOT inherit gimli's cwd, so the worktree cannot be
    inferred and must be passed explicitly (gimli takes it from the roster
    preflight's `git rev-parse --show-toplevel`). Each finding is a dict of
    rule, file, line, severity, message, module. Run this before dispatching
    agent_d_databricks and pass the output to that reviewer so it focuses on
    subjective /databricks-review items only.

    Args:
        repo_root: Absolute path to the ticket's git worktree to check.
        base_ref: Base ref to diff against (e.g. origin/main or HEAD~1).
            Defaults to the branch's merge base with its detected default branch.
        modules: Subset of check modules to run, e.g. ["databricks.scala"] or
            ["databricks.commit"]. Defaults to all modules.
    """
    root = _require_repo(repo_root)

    scripts = _scripts_dir()
    if str(scripts) not in sys.path:
        sys.path.insert(0, str(scripts))

    from databricks.runner import run_all

    findings = run_all(base_ref=base_ref, cwd=root, modules=modules)
    return [finding.to_dict() for finding in findings]
