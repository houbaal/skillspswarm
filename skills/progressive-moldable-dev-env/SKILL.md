---
description: Use when the developer cannot answer a question about the system by reading code alone, when understanding requires seeing dependencies, state, or behavior visually, when recurring confusion or surprises indicate a blind spot, or when domain objects need to be explored interactively rather than traced mentally — propose to the user before invoking
---

# Progressive Moldable Development Environment

> **This skill is not affiliated with, endorsed by, or reviewed by Tudor Girba, Simon Wardley, or the feenk team.**
>
> "Progressive Moldable Development" is a working label. True moldable development, as defined by Girba and feenk, requires a moldable IDE where objects carry their own views (Glamorous Toolkit). This skill borrows principles from moldable development and applies them using mainstream technology with AI agents as enablers. It does not claim equivalence with GT's moldability — it provides a pragmatic path toward system understanding through custom views and micro-tools.

## Authoritative Sources

Informed by:
- **Moldable Development Patterns** — Oscar Nierstrasz and Tudor Girba (EuroPLoP 2024)
- **Rewilding Software Engineering** — Tudor Girba and Simon Wardley (Medium/feenk, 2025)
- **moldabledevelopment.com** — the official site defining the principles

See `references/external-sources.md` for links and attribution.

---

## Why Moldable Development

**Software engineering is primarily a decision-making activity.** Developers spend over half their time figuring systems out — not writing code. This is the single largest development expense.

The goal of moldable development is to **make systems explainable** — systems that can answer questions about themselves through custom tools built specifically for each question. Views are the means, not the end. A beautiful visualization that doesn't inform a decision is decoration. An ugly table that reveals something you didn't know is invaluable.

**The methodology matters more than the tools.** Building views without the question/answer discipline produces pretty artifacts that don't change what you do next. The discipline of asking the right question, building the cheapest view that answers it, evaluating the answer, and following the thread — that is what makes moldable development work.

---

## MANDATORY OUTPUT CONSTRAINT

**Your output MUST be a VIEW — a visual tool that makes system state visible.** This is the entire point of moldable development. If your output is not a view, you are not doing moldable development.

### What counts as a view

| Output mode        | Acceptable output                                                                    |
|--------------------|--------------------------------------------------------------------------------------|
| Terminal views     | A **script** that DISPLAYS something: table, ASCII diagram, state machine, colored output, sparklines |
| Web views          | A **web page/server** that RENDERS domain entities with clickable navigation         |
| Domain playgrounds | An **interactive interface** where you feed inputs to domain objects and see results  |
| Live view coding   | A **same-language environment** with embedded REPL for prototyping views in-place     |
| Moldable IDE       | A **fully moldable environment** where objects carry their own views (GT)             |

### What does NOT count as a view

| Not a view               | Why                                                                             |
|--------------------------|---------------------------------------------------------------------------------|
| A test                   | Tests verify behavior. Views make behavior VISIBLE. Different purpose.          |
| A raw database query     | A query returns data. A view PRESENTS data for human reasoning.                 |
| A code fix or refactoring| Fixing is acting. Moldable dev is about SEEING before acting.                   |
| A plan or documentation  | Plans describe intentions. Views show concrete, live system state.              |

### Self-check before proposing anything

> **"Does this PRODUCE a visual artifact the developer can LOOK AT?"**

- If yes: proceed.
- If no: STOP. Reformulate as a view.

**Example:** Developer says "I can't see why campaign messages aren't sent."
- BAD: "Let's write an acceptance test" or "Let's query the database"
- GOOD: "Let's build a script that traces a campaign through all phases and displays the state machine with current lead positions"

---

## Before You Build Anything — Find Your Blind Spot

A **Blind Spot** is the part of a system that is difficult to understand, monitor, or debug — and that is actively creating problems.

**Answer these three questions before choosing any tool or output mode:**

1. **What decision are you trying to make about this system right now?**
   Not "I want to understand the codebase." A specific decision.

2. **What can't you see clearly enough with your current tools?**
   What forces you to read files line by line or hold complex relationships in your head?

