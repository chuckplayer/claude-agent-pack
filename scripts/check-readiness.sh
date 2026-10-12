#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_DIR="$(dirname "$SCRIPT_DIR")"

SCOPE="user"
PROJECT_DIR_GIVEN=0
PROJECT_DIR_ARG=""
POSITIONAL_DIR=""

usage() {
    echo "Usage: scripts/check-readiness.sh [--scope user|project] [--project-dir DIR] [<project-path>]"
    echo
    echo "  --scope user       Check agents/skills in ~/.claude (default)."
    echo "  --scope project    Check agents/skills in <project>/.claude."
    echo "  --project-dir DIR  With --scope project: the project whose .claude/ is checked"
    echo "                     (default: the current directory's git toplevel). With --scope"
    echo "                     user: a project to inspect for a second-scope install. Validated"
    echo "                     the same way in all four pack scripts."
    echo "  <project-path>     Separate: the project whose scaffolding (CLAUDE.md, docs/,"
    echo "                     memory/) is checked. Not validated as an install target."
    echo "                     Default: the validated --project-dir if any, else the current directory."
}

while [ $# -gt 0 ]; do
    case "$1" in
        --scope)
            [ $# -ge 2 ] || { echo "ERROR: --scope needs a value (user|project)" >&2; exit 1; }
            SCOPE="$2"; shift ;;
        --scope=*)        SCOPE="${1#--scope=}" ;;
        --project-dir)
            [ $# -ge 2 ] || { echo "ERROR: --project-dir needs a value" >&2; exit 1; }
            PROJECT_DIR_GIVEN=1; PROJECT_DIR_ARG="$2"; shift ;;
        --project-dir=*)  PROJECT_DIR_GIVEN=1; PROJECT_DIR_ARG="${1#--project-dir=}" ;;
        -h|--help)        usage; exit 0 ;;
        -*) echo "ERROR: unknown option '$1' (try --help)" >&2; exit 1 ;;
        *)
            [ -z "$POSITIONAL_DIR" ] || { echo "ERROR: only one <project-path> may be given" >&2; exit 1; }
            POSITIONAL_DIR="$1" ;;
    esac
    shift
done

PACK_LIB="$PACK_DIR/scripts/lib/pack-common.sh"
if [ ! -f "$PACK_LIB" ]; then
    echo "ERROR: $PACK_LIB is missing -- incomplete pack checkout." >&2
    exit 1
fi
# shellcheck source-path=SCRIPTDIR source=lib/pack-common.sh
. "$PACK_LIB"

pack_init_scope "$SCOPE" "$PROJECT_DIR_GIVEN" "$PROJECT_DIR_ARG" "$PACK_DIR" || exit 1
if [ "$PACK_SCOPE" = "project" ]; then
    INSTALL_HINT="./install.sh --scope project --project-dir $(pack_shquote "$PACK_PROJECT_ROOT")"
else
    INSTALL_HINT="./install.sh"
fi

# Scaffolding target: explicit positional, else the validated --project-dir, else cwd.
if [ -n "$POSITIONAL_DIR" ]; then
    PROJECT_DIR="$POSITIONAL_DIR"
elif [ -n "$PACK_PROJECT_ROOT" ]; then
    PROJECT_DIR="$PACK_PROJECT_ROOT"
else
    PROJECT_DIR="$(pwd)"
fi

PASS=0
FAIL=0

check() {
    local label="$1"
    local result="$2"  # "ok" or "fail"
    local detail="${3:-}"
    if [ "$result" = "ok" ]; then
        echo "  [ok] $label"
        PASS=$((PASS + 1))
    else
        echo "  [!!] $label${detail:+  -- $detail}"
        FAIL=$((FAIL + 1))
    fi
}

echo "Claude Agent Pack -- Readiness Check"
echo "  scope: $PACK_SCOPE ($(pack_sanitize "$PACK_SCOPE_ROOT"))"
echo ""

# Claude Code
echo "-- Claude Code"
if [ -d "$HOME/.claude" ]; then
    check "~/.claude directory exists" "ok"
else
    check "~/.claude directory exists" "fail" "Install Claude Code first: https://claude.ai/download"
fi

# Agents
echo ""
echo "-- Agents"
missing_agents=()
agent_count=0
for agent_file in "$PACK_DIR/agents/"*.md; do
    name="$(basename "$agent_file")"
    agent_count=$((agent_count + 1))
    if [ ! -f "$PACK_AGENTS_DIR/$name" ]; then
        missing_agents+=("${name%.md}")
    fi
