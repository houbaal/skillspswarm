# Principles

Two levels of principles govern the harness. **Meta-principles** decide WHEN to add a rule, WHERE to aim it, and WHICH layer owns it. **Guiding principles** decide WHAT matters most — they set priorities, not methods. Practices (in `practices/`) describe HOW.

Read this file before proposing any new practice in Phase 3.

## Meta-principles

### Every rule must be earned

Before proposing any rule, check: is the failure it prevents **earned** — either by a named incident in this project, or by a well-documented failure mode that is statistically certain given the project's architecture and stack choices? Or is it a theoretical concern you're imagining?

Every rule in the harness is a tax. It consumes tokens on every invocation, slows review, and creates drag on future changes. The tax must be paid by a concrete failure mode — but that failure mode doesn't have to have happened *here* yet. Theoretical rules accumulate into the kind of bloated instruction file that measurably degrades agent performance — the same reason Phase 1.1 of the workflow pushes back against inlining anything the agent could infer on its own.

**Two ways a rule is earned:**

1. **Incident-earned** — a named, observed failure in this project or a directly comparable one. The classic case: you watched the agent break something, now you encode the fix.
2. **Prevention-earned** — the failure hasn't happened yet in this project, but it is *statistically certain* given the architecture/stack choices, and the cost of prevention is lower than the cost of the first incident. Example: if you adopt hexagonal architecture, agents *will* violate layer boundaries — it's not "if" but "when". Adding an architectural test (dependency-cruiser, ArchUnit) before the first violation is prevention, not speculation. The rule is earned by the architecture decision itself.

**What is NOT earned:** a rule with no basis in either project experience or documented industry failure modes for this type of architecture/stack. "We might need this someday" is speculative. "Every project using X hits this problem" is preventive.

The practices in `practices/` describe HOW to encode fixes; this meta-principle is the gate for WHEN.

### Swiss Cheese Model — diversity over depth

Every practice in the harness has holes. A linter catches syntactic mistakes but misses semantic ones. A type checker catches structural drift but misses runtime behaviour. A test suite catches behavioural regressions but misses operational surprises that only surface against real data. An AI reviewer catches semantic oddities but hallucinates its share of false positives. No single practice covers everything.

The probability of a defect surviving the harness is the product of the probabilities that each layer misses it — and that product only collapses toward zero when the layers catch *different kinds* of mistakes. The holes have to be in different places. This is James Reason's Swiss Cheese Model applied to coding-agent reliability: stack enough non-aligned layers and the failure modes get caught by at least one of them. Two linters with overlapping rule sets don't add meaningful coverage; a linter + a type checker + a smoke test + an exploratory session do.

#### Operational consequences for the hardening plan

- When picking the next improvement, deliberately aim at a category your harness has no presence in yet, not at a category you already cover. If you already have a formatter and a linter, the next investment is a type checker, a structural test, or a runtime smoke test — not a second linter.
- Use the guides/sensors × computational/inferential grid from the Context section of `SKILL.md` as a 2×2 coverage check. A harness biased heavily toward any single quadrant has aligned holes by construction.
- As a second, complementary coverage check, overlay your harness onto a full pipeline stage catalogue (the MinimumCD Pipeline Reference Architecture in `references/external-sources.md` is one such catalogue) and mark which stages your agent can actually exercise in-session. The gaps between what the pipeline catalogues and what your harness reaches are, by definition, where humans remain the feedback loop — making those gaps visible is half the point of the audit.
- A single dimension scored at level 4 on the scorecard is worth less than three dimensions scored at level 3 if the three cover distinct defect categories. Breadth beats depth — until breadth is already in place, at which point depth starts paying.
- Mixing computational and inferential coverage matters most. Computational checks what it's told to check (low false positives, predictable blind spots); inferential catches surprises at the cost of noise (high coverage, noisy). Together they cover each other's holes; apart, neither is sufficient.

### Scope — user-level vs project-level

