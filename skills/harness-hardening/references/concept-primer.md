# Harness Concept Primer

Background material for the harness-hardening skill. Load when you need the full conceptual grounding behind the audit workflow — attribution, framing, and the boundary rule for importing CI/CD practices.

## What is a harness?

Harness = everything in a coding agent's environment except the model itself.

> Agent = Model + Harness

The term was coined by Mitchell Hashimoto. The conceptual framework used throughout this skill follows Martin Fowler & Birgitta Böckeler's articulation of the discipline (see `external-sources.md`).

## The two sides of a harness

A well-built harness has two sides:

- **Guides (feedforward)**: anticipate agent mistakes and steer BEFORE the agent acts. Examples: linters configured strictly, type checkers on, CLAUDE.md rules, `.claude/rules/*.md` with `paths:` scoping, reference implementations, MCP tool surface.
- **Sensors (feedback)**: observe AFTER the agent acts and enable self-correction. Examples: tests, pre-commit hooks, CI checks, Claude Code hooks, AI code review, architectural fitness functions.

## The computational / inferential split

Both guides and sensors can be:

- **Computational** (deterministic, fast, cheap): linters, type checkers, tests, structural analysis, pre-commit hooks. Predictable blind spots, low false positives, check only what they are told to check.
- **Inferential** (semantic, slower, non-deterministic): AI code review, LLM-as-judge, review agents. High coverage of surprises, higher noise and false positives.

Together they cover each other's holes; apart, neither is sufficient. This is the Swiss Cheese argument — see `meta-principles.md`.

## The 2×2 grid

|                | Feedforward (before action)        | Feedback (after action)               |
|----------------|------------------------------------|---------------------------------------|
| Computational  | linters, formatters, type checkers | tests, hooks, CI gates, arch fitness  |
| Inferential    | CLAUDE.md rules, skills, MCP       | AI code review, review agents         |

A harness biased heavily toward any single quadrant has aligned holes by construction. Use this grid as a coverage check in Phase 1 and as a targeting tool in Phase 3.

## The CI/CD boundary rule

Many CI/CD best practices port to harness engineering with a direct mapping — **but the harness stops where the agent's reach stops.**

The same gates a human developer wants blocking on pre-commit or CI are the same gates an AI coding agent needs in-session: formatters, linters, type checks, unit tests, contract tests, architectural fitness functions. These port 1:1 and belong in both places.

What *doesn't* port into the harness are the stages past the agent's control loop — production monitoring, canary strategy, SLO dashboards, post-deploy integration are pipeline and ops engineering concerns, run by different tooling for a different audience.

**Rule of thumb when importing from CI/CD literature:** stop at the boundary of what the agent can trigger, observe, and react to in its own session.
