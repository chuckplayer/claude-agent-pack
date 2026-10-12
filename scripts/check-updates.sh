#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_DIR="$(dirname "$SCRIPT_DIR")"

SCOPE="user"
PROJECT_DIR_GIVEN=0
PROJECT_DIR_ARG=""

usage() {
    echo "Usage: scripts/check-updates.sh [--scope user|project] [--project-dir DIR]"
    echo
    echo "  --scope user       Compare against ~/.claude (default)."
    echo "  --scope project    Compare against <project>/.claude."
    echo "  --project-dir DIR  With --scope project: the project (default: the current"
    echo "                     directory's git toplevel). With --scope user: the project"
    echo "                     inspected for a second-scope install (default: the current"
    echo "                     directory's git toplevel, if any). Validated the same way in"
    echo "                     all four pack scripts."
    echo
    echo "Exit: 0 all current; 1 something to act on; 2 a file could not be rendered or"
    echo "compared, so the counts are not trustworthy."
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
        *) echo "ERROR: unknown option '$1' (try --help)" >&2; exit 1 ;;
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

RENDER_TMP="$(mktemp -d)"
trap 'rm -rf -- "$RENDER_TMP"' EXIT

up_to_date=0
outdated=0
not_installed=0
orphaned=0
dual=0
leftover_staging=0
held_staging=0
render_errors=0
compare_errors=0

in_list() {  # in_list <needle> <word>...
    local n="$1" w; shift
    for w in "$@"; do [ "$w" = "$n" ] && return 0; done
    return 1
}

# same_as_installed <src> <installed>
# Renders <src> exactly as install.sh would (same function, same replacement) and
# compares the result with <installed>. 0 = identical, 1 = differs, 2 = render
# error, 3 = diff could not compare (e.g. an unreadable installed file).
# Comparing the RENDERED source is what keeps a file carrying the token from
# reporting as outdated forever.
same_as_installed() {
    local rendered="$RENDER_TMP/rendered" rc=0
    rm -f -- "$rendered"
    render_pack_file "$1" "$rendered" "$PACK_REFS_REPLACEMENT" || return 2
    diff -q "$rendered" "$2" > /dev/null 2>&1 || rc=$?
    case "$rc" in
        0|1) return "$rc" ;;
        *)   echo "  diff could not compare $(pack_sanitize "$2") (exit $rc)" >&2; return 3 ;;
    esac
}

# tree_drift <src-dir> <installed-dir>
# Prints one line per drifted relative path, "<kind> <path>", with kind one of
# missing | changed | extra | render-error | unreadable. Nothing when the installed
# tree is the rendered source tree, file for file. Consumers act on the kind token
# (the first word) only -- never on the text, which contains file names.
tree_drift() {
    local src="$1" inst="$2" f rel rc
    if [ -d "$src" ]; then
        while IFS= read -r -d '' f; do
            rel="${f#"$src"/}"
            if [ ! -f "$inst/$rel" ]; then
                printf 'missing %s\n' "$(pack_sanitize "$rel")"
                continue
            fi
            rc=0
            same_as_installed "$f" "$inst/$rel" || rc=$?
            case "$rc" in
                0) ;;
                1) printf 'changed %s\n' "$(pack_sanitize "$rel")" ;;
                2) printf 'render-error %s\n' "$(pack_sanitize "$rel")" ;;
                *) printf 'unreadable %s\n' "$(pack_sanitize "$rel")" ;;
            esac
        done < <(find "$src" -type f -print0)
    fi
    if [ -d "$inst" ]; then
        while IFS= read -r -d '' f; do
            rel="${f#"$inst"/}"
            [ -f "$src/$rel" ] || printf 'extra %s\n' "$(pack_sanitize "$rel")"
        done < <(find "$inst" -type f -print0)
    fi
    return 0
}

