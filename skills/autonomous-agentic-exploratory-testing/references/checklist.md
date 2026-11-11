# Rules & Checklists

## Imperative Rules
1. **YOU execute. YOU click. YOU observe.** Never delegate to the human.
2. **Perception = chainable. Interaction = one at a time.**
3. **Logs after every suspicious action.** A silent crash is a real bug.
4. **Never assume.** No visible result = no certainty.
5. **Restore state.** Network cut, tab change -> restore to normal before continuing.
6. **3 identical failures = bug or limitation.** Note and move on.
7. **Prefer structured perception over screenshots.**
8. **Document in real time.** Each bug = 1 immediate append to the report.
9. **Be methodical.** 1 screen at a time.
10. **Black box.** Test observable behavior, not the code.
11. **Respect the budget.** 20 actions max.
12. **Cross-reference.** UI + console, UI + network, or UI + database.
13. **Know your level.** Match strategy to test level (L1-L4).
14. **Handoff is mandatory.** The report MUST end with the handoff checklist.

## Pre-flight Check
Before starting the charter, YOU verify:
1. Browser tools work: `mcp__claude-in-chrome__tabs_context_mcp`.
2. Navigate to the app's starting screen.
3. Credentials: log in if needed.
4. Create the report file on disk.
5. Clear/Note console baseline.
6. **Correct test level is set up** (L1-L4).
7. **Feature flags match the charter**.
8. **Data is in a known state**.