3. **What part of the system causes recurring confusion, pain, or surprises?**
   The thing that bites you every sprint. The module nobody wants to touch.

**Your answer to #3 is your blind spot. Start there.** Not with a grand architecture visualization. With the one thing that hurts most.

---

## The Question/Answer Cycle

This is the core practice. Everything else in this skill — output modes, analysis depths, tools — serves this cycle.

```
Question → View → Answer → "What do I see now?" → Next question → ...
```

You formulate a question. You build the cheapest view that answers it. You evaluate the answer. The answer reveals something new — a question you hadn't considered, a gap you couldn't see before ("the adjacent unexplored"). You follow that thread. Each cycle should take minutes, not hours.

### What makes a good question

| Criterion    | Test                                                      |
|--------------|-----------------------------------------------------------|
| **Actionable** | "If I get the answer, what will I do differently?"     |
| **Specific**   | "Is this about THIS system's specific context?"        |
| **Timely**     | "Will the answer still be relevant when I get it?"     |

Bad: "How does this system work?" — not actionable, not specific.
Good: "Which endpoints depend on the auth middleware, and what breaks if we remove it?" — leads to a decision.

### What makes a good answer

| Criterion          | Test                                                      |
|--------------------|-----------------------------------------------------------|
| **Accurate enough** | Precision matches the decision. Don't over-engineer.    |
| **Explainable**     | You can show someone WHY this is the answer, with evidence. |
| **Representative**  | It comes from the actual system, not beliefs about it.  |

A view built from the live codebase is representative by definition. An outdated architecture diagram is not.

### When you don't know what to ask

For hard problems — the ones where you can't even formulate a question:

1. **Describe** what you already know about the system
2. **Identify** what you can't see (visibility gaps)
3. **Build** a small view to make the invisible visible
4. The right question will emerge from what you see

Full detail on the cycle dynamics (time to question, time to answer, the economics of cheap views): `references/question-answer-cycle.md`

---

## How Claude Behaves With This Skill

### Infer context first

Before asking anything, scan for existing moldable work:
- Look for folders with "moldable" in the name (`moldable/`, `moldable-views/`, etc.)
- Check recent commits for view-related work (`git log --oneline | grep -i moldable\|view\|inspect`)
- Look for scripts that smell like views (terminal output, HTML generators, D3/mermaid)

If existing views are found, read their headers to reconstruct the exploration trail. If a view exists but its question/answer context is unclear, ask the user about it.

### Gravity, not gates

The skill never blocks you from building. But it pulls gently toward the methodology:

- **If you arrive wanting to build something** — build it. The view header convention applies (see below), and after the view is built: *"What decision does this help you make? What can you see now that was invisible before?"*
- **If you arrive with a problem** — let's make sure the question is one we can answer. Check it against the three criteria, then build.
- **If you're deep in a cycle** (multiple views, clear exploration trail) — full engagement. Track iterations. Check question quality. Surface the adjacent unexplored proactively.

The joy of building views is real and valuable — it hooks you into the practice. Even if the first few questions are imprecise, the act of building and looking teaches you to ask better questions. Don't let process kill the momentum.

### View conventions (non-negotiable)

**Folder:** All views go in a folder with "moldable" in the name (e.g., `moldable/`, `moldable-views/`). This enables discovery across sessions and by other agents.

**Header:** Every view file starts with this:

```
# Question: <the specific question this view answers>
# Answer:   <[pending] | one-liner summary | [failed — reason]>
# Why:      <what decision this informs>
```

Three lines. Costs nothing. Enables the skill to reconstruct your exploration trail later. Fill in `Answer:` when the view delivers — or mark it `[failed — wrong angle]` when it doesn't. Both are valuable data.

### After every view

A light closing prompt — always curiosity, never homework:

> *"What does this reveal that was invisible before? Any new questions?"*

If the user engages: follow the thread. If they move on: that's fine — the view header is there for later.

---

## Two Independent Axes

The skill is organized around two independent dimensions. Choose your position on each axis based on your current need — they are not coupled.

