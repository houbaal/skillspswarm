# Charter Methodology

A charter is a **one-sentence mission statement** using Hendrickson's template:

> **Explore** [target] **with** [resources] **to discover** [information]

- **Target**: a feature, screen, workflow, or API endpoint.
- **Resources**: a technique, data set, tool, configuration, or persona.
- **Information**: the type of problem you hope to find (not a specific bug).

## Standard Exploration Charters
| Good charter                                                                              | Bad charter             |
|-------------------------------------------------------------------------------------------|-------------------------|
| Explore user registration with special characters in all fields to discover validation gaps | Test registration       |
| Explore the checkout flow with network loss mid-payment to discover data integrity issues  | Make sure checkout works |
| Explore the list view with 500+ items to discover scroll performance on low-end devices   | Test the list           |

## Debugging Charters (Occasional Debug Tool)
When used for debugging a specific reported issue:
> **Explore** [symptom/reported bug] **with** [diagnostic tools/isolation] **to discover** [root cause/repro steps].

**Example**: "Explore the 'Add to Cart' failure on Safari with network inspection and console logs to discover why the session token is rejected."

## Scoping & Budget
- **Too broad**: "Explore the whole app" — leads to aimless clicking.
- **Too narrow**: "Verify button X changes color on hover" — that's a check, not exploration.
- **Budget per session**:
    - Interaction actions: 20 max.
    - Screenshots: 8 max.
    - Observations (dumps): 15 max.

Beyond budget: STOP, write the debrief, propose follow-up charters.
