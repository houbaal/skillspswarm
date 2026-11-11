#!/usr/bin/env python3
"""Fetch GitLab CI pipeline details — including bridges and downstream child pipelines.

Crucial design point: GitLab parent-child pipelines are split across multiple API
endpoints. The /jobs endpoint of a parent pipeline does NOT include trigger jobs
(bridges) that launch child pipelines, and the failed test that turned the parent
red may live one or more levels down. This script walks the tree end-to-end so the
caller sees the truth, not just the parent slice.

Usage:
  get-pipeline-details.py                                # current pipeline (+ children), JSON
  get-pipeline-details.py --history 5                    # last 5 runs (each with children)
  get-pipeline-details.py --branch main                  # specific branch
  get-pipeline-details.py --pipeline-id 2457561246       # explicit pipeline by ID
  get-pipeline-details.py --format markdown              # human-readable
  get-pipeline-details.py --failed-only                  # only the failed jobs (anywhere in tree)
  get-pipeline-details.py --no-children                  # skip downstream resolution (faster)
  get-pipeline-details.py --max-depth 2                  # limit recursion (default 3)

Output: JSON (default) or Markdown to stdout.

Each pipeline node carries:
  - direct jobs (parent-level)
  - bridges (trigger jobs that launch downstream child pipelines)
  - child_pipelines: recursive list, one per bridge that actually triggered something
  - is_superseded: True if status=failed but nothing in this pipeline OR its children
                   actually ran and failed -- typically caused by a newer push
                   superseding this pipeline before its jobs started.
  - real_failure: True if at least one job (here or in a downstream child) genuinely
                  failed (started_at != null and status == failed).
"""

import argparse
import json
import subprocess
import sys


# --- glab wrappers --------------------------------------------------------

def _run(cmd):
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        raise RuntimeError(f"{' '.join(cmd)} failed: {r.stderr.strip()}")
    return r.stdout


def get_branch():
    return subprocess.check_output(
        ["git", "rev-parse", "--abbrev-ref", "HEAD"],
        text=True,
    ).strip()


def list_pipelines(branch, count):
    """Most recent N pipelines on a branch (parent pipelines only -- source=push)."""
    out = _run(
        ["glab", "ci", "list", "-r", branch, "--per-page", str(count), "-F", "json"]
    )
    return json.loads(out)


def get_pipeline(pipeline_id):
    """Pipeline metadata + direct jobs (does NOT include bridges)."""
    out = _run(["glab", "ci", "get", "-p", str(pipeline_id), "-d", "-F", "json"])
    return json.loads(out)


def get_bridges(pipeline_id):
    """Trigger/bridge jobs of a pipeline. Each carries an optional downstream_pipeline."""
    try:
        out = _run(
            ["glab", "api", f"projects/:id/pipelines/{pipeline_id}/bridges?per_page=100"]
        )
        return json.loads(out)
    except RuntimeError:
        # Project may not use parent-child pipelines, or API call may fail
        # for permission reasons -- treat as "no bridges" rather than crash.
        return []


# --- formatting -----------------------------------------------------------

def format_duration(seconds):
    if seconds is None:
        return "—"
    m, s = divmod(int(seconds), 60)
    return f"{m}m{s:02d}s" if m else f"{s}s"


_STATUS_ICONS = {
    "success": "OK",
    "failed": "FAIL",
    "running": "RUN",
    "pending": "WAIT",
    "canceled": "SKIP",
    "skipped": "SKIP",
    "manual": "MANUAL",
    "created": "CREATED",
}


def status_icon(status):
    return _STATUS_ICONS.get(status, status.upper())


# --- failure classification ----------------------------------------------

def classify_failure(node):
    """Returns (is_superseded, real_failure) for a pipeline node.

    Logic (in order):
    1. Status not 'failed'             -> (False, False)
    2. Any direct job started + failed -> (False, True)   real failure here
    3. Any bridge downstream failed    -> (False, True)   real failure in child
    4. No direct job ever started AND no bridge produced a downstream
       that genuinely failed           -> (True, False)   superseded
    5. Otherwise                       -> (False, True)   default to real
    """
    if node.get("status") != "failed":
        return False, False

    direct_jobs = node.get("jobs", [])
    started_failures = [
        j for j in direct_jobs
        if j.get("status") == "failed" and j.get("started_at")
    ]
    if started_failures:
        return False, True

    for child in node.get("child_pipelines", []):
        if child.get("real_failure"):
            return False, True

    # A bridge with status=failed is evidence of a real failure, even when we
    # couldn't fetch its downstream pipeline details (API error, permission
    # issue, empty response). Without this, an unresolvable downstream would
    # incorrectly be classified as 'superseded'.
    for bridge in node.get("bridges", []):
        if bridge.get("status") == "failed":
            return False, True

    any_direct_started = any(j.get("started_at") for j in direct_jobs)
    any_child_started = any(
        any(j.get("started_at") for j in c.get("jobs", []))
        for c in node.get("child_pipelines", [])
    )
    if not any_direct_started and not any_child_started:
        return True, False

    return False, True


