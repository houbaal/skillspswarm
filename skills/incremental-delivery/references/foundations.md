# Shared Foundations

These principles appear across all three disciplines (Vertical Slicing, ATDD/TDD, CD Enforcement). They are the common ground — when in doubt, return here.

---

## 1. Every Commit is Deployable to Production

Not "ready for PR review." Not "ready for merge." Ready for **production. Right now.**

This is the non-negotiable shared by all three disciplines:
- **CD Enforcer**: The golden rule. Main is always production-ready.
- **Vertical Slicer**: Each slice = a series of deployable commits. If you can't deploy it, it's not a slice.
- **ATDD/TDD**: Every GREEN commit includes code + tests and is production-ready. RED ATDD commits use `@skip`/`@pending` markers to stay deployable (see tensions.md).

**Implication**: No commit exists in a "WIP" state. No "I'll fix this later." Every commit is a complete, deployable unit.

---

## 2. Small Batches / Baby Steps

Build the **smallest increment possible** that can be tested and deployed.

| Discipline       | Unit of work        | Typical size        |
|------------------|---------------------|---------------------|
| Vertical Slicer  | Deployment          | 10 min to 2-4 hours |
| CD Enforcer      | Commit              | 10-15 minutes        |
| ATDD/TDD         | TDD inner cycle     | Minutes (R/G/R)      |

The relationship:
- 1 vertical slice = 1 ATDD outer loop
- 1 ATDD outer loop = N TDD inner cycles
- 1 TDD inner cycle = 1 commit
- Therefore: 1 vertical slice = N commits (typically 8-16 for a 2-4h slice)

**The 30-second feedback rule**: Within 30 seconds of making a change, you should know if you're on the right track. If not, the batch is too big.

---

## 3. Tests in the Same Commit

Production code and tests are an **atomic unit**. They belong in the same commit.

- **CD Enforcer**: "Tests prove the commit is production-ready." Separate commits for code and tests = the first commit is untested in production.
- **ATDD/TDD**: Tests drive design — they come **before** code. The commit is `code + test` because the test existed first.

**No exceptions** for new work. The only exception is adding tests for pre-existing untested code (tech debt payback), which is its own commit.

---

## 4. Backward Compatibility is Non-Negotiable

Breaking changes are delivered **incrementally**. Old and new code coexist during transitions.

- **CD Enforcer**: No "big bang" deployments. Use Expand-and-Contract, Branch by Abstraction, Feature Flags.
- **Vertical Slicer**: Each deployment works with current production. Refactoring direction is inside-out specifically to maintain backward compat.

**The rule**: If deploying your change would break anything that was working before, the change is not ready.

---

## 5. Feedback Drives Everything

The purpose of small batches, deployability, and tests is **fast feedback loops**.

- **Vertical Slicer**: "What can we do today that can be used tomorrow?" — feedback from real users on real deployments.
- **ATDD/TDD**: Tests as specifications — feedback from automated checks on every cycle.
- **CD Enforcer**: CI runs locally before push — feedback in seconds, not after a pipeline run.

**Optimize for fastest feedback**, even if it means reordering "logical" steps. Test -> Code -> Infrastructure, not the reverse.

---

## 6. Value is Deployable

A unit of work has value only when it is:
1. **Deployed** (or deployable) to production
2. **Tested** (automated proof it works)
3. **Usable** (delivers something to at least one user, even if behind a flag)

Code that compiles but isn't deployable has no value. Tests that pass on a branch but aren't in production have no value. A feature behind a flag that nobody can enable has no value.

The three disciplines enforce this from different angles — together they ensure nothing slips through.
