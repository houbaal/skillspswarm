# Driver Dimensions, Performance & Discoverability

This reference covers:
1. The **dimensions** along which a driver varies (interaction level, server mode, DB backing…).
2. The **performance profile** of each driver category and the associated developer workflow.
3. **Discoverability** — how to expose the available drivers to engineers.

---

## Driver Dimensions Analysis

### Identified Dimensions

| Dimension             | Possible Values                                                       |
|-----------------------|----------------------------------------------------------------------:|
| **Interaction Level** | Domain / HTTP / Browser-no-JS / Browser-with-JS / CLI / Native App    |
| **Server Mode**       | In-process / Embedded / External (black-box)                          |
| **Browser Tool**      | None / HtmlUnit / Playwright / Cypress                                |
| **HTTP Client**       | None / MockMvc / WebTestClient / RestAssured / fetch                  |
| **Database Backing**  | Fake / In-memory DB (H2/SQLite) / Testcontainers / External DB        |
| **Framework Context** | Without / With                                                        |

### Valid Combinations (Constraints)

| Constraint           | Rule                                                          |
|----------------------|--------------------------------------------------------------:|
| Domain level         | Always in-process, no framework context, no browser, no real DB |
| HTTP level           | Requires framework for mock clients; external uses real HTTP  |
| Browser-no-JS        | Typically HtmlUnit, can be embedded or external               |
| Browser-with-JS      | Requires Playwright or similar                                |
| External mode        | Server lifecycle managed elsewhere (Docker, etc.)             |

### Example Driver Category Registry

Each engineering team defines their own. CLI IDs use **PascalCase** for easier typing:

| #  | Namespace Path                  | CLI ID                            | Interaction     | Server      | DB          |
|----|---------------------------------|----------------------------------:|-----------------|-------------|------------:|
| 1  | `Domain.InMemory`               | `DomainInMemory`                  | Domain          | In-process  | Fake        |
| 2  | `Http.MockH2`                   | `HttpMockH2`                      | HTTP            | In-process  | H2          |
| 3  | `Http.MockTestcontainers`       | `HttpMockTestcontainers`          | HTTP            | In-process  | TC Postgres |
| 4  | `Http.EmbeddedH2`               | `HttpEmbeddedH2`                  | HTTP            | Embedded    | H2          |
| 5  | `Http.External`                 | `HttpExternal`                    | HTTP            | External    | External    |
| 6  | `Browser.HtmlUnitEmbedded`      | `BrowserHtmlUnitEmbedded`         | Browser-no-JS   | Embedded    | H2          |
| 7  | `Browser.PlaywrightEmbeddedH2`  | `BrowserPlaywrightEmbeddedH2`     | Browser-with-JS | Embedded    | H2          |
| 8  | `Browser.PlaywrightEmbeddedTc`  | `BrowserPlaywrightEmbeddedTc`     | Browser-with-JS | Embedded    | TC Postgres |
| 9  | `Browser.PlaywrightExternal`    | `BrowserPlaywrightExternal`       | Browser-with-JS | External    | External    |

---

## Performance & Developer Workflow

### I/O Characteristics by Driver Category

| Driver Category                  | Framework Context | Database I/O    | Network I/O        | Browser I/O      | Typical Speed      |
|----------------------------------|-------------------|-----------------|--------------------|------------------|-------------------:|
| `DomainInMemory`                 | None              | None (fake)     | None               | None             | **~10-50ms/test**  |
| `HttpMockH2`                     | Required (~14s)   | Fast (H2)       | None (in-process)  | None             | **~50-200ms/test** |
| `HttpMockTestcontainers`         | Required          | Real (~2-5s)    | None (in-process)  | None             | **~100-300ms/test**|
| `HttpEmbeddedH2`                 | Required          | Fast (H2)       | Real HTTP (local)  | None             | **~100-500ms/test**|
| `HttpExternal`                   | None (client)     | Real (external) | Real HTTP          | None             | **~200-1000ms/test**|
| `BrowserHtmlUnitEmbedded`        | Required          | Fast (H2)       | HTTP               | HtmlUnit (no JS) | **~200-500ms/test**|
| `BrowserPlaywrightEmbeddedH2`    | Required          | Fast (H2)       | HTTP               | Playwright IPC   | **~500ms-2s/test** |
| `BrowserPlaywrightExternal`      | None              | Real (external) | Real HTTP          | Playwright IPC   | **~1-3s/test**     |

