# Session Debrief and Virtuous Cycle

## Session Debrief (PROOF)

At the end of each session (or when budget is exhausted), write a debrief
in the report file. Use the PROOF framework from Session-Based Test Management:

| Element       | What to write                                               |
|---------------|-------------------------------------------------------------|
| **P**ast      | What charter was explored? What was the initial plan?       |
| **R**esults   | Bugs found, observations, questions raised                  |
| **O**bstacles | What blocked exploration? (missing data, tool issues, etc.) |
| **O**utlook   | What should be tested next? Propose follow-up charters.     |
| **F**eelings  | Confidence level: how thorough was this session?            |

**Follow-up charters**: every session should produce 0-3 new charter ideas.
These are the seeds for the next session. A session that finds nothing
AND suggests no follow-ups is suspicious — the scope was likely too narrow.

---

## The Virtuous Cycle

**This agent's job ends at the report.** It does NOT write tests or fix bugs.
The report is the handoff artifact — other agents or developers pick it up.

```
                          +---- YOU ARE HERE ----+
                          |                      |
Acceptance scenario -> TDD -> automated check    |  Exploratory testing
       ^                       (regression net)  |  (this agent)
       |                              v          |       |
       +-- New test <- Bug ticket <---+----------+       |
                                                         |
                            Detailed report on disk <----+
                            (= the handoff artifact)
```

**Your deliverable is the report + the handoff checklist.**
The rest of the cycle is someone else's job:
1. A developer or agent reads the report
2. For each bug: writes a failing test BEFORE fixing (test-first discipline)
3. Fixes the bug -> test goes green
4. The regression net grows with real bugs, not theoretical specs

### Why the Handoff Checklist Matters

The **Handoff section is the most important part of the report**.
Without it, the virtuous cycle breaks: bugs are documented but never
converted to automated checks. The handoff must be:

- **Concrete**: each bug maps to a specific test type and stack
- **Actionable**: a developer or agent can pick it up without context
- **Impossible to ignore**: it's the last thing in the report, formatted as a table

### Agile Testing Quadrants Context (Crispin & Gregory)

This agent operates in **Quadrant 3** (business-facing, critique product):

```
         Business-facing
              |
  Q2: BDD    |  Q3: Exploratory    <-- YOU ARE HERE
  ATDD       |  Usability
  Prototypes |  Soap opera
              |
 -------------+------------------
              |
  Q1: TDD    |  Q4: Performance
  Unit tests  |  Security
  Component  |  Load testing
              |
         Technology-facing
```

Each bug found in Q3 feeds back as a new automated check in Q1 or Q2.
