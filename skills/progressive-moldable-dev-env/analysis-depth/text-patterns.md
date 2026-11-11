# Text Patterns (grep / awk / sed)

**The simplest analysis level.** Pattern matching on raw text. Fast, available everywhere, but fragile.

## Strengths

- Zero setup — available on any Unix system
- Instant execution
- Pipeable — compose analysis from small tools
- Works over SSH, in CI, in any environment

## Limitations

- Breaks on multiline constructs, comments, string literals containing keywords
- No understanding of language structure — everything is text
- Can't resolve types, interfaces, or dependencies semantically
- Edge cases accumulate: the more complex the query, the more fragile it gets

## When This Is Enough

- Simple structural queries: "find all files with `@GetMapping`"
- Counting occurrences: "how many TODO comments?"
- Quick surface scans: "which files import this module?"
- One-off checks where false positives are acceptable

## When to Graduate

Move to `syntax-aware.md` (tree-sitter) when:
- You need to distinguish function declarations from function calls
- Multiline constructs break your regex
- Comments or string literals generate false positives
- You need to match on language-specific AST nodes (class definitions, parameter lists)

## Key Tools

- **grep/rg** — basic pattern matching
- **awk** — field-based extraction and transformation
- **sed** — stream editing for format conversion
- **jq** — JSON filtering and transformation (when input is already structured)
- **gron** — flatten JSON into greppable lines (`gron data.json | grep endpoint`)
