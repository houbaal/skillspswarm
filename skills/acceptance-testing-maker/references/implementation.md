# Driver Infrastructure Implementation Guide

This guide uses TypeScript examples. The patterns translate to other languages.

> **Scope**: this file covers the end-to-end steps for standing up the driver infrastructure (Port, Categories registry, Adapters, DSL layer, runtime selection, test lifecycle). For **reusable components** (Page Objects, User Actions, Test Data Builders, Mixed-Strategy drivers), see `reusable-components.md`. For the **phased checklist**, see `checklist.md`.

---

## Step 1: Define the Driver Interface (Port)

Create an interface expressing **what** the test needs, not **how** it's done.

```typescript
interface ProfileSearchDriver {
    // Setup (Given)
    createProfile(name: string, headline: string, location?: string): Promise<void>;
    createUser(name: string, email: string): Promise<void>;

    // Actions (When)
    loginAs(email: string): Promise<void>;
    searchByHeadline(keyword: string): Promise<void>;
    openProfileDetails(profileName: string): Promise<void>;

    // Queries (Then)
    getVisibleProfileNames(): Promise<string[]>;
    getCurrentUserName(): Promise<string>;
    isSuccessMessageVisible(): Promise<boolean>;
    getErrorMessage(): Promise<string | null>;

    // Lifecycle
    setup(): Promise<void>;
    teardown(): Promise<void>;
}
```

## Step 2: Define Driver Categories

Create a registry with CLI-friendly identifiers (PascalCase):

```typescript
const DriverCategory = {
    Domain: {
        InMemory: 'DomainInMemory',
    },
    Http: {
        MockH2: 'HttpMockH2',
        MockTestcontainers: 'HttpMockTestcontainers',
        External: 'HttpExternal',
    },
    Browser: {
        PlaywrightEmbeddedH2: 'BrowserPlaywrightEmbeddedH2',
        PlaywrightExternal: 'BrowserPlaywrightExternal',
    },
} as const;

type DriverCategoryId = typeof DriverCategory[keyof typeof DriverCategory][keyof typeof DriverCategory[keyof typeof DriverCategory]];

const allCategories: DriverCategoryId[] = Object.values(DriverCategory)
    .flatMap(group => Object.values(group));

function fromCliId(id: string): DriverCategoryId {
    const found = allCategories.find(c => c.toLowerCase() === id.toLowerCase());
    if (!found) {
        throw new Error(buildErrorMessage(id));
    }
    return found;
}

function buildErrorMessage(invalidId: string): string {
    return `Unknown driver: '${invalidId}'

Available drivers:
${Object.entries(DriverCategory).map(([group, drivers]) =>
    `  ${group}:\n${Object.values(drivers).map(d => `    - ${d}`).join('\n')}`
).join('\n')}

Usage:
  Single driver:    DRIVER=DomainInMemory npm test
  Multiple drivers: DRIVER=DomainInMemory,HttpMockH2 npm test

Tip: Run 'npm run list-drivers' to see all available drivers`;
}
```

## Step 3: Implement Drivers (Adapters)

### In-Memory Driver (Fastest)

```typescript
/**
 * Driver: InMemoryProfileSearchDriver
 * Category: DomainInMemory
 *
 * I/O Profile:
 *   - Framework Context: Not required
 *   - Database: Fake (in-memory arrays)
 *   - Network: None
 *   - Browser: None
 *
 * Typical Speed: ~10-50ms per test
 * Best For: TDD cycle, domain logic validation
 * Limitations: Does not test HTTP layer, framework wiring, or UI
 */
class InMemoryProfileSearchDriver implements ProfileSearchDriver {
    private profiles: Profile[] = [];
    private users: User[] = [];
    private currentUser: User | null = null;
    private searchResults: Profile[] = [];
    private lastError: string | null = null;

    async setup(): Promise<void> {
        this.profiles = [];
        this.users = [];
        this.currentUser = null;
        this.searchResults = [];
        this.lastError = null;
    }

    async teardown(): Promise<void> {}

    async createProfile(name: string, headline: string, location?: string): Promise<void> {
        this.profiles.push({ name, headline, location: location ?? null });
    }

    async createUser(name: string, email: string): Promise<void> {
        this.users.push({ name, email });
    }

    async loginAs(email: string): Promise<void> {
        const user = this.users.find(u => u.email === email);
        if (!user) {
            this.lastError = `User not found: ${email}`;
            return;
        }
        this.currentUser = user;
    }

    async searchByHeadline(keyword: string): Promise<void> {
        this.searchResults = this.profiles.filter(p =>
            p.headline.toLowerCase().includes(keyword.toLowerCase())
        );
    }

    async getVisibleProfileNames(): Promise<string[]> {
        return this.searchResults.map(p => p.name);
    }

    async getCurrentUserName(): Promise<string> {
        return this.currentUser?.name ?? '';
    }

    async isSuccessMessageVisible(): Promise<boolean> {
        return this.lastError === null;
    }

    async getErrorMessage(): Promise<string | null> {
        return this.lastError;
    }
}
```

### HTTP Driver

