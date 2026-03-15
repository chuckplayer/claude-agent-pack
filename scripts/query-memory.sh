#!/usr/bin/env bash
set -euo pipefail

PATTERN="${1:-}"
MEMORY_DIR="${2:-$(pwd)/memory}"

if [ -z "$PATTERN" ]; then
    echo "Usage: query-memory.sh <pattern> [memory-dir]"
    echo ""
    echo "  pattern     Text or regex to search for (case-insensitive)"
    echo "  memory-dir  Path to memory/ directory (default: ./memory)"
    echo ""
    echo "Skips files with status: superseded or archived."
    exit 1
fi

if [ ! -d "$MEMORY_DIR" ]; then
    echo "ERROR: Memory directory not found: $MEMORY_DIR"
    echo "Run scripts/setup-project.sh to scaffold the memory/ structure."
    exit 1
fi

found=0

while IFS= read -r -d '' file; do
    # Skip superseded/archived files
    status=$(grep -i '^\*\*Status:\*\*' "$file" 2>/dev/null | head -1 \
        | sed 's/.*\*\*Status:\*\*[[:space:]]*//' | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
    if [ "$status" = "superseded" ] || [ "$status" = "archived" ]; then
        continue
    fi

    # Search for pattern (case-insensitive)
    if grep -qiE "$PATTERN" "$file" 2>/dev/null; then
        echo "=== $file"
        grep -niE "$PATTERN" "$file" | head -10
        echo ""
        found=$((found + 1))
    fi
done < <(find "$MEMORY_DIR" -name "*.md" -print0 2>/dev/null | sort -z)

if [ "$found" -eq 0 ]; then
    echo "No results for: $PATTERN"
    exit 1
fi

echo "$found file(s) matched."