# --- recursive walk -------------------------------------------------------

def build_node(pipeline_id, with_children, max_depth, depth=0):
    """Fetch a pipeline + bridges + (recursively) downstream child pipelines."""
    p = get_pipeline(pipeline_id)
    jobs = [
        {
            "id": j["id"],
            "name": j["name"],
            "stage": j.get("stage"),
            "status": j["status"],
            "duration": j.get("duration"),
            "started_at": j.get("started_at"),
            "finished_at": j.get("finished_at"),
            "failure_reason": j.get("failure_reason"),
            "web_url": j.get("web_url"),
        }
        for j in (p or {}).get("jobs", [])
    ]

    bridges_raw = get_bridges(pipeline_id) if with_children else []
    bridges = []
    child_pipelines = []
    for b in bridges_raw:
        dp = b.get("downstream_pipeline")
        bridges.append(
            {
                "id": b.get("id"),
                "name": b.get("name"),
                "stage": b.get("stage"),
                "status": b.get("status"),
                "downstream_id": (dp or {}).get("id"),
                "downstream_status": (dp or {}).get("status"),
            }
        )
        if dp and depth < max_depth:
            try:
                child = build_node(dp["id"], with_children, max_depth, depth + 1)
                child["bridge_name"] = b.get("name")
                child_pipelines.append(child)
            except RuntimeError as e:
                print(f"warning: could not fetch child pipeline {dp['id']}: {e}",
                      file=sys.stderr)

    node = {
        "id": p.get("id"),
        "iid": p.get("iid"),
        "status": p.get("status"),
        "source": p.get("source"),
        "ref": p.get("ref"),
        "sha": p.get("sha"),
        "created_at": p.get("created_at"),
        "started_at": p.get("started_at"),
        "finished_at": p.get("finished_at"),
        "duration": p.get("duration"),
        "web_url": p.get("web_url"),
        "jobs": jobs,
        "bridges": bridges,
        "child_pipelines": child_pipelines,
    }
    is_superseded, real_failure = classify_failure(node)
    node["is_superseded"] = is_superseded
    node["real_failure"] = real_failure
    return node


def walk_failed_jobs(node, path=None):
    """Yield (path, job) for every genuinely failed job in the tree.

    `path` is a human-readable trail like 'parent #1471 > child mobile #1473'.
    """
    if path is None:
        path = f"#{node.get('iid', '?')} ({node.get('id')})"
    for j in node.get("jobs", []):
        if j["status"] == "failed" and j.get("started_at"):
            yield path, j
    for child in node.get("child_pipelines", []):
        child_path = f"{path} > child {child.get('bridge_name','?')} #{child.get('iid','?')}"
        yield from walk_failed_jobs(child, child_path)


# --- markdown rendering ---------------------------------------------------

def _render_jobs_table(jobs, indent=""):
    if not jobs:
        return [f"{indent}_(no direct jobs)_"]
    lines = [
        f"{indent}| Job                          | Stage        | Status  | Duration |",
        f"{indent}|------------------------------|--------------|---------|----------|",
    ]
    for j in jobs:
        name = (j["name"][:30]).ljust(30)
        stage = ((j.get("stage") or "—")[:12]).ljust(12)
        st = status_icon(j["status"]).ljust(7)
        dur = format_duration(j.get("duration")).ljust(8)
        lines.append(f"{indent}| {name} | {stage} | {st} | {dur} |")
    return lines


def _render_bridges_table(bridges, indent=""):
    if not bridges:
        return []
    lines = [
        "",
        f"{indent}**Bridges (trigger jobs to child pipelines):**",
        "",
        f"{indent}| Bridge      | Stage      | Status  | Downstream pipeline    |",
        f"{indent}|-------------|------------|---------|------------------------|",
    ]
    for b in bridges:
        name = (b.get("name") or "—")[:11].ljust(11)
        stage = (b.get("stage") or "—")[:10].ljust(10)
        st = status_icon(b.get("status") or "—").ljust(7)
        if b.get("downstream_id"):
            ds = f"id={b['downstream_id']} ({b.get('downstream_status') or '?'})"
        else:
            ds = "—  (bridge skipped, e.g. rules.changes)"
        lines.append(f"{indent}| {name} | {stage} | {st} | {ds:<22} |")
    return lines


