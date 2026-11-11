# Feedback Sensor Practices (Group B)

How mistakes get caught and fixed — the observation side of the harness. For guiding principles, see `../principles.md`. For meta-principles that govern WHEN to add any of these, see the meta-principles section in the same file.

## Hooks as deterministic enforcement

Claude Code hooks are the only mechanism inside the harness that *guarantees* an action happens. Anthropic's own guidance draws the line explicitly: *"Unlike CLAUDE.md instructions which are advisory, hooks are deterministic and guarantee the action happens."* If a rule in CLAUDE.md keeps getting broken despite being clearly written, the problem isn't the writing — it's that advisory rules are, by definition, advisory. Promote the rule to a hook.

Hook placement options, from cheapest to most invasive:
- `PreToolUse` — validate or block a tool call before it runs. Examples: refuse `rm -rf` on sensitive paths; inject a worktree-discipline reminder before any `git commit` on main; refuse destructive git patterns by blocklist (`git reset --hard`, `git push --force` on protected branches); **TDD guard — block `Edit` on implementation files until a matching failing test exists** (see Finster's `tdd-guard.sh` in the agentic-dev-team plugin for a worked example).
- `PostToolUse` — react after a tool call completes. Examples: auto-format after every `Edit`; log tool output to a file the agent can later grep when its context has been compacted; **log cumulative token cost per tool call to a session file so the agent can reason about its own budget** (Finster's `token-efficiency-review.sh`).
- `UserPromptSubmit` — inject context or rewrite the user's prompt. Examples: append current git status; remind the agent of active constraints; inject a link to a relevant skill; **pipeline-red restore-only injection — check CI state on each prompt and prepend a reminder that only restoration work is permitted when `main` is broken**.
- `Stop` / `SubagentStop` — final checks before returning control. Examples: verify tests are still green; verify no untracked files were forgotten; verify commit messages exist for any staged changes; **progress-guardian — check whether the session actually advanced its stated goal before returning, flag session drift if not**.

Treat hooks as code, not config — they're load-bearing. Write them in a real language, cover them with tests, and version them the same way you version source files.

## Error messages as positive prompt injection

When writing custom lint rules or structural tests, treat the error message as the context an AI agent receives when it needs to self-correct — but also as documentation for humans. A bare `"Type error on line 42"` helps nobody. A message with diagnosis + remediation enables a fix in the same loop, whether the reader is a person or a model.

Example:
```
ERROR: Module 'api' imports from 'ui'. Dependency direction violation.
FIX: Dependencies must flow Types → Config → Repo → Service → Runtime → UI.
Move shared types to the 'types' layer, or create a service interface.
```

> **Evidence disclaimer (Apr 2026):** this practice is a valid design heuristic supported by the direction of the field, but it lacks hard empirical backing. The closest signal: Augment Code observed that Python's more descriptive errors correlate with better agent benchmark performance than Java/C++, but this is a qualitative observation, not a controlled experiment. The academic community explicitly identifies agent-friendly toolchain output as an open research gap (arxiv 2508.11126). No study has isolated error message richness as an independent variable on agent self-correction rates. No trade-off between human-readability and agent-readability has been documented — richer, structured messages appear to help both audiences.

## Mechanical architecture enforcement

Documenting architecture in a `docs/architecture.md` file does not enforce it. Agents (and humans) violate undocumented-as-enforceable rules routinely. Pick a mechanical check per architectural invariant:
- Dependency direction rules (dependency-cruiser, ArchUnit)
- Module boundary tests
- File size limits
- Naming convention validators
- Import restriction rules
- **Fitness functions** (Ford, Parsons, Kua — *Building Evolutionary Architectures*): objective tests of architectural characteristics — coupling, latency, data sensitivity, cyclomatic complexity — run repeatedly as the codebase evolves. The generalisation of the bullets above: anything you can express as a numeric property of the architecture can be guarded by a fitness function. Fitness functions also compose naturally with structural tests — a dependency rule *is* a boolean fitness function.

When an architectural rule can't be mechanically enforced, treat it as aspirational and don't expect compliance.

If the target architecture isn't clear enough to enforce mechanically, reverse-engineer it first: have an agent map the de facto architecture from the code as it currently stands, ratify or correct the result, then lock it in with mechanical checks. Do NOT skip the ratification step — the whole point is to produce a ground truth that outlasts the next refactor.

## Wire verification to real systems

The guiding principle "Verification is the highest-leverage investment" (see `../principles.md`) established verification as the top priority; this practice refines it. The shallow reading is "make the agent run the test suite". The deeper reading is that the agent needs feedback rich enough to distinguish "actually correct" from "passes the tests I happened to write". Three channels extend the verification surface into the real software, each backed by different Tier 1 sources (see `../references/external-sources.md` for source details).

### Channel 1: CI as a feedback loop, not a distant verdict

Wire the agent into CI output so it can diagnose and fix failing jobs on its own. Two convergent Tier 1 patterns: OpenAI's Codex Cookbook describes a GitHub Actions setup where a `workflow_run` trigger fires Codex on any failed CI run — the agent reads the logs, runs the suite locally, applies the minimal fix, and opens a PR. Stripe's Minions documents the same loop with a hard cap of two CI rounds before human handoff, a deliberate safeguard against runaway autofix loops. Cheapest starting point for smaller repos: a one-shot command that pipes the last failing CI log into the next agent invocation.

*Caveat:* the "agent polls CI state in parallel with other coding sessions" framing is a field observation — both documented patterns are event-triggered, not polling-based.

### Channel 2: Drive the running application the way a user would (exploratory testing / agentic QA)

Give the agent the ability to launch and interact with the actual app, not just run unit and integration tests. This is the channel that supports **agentic exploratory testing** and **agentic QA** sessions: the agent navigates the app, clicks, types, observes behavior, and diagnoses deviations — the same loop a human explorer would run, but automated. OpenAI's harness-engineering article describes wiring Chrome DevTools Protocol into the Codex runtime with the app bootable per git worktree — each agent instance spins up its own live copy, reproduces bugs against the live DOM, validates fixes by navigating the UI, and reasons about visual state from screenshots. Anthropic's harness-design piece reports the same pattern via Playwright MCP: an evaluator agent clicks through the running app, observes API responses and database state, and compares against expectations before approving a build. The point is not "turn this into E2E tests" but "exercise the software in the shape it will actually ship".

*Caveat:* beyond browsers, the analogous extensions — `curl`/`httpie` for backend APIs, `adb` for Android, iOS simulators, scripted CLI sessions — are not directly documented in the sources but follow the same principle. Treat them as extensions by analogy rather than canonical patterns.

### Channel 3: Expose a real observability stack, ephemeral per worktree

Let the agent query logs, metrics, and traces from a real run of the app, not just stdout captured during a test. OpenAI describes an observability stack that is ephemeral per git worktree: the agent queries logs and metrics through proper query languages (LogQL/PromQL or equivalent), reasons about what actually happened, and the whole stack tears down with the worktree. For smaller repos, a `docker-compose` with a log aggregator and a Prometheus sidecar gets most of the benefit for near-zero ongoing cost. The load-bearing property is *ephemeral, per task* — a shared stack accumulates noise and leaks state across sessions, defeating the point.

*Caveat:* dev/ephemeral access is directly supported by the literature. Production access — even strictly read-only — is ahead of that discourse: Simon Willison's *Designing agentic loops* explicitly recommends keeping agents out of production in favour of containment. If you wire a prod read path anyway (there are real cases where it unblocks otherwise-impossible debugging), treat it as experimental: scoped credentials, explicit query allowlist, a hard wall against any write path, and human review of every session that touches it. Not because it can't work — because nobody has documented the failure modes yet.

*Source caveat:* two of the main articles behind this practice (OpenAI's harness-engineering and Fowler/Böckeler's) returned HTTP 403 during source verification. The patterns above are reconstructions cross-checked against multiple independent summaries (InfoQ, Latent Space, mirror copies). They're consistent across sources, but if you intend to quote any of this verbatim publicly, spot-check the original articles yourself first.

## Structured agentic reviews

A single agent reviewing "everything" applies every lens shallowly. The result is generic feedback that the user skips. Effective agentic reviews are **narrow**, **multi-dimensional**, and **adversarial** — three properties that must be designed in, not hoped for.

### Narrow scope

Review a small, bounded changeset — a few commits, a single feature boundary, one architectural decision. Broad reviews ("review the whole repo") produce noise because the agent has to spread its context budget across too many concerns. Narrow reviews let the agent saturate a small surface and find real issues.

Practical guidance:
- Scope by commit range (`git diff base..HEAD`), by path (`src/domain/`), or by artifact type (all acceptance criteria for feature X).
- If the changeset is too large, split it. Multiple narrow reviews beat one broad review every time.
- The review tooling should make scoping easy — if it doesn't, that's a Phase 3 proposal.

### Multi-dimensional dispatch

Dispatch **one sub-agent per review dimension**, each with a focused mandate and a specific checklist. Dimensions are independent — running them in parallel via sub-agents produces deeper findings faster.

Recommended dimensions (adapt to context):

| Dimension        | Mandate                                                                                       |
|------------------|-----------------------------------------------------------------------------------------------|
| Correctness      | Does the code do what the spec says? Are edge cases handled?                                  |
| Security         | OWASP top 10, input validation, secrets exposure, injection vectors                           |
| Performance      | Algorithmic complexity, N+1 queries, unnecessary allocations, missing caching                 |
| Architecture     | Dependency direction, layer violations, coupling, fitness function compliance                  |
| Test quality     | Coverage of happy path + edge cases, test isolation, assertion quality, mutation survival risk |
| Intent alignment | Does the implementation match the acceptance criteria / user story / ADR that motivated it?   |

A monolithic review agent implicitly runs all these lenses in sequence inside one context window, with each lens getting a fraction of the attention budget. Splitting them means each lens gets the full window.

### Adversarial posture

The default review posture is **confirmatory**: "does this code do what the author intended?" The adversarial posture is the opposite: "what assumptions does this code make that could be wrong?" Adversarial reviews actively try to break the artifact under review.

Key adversarial techniques:
- **Assumption extraction** — before judging the code, list the assumptions it makes (about inputs, about the environment, about upstream contracts). Then challenge each one: is this assumption documented? Tested? Guaranteed by something mechanical?
- **Negative-space review** — what is NOT in the changeset that should be? Missing error handling, missing tests, missing migrations, missing documentation updates. Absence is harder to spot than presence.
- **Upstream artifact review** — review plans, ADRs, acceptance criteria, and user stories with the same adversarial lens. A flawed acceptance criterion produces correct-but-wrong code. The earlier the artifact, the higher the leverage of catching a defect in it. Specifically:
  - **Plans**: are the steps complete? Do they cover rollback? Do they account for concurrent work?
  - **ADRs**: is the "rejected alternatives" section honest? Are the trade-offs quantified or hand-waved?
  - **Acceptance criteria**: are they testable? Do they cover failure modes, not just happy paths?
  - **User stories**: does the "so that" clause name a real, verifiable outcome?
- **Pre-mortem** — assume the implementation will fail in production. What is the most likely cause? Work backwards from that failure to the current code.

### When to use which combination

| Situation                             | Scope      | Dimensions           | Posture       |
|---------------------------------------|------------|----------------------|---------------|
| PR review (few commits)               | Narrow     | All relevant dims    | Adversarial   |
| Plan review before implementation     | The plan   | Intent, architecture | Adversarial   |
| Post-feature quality gate             | Feature    | All dims             | Adversarial   |
| Quick sanity check mid-implementation | 1-2 files  | Correctness, tests   | Confirmatory  |
| ADR / acceptance criteria review      | 1 artifact | Intent alignment     | Adversarial   |

*Source notes:* The narrow/multi-dimensional/adversarial decomposition is a synthesis of practices from MinimumCD's Expert Validation Agents (see `../references/external-sources.md`), Finster's agentic-dev-team (19 specialised review agents rather than one monolithic reviewer), and Stripe's Minions (scoped review with human handoff). The adversarial techniques (assumption extraction, negative-space, pre-mortem) draw from established code review and risk analysis literature adapted to the agentic context.
