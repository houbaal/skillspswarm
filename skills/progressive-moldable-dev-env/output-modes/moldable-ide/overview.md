# Moldable IDE — True Moldable Development (The North Star)

**Philosophy:** This is moldable development as defined by Nierstrasz and Girba — a fully integrated environment where development happens by inspecting and molding live objects, where the IDE itself is moldable, and where custom tools are intrinsic to the software system.

## What This Adds Over Live View Coding

- **Moldable Tool** — the IDE tools (inspector, debugger, editor, notebook) are themselves moldable. They dynamically discover custom views, searches, and actions from the objects they encounter — via annotations, conventions, or metadata on the objects themselves. You don't configure the tool; the object tells the tool how to display itself.
- **Moldable Object as development center** — you don't edit files and run them. You inspect a live object, prototype code in a contextual playground bound to that object's state, extract working code as methods, and continue. Development is object-centric, not file-centric.
- **Contextual Playground** — a live programming interface bound to the state of a specific object instance. `self` refers to the object you're inspecting. You prototype, explore, and test in the context of a real, live domain entity.
- **Project Diary (Lepiter)** — a knowledge management system where you interleave prose, live code snippets, and embedded views. The diary is the starting point for every development task, the progress tracker, and eventually the documentation. It is alive — the code runs, the views update, the examples are executable.
- **Composed Narrative** — a sequence of connected views that tells a story. Not a screenshot — a live, reproducible path through the system. Shareable, repeatable, and grounded in real objects.

## Implementations

| Implementation                    | Status       | Detail                                      |
|-----------------------------------|--------------|---------------------------------------------|
| **Glamorous Toolkit**             | Operational  | `glamorous-toolkit/` — full setup + codegen |

As of today, **Glamorous Toolkit is the only complete implementation** of this level. It runs on Pharo Smalltalk, which provides the unified "image" model where environment and system share the same runtime. This is not easily replicated in mainstream languages — not because of missing features, but because of the fundamental architecture: in Smalltalk, everything is an object in a live image; in most other languages, there is a compilation step, a file system, and a process boundary separating the IDE from the running code.

## Future Possibility

Could AI agents bridge this gap? An AI agent that can inspect live objects (via debugger APIs, reflection, REPL connections), generate views on the fly, and maintain a conversational "diary" of exploration might approximate the moldable IDE experience without requiring a Smalltalk-like platform. This remains an open area for investigation.
