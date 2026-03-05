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

VERSION=$(cat "$SCRIPT_DIR/VERSION")
echo "Claude Agent Pack v$VERSION"
echo ""

for agent_file in "$SCRIPT_DIR/agents/"*.md; do
    filename="$(basename "$agent_file")"
    cp "$agent_file" "$AGENTS_DIR/$filename"
    echo "  [ok] ${filename%.md}"
done

echo ""
echo "Next steps:"
echo ""
echo "  1. Copy CLAUDE.md to your project root:"
echo "     cp \"\$SCRIPT_DIR/CLAUDE.md\" ./CLAUDE.md"
echo ""
echo "  2. Copy CONVENTIONS template:"
echo "     mkdir -p ./docs"
echo "     cp \"\$SCRIPT_DIR/docs/CONVENTIONS.template.md\" ./docs/CONVENTIONS.md"
echo ""
echo "  3. Copy memory scaffold:"
echo "     cp -r \"\$SCRIPT_DIR/memory\" ."
echo ""
echo "  4. In Claude Code, try: Use the tech-lead agent to plan this feature"
echo ""
echo "To verify: open Claude Code and run /agents -- your new agents should appear in the list."