# classify_drift <tree_drift output>
# Counts by the kind token of each line. Sets DRIFT_SRC (lines about shipped
# files: missing, changed, render-error, unreadable), DRIFT_MISSING, DRIFT_EXTRA,
# DRIFT_RENDER and DRIFT_UNREADABLE. Adds the error kinds to render_errors and
# compare_errors -- tree_drift runs in a subshell, so this is where they count.
classify_drift() {
    local line kind
    DRIFT_SRC=0; DRIFT_MISSING=0; DRIFT_EXTRA=0; DRIFT_RENDER=0; DRIFT_UNREADABLE=0
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        kind="${line%% *}"
        case "$kind" in
            missing)      DRIFT_MISSING=$((DRIFT_MISSING + 1)); DRIFT_SRC=$((DRIFT_SRC + 1)) ;;
            changed)      DRIFT_SRC=$((DRIFT_SRC + 1)) ;;
            extra)        DRIFT_EXTRA=$((DRIFT_EXTRA + 1)) ;;
            render-error) DRIFT_RENDER=$((DRIFT_RENDER + 1)); DRIFT_SRC=$((DRIFT_SRC + 1)) ;;
            unreadable)   DRIFT_UNREADABLE=$((DRIFT_UNREADABLE + 1)); DRIFT_SRC=$((DRIFT_SRC + 1)) ;;
        esac
    done <<< "$1"
    render_errors=$((render_errors + DRIFT_RENDER))
    compare_errors=$((compare_errors + DRIFT_UNREADABLE))
}

echo "Claude Agent Pack -- Update Check"
echo "  scope: $PACK_SCOPE ($(pack_sanitize "$PACK_SCOPE_ROOT"))"
echo ""

echo "-- Agents"
for agent_file in "$PACK_DIR/agents/"*.md; do
    name="$(basename "$agent_file")"
    label="$(pack_sanitize "${name%.md}")"
    installed="$PACK_AGENTS_DIR/$name"

    if [ ! -f "$installed" ]; then
        echo "  [--] $label  (not installed)"
        not_installed=$((not_installed + 1))
        continue
    fi
    rc=0
    same_as_installed "$agent_file" "$installed" || rc=$?
    case "$rc" in
        0) echo "  [ok] $label"; up_to_date=$((up_to_date + 1)) ;;
        1) echo "  [!!] $label  (outdated)"; outdated=$((outdated + 1)) ;;
        2) echo "  [!!] $label  (render failed -- see error above)"; outdated=$((outdated + 1)); render_errors=$((render_errors + 1)) ;;
        *) echo "  [!!] $label  (installed file unreadable -- see error above)"; outdated=$((outdated + 1)); compare_errors=$((compare_errors + 1)) ;;
    esac
done

echo ""
echo "-- Skills"
# A skill is the whole directory: SKILL.md plus any supporting files. It is
# outdated if any file differs, is missing, or is installed but not shipped.
for skill_dir in "$PACK_DIR/skills/"*/; do
    skill_dir="${skill_dir%/}"
    name="$(basename "$skill_dir")"
    label="$(pack_sanitize "$name")"
    installed="$PACK_SKILLS_DIR/$name"

    if [ ! -f "$installed/SKILL.md" ]; then
        echo "  [--] $label  (not installed)"
        not_installed=$((not_installed + 1))
        continue
    fi
    drift="$(tree_drift "$skill_dir" "$installed")"
    classify_drift "$drift"
    if [ -z "$drift" ]; then
        echo "  [ok] $label"
        up_to_date=$((up_to_date + 1))
    else
        echo "  [!!] $label  (outdated: $(printf '%s' "$drift" | tr '\n' ';' | sed 's/;/; /g'))"
        outdated=$((outdated + 1))
    fi
done

echo ""
echo "-- References ($(pack_sanitize "$PACK_REFS_INSTALL_DIR"))"
# Counted per file. The installed references dir is owned wholesale by install.sh,
# so an installed file the pack no longer ships is drift, not someone else's file.
if [ ! -d "$PACK_DIR/references" ] && [ ! -d "$PACK_REFS_INSTALL_DIR" ]; then
    echo "  [ok] no references shipped, none installed"
