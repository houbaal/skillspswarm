---
description: "Multi-angle parallel code review — launches several review agents simultaneously, each analyzing code from a different dimension — propose to the user before invoking"
---

# Mega-Review: Multi-Angle Parallel Code Review

You are orchestrating a multi-dimensional code review. Follow these steps precisely.

## Step 1: Interactive Menu

Ask the user ALL 4 questions in a SINGLE AskUserQuestion call:

**Q1 — Internal dimensions** (multiSelect):
- **Craft** — Clean code, naming, complexity, code smells, magic numbers, dead code
- **Architecture** — Coupling, cohesion, boundaries, DDD, separation of concerns, circular dependencies
- **Tests** — Test quality (Farley properties), coverage, assertions, mocks, edge cases
- **Cognitive Load** — Readability, mixed abstraction levels, nesting depth, cyclomatic complexity

**Q2 — Cross-cutting dimensions** (multiSelect):
- **Security** — OWASP top 10, input validation, injection, secrets in code, vulnerable dependencies
- **Performance** — N+1, algorithmic complexity, unnecessary allocations, missing caching, blocking I/O
- **Observability** — Error handling (swallowed exceptions?), structured logging, metrics, tracing, failure visibility
- **Maintainability** — Technical debt, missing documentation, temporal coupling, breaking change risk, bus factor

**Q3 — Scope** (singleSelect):
- **Whole project** — Full codebase scan
- **Today's commits** — Only today's changes
- **Specific subject** — Feature or subject described by the user

**Q4 — Depth** (singleSelect):
- **Quick** — Surface scan, Haiku agents
- **Standard** — Thorough analysis, Sonnet agents
- **Deep** — Exhaustive review, Opus agents

## Step 2: Resolve Scope and Report Directory

Based on Q3 answer, determine the scope context AND report directory name:

