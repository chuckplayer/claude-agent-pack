#!/usr/bin/env bash
# Obsidian auto-log Stop hook — runs when Claude Code session stops.
# Only writes if git has new commits or uncommitted changes since the last log.
# Always exits 0 — never blocks or errors visibly.
set -uo pipefail

# Guard: require vault path and directory
VAULT="${OBSIDIAN_VAULT_PATH:-}"
[ -z "$VAULT" ] && exit 0
[ ! -d "$VAULT" ] && exit 0

# Canonicalize vault path to prevent traversal
if command -v realpath &>/dev/null; then
    VAULT="$(realpath "$VAULT" 2>/dev/null || echo "$VAULT")"
elif command -v readlink &>/dev/null; then
    VAULT="$(readlink -f "$VAULT" 2>/dev/null || echo "$VAULT")"
fi

# Determine project context
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PROJECT_NAME="$(basename "$PROJECT_DIR")"
# Sanitize values that go into YAML frontmatter
PROJECT_DIR="$(echo "$PROJECT_DIR" | tr -d '\n\r')"
PROJECT_NAME="$(echo "$PROJECT_NAME" | tr -d '\n\r:#{}|>`')"
NOW="$(date '+%Y-%m-%dT%H:%M')"
DATE="$(date '+%Y-%m-%d')"
TIME="$(date '+%H:%M')"

# Get current git HEAD (empty if not a git repo)
HEAD_SHA=""
if git -C "$PROJECT_DIR" rev-parse HEAD &>/dev/null 2>&1; then
    HEAD_SHA="$(git -C "$PROJECT_DIR" rev-parse HEAD 2>/dev/null || true)"
fi

# Guard: skip if nothing has changed since last log
LAST_SHA_FILE="$HOME/.claude/obsidian-last-logged-sha"
if [ -f "$LAST_SHA_FILE" ]; then
    LAST_SHA="$(cat "$LAST_SHA_FILE" 2>/dev/null || true)"
    # If SHA matches and working tree is clean, skip
    if [ -n "$HEAD_SHA" ] && [ "$HEAD_SHA" = "$LAST_SHA" ]; then
        GIT_DIRTY="$(git -C "$PROJECT_DIR" status --short 2>/dev/null || true)"
        [ -z "$GIT_DIRTY" ] && exit 0
    fi
fi

# Gather git context
BRANCH="$(git -C "$PROJECT_DIR" branch --show-current 2>/dev/null || echo 'not a git repo')"
BRANCH="$(echo "$BRANCH" | tr -d '\n\r:#{}|>`')"
RECENT_COMMITS="$(git -C "$PROJECT_DIR" log --oneline -5 2>/dev/null || echo '(none)')"
CHANGED_FILES=""
if git -C "$PROJECT_DIR" rev-parse HEAD~1 &>/dev/null 2>&1; then
    CHANGED_FILES="$(git -C "$PROJECT_DIR" diff --stat HEAD~1 2>/dev/null || true)"
fi
UNCOMMITTED="$(git -C "$PROJECT_DIR" status --short 2>/dev/null || echo '')"

# Build project slug (lowercase, hyphens, max 30 chars)
SLUG="$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-//;s/-$//' | cut -c1-30)"
TIMESTAMP="$(date '+%Y-%m-%d-%H%M')"
SESSION_FILE="Claude/sessions/${TIMESTAMP}-${SLUG}.md"
DAILY_FILE="Claude/daily/${DATE}.md"
FULL_SESSION_PATH="${VAULT}/${SESSION_FILE}"
FULL_DAILY_PATH="${VAULT}/${DAILY_FILE}"

# Assert both write targets are inside $VAULT/Claude/
case "$FULL_SESSION_PATH" in
    "$VAULT/Claude/"*) ;;
    *) exit 0 ;;
esac
case "$FULL_DAILY_PATH" in
    "$VAULT/Claude/"*) ;;
    *) exit 0 ;;
esac

# Create directories
mkdir -p "$(dirname "$FULL_SESSION_PATH")"
mkdir -p "$(dirname "$FULL_DAILY_PATH")"

# Build session file content
{
    echo "---"
    echo "type: claude/session"
    echo "project: ${PROJECT_NAME}"
    echo "project_dir: ${PROJECT_DIR}"
    echo "date: ${DATE}"
    echo "ended_at: ${NOW}"
    echo "branch: ${BRANCH}"
    echo "tags: [claude, session-log, auto]"
    echo "---"
    echo ""
    echo "## Recent commits"
    while IFS= read -r line; do
        echo "- ${line}"
    done <<< "$RECENT_COMMITS"
    echo ""
    if [ -n "$CHANGED_FILES" ] && [ "$CHANGED_FILES" != "(no prior commit)" ]; then
        echo "## Files changed in last commit"
        echo "$CHANGED_FILES"
        echo ""
    fi
    if [ -n "$UNCOMMITTED" ]; then
        echo "## Uncommitted changes"
        while IFS= read -r line; do
            [ -n "$line" ] && echo "- ${line}"
        done <<< "$UNCOMMITTED"
        echo ""
    fi
    echo "<!-- auto-logged by Stop hook -->"
} > "$FULL_SESSION_PATH"

# Append to daily note
SLUG_NO_EXT="${TIMESTAMP}-${SLUG}"
DAILY_LINE="- ${TIME} **session** [[Claude/sessions/${SLUG_NO_EXT}]] — branch: ${BRANCH} (auto)"

if [ ! -f "$FULL_DAILY_PATH" ]; then
    printf "# %s\n\n%s\n" "$DATE" "$DAILY_LINE" > "$FULL_DAILY_PATH"
else
    printf "\n%s\n" "$DAILY_LINE" >> "$FULL_DAILY_PATH"
fi

# Save current SHA so next hook invocation can detect unchanged state
[ -n "$HEAD_SHA" ] && echo "$HEAD_SHA" > "$LAST_SHA_FILE"

exit 0