Every rule added to the harness lives somewhere — inside the project (`<repo>/.claude/rules/`, `<repo>/.claude/skills/`, `<repo>/.claude/settings.json`, `<repo>/CLAUDE.md`) or at the user level (`~/.claude/rules/`, `~/.claude/skills/`, `~/.claude/settings.json`, `~/.claude/CLAUDE.md`). The choice is not cosmetic: it changes blast radius, reversibility, and who pays the ongoing token tax on every session of every repo.

**Default heuristic:**

- **Methodology and discipline** (BDD, test-first, scope hygiene, review rituals, tone, communication style) → **user-level by default**. These cross-cut every project the user touches; duplicating them per-repo accumulates drift and forces the user to re-teach the same habit each time they bootstrap a new repo.
- **Tech, stack, and config** (linters, formatters, type checkers, project-specific hooks, architecture fitness functions, framework conventions) → **project-level by default**. These are bound to the concrete stack of the repo and don't generalise cleanly to unrelated projects.

**When the defaults flip:**

- A user with many repos sharing the same stack may prefer to **promote** a tech/config rule up to user-level — portfolio DRY beats local control when the stack is genuinely shared and the user is tired of copy-pasting the same hook into every new repo.
- A project with stricter discipline than the user's baseline (regulated environment, safety-critical code, higher-risk codebase) may need to **override** a user-level methodology rule with a tighter project-level one. Project rules take precedence on conflict, which makes this safe.

**Portability test:** if a rule must survive `rm -rf` of the repo, it belongs at user-level. If the rule only makes sense against the files of this specific repo, it stays at project-level. A rule that would be silently wrong in a different context is a project-level rule in disguise, no matter where it currently lives.

**Inverse check — audit both directions.** When auditing an existing harness, look both ways. A user-level rule that only serves one project is misplaced — propose **demoting** it to project-level to reduce the token tax paid on every other repo. A project-level rule repeated (identical or near-identical) across N repos is a DRY violation — propose **promoting** it to user-level to stop paying the maintenance cost N times. Both directions of drift are real and both deserve a Phase 3 proposal when detected.

**Output consequence:** every proposal in Phase 3 must carry a scope tag — `[user]`, `[project]`, or `[either — user's call]`. When tagged `[either]`, Phase 4 asks the user explicitly at implementation time rather than silently defaulting. Untagged proposals are incomplete and should be sent back to Phase 3 before implementation starts.

### Tension between the three

These principles pair with each other deliberately. "Every rule must be earned" constrains the *rate* at which new rules enter the harness. "Swiss Cheese" constrains the *direction* — when you do add a rule, pick it to cover a new kind of failure, not to deepen a category you already cover. "Scope" constrains the *location* — once the rate and direction are decided, the rule still has to land in the right layer, or it either leaks cost across projects it doesn't serve or fragments into duplicated copies. Two practices in the same category cost two taxes and buy very little; the same practice duplicated across the user and project layers costs two taxes and buys negative value (conflict risk).

---

## Guiding principles

These govern WHERE and WHAT to prioritise. They don't prescribe specific methods — the practices in `practices/` do that.

### Verification is the highest-leverage investment

Without verification — tests, screenshots, lint output, type checkers, smoke tests — YOU are the feedback loop. Every mistake the agent makes requires a human to notice and correct, which defeats the point of having an agent in the first place. With verification, the agent detects and fixes its own mistakes in the same invocation, inside the same loop.

Anthropic's own Claude Code guidance ranks this above everything else: *"Include tests, screenshots, or expected outputs so Claude can check itself. This is the single highest-leverage thing you can do."*

Practical consequences for a harness audit:
- Before investing anywhere else, check whether the repo has working verification *that the agent can actually run in-session*. Tests that only CI runs don't count — the agent needs to invoke them itself and react to the output before returning.
- A 30-second smoke test that runs on session start (or via a hook) prevents the common failure mode where an agent builds on top of already-broken code because a previous session left the repo red.
- Verification that produces opaque error messages defeats its own purpose — the output has to be actionable by the next agent invocation.

