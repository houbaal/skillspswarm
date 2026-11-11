# Phase 0 — Friction Sourcing

Full treatment of Phase 0. For summary and workflow placement, see `../SKILL.md` Phase 0.

## Two modes: mid-session vs fresh-session

**Mid-session (reactive).** Triggered by a friction marker in conversation. Friction is already named — skip the menu, isolate root cause at the harness level, feed into Phase 1.

**Fresh-session (proactive).** Periodic health check, no immediate friction. Sample friction sources via sub-agents (see "Sub-agents as context firewall" in `../practices/context-economy.md`), synthesise a ranked list before Phase 1.

**Disambiguation.** If mode is unclear, ask once: *"Context: (A) friction we just hit, (B) cold audit, (C) specific friction I'll name manually?"* Trigger rules should pass a hint to skip this in case A.

## Fresh-session: source menu

Present the menu as **categorised checkbox questions** via `AskUserQuestion`, because the tool is limited to ~4 options per question. Group sources by the nature of the signal, and **only show sources whose prerequisites are present** — don't pollute the menu with sources the repo doesn't support.

### Category 1 — User activity traces

What the user actually experienced. The highest-signal category because it captures **lived friction**, not inferred friction.

- **Pre-analyzed escapes + JSONL fallback** *(default on, MANDATORY)* — the primary source is `~/.claude/learnings/harness-escapes/*.md`: structured escapes produced by `../session-analyzer.md`, each carrying signal type, `evidence_sessions`, and a `prevention:` triplet. Two branches:
  - **If coverage is sufficient** — escapes reference most session IDs from the last 30 days — base Category 1 on those files directly. No JSONL scan needed.
  - **If coverage is thin or absent** — skill freshly installed, SessionEnd analyzer disabled, or too few analyzed sessions — scan `~/.claude/projects/*/*.jsonl` (last 30 days) inline using `../session-analyzer.md` as the detection prompt. The analyzer writes escape files; do not skip writing just because this is an ad-hoc scan. For a larger retroactive sweep (90+ days, cross-project, full history), see `${CLAUDE_PLUGIN_ROOT}/skills/session-analysis/retroactive-backfill.md` — it orchestrates this analyzer in parallel waves with budget monitoring; this Phase 0 fallback stays lean for in-audit use.
  - **Parallelise the fallback.** Uncovered sessions are independent — do NOT scan them sequentially. Dispatch one sub-agent per batch (or per session if the count is small) via the Task tool, each running the analyzer prompt against its assigned transcript(s) in the background. The orchestrator waits for completion, then re-reads `~/.claude/learnings/harness-escapes/` to get the deduplicated/aggregated view. Sequential scanning bloats the orchestrator's context with raw JSONL and stalls Phase 1.
  - Sufficiency heuristic: distinct session IDs in `evidence_sessions:` ≥ 50% of JSONL files from the last 30 days.
  - Ask the user whether to restrict to the current project only (default) or cross-project. Time limit: 30 days.
- **`.claude/memory/` auto-memory feedback entries** *(default on if present)* — the `feedback_*.md` files already contain friction the user explicitly recorded. Free signal, zero parsing needed.
- **Plans history** *(default on if detected)* — scan the configured plans directory for:
  - Completion notes in done plans (lessons learned, post-mortem notes)
  - Stalled plans in todo (plans untouched for N days signal blockers at the harness level)
  - *Discovery*: read `plansDirectory` from `~/.claude/settings.json` and `.claude/settings.json` (project); fall back to common conventions like `ai/plans/`, `docs/plans/`, `.plans/`.
- **Kaizen PDCA items** *(opt-in if detected)* — if a `kaizen/` directory exists at the repo root, the user is running a formal PDCA loop and the items there are pre-formalised friction. Treat as first-class source. *Discovery*: check for `kaizen/` by convention; no settings key is standardised.

### Category 2 — Repo state (static clues)

What the repo itself reveals about accumulated friction.

- **Static harness-files scan** *(default on)* — run `scripts/scan-harness-files.sh` (already in the skill). Surfaces inventory but also stale files (old mtimes on instruction files that the repo has since outgrown).
- **Git log friction markers** *(default on)* — grep recent commit messages for: `fix`, `revert`, `oops`, `wip`, `hotfix`, `rollback`, `rework`, `chore(rules)`, `chore(claude)`. High density on a short window = local pain.
- **Churn on `CLAUDE.md` and `.claude/rules/`** *(opt-in)* — `git log --oneline -- CLAUDE.md .claude/rules/` over the last 90 days. Files that keep moving indicate rules that haven't stabilised, which itself is friction.
- **Orphan slash commands and skills** *(opt-in)* — list entries in `.claude/commands/` and `.claude/skills/`, then grep JSONL invocation traces for each. Zero-invocation entries after N days are dead weight to remove (meta-principle: every rule must be earned).

### Category 3 — System signals (runtime feedback)

What the running system observed. Most valuable when present, often absent.

- **CI failure history** *(opt-in if detected)* — recent failing builds clustered on the same checks signal a sensor that doesn't steer effectively (error messages aren't carrying remediation). *Discovery*: `.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile`, etc.
- **Hook logs** *(opt-in if detected)* — Claude Code hooks (`PreToolUse`, `PostToolUse`) that block or warn repeatedly on the same pattern are perfect Hashimoto candidates: either the rule is wrong, the communication is wrong, or the pattern should be encoded more deeply.
- **Linter/type-checker error history** *(opt-in if detected)* — if the project runs a linter/type-checker in CI with persisted output, the same error fingerprint recurring over weeks is friction.

