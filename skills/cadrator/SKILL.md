---
description: "Preventive requirement framing — surfaces implicit assumptions, unspoken constraints, and decisions the AI would make by default, BEFORE implementation starts — propose to the user before invoking"
---

# Cadrator: Preventive Requirement Framing

You are orchestrating a **preventive cadrage session**. Your stance is NOT "is this code good?" but **"what will go wrong if we start implementing NOW with what we know?"**

This tool exists because AI agents make erroneous presuppositions when requirements are under-specified: wrong patterns, wrong architectural style, wrong data schemas, wrong quality bar. The developer discovers the mismatch too late, and it's rework.

**The cadrator intervenes BEFORE implementation** to make every implicit decision explicit.

## The 7 Cadrage Axes

Every finding MUST be tagged with exactly one of these:

| Tag                      | What it surfaces                                                              | Example                                                              |
|--------------------------|-------------------------------------------------------------------------------|----------------------------------------------------------------------|
| **INTENTION**            | The real goal behind the request — what does success look like?               | "Add caching" — for latency? cost? offline support?                  |
| **SCOPE**                | What's in, what's out — where does this feature start and stop?              | "Add auth" — just login? roles? OAuth? session management?           |
| **IMPLICIT_DECISION**    | A choice the AI will make by default if the dev says nothing                  | "I'll use a class-based pattern" when the codebase is functional     |
| **CONSTRAINT**           | A technical/quality/convention requirement that's unspoken but expected       | No mention of error handling strategy, test expectations, conventions |
| **DATA_SHAPE**           | Data structures, integration points, formats, contracts left undefined        | API response format, DB schema relations, event payload structure    |
| **UNASKED_QUESTION**     | A question whose answer would change the implementation significantly        | "Should this be idempotent?" "Is this paginated?" "Sync or async?"  |
| **ASSUMED_CONTEXT**      | Technical or business context the dev has in mind but hasn't shared           | Existing conventions, domain rules, deployment target, team norms    |

## Step 1: Determine Subject

The subject to analyze is determined in this order:

1. **{PROMPT}** — if the user provided a description with the command, use it
2. **Current task in session** — if there's an ongoing discussion about a feature/task, use that context
3. **Most recent plan** — look in `ai/plans/todo/` for the most recently modified plan file and use it

If none of these yield a clear subject, ask the user:

> "Qu'est-ce qu'on cadre ? Decris-moi la tache ou la feature en 2-3 phrases."

## Step 2: Depth Selection

Ask the user in a SINGLE AskUserQuestion call:

**Q1 — Depth** (singleSelect):
- **Quick** — Fast scan, 5-7 top questions (~2 min)
- **Standard** — Multi-angle analysis, 3 parallel agents (~5 min)
- **Deep** — Exhaustive interrogation, 3 parallel Opus agents (~10 min)

## Step 3: Gather Context

Before any analysis, gather the raw material:

1. **Read the subject** (plan file, or summarize from conversation)
2. **Scan relevant code areas** — if the subject references existing code, read those files to understand current conventions, patterns, and data structures
3. **Check git log** — `git log --oneline -10` to see recent direction
4. **Check existing plans** — `ls ai/plans/todo/` for related plans

Compile this into a CONTEXT_SUMMARY (max 500 words) that any agent can use.

## Step 4: Analysis

### Quick Depth (inline, no subagents)

Perform the analysis yourself. Read the following knowledge files for methodology:

- Read `${CLAUDE_PLUGIN_ROOT}/skills/vendors/CAPABILITIES.md` to discover available resources.
  If missing, generate it: `bash ${CLAUDE_PLUGIN_ROOT}/skills/vendors/generate.sh`
  Focus on skills related to: skeptical review, blind spot detection, awareness.

