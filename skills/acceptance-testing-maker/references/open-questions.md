# Open Questions (Project Decisions)

When implementing the acceptance-testing infrastructure for a specific project, several design trade-offs must be made explicitly. Each team should pick consciously — recommendations below are sensible defaults.

---

## 1. Driver Instance Isolation

| Option                    | Pros                | Cons                     |
|---------------------------|---------------------|--------------------------|
| Fresh instance per test   | True isolation      | Instantiation overhead   |
| Pooled with state reset   | Less overhead       | Shared state risk        |
| Per-class instance        | Balance             | Cross-test contamination |

**Recommendation**: Fresh instance per test as default.

## 2. Framework Context Lifecycle

| Option                          | Trigger             | Pros              | Cons                    |
|---------------------------------|---------------------|-------------------|-------------------------|
| Lazy on first use               | First test needing  | Fast for IN_MEMORY| First pays startup      |
| Eager if any framework driver   | Before any test     | Predictable       | Startup even if skipped |

**Recommendation**: Lazy on first use.

## 3. Parallel Execution

| Driver Category     | Thread Safety           | Recommendation          |
|---------------------|-------------------------|-------------------------|
| IN_MEMORY           | Needs separate state    | Thread-local            |
| MOCK_*              | Client safe, DB not     | Careful with DB         |
| SELENIUM_*          | WebDriver not safe      | One browser per thread  |

**Recommendation**: Run separate processes per parallel stream in CI.