### Recommended Developer Workflow

> **Key Principle**: Fast tests locally for flow state. Comprehensive tests in CI for confidence.

```
┌─────────────────────────────────────────────────────────────────────────┐
│  LOCAL DEVELOPMENT                                                      │
│                                                                         │
│  TDD Cycle (Red-Green-Refactor):                                        │
│    1. Write/modify test                                                 │
│    2. Run: ./test --driver=DomainInMemory                               │
│    3. See result in < 1 second  ◀── CRITICAL FOR FLOW STATE            │
│    4. Write minimal code to pass                                        │
│    5. Refactor                                                          │
│    6. Repeat                                                            │
│                                                                         │
│  Feature Validation (before commit):                                    │
│    Run the specific acceptance test class/method with E2E driver:       │
│    ./test --driver=BrowserPlaywrightEmbeddedH2 ProfileSearchTest        │
│    (Validates the feature at hand, not the entire suite)                │
│                                                                         │
│  Quick Confidence Check (before push):                                  │
│    ./test --driver=DomainInMemory,HttpMockH2                            │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  CI PIPELINE                                                            │
│                                                                         │
│  Stage 1 - Fast Gate (blocks merge):                                    │
│    DRIVER=DomainInMemory,HttpMockH2 ./test                              │
│                                                                         │
│  Stage 2 - Integration (parallel):                                      │
│    DRIVER=HttpMockTestcontainers ./test                                 │
│    DRIVER=BrowserHtmlUnitEmbedded ./test                                │
│                                                                         │
│  Stage 3 - E2E (each commit or nightly, depending on project size):     │
│    DRIVER=BrowserPlaywrightExternal ./test                              │
│                                                                         │
│  When a test fails in CI:                                               │
│    Developer runs the failing test locally with E2E driver              │
│    ./test --driver=BrowserPlaywrightExternal FailingTestName            │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### I/O Elimination Strategy

Each layer of I/O adds latency:

```
┌──────────────────┐
│ Your Test Code   │
└────────┬─────────┘
         │  ~0ms (no I/O)
┌────────▼─────────┐
│ Domain Services  │ ◀── DOMAIN_IN_MEMORY stops here (fastest)
└────────┬─────────┘
         │  ~0-10ms (H2 in-memory)
┌────────▼─────────┐
│ Framework Context│ ◀── HTTP_MOCK_H2 stops here
└────────┬─────────┘
         │  ~10-50ms (HTTP overhead)
┌────────▼─────────┐
│ Embedded Server  │ ◀── HTTP_EMBEDDED stops here
└────────┬─────────┘
         │  ~100-500ms (WebDriver IPC)
┌────────▼─────────┐
│ Real Browser     │ ◀── BROWSER_SELENIUM stops here
└────────┬─────────┘
         │  ~50-200ms (render time)
┌────────▼─────────┐
│ DOM Rendering    │
└──────────────────┘
```

### IDE Configuration for Fast Feedback

Configure your IDE to default to the fastest driver:

**IntelliJ IDEA:**
1. Run → Edit Configurations → Templates → JUnit
2. Add VM options: `-Ddriver=DomainInMemory`

**VS Code:**
```json
{
  "jest.jestCommandLine": "DRIVER=DomainInMemory jest"
}
```

**Continuous Mode:**
```bash
./gradlew test -Ddriver=DomainInMemory --continuous
npm test -- --watch --driver=DomainInMemory
pytest --driver=DomainInMemory -f
```

---

## Driver Discoverability

Make available drivers easy to find:

**CLI list command:**
```bash
$ npm run list-drivers

Available Acceptance Test Drivers:
  DOMAIN:    DomainInMemory (fastest, no framework)
  HTTP:      HttpMockH2, HttpMockTestcontainers, HttpExternal
  BROWSER:   BrowserPlaywrightEmbeddedH2, BrowserPlaywrightExternal

Usage:
  Single:   DRIVER=DomainInMemory npm test
  Multiple: DRIVER=DomainInMemory,HttpMockH2 npm test
```

**Helpful error messages** when invalid driver specified, showing available options and suggesting similar names.

**Startup banner** optionally showing selected driver configuration.
