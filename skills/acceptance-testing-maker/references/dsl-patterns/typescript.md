# TypeScript DSL Pattern: Object Destructuring

TypeScript leverages object destructuring to provide both readability and full type safety.

## Usage Example
```typescript
test("should filter profiles by headline keyword", async () => {
    await admin.createProfile({ name: "Alice", headline: "Software Engineer at TechCorp" });
    await admin.createProfile({ name: "Bob", headline: "Product Manager at StartupXYZ" });

    await search.byHeadlineContaining("Engineer");
    await search.verifyVisibleProfiles("Alice", "Charlie");
});
```

## Implementation
```typescript
interface ProfileParams {
    name: string;
    headline: string;
    location?: string;
    pictureUrl?: string;
}

class AdminDsl {
    constructor(private driver: Driver) {}

    async createProfile({ name, headline, location, pictureUrl }: ProfileParams): Promise<void> {
        await this.driver.createProfile(name, headline, location, pictureUrl);
    }
}

class SearchDsl {
    constructor(private driver: Driver) {}

    async byHeadlineContaining(keyword: string): Promise<void> {
        await this.driver.searchByHeadline(keyword);
    }

    async verifyVisibleProfiles(...expectedNames: string[]): Promise<void> {
        const actual = await this.driver.getVisibleProfileNames();
        expect(actual).toEqual(expect.arrayContaining(expectedNames));
        expect(actual.length).toBe(expectedNames.length);
    }
}
```
