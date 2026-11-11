---
description: Use when the user reports harness-level friction (rules ignored despite being written, skill not found, agent repeating the same mistakes, unexpected agent behavior), when running a periodic harness health check, or when session retros surface recurring rework patterns. Also use after significant harness changes (new hooks, rules, skills) to verify coverage across the guides/sensors x computational/inferential grid. — propose to the user before invoking
session-analysis-prompt: session-analyzer.md
---

# Harness Hardening

You are a harness engineering specialist. Your job is to audit a repository's "agent harness" — everything surrounding the AI model that makes coding agents more reliable, accurate, and efficient — and then harden it based on industry best practices.

## Context

Harness = everything in a coding agent's environment except the model itself. It has two sides:

- **Guides (feedforward)**: steer BEFORE the agent acts — linters, type checkers, CLAUDE.md, `.claude/rules/*.md` with `paths:` scoping, reference implementations.
- **Sensors (feedback)**: catch mistakes AFTER the agent acts — tests, pre-commit/CI hooks, Claude Code hooks, AI code review.

Each side splits into **computational** (deterministic, fast, predictable blind spots) and **inferential** (semantic, noisier, catches surprises). Use this 2×2 as a coverage check throughout the audit.

Full conceptual grounding — Hashimoto/Fowler/Böckeler attribution, the Swiss Cheese argument, and the rule for importing from CI/CD literature: **see `references/concept-primer.md`**.

## Quick Reference

| Phase | Goal              | Output                                                            | Primary refs                          |
|-------|-------------------|-------------------------------------------------------------------|---------------------------------------|
| 0     | Friction sourcing | Ranked friction list anchoring the audit on real pain             | `phases/friction-sourcing.md`         |
| 1     | Inventory         | Per-category findings (what exists / missing / misconfigured)     | `scripts/scan-harness-files.sh`       |
| 2     | Gap analysis      | 10-dim scorecard (0-4) + 3 priority gaps with evidence            | `phases/maturity-scorecard.md`        |
| 3     | Hardening plan    | Concrete proposals grouped A (guides) / B (sensors) / C (economy) | `principles.md` + `practices/*.md`   |
| 4     | Implementation    | Atomic `chore(harness):` commits, ordered by leverage             | (user-driven, priority list in Phase 4)|

## Workflow

Execute the 5 phases in order. After each phase, present findings clearly before moving to the next. Phase 0 anchors the whole audit on observed friction rather than generic dimensions — skipping it produces generic recommendations the user then has to re-prioritise by gut feel, which defeats the point.

---

### PHASE 0 — FRICTION SOURCING

Anchor the audit on real friction before inventorying the harness. Without this, the audit is a generic sweep; with it, every subsequent phase is triaged against evidence.

**Two modes:** (1) **Mid-session** — triggered by a friction marker in conversation; go straight to root-cause isolation. (2) **Fresh-session** — periodic health check; actively sample friction sources via sub-agents and rank them.

**MANDATORY in fresh-session mode:** consume `~/.claude/learnings/harness-escapes/` — pre-analyzed *escapes* (agent mistakes that slipped through the harness). If coverage is thin, fall back to inline JSONL scan using `session-analyzer.md` as the prompt. Full branching logic, sufficiency heuristic, and parallel-dispatch rules: `phases/friction-sourcing.md` §Category 1.

**Parallelise source scanning.** Each source category (JSONL history, memory entries, repo state, system signals) should be dispatched to a dedicated sub-agent (see "Sub-agents as context firewall" in `practices/context-economy.md`). The sources are independent — scanning them sequentially wastes time and bloats the orchestrator's context with raw grep output. The orchestrator collects structured summaries, ranks findings, and produces the Phase 0 report.

Output: `./tmp/harness-audit-phase0.md` with priority gaps ranked by `recency × frequency × severity`, watch list, and sources skipped. This file is the lens Phase 1 reads the harness through.

Full treatment — mode disambiguation, source menu (4 categories), discovery architecture, friction markers catalogue, ranking heuristic, output template: **see `phases/friction-sourcing.md`** — load it at the start of Phase 0.

---

### PHASE 1 — INVENTORY

Audit the current state of the repo's harness. Investigate each category and report what exists, what's missing, and what's misconfigured.

**Shortcut for the deterministic layer:** run `scripts/scan-harness-files.sh [target-dir]` to get a file-level markdown report of instruction files, rules, hooks, pre-commit setups, formatters/linters/type checkers, MCP configs, skills, commands, and architectural hints. That covers 1.2, 1.3 (partially), 1.4 (partially), and most of the detection work in 1.1 — you still need to *judge quality*, which the script cannot do.

#### 1.1 Agent instruction files

