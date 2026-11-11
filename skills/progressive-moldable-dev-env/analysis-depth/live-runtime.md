# Live Runtime Analysis

**Analysis of the running application.** Requires the app to be running. Exposes live beans, DI containers, active connections, metrics, request traces.

## What This Adds Over Native Compiler

Static analysis (native compiler) tells you what the code *says*. Live runtime analysis tells you what the application *does* — which beans are actually loaded, which routes are active, what configuration is in effect, what connections are open.

## Two Approaches

### Introspection Endpoints (Recommended Start)

Add analysis endpoints to the running app itself:

```
Kotlin Spring Boot app → /dev/analyze/dependencies
C# ASP.NET app        → /dev/analyze/services
Python FastAPI app     → /dev/analyze/ast
```

These can be consumed by any output mode — terminal views polling the endpoint, web views with HTMX refreshing from it, or playgrounds feeding live objects into the UI.

### Reflection / DI Container Inspection

Query the runtime's object graph directly:
- **JVM:** Spring `ApplicationContext.getBeansOfType()`, JMX MBeans
- **.NET:** `IServiceProvider` inspection, middleware pipeline
- **Python:** `inspect` module on live objects, `gc.get_objects()`
- **Ruby:** `ObjectSpace.each_object`, method introspection
- **Elixir/BEAM:** Process inspection, `:observer`, `:sys.get_state()`

## When to Use

- You need runtime state that doesn't exist in code (which DI bindings are actually active, which config profile is loaded)
- You need request tracing (what actually happens when endpoint X is called)
- You need metrics (response times, connection pool state, queue depths)
- You're building toward a domain playground that feeds real live objects

## Trade-offs

| Benefit                                | Cost                                              |
|----------------------------------------|---------------------------------------------------|
| Always-fresh data                      | App must be compiled and running                  |
| Runtime state not visible in code      | If the app crashes, your views go dark            |
| Smooth path to domain playgrounds      | Analysis endpoints need maintenance               |
| Real DI graph (not just declared)      | Latency on complex analysis                       |

## Pragmatic Guidance

The file-watching + static analysis approach (native compiler) covers most needs and has no runtime dependency. Use live runtime when you specifically need runtime state (DI graphs, active configuration, request tracing) or when building toward domain playgrounds. Don't default to it — opt in for specific views that benefit from liveness.
