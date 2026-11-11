# Scala 3 DSL Pattern: Significant Indentation & Infix

Scala 3 achieves maximum elegance with zero braces.

## Usage Example

```scala
@Test def `should filter profiles by headline keyword` = scenario:

  Given:
    profile named "Alice":
      headline being "Software Engineer at TechCorp"
    profile named "Bob":
      headline being "Product Manager at StartupXYZ"

  When:
    user searchesForHeadlineContaining "Engineer"

  Then:
    user shouldSee visibleProfiles:
      "Alice"
      "Charlie"
```

## Language Features Used

- Significant indentation (colon + newline replaces braces)
- Infix notation (method calls without dots)
- Backtick identifiers (spaces in test names)
- Extension methods
- Context functions (implicit receivers)
- `infix` soft modifier
- Singleton objects as DSL anchors