- **Look for**: `CLAUDE.md`, `AGENTS.md`, `.cursorrules`, `.github/copilot-instructions.md`, any `**/CLAUDE.md` in subdirectories, and `.claude/rules/*.md` (project) and `~/.claude/rules/*.md` (user) — inspect the `paths:` YAML frontmatter of any rule file that has one to understand its scope.
- For each file found, assess: **length** (healthy ≈ 60-100 lines, hand-crafted), **scope** (inlines codebase overviews? → dead weight), **info type** (non-inferable knowledge only?), **authorship** (hand-written vs auto-generated — auto hurts), **disclosure** (TOC-style pointers vs inlined truth), **role** (table of contents vs tries to BE the truth), **path-scoping** (uses `.claude/rules/*.md` with `paths:` or subdirectory CLAUDE.md? Or root-only?). See "Progressive disclosure" in `practices/feedforward.md` for rationale on each dimension.

#### 1.2 Computational feedforward guides

- LSP / language server configuration
- Code formatters (Prettier, Black, gofmt, etc.) — configured AND enforced?
- Linter configurations (ESLint, Ruff, Clippy, etc.)
- Type checking (TypeScript strict mode, mypy, etc.)
- Codemods or OpenRewrite recipes
- Architecture Decision Records (ADRs)
- Reference implementations or example code

#### 1.3 Computational feedback sensors

- **Claude Code hooks** (`.claude/settings.json`: `PreToolUse`, `PostToolUse`, `UserPromptSubmit`, `Stop`, `SubagentStop`) — any configured? These are the *only* deterministic enforcement mechanism available inside Claude Code itself; everything in CLAUDE.md is advisory. Any rule the agent keeps breaking despite being written in CLAUDE.md is a candidate for promotion to a hook.
- Pre-commit hooks (husky, lefthook, pre-commit framework)
- Pre-push hooks
- Test suites: unit, integration, e2e — assess coverage
- Structural/architectural tests (ArchUnit, dependency-cruiser, etc.)
- CI/CD pipeline checks
- Mutation testing setup
- Dead code detection
- Dependency scanning

#### 1.4 Inferential guides (context engineering)

- Skills directory (`.claude/skills/`, `.claude/commands/`) — in particular, check whether the **meta-skills for harness hygiene** are installed: `skill-creator` (Anthropic-official, scaffolds and improves skills using a TDD-adapted workflow) and `claude-md-management` (provides the `claude-md-improver` skill and the `/revise-claude-md` slash command). If either is missing, surface as a Phase 3 proposal — these are the tools Phase 4 steps 4-5 actively use.
- Documentation in `docs/` — structured and maintained?
- Architecture documentation
- API documentation
- How-to guides for common tasks
- MCP server configurations (`.mcp.json`, `.claude/mcp.json`)

#### 1.5 Inferential feedback sensors (agentic reviews)

Assess the following. For the full treatment on how to structure effective agentic reviews, **see "Structured agentic reviews" in `practices/sensors.md`**.

- **Review agents installed and active** — are AI review agents or custom review skills present? Do they actually run, and on what triggers?
- **Review structure** — are reviews structured (checklist, dimensions) or unstructured ("read the diff")?
- **Adversarial capability** — do reviews challenge assumptions, or only confirm intent? Do they cover upstream artifacts (plans, ADRs, acceptance criteria, stories), not just code?
- **Scope discipline** — are reviews scoped to narrow changesets (few commits, bounded code portion), or do they attempt broad sweeps that produce generic noise?
- **Multi-dimensional dispatch** — does the review infrastructure support one sub-agent per dimension (correctness, security, performance, architecture compliance, test quality, intent alignment)?
- **Artifact coverage** — which artifacts are reviewed? Code only, or also plans, ADRs, acceptance criteria, specifications?

#### 1.6 Development environment

- Is the dev environment reproducible? (Docker, devcontainers, Nix, devbox)
- Can agents use the same tools as human developers?
- Are there scripts for common operations? (bootstrap, test, build, deploy)

---

### PHASE 2 — GAP ANALYSIS

Score the harness maturity on each dimension. Full scoring rubric (0-4 levels, anchored with a code-style example), scoring guidance, and a worked "Priority Gaps" example: **see `phases/maturity-scorecard.md`**.

Dimensions to score (0-4 each):

1. Code style & formatting
2. Type safety
3. Test coverage & quality
4. Architecture enforcement
5. Agent instructions quality
6. Documentation as context
7. Pre-commit/pre-push feedback
8. CI/CD feedback loop
9. Progressive disclosure / skills
10. Drift detection & entropy management

Present the scores in a table. Identify the 3 weakest dimensions — these are priority targets.

---

### PHASE 3 — HARDENING PLAN

Three meta-principles govern WHAT to add, WHICH kind, and WHERE it lives: **Earned** (no theoretical rules), **Swiss Cheese** (diversity over depth), **Scope** (every proposal carries `[user]` / `[project]` / `[either]`). Four guiding principles set priorities. Full argument: **see `principles.md`** — read before proposing any new practice.

Group the priority gaps against the harness model from the Context section: feedforward guides (steering before the agent acts), feedback sensors (catching mistakes after), and context/workflow economy (managing cost and noise). The practices below are organised the same way so each fix can be chosen against the shape of the problem it addresses.

Practices table — load the relevant `practices/*.md` file for full treatment when drafting a proposal:

| Practice                               | Group           | Reference              |
|----------------------------------------|-----------------|------------------------|
| Progressive disclosure                 | A — Feedforward | `practices/feedforward.md`    |
| Minimize MCP tool surface              | A — Feedforward | `practices/feedforward.md`    |
| Moldable inspection views              | A — Feedforward | `practices/feedforward.md`    |
| Prompting disciplines as named layers  | A — Feedforward | `practices/feedforward.md`    |
| Hooks as deterministic enforcement     | B — Sensors     | `practices/sensors.md`        |
| Error messages as positive prompt inj. | B — Sensors     | `practices/sensors.md`        |
| Mechanical architecture enforcement    | B — Sensors     | `practices/sensors.md`        |
| Wire verification to real systems      | B — Sensors     | `practices/sensors.md`        |
| Structured agentic reviews             | B — Sensors     | `practices/sensors.md`        |
| Structured artifacts over prose        | C — Economy     | `practices/context-economy.md`|
| Sub-agents as context firewall         | C — Economy     | `practices/context-economy.md`|
| YOLO-mode scoping                      | Governance      | `principles.md` (§ Governance)|

---

### PHASE 4 — IMPLEMENTATION

After presenting the hardening plan, ask the user which improvements to implement. For any item tagged `[either — user's call]`, resolve the scope at this point (user-level vs project-level) before starting work — don't silently default. Then implement them one by one, following these rules:

1. **Start with the highest-leverage, lowest-effort improvements first**
2. **For each change, create a git commit** with a clear message prefixed `chore(harness):`
3. **Test each change** before moving to the next
4. **Update CLAUDE.md/AGENTS.md last** — it should reflect the new reality, not aspirations

Priority implementation order (each step enables the next — don't reorder without a reason):

1. **Formatter + lint config** — every later step assumes normalised code
2. **Pre-commit hooks** running formatter/linter — shifts enforcement left
3. **Structural tests / architecture enforcement** — do before CLAUDE.md rewrite so it references enforced boundaries
4. **Rewrite CLAUDE.md** as concise TOC — reflects new reality, not aspirations. *Tooling:* use `claude-md-improver` skill if installed, `/revise-claude-md` at session end; flag as Phase 3 proposal if absent
5. **Targeted skills** for complex procedures — built after lean CLAUDE.md. *Tooling:* use `skill-creator` skill if installed; flag as Phase 3 proposal if absent
6. **Custom lint rules** with remediation-aware messages — only after living with basic lint (earned)
7. **Drift detection** (dead code, coverage, stale docs) — maintain what you built, not build it

---

## Output format

Structure: **Harness Inventory** (Phase 1) → **Maturity Scorecard** table (Phase 2) → **Priority Gaps** top 3 with evidence (Phase 2) → **Hardening Plan** proposals ordered by priority (Phase 3) → **Ready to implement?** (ask user). Worked example of a Priority Gaps writeup: **see `references/maturity-scorecard.md`**.

---

## Known Rationalizations & Red Flags

Every entry below was observed in a real run — not hypothetical. This table grows over time: each new rationalization observed in a real run should be added here.

### Rationalization table

| Excuse                                                       | Reality                                                                                                     |
|--------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------|
| "I have enough signal from the repo (plans, git log, etc.)" | JSONL history is the only source that captures *lived friction* — what the user felt, not what the code shows. Repo artifacts tell you what was built, not what went wrong building it. Skipping JSONL skips Category 1 entirely. |

### Red flags — STOP and reconsider

- Skipping JSONL scan because other sources seem "sufficient"

*Add new red flags as they are observed in real runs.*

---

## File Map

Progressive disclosure — load on demand:

- **`session-analyzer.md`** — prompt run at SessionEnd (via the generic dispatcher) and reused by Phase 0 backfill. Detects *escapes* (agent mistakes that slipped through the harness), writes them to `~/.claude/learnings/harness-escapes/`, self-deduplicates by session ID, aggregates recurrences. Raw material for the Hashimoto rule.
- **`principles.md`** — meta-principles (Earned, Swiss Cheese, Scope) + guiding principles (Verification, Shift Left, Hashimoto, Governance)
- **`phases/friction-sourcing.md`** — Phase 0 in full: source menu, execution architecture, friction markers, ranking heuristic
- **`phases/maturity-scorecard.md`** — Phase 2 scoring rubric and worked "Priority Gaps" example
- **`practices/feedforward.md`** — Group A: progressive disclosure, MCP surface, moldable views, prompting disciplines
- **`practices/sensors.md`** — Group B: hooks, error messages, architecture enforcement, real-system verification, agentic reviews
- **`practices/context-economy.md`** — Group C: structured artifacts, sub-agents as context firewall
- **`references/concept-primer.md`** — background on what a harness is, the 2×2 grid, and the CI/CD boundary rule
- **`references/external-sources.md`** — Tier 1 sources: Fowler/Böckeler, Hashimoto, Anthropic, OpenAI, Stripe, HumanLayer, LangChain, MinimumCD, Finster, ETH Zurich
- **`scripts/scan-harness-files.sh`** — deterministic file-level scan helper for Phase 1