```typescript
/**
 * Driver: HttpProfileSearchDriver
 * Category: HttpMockH2 or HttpExternal
 */
class HttpProfileSearchDriver implements ProfileSearchDriver {
    private httpClient: AxiosInstance;
    private authToken: string | null = null;

    constructor(private baseUrl: string) {
        this.httpClient = axios.create({ baseURL: baseUrl });
    }

    async setup(): Promise<void> {
        await this.httpClient.post('/admin/reset');
    }

    async teardown(): Promise<void> {
        this.authToken = null;
    }

    async createProfile(name: string, headline: string, location?: string): Promise<void> {
        await this.httpClient.post('/api/profiles',
            { name, headline, location },
            { headers: this.authHeaders() }
        );
    }

    async searchByHeadline(keyword: string): Promise<void> {
        await this.httpClient.get('/api/profiles/search', {
            params: { headline: keyword },
            headers: this.authHeaders()
        });
    }

    async getVisibleProfileNames(): Promise<string[]> {
        const response = await this.httpClient.get('/api/profiles/visible', {
            headers: this.authHeaders()
        });
        return response.data.map((p: any) => p.name);
    }

    private authHeaders(): Record<string, string> {
        return this.authToken ? { Authorization: `Bearer ${this.authToken}` } : {};
    }

    // ... other methods
}
```

### Browser Driver (Playwright)

```typescript
/**
 * Driver: PlaywrightProfileSearchDriver
 * Category: BrowserPlaywrightEmbeddedH2 or BrowserPlaywrightExternal
 */
class PlaywrightProfileSearchDriver implements ProfileSearchDriver {
    private page: Page;
    private baseUrl: string;

    constructor(page: Page, baseUrl: string) {
        this.page = page;
        this.baseUrl = baseUrl;
    }

    async setup(): Promise<void> {
        await this.page.goto(this.baseUrl);
        await this.page.context().clearCookies();
    }

    async teardown(): Promise<void> {
        await this.page.context().clearCookies();
    }

    async createProfile(name: string, headline: string, location?: string): Promise<void> {
        await this.page.goto(`${this.baseUrl}/profiles/new`);
        await this.page.locator('#profile-name').fill(name);
        await this.page.locator('#profile-headline').fill(headline);
        if (location) {
            await this.page.locator('#profile-location').fill(location);
        }
        await this.page.locator('button[type="submit"]').click();
        await this.page.waitForSelector('.toast-success, .toast-error');
    }

    async searchByHeadline(keyword: string): Promise<void> {
        await this.page.goto(`${this.baseUrl}/profiles`);
        await this.page.locator('#search-headline').fill(keyword);
        await this.page.locator('#search-btn').click();
        await this.page.waitForSelector('.profile-card');
    }

    async getVisibleProfileNames(): Promise<string[]> {
        return this.page.locator('.profile-card .profile-name').allTextContents();
    }

    // ... other methods
}
```

## Step 4: Create the DSL Layer

```typescript
class ProfileSearchDsl {
    private driver: ProfileSearchDriver;

    constructor(driver: ProfileSearchDriver) {
        this.driver = driver;
    }

    get admin(): AdminDsl {
        return new AdminDsl(this.driver);
    }

    get user(): UserDsl {
        return new UserDsl(this.driver);
    }

    get search(): SearchDsl {
        return new SearchDsl(this.driver);
    }
}

class AdminDsl {
    constructor(private driver: ProfileSearchDriver) {}

    async createProfile(params: { name: string; headline: string; location?: string }): Promise<void> {
        await this.driver.createProfile(params.name, params.headline, params.location);
    }

    async createUser(params: { name: string; email: string }): Promise<void> {
        await this.driver.createUser(params.name, params.email);
    }
}

class UserDsl {
    constructor(private driver: ProfileSearchDriver) {}

    async logsInAs(email: string): Promise<void> {
        await this.driver.loginAs(email);
    }

    async searchesForHeadlineContaining(keyword: string): Promise<void> {
        await this.driver.searchByHeadline(keyword);
    }
}

class SearchDsl {
    constructor(private driver: ProfileSearchDriver) {}

    async byHeadlineContaining(keyword: string): Promise<void> {
        await this.driver.searchByHeadline(keyword);
    }

    async verifyVisibleProfiles(...expectedNames: string[]): Promise<void> {
        const actual = await this.driver.getVisibleProfileNames();
        expect(actual.sort()).toEqual(expectedNames.sort());
    }
}
```

## Step 5: Implement Runtime Driver Selection

```typescript
class DriverRegistry {
    private static factories: Map<string, () => ProfileSearchDriver> = new Map();

    static register(categoryId: string, factory: () => ProfileSearchDriver): void {
        this.factories.set(categoryId.toUpperCase(), factory);
    }

    static get(categoryId: string): ProfileSearchDriver {
        const factory = this.factories.get(categoryId.toUpperCase());
        if (!factory) {
            throw new Error(buildErrorMessage(categoryId));
        }
        return factory();
    }

    static getSelectedCategories(): string[] {
        const envValue = process.env.DRIVER;
        if (!envValue) {
            return ['DomainInMemory']; // Default
        }
        return envValue.split(',').map(s => s.trim());
    }
}

// Registration
DriverRegistry.register('DomainInMemory', () => new InMemoryProfileSearchDriver());
DriverRegistry.register('HttpMockH2', () => new HttpProfileSearchDriver('http://localhost:8080'));
DriverRegistry.register('BrowserPlaywrightEmbeddedH2', async () => {
    const browser = await playwright.chromium.launch();
    const page = await browser.newPage();
    return new PlaywrightProfileSearchDriver(page, 'http://localhost:8080');
});
```

## Step 6: Handle Test Lifecycle

**Jest (TypeScript):**
```typescript
describe('Profile Search', () => {
    let driver: ProfileSearchDriver;
    let dsl: ProfileSearchDsl;

    beforeEach(async () => {
        const categories = DriverRegistry.getSelectedCategories();
        driver = DriverRegistry.get(categories[0]);
        await driver.setup();
        dsl = new ProfileSearchDsl(driver);
    });

    afterEach(async () => {
        await driver.teardown();
    });

    // Tests use `dsl`
});
```