### Shift quality left

Fast, cheap checks belong BEFORE commit, where the feedback loop is measured in seconds. Expensive checks belong in CI, where the feedback loop is measured in minutes.

Suggested ordering (each step is a gate for the next):
1. Formatter (instant) — normalises style before anything else judges it
2. Linter (seconds) — catches syntactic and simple semantic mistakes
3. Type check (seconds) — catches structural mistakes
4. Fast tests (seconds to minutes) — catches behavioural mistakes on the unit level
5. Pre-push hooks — last chance before the work becomes visible to others

Expensive checks — mutation testing, broad AI review, full e2e suites — run in CI, not on the developer/agent's critical path.

### Encode every recurring mistake (Hashimoto rule)

Apply the Hashimoto rule, in his own words: *"Anytime you find an agent makes a mistake, you take the time to engineer a solution such that the agent never makes that mistake again."* Each fix chooses the cheapest channel that prevents the failure:
- A rule in CLAUDE.md/AGENTS.md (for convention violations that are hard to enforce mechanically)
- A lint rule or structural test (for enforceable constraints — always preferred over the above)
- A skill with instructions (for complex multi-step procedures)
- A Claude Code hook or pre-commit hook (for deterministic prevention of a specific pattern)

Note: this principle is downstream of the meta-principle *Every rule must be earned*. The recurring mistake earns the encoding; the encoding has to be cheaper than the failure mode it prevents.

### Governance constraints as operating envelope

Some rules aren't practices — they're invariants about *what the agent is allowed to do*, not how it does it. They scope the operating envelope before any check runs. The MinimumCD Agentic CD guide (Finster, Kusters, Prugh) names four that belong in any harness granting an agent meaningful autonomy:

- **Agents cannot promote changes to production.** Deployment authority stays human, or at minimum belongs to a separate system with its own trust boundary. Encode as a `PreToolUse` hook refusing `kubectl apply` on prod contexts, `terraform apply` on prod workspaces, or equivalent. Cheap to add, load-bearing.
- **Pipeline red = restore-only mode.** When `main` is broken, the only work an agent may do is restore health. New feature work on a red pipeline compounds damage and obscures root cause. A `UserPromptSubmit` hook that checks CI state and injects a restore-only reminder when red is the cheapest encoding.
- **Versioned delivery artifacts.** Every change the agent produces must be identifiable — commit SHA, build hash, signed tag. No "apply these changes directly" or "patch the running system" side-channels. This is what makes every other check meaningful: you can't gate what you can't name.
- **Explicit, human-owned intent for every change.** The agent may draft, generate, and refactor, but the *why* of the change stays anchored to a human artifact: a ticket, a spec, a plan file. No autonomous specification drift.

These are design-time constraints chosen once and encoded at the hook layer so they can't be forgotten mid-session.

#### Unsupervised autonomous execution (YOLO mode)

If the harness permits unsupervised autonomous execution, the blast radius must be bounded. Autonomous execution is where the productivity lives AND where the danger lives — the two are inseparable. The way to have both is to scope the operating envelope.

**Default:** bound YOLO mode with all of the following:
- Run in a sandboxed environment (Docker, Apple containers, Codespaces)
- Use scoped credentials that can't touch production
- Set explicit budget caps (time, tokens, tool calls)
- Pair with the governance constraints above (no prod promote, red = restore-only, versioned artifacts, human-owned intent)

**When to override:** local-only development with no external side effects (no network calls, no shared state) may safely relax sandboxing. Budget caps can be adjusted to match the task — but never removed entirely, because unbounded loops are unbounded cost.

A harness that allows YOLO without scoping is badly shaped regardless of how good its CLAUDE.md is. Simon Willison's *Designing agentic loops* (see `../references/external-sources.md`) makes this case in detail.
