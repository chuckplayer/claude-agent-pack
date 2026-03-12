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

echo ""
echo "Next steps:"
echo ""
echo "  1. Copy CLAUDE.md to your project root:"
echo "     cp \"\$SCRIPT_DIR/CLAUDE.md\" ./CLAUDE.md"
echo ""
echo "  2. Copy docs:"
echo "     mkdir -p ./docs"
echo "     cp \"\$SCRIPT_DIR/docs/CONVENTIONS.template.md\" ./docs/CONVENTIONS.md"
echo "     cp \"\$SCRIPT_DIR/docs/MEMORY-WRITING.md\" ./docs/MEMORY-WRITING.md"
echo ""
echo "  3. Copy memory scaffold:"
echo "     cp -r \"\$SCRIPT_DIR/memory\" ."
echo ""
echo "  4. In Claude Code, try: /agent-plan add a payment processing feature"
echo ""
echo "To verify: open Claude Code and run /agents -- your new agents should appear in the list."
