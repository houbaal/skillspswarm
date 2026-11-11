---
description: "Adversarial gap detector — hunts for what's MISSING or WRONG that nobody noticed: ghost code, facade implementations, silent decisions, and blind spots — propose to the user before invoking"
---

# Gap Detector: Adversarial Analysis

You are orchestrating an adversarial gap detection session. Your stance is NOT "how good is this code?" but **"what is probably MISSING or WRONG that nobody noticed?"**

This is specifically designed to catch AI-agent shortcuts: ghost implementations, facade tests, silent architectural decisions made without developer consent, and entire categories of concerns left unaddressed.

## Gap Taxonomy

Every finding MUST be tagged with exactly one of these:

| Tag               | Meaning                                                            | Example                                                         |
|-------------------|--------------------------------------------------------------------|-----------------------------------------------------------------|
| **GHOST**         | Code that pretends to exist but does nothing useful                | Empty catch blocks, stub methods returning hardcoded values     |
| **FACADE**        | Looks correct superficially but has no real substance              | Tests that assert true, validation that accepts everything      |
| **SHORTCUT**      | Simpler than it should be, missing real-world complexity           | No retry logic, no pagination, no rate limiting                 |
| **BLIND SPOT**    | Entire category of concerns not addressed at all                   | No error handling strategy, no security consideration           |
| **SILENT DECISION** | Design choice made by AI without developer awareness             | Framework chosen, pattern selected, dependency added silently   |

## Step 1: Interactive Scope Selection

Ask the user ALL questions in a SINGLE AskUserQuestion call:

**Q1 — Scope** (singleSelect):
- **Whole project** — Full adversarial scan of the codebase
- **Today's commits** — Focus on changes made today
- **Specific area** — Feature, module, or subject described by the user

**Q2 — Depth** (singleSelect):
- **Quick scan** — Fast surface detection, Haiku agents (~2 min)
- **Standard** — Thorough adversarial analysis, Sonnet agents (~5 min)
- **Deep dive** — Exhaustive interrogation, Opus agents (~10 min)

## Step 2: Resolve Scope and Report Directory

Based on Q1 answer, determine the scope context AND report directory name:

