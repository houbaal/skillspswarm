# Test Framework Integration, Tool Comparison & CLI Reference

Practical guidance on wiring acceptance tests into a specific framework, comparing the competing tools at each layer (DB / HTTP / Browser), and a complete CLI cheat-sheet for running tests under different drivers.

For anti-patterns to avoid, see `anti-patterns.md`. For driver discoverability, see `drivers.md`.

---

## Test Framework Integration

### General Principles

Regardless of framework, apply these patterns:

1. **Driver selection via environment/CLI**: Tests read `DRIVER` env var or `--driver` flag
2. **Per-test driver annotations**: `@ExcludeDriver` and `@OnlyDriver` restrict which drivers run a test
3. **Automatic skipping**: Tests skip gracefully when incompatible driver is selected
4. **Shared driver lifecycle**: Setup before test, teardown after, with proper cleanup

### Driver Restriction Annotations

```typescript
// Conceptual - adapt to your framework
@ExcludeDriver('DomainInMemory', reason: 'Requires HTTP layer')
test('should handle HTTP errors gracefully', () => { ... });

@OnlyDriver('BrowserPlaywrightEmbeddedH2')
test('should show visual feedback animation', () => { ... });
```

**When to use:**
- `@ExcludeDriver`: Test doesn't make sense for certain drivers (e.g., visual tests excluded from in-memory)
- `@OnlyDriver`: Test only makes sense for specific drivers (e.g., browser-only visual tests)

### Framework-Specific Patterns

**JUnit 5**: Use `@ExtendWith` with custom extension that reads driver config and conditionally enables tests.

**Pytest**: Use markers (`@pytest.mark.driver`, `@pytest.mark.exclude_driver`) and fixtures that skip incompatible combinations.

**Jest/Vitest**: Create wrapper functions like `describeWithDrivers` that filter based on selected drivers.

---

## Framework / Tool Comparison

### Database Layer

| Technology               | Cold Start | Per-Test | Fidelity | Best For             |
|--------------------------|------------|----------|----------|----------------------|
| Fake (in-memory maps)    | 0ms        | ~0ms     | Low      | TDD, domain logic    |
| H2/SQLite in-memory      | ~100ms     | ~1-5ms   | Medium   | SQL validation       |
| H2 PostgreSQL mode       | ~100ms     | ~1-5ms   | Medium+  | Better compatibility |
| Testcontainers           | ~2-5s      | ~5-20ms  | High     | Real DB behavior     |
| External DB              | 0ms        | ~5-50ms  | Highest  | Black-box, prod-like |

### HTTP Layer

| Technology                | Process Model  | Network I/O     | Fidelity | Best For            |
|---------------------------|----------------|-----------------|----------|---------------------|
| Direct service call       | Same process   | None            | Low      | Domain logic        |
| MockMvc / WebTestClient   | Same process   | None (mocked)   | High     | Controller testing  |
| RestAssured + Embedded    | Separate thread| localhost       | Very High| Full HTTP stack     |
| OkHttp/fetch + External   | Separate proc  | Real network    | Highest  | Black-box           |

### Browser Layer

| Technology        | JS Execution | Process Model    | Speed     | Fidelity | Best For          |
|-------------------|--------------|------------------|-----------|----------|-------------------|
| HtmlUnit          | Limited/None | Same JVM/process | Very Fast | Low      | Server-rendered   |
| Selenium          | Full         | Separate process | Slow      | Highest  | E2E, visual       |
| Playwright        | Full         | Separate process | Medium    | Highest  | Modern apps       |
| Cypress           | Full         | Electron         | Fast      | High     | JS-heavy apps     |
| cucumber-electron | Full         | Same process     | Very Fast | High     | Subsecond browser |

---

## CLI Reference

```bash
# === Discovery ===
./gradlew listDrivers
npm run list-drivers
pytest --list-drivers
dotnet test --list-drivers

# === Single Driver ===
./gradlew test -Ddriver=DOMAIN_IN_MEMORY
npm test -- --driver=DOMAIN_IN_MEMORY
DRIVER=DOMAIN_IN_MEMORY pytest
dotnet test --driver=DOMAIN_IN_MEMORY

# === Multiple Drivers ===
./gradlew test -Ddriver=DOMAIN_IN_MEMORY,HTTP_MOCK_H2
npm test -- --driver=DOMAIN_IN_MEMORY,HTTP_MOCK_H2
DRIVER=DOMAIN_IN_MEMORY,HTTP_MOCK_H2 pytest

# === All Drivers (IDE default) ===
./gradlew test
npm test
pytest

# === Convenience Tasks (project-defined) ===
./gradlew testFast              # DOMAIN_IN_MEMORY
./gradlew testHttp              # HTTP_MOCK_H2
./gradlew testFastSuite         # DOMAIN_IN_MEMORY,HTTP_MOCK_H2
./gradlew testBrowser           # BROWSER_SELENIUM_EMBEDDED_H2
./gradlew testBlackBox          # BROWSER_SELENIUM_EXTERNAL

npm run test:fast               # DOMAIN_IN_MEMORY
npm run test:http               # HTTP_MOCK_H2
npm run test:browser            # BROWSER_SELENIUM_EMBEDDED_H2

# === Environment Variables (CI) ===
DRIVER=DOMAIN_IN_MEMORY ./gradlew test
DRIVER=HTTP_MOCK_H2,HTTP_MOCK_TESTCONTAINERS npm test

# === Show Configuration ===
./gradlew test -Ddriver=DOMAIN_IN_MEMORY -Dacceptance.showConfig=true

# === CI Matrix Example (GitHub Actions) ===
# strategy:
#   matrix:
#     driver:
#       - DOMAIN_IN_MEMORY
#       - HTTP_MOCK_H2
#       - BROWSER_SELENIUM_EMBEDDED_H2
# steps:
#   - run: DRIVER=${{ matrix.driver }} npm test

# === Continuous Mode (local dev) ===
./gradlew test -Ddriver=DOMAIN_IN_MEMORY --continuous
npm test -- --watch --driver=DOMAIN_IN_MEMORY
pytest -f --driver=DOMAIN_IN_MEMORY
```