### Category 4 — Extension

- **Other source** — free-text slot for anything the user knows to be relevant that the skill couldn't detect. Shown last, always available.

## Execution architecture

**Parallelise by category.** Each source category (1 through 4) is independent. Dispatch one sub-agent per category (see "Sub-agents as context firewall" in `../practices/context-economy.md`). The orchestrator collects structured summaries, ranks findings, and produces the Phase 0 report. Do NOT scan sequentially — it wastes time and bloats the orchestrator's context with raw output.

**JSONL scanning uses the friction markers catalogue as a sentiment analysis grid.** The sub-agent scanning JSONL must use the friction markers table (see below) as its detection lens — it is not reading for keywords, it is classifying conversation segments by signal type (surprise, disapproval, repetition, disorientation, disappointment). Each match should be tagged with the signal type and a short excerpt. This is what made the difference between a generic scan and an actionable one in prior runs.

**Each sub-agent returns a structured summary** — not raw grep output. Format per finding: friction description (1 line), signal type, recency/frequency/severity ratings, evidence excerpt. The orchestrator ranks and deduplicates across categories.

## Source discovery architecture

Three layers, in order: (1) **conventions** — community directory names (`kaizen/`, `docs/adr/`, `.github/workflows/`, `.claude/memory/`); present → available, absent → skipped. (2) **settings.json** — read `plansDirectory` from `~/.claude/settings.json` and `.claude/settings.json`. (3) **runtime opt-in** — Category 4 free-text slot. The skill works out-of-the-box with defaults only; richer repos get richer audits; no repo breaks the skill.

## Friction markers — generic catalogue

The same catalogue drives (a) mid-session detection in the trigger rule, (b) JSONL scanning in Category 1, and (c) git-log scanning in Category 2. Markers are language-agnostic in intent — the examples below are English but the agent should generalise to any language in the conversation history.

| Pattern examples                                              | Signal                                                 | What it means for the harness                                                       |
|---------------------------------------------------------------|--------------------------------------------------------|-------------------------------------------------------------------------------------|
| *"wait, what?", "I thought you were...", "but I assumed..."*  | **Surprise** — mental model diverged from reality      | Likely missing documentation, stale instructions, or hidden state                   |
| *"no, not like that", "stop doing X", "don't do Y"*           | **Disapproval** — explicit correction of action        | Rule missing or violated; candidate for Hashimoto encoding                          |
| *"again?", "you already did this", "same as last time"*       | **Repetition** — recurring mistake                     | Pure Hashimoto signal: encode so it never happens again                             |
| *"how did we get here?", "where am I?", "I lost track"*       | **Disorientation** — blind spot / lost mental map      | Needs moldable view; current context insufficient for navigation                    |
| *"I expected X but got Y", "I thought this would..."*         | **Disappointment** — intent-outcome gap                | Specification/intent engineering layer is missing or too shallow                    |

These categories are intentionally coarse. Fine-grained marker lists rot as user language evolves; category *intent* is stable.

## Ranking findings: recency × frequency × severity

Once sources have been scanned, findings must be ranked. Without ranking, Phase 0 dumps 30 items and the user falls back to gut-feel — which is exactly what Phase 0 was supposed to replace.

**Three dimensions**, each rated qualitatively as high/medium/low:

- **Recency** — when did this friction last occur? Last 7 days = high. Last 30 days = medium. Older = low. Old friction may already be fixed.
- **Frequency** — how often does this friction recur? More than 3 times in the window = high. 2-3 times = medium. Once = low. One-shots rarely justify a harness change (meta-principle: every rule must be earned).
- **Severity** — how much did this friction cost? Blocked a merge / broke main / wasted >30 min = high. Noticeable rework = medium. Minor irritation = low.

**Aggregation rule**: a finding graduates to "priority gap" if it scores high on at least two of the three dimensions, OR scores high on severity alone. Everything else goes into a secondary "watch list" mentioned briefly in the report but not used to drive Phase 1.

Qualitative rather than numeric because false precision invites nitpicking and the inputs are estimates anyway. The skill can tighten the heuristic in a later iteration if the user wants.

## Phase 0 output

A single markdown file at `./tmp/harness-audit-phase0.md` (local to the project, per the `./tmp/` convention). Structure:

```markdown
# Harness Audit — Phase 0: Friction Sourcing

**Mode:** [mid-session | fresh-session]
**Date:** YYYY-MM-DD
**Sources scanned:** [list of categories and sources consulted]

## Priority gaps (top 3-5)
For each:
- **Friction:** one-line description
- **Signal type:** [surprise | disapproval | repetition | disorientation | disappointment]
- **Recency / Frequency / Severity:** H/M/L each
- **Evidence:** 1-3 short excerpts (commit SHA, JSONL line, memory file name, etc.)
- **Hypothesis for harness root cause:** which dimension in Phase 2's scorecard this likely maps to

## Watch list
Lower-priority findings, listed one-line each. Not actioned in this audit but worth revisiting next round.

## Sources skipped and why
One-line per source that was in the menu but not scanned (e.g., "CI logs: no .github/workflows detected").
```

The file is committed nowhere — `./tmp/` is gitignored per convention. It's a working artifact consumed by Phase 1 and kept around for the user to re-read across agent restarts until the audit is complete.

## Handoff to Phase 1

Phase 1 runs with the ranked friction list as a lens — focusing on categories that explain priority gaps (e.g., "repetition" → 1.3 sensors + 1.4 encoding; "disorientation" → 1.1 instructions + 1.4 docs/views).
