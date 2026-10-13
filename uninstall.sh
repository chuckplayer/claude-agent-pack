#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SCOPE="user"
PROJECT_DIR_GIVEN=0
PROJECT_DIR_ARG=""
FORCE=0

usage() {
    echo "Usage: bash uninstall.sh [--scope user|project] [--project-dir DIR] [--force]"
    echo
    echo "  --scope user       Remove from ~/.claude (default), including Obsidian hooks/env."
    echo "  --scope project    Remove from <project>/.claude. Never touches settings.json."
    echo "  --project-dir DIR  With --scope project: the project (default: the current"
    echo "                     directory's git toplevel). With --scope user: a project to"
    echo "                     inspect for a second-scope install (reported, never touched)."
    echo "                     Validated the same way in all four pack scripts."
    echo "  --force            Also remove pack-named files that look foreign (see below)."
    echo
    echo "Only names this pack ships (agents/*.md, skills/*/) and the pack's own"
    echo "agent-pack/ directory are considered. A pack-named file is removed only when the"
    echo "scope holds a pack install (agent-pack/.installed marker, or at least half the"
    echo "pack's agent names) AND, without the marker, its content matches what this pack"
    echo "version installs. Anything else is listed as foreign and kept unless --force."
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
        --force)          FORCE=1 ;;
        -h|--help)        usage; exit 0 ;;
        *) echo "ERROR: unknown option '$1' (try --help)" >&2; exit 1 ;;
    esac
    shift
done

PACK_LIB="$SCRIPT_DIR/scripts/lib/pack-common.sh"
if [ ! -f "$PACK_LIB" ]; then
    echo "ERROR: $PACK_LIB is missing -- incomplete pack checkout." >&2
    exit 1
fi
# shellcheck source=scripts/lib/pack-common.sh
. "$PACK_LIB"

pack_init_scope "$SCOPE" "$PROJECT_DIR_GIVEN" "$PROJECT_DIR_ARG" "$SCRIPT_DIR" || exit 1
pack_check_scope_links "$PACK_SCOPE_ROOT" || exit 1

SETTINGS="$HOME/.claude/settings.json"
HOOK_SH="$HOME/.claude/scripts/obsidian-stop-hook.sh"
HOOK_FILES=(
    "$HOOK_SH"
    "$HOME/.claude/scripts/obsidian-stop-hook.js"
    "$HOME/.claude/scripts/obsidian-prompt-hook.js"
    "$HOME/.claude/scripts/obsidian-agent-hook.js"
    "$HOME/.claude/scripts/obsidian-context-hook.js"
    "$HOME/.claude/scripts/obsidian-memory-hook.js"
)

RENDER_TMP="$(mktemp -d)"
trap 'rm -rf -- "$RENDER_TMP"' EXIT

# --- Leftover staging dirs (checked before anything else) ---------------------------
# One holding set-aside copies is the only copy of a previous install that a failed
# rollback could not restore: stop and show it, and remove nothing at all.
stale_staging=()
while IFS= read -r -d '' _s; do
    if pack_staging_has_aside "$_s"; then
        {
            echo "ERROR: a staging dir still holds set-aside copies of a previous install"
            echo "       (an install's rollback failed). Nothing has been removed."
            pack_show_staging "$_s"
            echo "       Move those files back or delete the directory, then re-run uninstall.sh."
        } >&2
        exit 1
    fi
    stale_staging+=("$_s")
done < <(pack_list_staging "$PACK_NS_DIR")

