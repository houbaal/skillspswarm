# Anti-Patterns to Avoid

Recurring mistakes that erode the whole point of an acceptance-testing architecture. Spot them early — the cost of undoing them grows fast.

---

## 1. UI Language Leakage

```typescript
// BAD
test.click("#submit-btn")
test.type("#name-field", "Alice")
test.assertElementVisible(".success-toast")

// GOOD
user.submitsTheForm()
admin.createsProfile({ name: "Alice" })
user.shouldSeeSuccessMessage()
```

The test should describe **business behavior**, not DOM operations. When UI vocabulary leaks into the scenario, every HTML rewrite breaks tests that have nothing to do with what changed.

## 2. Framework Coupling in Test Code

```typescript
// BAD - Test imports Playwright directly
import { Page } from 'playwright';
test("...", async ({ page }) => {
    await page.locator("#search").fill("engineer");
});

// GOOD - Test only knows DSL
test("...", async () => {
    await search.byHeadlineContaining("engineer");
});
```

The test must be unaware of the driver technology. Framework imports inside scenario code make driver substitution impossible and lock the suite to one tool.

## 3. Test Data Sharing

```typescript
// BAD - Shared state between tests
let globalUser = createUser("Alice");  // Created once, reused

// GOOD - Each test creates its own data
test("...", async () => {
    await admin.createUser({ name: "Alice" });
    // ...
});
```

Shared fixtures silently couple tests. Order of execution starts to matter; a failure in one test cascades into false failures in others; parallelism becomes unsafe.
