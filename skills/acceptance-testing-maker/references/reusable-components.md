# Reusable Component Patterns

Beyond the core driver/DSL split documented in `implementation.md`, real-world test suites benefit from a handful of recurring building blocks. They are **optional** — introduce them when the pain justifies the extra code.

Patterns covered here:
1. **Page Objects** — UI structure encapsulation, used inside browser drivers.
2. **User Actions** — Higher-level driver-aware operations.
3. **Test Data Builders** — Canonical fixtures with sane defaults.
4. **Mixed-Strategy Drivers** — Different mechanisms per test phase.

---

## Page Objects (Browser Drivers)

Encapsulate UI structure and locators. These are used by browser drivers, not by DSL or tests.

```typescript
interface ProfileFormPage {
    enterName(name: string): Promise<void>;
    enterHeadline(headline: string): Promise<void>;
    enterLocation(location: string): Promise<void>;
    submit(): Promise<void>;
    getSuccessMessage(): Promise<string | null>;
    getErrorMessage(): Promise<string | null>;
}

class PlaywrightProfileFormPage implements ProfileFormPage {
    constructor(private page: Page) {}

    async enterName(name: string): Promise<void> {
        await this.page.locator('#profile-name').fill(name);
    }

    async enterHeadline(headline: string): Promise<void> {
        await this.page.locator('#profile-headline').fill(headline);
    }

    async enterLocation(location: string): Promise<void> {
        await this.page.locator('#profile-location').fill(location);
    }

    async submit(): Promise<void> {
        await this.page.locator('button[type="submit"]').click();
        await this.page.waitForSelector('.toast-success, .toast-error');
    }

    async getSuccessMessage(): Promise<string | null> {
        const locator = this.page.locator('.toast-success');
        if (await locator.count() > 0) {
            return locator.textContent();
        }
        return null;
    }

    async getErrorMessage(): Promise<string | null> {
        const locator = this.page.locator('.toast-error');
        if (await locator.count() > 0) {
            return locator.textContent();
        }
        return null;
    }
}
```

## User Actions (Driver-Aware)

Higher-level actions that take the driver as parameter, remaining decoupled from page objects:

```typescript
class ProfileUserActions {
    constructor(private driver: ProfileSearchDriver) {}

    async createAndVerifyProfile(name: string, headline: string): Promise<void> {
        await this.driver.createProfile(name, headline);
        const names = await this.driver.getVisibleProfileNames();
        if (!names.includes(name)) {
            throw new Error(`Profile ${name} was not created successfully`);
        }
    }

    async searchAndVerify(keyword: string, expectedNames: string[]): Promise<void> {
        await this.driver.searchByHeadline(keyword);
        const actual = await this.driver.getVisibleProfileNames();
        expect(actual.sort()).toEqual(expectedNames.sort());
    }
}
```

## Test Data Builders

```typescript
const TestProfile = {
    simple: (name: string = 'Test Profile') => ({
        name,
        headline: 'Default Headline',
    }),

    engineer: (name: string) => ({
        name,
        headline: `Software Engineer at TechCorp`,
    }),

    manager: (name: string) => ({
        name,
        headline: `Product Manager at StartupXYZ`,
    }),
};

// Usage in tests
await admin.createProfile(TestProfile.engineer('Alice'));
```

## Mixed Strategy (Advanced)

Different mechanisms for different test phases. Example: external API for setup, browser for actions, API or browser for assertions.

| Phase | Mechanism         | Rationale                            |
|-------|-------------------|-------------------------------------:|
| Given | External API call | Fast setup, no browser overhead      |
| When  | Browser           | Tests the real user interaction      |
| Then  | API or Browser    | Fast verification or visual checking |

```typescript
class MixedStrategyProfileDriver implements ProfileSearchDriver {
    constructor(
        private apiClient: AxiosInstance,  // For Given/Then
        private page: Page                  // For When
    ) {}

    // ══════════════════════════════════════════════════════════════
    // GIVEN: External API (fast setup, bypasses browser)
    // ══════════════════════════════════════════════════════════════

    async createProfile(name: string, headline: string, location?: string): Promise<void> {
        await this.apiClient.post('/api/profiles', { name, headline, location });
    }

    async createUser(name: string, email: string): Promise<void> {
        await this.apiClient.post('/api/users', { name, email });
    }

    // ══════════════════════════════════════════════════════════════
    // WHEN: Browser (tests real user interaction)
    // ══════════════════════════════════════════════════════════════

    async searchByHeadline(keyword: string): Promise<void> {
        await this.page.goto('/profiles');
        await this.page.locator('#search-headline').fill(keyword);
        await this.page.locator('#search-btn').click();
        await this.page.waitForSelector('.profile-card');
    }

    // ══════════════════════════════════════════════════════════════
    // THEN: External API (fast verification) or Browser (visual)
    // ══════════════════════════════════════════════════════════════

    async getVisibleProfileNames(): Promise<string[]> {
        // Option A: API for speed
        const response = await this.apiClient.get('/api/profiles/visible');
        return response.data.map((p: any) => p.name);

        // Option B: Browser for visual verification
        // return this.page.locator('.profile-card .profile-name').allTextContents();
    }
}
```

**When to use mixed strategies:**

| Use Case                                    | Recommendation                          |
|---------------------------------------------|-----------------------------------------|
| Setup involves many related entities        | Use direct insertion                    |
| Action is the primary thing being tested    | Use the real protocol (HTTP, browser)   |
| Verification needs complex state check      | Consider direct inspection              |
| Testing the "create" flow itself            | Use consistent protocol throughout      |
| Testing error handling on create            | Use consistent protocol throughout      |
| Need full end-to-end confidence             | Use consistent protocol throughout      |