# --- settings.json is parsed BEFORE anything is deleted (user scope) ----------------
# An unparseable settings.json aborts here, so a run can never remove the agents and
# skills and then fail half-way through the settings edit.
remove_obsidian_env=false
remove_obsidian_hooks=false
settings_tool_ok=false
if [ "$PACK_SCOPE" = "user" ]; then
    if [ -f "$SETTINGS" ]; then
        _rc=0
        pack_settings_parse "$SETTINGS" || _rc=$?
        case "$_rc" in
            0) settings_tool_ok=true ;;
            3) echo "  WARNING: no working python found -- $SETTINGS will not be modified." >&2 ;;
            *) echo "ERROR: $(pack_sanitize "$SETTINGS") does not parse (see above). Nothing has been removed." >&2
               echo "       Fix or move the file, then re-run uninstall.sh." >&2
               exit 1 ;;
        esac
        if [ "$settings_tool_ok" = true ] && pack_settings_has_obsidian_env "$SETTINGS"; then
            remove_obsidian_env=true
        fi
    fi
    for _h in "${HOOK_FILES[@]}"; do
        [ -f "$_h" ] && remove_obsidian_hooks=true
    done
    # Dry-run every settings transform this run will apply, in memory, BEFORE
    # anything is deleted: a wrong-shaped settings.json (e.g. "hooks" holding a
    # list) must abort here with nothing removed, not after the agents, skills and
    # hook scripts are already gone.
    if [ "$settings_tool_ok" = true ]; then
        for _what in env hooks; do
            if [ "$_what" = env ] && [ "$remove_obsidian_env" != true ]; then continue; fi
            if [ "$_what" = hooks ] && [ "$remove_obsidian_hooks" != true ]; then continue; fi
            if ! pack_settings_remove_obsidian "$SETTINGS" "$_what" check; then
                echo "ERROR: $(pack_sanitize "$SETTINGS") cannot be updated (see above). Nothing has been removed." >&2
                echo "       Fix its shape, or move it aside, then re-run uninstall.sh." >&2
                exit 1
            fi
        done
    fi
fi

# --- Ownership of pack-named files ------------------------------------------------------
# A pack-named agent or skill is the pack's to remove only when this scope holds a
# pack install. With the .installed marker every pack-named file counts as the
# pack's (it may have been edited). Without it (an install made before markers), a
# file counts only when its content matches what this pack version installs --
# otherwise it is listed as foreign and kept unless --force.
has_pack=false; has_marker=false
pack_scope_has_pack "$PACK_SCOPE_ROOT" "$SCRIPT_DIR" && has_pack=true
[ -f "$PACK_NS_DIR/$AGENT_PACK_MARKER" ] && has_marker=true

# _matches_render <src> <installed> -- installed equals the rendered source?
_matches_render() {
    render_pack_file "$1" "$RENDER_TMP/r" "$PACK_REFS_REPLACEMENT" >/dev/null 2>&1 || return 1
    cmp -s "$RENDER_TMP/r" "$2"
}

# _owned <src> <installed>
_owned() {
    [ "$has_pack" = true ] || return 1
    [ "$has_marker" = true ] && return 0
    _matches_render "$1" "$2"
}

to_remove_agents=(); foreign_agents=()
to_remove_skills=(); foreign_skills=()
declare -A SKILL_EXTRA=()

if [ -d "$PACK_AGENTS_DIR" ]; then
    for agent_file in "$SCRIPT_DIR/agents/"*.md; do
        [ -f "$agent_file" ] || continue
        target="$PACK_AGENTS_DIR/$(basename "$agent_file")"
        [ -f "$target" ] || continue
        if _owned "$agent_file" "$target"; then
            to_remove_agents+=("$target")
        else
            foreign_agents+=("$target")
        fi
    done
fi

if [ -d "$PACK_SKILLS_DIR" ]; then
    for skill_dir in "$SCRIPT_DIR/skills/"*/; do
        [ -d "$skill_dir" ] || continue
        skill_dir="${skill_dir%/}"
        skill_name="$(basename "$skill_dir")"
        [ -n "$skill_name" ] || continue
        target="$PACK_SKILLS_DIR/$skill_name"
        [ -d "$target" ] || continue
        _n=0
        while IFS= read -r -d '' _f; do
            [ -f "$skill_dir/${_f#"$target"/}" ] || _n=$((_n + 1))
        done < <(find "$target" -type f -print0)
        SKILL_EXTRA[$target]=$_n
        if _owned "$skill_dir/SKILL.md" "$target/SKILL.md"; then
            to_remove_skills+=("$target")
        else
            foreign_skills+=("$target")
        fi
    done