else
    drift="$(tree_drift "$PACK_DIR/references" "$PACK_REFS_INSTALL_DIR")"
    classify_drift "$drift"
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        kind="${line%% *}"; rel="${line#* }"
        case "$kind" in
            missing)      echo "  [--] $rel  (not installed)" ;;
            changed)      echo "  [!!] $rel  (outdated)" ;;
            extra)        echo "  [!!] $rel  (installed but no longer shipped)" ;;
            unreadable)   echo "  [!!] $rel  (installed file unreadable -- see error above)" ;;
            render-error) echo "  [!!] $rel  (render failed -- see error above)" ;;
        esac
    done <<< "$drift"
    not_installed=$((not_installed + DRIFT_MISSING))
    outdated=$((outdated + DRIFT_SRC - DRIFT_MISSING + DRIFT_EXTRA))
    n_src="$(count_files "$PACK_DIR/references")"
    n_ok=$((n_src - DRIFT_SRC))
    up_to_date=$((up_to_date + n_ok))
    echo "  [ok] $n_ok of $n_src shipped reference file(s) up to date"
fi

# Staging dirs are deleted by install.sh on success and on failure. An EMPTY one
# still present means a run was killed; install.sh sweeps it at its next start.
# One whose aside/ holds files is the only copy of a previous install that a
# failed rollback could not restore -- nothing sweeps it; it needs a human.
while IFS= read -r -d '' _s; do
    if pack_staging_has_aside "$_s"; then
        echo "  [!!] staging dir HOLDS SET-ASIDE COPIES from a failed rollback: $(pack_sanitize "$_s")"
        echo "       restore them into $(pack_sanitize "$PACK_SCOPE_ROOT") by hand; no pack script will delete it"
        held_staging=$((held_staging + 1))
    else
        echo "  [!!] leftover staging dir: $(pack_sanitize "$_s")  (an install was interrupted -- re-run install.sh or uninstall.sh)"
        leftover_staging=$((leftover_staging + 1))
    fi
done < <(pack_list_staging "$PACK_NS_DIR")
if [ ! -f "$PACK_NS_DIR/$AGENT_PACK_MARKER" ] && [ -d "$PACK_AGENTS_DIR" ]; then
    echo "  [--] no $(pack_sanitize "$PACK_NS_DIR/$AGENT_PACK_MARKER") marker (installed before markers existed, or not installed)"
fi

echo ""
echo "-- Orphans (installed but not in this pack)"
# Reverse pass. The loops above walk pack -> installed, so they can only ever
# report what is missing or stale; an installed agent or skill that the pack has
# since dropped is invisible to them. Those files stay routable -- the router reads
# whatever is in the .claude directory -- so a retired agent can still be dispatched
# months after its removal. This pass walks installed -> pack to catch exactly that.
#
# Not everything here is the pack's to judge: hand-written agents and skills from
# other sources live in the same directories. So a name is only called out for
# removal when it is on a PACK_RETIRED_* list; anything else is reported as
# unrecognized and left alone.
if [ "$PACK_SCOPE" = "project" ]; then
    retired_hint="retired from the pack -- delete it and commit; install.sh only reports in project scope"
else
    retired_hint="retired from the pack -- run install.sh to remove"
fi
orphan_retired=""
for installed in "$PACK_AGENTS_DIR/"*.md; do
    [ -f "$installed" ] || continue
    name="$(basename "$installed")"
    label="${name%.md}"
    [ -f "$PACK_DIR/agents/$name" ] && continue
    if in_list "$label" "${PACK_RETIRED_AGENTS[@]}"; then
        echo "  [!!] agent:  $(pack_sanitize "$label")  ($retired_hint)"
        orphan_retired="yes"
        orphaned=$((orphaned + 1))
    else
        echo "  [??] agent:  $(pack_sanitize "$label")  (not from this pack -- left alone)"
    fi
done

for installed_dir in "$PACK_SKILLS_DIR/"*/; do
    [ -d "$installed_dir" ] || continue
    name="$(basename "$installed_dir")"
    [ -d "$PACK_DIR/skills/$name" ] && continue
    if in_list "$name" "${PACK_RETIRED_SKILLS[@]}"; then
        echo "  [!!] skill:  $(pack_sanitize "$name")  ($retired_hint)"
        orphan_retired="yes"
        orphaned=$((orphaned + 1))
    else
        echo "  [??] skill:  $(pack_sanitize "$name")  (not from this pack -- left alone)"
    fi
done

if [ "$orphaned" -eq 0 ]; then
    echo "  [ok] no retired pack files left installed"
