# Maturity Scorecard & Priority Gaps

Phase 2 of the workflow: score the harness on 10 dimensions, 0-4 each. Use this file as the full scoring rubric, and the worked "Priority Gaps" writeup at the end as a reference for the level of evidence Phase 2 output should reach.

## Scoring rubric

| Level               | Description                                              | Example (code style dimension)                                                                      |
|---------------------|----------------------------------------------------------|-----------------------------------------------------------------------------------------------------|
| 0 — Absent          | Nothing in place                                         | No formatter config, no lint config                                                                 |
| 1 — Ad hoc          | Some elements exist but not systematic                   | `.prettierrc` exists but half the repo is unformatted; no one runs it consistently                  |
| 2 — Defined         | Documented and consistent, but not mechanically enforced | Formatter runs via `npm run format`, documented in README, but no hook blocks unformatted commits   |
| 3 — Enforced        | Automated and blocking (CI gate, pre-commit hook)        | Pre-commit hook auto-runs formatter; CI fails on unformatted PRs                                    |
| 4 — Self-correcting | Feedback loop enables agent self-repair                  | Error output tells the agent exactly how to fix; remediation command documented in CLAUDE.md        |

A dimension at level 3 is "safe" — mistakes can't escape. Level 4 is "compounding" — the agent gets better at avoiding the mistake over time because the feedback loop teaches it.

The example column uses code style & formatting to anchor each level concretely — apply the same progression logic to the other dimensions.

## Dimensions (10)

1. **Code style & formatting** (0-4)
2. **Type safety** (0-4)
3. **Test coverage & quality** (0-4)
4. **Architecture enforcement** (0-4)
5. **Agent instructions quality** (0-4)
6. **Documentation as context** (0-4)
7. **Pre-commit/pre-push feedback** (0-4)
8. **CI/CD feedback loop** (0-4)
9. **Progressive disclosure / skills** (0-4)
10. **Drift detection & entropy management** (0-4)

Present the scores in a table. Identify the 3 weakest dimensions — these are priority targets for Phase 3.

## What a good "Priority Gaps" section looks like

The goal of this section in the audit output is not to restate the scores — it's to give the reader enough evidence that they immediately understand the failure mode AND the cost of not fixing it. Each gap should name a concrete observation from the repo, not a generic complaint.

> ## Priority Gaps
>
> 1. **Pre-commit/pre-push feedback — score 1**
>    Prettier is installed and `.prettierrc` exists, but it only runs manually via `npm run format`. Running it now reformats 47 files across `src/`. No pre-commit hook blocks unformatted commits. Consequence: every PR produces style noise that CI flags, causing round trips between the agent and the user before the actual review can start. Estimated waste: several minutes per PR, compounded by the agent re-reading diffs to understand what it actually changed versus what the formatter changed.
>
> 2. **Architecture enforcement — score 0**
>    `docs/architecture.md` describes a layered architecture (types → repo → service → ui). `src/api/handlers.ts:42` already imports from `src/ui/components/UserCard.tsx`, violating the documented direction. No lint rule, no dependency-cruiser config, no structural test exists. Consequence: the documented architecture is purely aspirational, and every agent reading it will receive wrong context about what the code actually does.
>
> 3. **Agent instructions quality — score 1**
>    `CLAUDE.md` is 340 lines. It contains a full directory tree (lines 45-120), a list of every npm dependency with a one-line description (lines 150-210), and a glossary of internal terms that could be derived by reading two source files (lines 230-290). At this length most of the content sits in the attention-degraded middle of the context and the token cost is paid on every invocation. Most of the content is also inferable from the repo itself.

The three gaps above each name a specific file, a specific line number, a specific line count — concrete artifacts the user can verify in 30 seconds. Generic complaints ("docs are out of date", "tests could be better") fail the bar: they don't give the user enough evidence to act, and they don't give the agent enough context to propose a concrete fix.
