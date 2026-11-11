# Java DSL Pattern: DslParams

LMAX invented runtime parameter parsing to simulate named parameters in Java.

## Usage Example
```java
@Test
public void shouldFilterProfilesByHeadlineKeyword() {
    admin.createProfile("name: Alice", "headline: Software Engineer at TechCorp");
    admin.createProfile("name: Bob", "headline: Product Manager at StartupXYZ");
    
    search.byHeadlineContaining("Engineer");
    search.verifyVisibleProfiles("Alice", "Charlie");
}
```

## Implementation
```java
public class AdminDsl {
    private final Driver driver;

    public AdminDsl(Driver driver) {
        this.driver = driver;
    }

    public void createProfile(String... args) {
        DslParams params = new DslParams(args,
            new RequiredParam("name"),
            new RequiredParam("headline"),
            new OptionalParam("location"),
            new OptionalParam("pictureUrl")
        );

        driver.createProfile(
            params.value("name"),
            params.value("headline"),
            params.valueAsOptional("location"),
            params.valueAsOptional("pictureUrl")
        );
    }
}
```
*Note: This approach provides excellent readability though no compile-time type safety for parameter names.*
