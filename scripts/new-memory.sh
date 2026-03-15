#!/usr/bin/env bash
set -euo pipefail

VALID_SUBDIRS="decisions architecture context known-issues"

declare -A TYPE_MAP=(
    [decisions]="decision"
    [architecture]="finding"
    [context]="constraint"
    [known-issues]="finding"
)

SUBDIR="${1:-}"
SLUG="${2:-}"
MEMORY_DIR="${3:-$(pwd)/memory}"

usage() {
    echo "Usage: new-memory.sh <subdir> <slug> [memory-dir]"
    echo ""
    echo "  subdir      One of: decisions, architecture, context, known-issues"
    echo "  slug        Brief kebab-case identifier (e.g. auth-token-storage)"
    echo "  memory-dir  Path to memory/ directory (default: ./memory)"
    echo ""
    echo "Examples:"
    echo "  new-memory.sh decisions  auth-token-storage"
    echo "  new-memory.sh context    docker-compose-port-conflict"
    echo "  new-memory.sh known-issues  flaky-integration-test"
    exit 1
}

if [ -z "$SUBDIR" ] || [ -z "$SLUG" ]; then
    usage
fi

# Validate subdir
valid=false
for s in $VALID_SUBDIRS; do
    [ "$s" = "$SUBDIR" ] && valid=true && break
done
if [ "$valid" = "false" ]; then
    echo "ERROR: Invalid subdir '$SUBDIR'."
    echo "Must be one of: $VALID_SUBDIRS"
    exit 1
fi

# Validate slug (kebab-case, no spaces or special chars)
if ! echo "$SLUG" | grep -qE '^[a-z0-9][a-z0-9-]*$'; then
    echo "ERROR: Slug must be lowercase kebab-case (letters, numbers, hyphens only)."
    echo "  Got: $SLUG"
    exit 1
fi

TYPE="${TYPE_MAP[$SUBDIR]}"
DATE="$(date +%Y-%m-%d)"
FILENAME="${DATE}-${SLUG}.md"
FILEPATH="$MEMORY_DIR/$SUBDIR/$FILENAME"

if [ -f "$FILEPATH" ]; then
    echo "ERROR: File already exists: $FILEPATH"
    exit 1
fi

mkdir -p "$MEMORY_DIR/$SUBDIR"

cat > "$FILEPATH" << EOF
**Date:** $DATE
**Type:** $TYPE
**Status:** active
**Superseded-by:** n/a
**Scope:** global
**Overrides-convention:** no
**Related-to:** n/a

## Summary

<!-- One paragraph describing this $TYPE. -->

## Context

<!-- Why this situation arose or what drove this decision. -->

## Details

<!-- The specifics: what was decided, found, or constrained. -->

## Consequences

<!-- What this means for future work. What to watch out for. -->
EOF

echo "Created: $FILEPATH"
echo ""
echo "Next steps:"
echo "  1. Fill in the sections above."
echo "  2. Add a pointer to memory/MEMORY.md:"
echo "     | [$FILENAME](memory/$SUBDIR/$FILENAME) | <one-line description> |"
