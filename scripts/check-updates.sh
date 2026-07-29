#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_DIR="$(dirname "$SCRIPT_DIR")"

CLAUDE_AGENTS="$HOME/.claude/agents"
CLAUDE_SKILLS="$HOME/.claude/skills"

up_to_date=0
outdated=0
not_installed=0
orphaned=0

# Agents and skills this pack has retired. Installed copies stay routable until
# they are deleted, so they are named here to be reported as orphans (and in
# install.sh's deprecated_* lists to actually be removed). Keep the two in sync.
KNOWN_RETIRED_AGENTS="branch-manager typescript-engineer wiki-ingestor wiki-librarian wiki-linter"
KNOWN_RETIRED_SKILLS="agent-plan challenge check-readiness check-updates obsidian-log skill-writer wiki wiki-ingest wiki-init wiki-lint wiki-query"

in_list() {  # in_list <needle> <space-separated haystack>
    case " $2 " in *" $1 "*) return 0 ;; *) return 1 ;; esac
}

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
echo "-- Orphans (installed but not in this pack)"
# Reverse pass. The two loops above walk pack -> installed, so they can only ever
# report what is missing or stale; an installed agent or skill that the pack has
# since dropped is invisible to them. Those files stay routable -- the router reads
# whatever is in ~/.claude -- so a retired agent can still be dispatched months after
# its removal. This pass walks installed -> pack to catch exactly that.
#
# Not everything here is the pack's to judge: hand-written agents and skills from
# other sources live in the same directories. So a name is only called out for
# removal when it is on a KNOWN_RETIRED_* list; anything else is reported as
# unrecognized and left alone.
orphan_retired=""
for installed in "$CLAUDE_AGENTS/"*.md; do
    [ -f "$installed" ] || continue
    name="$(basename "$installed")"
    label="${name%.md}"
    [ -f "$PACK_DIR/agents/$name" ] && continue
    if in_list "$label" "$KNOWN_RETIRED_AGENTS"; then
        echo "  [!!] agent:  $label  (retired from the pack -- run install.sh to remove)"
        orphan_retired="yes"
        orphaned=$((orphaned + 1))
    else
        echo "  [??] agent:  $label  (not from this pack -- left alone)"
    fi
done

for installed_dir in "$CLAUDE_SKILLS/"*/; do
    [ -d "$installed_dir" ] || continue
    name="$(basename "$installed_dir")"
    [ -d "$PACK_DIR/skills/$name" ] && continue
    if in_list "$name" "$KNOWN_RETIRED_SKILLS"; then
        echo "  [!!] skill:  $name  (retired from the pack -- run install.sh to remove)"
        orphan_retired="yes"
        orphaned=$((orphaned + 1))
    else
        echo "  [??] skill:  $name  (not from this pack -- left alone)"
    fi
done

if [ "$orphaned" -eq 0 ]; then
    echo "  [ok] no retired pack files left installed"
fi

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
echo "  $up_to_date up to date, $outdated outdated, $not_installed not installed, $orphaned orphaned"
echo ""

if [ "$outdated" -gt 0 ] || [ "$not_installed" -gt 0 ] || [ "$orphaned" -gt 0 ]; then
    echo "Run ./install.sh to update."
    if [ -n "$orphan_retired" ]; then
        echo "Retired files above stay routable until install.sh removes them -- an agent"
        echo "the pack dropped can still be dispatched while its file is present."
    fi
    exit 1
fi
