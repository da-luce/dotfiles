#!/usr/bin/env python3
"""Run PR nit checks. Thin wrapper around the databricks package.

Stdlib only. Run from a git checkout:

  ./check_pr_nits.py
  ./check_pr_nits.py --module databricks.scala --module databricks.commit
  python -m databricks --base origin/main

Modules:
  databricks.commit   conventional commits, merge commits, AI attribution
  databricks.scala    logging, imports, Option.get, companion order, etc.
  databricks.rust     .unwrap() on added lines
  databricks.comments scaladoc length, em-dash, semicolons, curly quotes
  databricks.refactor dropped TODO/FIXME markers
  databricks.misc     debug leftovers, copyright year
"""

from __future__ import annotations

import sys
from pathlib import Path

# Allow `python scripts/check_pr_nits.py` without installing the package.
sys.path.insert(0, str(Path(__file__).resolve().parent))

from databricks.__main__ import main

if __name__ == "__main__":
    raise SystemExit(main())