def render_node(node, depth=0):
    indent = "  " * depth
    iid = node.get("iid", "?")
    icon = status_icon(node.get("status") or "?")
    flags = []
    if node.get("is_superseded"):
        flags.append("SUPERSEDED")
    if node.get("real_failure"):
        flags.append("REAL FAILURE")
    flag_suffix = f" — {', '.join(flags)}" if flags else ""

    lines = [f"{indent}## Pipeline #{iid} — {icon}{flag_suffix}", ""]
    lines.append(f"{indent}- **Status**: {node.get('status')}")
    lines.append(f"{indent}- **Source**: {node.get('source') or '—'}")
    lines.append(f"{indent}- **SHA**: `{(node.get('sha') or '')[:8]}`")
    lines.append(f"{indent}- **Duration**: {format_duration(node.get('duration'))}")
    lines.append(f"{indent}- **Created**: {node.get('created_at', '?')}")
    if node.get("web_url"):
        lines.append(f"{indent}- **URL**: {node['web_url']}")
    if node.get("is_superseded"):
        lines.append(
            f"{indent}- _Marked failed but nothing ran here or in children — "
            "likely superseded by a newer push._"
        )
    lines.append("")

    lines.extend(_render_jobs_table(node.get("jobs", []), indent))
    lines.extend(_render_bridges_table(node.get("bridges", []), indent))

    for child in node.get("child_pipelines", []):
        lines.append("")
        lines.append(f"{indent}### Child pipeline via `{child.get('bridge_name','?')}` bridge")
        lines.append("")
        lines.extend(render_node(child, depth + 1).splitlines())

    return "\n".join(lines)


def render_failed_only(roots):
    lines = ["# Failed jobs (across parent and child pipelines)", ""]
    any_failure = False
    for root in roots:
        for path, job in walk_failed_jobs(root):
            any_failure = True
            lines.append(f"## `{job['name']}` (id={job['id']})")
            lines.append(f"- **Path**: {path}")
            lines.append(f"- **Stage**: {job.get('stage') or '—'}")
            lines.append(f"- **Failure reason**: {job.get('failure_reason') or 'unknown'}")
            lines.append(f"- **Duration**: {format_duration(job.get('duration'))}")
            if job.get("web_url"):
                lines.append(f"- **URL**: {job['web_url']}")
            lines.append(
                f"- **Logs**: `scripts/get-job-logs.sh {job['id']}` "
                "(or `--tail 200` for the end)"
            )
            lines.append("")
    if not any_failure:
        lines.append("_No genuinely failed jobs anywhere in the tree._")
        lines.append("")
        lines.append("If a parent pipeline shows status=failed but nothing here, it's likely")
        lines.append("`is_superseded` — a newer push canceled it before any job started.")
    return "\n".join(lines)


# --- entry point ----------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description="Fetch GitLab CI pipeline details (incl. children)")
    parser.add_argument("--branch", default=None,
                        help="Branch name (default: current branch)")
    parser.add_argument("--history", type=int, default=1,
                        help="Number of recent runs (default: 1)")
    parser.add_argument("--pipeline-id", type=int, default=None,
                        help="Inspect a specific pipeline by ID (overrides --branch/--history)")
    parser.add_argument("--format", dest="fmt", choices=["json", "markdown"], default="json",
                        help="Output format (default: json)")
    parser.add_argument("--failed-only", action="store_true",
                        help="Markdown view limited to genuinely failed jobs (any depth)")
    parser.add_argument("--no-children", action="store_true",
                        help="Skip downstream child pipelines (faster, but blind to triggers)")
    parser.add_argument("--max-depth", type=int, default=3,
                        help="Recursion depth for child pipelines (default: 3)")
    args = parser.parse_args()

    with_children = not args.no_children

    if args.pipeline_id is not None:
        try:
            roots = [build_node(args.pipeline_id, with_children, args.max_depth)]
        except RuntimeError as e:
            print(f"error: {e}", file=sys.stderr)
            sys.exit(1)
    else:
        branch = args.branch or get_branch()
        try:
            pipelines = list_pipelines(branch, args.history)
        except RuntimeError as e:
            print(f"error: {e}", file=sys.stderr)
            sys.exit(1)
        if not pipelines:
            if args.fmt == "markdown":
                print("No pipelines found.")
            else:
                json.dump([], sys.stdout)
            sys.exit(0)
        roots = []
        for p in pipelines:
            try:
                roots.append(build_node(p["id"], with_children, args.max_depth))
            except RuntimeError as e:
                print(f"warning: could not fetch pipeline {p['id']}: {e}", file=sys.stderr)

    if args.failed_only:
        print(render_failed_only(roots))
    elif args.fmt == "markdown":
        print("\n\n".join(render_node(r) for r in roots))
    else:
        json.dump(roots, sys.stdout, indent=2)


if __name__ == "__main__":
    main()
