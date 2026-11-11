# C# DSL Pattern: Fluent Builder Chain

C# can use fluent chaining combined with `using static` and named arguments. Note that Python/TypeScript patterns work equally well in C# — this is just one alternative.

## Usage Example

```csharp
using static MyProject.AcceptanceTests.Dsl;

[Test]
public void Should_filter_profiles_by_headline_keyword() => Scenario(s => s

    .Given(
        Profile(Name: "Alice", Headline: "Software Engineer at TechCorp"),
        Profile(Name: "Bob", Headline: "Product Manager at StartupXYZ"))

    .When(User.SearchesForHeadlineContaining("Engineer"))

    .Then(
        User.ShouldSee(VisibleProfiles("Alice", "Charlie")))
);
```

## Implementation

```csharp
public static class Dsl
{
    public static Actor User { get; } = new();

    public static Profile Profile(
        string Name,
        string Headline,
        string? Location = null) => new(Name, Headline, Location);

    public static Expectation VisibleProfiles(params string[] expectedNames)
        => new VisibleProfilesExpectation(expectedNames);

    public static void Scenario(Func<ScenarioBuilder, ScenarioBuilder> configure)
    {
        var builder = new ScenarioBuilder();
        configure(builder).Execute();
    }
}

public class ScenarioBuilder
{
    private readonly List<Profile> _profiles = new();
    private IAction? _action;
    private readonly List<Expectation> _expectations = new();

    public ScenarioBuilder Given(params Profile[] profiles)
    {
        _profiles.AddRange(profiles);
        return this;
    }

    public ScenarioBuilder When(IAction action)
    {
        _action = action;
        return this;
    }

    public ScenarioBuilder Then(params Expectation[] expectations)
    {
        _expectations.AddRange(expectations);
        return this;
    }

    public void Execute()
    {
        var driver = DriverFromContext();
        driver.Setup();
        try
        {
            foreach (var profile in _profiles)
                driver.CreateProfile(profile);

            _action?.Execute(driver);

            foreach (var expectation in _expectations)
                expectation.Verify(driver);
        }
        finally
        {
            driver.Teardown();
        }
    }
}

public class Actor
{
    public IAction SearchesForHeadlineContaining(string keyword)
        => new SearchAction(keyword);

    public Expectation ShouldSee(Expectation expectation)
        => expectation;
}
```
