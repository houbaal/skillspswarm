# Native Compiler Analysis (Full Semantic Depth)

**The most accurate analysis level.** Uses the native compiler or language-specific tooling to produce semantically accurate intermediate representations.

## The Accuracy Gap

| Tool            | Gives You              | Example                                                                              |
|-----------------|------------------------|--------------------------------------------------------------------------------------|
| grep/awk        | Text pattern matches   | "This file contains `@GetMapping`"                                                   |
| tree-sitter     | Syntax tree            | "This is a function declaration with these parameters"                               |
| Native compiler | Full semantic model    | "This method calls *that specific overload* through *that interface* resolved via *DI injection*" |

## Native Compiler Tools by Stack

### Kotlin / JVM
- **Kotlin Compiler API** — full semantic source analysis
- **Java Reflection** — runtime type inspection
- **ASM** — bytecode analysis
- **Spring ApplicationContext** — bean graph, endpoint mappings, configuration (runtime only)
- **Spring Boot Actuator** — exposes beans, health, metrics, env as JSON endpoints (runtime only)

### C# / .NET
- **Roslyn** — compiler-as-a-service. Parsing, semantic analysis, type resolution, symbol references, data flow. The most powerful code analysis API of any mainstream language.
- **.NET Reflection** — runtime type inspection
- **ASP.NET DI Container** — service graph, middleware pipeline, endpoint metadata (runtime only)

### Python
- **`ast` module** — built-in AST parsing (stdlib)
- **`inspect` module** — runtime introspection of live objects (stdlib)
- **`dis` module** — bytecode disassembly (stdlib)
- **mypy / pyright** — type checking and type inference (external)

### Go
- **`go/ast`, `go/parser`, `go/types`** — full semantic analysis (stdlib)
- **`go/packages`** — module-aware package loading (quasi-stdlib)

### JavaScript / TypeScript
- **TypeScript Compiler API** — full semantic analysis, type resolution
- **`deno doc --json`** — documentation extraction as JSON

### Ruby
- **`RubyVM::AbstractSyntaxTree`** — built-in AST parsing (stdlib)
- **`ObjectSpace`** — runtime object graph inspection
- **`Method#source_location`** — source mapping

## Output Format

Native compilers output a **semantic intermediate representation** consumed by any output mode. Default format is JSON (see `references/output-formats.md`).

The representation should include:
- **Entities**: classes, interfaces, functions, endpoints, configurations
- **Relationships**: implements, depends-on, calls, injects, extends
- **Metadata**: file location, visibility, annotations, types, documentation

Example:
```json
{
  "entities": [
    {
      "id":           "com.example.UserController",
      "type":         "controller",
      "file":         "src/main/kotlin/UserController.kt",
      "endpoints":    [{"method": "GET", "path": "/users/{id}", "returnType": "UserDTO"}],
      "dependencies": ["com.example.UserService"]
    }
  ],
  "relationships": [
    {"from": "com.example.UserController", "to": "com.example.UserService", "type": "injects"}
  ]
}
```

This same JSON is renderable as a terminal table, a web page, or a playground input.
