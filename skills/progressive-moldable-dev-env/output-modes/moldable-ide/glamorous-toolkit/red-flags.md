# Glamorous Toolkit — Common Failures

| Symptom                            | Cause                                    | Fix                                            |
|------------------------------------|------------------------------------------|------------------------------------------------|
| `Undeclared variable -> ClassName` | Class name resolved at compile time      | Use `Smalltalk globals at: #ClassName`         |
| GT opens but no Inspector          | Script error swallowed silently           | Test with headless `eval` first (no `--interactive`) |
| GT doesn't open at all             | Wrong working directory                  | MUST `cd` into GT install dir before CLI        |
| `fileIn` errors                    | Wrong file format                        | NEVER use `fileIn` — use `Smalltalk compiler evaluate:` |
| Quotes broken in compiled methods  | Single quotes not doubled                | All `'` inside `compile:` strings become `''`  |