Then, for each of the 7 axes, ask yourself:
- **INTENTION**: What is the real goal? What does "done" look like? Could two people read this and aim for different outcomes?
- **SCOPE**: Where does this feature start and stop? What could be interpreted as in-scope or out-of-scope?
- **IMPLICIT_DECISION**: If I were implementing this right now, what choices would I make that the dev hasn't validated?
- **CONSTRAINT**: What quality/architecture/convention expectations are unspoken? What does the dev probably expect but didn't say?
- **DATA_SHAPE**: What data structures, API contracts, schemas, or integration formats are left undefined?
- **UNASKED_QUESTION**: What single question, if answered differently, would lead to a fundamentally different implementation?
- **ASSUMED_CONTEXT**: What technical or business context does the dev have in mind but hasn't shared?

Produce **5-7 findings** ranked by **risk of wrong assumption** (high = the AI is very likely to guess wrong, and the cost of guessing wrong is high).

Skip to **Step 5**.

### Standard / Deep Depth (3 parallel agents)

Map depth to model:
- **Standard**: model=sonnet, max_turns=15
- **Deep**: model=opus, max_turns=25

Create output directory: `mkdir -p ./tmp/cadrage`

Dispatch ALL 3 agents in a **SINGLE message** with `run_in_background=true`.

#### Agent 1: Assumption Miner

**subagent_type**: `problem-analyst`

Prompt:
```
You are an ASSUMPTION MINER. Your job is to find decisions that an AI agent would make BY DEFAULT if the developer says nothing — and flag them BEFORE implementation.

## Your Mission

For the subject described below, identify:

1. **IMPLICIT_DECISION**: Concrete implementation choices the AI will make without asking. For each one:
   - What the AI would choose by default
   - What alternatives exist
   - Why the default might be wrong for THIS context
   - The cost of discovering the wrong choice after implementation

2. **ASSUMED_CONTEXT**: Things the developer probably knows but hasn't shared that would change the implementation. For each one:
   - What context is missing
   - How it would change the approach
   - A question to surface it

## Methodology

Read `${CLAUDE_PLUGIN_ROOT}/skills/vendors/CAPABILITIES.md` to discover available resources.
If missing, generate it: `bash ${CLAUDE_PLUGIN_ROOT}/skills/vendors/generate.sh`
Focus on skills related to: skeptical review, blind spot detection, awareness.
Pick 2-4 relevant resources and read them with the Read tool.

Think about: patterns, naming conventions, data structures, error handling style, test expectations, architectural layers, dependency choices, API contracts, state management.

## Subject

<SUBJECT_DESCRIPTION>

## Codebase Context

<CONTEXT_SUMMARY>

## Output Format (MANDATORY)

Write to ./tmp/cadrage/assumptions.md:

# Cadrage: Assumptions & Implicit Decisions

## IMPLICIT_DECISION findings

### [IMPLICIT_DECISION] Title
- **What the AI would default to**: <concrete choice>
- **Alternatives**: <other valid approaches>
- **Risk of wrong guess**: Low / Medium / High
- **Cost if wrong**: <rework description>
- **Question to ask**: <one sharp question>

## ASSUMED_CONTEXT findings

### [ASSUMED_CONTEXT] Title
- **Missing context**: <what's not said>
- **Impact on implementation**: <how it changes things>
- **Question to ask**: <one sharp question>

IMPORTANT: Write the file using the Write tool.
```

#### Agent 2: Scope & Intent Analyst

**subagent_type**: `general-purpose`

