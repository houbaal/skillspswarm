# Web Views

**Philosophy:** Serve HTML views in a browser. Add hypermedia-driven navigation between entities. Use HTMX/Unpoly/Alpine for interactivity without building an SPA.

**Move to web views when you need:** clickable navigation between related entities, richer visualizations (graphs, diagrams), multiple simultaneous views, or views that are hard to render in a terminal.

## Architecture

```
Analysis scripts → JSON intermediate representation
                            ↓
                  Lightweight web server
                  Server-side HTML rendering
                  Hypermedia interactions
                            ↓
                      Browser views
```

## Web Server + Templating Candidates

These languages ship with both a web server and a templating engine in their standard distribution:

| Language    | Web Server       | Templating        | Notes                                                                          |
|-------------|------------------|-------------------|--------------------------------------------------------------------------------|
| **Go**      | `net/http`       | `html/template`   | Zero deps. Templates are secure but deliberately limited (no logic).           |
| **Ruby**    | WEBrick          | ERB               | Full language in templates. May want Sinatra (one gem) for routing.            |
| **PHP**     | `php -S`         | PHP itself         | PHP is literally a templating engine. Lowest friction for HTML generation.     |
| **Elixir**  | `:httpd`         | EEx               | Both in stdlib. LiveView (external) adds WebSocket push.                       |
| **Deno**    | `Deno.serve()`   | JSX (built-in)    | Needs Preact for `renderToString`. `deno compile` for single binary.           |
| **Bun**     | `Bun.serve()`    | JSX (built-in)    | Same JSX story as Deno. Better npm compat, less mature.                        |
| **Python**  | Needs Flask/FastAPI | Needs Jinja2    | Not in stdlib, but `uvx` makes it a one-liner.                                |

## Frontend Interaction Layer

The moldable env interaction model: click on something, see a custom view, navigate to related things. This is the hypermedia model — the closest approximation to GT's **inspector chain** at this level.

| Tool            | Best For                              | Notes                                                        |
|-----------------|---------------------------------------|--------------------------------------------------------------|
| **HTMX**        | Polling, SSE, partial updates         | `hx-trigger="every 1s"` for live views. Most popular.        |
| **Unpoly**       | Layered navigation, inspector panels  | Overlays/layers map naturally to inspector pattern.           |
| **Alpine.js**    | Local UI state, toggles, tabs         | Complements HTMX/Unpoly for client-side behavior.            |
| **Hyperscript**  | Inline behavior                       | Alternative to Alpine for simple interactions.                |

Pick one primary (HTMX or Unpoly) + Alpine for local interactivity.

## Liveness Strategies

| Strategy           | Mechanism                                             | Latency  | Implementation                   |
|--------------------|-------------------------------------------------------|----------|----------------------------------|
| HTMX polling       | `hx-trigger="every 1s"`                               | ~1s      | Trivial — one attribute          |
| SSE                | Server pushes on file change                          | ~instant | Moderate — needs event stream    |
| File watch + rebuild | `fswatch` triggers re-analysis, poll picks it up    | ~1-2s    | Simple                           |

HTMX polling alone gets you 90% of the "live" feeling with minimal effort.

## Embedded JS Console (Deno/Bun path only)

If the backend is JavaScript, the browser console becomes a view prototyping environment:

1. User types a function: `(data) => '<div>' + data.name + '</div>'`
2. Function is `eval()`'d in the browser against live data
3. Result renders alongside the editor
4. User clicks "save" — function becomes a persistent server-side view

This recreates GT's core workflow: prototype a view interactively, then keep it. Only natural when backend and frontend share the same language.

## Visualization Libraries

| Library          | Best For                                              | Notes                                                        |
|------------------|-------------------------------------------------------|--------------------------------------------------------------|
| **D3.js**        | Custom, data-driven visualizations of any kind        | Most powerful/flexible. AI agents generate D3 fluently.      |
| **Chart.js**     | Standard charts — bar, line, pie, radar               | Simple API, good defaults.                                   |
| **ApexCharts**   | Interactive charts with zoom, pan, drill-down         | Richer interactivity than Chart.js.                          |
| **Cytoscape.js** | Graph/network visualization                           | Purpose-built for dependency/call graphs.                    |
| **Mermaid.js**   | Declarative diagrams rendered client-side             | Serve Mermaid text, render in-page.                          |

These compose with HTMX: server returns a `<div>` with data attributes, HTMX swaps it in, the chart renders. No SPA framework needed.
