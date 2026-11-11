---
description: >
  Use when a git push was just performed, when the CI pipeline is red or failing,
  when the user asks about pipeline status, or when diagnosing CI issues like
  flaky tests, slow jobs, or silent errors. Monitors GitLab CI pipelines via glab CLI.
  Propose to the user before invoking.
---

# Pipeline Steward

## Overview

Monitors and analyzes GitLab CI pipelines. Two parallel streams:
deterministic scripts for monitoring, LLM sub-agent for intelligent analysis.

## Prerequisites

- `glab` CLI authenticated and available in PATH
- Git repo with GitLab remote

## Read `.gitlab-ci.yml` BEFORE making architectural claims

Before saying anything about how the CI is structured (what stages exist, what
jobs run when, whether the CI is "minimal" or "thorough"), open the actual
`.gitlab-ci.yml` and any `include:` / `trigger: include:` referenced from it.
The output of `glab ci status` lists only **direct jobs of the parent pipeline**
and OMITS:

- Bridge jobs (trigger jobs that launch child pipelines)
- Jobs of child pipelines themselves
- Conditional jobs gated by `rules.changes` that did not match this commit

Drawing conclusions from `glab ci status` alone is the most common mistake
this skill makes — it routinely produces **wrong claims about CI architecture**.
Open the YAML, follow the includes, and only then describe what the CI does.

## Parent-child pipelines (CRITICAL)

GitLab supports parent-child pipelines via `trigger: include: <file>`. This
splits a single conceptual pipeline across multiple `pipeline_id`s — and the
GitLab API splits them too. Concretely:

| Concept                           | Endpoint / command                                    |
|-----------------------------------|-------------------------------------------------------|
| Parent's direct jobs              | `glab api projects/:id/pipelines/<id>/jobs`           |
| **Bridge / trigger jobs**         | `glab api projects/:id/pipelines/<id>/bridges`        |
| Downstream child pipeline         | `bridge.downstream_pipeline.id` (recurse)             |
| Whole tree (parent + children)    | `scripts/get-pipeline-details.py` (handles recursion) |

A **failed** parent pipeline often hides the real failure inside a downstream
child. A **canceled** or even `failed`-marked parent with no started jobs is
usually a "superseded by newer push" situation, NOT a real regression. Use
`scripts/get-pipeline-details.py --failed-only` to drill straight to the
truly failed jobs across the whole tree.

## Quick check vs. monitoring

| Need                                | Command                                                       | When to use                    |
|-------------------------------------|---------------------------------------------------------------|--------------------------------|
| One-shot status (parent only)       | `glab ci status`                                              | "Is it green?" — 1 second      |
| Detailed pipeline + children        | `scripts/get-pipeline-details.py --format markdown`           | Need full tree + job-level     |
| Just the failed jobs (any depth)    | `scripts/get-pipeline-details.py --failed-only`               | Pipeline RED, want the cause   |
| Continuous monitoring               | `scripts/monitor-loop.sh` (background)                        | Waiting for a running pipeline |
| Logs of a specific job              | `scripts/get-job-logs.sh <job-id> [--tail 200]`               | Diagnose a known failed job    |

**Default to `glab ci status` for a binary green/red answer.** Move to
`get-pipeline-details.py` as soon as you need to understand WHY, especially
because `glab ci status` can mislead you about CI architecture (see above).

## Workflow

### Quick check (most common)

```bash
glab ci status
```

If green or you only need the parent status — done.

### Detailed inspection

```bash
# Full tree (parent + bridges + child pipelines), markdown
scripts/get-pipeline-details.py --format markdown

# Last 5 runs (each with their child trees) for trend analysis
scripts/get-pipeline-details.py --format markdown --history 5

# Drill straight to genuinely failed jobs (any depth)
scripts/get-pipeline-details.py --failed-only

# Inspect a specific pipeline by ID (useful for old / different-branch pipelines)
scripts/get-pipeline-details.py --pipeline-id 2457561246 --format markdown

# Raw JSON (for sub-agent processing)
scripts/get-pipeline-details.py --history 5

# Faster but blind to children — use only when you know the project has no
# parent-child pipelines, or when you only need parent-level metadata
scripts/get-pipeline-details.py --no-children
```

### Full monitoring (running pipeline)

1. Launch monitor in background — **pipeline ID is optional** (auto-detects
   from the latest pipeline of the current branch):
   ```bash
   scripts/monitor-loop.sh                    # auto-detect
   scripts/monitor-loop.sh <pipeline-id>      # explicit ID
   scripts/monitor-loop.sh <pipeline-id> 15   # custom interval (15s)
   ```
   Always use `run_in_background=true` when launching from Claude Code.

