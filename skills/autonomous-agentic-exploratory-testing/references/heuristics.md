# Exploration Heuristics (Hendrickson)

Use these structured heuristics to systematically cover different dimensions.
For each screen, apply at least 2-3.

## CRUD (Create, Read, Update, Delete)
- Create an entity -> does it appear in the list?
- Read it back -> is all data preserved (accents, special chars)?
- Update it -> do dependent screens reflect the change?
- Delete it -> is it gone everywhere? Can you undo?

## Follow the Data
- Enter data in screen A -> trace it through screens B, C, D
- Does the data arrive intact? Same format? Same encoding?
- Where does data get transformed? Can the transformation fail?

## States & Transitions
- Map the state machine: what are the valid states?
- Can you reach an invalid state?
- What happens at each transition boundary?
- Can you trigger a transition twice? (double-click, double-confirm)

## Interrupt & Resume
- Start an action -> interrupt (navigate away, close tab, network loss)
- Resume -> is the state correct? Is data preserved?
- Tab closed and reopened -> what is lost?

## Sequences & Interactions
- Do steps in the wrong order -> is the error clear?
- Skip a step -> what happens?
- Repeat a step -> is it idempotent?
- Interleave two workflows -> do they interfere?

## Ecosystem
- How does this feature interact with other features?
- External systems: does the backend agree with the client app?
- Time-based: what happens if you wait 5 minutes between steps?

## Data Heuristics (Goldilocks)

| Heuristic              | What to try                                  |
|------------------------|----------------------------------------------|
| **Zero / One / Many**  | 0 items, 1 item, 50+ items                  |
| **Too Big / Too Small**| 500+ char input, empty input, 1-char input   |
| **Goldilocks**         | Just right, slightly over, slightly under    |
| **Beginning / End**    | First item, last item, middle item           |
| **Never / Always**     | Feature never used, used 100 times in a row  |

## Soap Opera Testing (Crispin & Gregory)

Compressed, extreme, multi-step realistic scenarios:
- Compress a week's worth of realistic usage into one session
- Chain multiple operations, interruptions, and edge cases

## Input-Specific Strategies

For data entry screens, always try:
- Empty fields -> submit
- Very long text (500+ characters)
- Special characters: `<script>`, `'; DROP TABLE`, `../../etc/passwd`
- Spaces only, leading/trailing spaces
- Negative numbers, zero, very large numbers
- Copy-paste instead of typing

## Degraded Conditions (L2+ only)

These strategies have **NO EFFECT at L1** (stubs):
- Network off -> attempt network action
- Cut network mid-request
- Backend stopped -> app behavior
- Slow network simulation (if available)

## Platform-Specific Heuristics

**Web** (your primary testing environment):
- Resize the browser with `mcp__claude-in-chrome__resize_window`
- Open 2 tabs on the same page with `mcp__claude-in-chrome__tabs_create_mcp`
- Refresh during an action
- Browser back/forward buttons

**Mobile** (via ADB commands in Bash):
- Back button from every screen
- Home -> return: is state preserved?
- Screen rotation: data preserved?
- Process death and return
- Elements without accessibility labels
