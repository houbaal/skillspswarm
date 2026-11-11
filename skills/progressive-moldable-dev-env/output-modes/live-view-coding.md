# Live View Coding

**Philosophy:** The moldable environment is built in the same language as the target stack. It has full compiler-grade analysis, a web GUI, and an embedded REPL for live view prototyping — all in one process.

**Move to live view coding when:** you've validated the concept at lower output modes and want the full GT-like experience with semantic depth and live interactivity combined. This is the most powerful option for mainstream stacks but also the most effort. Most projects will never need this.

## What This Adds Over Web Views + Playgrounds

- **Embedded REPL in the GUI** — type code in the browser, evaluate it on the server, render the result live. Prototype new views interactively without a separate editor or compile cycle.
- **Same-process access** — the analysis engine, web server, and REPL share a runtime. No serialization boundary, no intermediate JSON. Views can directly query the semantic model.
- **Runtime + static in one** — inspect live application state AND code structure from the same interface.

## Stack Feasibility

Not all stacks support embedded REPLs. This is a natural ceiling — languages without eval/scripting cannot fully reach this level.

| Stack              | Analysis                      | Server             | REPL                              | Feasibility |
|--------------------|-------------------------------|--------------------|-----------------------------------|-------------|
| **C# / .NET**      | Roslyn                        | Kestrel + Blazor   | CSharpScript                      | Strong      |
| **Kotlin / JVM**   | Kotlin Compiler API           | Ktor / Spring Boot | Kotlin Scripting API              | Strong      |
| **Python**         | ast + inspect                 | Flask / FastAPI    | `code.InteractiveConsole` / IPython | Strong    |
| **Ruby**           | RubyVM::AbstractSyntaxTree    | Sinatra / Roda     | IRB / Pry                         | Strong      |
| **Elixir**         | BEAM introspection            | Phoenix LiveView   | IEx                               | Strong      |
| **Clojure**        | Clojure analyzer              | Ring / Jetty       | nREPL                             | Strong      |
| **Deno / Bun**     | TypeScript Compiler API       | Deno.serve / Bun.serve | Browser-native `eval()`      | Strong      |
| **Go**             | go/ast + go/types             | net/http           | **No eval** — natural ceiling     | Partial     |

**Go note:** Go excels at terminal views and web views (stdlib has everything) but cannot reach live view coding without a workaround (WASM REPL, external scripting engine). This is a valid stopping point, not a failure.

## The Deno/Bun Advantage

When backend and frontend share JS/TS, the browser console becomes a view prototyping environment natively:

1. User types a view function in the browser
2. Function evaluates against live data (no server round-trip)
3. Result renders inline
4. User saves — function becomes a persistent view

This is the closest mainstream approximation to GT's "prototype in the inspector, keep what works" workflow.

## Transition from Web Views

The jump from web views to live view coding is incremental if you're already in a compatible stack:
- You already have a web server (from web views)
- You already have domain objects accessible server-side (from playgrounds)
- Adding a REPL endpoint is one route addition
- The frontend needs a code editor component (CodeMirror, Monaco) and an eval endpoint

The hard part is not the technical plumbing — it's the design of the **interaction model**: what does the REPL have access to? How do you save a prototype view as a persistent one? How does navigation work between REPL-generated views and pre-built views?
