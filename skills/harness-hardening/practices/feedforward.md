# Feedforward Practices (Group A)

How the agent gets what it needs to act — the steering side of the harness. For guiding principles, see `../principles.md`. For meta-principles that govern WHEN to add any of these, see the meta-principles section in the same file.

## Progressive disclosure over monolithic instructions

Don't put everything in CLAUDE.md. Layer information so the agent loads only what it needs for the task at hand:

- CLAUDE.md / AGENTS.md at the repo root = concise table of contents + universal rules, loaded every session
- Subdirectory `CLAUDE.md` / `AGENTS.md` = instructions loaded on demand when the agent reads files in that subtree (directory-bound scope)
- **`.claude/rules/*.md` (project) and `~/.claude/rules/*.md` (user) = modular instructions, optionally path-scoped via a `paths:` YAML frontmatter with explicit glob patterns** (glob-bound scope, the most precise layer)
- `.claude/commands/` = task-specific slash commands loaded on demand
- `docs/` = deep reference documentation pulled in when the agent reads a related file
- Skills = reusable instruction modules loaded when their trigger description matches (inferential, model-judged)

This keeps every invocation lean and defers detail to the moment it's actually useful. The pattern is what OpenAI uses for their 1M-line Codex case study: a ~100-line `AGENTS.md` acting as a table of contents that points into a structured `docs/` tree, rather than inlining everything.

### Default: don't auto-generate instruction files

Auto-generated instruction files (CLAUDE.md, AGENTS.md) tend to hurt agent performance and increase token cost. The ETH Zurich study (Gloaguen et al., Feb 2026 — see `../references/external-sources.md`) found that LLM-generated files reduced success by ~2% and increased cost by ~20%, while hand-written files improved success by ~4% (at +19% cost). The core reason: 95–100% of auto-generated content duplicates information agents can already discover from docs and code.

**Default:** hand-craft instruction files, or leave them alone. If you don't have time to hand-craft, no file beats a generated file.

**When to override:** no rigorous study has tested a hybrid approach (auto-generate + human curation). If you try one, treat it as experimental and measure the result. Also: when existing documentation is removed or absent, auto-generated files recover ~2.7% of performance — so the calculus changes for repos with no docs at all.

> **Evidence disclaimer (Apr 2026):** this default rests primarily on one study (ETH Zurich, 438 tasks, 4 models). A second study (McMillan, 2026) found similar patterns (+2.7% for frontier models, -7.7% for open-source). No contradicting study exists, but the evidence base is thin and the field is moving fast. Re-evaluate when new benchmarks appear.

### Default: don't inline codebase overviews

Directory trees and file-by-file descriptions in instruction files do not measurably help agents find relevant code faster. The ETH Zurich study found overviews did not reduce navigation steps. Anthropic's official best practices explicitly exclude "file-by-file descriptions of the codebase" from CLAUDE.md. The maintenance cost is real: a study of thousands of context files (Mohsenimofidi et al., 2025) found median update interval of ~24 hours in active codebases — static listings drift fast.

**Default:** don't inline overviews. Instead, document what agents can't infer: custom build commands, non-obvious conventions, intentional architectural decisions that look wrong to an outsider.

**When to override:** monorepos with non-obvious service boundaries, or codebases with unconventional structure that breaks framework assumptions. In those cases, limit the overview to 5–10 lines covering service boundaries only — not a full directory tree. A CI-regenerated overview (fresh at every commit) would avoid the staleness problem, but no study has tested whether it actually helps agents.

> **Evidence disclaimer (Apr 2026):** no study has directly compared CI-regenerated overviews vs static vs none. No monorepo-specific data exists. The "don't inline" default is well-supported for standard single-project repos; for other layouts, treat it as a strong default that may need exceptions.

**The path-based layers are the most under-rated part of the list above.** Claude Code ships three ways to scope instructions so they fire on a deterministic trigger, ranked from coarsest to most precise:

1. **Subdirectory `CLAUDE.md`** — scope is a directory. Loaded when the agent reads files in that subtree. Good for package-local conventions where the whole area has its own rules and a directory-wide scope is enough.
2. **`.claude/rules/*.md` without frontmatter** — scope is the whole project. Loaded unconditionally at session start with the same priority as `.claude/CLAUDE.md`. Good for splitting long instructions into topic files (`rules/testing.md`, `rules/security.md`, `rules/api-design.md`) for maintenance, without needing finer filtering.
3. **`.claude/rules/*.md` with a `paths:` YAML frontmatter** — scope is exactly the glob you write. Loaded only when the agent works on files matching a pattern like `src/api/**/*.ts`, `**/*.{ts,tsx}`, or `tests/**/*.test.ts`. Most precise layer in the harness: you name the file patterns explicitly, no directory-boundary guessing.

All three fire on path criteria — no model judgment involved, no missing. Compare to skills, which fire on inferential trigger-description matching: the model judges whether the skill description applies to the current task, and can miss when the description is ambiguous or the task is oblique. For rules that *must* apply whenever the agent touches a specific area, any path-based layer is strictly more reliable than a skill.

User-level `~/.claude/rules/` loads before project rules (project takes precedence on conflict). Debug loading issues with the `InstructionsLoaded` hook.

### Prose-mention: the universal progressive disclosure pattern

