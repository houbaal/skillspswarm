# Inspirations & References

The architecture documented in this skill stands on the shoulders of prior work by multiple authors. Consult these sources when deeper context is needed.

---

## Nat Pryce: "Having Our Cake and Eating It"

- [Speaker Deck](https://speakerdeck.com/npryce/having-our-cake-and-eating-it-1)
- [YouTube Talk](https://www.youtube.com/watch?v=Fk4rCn4YLLU)

Key insights:
1. **Four interaction levels**: Domain / Service API / Browser-no-JS / Browser-with-JS
2. **Lingua Franca Pattern**: Common vocabulary between tests and drivers
3. **Hexagonal test architecture**: Tests depend on abstractions, not concretions
4. **Screenplay pattern**: Actors perform tasks against a system

## Dave Farley / LMAX Principles

- [ATDD How-To Guide (PDF)](https://dojoconsortium.org/assets/ATDD%20-%20How%20to%20Guide.pdf)
- [LMAX Simple-DSL Library](https://github.com/LMAX-Exchange/Simple-DSL)
- [Testing@LMAX Blog Series](https://www.symphonious.net/testing-at-lmax/)

Key guidance:
- Imagine the least technical reader
- Avoid UI-specific language
- Make scenarios atomic
- Grow the DSL pragmatically
- Developers own the tests

## SubsecondTDD (Aslak Hellesoy)

- [SubsecondTDD Website](https://subsecondtdd.org)
- [codebreaker-js](https://github.com/subsecondtdd/codebreaker-js)
- [todo-subsecond](https://github.com/subsecondtdd/todo-subsecond)
- [Honeycomb DSL Discussion](https://github.com/subsecondtdd/subsecondtdd.org/issues/1)

Key concepts:
- **Assemblies**: Composable stacks of adapters
- **I/O Elimination**: Explicit documentation of I/O characteristics
- **cucumber-electron**: Browser testing without WebDriver IPC overhead

## Screenplay Pattern / Serenity BDD

- [Serenity BDD Documentation](https://serenity-bdd.github.io/)
- [Serenity JS](https://serenity-js.org/)
- [Screenplay Pattern Paper](https://www.infoq.com/articles/Beyond-Page-Objects-Test-Automation-Serenity-Screenplay/)

Key concepts:
- **Actors** with **Abilities**
- **Tasks** and **Questions**
- Rich reporting and living documentation