### Axis 1 — Output Mode (how you SEE it)

| Mode                | You...                                       | When to use                                           | Detail                            |
|---------------------|----------------------------------------------|-------------------------------------------------------|-----------------------------------|
| **Terminal views**  | Read structured output                       | Default. Covers ~80% of needs.                        | `output-modes/terminal-views.md`  |
| **Web views**       | Navigate between linked entities             | When you need clickable entity navigation              | `output-modes/web-views.md`       |
| **Domain playgrounds** | Manipulate live objects, step through logic | When you need to interact with real domain objects     | `output-modes/domain-playgrounds.md` |
| **Live view coding** | Code views in-place, see them render         | When you need interactive prototyping with REPL        | `output-modes/live-view-coding.md` |
| **Desktop app**     | Persistent app with proper windowing         | When views accumulate and need a unified shell         | `output-modes/desktop-app.md`     |
| **Moldable IDE**    | The IDE molds itself around your objects     | Full object inspection, contextual playgrounds, live narratives | `output-modes/moldable-ide/`      |

**Default path:** Start with terminal views. Graduate when you hit a wall: "I need to click through relationships" -> web views. "I need to feed inputs and see outputs" -> domain playgrounds. "I need to inspect live objects with custom views" -> moldable IDE (GT).

### Axis 2 — Analysis Depth (how you ANALYZE it)

| Method             | Gives you                                          | When to use                                    |
|--------------------|----------------------------------------------------|------------------------------------------------|
| **Text patterns**  | grep/awk — fast, fragile, universal                | Quick structural queries, always available      |
| **Syntax-aware**   | tree-sitter — proper AST, no compilation           | When regex breaks on edge cases                 |
| **Full semantic**  | Native compiler — types, DI, overloads             | When you need type resolution or DI graphs      |
| **Live runtime**   | Reflection, DI container, active connections       | When you need runtime state, not just code      |

Any analysis depth can feed ANY output mode. A Roslyn analysis can produce a terminal table. A grep can feed a web view. Choose analysis depth based on accuracy needs, not output mode.

Full detail per level: `analysis-depth/text-patterns.md`, `analysis-depth/syntax-aware.md`, `analysis-depth/native-compiler.md`, `analysis-depth/live-runtime.md`

### Decision Guide

```
Start: Blind spot identified
  │
  ├─ "I need to SEE something" ──────────── Pick output mode
  │    ├─ One-off answer? ─────────────── Terminal views
  │    ├─ Entity relationships? ───────── Web views
  │    ├─ Algorithm/object behavior? ──── Domain playgrounds
  │    ├─ Rapid view iteration? ───────── Live view coding
  │    ├─ Unified shell for many views? ── Desktop app
  │    └─ Live object inspection? ──────── Moldable IDE (GT: output-modes/moldable-ide/glamorous-toolkit/)
  │
  └─ "grep isn't accurate enough" ──────── Increase analysis depth
       ├─ Multiline/nesting issues? ────── tree-sitter
       ├─ Need types/DI/overloads? ────── Native compiler
       └─ Need runtime state? ─────────── Live runtime API
```

---

## Eight Core Principles

These apply at every output mode and analysis depth. One-liner summaries here; full detail in `references/principles-detail.md`.

1. **Start from concrete instances, not abstractions.** Pick *this* controller, not "all controllers."
2. **Think in domain entities, not files.** A Controller depends on a Service, not `file.kt` on `other.kt`.
3. **Wrap your data in domain concepts.** `{"type": "controller", "id": "UserController"}` — not raw JSON blobs.
4. **Navigate between entities.** Each entity leads to the next. Without navigation, you have a dashboard.
5. **Build narratives, not dashboards.** Compose views into stories that walk through a chain of reasoning.
6. **Views, searches, AND actions.** Custom views display, custom searches navigate, custom actions operate.
7. **Simple views first.** A plain table. A one-liner verdict. Elaborate only when there is a clear need.
8. **Low-cost views are not waste.** A 5-minute AI-generated view that saves 30 minutes of exploration has paid for itself.

