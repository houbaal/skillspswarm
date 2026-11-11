# Domain Playgrounds — Interactive Domain Object Exploration

**Philosophy:** Build form-based interfaces where you feed inputs to your real domain objects and algorithms, see the output live, and step through business logic interactively.

**Move to domain playgrounds when:** you need to understand what a domain object or business algorithm *does* — not just what it looks like structurally, but how it *behaves* with concrete inputs. This is the difference between reading a recipe and watching someone cook.

## What It Looks Like

```
┌─────────────────────────────────────────────────────────┐
│  Pricing Algorithm Playground                           │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Customer: [Select: Gold / Silver / Bronze ▼]           │
│  Product:  [Select: Widget A ▼]   Qty: [___5___]       │
│  Date:     [2026-02-23]  Promo Code: [WINTER20__]      │
│                                                         │
│  [Calculate]  [Step-by-Step ▶]  [Reset]                 │
│                                                         │
├─────────────────────────────────────────────────────────┤
│  Step 3/7: Apply volume discount                        │
│  ┌───────────────────────────────────────────────────┐  │
│  │  Base price:     €50.00                           │  │
│  │  Qty discount:   -10% (≥5 units) → €45.00        │  │
│  │  Gold tier:      -15%            → €38.25   ◀──  │  │
│  │  Promo WINTER20: -20%            → (next step)   │  │
│  └───────────────────────────────────────────────────┘  │
│                                                         │
│  [◀ Prev]  [Next ▶]  [Run to End ⏩]                    │
│                                                         │
│  State: { price: 38.25, discountsApplied: 2,           │
│           remaining: ["promo", "tax", "rounding"] }    │
└─────────────────────────────────────────────────────────┘
```

## Three Flavors

| Flavor                  | What You Do                                                   | Example                                                                   |
|-------------------------|---------------------------------------------------------------|---------------------------------------------------------------------------|
| **Input → Output**      | Provide inputs, see the result. A function call with a UI.    | "What price does this customer get for this product?"                     |
| **Step-Through**        | Advance an algorithm one step at a time. See intermediate state. | "Show me each discount rule applied, one by one, with before/after."   |
| **Scenario Simulation** | Feed a sequence of events and watch state evolve over time.   | "Replay these 5 orders and show me how inventory changes at each step."  |

**When to use which:**
- **Input → Output** — stateless computations: pricing, validation, eligibility checks, scoring
- **Step-Through** — algorithms with multiple stages: discount pipelines, approval workflows, ETL
- **Scenario Simulation** — stateful systems: order lifecycle, inventory, game logic, state machines

## Implementation with HTMX

- Form inputs POST to the server — server runs the domain object with those inputs — returns HTML fragment
- "Step-by-Step" button: `hx-post="/playground/pricing/step"` with current state in a hidden field — server advances one step, returns new state as HTML
- "Next/Prev" buttons: same pattern, server tracks step index and re-renders
- Alpine.js handles local UI state (collapsible panels, tabs)
- The server-side code calls the **real domain objects** — no mock, no approximation. The playground is a thin HTTP wrapper around your actual business logic.

## Connection to Example Objects

Your Example Objects (tests that return objects — see `references/example-objects.md`) are **pre-built starting states** for the playground. Instead of filling the form manually, you select an example, the playground loads with that state, and you explore from there. The examples become entry points, just like in GT.

## Across Output Modes

- **With web views:** the playground calls server-side code that wraps your domain objects. Works with any backend language.
- **With live view coding:** the playground calls domain objects compiled with the native compiler, giving full semantic accuracy. The same `PricingEngine` used in production, invoked directly.
- **At the moldable IDE level:** the playground IS a REPL — you type arbitrary code, not just form inputs. Maximum flexibility.
