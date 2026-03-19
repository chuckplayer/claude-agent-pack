#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CLAUDE_DIR="$HOME/.claude"
if [ ! -d "$CLAUDE_DIR" ]; then
    echo "ERROR: Claude Code directory not found at $CLAUDE_DIR"
    echo "Install Claude Code first: https://code.claude.com"
    exit 1
fi

AGENTS_DIR="$CLAUDE_DIR/agents"
mkdir -p "$AGENTS_DIR"

SKILLS_DIR="$CLAUDE_DIR/skills"
mkdir -p "$SKILLS_DIR"

VERSION=$(cat "$SCRIPT_DIR/VERSION")
echo "Claude Agent Pack v$VERSION"
echo ""

for agent_file in "$SCRIPT_DIR/agents/"*.md; do
    filename="$(basename "$agent_file")"
    cp "$agent_file" "$AGENTS_DIR/$filename"
    echo "  [ok] agent:  ${filename%.md}"
done

echo ""
for skill_dir in "$SCRIPT_DIR/skills/"*/; do
    skill_name="$(basename "$skill_dir")"
    mkdir -p "$SKILLS_DIR/$skill_name"
    cp "$skill_dir/SKILL.md" "$SKILLS_DIR/$skill_name/SKILL.md"
    echo "  [ok] skill:  $skill_name"
done

# Remove skills that were deprecated or merged in a previous version
deprecated_skills=("agent-plan" "challenge" "check-readiness" "check-updates")
deprecated_removed=0
for name in "${deprecated_skills[@]}"; do
    target="$SKILLS_DIR/$name"
    if [ -d "$target" ]; then
        rm -rf "$target"
        echo "  [rm] skill:  $name (deprecated)"
        deprecated_removed=$((deprecated_removed + 1))
    fi
done
[ "$deprecated_removed" -gt 0 ] && echo ""

echo ""
echo "Next steps:"
echo ""
echo "  1. Scaffold a project (copies CLAUDE.md, docs, and memory/ structure):"
echo "     $SCRIPT_DIR/scripts/setup-project.sh <your-project-path>"
echo ""
echo "  2. Verify everything is ready:"
echo "     $SCRIPT_DIR/scripts/check-readiness.sh <your-project-path>"
echo ""
echo "  3. In Claude Code, try: /plan add a payment processing feature"
echo ""
echo "To verify: open Claude Code and run /agents -- your new agents should appear in the list."
