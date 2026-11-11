# Engagement Protocol & Implementation Checklist

How to engage with a team on acceptance-testing work, and a phased checklist for actually implementing the infrastructure.

---

## Engagement Protocol

When a user asks for help with acceptance testing:

### 1. Understand the Context

- What language/framework?
- What's being tested?
- Current pain points?
- Team size and skill level?

### 2. Assess Current State

- Do they have existing tests?
- What patterns are they using?
- What's working, what's not?

### 3. Explore DSL Options with the Stack

Look at what the stack and language can do, then present options:

- **Conservative**: DSL objects with named parameters (works everywhere)
- **Idiomatic**: Language-specific patterns (Kotlin trailing lambdas, Ruby blocks)
- **Maximum Readability**: Advanced DSL features if the language supports them

Ask the user which style resonates with their team.

### 4. Start with E2E, Then Scale Down

Begin with the widest fidelity level — this is what acceptance testing is about, and promote ATDD/TDD double loop:

1. **First**: Write ONE test with a full E2E driver (browser/Playwright)
2. **Then**: Add an integration-level driver (HTTP with MockMvc/WebTestClient/etc.)
3. **Finally**: Add in-memory driver for TDD speed

This ensures the test architecture works for real scenarios before optimizing for speed.
E2E is for validating the deployability of the system in the pipeline.
In-memory is to enable flow for local development.

### 5. Document Decisions

- Help capture architectural decisions
- Create team conventions
- Reference patterns from this guide

### 6. Reference Patterns

- Point to relevant sections of this guide
- Provide concrete examples in their language
- Share relevant external resources

---

## Implementation Checklist

When helping teams implement acceptance test infrastructure:

### Phase 1: Foundation
- [ ] **Define driver interface** with Given/When/Then methods
- [ ] **Implement in-memory driver** (enables fast TDD)
- [ ] **Create basic DSL layer** with domain vocabulary
- [ ] **Configure runtime driver selection** (CLI/env vars)
- [ ] **Write first test** using DSL and in-memory driver

### Phase 2: HTTP Layer
- [ ] **Add HTTP driver** (mock or embedded)
- [ ] **Verify same test works** with both drivers
- [ ] **Configure CI** to run fast driver first

### Phase 3: Browser Layer
- [ ] **Define page object interfaces**
- [ ] **Implement Selenium or Playwright driver**
- [ ] **Add page object implementations**
- [ ] **Configure browser driver in CI** (nightly)

### Phase 4: Polish
- [ ] **Document I/O characteristics** for each driver
- [ ] **Set up driver discoverability** (list command, error messages)
- [ ] **Configure IDE defaults** for fast feedback
- [ ] **Create convenience scripts** (test:fast, test:http, etc.)

### Phase 5: Advanced (Optional)
- [ ] **Add Testcontainers variant** for real database
- [ ] **Consider mixed-strategy drivers** if appropriate
- [ ] **Add test data builders** for complex scenarios
- [ ] **Consider Screenplay pattern** for complex journeys