fi

echo ""
echo "-- Second scope"
# Agents resolve project-over-user; skills resolve user-over-project. With the
# pack in both scopes a session can run one scope's agent beside the other
# scope's skill, so report every pack name present in both and say which wins.
# Same predicate as install.sh's refusal: only a real pack install in the other
# scope makes this a dual install (and a non-zero exit). Same-named files in a
# scope that holds no pack install are still listed, with their winner, as [??].
OTHER_ROOT="$(pack_other_scope_root "$PACK_SCOPE" "$PACK_PROJECT_ROOT")"
if [ -z "$OTHER_ROOT" ]; then
    echo "  [skip] not inside a git work tree and no --project-dir -- no project scope to compare"
else
    if [ "$PACK_SCOPE" = "user" ]; then
        USER_ROOT="$PACK_SCOPE_ROOT"; PROJ_ROOT_DIR="$OTHER_ROOT"
    else
        USER_ROOT="$OTHER_ROOT"; PROJ_ROOT_DIR="$PACK_SCOPE_ROOT"
    fi
    if pack_scope_has_pack "$OTHER_ROOT" "$PACK_DIR"; then
        other_is_pack=1; tag="[!!]"
        echo "  other scope holds a pack install: $(pack_sanitize "$OTHER_ROOT") ($(pack_sanitize "$PACK_HAS_PACK_WHY"))"
    else
        other_is_pack=0; tag="[??]"
    fi
    both=0
    while IFS=' ' read -r kind name; do
        [ -n "${kind:-}" ] || continue
        if [ "$kind" = "agent" ] && [ -f "$PACK_AGENTS_DIR/$name.md" ]; then
            echo "  $tag agent:  $(pack_sanitize "$name")  in both scopes -- the PROJECT copy wins ($(pack_sanitize "$PROJ_ROOT_DIR/agents/$name.md"))"
            both=$((both + 1))
        elif [ "$kind" = "skill" ] && [ -d "$PACK_SKILLS_DIR/$name" ]; then
            echo "  $tag skill:  $(pack_sanitize "$name")  in both scopes -- the USER copy wins ($(pack_sanitize "$USER_ROOT/skills/$name"))"
            both=$((both + 1))
        fi
    done < <(pack_list_shipped_in "$OTHER_ROOT" "$PACK_DIR")
    if [ "$other_is_pack" = "1" ]; then
        dual="$both"
    elif [ "$both" -gt 0 ]; then
        echo "  [ok] the $both name(s) above are same-named files, not a pack install in $(pack_sanitize "$OTHER_ROOT") -- not counted"
    fi
    if [ "$both" -eq 0 ]; then
        echo "  [ok] no pack name installed in both scopes (checked $(pack_sanitize "$OTHER_ROOT"))"
    fi
fi

echo ""
echo "-- Obsidian hooks"
if [ "$PACK_SCOPE" = "project" ]; then
    echo "  [skip] project scope -- hook scripts are user-level (~/.claude/scripts) and not checked here"
else
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
fi

echo ""
echo "----"
echo "  $up_to_date up to date, $outdated outdated, $not_installed not installed, $orphaned orphaned, $dual in both scopes, $leftover_staging leftover staging, $held_staging staging holding set-aside copies"
echo ""

if [ "$render_errors" -gt 0 ] || [ "$compare_errors" -gt 0 ]; then
    echo "$render_errors file(s) could not be rendered and $compare_errors could not be compared -- the counts above are not trustworthy."
    exit 2
fi

if [ "$outdated" -gt 0 ] || [ "$not_installed" -gt 0 ] || [ "$orphaned" -gt 0 ] || [ "$dual" -gt 0 ] \
        || [ "$leftover_staging" -gt 0 ] || [ "$held_staging" -gt 0 ]; then
    echo "Run $INSTALL_HINT to update."
    if [ -n "$orphan_retired" ]; then
        echo "Retired files above stay routable until they are removed -- an agent"
        echo "the pack dropped can still be dispatched while its file is present."
    fi
    if [ "$dual" -gt 0 ]; then
        echo "Uninstall one of the two scopes so a session cannot mix pack versions."
    fi
    exit 1
fi
