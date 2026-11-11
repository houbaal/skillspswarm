# Wiring to Live Data

Connecting your domain objects to a live database enables querying and visualization of real data — the ultimate "concrete-first" approach. A `Customer` wrapper inspecting real DB rows, with views showing order history, support tickets, and payment patterns, is moldable development applied to the business domain.

## Progressive Levels of Data Access

| Level | Data Source              | Risk         | Use When                                                   |
|-------|--------------------------|--------------|-------------------------------------------------------------|
| 0     | Local / test DB          | None         | Default. Fast iteration, fake data, zero risk               |
| 1     | Staging DB               | Low          | Real schema, sanitized data, safe to experiment             |
| 2     | Production read replica  | Moderate     | Real data, no write risk, no primary impact                 |
| 3     | Production primary       | High         | Only for specific, audited, time-boxed queries              |

## Mandatory Guardrails for Level 2+

- **Read replica only** — never the primary
- **Query timeouts** — hard limit (e.g., 5s), enforced at connection level
- **Row limits** — all queries `LIMIT`-capped by default
- **PII masking** — views automatically mask sensitive fields unless explicitly unmasked with authorization
- **Audit trail** — log what was queried, by whom, when
- **Network isolation** — access through a dedicated, monitored path

## Pragmatic Recommendation

Start at Level 1 (staging). It gives 90% of the insight with 10% of the risk. Graduate to Level 2 (read replica) only when you have a specific question that staging data can't answer.
