# Context & Workflow Economy Practices (Group C)

How cost and noise are managed in the harness — the budget side of the discipline. For guiding principles, see `../principles.md`. For meta-principles that govern WHEN to add any of these, see the meta-principles section in the same file.

## Structured artifacts over prose

Prose drifts; structured data is easier for agents to read, write, and update without accidental rewrites. Specifically:
- Use JSON for feature tracking and state (agents overwrite Markdown more readily than they overwrite structured data)
- Use git commits as checkpoints — small, atomic, described
- Maintain progress files for long-running tasks so resuming is cheap

Anthropic's harness-for-long-running-agents pattern makes the mechanism concrete: a `feature_list.json` where the agent can only flip a boolean `passes` field per item, never edit test definitions. The asymmetry — write-restricted fields within a structured artifact — is what makes it drift-resistant. Markdown would invite the agent to rewrite the test definitions too.

## Sub-agents as context firewall

For complex tasks, structure work so that discrete sub-tasks run in isolated context windows. Intermediate noise (exploration, dead ends, verbose tool output) stays contained in the sub-agent and never pollutes the orchestrator's context.

Anthropic puts the case plainly: *"Since context is your fundamental constraint, subagents are one of the most powerful tools available. Subagents run in separate context windows and report back summaries."* The framing "context is your fundamental constraint" is worth internalising — everything else (model capability, tool access, speed) matters less than whether the right tokens are in the window at the right moment.

Typical split:
- Research sub-agent → outputs structured findings
- Implementation sub-agent → works from the findings + plan
- Review sub-agent → evaluates the output against the plan

The orchestrator only sees the summaries. This is how you prevent a 50k-token investigation from bleeding into the context that then has to make architectural decisions.
