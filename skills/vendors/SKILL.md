---
description: "Scan and catalog all locally available skills, agents, and tools into CAPABILITIES.md — used by consumer skills (mega-review, gap-detector, etc.) to discover resources dynamically — propose to the user before invoking"
---

# DevOpsCraft Vendors: Capability Catalog

Generate (or refresh) the `CAPABILITIES.md` file that lists all locally available skills, agents, and tools.

## What it does

Scans the local `.claude/` directory for:
- **DevOpsCraft skills** (plugin `devopscraft` — `${CLAUDE_PLUGIN_ROOT}/skills/*/`)
- **Analysis skills** (e.g., `test-design-reviewer`, `cognitive-load-analyzer`)
- **nWave agents** (`agents/nw/*.md`)
- **Vendor agents** (andlaf/alf, citypaul)
- **Plugin resources** (superpowers, etc.)

Only lists what is **actually installed**. Missing tools are simply absent from the catalog.

## Procedure

### 1. Staleness check

If `CAPABILITIES.md` already exists in this skill's directory:
1. Extract the `<!-- hash: ... -->` value from the file header
2. Recompute the hash by running: `bash ${CLAUDE_PLUGIN_ROOT}/skills/vendors/generate.sh 2>&1 | tail -1`
3. If the hash changed, the catalog is stale — regenerate
4. If the hash matches, the catalog is current — display it as-is

### 2. Generate

Run the generation script:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/vendors/generate.sh
```

### 3. Display

Read and display the generated `CAPABILITIES.md` file.

If {PROMPT} contains a filter keyword (e.g., "nwave", "alf", "devopscraft"), show only matching sections.

### 4. Report

Tell the user:
- How many resources were found in each category
- Whether the catalog was freshly generated or already current
- Suggest: "Consumer skills (mega-review, gap-detector, etc.) will use this catalog to discover available resources."
