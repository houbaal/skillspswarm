# Terminal Views

**Philosophy:** Parse your codebase, render views directly in the terminal using tables, ASCII diagrams, colors. No web server, no browser. Just scripts that output useful representations.

**This output mode alone may cover 80% of your needs.**

## Language Candidates

### Bash + standard Unix tools

```bash
# Example: list all Spring controllers and their endpoints
grep -rn "@GetMapping\|@PostMapping\|@RequestMapping" src/ \
  | awk -F: '{print $1, $3}' \
  | column -t
```

Pros:
- Available everywhere, zero setup
- Pipeable — compose views from small tools
- `grep`, `awk`, `sed`, `jq`, `column`, `tree` cover most formatting needs
- Works over SSH, in CI, in any terminal

Cons:
- Fragile parsing — regex on source code breaks on edge cases
- No structured data model — everything is text streams
- Complex views require painful string manipulation
- Limited diagram capabilities (though `graph-easy` and `boxchar` exist)

### Nushell

Pros:
- Structured data (tables) as first-class citizens — output is not raw text
- Built-in table rendering with colors, sorting, filtering
- Pipelines operate on typed records, not strings
- `to json`, `to md`, `to csv` for easy format conversion
- Modern and pleasant to write

Cons:
- Not installed by default anywhere
- Smaller ecosystem — fewer examples for AI code generation
- No built-in web server or templating (stays in terminal only)

### Python (CLI scripts, with uvx for dependencies)

Pros:
- `uvx` eliminates pip/venv friction for one-shot scripts
- `rich` library gives beautiful terminal tables, trees, panels, progress bars
- `ast` module for Python self-inspection is excellent
- Best tree-sitter bindings for cross-language parsing
- Largest AI training data — best vibe-coding results

Cons:
- Needs Jinja2/Flask to graduate to web views (though `uvx` makes this painless)
- GIL limits concurrent file watching + output

### Go (CLI tool)

Pros:
- Single binary — build once, run anywhere, distribute trivially
- `text/tabwriter` for aligned tables in stdlib
- Strong concurrency for file watchers + analysis pipelines
- `go/ast`, `go/parser` for Go self-inspection
- Fast execution

Cons:
- Verbose for quick scripts
- Rigid types — heterogeneous data needs boilerplate
- No REPL for interactive exploration

### Ruby (CLI scripts)

Pros:
- Very expressive — shortest scripts for equivalent output
- `terminal-table` gem for formatted tables
- Open classes, metaprogramming for flexible data handling
- `RubyVM::AbstractSyntaxTree` for Ruby self-inspection

Cons:
- Ruby version management friction
- Gem dependencies for nice formatting

## Liveness

File watching provides the "live" feeling:

```bash
# Watch source files and re-run analysis on change
fswatch -o src/ | xargs -n1 -I{} ./analyze.sh
# Or with entr:
find src/ -name '*.kt' | entr -c ./analyze.sh
```

The terminal output refreshes every time you save a file.

## Output Formats

- **Tables:** `column -t`, nushell tables, `rich` tables, `text/tabwriter`
- **Trees:** `tree` command, custom ASCII tree rendering
- **Diagrams:** `graph-easy` for ASCII graph rendering, `boxchar` for box diagrams
- **JSON:** Universal intermediate format — any terminal tool can produce JSON consumed by web views later

For the full format comparison (Mermaid, PlantUML, DOT, DSM, flamegraphs, treemaps...), see `references/output-formats.md`.