done
if [ ${#missing_agents[@]} -eq 0 ]; then
    check "All $agent_count agents installed" "ok"
else
    check "Agents installed ($((agent_count - ${#missing_agents[@]}))/$agent_count)" "fail" \
        "Missing: ${missing_agents[*]}  -- run $INSTALL_HINT"
fi

# Skills
echo ""
echo "-- Skills"
missing_skills=()
skill_count=0
for skill_dir in "$PACK_DIR/skills/"*/; do
    name="$(basename "$skill_dir")"
    skill_count=$((skill_count + 1))
    if [ ! -f "$PACK_SKILLS_DIR/$name/SKILL.md" ]; then
        missing_skills+=("$name")
    fi
done
if [ ${#missing_skills[@]} -eq 0 ]; then
    check "All $skill_count skills installed" "ok"
else
    check "Skills installed ($((skill_count - ${#missing_skills[@]}))/$skill_count)" "fail" \
        "Missing: ${missing_skills[*]}  -- run $INSTALL_HINT"
fi

# References. Presence only -- content drift is scripts/check-updates.sh's job.
echo ""
echo "-- References"
if [ "$(count_files "$PACK_DIR/references")" -eq 0 ]; then
    check "No references shipped by this pack version (nothing to install)" "ok"
else
    missing_refs=()
    ref_count=0
    while IFS= read -r -d '' ref_file; do
        rel="${ref_file#"$PACK_DIR/references"/}"
        ref_count=$((ref_count + 1))
        [ -f "$PACK_REFS_INSTALL_DIR/$rel" ] || missing_refs+=("$(pack_sanitize "$rel")")
    done < <(find "$PACK_DIR/references" -type f -print0)
    if [ ${#missing_refs[@]} -eq 0 ]; then
        check "All $ref_count reference files installed ($PACK_REFS_INSTALL_DIR)" "ok"
    else
        check "References installed ($((ref_count - ${#missing_refs[@]}))/$ref_count)" "fail" \
            "Missing: ${missing_refs[*]}  -- run $INSTALL_HINT"
    fi
fi

# Configuration
echo ""
echo "-- Configuration"
# Read-only. User scope reads ~/.claude/settings.json, as before. Project scope
# reports the EFFECTIVE value -- <project>/.claude/settings.local.json over
# <project>/.claude/settings.json over ~/.claude/settings.json -- because any of the
# three can set it, and only the winner decides where engineer worktrees branch from.
user_base_ref="$(pack_sanitize "$(pack_read_base_ref "$HOME/.claude/settings.json")")"
if [ "$PACK_SCOPE" = "project" ]; then
    local_base_ref="$(pack_sanitize "$(pack_read_base_ref "$PACK_SCOPE_ROOT/settings.local.json")")"
    proj_base_ref="$(pack_sanitize "$(pack_read_base_ref "$PACK_SCOPE_ROOT/settings.json")")"
    base_ref="${local_base_ref:-${proj_base_ref:-$user_base_ref}}"
    base_ref_where="effective; .claude/settings.local.json='${local_base_ref:-unset}', .claude/settings.json='${proj_base_ref:-unset}', ~/.claude/settings.json='${user_base_ref:-unset}'"
    base_ref_fix="add { \"worktree\": { \"baseRef\": \"head\" } } to ~/.claude/settings.json or the project's .claude/settings.json (project-scope install never writes settings)"
else
    base_ref="$user_base_ref"
    # shellcheck disable=SC2088  # display text, not a path
    base_ref_where="~/.claude/settings.json"
    base_ref_fix="Re-run ./install.sh or add { \"worktree\": { \"baseRef\": \"head\" } } to ~/.claude/settings.json"
fi

if [ "$base_ref" = "head" ]; then
    check "worktree.baseRef is \"head\"" "ok"
else
    check "worktree.baseRef is \"head\"" "fail" \
        "currently '${base_ref:-unset, defaults to fresh}' ($base_ref_where) -- engineer worktrees (isolation:\"worktree\") will silently base off local/origin main instead of your feature branch. $base_ref_fix"
fi

# Project scaffolding
echo ""
echo "-- Project ($(pack_sanitize "$PROJECT_DIR"))"
[ -f "$PROJECT_DIR/CLAUDE.md" ]              && check "CLAUDE.md"               "ok" || check "CLAUDE.md"               "fail" "run scripts/setup-project.sh"
[ -f "$PROJECT_DIR/docs/CONVENTIONS.md" ]    && check "docs/CONVENTIONS.md"     "ok" || check "docs/CONVENTIONS.md"     "fail" "run scripts/setup-project.sh"
[ -f "$PROJECT_DIR/docs/MEMORY-WRITING.md" ] && check "docs/MEMORY-WRITING.md"  "ok" || check "docs/MEMORY-WRITING.md"  "fail" "run scripts/setup-project.sh"
for subdir in decisions architecture context known-issues; do
    [ -d "$PROJECT_DIR/memory/$subdir" ] \
        && check "memory/$subdir/" "ok" \
        || check "memory/$subdir/" "fail" "run scripts/setup-project.sh"
done

# Gate scripts. A missing checker is a stated gap, not a silent pass: any
# instruction to run one of these must degrade to "not applicable" when the file
# is absent, rather than being reported as clean.
echo ""
echo "-- Checks"
for script in lint-agents.sh lint-identifiers.sh lint-plans.sh lint-memory.sh; do
    if [ -f "$PACK_DIR/scripts/$script" ]; then
        check "scripts/$script" "ok"
    else
        check "scripts/$script" "fail" \
            "absent -- any step instructing it must report 'not applicable', never a pass. Re-run ./install.sh or update the pack."
    fi
done

echo ""
echo "----"
echo "  $PASS passed, $FAIL failed"
echo ""

[ "$FAIL" -eq 0 ] || exit 1
