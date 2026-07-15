"""CLI entry point: python -m databricks"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from databricks.runner import MODULES, run_all, to_json


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Run PR nit checks against the current branch.",
    )
    parser.add_argument(
        "--base",
        help="Base ref (default: auto-detect origin/HEAD, origin/main, etc.)",
    )
    parser.add_argument(
        "--cwd",
        type=Path,
        default=Path.cwd(),
        help="Repository root (default: current directory)",
    )
    parser.add_argument(
        "--module",
        action="append",
        dest="modules",
        choices=[name for name, _ in MODULES],
        help="Run only selected module(s); repeatable",
    )
    parser.add_argument(
        "--fail-on",
        choices=("error", "warn", "any"),
        default="error",
        help="Exit non-zero when findings at or above this severity exist",
    )
    args = parser.parse_args(argv)

    try:
        findings = run_all(base_ref=args.base, cwd=args.cwd, modules=args.modules)
    except RuntimeError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2

    print(to_json(findings))

    if args.fail_on == "any" and findings:
        return 1
    if args.fail_on == "warn" and any(f.severity in ("error", "warn") for f in findings):
        return 1
    if args.fail_on == "error" and any(f.severity == "error" for f in findings):
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
