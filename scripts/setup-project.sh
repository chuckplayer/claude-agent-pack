#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_DIR="$(dirname "$SCRIPT_DIR")"

TARGET="${1:-$(pwd)}"

if [ ! -d "$TARGET" ]; then
    echo "ERROR: Target directory not found: $TARGET"
    exit 1
fi

echo "Claude Agent Pack -- Project Setup"
echo "Target: $TARGET"
echo ""

# CLAUDE.md
cp "$PACK_DIR/CLAUDE.md" "$TARGET/CLAUDE.md"
echo "  [ok] CLAUDE.md"

# docs/
mkdir -p "$TARGET/docs"
if [ ! -f "$TARGET/docs/CONVENTIONS.md" ]; then
    cp "$PACK_DIR/docs/CONVENTIONS.template.md" "$TARGET/docs/CONVENTIONS.md"
    echo "  [ok] docs/CONVENTIONS.md  (from template)"
else
    echo "  [--] docs/CONVENTIONS.md already exists, skipped"
fi
cp "$PACK_DIR/docs/MEMORY-WRITING.md" "$TARGET/docs/MEMORY-WRITING.md"
echo "  [ok] docs/MEMORY-WRITING.md"

# memory/
for subdir in decisions architecture context known-issues; do
    mkdir -p "$TARGET/memory/$subdir"
    touch "$TARGET/memory/$subdir/.gitkeep"
    echo "  [ok] memory/$subdir/"
done

echo ""
echo "Done. Suggested next steps:"
echo "  1. Edit docs/CONVENTIONS.md to match your project's conventions."
echo "  2. Commit: git add CLAUDE.md docs/ memory/ && git commit -m 'chore: add Claude Agent Pack scaffolding'"
echo "  3. In Claude Code, run /onboard to get oriented."
