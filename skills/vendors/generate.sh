#!/bin/bash
# Generate CAPABILITIES.md — catalog of locally available skills, agents, and tools.
# Idempotent. Output is gitignored. Safe to run from any directory.
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$(dirname "$SCRIPT_DIR")"
CLAUDE_DIR="$(dirname "$SKILLS_DIR")"
OUTPUT="$SCRIPT_DIR/CAPABILITIES.md"

# Path prefix: ~ for global install, .claude for project-local
if [ "$(cd "$CLAUDE_DIR" && pwd)" = "$(cd "$HOME/.claude" 2>/dev/null && pwd)" ]; then
    P="~/.claude"
else
    P=".claude"
fi

# --- Portable md5 ---
compute_hash() {
    if command -v md5 >/dev/null 2>&1; then
        md5 -q
    else
        md5sum | cut -d' ' -f1
    fi
}

# --- Staleness hash ---
HASH=$( {
    ls -1d "$SKILLS_DIR"/*/ 2>/dev/null | while read -r d; do basename "$d"; done
    ls -1d "$CLAUDE_DIR/agents"/*/ 2>/dev/null | while read -r d; do basename "$d"; done
    ls -1d "$CLAUDE_DIR/vendors"/*/ 2>/dev/null | while read -r d; do basename "$d"; done
} | sort | compute_hash )
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# --- Helpers ---

# Extract description from YAML frontmatter (handles quoted/unquoted)
extract_desc() {
    sed -n '/^---$/,/^---$/{
        /^description:/{
            s/^description: *//
            s/^"//; s/"$//
            '"s/^'//; s/'$//"'
            p; q
        }
    }' "$1" 2>/dev/null || true
}

# Find main knowledge file (prefers non-SKILL.md content files)
find_knowledge_file() {
    local dir="$1" f
    f=$(find "$dir" -maxdepth 1 -name "*.md" \
        ! -name "SKILL.md" ! -name "README.md" ! -name "CAPABILITIES.md" \
        -print 2>/dev/null | sort | head -1)
    if [ -n "$f" ]; then echo "$f"; return; fi
    [ -f "$dir/SKILL.md" ] && echo "$dir/SKILL.md"
}

# Extract description with fallback: try the file, then try SKILL.md in same dir
extract_desc_with_fallback() {
    local file="$1" dir desc
    desc=$(extract_desc "$file")
    if [ -z "$desc" ]; then
        dir=$(dirname "$file")
        if [ -f "$dir/SKILL.md" ] && [ "$(basename "$file")" != "SKILL.md" ]; then
            desc=$(extract_desc "$dir/SKILL.md")
        fi
    fi
    echo "$desc"
}

# --- Generate ---
{
    printf '<!-- generated: %s -->\n' "$TIMESTAMP"
    printf '<!-- hash: %s -->\n\n' "$HASH"
    printf '# Available Capabilities\n\n'

    # === DevOpsCraft Skills ===
    buf=""
    for d in "$SKILLS_DIR"/devopscraft-*/; do
        [ -d "$d" ] || continue
        name=$(basename "$d")
        case "$name" in devopscraft-wip-*|devopscraft-vendors) continue ;; esac
        f=$(find_knowledge_file "$d")
        [ -n "$f" ] || continue
        desc=$(extract_desc_with_fallback "$f")
        [ -z "$desc" ] && desc="-"
        buf="${buf}| ${name} | ${P}/skills/${name}/$(basename "$f") | ${desc} |