Mention a file path as plain text in prose (no `@` prefix). The agent sees it, remembers it, and calls `Read` only when the topic comes up. **Zero context weight until needed.** Contrast with `@`, which force-loads into context on every invocation.

Applies to every instruction surface: root CLAUDE.md, subdirectory CLAUDE.md, `.claude/rules/*.md`, hook scripts, slash commands, skills. This skill itself uses the pattern for its reference tree.

**`@` vs prose-mention.** `@` = always needed → directive. Prose-mention = sometimes needed → hint. Default to prose-mention; promote to `@` only if the file is load-bearing on every invocation.

**Complementary with path-scoped rules.** Path-scoped rules fire on deterministic file-path triggers (globs). Prose-mentions fire on inferential topic triggers (agent judges relevance). Use both: path-scoped for constraints on touched files, prose-mention for conceptual procedures.

**Writing a useful prose-mention:** (1) clear path, (2) one-line description, (3) explicit trigger condition. Without (3), the agent treats it as decorative. Example: *"See `~/.claude/rules/worktree-commits.md` — load before your first commit of a new branch."*

## Minimize MCP tool surface

Each enabled MCP server consumes context for its tool descriptions on every invocation, whether the tools are used or not — *unless the client implements deferred loading*. Guidelines:
- Only enable MCP servers actively in use
- If a CLI exists in training data (git, docker, npm, kubectl, etc.), prefer the CLI — the agent already knows it, no description needed
- Consider replacing verbose MCP servers with lean custom CLIs that return context-efficient responses
- Document example CLI usage in CLAUDE.md (saves thousands of tokens versus leaving the agent to infer MCP tool semantics)

The HumanLayer team documents the payoff concretely: replacing the Linear MCP with a thin custom CLI dropped their tool surface enough that the agent stopped getting distracted by tool descriptions it never used. The same pattern applies to most MCP servers that wrap an existing CLI — the wrapper is paying a tax the wrapped tool doesn't need.

> **Evidence disclaimer (Apr 2026):** the MCP specification (2025-06-18) still defaults to eager loading — all tool schemas sent on `tools/list`. However, Claude Code auto-defers tool loading when descriptions exceed ~10% of the context window (shipped ~v2.1.7), and the Claude API offers `defer_loading` + Tool Search since Nov 2025. Other clients (Cursor, Codex) must implement their own mitigations. Spec-level lazy loading has been proposed (GitHub issues #1978, discussion #532) but not adopted. The tax is real but shrinking — re-evaluate as the protocol evolves.

## Moldable inspection views (field observation, outside the canonical literature)

When the agent needs information about the codebase that grep, glob, and plain file reads can't surface directly — the current shape of module dependencies, which files churn together, how aggregates currently map to the data model, where the dead code is concentrated — the cheapest answer is usually a small, disposable program written on the spot. A shell script that dumps a CSV of coupling scores. A one-shot Python snippet that walks the AST and emits a PlantUML diagram. A web page rendered from a JSON extract. The output doesn't have to be pretty; it has to be accurate for the question asked.

This is a degenerate form of Tudor Gîrba's moldable development (Glamorous Toolkit) applied to agent harnesses. The full discipline is much richer; what belongs in a harness is the habit of building custom views instead of asking the agent to reconstruct them from raw reads every time. The view is cheaper to build once than to reconstruct on each session, it stays accurate as the codebase evolves (rerun it, no drift), and it keeps the agent's context clean because the output is a focused artifact rather than a sprawling file walk.

Why this is a feedforward guide, not a sensor: the view feeds the agent non-inferable context *before* it acts — the same role CLAUDE.md plays but with higher fidelity. Prose rots; a script rerun yields current truth.

*Field observation note:* this technique is not in the canonical harness-engineering literature as of April 2026 (checked against OpenAI, Anthropic, Fowler/Böckeler, Stripe, HumanLayer, LangChain, Hashimoto, Willison). If you add a moldable view to a harness, you're applying an idea from an adjacent tooling community that the discipline has not yet absorbed. That's not a reason to skip it — it's a reason to earn it the way the meta-principle demands: build the view when the pain justifies it, not speculatively.

## Prompting disciplines as named layers

Inferential feedforward isn't a single thing you do — it's a stack of four increasingly durable layers, each with its own tools and failure modes. The MinimumCD Agentic CD guide names them in order of durability:

1. **Prompt Craft** — the immediate request shaping. How you phrase what you want right now. Disposable, per-message, lowest durability.
2. **Context Engineering** — what background the agent receives. Files it can read, skills it has loaded, prior artifacts in scope. Persists across a session.
3. **Intent Engineering** — the *why*, the constraints, the success criteria. The implicit contract the agent works against. Usually encoded in plans, acceptance criteria, or task briefs.
4. **Specification Engineering** — the formal artifacts the agent works against: architecture docs, ADRs, schemas, committed feature lists. The most durable layer, and the only one that survives across teams and sessions without loss.

A mature harness invests in all four. Leaning on prompt craft alone — clever phrasing per request — is amateur hour, because nothing you learn sticks. Specification engineering without context engineering is the inverse failure: you have great docs but the agent never loads them. Each layer compensates for a different failure mode; they're not substitutes.

Operationally: if you find yourself repeating the same clarification in every session, the fix is to promote it one layer up (prompt → context → intent → specification). Every promotion trades a small one-time cost for a continuous saving.
