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

# CLAUDE.md -- the consumer block, not this repository's own CLAUDE.md (which adds pack-development
# gates a consuming project does not have). Its long-form rules are read on demand from the pack's
# installed references (run install.sh if they are missing).
cp "$PACK_DIR/docs/CLAUDE.template.md" "$TARGET/CLAUDE.md"
echo "  [ok] CLAUDE.md  (from docs/CLAUDE.template.md)"

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

# docs/plans/ (durable plan spine)
mkdir -p "$TARGET/docs/plans"
touch "$TARGET/docs/plans/.gitkeep"
echo "  [ok] docs/plans/"

# memory/
for subdir in decisions architecture context known-issues; do
    mkdir -p "$TARGET/memory/$subdir"
    touch "$TARGET/memory/$subdir/.gitkeep"
    echo "  [ok] memory/$subdir/"
done

# The CLAUDE.md block points at long-form rules the pack installs. A missing install leaves that
# pointer dangling without any other symptom, so say so. A warning, not a failure: the scaffolding
# itself is complete, and the pack may be installed after.
if [ ! -f "$TARGET/.claude/agent-pack/references/orchestration-rules.md" ] \
   && [ ! -f "$HOME/.claude/agent-pack/references/orchestration-rules.md" ]; then
    echo ""
    echo "  [!!] The pack's long-form rules (agent-pack/references/) are not installed, so the"
    echo "       pointer in CLAUDE.md will not resolve. Run: bash \"$PACK_DIR/install.sh\""
    echo "       (add --scope project --project-dir <this project> to install into the project)"
fi

echo ""
echo "Done. Suggested next steps:"
echo "  1. Edit docs/CONVENTIONS.md to match your project's conventions."
echo "  2. Commit: git add CLAUDE.md docs/ memory/ && git commit -m 'chore: add Claude Agent Pack scaffolding'"
echo "  3. In Claude Code, run /onboard to get oriented."
