# View Lifecycle — Disposable vs. Durable

Not all views are single-use. Understanding where a view falls on the lifecycle spectrum helps you decide how much to invest in it.

## The Spectrum

| Lifecycle          | Description                                                        | Example                                                    |
|--------------------|--------------------------------------------------------------------|------------------------------------------------------------|
| **Disposable**     | Built to answer one question, discarded after                      | "Show me this controller's dependencies" — look, answer, done |
| **Recurring**      | Same question comes back regularly, worth keeping                  | Weekly dependency drift check, sprint-start architecture scan |
| **Durable sensor** | Integrated into the development workflow as a permanent feedback loop | Pre-commit hook that visualizes coupling changes, CI gate that renders dependency impact |
| **Harness tool**   | Part of the agent harness infrastructure                           | A view that feeds data to other tools, a sensor that triggers alerts |

## Decision Guide

- **First time building a view?** Treat it as disposable. Don't invest in polish, error handling, or configuration.
- **Same view requested 3+ times?** Promote to recurring — save the script, add a filename, maybe a `Makefile` target.
- **View catches something important every time?** Promote to durable sensor — integrate into pre-commit, CI, or a monitoring loop.
- **Other tools depend on the view's output?** It's now a harness tool — treat it like infrastructure code.

## Terminal Views as Harness Sensors

Terminal views are not just for human consumption. A script that outputs structured data can also serve as:

- A **pre-commit hook** — run the analysis, fail if a threshold is exceeded
- A **CI gate** — produce a report artifact, fail the build on regressions
- An **agent input** — another AI agent reads the output to make decisions
- A **monitoring feed** — scheduled execution with alerts on anomalies

The same 20-line script that answers "how coupled is this module?" can become a permanent coupling sensor in the pipeline. The view graduates from exploration tool to quality gate.

## Implications

Don't assume a view's lifecycle at creation time. Build it as disposable, let usage reveal its value, promote when the pattern is clear. The cheapest views to build are also the cheapest to discard — and the ones that survive are worth investing in.
