# Alternative Approaches

The Driver/DSL/Driver-selection architecture documented in `philosophy.md` and `implementation.md` is one proven pattern, but not the only one. This file describes three established alternatives so teams can pick consciously.

---

## Screenplay Pattern

The Screenplay pattern models tests around **actors** performing **tasks** to achieve goals.

**Key Concepts:**
- **Actors**: Represent users with abilities (browse web, call APIs)
- **Tasks**: High-level actions (Login, PlaceOrder)
- **Questions**: How actors inspect system state
- **Abilities**: What actors can do (BrowseTheWeb, CallAnApi)

```java
// Serenity BDD style
@Test
public void user_can_search_profiles() {
    Actor john = Actor.named("John")
        .whoCan(BrowseTheWeb.with(browser));

    john.attemptsTo(
        Login.withCredentials("john@example.com", "password"),
        Navigate.to(ProfileSearchPage.class),
        SearchProfiles.byHeadline("Engineer")
    );

    john.should(seeThat(
        TheVisibleProfiles.names(),
        containsInAnyOrder("Alice", "Charlie")
    ));
}
```

**Pros:** Very readable, strong separation, reusable tasks, good for complex journeys
**Cons:** Steeper learning curve, more infrastructure code, verbose for simple tests

**When to choose:** Large teams, complex multi-step journeys, need living documentation

**Resources:**
- [Serenity BDD](https://serenity-bdd.github.io/)
- [Screenplay Pattern Paper](https://www.infoq.com/articles/Beyond-Page-Objects-Test-Automation-Serenity-Screenplay/)

## Serenity JS

TypeScript port of Serenity concepts for modern web testing.

```typescript
import { Actor, Task } from '@serenity-js/core';
import { Navigate, Enter, Click } from '@serenity-js/playwright';

const SearchProfiles = (keyword: string) =>
    Task.where(`#actor searches for "${keyword}"`,
        Navigate.to('/profiles'),
        Enter.theValue(keyword).into(ProfilePage.searchField),
        Click.on(ProfilePage.searchButton)
    );

await actor.attemptsTo(
    SearchProfiles('Engineer')
);
```

**Resources:** [Serenity JS](https://serenity-js.org/)

## SubsecondTDD (Aslak Hellesoy)

Focuses on true subsecond feedback through I/O elimination and composable assemblies.

**Key Concepts:**
- **Assemblies**: Composable stacks of adapters
- **I/O Elimination**: Each layer documents its I/O characteristics
- **cucumber-electron**: Browser testing without WebDriver IPC overhead

```
┌─────────────────────────────────────────────┐
│  Cucumber Step Definitions                  │
│  (Pure business language)                   │
└─────────────────┬───────────────────────────┘
                  │
┌─────────────────▼───────────────────────────┐
│  World (Assembly)                           │
│  Composes: Context + Action + Outcome       │
└─────────────────┬───────────────────────────┘
                  │
    ┌─────────────┼─────────────┐
    ▼             ▼             ▼
┌───────┐    ┌────────┐    ┌─────────┐
│Context│    │ Action │    │ Outcome │
│(setup)│    │ (when) │    │ (then)  │
└───────┘    └────────┘    └─────────┘
```

**Resources:**
- [SubsecondTDD Website](https://subsecondtdd.org)
- [codebreaker-js](https://github.com/subsecondtdd/codebreaker-js)
- [todo-subsecond](https://github.com/subsecondtdd/todo-subsecond)

---

## Comparison Summary

| Aspect              | Driver Architecture | Screenplay     | SubsecondTDD      |
|---------------------|---------------------|----------------|-------------------|
| **Language**        | Any                 | Java/TS        | JS/Gherkin        |
| **Type Safety**     | Full                | Full           | Runtime           |
| **Composability**   | Flat drivers        | Tasks/Abilities| Stacking          |
| **Reporting**       | DIY                 | Built-in       | DIY               |
| **Learning Curve**  | Medium              | High           | High              |
| **Multi-driver**    | Built-in            | Manual         | Built-in          |
| **Browser Speed**   | Standard            | Standard       | cucumber-electron |
