# Syntax-Aware Analysis (tree-sitter)

**The universal middle ground.** Proper syntax-aware parsing without compilation. Works for virtually every language via grammars.

## What tree-sitter Gives You

Real AST nodes — function declarations, class definitions, method calls — not just text matches. You get structural matching that understands language syntax without needing a compiler, build system, or type checker.

## Available As

- **CLI** — `tree-sitter parse`, `tree-sitter query` for pattern matching against syntax nodes
- **Python bindings** (`py-tree-sitter`) — the most mature library bindings, good match with `uvx` for one-shot scripts
- **Rust, JS, Go bindings** — also available
- **tree-sitter query language** — S-expression patterns for structural matching

## Example

```bash
# Parse a Kotlin file and extract all function names using tree-sitter queries
tree-sitter query '(function_declaration name: (simple_identifier) @name)' src/UserController.kt \
  | jq -s '.' > functions.json
```

## When tree-sitter Is Enough

- You need to distinguish function declarations from function calls
- You need to extract specific AST nodes (all class names, all method signatures)
- Cross-language analysis — same tool for Kotlin, Python, TypeScript, Go, Ruby...
- File-based analysis where compilation isn't available or practical
- Building views that need structural accuracy without semantic depth

## When to Graduate

Move to `native-compiler.md` when:
- You need type resolution ("what type does this variable actually hold?")
- You need overload resolution ("which `process()` method is actually called here?")
- You need DI/injection graphs ("what concrete class is injected for this interface?")
- You need cross-file semantic relationships that require a type system

## Sweet Spot

Tree-sitter is the sweet spot for most moldable views: syntax-aware but no compilation needed, works across languages, and composes with Unix pipes. It fills the gap between grep (fragile text matching) and native compilers (full semantic analysis).
