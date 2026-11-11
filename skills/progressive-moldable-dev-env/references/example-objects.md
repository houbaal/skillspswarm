# Example Objects — Tests That Teach

The paper defines one of its most powerful patterns: the **Example Object**. An example object is a unit test that **returns the tested object**. This small change unifies three activities that are usually separate:

- **Testing** — the example includes assertions, so it works as a test
- **Documentation** — the example shows a concrete instance in a specific state, so it works as illustration
- **Exploration** — the returned object can be inspected further, so it works as a starting point for moldable development

## How It Works (in any language)

A traditional test consumes its fixture and discards it:

```python
def test_empty_game():
    game = LudoGame()
    assert not game.is_over
    assert game.current_player.name == "A"
    # game is discarded
```

An example object returns the fixture:

```python
def example_empty_game():
    game = LudoGame()
    assert not game.is_over
    assert game.current_player.name == "A"
    return game  # the key difference
```

## Why This Matters

**Examples compose.** An example can use another example as its setup:

```python
def example_player_a_rolls_6():
    game = example_empty_game()  # start from a known state
    game.roll(6)
    assert game.current_player.can_move
    return game
```

This creates a **tree of examples** — each one a tested, documented state that can be inspected. When you search for usages of an API, you don't just find code — you find live, runnable instances that demonstrate the API in specific states.

**Examples are moldable objects.** Once you have an example that returns an object, you can inspect that object, build views for it, navigate from it to related objects. The example is your entry point into the explorable system.

## Practical Adoption

You don't need GT or Smalltalk for example objects. You need:
1. A convention: test methods (or a subset) return the exercised object
2. A runner that can execute them both as tests (checking assertions) and as factories (returning objects)
3. A way to use the returned objects — either in other tests, in documentation, or as input to your moldable views

With terminal views, this could be Python functions callable from a REPL. With domain playgrounds, these examples become **pre-built starting states** — select an example, the playground loads with that state, and you explore from there.
