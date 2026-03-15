#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_DIR="${1:-$(pwd)}"

PASS=0
FAIL=0

check() {
    local label="$1"
    local result="$2"  # "ok" or "fail"
    local detail="${3:-}"
    if [ "$result" = "ok" ]; then
        echo "  [ok] $label"
        PASS=$((PASS + 1))
    else
        echo "  [!!] $label${detail:+  -- $detail}"
        FAIL=$((FAIL + 1))
    fi
}

echo "Claude Agent Pack -- Readiness Check"
echo ""

# Claude Code
echo "-- Claude Code"
if [ -d "$HOME/.claude" ]; then
    check "~/.claude directory exists" "ok"
else
    check "~/.claude directory exists" "fail" "Install Claude Code first: https://claude.ai/download"
fi

# Agents
echo ""
echo "-- Agents"
missing_agents=()
agent_count=0
for agent_file in "$PACK_DIR/agents/"*.md; do
    name="$(basename "$agent_file")"
    agent_count=$((agent_count + 1))
    if [ ! -f "$HOME/.claude/agents/$name" ]; then
        missing_agents+=("${name%.md}")
    fi
done
if [ ${#missing_agents[@]} -eq 0 ]; then
    check "All $agent_count agents installed" "ok"
else
    check "Agents installed ($((agent_count - ${#missing_agents[@]}))/$agent_count)" "fail" \
        "Missing: ${missing_agents[*]}  -- run ./install.sh"
fi

# Skills
echo ""
echo "-- Skills"
missing_skills=()
skill_count=0
for skill_dir in "$PACK_DIR/skills/"*/; do
    name="$(basename "$skill_dir")"
    skill_count=$((skill_count + 1))
    if [ ! -f "$HOME/.claude/skills/$name/SKILL.md" ]; then
        missing_skills+=("$name")
    fi
done
if [ ${#missing_skills[@]} -eq 0 ]; then
    check "All $skill_count skills installed" "ok"
else
    check "Skills installed ($((skill_count - ${#missing_skills[@]}))/$skill_count)" "fail" \
        "Missing: ${missing_skills[*]}  -- run ./install.sh"
fi

# Project scaffolding
echo ""
echo "-- Project ($PROJECT_DIR)"
[ -f "$PROJECT_DIR/CLAUDE.md" ]              && check "CLAUDE.md"               "ok" || check "CLAUDE.md"               "fail" "run scripts/setup-project.sh"
[ -f "$PROJECT_DIR/docs/CONVENTIONS.md" ]    && check "docs/CONVENTIONS.md"     "ok" || check "docs/CONVENTIONS.md"     "fail" "run scripts/setup-project.sh"
[ -f "$PROJECT_DIR/docs/MEMORY-WRITING.md" ] && check "docs/MEMORY-WRITING.md"  "ok" || check "docs/MEMORY-WRITING.md"  "fail" "run scripts/setup-project.sh"
for subdir in decisions architecture context known-issues; do
    [ -d "$PROJECT_DIR/memory/$subdir" ] \
        && check "memory/$subdir/" "ok" \
        || check "memory/$subdir/" "fail" "run scripts/setup-project.sh"
done

echo ""
echo "----"
echo "  $PASS passed, $FAIL failed"
echo ""

[ "$FAIL" -eq 0 ] || exit 1
