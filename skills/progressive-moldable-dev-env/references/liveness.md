# Liveness Strategies

Liveness = views that update automatically as the system changes. The strategy depends on your output mode and what you're inspecting.

## By Output Mode

| Output Mode        | Code Structure Liveness          | Runtime State Liveness     |
|--------------------|----------------------------------|----------------------------|
| Terminal views     | `fswatch` + re-run script        | N/A (no server)            |
| Web views          | `fswatch` + HTMX polling         | Polling app endpoints      |
| Domain playgrounds | Re-run on input change           | Direct API calls           |
| Live view coding   | Same-process file watching       | Direct runtime access      |
| Moldable IDE       | Live, in-image                   | Same-process, same-image   |

## Two Distinct Inspection Modes

**Code Structure (Static Analysis):**
Reads source files from disk. No running application needed. Parses AST, resolves types, maps dependencies. Liveness via file watching (`fswatch`, `inotifywait`, `entr`) triggering re-analysis on save.

**Runtime State (Live Analysis):**
Requires the application to be running. Exposes live beans, DI containers, active connections, metrics. Liveness via polling or push. No extra compile cycle.

**Live Data (Database Inspection):**
Connecting domain objects to a live database — staging or production read replica. See `references/live-data.md`.

All modes produce an **intermediate representation** (typically JSON) consumed by whatever output mode you choose.