Prompt:
```
You are a SCOPE & INTENT ANALYST. Your job is to find where the intention is ambiguous, where the boundaries of a request are unclear, and what questions would fork the implementation.

## Your Mission

For the subject described below, identify:

1. **INTENTION**: Where the real goal is unclear or could be misread. For each one:
   - What the stated goal seems to be
   - What the REAL goal might be (the "why behind the what")
   - How misreading the intention changes the implementation
   - A question to clarify

2. **SCOPE**: Places where the scope is unclear. For each one:
   - What could be interpreted as in-scope or out-of-scope
   - The two most likely interpretations
   - Which interpretation the AI would probably pick
   - Why it matters (cost of picking wrong)

3. **UNASKED_QUESTION**: Questions whose answer would significantly change the implementation. For each one:
   - The question itself
   - The 2-3 possible answers
   - How each answer leads to a different implementation path
   - The default the AI would assume

## Methodology

Think like a product owner receiving this spec. Ask yourself:
- What does "done" look like? Is that clear?
- If I gave this to 3 different senior developers, would they build the same thing?
- What user scenarios are implied but not described?
- What error/edge cases are not mentioned?
- What integration points are hand-waved?

## Subject

<SUBJECT_DESCRIPTION>

## Codebase Context

<CONTEXT_SUMMARY>

## Output Format (MANDATORY)

Write to ./tmp/cadrage/scope.md:

# Cadrage: Scope & Intent Analysis

## INTENTION findings

### [INTENTION] Title
- **Stated goal**: <what the request says>
- **Possible real goal**: <the why behind the what>
- **Misread risk**: <how wrong interpretation changes implementation>
- **Question to ask**: <one sharp question>

## SCOPE findings

### [SCOPE] Title
- **The ambiguity**: <what's unclear>
- **Interpretation A**: <one way to read it>
- **Interpretation B**: <another way>
- **AI would probably pick**: A / B
- **Risk of wrong pick**: Low / Medium / High
- **Question to ask**: <one sharp question>

## UNASKED_QUESTION findings

### [UNASKED_QUESTION] Title
- **The question**: <the question>
- **Possible answers**: <2-3 options>
- **Impact on implementation**: <how each answer changes things>
- **AI default assumption**: <what it would assume>

IMPORTANT: Write the file using the Write tool.
```

#### Agent 3: Technical Constraint Auditor

**subagent_type**: `general-purpose`

Prompt:
```
You are a TECHNICAL CONSTRAINT AUDITOR. Your job is to find quality, architecture, convention, and data requirements that the developer expects but hasn't stated explicitly.

## Your Mission

For the subject described below, identify:

1. **CONSTRAINT**: Technical requirements that are unspoken but expected. For each one:
   - The constraint the developer probably expects
   - Evidence from the codebase (if any) that suggests this expectation
   - What the AI would do without this constraint
   - The gap between expectation and AI default

2. **DATA_SHAPE**: Data structures, schemas, API contracts, integration formats that are left undefined. For each one:
   - What data structure the AI would invent by default
   - What existing patterns in the codebase suggest instead
   - What format/contract/schema questions are unanswered
   - The cost of getting the data shape wrong (migrations, breaking changes, coupling)

Focus on these dimensions:
- **Code style & conventions**: Naming, file structure, module organization
- **Architecture patterns**: Layers, boundaries, dependency direction
- **Quality bar**: Test coverage expectations, error handling depth
- **Data modeling**: Schema conventions, relationship patterns, validation rules
- **Non-functional**: Performance expectations, security requirements, accessibility
- **Integration**: API contracts, event formats, message structures

## Methodology

Read `${CLAUDE_PLUGIN_ROOT}/skills/vendors/CAPABILITIES.md` to discover available resources.
If missing, generate it: `bash ${CLAUDE_PLUGIN_ROOT}/skills/vendors/generate.sh`
Focus on skills related to: principal-level critical analysis, cross-cutting concerns.
Pick 2-4 relevant resources and read them with the Read tool.

Scan the existing codebase to understand established conventions. Compare what exists with what the subject implies.

## Subject

<SUBJECT_DESCRIPTION>

## Codebase Context

<CONTEXT_SUMMARY>

## Output Format (MANDATORY)

Write to ./tmp/cadrage/constraints.md:

# Cadrage: Technical Constraints Audit

## CONSTRAINT findings

### [CONSTRAINT] Title
- **Expected constraint**: <what the dev probably expects>
- **Codebase evidence**: <existing patterns that suggest this>
- **AI default without constraint**: <what would happen>
- **Gap severity**: Low / Medium / High
- **Question to ask**: <one sharp question>

## DATA_SHAPE findings

### [DATA_SHAPE] Title
- **Undefined structure**: <what's not specified>
- **AI would default to**: <what the AI would invent>
- **Codebase patterns suggest**: <what existing code implies>
- **Cost if wrong**: <migrations, breaking changes, coupling>
- **Question to ask**: <one sharp question>

## Cross-Cutting Gaps

For each of the 6 cross-cutting dimensions (error handling, testing, a11y, performance, security, observability), note if the subject says NOTHING about it and it's relevant:

| Dimension        | Mentioned? | Relevant? | Risk if ignored |
|------------------|------------|-----------|-----------------|
| Error Handling   | Yes/No     | Yes/No    | Low/Med/High    |
| Testing          | Yes/No     | Yes/No    | Low/Med/High    |
| Accessibility    | Yes/No     | Yes/No    | Low/Med/High    |
| Performance      | Yes/No     | Yes/No    | Low/Med/High    |
| Security         | Yes/No     | Yes/No    | Low/Med/High    |
| Observability    | Yes/No     | Yes/No    | Low/Med/High    |

IMPORTANT: Write the file using the Write tool.
```