"
    done
    if [ -n "$buf" ]; then
        printf '## DevOpsCraft Skills\n\n'
        printf '| Skill | Path | Description |\n'
        printf '|-------|------|-------------|\n'
        printf '%s\n' "$buf"
    fi

    # === Analysis Skills (non-devopscraft, non-vendor, non-nw) ===
    buf=""
    for d in "$SKILLS_DIR"/*/; do
        [ -d "$d" ] || continue
        name=$(basename "$d")
        case "$name" in devopscraft-*|nw-*|w|vendors) continue ;; esac
        f=$(find_knowledge_file "$d")
        [ -n "$f" ] || continue
        desc=$(extract_desc_with_fallback "$f")
        [ -z "$desc" ] && desc="-"
        buf="${buf}| ${name} | ${P}/skills/${name}/$(basename "$f") | ${desc} |
"
    done
    if [ -n "$buf" ]; then
        printf '## Analysis Skills\n\n'
        printf '| Skill | Path | Description |\n'
        printf '|-------|------|-------------|\n'
        printf '%s\n' "$buf"
    fi

    # === nWave Agents ===
    if [ -d "$CLAUDE_DIR/agents/nw" ]; then
        buf=""
        for f in "$CLAUDE_DIR/agents/nw"/*.md; do
            [ -f "$f" ] || continue
            name=$(basename "$f" .md)
            desc=$(extract_desc "$f")
            [ -z "$desc" ] && desc="-"
            buf="${buf}| ${name} | ${name} | ${desc} |
"
        done
        if [ -n "$buf" ]; then
            printf '## nWave Agents (subagent_type)\n\n'
            printf '| Agent | subagent_type | Description |\n'
            printf '|-------|---------------|-------------|\n'
            printf '%s\n' "$buf"
        fi
    fi

    # === Vendor Agents: andlaf (alf) ===
    if [ -d "$CLAUDE_DIR/vendors/andlaf" ]; then
        buf=""
        for d in "$CLAUDE_DIR/vendors/andlaf"/alf-*/; do
            [ -d "$d" ] || continue
            name=$(basename "$d")
            f=$(find "$d" -maxdepth 1 -name "*.md" ! -name "README.md" -print 2>/dev/null | sort | head -1)
            [ -n "$f" ] || continue
            desc=$(extract_desc "$f")
            [ -z "$desc" ] && desc="-"
            buf="${buf}| ${name} | ${P}/vendors/andlaf/${name}/$(basename "$f") | ${desc} |
"
        done
        if [ -n "$buf" ]; then
            printf '## Vendor Agents: alf (andlaf)\n\n'
            printf '| Agent | Path | Description |\n'
            printf '|-------|------|-------------|\n'
            printf '%s\n' "$buf"
        fi
    fi

    # === Vendor Agents: citypaul ===
    if [ -d "$CLAUDE_DIR/vendors/citypaul/claude/.claude/agents" ]; then
        buf=""
        for f in "$CLAUDE_DIR/vendors/citypaul/claude/.claude/agents"/*.md; do
            [ -f "$f" ] || continue
            name=$(basename "$f" .md)
            [ "$name" = "README" ] && continue
            desc=$(extract_desc "$f")
            [ -z "$desc" ] && desc="-"
            buf="${buf}| ${name} | ${P}/vendors/citypaul/claude/.claude/agents/$(basename "$f") | ${desc} |
"
        done
        if [ -n "$buf" ]; then
            printf '## Vendor Agents: citypaul\n\n'
            printf '| Agent | Path | Description |\n'
            printf '|-------|------|-------------|\n'
            printf '%s\n' "$buf"
        fi
    fi

    # === Plugin Resources ===
    if [ -d "$CLAUDE_DIR/plugins/cache" ]; then
        buf=""
        for org_dir in "$CLAUDE_DIR/plugins/cache"/*/; do
            [ -d "$org_dir" ] || continue
            org=$(basename "$org_dir")
            for plugin_dir in "$org_dir"/*/; do
                [ -d "$plugin_dir" ] || continue
                plugin_name=$(basename "$plugin_dir")
                # Latest version by modification time
                latest=$(ls -td "$plugin_dir"/*/ 2>/dev/null | head -1)
                [ -n "$latest" ] && [ -d "$latest" ] || continue
                version=$(basename "$latest")

                # Agents in plugin
                if [ -d "$latest/agents" ]; then
                    for f in "$latest/agents"/*.md; do
                        [ -f "$f" ] || continue
                        name=$(basename "$f" .md)
                        desc=$(extract_desc "$f")
                        [ -z "$desc" ] && desc="-"
                        buf="${buf}| ${name} (${plugin_name}) | ${P}/plugins/cache/${org}/${plugin_name}/${version}/agents/$(basename "$f") | ${desc} |
"
                    done
                fi
            done
        done
        if [ -n "$buf" ]; then
            printf '## Plugin Resources\n\n'
            printf '| Resource | Path | Description |\n'
            printf '|----------|------|-------------|\n'
            printf '%s\n' "$buf"
        fi
    fi

} > "$OUTPUT"

lines=$(wc -l < "$OUTPUT" | tr -d ' ')
printf 'Generated: %s (%s lines, hash: %s)\n' "$OUTPUT" "$lines" "$HASH"
