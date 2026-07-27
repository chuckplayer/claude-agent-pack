#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_DIR="$(dirname "$SCRIPT_DIR")"

CLAUDE_AGENTS="$HOME/.claude/agents"
CLAUDE_SKILLS="$HOME/.claude/skills"

up_to_date=0
outdated=0
not_installed=0

echo "Claude Agent Pack -- Update Check"
echo ""

echo "-- Agents"
for agent_file in "$PACK_DIR/agents/"*.md; do
    name="$(basename "$agent_file")"
    label="${name%.md}"
    installed="$CLAUDE_AGENTS/$name"

    if [ ! -f "$installed" ]; then
        echo "  [--] $label  (not installed)"
        not_installed=$((not_installed + 1))
    elif diff -q "$agent_file" "$installed" > /dev/null 2>&1; then
        echo "  [ok] $label"
        up_to_date=$((up_to_date + 1))
    else
        echo "  [!!] $label  (outdated)"
        outdated=$((outdated + 1))
    fi
done

echo ""
echo "-- Skills"
for skill_dir in "$PACK_DIR/skills/"*/; do
    name="$(basename "$skill_dir")"
    src="$skill_dir/SKILL.md"
    installed="$CLAUDE_SKILLS/$name/SKILL.md"

    if [ ! -f "$installed" ]; then
        echo "  [--] $name  (not installed)"
        not_installed=$((not_installed + 1))
    elif diff -q "$src" "$installed" > /dev/null 2>&1; then
        echo "  [ok] $name"
        up_to_date=$((up_to_date + 1))
    else
        echo "  [!!] $name  (outdated)"
        outdated=$((outdated + 1))
    fi
done

echo ""
echo "-- Obsidian hooks"
for hook in obsidian-stop-hook obsidian-prompt-hook obsidian-agent-hook obsidian-context-hook obsidian-memory-hook; do
    HOOK_SRC="$PACK_DIR/scripts/${hook}.js"
    HOOK_INSTALLED="$HOME/.claude/scripts/${hook}.js"
    if [ ! -f "$HOOK_INSTALLED" ]; then
        echo "  [--] ${hook}.js  (not installed — run install.sh)"
        not_installed=$((not_installed + 1))
    elif diff -q "$HOOK_SRC" "$HOOK_INSTALLED" > /dev/null 2>&1; then
        echo "  [ok] ${hook}.js"
        up_to_date=$((up_to_date + 1))
    else
        echo "  [!!] ${hook}.js  (outdated — run install.sh)"
        outdated=$((outdated + 1))
    fi
done

echo ""
echo "----"
echo "  $up_to_date up to date, $outdated outdated, $not_installed not installed"
echo ""

if [ "$outdated" -gt 0 ] || [ "$not_installed" -gt 0 ]; then
    echo "Run ./install.sh to update."
    exit 1
fi
