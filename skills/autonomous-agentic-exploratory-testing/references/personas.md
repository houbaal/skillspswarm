# Testing Personas

Adopt a persona to guide your exploration style. Switch personas
between iterations to broaden coverage:

| Persona              | Behavior                                              | What it finds                    |
|----------------------|-------------------------------------------------------|----------------------------------|
| **Impatient user**   | Double-clicks, skips steps, navigates away during load | Race conditions, debounce bugs   |
| **Confused novice**  | Presses wrong buttons, enters unexpected data         | Error handling, guidance gaps     |
| **Power user**       | Rapid workflows, keyboard shortcuts, bulk operations  | Performance, edge case handling  |
| **Malicious user**   | Injection, path traversal, oversized input            | Security vulnerabilities         |
| **Offline user**     | Network toggle mid-action (L2+ only)                  | Offline-first gaps, sync bugs    |
| **Distracted user**  | Starts action, switches tabs, returns minutes later   | State restoration, process death |
