# Debugging & Isolation Strategies

When using this skill as a **Debugging Tool**, apply these specific strategies to isolate the cause of a failure.

## 1. Minimal Reproduction Path
- **Vary one thing**: Change only one input or configuration at a time.
- **Strip the context**: If a bug happens in a complex flow, try to trigger it with the minimum number of steps.
- **Reset between tries**: Use Bash tools to reset the database or clear cache to ensure a clean state.

## 2. State Diffing (UI vs. System)
Never trust the UI alone. When a bug occurs:
1. **Perception**: What does the UI show?
2. **Investigation**: What does the API/Network tab say?
3. **Verification**: What does the Database/Log say?
4. **Identify the Gap**: The bug is often the discrepancy between these layers.

## 3. Hypothesis-Driven Debugging
Before performing a diagnostic action, state:
- **Hypothesis**: "I suspect the failure is due to [X]."
- **Test**: "I will [Action] to verify this."
- **Oracle**: "If I see [Y] in the logs, then [X] is confirmed."

## 4. Common Debugging Tours
- **The Saboteur**: Intentionally provide bad data or cut the network mid-way to see how the system handles it.
- **The Historian**: Check logs to see if this error has happened before or if it follows a pattern.
- **The Diver**: Look deep into the console and network requests for silent failures (200 OK with error payload).

## 5. Isolation Oracles
- **Explainability**: If you can't explain *why* it happened, you haven't found the root cause yet.
- **Consistency**: Does the bug happen every time? If not, investigate timing and race conditions.
