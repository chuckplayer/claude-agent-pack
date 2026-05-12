#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_DIR="$(dirname "$SCRIPT_DIR")"

PASS=0
FAIL=0

# Validate pack directory
if [ ! -d "$PACK_DIR/agents" ] || [ ! -d "$PACK_DIR/skills" ]; then
    echo "Error: agents/ and skills/ directories not found in $PACK_DIR"
    echo "Run this script from the pack repository root: bash scripts/lint-agents.sh"
    exit 1
fi

# Valid frontmatter fields by file type
AGENT_VALID_FIELDS="name description tools model effort permissionMode version"
SKILL_VALID_FIELDS="name description model effort"

pass() {
    echo "  [ok] $1"
    PASS=$((PASS + 1))
}

fail() {
    echo "  [!!] $1  -- $2"
    FAIL=$((FAIL + 1))
}

# Extract the value of a frontmatter field from a file.
# Returns empty string if not found.
get_field() {
    local file="$1"
    local field="$2"
    # Match lines like: field: value  OR  field: >  (multi-line)
    local val
    val=$(awk "/^---/{fm++} fm==1 && /^${field}:/{found=1; sub(/^${field}:[[:space:]]*/,\"\"); print; exit} /^---/{if(fm>=2)exit}" "$file" 2>/dev/null || true)
    echo "$val"
}

# Check if a frontmatter field is present (non-empty line starting with field:)
has_field() {
    local file="$1"
    local field="$2"
    awk "/^---/{fm++} fm==1 && /^${field}:/{found=1; exit} /^---/{if(fm>=2)exit} END{exit !found}" "$file" 2>/dev/null
}

# Check for unknown frontmatter fields
unknown_fields() {
    local file="$1"
    local valid="$2"
    awk '
        /^---/{fm++; next}
        fm==1 && /^[a-zA-Z]/{
            key=$0; sub(/:.*$/,"",key)
            print key
        }
        fm>=2{exit}
    ' "$file" 2>/dev/null | while read -r key; do
        local found=0
        for v in $valid; do
            [ "$key" = "$v" ] && found=1 && break
        done
        [ "$found" -eq 0 ] && echo "$key"
    done || true
}

# Count body content lines (after the closing ---)
body_line_count() {
    local file="$1"
    awk '/^---/{fm++; next} fm>=2{lines++} END{print lines+0}' "$file" 2>/dev/null || echo 0
}

# Get description length (handles multi-line > style)
description_length() {
    local file="$1"
    # Extract everything between description: and the next top-level key or closing ---
    awk '
        /^---/{fm++; next}
        fm==1 && /^description:/{in_desc=1; sub(/^description:[[:space:]]*/,""); if($0!=">" && $0!=""){buf=buf $0}; next}
        fm==1 && in_desc && /^[[:space:]]/{buf=buf " " $0; next}
        fm==1 && in_desc{in_desc=0}
        fm>=2{exit}
        END{print length(buf)}
    ' "$file" 2>/dev/null || echo 0
}

lint_file() {
    local file="$1"
    local type="$2"  # "agent" or "skill"
    local label
    label="$(basename "$(dirname "$file")")/$(basename "$file")"
    [ "$type" = "agent" ] && label="agents/$(basename "$file")"

    local file_pass=1

    # Check required: name
    if ! has_field "$file" "name"; then
        fail "$label" "Missing required field: \`name\`"
        file_pass=0
    fi

    # Check required: description
    if ! has_field "$file" "description"; then
        fail "$label" "Missing required field: \`description\`"
        file_pass=0
    else
        local desc_len
        desc_len=$(description_length "$file")
        if [ "$desc_len" -gt 1536 ]; then
            fail "$label" "Description exceeds 1536 characters (${desc_len} chars)"
            file_pass=0
        fi
    fi

    # Check for unknown fields
    local valid_fields
    [ "$type" = "agent" ] && valid_fields="$AGENT_VALID_FIELDS" || valid_fields="$SKILL_VALID_FIELDS"
    local unknown
    unknown=$(unknown_fields "$file" "$valid_fields")
    if [ -n "$unknown" ]; then
        for f in $unknown; do
            fail "$label" "Unknown frontmatter field: \`$f\`"
            file_pass=0
        done
    fi

    # Check body content exists
    local body_lines
    body_lines=$(body_line_count "$file")
    if [ "$body_lines" -lt 3 ]; then
        fail "$label" "Missing body content (found ${body_lines} lines after frontmatter)"
        file_pass=0
    fi

    [ "$file_pass" -eq 1 ] && pass "$label"
}

echo "Claude Agent Pack -- Lint Check"
echo ""

# Lint agents
echo "-- Agents"
agent_count=0
for agent_file in "$PACK_DIR/agents/"*.md; do
    [ -f "$agent_file" ] || continue
    agent_count=$((agent_count + 1))
    lint_file "$agent_file" "agent"
done
[ "$agent_count" -eq 0 ] && echo "  (no agent files found)"

echo ""

# Lint skills
echo "-- Skills"
skill_count=0
for skill_dir in "$PACK_DIR/skills/"*/; do
    skill_file="$skill_dir/SKILL.md"
    [ -f "$skill_file" ] || continue
    skill_count=$((skill_count + 1))
    lint_file "$skill_file" "skill"
done
[ "$skill_count" -eq 0 ] && echo "  (no skill files found)"

echo ""
echo "----"
echo "  $PASS passed, $FAIL failed"
echo ""

[ "$FAIL" -eq 0 ] || exit 1
