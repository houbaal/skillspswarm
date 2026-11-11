# Tension Resolutions

When Vertical Slicing, ATDD/TDD, and CD Enforcement are used together, they create tensions. The orchestrator resolves them contextually.

**When the orchestrator resolves a tension, it must mention the resolution in its output.** If writing a plan, the trade-off and choice must appear in the plan. Silent resolution is not acceptable — the user must see what was decided and why.

**When the context is ambiguous**, present the tension to the user with trade-offs and let them decide.

---

## Tensions

### T1: Granularity — What is a "Unit of Work"?

| Discipline       | Unit of work        | Typical size         |
|------------------|---------------------|----------------------|
| Vertical Slicer  | Deployment/slice    | 10 min to 2-4 hours |
| CD Enforcer      | Commit              | 10-15 minutes        |
| ATDD/TDD         | TDD inner cycle     | Minutes (R/G/R)      |

**Resolution**: They nest.

```
1 vertical slice = 1 ATDD outer loop
1 ATDD outer loop = N TDD inner cycles
1 TDD inner cycle = 1 commit (GREEN) or 1 refactor commit
1 vertical slice = N commits (typically 8-16 for a 2-4h slice)
```

**Practical mapping for a single slice**:
```
Commit 1:  ATDD test (@pending)                    — Outer loop specification
Commit 2:  First domain concept + unit test         — Inner loop GREEN
Commit 3:  Refactor                                 — Inner loop REFACTOR
...
Commit N-1: Final domain concept + unit test        — Inner loop GREEN
Commit N:   Activate ATDD test                      — Outer loop GREEN
```

---

### T2: Direction of Development

| Discipline       | New code           | Refactoring                       |
|------------------|--------------------|-----------------------------------|
| Vertical Slicer  | Outside-In         | Inside-Out                        |
| ATDD/TDD         | Outside-In (ATDD)  | then Inside (domain TDD)          |
| CD Enforcer      | Not specified       | Expand-and-Contract (any dir)     |

**Resolution**: The double loop reconciles these.

**For new features**:
- **Outer ATDD loop**: Outside-In (matches Vertical Slicer). Start from user-visible behavior.
- **Inner TDD loop**: Domain-first (inside work). Extract entities, value objects, services — build the domain model through TDD.
- **Deployment**: Outside-In with feature flag (UI stub -> API -> DB).

The outer loop determines WHAT to build (outside-in). The inner loop determines HOW to build it (domain-driven). No contradiction — they operate at different levels.

**For refactoring**:
- Direction is Inside-Out (DB -> API -> UI) using Expand-and-Contract.
- The inner TDD loop still drives the implementation of each step.
- ATDD tests validate that the refactoring preserves behavior.

**When ambiguous** (refactoring + new feature at the same time): present both directions to the user with trade-offs. Let them decide which aspect dominates.

---

### T3: Three Definitions of "Value"

| Discipline       | "Value" means                                     |
|------------------|---------------------------------------------------|
| Vertical Slicer  | Usable by a real user ("used tomorrow")           |
| ATDD/TDD         | Behavior specified and tested (even if @pending)  |
| CD Enforcer      | Deployable to production (even if invisible)      |

**Resolution**: These are stages, not alternatives. A slice progresses:

```
Stage 1: SPECIFICATION value — ATDD test written (@pending). Intent documented.
Stage 2: DEPLOYMENT value  — Each TDD commit is deployable. Code exists behind flag.
Stage 3: USER value        — ATDD test GREEN, feature flag ON. Usable by real users.
```

A vertical slice is "done" only at Stage 3. The orchestrator tracks which stage each slice is at, and reports it.

---

### T4: Feature Flags + Test-First = What is the SUT?

**The tension**:
- CD Enforcer + Vertical Slicer: put new code behind a feature flag
- ATDD/TDD: write an acceptance test that validates behavior

Does the ATDD test target **flag ON** or **flag OFF**?

**Resolution**: ATDD tests run with the flag **ON**. CI runs **both** flag states.

```
CI pipeline:
  1. Run all tests with default flags     → verifies production behavior
  2. Run all tests with new flags ON      → verifies new feature behavior
  3. Both must pass                       → both states are deployable
```

The ATDD test validates behavior. The flag controls visibility. These are independently deployable concerns.

**When the CI setup doesn't support dual-flag testing**: present the trade-off to the user. Options: (a) run ATDD tests with flag ON only, accept the risk that flag-OFF behavior is untested; (b) add a separate test for flag-OFF state (typically a no-op assertion).

---

### T5: "Refactoring" Means Three Different Things

| Discipline       | "Refactoring" means                                   |
|------------------|-------------------------------------------------------|
| ATDD/TDD         | Code-level: rename, eliminate duplication, SOLID       |
| Vertical Slicer  | System-level: change architecture, migrate data       |
| CD Enforcer      | Deployment-level: how to ship the change safely       |

**Resolution**: Three levels, clearly named:

| Level        | Scope               | Technique                   | Commit pattern          |
|--------------|---------------------|-----------------------------|-------------------------|
| **Micro**    | Code within a file  | TDD REFACTOR step           | `refactor: [desc]`      |
| **Macro**    | System architecture | Vertical Slicer strategies  | Series of slices        |
| **Delivery** | How to ship safely  | CD techniques catalog       | Expand-Contract commits |

A system-level refactoring (macro) is a series of vertical slices. Each slice uses TDD (with micro-refactoring). Each commit uses CD delivery techniques. The levels compose — they don't compete.

---

### T6: Interactive TDD Pace vs CD Commit Rhythm

**The tension**:
- ATDD Standard Cycle: interactive, human chooses/approves/adjusts at each step
- CD Enforcer: commit every 10-15 minutes

If human discussion takes 30+ minutes per test selection, the commit rhythm breaks.

**Resolution**: The 10-15 minute rhythm applies to **implementation time**, not **negotiation time**. Discussion, review, and decision-making are investment, not waste. The commits should be frequent relative to implementation effort, not wall-clock time.

---

### T7: CD "Technical Anti-Patterns" vs VS "Business Value"

**The tension**:
- CD sees everything through a technical lens: is it deployable? backward-compatible? tested?
- VS sees everything through a business lens: is it usable? does it deliver value? can we get feedback?

An agent using only CD Enforcer can approve a series of perfectly CD-compliant horizontal commits. An agent using only VS can propose a vertical slice that ignores deployment safety.

**Resolution**: The orchestrator combines both perspectives. Every commit must be CD-compliant AND contribute to a vertical slice. CD validates HOW you ship. VS validates WHAT you ship. Neither is sufficient alone.