fi

if [ "$FORCE" = "1" ]; then
    to_remove_agents+=("${foreign_agents[@]}")
    to_remove_skills+=("${foreign_skills[@]}")
fi

remove_refs=false; remove_ns=false
[ -d "$PACK_REFS_INSTALL_DIR" ] && remove_refs=true
[ -d "$PACK_NS_DIR" ] && remove_ns=true

# User scope with --project-dir: report a second-scope install there, touch nothing.
if [ "$PACK_SCOPE" = "user" ] && [ -n "$PACK_PROJECT_ROOT" ] \
        && pack_scope_has_pack "$PACK_PROJECT_ROOT/.claude" "$SCRIPT_DIR"; then
    echo "  [note] $(pack_sanitize "$PACK_PROJECT_ROOT") also holds a project-scope install -- not touched;"
    echo "         remove it with --scope project --project-dir $(pack_shquote "$PACK_PROJECT_ROOT")."
    echo ""
fi

if [ ${#to_remove_agents[@]} -eq 0 ] && [ ${#to_remove_skills[@]} -eq 0 ] \
        && [ "$remove_refs" = false ] && [ "$remove_ns" = false ] \
        && [ "$remove_obsidian_env" = false ] && [ "$remove_obsidian_hooks" = false ]; then
    echo "Nothing to remove from $(pack_sanitize "$PACK_SCOPE_ROOT") -- no pack-owned agents, skills, references, or Obsidian config found."
    if [ $(( ${#foreign_agents[@]} + ${#foreign_skills[@]} )) -gt 0 ]; then
        echo "${#foreign_agents[@]} agent(s) and ${#foreign_skills[@]} skill(s) carry pack names but look foreign; re-run with --force to remove them."
    fi
    exit 0
fi

_skill_line() {  # _skill_line <target>
    local n="${SKILL_EXTRA[$1]:-0}"
    if [ "$n" -gt 0 ]; then
        echo "  skill: $(pack_sanitize "$(basename "$1")")  (includes $n file(s) the pack does not ship)"
    else
        echo "  skill: $(pack_sanitize "$(basename "$1")")"
    fi
}

echo "The following will be removed ($PACK_SCOPE scope, $(pack_sanitize "$PACK_SCOPE_ROOT")):"
echo ""
for path in "${to_remove_agents[@]}"; do echo "  agent: $(pack_sanitize "$(basename "$path")")"; done
for path in "${to_remove_skills[@]}"; do _skill_line "$path"; done
[ "$remove_refs" = true ] && echo "  refs:  $(pack_sanitize "$PACK_REFS_INSTALL_DIR")"
for path in "${stale_staging[@]}"; do echo "  stage: $(pack_sanitize "$path") (left by an interrupted install)"; done
[ "$remove_ns" = true ] && echo "  pack:  $(pack_sanitize "$PACK_NS_DIR")/{$AGENT_PACK_MARKER,$AGENT_PACK_GITIGNORE}"
OBSIDIAN_KEY_LIST="$(IFS=,; printf '%s' "${PACK_OBSIDIAN_ENV_KEYS[*]}")"
OBSIDIAN_KEY_LIST="${OBSIDIAN_KEY_LIST//,/, }"
[ "$remove_obsidian_env" = true ] && echo "  env:   $OBSIDIAN_KEY_LIST (~/.claude/settings.json)"
[ "$remove_obsidian_hooks" = true ] && echo "  hook:  obsidian hook scripts (~/.claude/scripts/obsidian-{stop,prompt,agent,context,memory}-hook.js)"
if [ "$FORCE" = "0" ] && [ $(( ${#foreign_agents[@]} + ${#foreign_skills[@]} )) -gt 0 ]; then
    echo ""
    echo "Foreign -- carry a pack name but are not this pack's install; will NOT be removed unless --force:"
    for path in "${foreign_agents[@]}"; do echo "  agent: $(pack_sanitize "$(basename "$path")")"; done
    for path in "${foreign_skills[@]}"; do _skill_line "$path"; done
fi

echo ""
# EOF on stdin is a "no", never an abort mid-removal.
response=""
read -rp "Remove these? [y/N] " response || response=""

if [ "$response" != "y" ] && [ "$response" != "Y" ]; then
    echo "Cancelled."
    exit 0
fi

echo ""
for path in "${to_remove_agents[@]}"; do
    pack_safe_rm_file "$path" "$PACK_SCOPE_ROOT" || exit 1
    echo "  Removed agent: $(pack_sanitize "$(basename "$path")")"
done
for path in "${to_remove_skills[@]}"; do
    pack_safe_rm_tree "$path" "$PACK_SCOPE_ROOT" || exit 1
    echo "  Removed skill: $(pack_sanitize "$(basename "$path")")"
done
if [ "$remove_refs" = true ]; then
    pack_safe_wipe_refs "$PACK_REFS_INSTALL_DIR" "$PACK_SCOPE_ROOT" || exit 1
    echo "  Removed refs:  $(pack_sanitize "$PACK_REFS_INSTALL_DIR")"
fi
for path in "${stale_staging[@]}"; do
    pack_safe_rm_staging "$path" "$PACK_NS_DIR" "$PACK_SCOPE_ROOT" || exit 1
    echo "  Removed stage: $(pack_sanitize "$path")"
done
if [ "$remove_ns" = true ]; then
    for _leaf in "$AGENT_PACK_MARKER" "$AGENT_PACK_GITIGNORE"; do
        if [ -e "$PACK_NS_DIR/$_leaf" ]; then
            pack_safe_rm_file "$PACK_NS_DIR/$_leaf" "$PACK_SCOPE_ROOT" || exit 1
        fi
    done
    # Anything else in agent-pack/ (e.g. removed-* backups of your files) is kept,
    # and the directory with it.
    if rmdir -- "$PACK_NS_DIR" 2>/dev/null; then
        echo "  Removed pack:  $(pack_sanitize "$PACK_NS_DIR")"
    else
        echo "  Kept:          $(pack_sanitize "$PACK_NS_DIR") (holds files the pack did not create, e.g. removed-* backups)"
    fi
fi

if [ "$remove_obsidian_env" = true ]; then
    pack_settings_remove_obsidian "$SETTINGS" env || { echo "ERROR: failed to update $(pack_sanitize "$SETTINGS")" >&2; exit 1; }
    echo "  Removed env:   $OBSIDIAN_KEY_LIST"
fi

if [ "$remove_obsidian_hooks" = true ]; then
    for _h in "${HOOK_FILES[@]}"; do
        [ -e "$_h" ] && { pack_safe_rm_file "$_h" "$HOME/.claude" || exit 1; }
    done
    # Remove all Obsidian hook entries and the decisions permission from settings.json
    if [ "$settings_tool_ok" = true ]; then
        pack_settings_remove_obsidian "$SETTINGS" hooks || { echo "ERROR: failed to update $(pack_sanitize "$SETTINGS")" >&2; exit 1; }
    fi
    echo "  Removed hook:  obsidian hook scripts and settings entries"
fi

if [ -n "${PACK_SETTINGS_BACKED_UP:-}" ] && [ -f "$PACK_SETTINGS_BACKED_UP.bak" ]; then
    echo "  Backup:        $(pack_sanitize "$PACK_SETTINGS_BACKED_UP.bak") (mode 0600)"
    echo "                 It still holds the OLD settings, including any OBSIDIAN_REST_API_KEY."
    echo "                 Delete it once you no longer need it."
fi

echo ""
echo "${#to_remove_agents[@]} agent(s) and ${#to_remove_skills[@]} skill(s) removed."

echo ""
if [ "$PACK_SCOPE" = "project" ]; then
    echo "Commit the removal so teammates and worktrees stop loading these agents:"
    echo "  git -C $(pack_shquote "$PACK_PROJECT_ROOT") add -A .claude/agents .claude/skills .claude/$AGENT_PACK_NS_NAME"
    echo ""
fi
echo "Note: project-level memory/ directories are not removed -- those live"
echo "in your repositories and are managed like any other project file."
