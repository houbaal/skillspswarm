# Test Harness Strategies & Time Travel

Production code can expose **test-only endpoints** that enable fast, reliable test setup without going through the UI or public API flow. This file covers:

1. **Back Doors (Mangling endpoints)** — deliberate bypass of business rules for setup.
2. **Time Travel** — shifting the system's perception of "now" for time-dependent features.
3. **Scheduled Jobs back doors** — forcing jobs to run on demand.
4. **References** — authoritative sources (LMAX, Dave Farley).

---

## Test Harness Strategies (Back Doors)

> **"Mangling"** — A term from Dave Farley / LMAX describing test-dedicated endpoints that manipulate system state directly.

Production code exposes **test-only endpoints** that enable fast, reliable test setup without going through the UI or public API flow. These are sometimes called "back doors", "test harness endpoints", or "mangling endpoints".

### Why "Mangling"?

The term **mangling** emphasizes that these endpoints deliberately bypass normal business rules and validation to "mangle" (directly manipulate) the system state. Unlike the careful, validated paths that production users follow, mangling endpoints:

- **Skip validation** — Create invalid states for edge-case testing
- **Bypass workflows** — Set up complex scenarios without multi-step UI flows
- **Ignore side effects** — Create data without triggering notifications, audits, etc.
- **Access internals** — Expose state that's normally encapsulated

The name is intentionally ugly — it reminds developers these are **testing shortcuts, not production APIs**.

### Why Use Back Doors?

| Concern        | UI-based Setup              | Back Door Setup              |
|----------------|-----------------------------|-----------------------------|
| Speed          | Slow (renders, waits, JS)   | Fast (direct DB/service)    |
| Reliability    | Flaky (timing, animations)  | Deterministic               |
| Coupling       | Breaks when UI changes      | Stable test contract        |
| Parallelism    | Hard (shared browser state) | Easy (stateless calls)      |
| Edge cases     | Can't create invalid states | Can create any state        |

### Implementation Pattern

```typescript
// Test-only controller (stripped in production builds or behind feature flag)
@Controller('/test-harness')
@ConditionalOnProperty('test.harness.enabled')
export class TestHarnessController {

    @Post('/reset')
    async resetDatabase(): Promise<void> {
        // Truncate all tables, reset sequences
        await this.db.truncateAll();
    }

    @Post('/profiles')
    async createProfile(@Body() data: any): Promise<Profile> {
        // Bypasses validation, events, audit logs — direct insertion
        return this.profileRepository.insertDirect(data);
    }

    @Post('/users/:id/login-token')
    async createLoginToken(@Param('id') userId: string): Promise<{ token: string }> {
        // Creates auth token WITHOUT password verification
        return { token: this.authService.createTokenForUser(userId) };
    }

    @Post('/users/:id/make-admin')
    async makeAdmin(@Param('id') userId: string): Promise<void> {
        // Bypasses approval workflows
        await this.userRepository.setRole(userId, 'ADMIN');
    }
}
```

### Safety Guidelines

| Guideline                  | Implementation                                                       |
|----------------------------|----------------------------------------------------------------------|
| **Never deploy to prod**   | Build profiles, feature flags, or separate modules                   |
| **Document clearly**       | Name endpoints obviously (`/test-harness/*`, `/backdoor/*`, `/_test/*`) |
| **Restrict access**        | Even in test envs, limit to localhost or CI IP ranges                |
| **Keep minimal**           | Only create endpoints you actually need                              |
| **No business logic**      | Mangling endpoints should be dumb CRUD, no validation                |

### Usage in Drivers

```typescript
class HttpProfileSearchDriver implements ProfileSearchDriver {

    // ══════════════════════════════════════════════════════════════
    // GIVEN: Uses back door for speed (mangling)
    // ══════════════════════════════════════════════════════════════

    async createProfile(name: string, headline: string): Promise<void> {
        await this.httpClient.post('/test-harness/profiles', { name, headline });
    }

    async createUserWithRole(name: string, email: string, role: string): Promise<void> {
        const user = await this.httpClient.post('/test-harness/users', { name, email });
        await this.httpClient.post(`/test-harness/users/${user.id}/role`, { role });
    }

    // ══════════════════════════════════════════════════════════════
    // WHEN: Uses real API (what we're actually testing)
    // ══════════════════════════════════════════════════════════════

    async searchByHeadline(keyword: string): Promise<void> {
        await this.httpClient.get('/api/profiles/search', {
            params: { headline: keyword }
        });
    }

    // ══════════════════════════════════════════════════════════════
    // THEN: Can use either real API or back door for verification
    // ══════════════════════════════════════════════════════════════

    async getVisibleProfileNames(): Promise<string[]> {
        const response = await this.httpClient.get('/api/profiles/visible');
        return response.data.map((p: any) => p.name);
    }
}
```

---

## Time Travel Strategy

Many business features depend on time: subscriptions expire, trials end, scheduled jobs run, reports generate for date ranges. Testing these without **time travel** means either:

- Waiting real time (impractical)
- Hardcoding dates (brittle, fails on specific days)
- Complex mocking (error-prone)

### The Pattern

Expose a **test harness endpoint** that shifts the system's perception of "now":

