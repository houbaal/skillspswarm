# Test Levels and Diagnostic Tools

## Test Levels (increasing fidelity)

Most applications can be tested at increasing levels of fidelity.
The project context file (`ai/prompts/exploratory-context.md`) defines the
specific levels for this project. The general pattern is:

| Level  | Typical combo                          | What it tests                                           |
|--------|----------------------------------------|---------------------------------------------------------|
| **L1** | Stubs / mocks / no backend             | UI, state, navigation, process death (0 network)        |
| **L2** | Real backend (local)                   | API errors, auth, timeout, offline-first sync           |
| **L3** | Real device + local backend            | Physical I/O, device performance, memory pressure       |
| **L4** | Real device + staging/prod environment | Production-like data, real network latency              |

**Strict order**: L1 green -> L2 -> L3 -> L4. Never move up with known bugs.

### Critical: stub vs real backend

- **Stub/mock mode**: all data sources are in-memory. No network, no backend.
  Network tests (airplane mode, timeouts) have **NO EFFECT** in this mode.
- **Real backend mode**: actual API calls, real database, real sync.

**Any network-related test MUST be done at L2 minimum (real backend).**

Refer to the project context for exact setup commands per level.

---

## Diagnostic Tools (cross-reference is MANDATORY)

When encountering suspicious behavior, **use ALL available diagnostic tools**
to cross-reference what the UI shows with what actually happened in the system.
Do not rely on the UI alone.

### How YOU (the agent) cross-reference

| Diagnostic source    | How you access it                                                   |
|----------------------|---------------------------------------------------------------------|
| Browser console      | `mcp__claude-in-chrome__read_console_messages`                      |
| Network requests     | `mcp__claude-in-chrome__read_network_requests`                      |
| Server logs          | `Bash`: `tail -n 50 <log-path>` or `docker logs <container>`       |
| Database state       | `Bash`: `psql -c "SELECT ..."` or `sqlite3 db "SELECT ..."`        |
| Backend health       | `Bash`: `curl http://localhost:<port>/health`                       |
| Admin dashboard      | Navigate to it with `mcp__claude-in-chrome__navigate`               |

### When to use each tool

| Symptom                              | Diagnostic action                                      |
|--------------------------------------|--------------------------------------------------------|
| Action has no visible effect         | Check console logs + network requests for errors       |
| Data appears incorrect on screen     | Database query to verify actual state                  |
| Infinite loading / timeout           | Network requests for API errors + backend health check |
| Crash / app killed                   | Console logs for fatal exceptions + stack trace        |
| Sync seems broken                    | Database query before/after + backend logs for sync    |
| Entity in unexpected state           | Dashboard for overview + database for exact state      |

**Rule**: after every suspicious action, check **at least 2 sources**
(UI + console, UI + database, console + network). A bug confirmed by
cross-referencing is a strong bug. A bug seen in the UI alone may be
a perception gap.
