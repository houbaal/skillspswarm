---
description: Use when delivering a feature from story to production and vertical slicing + TDD + CD practices need to work together. Also use when facing tension between a RED ATDD test and the deployability rule, when unsure how slices map to commits, when outside-in clashes with domain-first TDD, or when a migration has multiple consumers. Trigger on "full delivery workflow", "end-to-end incremental", or any session combining 2+ of these three disciplines. — propose to the user before invoking
---

# Incremental Delivery

Orchestrates three disciplines into one coherent workflow:

```
Vertical Slicing   →  WHAT to build, how to scope
ATDD/TDD           →  HOW to build it, test-first
CD Enforcement     →  HOW to ship it, every commit deployable
```

These are not sequential phases — they are **cross-cutting**. While building (ATDD), you re-slice (VS) and validate CD compliance (CD). The three disciplines reinforce each other: slicing produces the right-sized units, TDD ensures each unit is correct, CD ensures each unit ships safely.

**Reference files** (read on demand, not upfront):
- `references/foundations.md` — Read when you need to ground a decision in shared principles (e.g., "is this commit deployable?" or "is this batch small enough?")
- `references/tensions.md` — Read when the three disciplines give conflicting guidance (e.g., "can I commit a RED ATDD test?")
- `references/cd-techniques.md` — Read when selecting a delivery technique for a specific change (e.g., schema migration, feature flag, strangler fig)

---

## Mode: Planning

Use when starting a new feature or epic. Goal: a set of vertical slices, each with ATDD scenarios and a CD technique selected.

### Steps

The order matters — each step depends on the previous one's output.

1. **Slice the feature** — Use the Skill tool to invoke `devopscraft:vertical-slices`
   - Break into deployable vertical slices (10 min to 2-4h each)
   - Each slice answers: "What can we do today that can be used tomorrow?"
   - **Why first**: Slicing defines the units of work. Without slices, you don't know what to write ATDD tests for.

2. **Specify each slice** — Use the Skill tool to invoke `devopscraft:atdd-tdd-double-loop`, focus on R1-R3
   - R1: Reformulate in business terms, list business rules
   - R2: Write at least one ATDD scenario per slice (Gherkin philosophy)
   - R3: Identify domain concepts (entities, value objects, services)
   - **Why second**: ATDD scenarios define acceptance criteria per slice. Without them, you can't choose the right CD technique.

3. **Select CD technique per slice** — Read `references/cd-techniques.md`
   - New feature? Feature Flag + Outside-In deployment
   - Refactoring? Expand-and-Contract + Inside-Out deployment
   - **Why third**: The technique depends on what you're building (from step 1) and what "done" looks like (from step 2).

4. **Resolve tensions upfront** — Read `references/tensions.md`
   - Decide now: RED ATDD commits use `@pending` markers (Tension 1)
   - Agree on: 1 slice = 1 ATDD outer loop = N commits (Tension 2)
   - Set up CI: ATDD tests run with flag ON; CI tests both states (Tension 5)
   - **Why last**: Tension resolution needs context from all three steps above.

### Planning output

Per slice:
- Business rules and ATDD scenarios (from steps 1-2)
- Domain concepts (from step 2, R3)
- CD technique and deployment direction (from step 3)
- Estimated commits (typically 8-16 per 2-4h slice)

---

## Mode: Execution

Use when implementing a planned slice. Goal: deliver the slice through the TDD double loop with CD compliance on every commit.

### Per-Slice Cycle

Each commit is a deployable unit. The outer ATDD loop frames the slice; the inner TDD loop builds it piece by piece.

```
1. Commit ATDD test (@pending)           → Outer loop RED (deployable via @skip)
2. For each domain concept:
   a. Write unit test                    → Inner loop RED
   b. Write minimum code                 → Inner loop GREEN
   c. Run all tests                      → Verify nothing broke
   d. Refactor                           → Inner loop REFACTOR
   e. Commit (code + test)              → CD-compliant: deployable, tested, backward-compat
3. Activate ATDD test                    → Outer loop GREEN
4. Final refactor + commit               → Slice complete, push
```

### How to invoke disciplines during execution

- **TDD cycle** (steps 2a-2e): Use the Skill tool to invoke `devopscraft:atdd-tdd-double-loop` — it drives R4-R8 (the inner loop). The skill enforces Red/Green/Refactor rhythm and prevents test-after development.
- **CD compliance** (every commit): Use the Skill tool to invoke `devopscraft:cd-enforcer` when in doubt about a commit's deployability. It catches: missing tests, backward-compat violations, commits requiring deployment coordination.
- **Drift detection** (ongoing): If you notice technical-layer splits creeping in ("let me do the DB first, then the API"), that's horizontal drift. Revisit `devopscraft:vertical-slices` detection patterns.

---

## Key Tension Resolutions (Summary)

These come from `references/tensions.md` — consult the full document for details.

| Tension                          | Resolution                                                    |
|----------------------------------|---------------------------------------------------------------|
| RED ATDD + deployability         | `@pending` marker — CI stays green, test documents intent     |
| Slice vs commit granularity      | 1 slice = 1 outer loop = N commits (8-16 typical)            |
| Outside-In vs domain TDD         | Outer loop: outside-in. Inner loop: domain-first. No conflict.|
| Three definitions of "value"     | Spec value -> deployment value -> user value (stages)         |
| Feature flag + test target       | ATDD tests run flag ON; CI tests both states                  |
| "Refactoring" = 3 things         | Micro (TDD), macro (architecture), delivery (CD techniques)   |

---

## When to Use Each Skill Standalone

This orchestrator is for the **full workflow**. Each skill remains independently useful:

| Need                                          | Use                              |
|-----------------------------------------------|----------------------------------|
| Full feature planning + execution             | This skill (incremental-delivery)|
| Just validate commit/deployment practices     | devopscraft:cd-enforcer          |
| Just split a story into slices                | devopscraft:vertical-slices      |
| Just enforce TDD discipline on implementation | devopscraft:atdd-tdd-double-loop |
