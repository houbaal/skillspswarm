# DSL Design Patterns

Different languages offer various ways to implement readable DSLs for acceptance testing. Choose the pattern that best fits your project's language and team preferences.

## Language-Specific Guides

| Language   | Pattern Description             | Reference File |
|------------|---------------------------------|----------------|
| **Java**   | DslParams (runtime parsed)      | **[java.md](dsl-patterns/java.md)** |
| **Python** | Native Named Parameters         | **[python.md](dsl-patterns/python.md)** |
| **TypeScript**| Object Destructuring & Types | **[typescript.md](dsl-patterns/typescript.md)** |
| **Kotlin** | Trailing Lambdas & Infix        | **[kotlin.md](dsl-patterns/kotlin.md)** |
| **Scala 3**| Indentation & Infix             | **[scala.md](dsl-patterns/scala.md)** |
| **C#**     | Fluent Builder Chain            | **[csharp.md](dsl-patterns/csharp.md)** |
| **Ruby**   | instance_eval Block Style       | **[ruby.md](dsl-patterns/ruby.md)** |

## Comparison Summary

Those are mainly propositions and samples, and can be adapted to the tastes of the team.

| Language   | Approach                        | Named Params    | Type Safety | Noise Level |
|------------|---------------------------------|-----------------|-------------|-------------|
| Java       | DslParams (string varargs)      | Runtime parsed  | None        | Medium      |
| Python     | DSL objects + kwargs            | Native          | Optional    | Low         |
| TypeScript | DSL objects + destructuring     | Native          | Full        | Low-Medium  |
| Scala 3    | Infix + indentation             | Native          | Full        | **Minimal** |
| Kotlin     | Trailing lambda + infix         | Native          | Full        | Low         |
| C#         | Fluent chain + named args       | Native          | Full        | Medium      |
| Ruby       | DSL blocks + symbols            | Native          | None        | Low         |
