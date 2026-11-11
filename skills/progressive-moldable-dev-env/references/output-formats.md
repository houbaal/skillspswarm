# Output Formats

## JSON as the Default Intermediate Format

JSON is the natural default at all output modes. The tooling ecosystem:

- **jq** — filter, transform, query, reshape. Makes JSON composable in Unix pipelines.
- **gron** — flattens JSON into greppable lines (`gron data.json | grep endpoint`)
- **fx** — interactive JSON viewer with syntax highlighting and folding
- **nushell** — treats JSON as native structured data
- **jless** — terminal JSON pager for exploring large files
- **miller (mlr)** — handles JSON, CSV, TSV interchangeably

## View-Specific Formats

| Format               | Best For                                                            | Notes                                                                    |
|----------------------|---------------------------------------------------------------------|--------------------------------------------------------------------------|
| **JSON**             | Default intermediate, web APIs, tree-shaped data                    | Universal. `jq`, `gron`, `fx`, `nushell` composability.                  |
| **CSV/TSV**          | Terminal tables, Unix pipes                                         | `column -t`, `awk`, `sort`, `cut`, nushell tables, `miller`.             |
| **Mermaid**          | Architecture diagrams, dependency graphs, ER diagrams               | Renders in GitHub, GitLab, Notion, Obsidian. Text-based, diffable.       |
| **C4 / Structurizr** | System architecture at 4 zoom levels                                | Mermaid supports C4 natively. Use as generated output, not maintained artifact. |
| **PlantUML**         | Sequence diagrams, state machines, deployment diagrams              | Broader diagram support than Mermaid for complex sequences.              |
| **DOT (Graphviz)**   | Large/complex graphs, precise layout control                        | `graph-easy` renders DOT as ASCII. Better layouts than Mermaid for large graphs. |
| **DSM**              | Compact dependency overview, cycle detection                        | Square matrix (modules x modules). More compact than a graph for large codebases. |
| **Markdown**         | Human-readable reports, diffable documentation                      | `glow` in terminal. Can embed Mermaid inline.                            |
| **SQLite**           | Complex cross-entity queries, large datasets                        | Opt-in when jq pipelines get unwieldy. `sqlite-utils` for easy import.   |
| **Flamegraph**       | Performance profiling, CPU/memory hotspots                          | `flamegraph.pl`, `speedscope`, `py-spy`.                                 |
| **Treemap**          | Code size, complexity distribution, coverage gaps                   | D3.js renders treemaps natively. Good for high-level first-glance views. |

## Recommended Flow

```
Analysis (grep / tree-sitter / native compiler)
        ↓
    JSON files (canonical intermediate format)
        ↓
    View-appropriate transforms:
        ├── jq / gron / nushell → filtered JSON (all output modes)
        ├── jq → CSV → terminal tables via column -t / miller
        ├── jq → Mermaid / C4 → diagrams in terminal, browser, or markdown
        ├── jq → PlantUML → sequences, state machines, deployments
        ├── jq → DOT → complex graph visualizations
        ├── jq → DSM matrix → terminal table or HTML grid
        ├── Markdown with embedded Mermaid → static reports
        ├── profiler output → Flamegraph → performance views
        ├── metrics JSON → Treemap / Heatmap → size/complexity views
        └── sqlite-utils import → SQLite → SQL queries (when needed)
```

## SQLite as an Optimization

When cross-entity queries become painful in jq — "show me all controllers that depend on services with no tests" — that's a relational JOIN. Consider SQLite when:

- You write complex multi-step jq pipelines to correlate entities
- Your dataset grows large enough that re-parsing JSON per query is slow
- You want ad-hoc queries from the terminal (`sqlite3` CLI)

SQLite is a single file, works everywhere, every language has bindings. Import from JSON is trivial: `sqlite-utils insert db.sqlite entities entities.json`.