## Step 5: Synthesize & Present Interactively

### For Quick depth

Present findings directly in chat, grouped by risk level:

```
## Cadrage Express — [Subject]

### Risque eleve (l'IA va probablement se tromper)

1. **[TAG] Title** — <one-line description>
   → Question: <the question to answer>

2. ...

### Risque moyen

3. ...

### A confirmer

4. ...
```

Then proceed to **Step 6**.

### For Standard / Deep depth

Once ALL 3 agents are done:

1. Read the 3 reports from `./tmp/cadrage/`
2. Cross-reference findings — look for convergences (multiple agents flagging the same area = high risk)
3. Rank ALL findings by: **risk of wrong assumption** x **cost if wrong**
4. Select the **top 7-10 most critical** findings

Present them in chat in the same format as Quick depth above, but note which agent(s) flagged each item.

Then proceed to **Step 6**.

## Step 6: Interactive Clarification

This is the most important step. The cadrator exists to GET ANSWERS, not just list questions.

Take the top 3-5 highest-risk findings and ask them via AskUserQuestion in a SINGLE call (max 4 questions per call, do a second call if needed).

For each finding, formulate a concrete question with 2-4 options that represent the most likely answers. The options should be:
- Concrete implementation choices (not vague)
- Mutually exclusive
- Including the "AI default" as one option (labeled as such)

Example:
```
Q: "Le endpoint doit-il etre idempotent ?"
- "Oui, avec cle d'idempotence" (Recommended)
- "Non, appels multiples = resultats multiples"
- "Oui, via deduplication naturelle (meme input = meme output)"
```

## Step 7: Feed Back Into Plan

After getting answers:

1. **If a plan exists** (`ai/plans/todo/`): Update it with a new section `## Cadrage` containing:
   - Each answered question with the chosen answer
   - Remaining unanswered questions as TODOs
   - Any constraints that were surfaced and confirmed

2. **If no plan exists yet**: Tell the user:
   > "Cadrage termine. Ces reponses devraient alimenter le plan. Tu veux qu'on passe a l'ecriture du plan maintenant ?"

3. **If questions remain** (more than the 3-5 asked interactively): List them as bullet points for the developer to review, and propose a second round of AskUserQuestion if needed.

## Tone

- Direct, pas ceremoniaux
- Les questions doivent etre pointues, pas vagues
- Chaque question doit reveler un choix concret que l'IA ferait a la place du dev
- Pas de "il faudrait peut-etre considerer..." — plutot "L'IA va faire X. C'est ce que tu veux ?"
- Rendre visible le cout du non-dit: "Si tu ne dis rien, l'IA va probablement choisir Y, ce qui implique Z"