- **Whole project**: Set SCOPE_CONTEXT to "Scan the entire project codebase at: <project root path>. Leave no stone unturned." Set REPORT_DIR to `ai/analysis/YYYY-MM-DD-gap-full` (today's date).
- **Today's commits**: Run `git log --since="today 00:00" --name-only --pretty=format:""` to get the file list. Also run `git log --since="today 00:00" --pretty=format:"%h %s"` to get commit messages. Set SCOPE_CONTEXT to "Focus on these files changed today: <file list>. Commit messages: <commit messages>. Interrogate whether these changes are complete and honest." Set REPORT_DIR to `ai/analysis/YYYY-MM-DD-gap-daily`.
- **Specific area**: Use {PROMPT} if provided, otherwise use the user's "Other" text. Set SCOPE_CONTEXT to "Focus on code related to: <subject description>. Search the codebase to find all relevant files. Question every assumption." Set REPORT_DIR to `ai/analysis/YYYY-MM-DD-gap-<subject-slug>` (slugified subject, e.g. `2026-02-24-gap-auth-module`).

If REPORT_DIR already exists (e.g. second review same day), append a suffix: `-2`, `-3`, etc.

## Step 3: Map Depth to Model

- **Quick scan**: model=haiku, max_turns=10
- **Standard**: model=sonnet, max_turns=20
- **Deep dive**: model=opus, max_turns=30

## Step 4: Dispatch 3 Parallel Adversarial Agents

1. Create output directory: `mkdir -p <REPORT_DIR>` (the `ai/analysis/...` path resolved in Step 2)
2. Dispatch ALL 3 agents in a **SINGLE message** (3 Task tool calls) with `run_in_background=true`.
3. Tell the user: "Dispatching 3 adversarial agents in parallel..."

### Agent 1: Implementation Gap Scanner

**subagent_type**: `code-smell-detector`
**max_turns**: Use value from Step 3
**model**: Use value from Step 3
**output**: `<REPORT_DIR>/gap-detector-implementation.md`

Prompt:
```
You are an ADVERSARIAL code reviewer. Your job is NOT to praise — it is to find what's MISSING, FAKE, or INCOMPLETE.

## Your Mission

Hunt for implementation gaps using this taxonomy. Tag EVERY finding:
- **GHOST**: Code that pretends to exist but does nothing (empty methods, stub returns, TODO comments hiding missing logic)
- **FACADE**: Looks correct but has no substance (validation that validates nothing, error handling that swallows everything)
- **SHORTCUT**: Too simple for real-world use (no edge cases, no concurrency, no error recovery, hardcoded values)

## Methodology

1. Read `${CLAUDE_PLUGIN_ROOT}/skills/vendors/CAPABILITIES.md` to discover available resources.
   If missing, generate it: `bash ${CLAUDE_PLUGIN_ROOT}/skills/vendors/generate.sh`
   Focus on skills related to: clean code, cross-cutting concerns, skeptical review.
   Pick 2-4 relevant resources and read them with the Read tool.
2. Scan the codebase within scope
3. For each file, ask yourself: "If I were a malicious AI trying to look productive, what would I skip?"
4. Check for: empty implementations behind interfaces, hardcoded happy-path returns, missing null/error checks, TODO/FIXME comments hiding real gaps, configuration that's never actually read, feature flags that are always on/off

## Scope

<SCOPE_CONTEXT>

## Report Format (MANDATORY)

Create the report directory if needed (mkdir -p <REPORT_DIR>), then write this EXACT format to <REPORT_DIR>/gap-detector-implementation.md:

# Gap Detector: Implementation Gaps

**Scope**: <scope description>
**Date**: <today's date>
**Stance**: Adversarial — hunting for what's missing, not what's good

## Findings

For each finding, use this format:

### [TAG] Title
- **File**: file:line
- **What it looks like**: <what a quick review would see>
- **What's actually wrong**: <the real gap>
- **Surprise factor**: Low / Medium / High (would the developer expect this?)
- **Impact**: What breaks or fails because of this gap

## Ghost Code Inventory
<List all methods/classes that exist but do effectively nothing>

## Summary
- Total findings: N
- GHOST: N | FACADE: N | SHORTCUT: N
- Highest surprise factor items: <list top 3>

IMPORTANT: You MUST write the report file using the Write tool. Do not just output to chat.
```

### Agent 2: Test Gap Scanner

**subagent_type**: `test-design-reviewer`
**max_turns**: Use value from Step 3
**model**: Use value from Step 3
**output**: `<REPORT_DIR>/gap-detector-tests.md`

Prompt:
```
You are an ADVERSARIAL test reviewer. Your job is to find tests that CREATE FALSE CONFIDENCE — tests that pass but prove nothing.

## Your Mission

Hunt for test gaps using this taxonomy. Tag EVERY finding:
- **GHOST**: Tests that exist but verify nothing (no meaningful assertions, testing framework plumbing not behavior)
- **FACADE**: Tests that look thorough but miss the point (asserting implementation details, not behavior; high coverage of trivial code)
- **SHORTCUT**: Tests missing real-world scenarios (no error paths, no edge cases, no concurrency tests, no integration tests where needed)
- **BLIND SPOT**: Entire categories of testing absent (no security tests, no performance tests, no boundary tests, no negative tests)

## Methodology

1. Read `${CLAUDE_PLUGIN_ROOT}/skills/vendors/CAPABILITIES.md` to discover available resources.
   If missing, generate it: `bash ${CLAUDE_PLUGIN_ROOT}/skills/vendors/generate.sh`
   Focus on skills related to: test quality, test design, acceptance testing, BDD.
   Pick 2-4 relevant resources and read them with the Read tool.
2. Scan all test files in scope
3. For each test, ask: "If I deleted the implementation and replaced it with a hardcoded return value, would this test still pass?"
4. Check for: tests with no assertions, tests asserting only happy path, tests mocking so much they test nothing, tests coupled to implementation, missing error path coverage, no boundary value testing

## Scope

<SCOPE_CONTEXT>

## Report Format (MANDATORY)

Create the report directory if needed (mkdir -p <REPORT_DIR>), then write this EXACT format to <REPORT_DIR>/gap-detector-tests.md:

# Gap Detector: Test Gaps

**Scope**: <scope description>
**Date**: <today's date>
**Stance**: Adversarial — hunting for false confidence, not test count

## Findings

For each finding:

### [TAG] Title
- **File**: file:line
- **What the test claims to verify**: <test name / description>
- **What it actually verifies**: <the real coverage>
- **The gap**: <what would break in production that this test wouldn't catch>
- **Surprise factor**: Low / Medium / High

## Missing Test Categories
<List entire categories of tests that should exist but don't>

## False Confidence Score
Rate 1-10: How much false confidence do the current tests create?
(10 = tests pass but code is fundamentally broken, 1 = tests accurately reflect code quality)

## Summary
- Total findings: N
- GHOST: N | FACADE: N | SHORTCUT: N | BLIND SPOT: N
- False confidence score: X/10

IMPORTANT: You MUST write the report file using the Write tool. Do not just output to chat.
```

### Agent 3: Decision Audit

**subagent_type**: `general-purpose`
**max_turns**: Use value from Step 3
**model**: Use value from Step 3
**output**: `<REPORT_DIR>/gap-detector-decisions.md`

Prompt:
```
You are a DECISION AUDITOR. Your job is to find design choices that were made WITHOUT the developer's explicit awareness or consent — especially those made by AI agents.

## Your Mission

Hunt for silent decisions and blind spots. Tag EVERY finding:
- **SILENT DECISION**: A design choice made without developer awareness (framework selection, pattern choice, dependency added, architecture decision not discussed)
- **BLIND SPOT**: An entire category of concerns that nobody addressed (security strategy, error handling philosophy, deployment considerations, data migration)

## Methodology

1. Read `${CLAUDE_PLUGIN_ROOT}/skills/vendors/CAPABILITIES.md` to discover available resources.
   If missing, generate it: `bash ${CLAUDE_PLUGIN_ROOT}/skills/vendors/generate.sh`
   Focus on skills related to: critical analysis, awareness, blind spot detection.
   Pick 2-4 relevant resources and read them with the Read tool.
2. Examine git history for patterns: Run `git log --oneline -30` and `git log --all --oneline -30` to see recent history
3. Check for plan files: Look in `ai/plans/` for what was planned vs what was implemented
4. Scan the codebase for:
   - Dependencies added without justification in commit messages
   - Architectural patterns that appeared without discussion (singleton, service locator, event bus)
   - Configuration files with non-obvious settings
   - .env or config defaults that imply decisions (database choice, cache strategy, auth method)
   - Error handling strategies that were chosen implicitly
   - Naming conventions that imply domain modeling decisions

## Scope

<SCOPE_CONTEXT>

## Key Questions to Answer

For each silent decision found, determine:
1. WHO made this decision? (human or AI agent?)
2. WHEN was it made? (which commit?)
3. Was there ANY discussion or documentation?
4. What ALTERNATIVES existed?
5. What are the CONSEQUENCES the developer might not know about?

## Report Format (MANDATORY)

Create the report directory if needed (mkdir -p <REPORT_DIR>), then write this EXACT format to <REPORT_DIR>/gap-detector-decisions.md:

# Gap Detector: Decision Audit

**Scope**: <scope description>
**Date**: <today's date>
**Stance**: Adversarial — hunting for decisions made without developer consent

## Findings

For each finding:

### [TAG] Title
- **What was decided**: <the decision>
- **Evidence**: <commit hash, file, config entry>
- **Who decided**: Human / AI Agent / Unknown
- **Was it discussed?**: Yes (link) / No evidence found
- **Alternatives not considered**: <what else could have been chosen>
- **Consequences**: <what the developer should know>
- **Surprise factor**: Low / Medium / High

## Blind Spot Inventory
<List entire categories of concerns that have ZERO coverage in the codebase>
For each: What's the risk? What could go wrong?

## Summary
- Total findings: N
- SILENT DECISION: N | BLIND SPOT: N
- Decisions with no documentation: N
- Highest surprise factor items: <list top 3>

IMPORTANT: You MUST write the report file using the Write tool. Do not just output to chat.
```

## Step 5: Wait and Collect

Wait for all 3 background agents to complete using TaskOutput. As each finishes, briefly note its completion:
- "Implementation gap scanner done."
- "Test gap scanner done."
- "Decision audit done."

## Step 6: Synthesize

Once ALL 3 agents are done, dispatch ONE final agent (model=sonnet, max_turns=15, subagent_type="general-purpose") with this prompt:

```
You are synthesizing the results of an adversarial gap detection session. Your job is to produce a SHARP, POINTED summary that will surprise the developer with what they didn't know.

## Instructions

1. Read all gap detector reports in <REPORT_DIR>/:
   - <REPORT_DIR>/gap-detector-implementation.md
   - <REPORT_DIR>/gap-detector-tests.md
   - <REPORT_DIR>/gap-detector-decisions.md
2. Cross-reference findings across all 3 reports
3. Write the synthesis to <REPORT_DIR>/gap-detector-synthesis.md

## Synthesis Format (MANDATORY)

# Gap Detector: Synthesis

**Date**: <today's date>
**Scope**: <scope description>

## Overview

| Agent                        | Gaps Found | Critical | Surprise Factor |
|------------------------------|------------|----------|-----------------|
| Implementation Gap Scanner   | N          | N        | Low/Med/High    |
| Test Gap Scanner             | N          | N        | Low/Med/High    |
| Decision Audit               | N          | N        | Low/Med/High    |

## Gap Taxonomy Distribution

| Tag               | Count | % of Total |
|-------------------|-------|------------|
| GHOST             | N     | X%         |
| FACADE            | N     | X%         |
| SHORTCUT          | N     | X%         |
| BLIND SPOT        | N     | X%         |
| SILENT DECISION   | N     | X%         |

## Top Questions for the Developer

These are ranked by surprise factor. The developer probably doesn't know about these:

1. **Did you know?** <pointed question about highest-surprise finding>
   - Evidence: <file:line or commit>
   - Tag: <taxonomy tag>
   - Why it matters: <consequence>

2. **Did you know?** <next finding>
   ...

(List up to 10 questions, ranked by surprise factor)

## Prioritized Action Plan

### Immediate (fix before next commit)
- <list items>

### This Sprint
- <list items>

### Backlog
- <list items>

## Detailed Reports

- [Implementation Gaps](./gap-detector-implementation.md)
- [Test Gaps](./gap-detector-tests.md)
- [Decision Audit](./gap-detector-decisions.md)

IMPORTANT: You MUST write the synthesis file using the Write tool.
```

## Step 7: Present Results

Read `<REPORT_DIR>/gap-detector-synthesis.md` and present it to the user:

1. Show the **Overview table**
2. Show the **Gap Taxonomy Distribution**
3. Show the **Top Questions for the Developer** (this is the most important part — make these questions conversational and pointed)
4. Show the **Prioritized Action Plan**
5. List report file paths for deeper reading

Then:
- **Propose to commit** the analysis reports: `git add <REPORT_DIR> && git commit -m "analysis: gap-detector <scope> <date>"` — these reports serve as reference for future comparisons and team visibility
- Propose next steps:
  - "Want me to dig deeper into any of these gaps?"
  - "Should I create a moldable view to track these gaps? (`/progressive-moldable-dev-env`)"
  - "Want to fix the immediate items now?"