2. The script:
   - Echoes status to stdout on every poll (visible in background task output)
   - Writes atomic status to `./tmp/pipeline-status.txt`
   - Exits on terminal state (success, failed, canceled, skipped)
   - Exits on timeout (30 min default, override with `MONITOR_TIMEOUT=N` in seconds)
   - Handles manual jobs: if all non-manual jobs **and bridges** are done,
     considers the pipeline done (so a still-pending manual deploy doesn't
     block forever)
   - Tracks the SAME pipeline ID for the whole loop (won't auto-jump to a
     newer push mid-monitoring)

3. Optionally dispatch the analysis sub-agent in parallel
   (see [analysis-prompt.md](analysis-prompt.md)).

4. On terminal state:
   - GREEN: brief final report, mention any secondary findings
   - RED: run `scripts/get-pipeline-details.py --failed-only` first to find the
     real culprit, then `scripts/get-job-logs.sh <job-id> --tail 200` for the
     log; surface diagnosis in the conversation as a CRITICAL alert

## Scripts

| Script                            | Role                                                                   | Deterministic |
|-----------------------------------|------------------------------------------------------------------------|---------------|
| `scripts/monitor-loop.sh`         | Poll status, echo to stdout, write `pipeline-status.txt`               | yes           |
| `scripts/get-pipeline-details.py` | Pipeline + bridges + child pipelines (recursive). JSON, markdown, or `--failed-only` view | yes |
| `scripts/get-job-logs.sh`         | Fetch raw logs for a job by ID (works without TTY)                     | yes           |

## Output files

| File                               | Content                           | Consumer                    |
|------------------------------------|-----------------------------------|-----------------------------|
| `./tmp/pipeline-status.txt`        | Atomic status (GREEN/RED/TIMEOUT) | hook `pipeline-red-gate.sh` |
| `./tmp/pipeline-steward-report.md` | Rich report: history, timings     | Human + LLM                 |

## Analysis sub-agent

Dispatched in parallel with monitoring. Looks for:
- Abnormally slow jobs (compared against last 5 runs history)
- Flaky tests (intermittent failures on same jobs)
- Superfluous warnings in outputs
- Silent errors (exit 0 but non-empty stderr, ignored error messages)
- Configuration errors (deprecations, misconfigurations)
- **Failures hidden in child pipelines** (parent green-looking but child failed)

Prompt details: see [analysis-prompt.md](analysis-prompt.md)

## Tools that DON'T work in non-interactive mode

`glab` has commands that require a TTY and will fail with the message:
> Ci view requires an interactive terminal (TTY).

| Don't use                  | Use instead                                                 |
|----------------------------|-------------------------------------------------------------|
| `glab ci view`             | `glab ci get -p <id> -F json`, or `get-pipeline-details.py` |
| `glab ci status` (in loops)| `glab ci status` once is fine; for loops, parse JSON         |
| `glab issue view --web`    | `glab api projects/:id/issues/<iid>` if you need a snapshot  |

`glab ci trace <job-id>` and `glab api ...` both work without TTY.

## Common mistakes

- **Don't conclude on CI architecture from `glab ci status` alone** — it omits
  bridges and child pipelines. Read `.gitlab-ci.yml` first.
- **Don't trust a `failed` parent at face value** — a parent marked failed with
  no jobs that ever started (`started_at == null`) was likely superseded by a
  newer push. Use `--failed-only` to confirm a real failure.
- **Don't miss a downstream child failure** — a parent's `/jobs` endpoint will
  not show the failed child job. Always look at `/bridges` too, or just use
  `get-pipeline-details.py` which walks the tree for you.
- **Don't run `monitor-loop.sh` in foreground** — always `run_in_background=true`.
- **Don't overwrite `pipeline-steward-report.md` on each poll** — append/update sections.
- **Don't alert on every minor finding** — only criticals (RED, confirmed flaky).
- **Don't launch the monitoring loop for a simple "is it green?" check** — use
  `glab ci status`.

## Continuous improvement

Every problem encountered while using this skill is fuel for the next iteration.
After each session, note in `./tmp/pipeline-steward-report.md` (section
"Improvement backlog"):
- Scripts that errored or produced unexpected output
- Sub-agent behaviors that were erratic, wasteful, or ineffective
- Missing detection patterns (a real problem the analysis missed)
- False positives (findings that wasted human attention)
- Workflow friction (steps that felt manual but should be automated)

These observations feed directly into the next revision of this skill, its
scripts, and the analysis prompt. The steward improves by stewarding itself.
