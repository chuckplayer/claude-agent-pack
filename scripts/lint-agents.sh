#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_DIR="$(dirname "$SCRIPT_DIR")"

pass=0
fail=0

check_field() {
    local file="$1"
    local field="$2"
    if ! grep -qE "^${field}:" "$file" 2>/dev/null; then
        echo "    MISSING field: $field"
        return 1
    fi
    return 0
}

echo "Claude Agent Pack -- Agent & Skill Linter"
echo ""

echo "-- Agents"
for agent_file in "$PACK_DIR/agents/"*.md; do
    name="$(basename "${agent_file%.md}")"
    errors=0
    echo "  $name"

    # Frontmatter must open with ---
    if ! head -1 "$agent_file" | grep -qE "^---$"; then
        echo "    MISSING: frontmatter opening ---"
        errors=$((errors + 1))
    fi

    for field in name description tools model; do
        check_field "$agent_file" "$field" || errors=$((errors + 1))
    done

    # Must have body content after the closing ---
    body_lines=0
    fm_count=0
    while IFS= read -r line; do
        if [ "$line" = "---" ]; then
            fm_count=$((fm_count + 1))
            continue
        fi
        if [ "$fm_count" -ge 2 ] && [ -n "$(echo "$line" | tr -d '[:space:]')" ]; then
            body_lines=$((body_lines + 1))
        fi
    done < "$agent_file"

    if [ "$body_lines" -eq 0 ]; then
        echo "    MISSING: agent instructions body (no content after frontmatter)"
        errors=$((errors + 1))
    fi

    if [ "$errors" -eq 0 ]; then
        echo "    [ok]"
        pass=$((pass + 1))
    else
        fail=$((fail + 1))
    fi
done

echo ""
echo "-- Skills"
for skill_dir in "$PACK_DIR/skills/"*/; do
    name="$(basename "$skill_dir")"
    skill_file="$skill_dir/SKILL.md"
    errors=0
    echo "  $name"

    if [ ! -f "$skill_file" ]; then
        echo "    MISSING: SKILL.md"
        fail=$((fail + 1))
        continue
    fi

    line_count=$(wc -l < "$skill_file")
    if [ "$line_count" -lt 5 ]; then
        echo "    WARNING: SKILL.md is very short ($line_count lines)"
        errors=$((errors + 1))
    fi

    if [ "$errors" -eq 0 ]; then
        echo "    [ok]"
        pass=$((pass + 1))
    else
        fail=$((fail + 1))
    fi
done

echo ""
echo "----"
echo "  $pass passed, $fail failed"
echo ""

[ "$fail" -eq 0 ] || exit 1
