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

# Configuration
echo ""
echo "-- Configuration"
json_tool=""
_try_json_tool() {
    command -v "$1" &>/dev/null || return 1
    case "$1" in
        python*) "$1" -c 'import sys; sys.exit(0)' &>/dev/null 2>&1 || return 1 ;;
        node)    "$1" -e  'process.exit(0)'         &>/dev/null 2>&1 || return 1 ;;
    esac
    json_tool="$1"
}
_try_json_tool python3 || _try_json_tool python || _try_json_tool node || true

base_ref=""
if [ -n "$json_tool" ] && [ -f "$HOME/.claude/settings.json" ]; then
    if [ "$json_tool" = "node" ]; then
        base_ref="$(node -e "
const fs=require('fs'),os=require('os'),path=require('path');
const p=path.join(os.homedir(),'.claude','settings.json');
try{const s=JSON.parse(fs.readFileSync(p,'utf8'));process.stdout.write((s.worktree&&s.worktree.baseRef)||'');}catch(e){}
" 2>/dev/null || true)"
    else
        base_ref="$("$json_tool" - <<'PYEOF' 2>/dev/null || true
import json, os
p = os.path.expanduser("~/.claude/settings.json")
try:
    s = json.load(open(p))
    print(s.get("worktree", {}).get("baseRef", ""), end="")
except Exception:
    pass
PYEOF
)"
    fi
fi

if [ "$base_ref" = "head" ]; then
    check "worktree.baseRef is \"head\"" "ok"
else
    check "worktree.baseRef is \"head\"" "fail" \
        "currently '${base_ref:-unset, defaults to fresh}' -- engineer worktrees (isolation:\"worktree\") will silently base off local/origin main instead of your feature branch. Re-run ./install.sh or add { \"worktree\": { \"baseRef\": \"head\" } } to ~/.claude/settings.json"
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

# Gate scripts. A missing checker is a stated gap, not a silent pass: any
# instruction to run one of these must degrade to "not applicable" when the file
# is absent, rather than being reported as clean.
echo ""
echo "-- Checks"
for script in lint-agents.sh lint-identifiers.sh lint-plans.sh lint-memory.sh; do
    if [ -f "$PACK_DIR/scripts/$script" ]; then
        check "scripts/$script" "ok"
    else
        check "scripts/$script" "fail" \
            "absent -- any step instructing it must report 'not applicable', never a pass. Re-run ./install.sh or update the pack."
    fi
done

echo ""
echo "----"
echo "  $PASS passed, $FAIL failed"
echo ""

[ "$FAIL" -eq 0 ] || exit 1
