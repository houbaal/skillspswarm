# External Sources

Tier 1 sources behind each principle. The workflow executes without any of these — read selectively for the *why* behind a principle or for worked examples.

---

## Framework and naming

**Fowler & Böckeler — Harness engineering for coding agent users** (Apr 2026)
https://martinfowler.com/articles/harness-engineering.html
Conceptual framework: guides/sensors split, computational/inferential axis. Backs the Context section and Phase 2 scoring.

**Fowler — Harness engineering first thoughts (memo)** (Feb 2026)
https://martinfowler.com/articles/exploring-gen-ai/harness-engineering-memo.html
Earlier memo. Key phrase for P12: *"agent access to dynamic context like observability data and browser navigation"*.

**Hashimoto — My AI Adoption Journey** (Feb 2026)
https://mitchellh.com/writing/my-ai-adoption-journey
Source of P8: *"Anytime you find an agent makes a mistake, engineer a solution such that it never makes that mistake again."*

**ignorance.ai — The Emerging Harness Engineering Playbook** (Feb 2026)
https://www.ignorance.ai/p/the-emerging-harness-engineering
Best single entry point. Cross-synthesises OpenAI, Stripe, Hashimoto, Anthropic.

---

## Instruction files and progressive disclosure

**Anthropic — How Claude remembers your project** (Claude Code docs)
https://code.claude.com/docs/en/memory
Canonical reference for P1 path-based layers. Documents `paths:` frontmatter, `InstructionsLoaded` hook, user vs project rule precedence. Read before Phase 1.1.

**Gloaguen et al. — Evaluating AGENTS.md** (ETH Zurich, Feb 2026)
https://arxiv.org/abs/2602.11988
Only empirical study: auto-generated context files reduce success by ~2% and cost ~20% more tokens; hand-written improve ~4%. Backs Phase 1.1 and the "earned" meta-principle.

**Pocock — A Complete Guide to AGENTS.md**
https://www.aihero.dev/a-complete-guide-to-agents-md
"Instruction budget" framing. Useful vocabulary for pushing back against bloat.

**HumanLayer — Skill Issue: Harness Engineering** (Mar 2026)
https://www.humanlayer.dev/blog/skill-issue-harness-engineering-for-coding-agents
Most tactical article. Covers every lever this skill uses. Concrete example: replacing Linear MCP with custom CLI (P2). Companion: https://www.humanlayer.dev/blog/writing-a-good-claude-md

---

## Verification, hooks, feedback loops

**Anthropic — Claude Code best practices**
https://code.claude.com/docs/en/best-practices
Source of quotes in P3 ("single highest-leverage"), P5 ("hooks are deterministic"), P10 ("context is your fundamental constraint").

**Anthropic — Effective harnesses for long-running agents** (Nov 2025)
https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents
JSON-over-Markdown pattern (P9), dual-agent split, `feature_list.json` with write-restricted fields.

**Anthropic — Harness design for long-running apps** (Mar 2026)
https://www.anthropic.com/engineering/harness-design-long-running-apps
Triple-agent pattern. Meta-insight: harness hypotheses about model limitations need periodic stress-testing. Primary secondary source for P12 Channel 2.

---

## Case studies at scale

**OpenAI — Harness engineering: leveraging Codex** (Feb 2026)
https://openai.com/index/harness-engineering/
1M lines, 3 engineers. AGENTS.md as ~100-line TOC (P1), custom linters (P7), error messages as prompts (P6), garbage-collection agent. Primary source for P12 Channels 2-3.

**OpenAI Cookbook — Autofix CI failures with Codex**
https://developers.openai.com/cookbook/examples/codex/autofix-github-actions
Cleanest reference for P12 Channel 1: `workflow_run` trigger fires Codex on failed CI.

**Stripe — Minions** (Feb 2026)
https://stripe.dev/blog/minions-stripes-one-shot-end-to-end-coding-agents
Blueprints pattern, pre-push auto-fix, strict 2-pass CI budget. Backs P4, P5, P12. Key insight: DX investments *are* agent capability investments.

**LangChain — Improving Deep Agents** 
https://blog.langchain.com/improving-deep-agents-with-harness-engineering/
#30 → #5 on Terminal Bench by changing only the harness. Reproducible trace-analysis recipe.

---

## Pipeline taxonomy and Agentic CD

**Scope caveat:** P13/P14 are lifted from this literature. Use as external coverage check, not to import wholesale.

**MinimumCD — Pipeline Reference Architecture** (Finster et al.)
https://beyond.minimumcd.org/docs/reference/pipeline-reference-architecture/
Stage-by-stage technique catalogue with latency budgets. AI-native additions marked with triangle.

**MinimumCD — Agentic CD** (Kusters, Finster, Prugh)
https://beyond.minimumcd.org/docs/agentic-cd/
Source of P13's four governance invariants.

**MinimumCD — Four Prompting Disciplines**
https://beyond.minimumcd.org/docs/agentic-cd/getting-started/prompting-disciplines/
Source of P14's four-layer durability stack: Prompt Craft → Context → Intent → Specification Engineering.

**MinimumCD — Pipeline Enforcement (Expert Validation Agents)**
https://beyond.minimumcd.org/docs/agentic-cd/operations/pipeline-enforcement/
Named patterns for P12: test fidelity, coupling, conformance, intent alignment, constraint compliance agents.

**Finster — AI Patterns** (personal repo)
https://bdfinst.github.io/ai-patterns/
Phase 1/Phase 2 review split. Same computational/inferential distinction.

**Finster — Agentic Dev Team** (Claude Code plugin)
https://github.com/bdfinst/agentic-dev-team
19 review agents + 11 hooks. Most reusable source for concrete P5 hook examples.

**Ford, Parsons, Kua — Building Evolutionary Architectures** (O'Reilly)
Fitness functions. Original source for P7's deeper framing.

---

## Workflow and guardrails

**Boris Tane — How I use Claude Code** (Feb 2026)
https://boristane.com/blog
Research → plan.md → human annotation → implementation. Strict "no code before approved plan" rule.

**Simon Willison — Designing agentic loops** (Sep 2025)
https://simonwillison.net/2025/Sep/30/designing-agentic-loops/
Backs the YOLO guardrail: bound the operating envelope when relaxing supervision.
