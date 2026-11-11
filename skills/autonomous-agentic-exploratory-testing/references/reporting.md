# Reporting & Screenshots

## Constraint: Report on disk from the start
**MANDATORY**: create the report file BEFORE the first action.
Path: `ai/analysis/exploratory-YYYY-MM-DD-<charter-slug>.md`

Copy the report template from `assets/report-template.md` into this file.
Each observation = 1 append to the file. Never accumulate in memory.

## Constraint: Screenshots via sub-agent
Images consume ~1500 tokens each and stay in the context.

**Procedure**:
1. Take a screenshot to disk (`./tmp/screen-NNN.png`) using `mcp__claude-in-chrome__computer`.
2. Launch an ephemeral sub-agent (Agent tool) that reads the image and describes it:
   - Elements visible on screen.
   - Visual anomalies (broken layout, truncated text, overlaps).
   - Comparison with expected state.
3. Retrieve the text description — the sub-agent dies, the image dies with it.
4. Append the text description to the report.

**Rule**: Structured perception (`get_page_text`, `read_page`, DOM) suffices in 80% of cases. Only screenshot when you suspect a **visual** problem.

## Diagnostic Evidence
Every bug or suspicious observation MUST include at least one diagnostic artifact:
- Console output excerpt.
- Network response JSON.
- Database query result.
- Backend log lines.

A bug without evidence is not actionable.
