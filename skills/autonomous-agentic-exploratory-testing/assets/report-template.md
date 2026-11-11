# Exploratory Test Report

## Session
- **Date**: [date]
- **Charter**: [1-sentence description]
- **Scope**: [screen or workflow tested]
- **Level**: L1 / L2 / L3 / L4
- **Tools used**: [browser automation, CLI, etc.]
- **Actions**: [N / 20 budget used]
- **Config**: [build variant + flags]

## Bugs

### BUG-001: [short title]
- **Severity**: Critical | High | Medium | Low
- **Type**: Crash | Functional | Visual | Accessibility | Performance
- **Screen**: [name]
- **Repro**:
  1. [step — with exact tool call used]
  2. [step]
- **Observed**: [what happened]
- **Expected**: [what should have happened]
- **Diagnostic** (MANDATORY — paste raw evidence, not just "checked logs"):
  - console: [paste relevant lines]
  - network: [paste request/response]
  - database: [paste query + result]
  - backend: [paste relevant lines]
- **Screenshot**: [file path if captured]
- **Reproducibility**: Systematic | Intermittent

## Observations
[Fragile areas that deserve deeper testing — include diagnostic evidence]

## Coverage
[Screens visited + strategies applied]

## Not Tested
[What could not be reached and why — including any tool limitations]

## Debrief (PROOF)
[See references/debrief-and-cycle.md for the PROOF framework]

## Handoff — Actions Requises (DO NOT SKIP)

### Bugs to convert to regression tests
| Bug     | Test type          | Stack            | Test to write                              |
|---------|--------------------|------------------|--------------------------------------------|
| BUG-001 | acceptance / unit  | [mobile/backend] | [1-line description of the test]           |
| BUG-002 | acceptance / unit  | [mobile/backend] | [1-line description of the test]           |

### Observations to investigate further
| Obs     | Follow-up action                                                    |
|---------|---------------------------------------------------------------------|
| OBS-001 | [what to check next — code review, deeper test, ask domain expert]  |

### Next agent command
> Read this report and for each BUG, write a failing test BEFORE fixing.
> Workflow: red -> green -> refactor. No fix without a test.
> Report path: `[full path to this report]`
