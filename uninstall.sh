#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

AGENTS_DIR="$HOME/.claude/agents"

if [ ! -d "$AGENTS_DIR" ]; then
    echo "No agents directory found at $AGENTS_DIR -- nothing to remove."
    exit 0
fi

echo "The following agents will be removed from $AGENTS_DIR:"
echo ""

to_remove=()
for agent_file in "$SCRIPT_DIR/agents/"*.md; do
    filename="$(basename "$agent_file")"
    target="$AGENTS_DIR/$filename"
    if [ -f "$target" ]; then
        echo "  $filename"
        to_remove+=("$target")
    fi
done

if [ ${#to_remove[@]} -eq 0 ]; then
    echo "  (no matching agent files found)"
    exit 0
fi

echo ""
read -p "Remove these agents? [y/N] " response

if [ "$response" != "y" ] && [ "$response" != "Y" ]; then
    echo "Cancelled."
    exit 0
fi

echo ""
for path in "${to_remove[@]}"; do
    rm -f "$path"
    echo "  Removed: $(basename "$path")"
done

echo ""
echo "${#to_remove[@]} agent(s) removed."
echo ""
echo "Note: project-level memory/ directories are not removed -- those live"
echo "in your repositories and are managed like any other project file."