- **Whole project**: Set SCOPE_CONTEXT to "Analyze the entire project codebase at: <project root path>". Set REPORT_DIR to `ai/analysis/YYYY-MM-DD-full-review` (today's date).
- **Today's commits**: Run `git log --since="today 00:00" --name-only --pretty=format:""` to get file list. Set SCOPE_CONTEXT to "Focus your analysis on these files changed today: <file list>". Set REPORT_DIR to `ai/analysis/YYYY-MM-DD-daily-review`.
- **Specific subject**: Use {PROMPT} if provided, otherwise use the user's "Other" text. Set SCOPE_CONTEXT to "Focus your analysis on code related to: <subject description>. Search the codebase to find relevant files." Set REPORT_DIR to `ai/analysis/YYYY-MM-DD-<subject-slug>` (slugified subject, e.g. `2026-02-24-auth-module`).

If REPORT_DIR already exists (e.g. second review same day), append a suffix: `-2`, `-3`, etc.

## Step 3: Map Depth to Model

- **Quick**: model=haiku, max_turns=10
- **Standard**: model=sonnet, max_turns=20
- **Deep**: model=opus, max_turns=30

## Step 4: Prepare and Dispatch

1. Create output directory: `mkdir -p <REPORT_DIR>` (the `ai/analysis/...` path resolved in Step 2)
2. For each selected dimension, dispatch a Task agent with `run_in_background=true`.
3. **CRITICAL**: Dispatch ALL agents in a SINGLE message (multiple Task tool calls) for true parallelism.
4. Use the `subagent_type` from the mapping below. Use `general-purpose` only when no specialized agent exists.
5. Tell the user how many agents were dispatched and which dimensions.

### Dimension → subagent_type mapping

| Dimension       | subagent_type           |
|-----------------|-------------------------|
| Craft           | `code-smell-detector`   |
| Architecture    | `ddd-architect`         |
| Tests           | `test-design-reviewer`  |
| Cognitive Load  | `cognitive-load-analyzer` |
| Security        | `general-purpose`       |
| Performance     | `general-purpose`       |
| Observability   | `general-purpose`       |
| Maintainability | `refactoring-expert`    |

### Agent Prompt Template

For EACH selected dimension, use this prompt (replacing <DIMENSION>, <DIMENSION_KEY>, and <SCOPE_CONTEXT>):

```
You are a code reviewer specialized in the **<DIMENSION>** dimension.

## Your mission

1. Scan the codebase within the given scope
2. Consult the REVIEW RESOURCE TABLE below to find relevant methodologies for your dimension
3. Read the knowledge/skill files that are most relevant to what you observe in the code
4. Apply those methodologies to produce your analysis
5. Write your report to <REPORT_DIR>/mega-review-<DIMENSION_KEY>.md

## Scope

<SCOPE_CONTEXT>

## REVIEW RESOURCE TABLE

Read the capabilities catalog to discover available review resources:

1. Read `${CLAUDE_PLUGIN_ROOT}/skills/vendors/CAPABILITIES.md`
2. If the file does not exist, generate it: `bash ${CLAUDE_PLUGIN_ROOT}/skills/vendors/generate.sh`
3. Then read the generated file

The catalog lists all locally available:
- **Skills** — knowledge files you can Read for review methodologies
- **Agents** — subagent_types you can dispatch via Agent tool for deeper analysis

## How to use the catalog

1. Scan the code in scope first to understand what you're dealing with
2. Read CAPABILITIES.md and pick 2-4 resources that are MOST relevant to your dimension AND what you see in the code
3. Read those skill/knowledge files using the Read tool (do NOT use @ references)
4. Apply their methodologies to produce your findings
5. If reviewer agents are listed in the catalog and a sub-topic needs deeper analysis, consider dispatching one via Agent tool

## Report Format (MANDATORY)

Create the report directory if needed (mkdir -p <REPORT_DIR>), then write this EXACT format to <REPORT_DIR>/mega-review-<DIMENSION_KEY>.md:

# Mega-Review: <DIMENSION>

**Scope**: <scope description>
**Date**: <today's date and time>
**Resources used**: <list which knowledge files/skills you read and applied>

## Summary
<1-3 sentences summarizing your findings>

## Findings

### Critical (blocking)
<List each critical issue with: **[file:line]** description, impact, suggestion>
<Write "None found." if no critical issues>

### Important
<List each important issue with: **[file:line]** description, suggestion>
<Write "None found." if no important issues>

### Suggestions
<List each suggestion with: **[file:line]** description>
<Write "None found." if no suggestions>

## Score: X/10

IMPORTANT: You MUST write the report file using the Write tool. Do not just output to chat.
```

## Step 5: Wait and Collect

Wait for all background agents to complete using TaskOutput. As each finishes, briefly note its completion to the user.

## Step 6: Synthesize

Once ALL agents are done, dispatch ONE final agent (Haiku, max_turns=10, subagent_type="general-purpose") with this prompt:

```
Read all mega-review report files in <REPORT_DIR>/mega-review-*.md
Use the Glob tool to find them: Glob(pattern="<REPORT_DIR>/mega-review-*.md")
Then read each file.

Produce a consolidated synthesis and write it to <REPORT_DIR>/mega-review-synthesis.md with this format:

# Mega-Review: Synthesis

**Date**: <today's date and time>
**Dimensions**: <list of dimensions analyzed>
**Scope**: <scope description>
**Profondeur**: <rapide|standard|deep>

## Overview

| Dimension          | Score | Critical | Important | Suggestions |
|--------------------|-------|----------|-----------|-------------|
| <for each dim>     | X/10  | N        | N         | N           |

## Top 5 Priority Actions

1. **[Critical]** <description> — <file:line> (dimension: <name>)
2. ...
(if fewer than 5 findings total, list all of them)

## Detailed Reports

- [<Dimension>](./mega-review-<key>.md)
- ...

IMPORTANT: You MUST write the synthesis file using the Write tool.
```

## Step 7: Present Results

Read `<REPORT_DIR>/mega-review-synthesis.md` and present the synthesis to the user:
- Show the overview table
- Show the top 5 priority actions
- List the report file paths for deeper reading
- **Propose to commit** the analysis reports: `git add <REPORT_DIR> && git commit -m "analysis: mega-review <scope> <date>"` — these reports serve as reference for future comparisons and team visibility
- Propose next steps (fix criticals first? run /mega-review again after fixes?)