---

## How to Start

0. **Find your blind spot.** Answer the three questions above. Don't skip this.
1. **Pick one real thing** you wish you could inspect better. Not "everything" — one thing.
2. **Build it as a terminal view.** A script that outputs a table or diagram. This forces you to define the data model.
3. **Live with it.** If it's useful, you've validated the concept. If you hit a wall, you know which axis to graduate on and why.
4. **Graduate deliberately.** Move to web views only for navigation needs. Introduce native analysis only when grep accuracy fails. Consider playgrounds only for interactive object exploration.

---

## Remember: Start From a Question, Not a Tool

This is the Question/Answer Cycle in practice. **Never start with "let me build a dependency graph." Start with:**

- "Can I safely remove this module?"
- "What would break if I changed this interface?"
- "Where is the actual complexity in this system?"
- "Is this service really independent, or coupled through the database?"

The question tells you what to inspect, what entities matter, and what format makes the answer visible. The view is the answer rendered in a form your brain can process.

**Build the view that answers the question. Get your answer. Follow the thread.** If the same question keeps coming back, keep the view. If a new question arises, build a new view. If the answer reveals something unexpected — that's the adjacent unexplored. Go there.

---

## File Map

### Output Modes (read the one you need)

| File                                      | Content                                         |
|-------------------------------------------|-------------------------------------------------|
| `output-modes/terminal-views.md`          | Language candidates, analysis tools, liveness, output formats |
| `output-modes/web-views.md`               | Architecture, server candidates, HTMX/Unpoly, visualization libs |
| `output-modes/domain-playgrounds.md`      | Three flavors, implementation patterns, example objects integration |
| `output-modes/live-view-coding.md`        | Embedded REPL, same-process access, stack examples |
| `output-modes/desktop-app.md`                              | Tauri/Electron/native, when views need a unified shell        |
| `output-modes/moldable-ide/overview.md`                    | What a moldable IDE adds, implementations, future possibility |
| `output-modes/moldable-ide/glamorous-toolkit/setup.md`     | GT detection, installation, validation                        |
| `output-modes/moldable-ide/glamorous-toolkit/iterate.md`   | Generate views, launch GT, iterate on existing views          |
| `output-modes/moldable-ide/glamorous-toolkit/red-flags.md` | Common GT failures and fixes                                  |
| `output-modes/moldable-ide/glamorous-toolkit/codegen/st-generation.md` | Smalltalk code generation rules, view types, data loading |

### Analysis Depth (read the one you need)

| File                                      | Content                                         |
|-------------------------------------------|-------------------------------------------------|
| `analysis-depth/text-patterns.md`         | grep/awk/sed — when to use, limitations         |
| `analysis-depth/syntax-aware.md`          | tree-sitter CLI, bindings, query language        |
| `analysis-depth/native-compiler.md`       | Roslyn, Kotlin Compiler API, go/ast, etc. by stack |
| `analysis-depth/live-runtime.md`          | Reflection, DI containers, actuators, live APIs  |

### References (load on demand)

| File                                      | Content                                         |
|-------------------------------------------|-------------------------------------------------|
| `references/question-answer-cycle.md`     | ttQ/ttA economics, adjacent unexplored, iteration patterns |
| `references/principles-detail.md`         | Eight principles expanded + object-centric vs. file-centric |
| `references/example-objects.md`           | The Example Object pattern with code samples    |
| `references/cross-cutting-concerns.md`    | AI view generation, zoom levels, domain views, inspector chain |
| `references/output-formats.md`            | Format comparison table + recommended flow      |
| `references/live-data.md`                 | Wiring to databases, progressive levels, guardrails |
| `references/liveness.md`                  | Liveness strategies per output mode + analysis depth |
| `references/view-lifecycle.md`            | Disposable exploration vs. durable sensors/harness tools |
| `references/patterns-catalog.md`          | 15 moldable development patterns (in construction) |
| `references/external-sources.md`          | Nierstrasz/Girba paper, GT links, related work  |
