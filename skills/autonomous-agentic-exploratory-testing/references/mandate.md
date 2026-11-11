# Agent Execution Mandate & Tools

## YOU — the AI agent — are the tester
Not the human. Not "the user". YOU.

This means:
- **YOU** open the browser / connect to the device / call the API
- **YOU** click buttons, fill forms, navigate screens
- **YOU** observe the results (read page text, take screenshots, check DOM)
- **YOU** read logs, query databases, check dashboards
- **YOU** write the report on disk
- **YOU** execute the entire session from start to finish

### Interaction Tools

| Action                      | How (use your tools)                                            |
|-----------------------------|------------------------------------------------------------------|
| Navigate to a URL           | `mcp__claude-in-chrome__navigate` or `mcp__claude-in-chrome__tabs_create_mcp` |
| Click a button / link       | `mcp__claude-in-chrome__computer` (click action)                |
| Type text into a field      | `mcp__claude-in-chrome__form_input` or `mcp__claude-in-chrome__computer` |
| Read what's on screen       | `mcp__claude-in-chrome__get_page_text` or `mcp__claude-in-chrome__read_page` |
| Take a screenshot           | `mcp__claude-in-chrome__computer` (screenshot action)           |
| Find an element             | `mcp__claude-in-chrome__find`                                   |
| Read console/logs           | `mcp__claude-in-chrome__read_console_messages`                  |
| Read network requests       | `mcp__claude-in-chrome__read_network_requests`                  |
| Run a CLI/backend command   | `Bash` tool                                                     |
| Query a database            | `Bash` tool (psql, sqlite3, etc.)                               |
| Read server logs            | `Bash` tool (tail, grep on log files)                           |
| Write the report            | `Write` / `Edit` tools                                          |
| Describe a screenshot       | Launch a sub-agent (Agent tool) that reads the image file       |

### Tool Failure Protocol
If a tool is unavailable or fails, **say which tool failed and why**, then try an alternative. Only ask the human for help as a LAST RESORT after exhausting all tool options.

### Pre-session tool check
Before anything else, verify your tools work:
1. Call `mcp__claude-in-chrome__tabs_context_mcp` to see current browser state.
2. If no browser tabs: create one with `mcp__claude-in-chrome__tabs_create_mcp`.
3. If browser tools are unavailable: fall back to CLI-based testing (curl, API calls, Bash).
4. If the app is mobile-only with no web version: use ADB commands via Bash.
5. **If NO interaction tool works at all**: report the blocker explicitly.

---
**Perception Gap**: Transitions, animations, and temporary messages (2-second toasts) are invisible between two observations. Never assume you've seen everything.
