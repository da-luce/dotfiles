#!/usr/bin/env python3
"""Pull my open Jira tickets and write a Dataview data file of hygiene flags.

Read-only. Stdlib only, so it runs anywhere (cron included) with just Python 3.
It does NOT touch PRs/CI/goals -- those need other systems. It covers the
Jira-derivable checks: overdue, stuck-in-closed-sprint, due-outside-window,
no-sprint, missing due/points.

Auth (env vars):
  JIRA_BASE_URL   e.g. https://databricks.atlassian.net
  JIRA_EMAIL      your atlassian account email
  JIRA_TOKEN      an API token from id.atlassian.com/manage-profile/security/api-tokens

Config (env vars, optional):
  TICKET_REVIEW_DATA_FILE   path to write the Dataview data note.
                            If unset/unwritable, prints the file to stdout instead.
  JIRA_SPRINT_FIELD         sprint custom field id (default customfield_10007)
  JIRA_POINTS_FIELD         story points custom field id (default customfield_10004)

Usage:
  ./ticket_review_pull.py            # write data file (or stdout) + short summary
  ./ticket_review_pull.py --stdout   # force print, never write
"""

import base64
import datetime as dt
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request

SPRINT_FIELD = os.environ.get("JIRA_SPRINT_FIELD", "customfield_10007")
POINTS_FIELD = os.environ.get("JIRA_POINTS_FIELD", "customfield_10004")
JQL = "assignee = currentUser() AND statusCategory != Done ORDER BY updated DESC"
SEV = {"high": "1-high", "med": "2-med", "low": "3-low"}


def _fail(msg):
    print(f"error: {msg}", file=sys.stderr)
    sys.exit(1)


def _auth_header():
    base = os.environ.get("JIRA_BASE_URL", "").rstrip("/")
    email = os.environ.get("JIRA_EMAIL", "")
    token = os.environ.get("JIRA_TOKEN", "")
    if not (base and email and token):
        _fail("set JIRA_BASE_URL, JIRA_EMAIL, JIRA_TOKEN")
    raw = f"{email}:{token}".encode()
    return base, "Basic " + base64.b64encode(raw).decode()


