# Kotlin DSL Pattern: Trailing Lambdas & Infix

Kotlin's features enable a prose-like syntax that is highly readable.

## Usage Example

```kotlin
@Test
fun `should filter profiles by headline keyword`() = scenario {

    Given {
        profile named "Alice" {
            headline being "Software Engineer at TechCorp"
        }
        profile named "Bob" {
            headline being "Product Manager at StartupXYZ"
        }
    }

    When {
        user searchesForHeadlineContaining "Engineer"
    }

    Then {
        user shouldSee visibleProfiles {
            +"Alice"
            +"Charlie"
        }
    }
}
```

## Implementation

```kotlin
// DSL Entry Point
fun scenario(block: ScenarioScope.() -> Unit) {
    ScenarioScope(driverFromContext()).apply(block).execute()
}

class ScenarioScope(private val driver: Driver) {
    val user = UserActor(driver)
    private val givenActions = mutableListOf<() -> Unit>()
    private val whenActions = mutableListOf<() -> Unit>()
    private val thenActions = mutableListOf<() -> Unit>()

    fun Given(block: GivenScope.() -> Unit) {
        givenActions.add { GivenScope(driver).apply(block) }
    }

    fun When(block: WhenScope.() -> Unit) {
        whenActions.add { WhenScope(driver).apply(block) }
    }

    fun Then(block: ThenScope.() -> Unit) {
        thenActions.add { ThenScope(driver).apply(block) }
    }

    fun execute() {
        driver.setup()
        try {
            givenActions.forEach { it() }
            whenActions.forEach { it() }
            thenActions.forEach { it() }
        } finally {
            driver.teardown()
        }
    }
}

// Infix Builders
object profile

infix fun profile.named(name: String) = ProfileBuilder(name)

class ProfileBuilder(private val name: String) {
    val headline = StringField()
    var location: String? = null

    operator fun invoke(block: ProfileBuilder.() -> Unit): Profile {
        this.apply(block)
        return build()
    }

    private fun build() = Profile(name, headline.value, location)
}

class StringField {
    var value: String = ""

    infix fun being(value: String) {  // For Given: setup
        this.value = value
    }

    infix fun shouldBe(expected: String) {  // For Then: assertion
        assertThat(this.value).isEqualTo(expected)
    }
}

// User Actor
class UserActor(private val driver: Driver) {
    infix fun searchesForHeadlineContaining(keyword: String) {
        driver.searchByHeadline(keyword)
    }

    infix fun shouldSee(expectation: Expectation) {
        expectation.verify(driver)
    }
}

fun visibleProfiles(block: ProfileListBuilder.() -> Unit): Expectation {
    val builder = ProfileListBuilder().apply(block)
    return VisibleProfilesExpectation(builder.names)
}

class ProfileListBuilder {
    val names = mutableListOf<String>()

    operator fun String.unaryPlus() {
        names.add(this)
    }
}
```
