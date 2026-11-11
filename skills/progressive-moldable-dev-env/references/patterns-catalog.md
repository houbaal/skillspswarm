# Moldable Development Patterns — Catalog (IN CONSTRUCTION)

The authoritative pattern language defines 15 patterns in three categories. See `references/external-sources.md` for the source paper.

## Tooling Patterns
- **Moldable Tool** — Make development tools dynamically customizable by the artifacts they encounter
- **Contextual Playground** — A live programming interface bound to the state of a specific object
- **Custom View** — A dedicated view of an object to display domain-specific information
- **Custom Search** — An ad hoc query over objects reachable from a given moldable object
- **Custom Action** — A domain-specific action encapsulated as a button in a moldable tool
- **Composed Narrative** — A story built by navigating through connected views

## Modeling Patterns
- **Moldable Object** — A live instance explored and molded with custom tools
- **Example Object** — A unit test that returns the tested object (see `references/example-objects.md`)
- **Moldable Data Wrapper** — A domain class wrapping raw data to make it moldable
- **Moldable Collection Wrapper** — A domain collection wrapping query results to make them moldable

## Process Patterns
- **Project Diary** — A live notebook as the starting point for all tasks
- **Tooling Buildup** — Acquiring the basic tools before starting moldable exploration
- **Blind Spot** — Finding the part of the system that creates the most problems
- **Simple View** — Always start with the simplest view that answers the current question
- **Throwaway Analysis Tool** — A dedicated, single-use tool for a specific problem

*Adoption guidance per output mode, trade-off analysis, and implementation examples for each pattern are planned for future iterations.*
