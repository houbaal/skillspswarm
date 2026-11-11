# The Question/Answer Cycle

The main SKILL.md introduces the cycle and the quality checklists. This document covers the deeper dynamics: why cheap answers transform the practice, how to track iterations, and patterns for when you're stuck.

---

## Time to Question (ttQ) and Time to Answer (ttA)

Two metrics define the efficiency of the cycle:

- **ttQ** — how quickly you formulate a meaningful, actionable question
- **ttA** — how quickly you obtain an answer (by building a view, running a script, etc.)

These are not formal measurements. They are mental models for understanding where your energy goes.

### The economics

When ttA is high (manual exploration, reading code line by line, asking the one person who knows), you can only afford a few questions per day. Each question is a significant investment, so you tend to ask safe, broad questions — and hope one of a handful of approaches works. This is **brute-forcing with limited visibility**.

When ttA is low (micro-tools built in minutes, AI-generated views), the dynamics change:

1. **More questions per unit of energy.** Instead of 2-3 careful attempts, you try dozens.
2. **Bolder questions.** When the cost of a failed attempt is near zero, you ask questions you wouldn't have risked before.
3. **Energy shifts to ttQ.** With answers cheap, the bottleneck moves to formulating better questions. This is where the real skill develops.
4. **The adjacent unexplored opens up.** Each answer reveals questions you didn't know to ask. With cheap ttA, you can follow those threads immediately instead of filing them for "later" (which means never).

### The trap

Organizations obsess over action metrics (deployment frequency, lead time, time to recovery) while ignoring how long it takes to formulate a hypothesis and test it. DORA metrics measure how fast you ship — not how well you understand what you're shipping.

---

## The Adjacent Unexplored

Every answer reveals new territory. The original question ("why is this slow?") leads to an answer ("this service calls that other service 47 times per request") which reveals a question nobody had considered ("why does it call 47 times? is the contract wrong, or is the caller wrong?").

This is not linear (question → answer → done). It branches:

```
Q1 → A1 → Q2a, Q2b, Q2c
              Q2a → A2a → Q3a, Q3b
              Q2b → A2b → (resolved — the answer was sufficient)
              Q2c → (parked — not relevant right now)
```

Not every branch needs following. The skill is in recognizing which new question is most relevant to the decision you're trying to make.

### Tracking the trail

The view header convention (`# Question: ... / # Answer: ... / # Why: ...`) creates a physical trail of your exploration. When you return to a project after days or weeks, the trail shows:

- What questions you asked
- What answers you got (or didn't)
- Which questions led to decisions, and which were dead ends
- Where you left off

This is more valuable than git history because it captures the *reasoning*, not just the code changes.

---

## Patterns for When You're Stuck

### Investment before investigation

When your current tooling cannot answer your question, stop investigating and invest in building visibility first.

**The stuck cursor example** (from Feenk): A text editor bug persisted for six months despite repeated investigation. The team couldn't see what they needed — the bug crossed a language boundary (Smalltalk/Rust) and their tools only covered one side. Once they invested in building a Rust inspector, a completely *different* question emerged ("are ranges inclusive on both ends?") — and the fix was a single character change.

The lesson: if you've been stuck on a question for a long time, the problem is probably not the question but the lack of visibility. Build the tool to see, then the question will reformulate itself.

### Describe, then identify gaps

For hard problems — the ones where you can't even formulate a question:

1. **Describe** what you currently know about the system, as precisely as you can
2. **Identify** the gaps: what can't you see? what do you have to hold in your head? what do you take on faith?
3. **Pick one gap** and build a view that fills it
4. **Look** at what the view reveals. The right question will emerge.

This is the methodology for when "I don't know what I don't know." You start from what you DO know and systematically identify the boundaries of your knowledge.

### Noun-verb, not verb-noun

Start from WHAT you're looking at (the object, the entity, the context), not from WHAT you want to do (the action). "Show me this Controller's dependencies" not "Find all dependencies." The object determines the relevant questions and views, not the other way around.

---

## Belief vs. Evidence

Traditional software understanding relies on beliefs: "I think the architecture looks like this", "this component probably handles that", "the docs say...". Moldable development replaces belief with evidence: "here is a generated view of the actual dependencies", "this micro-tool shows exactly which component handles X", "the live system shows...".

The analogy from the Rewilding book: this is the difference between a painting (manual, interpretive, reflects the artist's beliefs) and a photograph (generated, representative, reflects reality). Both have value, but when you need to make a decision about a system, you want the photograph.

Views built from the actual codebase or runtime are representative by construction. They can still be misleading (wrong analysis, incomplete data), but they are grounded in reality rather than memory.

---

## The Two Wolves

The Rewilding series frames two challenges:

1. **Wolf 1: Mechanics** — "Can I build views cheaply?" This is the easier wolf. AI agents (like Claude) make micro-tool creation near-free. The skill's output modes and analysis depths address this wolf.

2. **Wolf 2: Methodology** — "Am I asking productive questions?" This is the harder wolf, and where the real value lies. Most developers assume Wolf 1 is the bottleneck. In practice, once views are cheap to build, the bottleneck shifts entirely to question quality.

The skill addresses both, but if you only engage with one, engage with Wolf 2.
