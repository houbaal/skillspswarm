# Eight Core Principles — Expanded

These principles come from the authoritative pattern language (Nierstrasz & Girba, EuroPLoP 2024). They are independent of technology and output mode.

## 1. Start from concrete instances, not abstractions

Don't design a generic "dependency analyzer." Pick *this specific controller*, inspect *its specific dependencies*, and only generalize if the pattern repeats. The concrete instance reveals what matters; the abstraction hides it.

## 2. Think in domain entities, not files

Even when your implementation reads files from disk, your mental model should be: "I'm inspecting a *Controller* that *depends on* a *Service* that *implements* an *Interface*." The intermediate representation should model entities and relationships, not file paths and line numbers. Files are just where entities happen to live.

## 3. Wrap your data in domain concepts

Don't pass raw JSON blobs around. If your analysis produces data about controllers, make "Controller" a first-class concept in your representation — with its own identity, relationships, and views. This is the **Moldable Data Wrapper** pattern. Even a JSON object with `{"type": "controller", "id": "UserController", "endpoints": [...]}` is already a lightweight domain wrapper.

## 4. Navigate between entities — the inspector chain

A view of a controller should let you drill into its service dependencies. A service view should link to its interface definitions. Each entity leads to the next. Without navigation, you have a dashboard. With it, you have an explorable system. This is the single most important interaction pattern. See `references/cross-cutting-concerns.md` for design decisions on inspector chains.

## 5. Build narratives, not dashboards

A dashboard is a predetermined set of views for anticipated questions. A moldable environment answers questions you haven't anticipated yet. Even better: compose views into stories — a sequence of connected views that walk the reader through a chain of reasoning.

## 6. Views, searches, AND actions

The paper defines three kinds of custom tools: **Custom View** (display information), **Custom Search** (navigate between entities by name, content, or criteria), and **Custom Action** (perform a domain-specific operation). Most people only think about views. But searchability and actionability are what make an environment truly moldable.

## 7. Simple views first

Always start with the simplest view that answers your current question. A plain table. A flat list. A one-liner verdict. Elaborate only when there is a clear need. This follows the Goal/Question/Metric (GQM) principle: a view only exists because it answers a specific question supporting a specific goal.

## 8. Low-cost views are not waste

Building a dedicated, single-use tool to answer one question is not wasteful — it is the core practice. The alternative is manual exploration, which is slower and less reliable. If a view costs 5 minutes to generate (via AI) and saves 30 minutes of exploration, it has paid for itself on first use.

---

## Object-Centric vs. File-Centric Approaches

The authoritative paper is deeply **object-centric**: you inspect live domain objects, not source files. The Moldable Object is the central pattern.

In a progressive adoption, especially with terminal and web views, you will often work **file-centrically**: parsing source files, producing JSON, rendering views. This is a valid simplification.

| Approach          | Strengths                                                          | Limitations                                                           |
|-------------------|--------------------------------------------------------------------|-----------------------------------------------------------------------|
| **File-centric**  | Lower friction, no running app needed, works with any language     | Static view only, no runtime state, serialization boundary everywhere |
| **Object-centric**| Live state, richer navigation, no serialization boundary           | Requires running app, language-specific, higher setup cost            |

For terminal and web views, file-centric is the pragmatic default. For domain playgrounds and above, choose based on context. At the moldable IDE level, object-centric is the natural paradigm.