```typescript
@Controller('/test-harness')
export class TimeHarnessController {

    @Post('/time/travel')
    async travelTo(@Body() { iso8601 }: { iso8601: string }): Promise<void> {
        // Sets the system clock for this test session
        await this.clockService.setCurrentTime(new Date(iso8601));
    }

    @Post('/time/advance')
    async advance(@Body() { days, hours, minutes }: TimeAdvance): Promise<void> {
        await this.clockService.advanceBy({ days, hours, minutes });
    }

    @Post('/time/reset')
    async resetToRealTime(): Promise<void> {
        await this.clockService.useRealClock();
    }
}
```

### Clock Abstraction

The system must use an injectable clock, not `new Date()` or `Date.now()` directly:

```typescript
// Port (interface)
interface Clock {
    now(): Date;
    today(): LocalDate;
}

// Production adapter
class SystemClock implements Clock {
    now(): Date { return new Date(); }
    today(): LocalDate { return LocalDate.now(); }
}

// Test adapter
class ControllableClock implements Clock {
    private frozen: Date | null = null;

    now(): Date {
        return this.frozen ?? new Date();
    }

    setCurrentTime(time: Date): void {
        this.frozen = time;
    }

    advanceBy(duration: Duration): void {
        this.frozen = addDuration(this.now(), duration);
    }

    useRealClock(): void {
        this.frozen = null;
    }
}
```

### DSL Integration

```typescript
class TimeDsl {
    constructor(private driver: Driver) {}

    async travelTo(dateString: string): Promise<void> {
        await this.driver.setSystemTime(dateString);
    }

    async advanceBy(duration: { days?: number; hours?: number }): Promise<void> {
        await this.driver.advanceTime(duration);
    }

    async theNextDay(): Promise<void> {
        await this.advanceBy({ days: 1 });
    }

    async oneWeekLater(): Promise<void> {
        await this.advanceBy({ days: 7 });
    }
}
```

### Test Example

```typescript
test('subscription expires after trial period', async () => {
    // Given
    await admin.createUser({ email: 'alice@test.com', plan: 'trial' });
    await time.travelTo('2024-01-01');
    await user.startsTrialSubscription();

    // When: 14 days pass (trial period)
    await time.advanceBy({ days: 14 });
    await system.runScheduledJobs();  // Another back door!

    // Then
    await user.shouldSeeSubscriptionStatus('expired');
    await user.shouldBePromptedToUpgrade();
});

test('monthly report includes correct date range', async () => {
    // Given
    await time.travelTo('2024-03-15');
    await admin.createSalesRecord({ amount: 100, date: '2024-03-10' });
    await admin.createSalesRecord({ amount: 200, date: '2024-03-20' });
    await admin.createSalesRecord({ amount: 50, date: '2024-02-28' });  // Previous month

    // When
    await time.travelTo('2024-04-01');
    await reports.generateMonthlyReport('2024-03');

    // Then
    await reports.shouldShowTotal(300);  // Only March records
});
```

### Scheduled Jobs Back Door

Time travel often pairs with a **job trigger endpoint**:

```typescript
@Controller('/test-harness')
export class JobHarnessController {

    @Post('/jobs/run')
    async runJob(@Body() { jobName }: { jobName: string }): Promise<void> {
        // Triggers scheduled job immediately, regardless of cron schedule
        await this.jobScheduler.runNow(jobName);
    }

    @Post('/jobs/run-all-due')
    async runAllDueJobs(): Promise<void> {
        // Runs all jobs that would be due at current (possibly fake) time
        await this.jobScheduler.runAllDue();
    }
}
```

### Time Travel Considerations

| Aspect                  | Recommendation                                                    |
|-------------------------|-------------------------------------------------------------------|
| **Scope**               | Per-test session, not global — parallel tests need isolation      |
| **Database timestamps** | Use `clock.now()` in application, not DB's `NOW()`                |
| **Third-party calls**   | Mock external services that validate timestamps                   |
| **Caching**             | Clear time-sensitive caches after time travel                     |
| **Audit logs**          | Decide: fake time or real time for audit trails?                  |

---

## References: Test Harness & Time Travel

### Dave Farley / LMAX

- **[Testing@LMAX Blog Series](https://www.symphonious.net/testing-at-lmax/)** — Detailed explanation of mangling endpoints and test infrastructure
- **[ATDD How-To Guide (PDF)](https://dojoconsortium.org/assets/ATDD%20-%20How%20to%20Guide.pdf)** — Section on test data management
- **[Dave Farley YouTube: TDD & Test Doubles](https://www.youtube.com/watch?v=EZ05e7EMOLM)** — Discusses when to use real vs fake dependencies
- **[Continuous Delivery YouTube Channel](https://www.youtube.com/@ContinuousDelivery)** — Many videos on acceptance testing patterns

### Key Quotes

> "We have a 'mangling' layer that lets us set up test state directly. It's ugly, it bypasses all our nice domain logic, and it's essential for fast, reliable tests."
> — LMAX Architecture Blog

> "The Given phase is about getting the system into the right state. How you do that is an implementation detail of the test infrastructure, not the test itself."
> — Dave Farley