def _get(base, auth, path, params):
    url = f"{base}{path}?{urllib.parse.urlencode(params)}"
    req = urllib.request.Request(url, headers={"Authorization": auth, "Accept": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            return json.load(r)
    except urllib.error.HTTPError as e:
        _fail(f"jira {e.code} on {path}: {e.read().decode()[:300]}")
    except urllib.error.URLError as e:
        _fail(f"jira unreachable: {e.reason}")


def fetch_issues(base, auth):
    """Page through the search API. Returns list of raw issue dicts."""
    fields = ["summary", "status", "duedate", "priority", SPRINT_FIELD, POINTS_FIELD]
    out, start = [], 0
    while True:
        page = _get(base, auth, "/rest/api/3/search", {
            "jql": JQL, "startAt": start, "maxResults": 100, "fields": ",".join(fields),
        })
        issues = page.get("issues", [])
        out.extend(issues)
        if start + len(issues) >= page.get("total", 0) or not issues:
            break
        start += len(issues)
    return out


def active_sprint(issue):
    """Return the active sprint dict from an issue's sprint field, else None.

    The field is a list of sprint objects; a ticket can carry a closed + active
    pair when it rolls over. Prefer the one whose state == 'active'.
    """
    val = issue["fields"].get(SPRINT_FIELD)
    if not isinstance(val, list):
        return None
    active = [s for s in val if isinstance(s, dict) and s.get("state") == "active"]
    return active[-1] if active else None


def any_sprint(issue):
    val = issue["fields"].get(SPRINT_FIELD)
    return val[-1] if isinstance(val, list) and val else None


def _date(s):
    return dt.date.fromisoformat(s[:10]) if s else None


def evaluate(issues, today):
    """Return list of flag dicts: {ticket, kind, sev, problem, action, due}."""
    flags = []
    for it in issues:
        key = it["key"]
        f = it["fields"]
        status = (f.get("status") or {}).get("name", "?")
        due = _date(f.get("duedate"))
        sp = any_sprint(it)
        sp_state = sp.get("state") if sp else None
        sp_end = _date(sp.get("endDate")) if sp else None
        sp_start = _date(sp.get("startDate")) if sp else None
        pts = f.get(POINTS_FIELD)

        # high: overdue within active sprint
        if due and due < today and sp_state == "active":
            flags.append(dict(ticket=key, kind="overdue", sev="high",
                              problem=f"overdue ({due}), still {status}",
                              action="close or re-date", due=str(due)))
        # high: unfinished ticket in a closed sprint
        if sp_state == "closed":
            flags.append(dict(ticket=key, kind="stuck-sprint", sev="high",
                              problem=f"unfinished in closed sprint '{sp.get('name')}'",
                              action="roll to active sprint or close", due=str(due) if due else ""))
        # low: due outside the sprint window
        if due and sp_state == "active" and sp_start and sp_end and not (sp_start <= due <= sp_end):
            flags.append(dict(ticket=key, kind="due-window", sev="low",
                              problem=f"due {due} outside sprint window",
                              action="re-date into sprint", due=str(due)))
        # low: no sprint at all
        if sp is None:
            flags.append(dict(ticket=key, kind="no-sprint", sev="low",
                              problem="no sprint assigned",
                              action="assign to a sprint or backlog", due=str(due) if due else ""))
        # low: in active sprint but missing due or points
        if sp_state == "active" and due is None:
            flags.append(dict(ticket=key, kind="no-due", sev="low",
                              problem="in sprint, no due date",
                              action="set a due date", due=""))
        if sp_state == "active" and pts in (None, 0):
            flags.append(dict(ticket=key, kind="no-points", sev="low",
                              problem="in sprint, no story points",
                              action="estimate points", due=""))
    return flags


FLAG_RE = re.compile(r"\[ticket:: (?P<ticket>[^\]]+)\].*?\[kind:: (?P<kind>[^\]]+)\]")
FLAGGED_RE = re.compile(r"\[flagged:: (?P<d>\d{4}-\d{2}-\d{2})\]")
RESOLVED_RE = re.compile(r"\[resolved:: (?P<d>\d{4}-\d{2}-\d{2})\]")


def parse_existing(text):
    """Map (ticket, kind) -> {flagged, resolved} from a prior data file body."""
    prev = {}
    for line in text.splitlines():
        m = FLAG_RE.search(line)
        if not m:
            continue
        k = (m["ticket"].strip(), m["kind"].strip())
        fm = FLAGGED_RE.search(line)
        rm = RESOLVED_RE.search(line)
        prev[k] = {"flagged": fm["d"] if fm else None,
                   "resolved": rm["d"] if rm else None}
    return prev


def bullet(fl, flagged, resolved):
    parts = [
        f"- {fl['ticket']} {fl['problem']}",
        f"[ticket:: {fl['ticket']}]",
        f"[sev:: {SEV[fl['sev']]}]",
        f"[kind:: {fl['kind']}]",
        f"[action:: {fl['action']}]",
    ]
    if fl.get("due"):
        parts.append(f"[due:: {fl['due']}]")
    parts.append(f"[flagged:: {flagged}]")
    if resolved:
        parts.append(f"[resolved:: {resolved}]")
    return " ".join(parts)


def reconcile(flags, prev, today, sprint_name, sprint_end, scanned):
    """Self-healing merge: keep flagged dates, resolve gone flags, add new ones."""
    today_s = today.isoformat()
    current = {(f["ticket"], f["kind"]): f for f in flags}
    lines = []

    # existing keys first (preserve order-ish: resolved or carried over)
    for key, meta in prev.items():
        if key in current:
            continue  # will be emitted below as still-open
        # was flagged before, not present now -> resolved (once)
        resolved = meta.get("resolved") or today_s
        lines.append(_carry_resolved(key, meta.get("flagged") or today_s, resolved))

    for key, fl in current.items():
        meta = prev.get(key)
        flagged = (meta or {}).get("flagged") or today_s
        # if it was previously resolved but reappeared, treat as freshly open
        lines.append(bullet(fl, flagged, resolved=None))

    body = [
        "---",
        "type: ticket-review-data",
        f'sprint: "{sprint_name}"',
        f"sprint_end: {sprint_end or ''}",
        f"last_run: {dt.datetime.now().isoformat(timespec='minutes')}",
        f"scanned: {scanned}",
        "---",
        "## Flags",
    ]
    body.extend(lines if lines else ["- (no flags — everything looks clean)"])
    return "\n".join(body) + "\n"


def _carry_resolved(key, flagged, resolved):
    ticket, kind = key
    return (f"- {ticket} resolved [ticket:: {ticket}] [sev:: {SEV['low']}] "
            f"[kind:: {kind}] [action:: done] [flagged:: {flagged}] [resolved:: {resolved}]")


def main():
    force_stdout = "--stdout" in sys.argv
    base, auth = _auth_header()
    today = dt.date.today()

    issues = fetch_issues(base, auth)
    sp = next((active_sprint(i) for i in issues if active_sprint(i)), None)
    sprint_name = sp.get("name") if sp else "(no active sprint)"
    sprint_end = (_date(sp.get("endDate")).isoformat() if sp and sp.get("endDate") else "")

    flags = evaluate(issues, today)

    path = os.environ.get("TICKET_REVIEW_DATA_FILE", "").strip()
    prev = {}
    if path and os.path.exists(path) and not force_stdout:
        try:
            with open(path) as fh:
                prev = parse_existing(fh.read())
        except OSError:
            pass

    content = reconcile(flags, prev, today, sprint_name, sprint_end, len(issues))

    wrote = False
    if path and not force_stdout:
        try:
            with open(path, "w") as fh:
                fh.write(content)
            wrote = True
        except OSError as e:
            print(f"warn: could not write {path}: {e}", file=sys.stderr)

    if not wrote:
        print(content)

    # short summary to stderr so cron mail / logs show the headline
    counts = {}
    for f in flags:
        counts[f["sev"]] = counts.get(f["sev"], 0) + 1
    summary = (f"[ticket-review] {len(issues)} scanned · "
               f"{counts.get('high',0)} high · {counts.get('med',0)} med · "
               f"{counts.get('low',0)} low · sprint={sprint_name}"
               + (f" · wrote {path}" if wrote else " · printed to stdout"))
    print(summary, file=sys.stderr)


if __name__ == "__main__":
    main()


