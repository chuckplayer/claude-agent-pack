#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Non-interactive support -------------------------------------------------
# Every prompt below goes through `prompt`, never a bare `read`. Two reasons:
#
# 1. Under `set -e`, a `read` that hits EOF returns non-zero and aborts the script
#    on the spot. With no TTY (a tool call, CI, or any `bash install.sh | ...`)
#    that killed the run at the first prompt -- after the agent/skill copies had
#    already printed their [ok] lines, so the output looked like a completed
#    install while the Obsidian hook scripts were never copied.
# 2. `--yes` lets a configured machine re-install unattended, keeping its existing
#    vault settings, which is the common case when only a hook script changed.
#
# An empty reply means "take the default", which is what every call site's
# ${var:-default} already assumed -- so behaviour with a TTY is unchanged.
ASSUME_DEFAULTS=0
SCOPE="user"
PROJECT_DIR_GIVEN=0
PROJECT_DIR_ARG=""
FORCE=0

usage() {
    echo "Usage: bash install.sh [--scope user|project] [--project-dir DIR] [--force] [--yes]"
    echo
    echo "  --scope user       Install into ~/.claude (default -- the behaviour with no flags)."
    echo "  --scope project    Install into <project>/.claude, to be committed with the project."
    echo "                     Skips the settings.json, Obsidian, and Codex blocks entirely."
    echo "  --project-dir DIR  With --scope project: the project to install into (default: the"
    echo "                     current directory's git toplevel). With --scope user: a project to"
    echo "                     inspect for a conflicting project-scope install. Validated the"
    echo "                     same way in both cases, and in all four pack scripts."
    echo "  --force            Install even though the other scope already holds a pack install."
    echo "                     Both copies will then be live."
    echo "  --yes, -y          Accept the default at every prompt (keeps existing"
    echo "                     Obsidian settings). Implied when stdin is not a TTY."
    echo "  --help, -h         Show this message."
    echo
    echo "Notes:"
    echo "  - Each skill directory with a pack name (skills/<name>/) is REPLACED WHOLE. Files"
    echo "    you added inside a pack-named skill directory are removed. Interactively you are"
    echo "    asked first (default No); with --yes or no TTY they are first copied to"
    echo "    <scope>/agent-pack/removed-<timestamp>/ and the location is printed."
    echo "  - The second-scope check can only see one project: with --scope user it inspects"
    echo "    --project-dir, or else the current directory's git toplevel. A project elsewhere"
    echo "    on disk that holds a project-scope install is NOT detected."
    echo "  - The other scope counts as holding the pack when its agent-pack/.installed marker"
    echo "    exists, or at least half the pack's agent names are present (older installs)."
}

while [ $# -gt 0 ]; do
    case "$1" in
        -y|--yes|--non-interactive)
            ASSUME_DEFAULTS=1
            ;;
        --scope)
            [ $# -ge 2 ] || { echo "ERROR: --scope needs a value (user|project)" >&2; exit 1; }
            SCOPE="$2"; shift
            ;;
        --scope=*)
            SCOPE="${1#--scope=}"
            ;;
        --project-dir)
            [ $# -ge 2 ] || { echo "ERROR: --project-dir needs a value" >&2; exit 1; }
            PROJECT_DIR_GIVEN=1; PROJECT_DIR_ARG="$2"; shift
            ;;
        --project-dir=*)
            PROJECT_DIR_GIVEN=1; PROJECT_DIR_ARG="${1#--project-dir=}"
            ;;
        --force)
            FORCE=1
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "ERROR: unknown option '$1' (try --help)" >&2
            exit 1
            ;;
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

if [ "$ASSUME_DEFAULTS" = "0" ] && [ ! -t 0 ]; then
    ASSUME_DEFAULTS=1
    echo "No TTY on stdin -- running non-interactively, taking the default at every prompt."
    echo "Re-run in a terminal to change any setting."
    echo
fi

# prompt <varname> <prompt-text>
# Sets <varname> to the user's reply, or empty when non-interactive. Never fails.
prompt() {
    local __var="$1" __text="$2" __reply=""
    if [ "$ASSUME_DEFAULTS" = "1" ]; then
        printf '%s[default]\n' "$__text"
    else
        read -rp "$__text" __reply || __reply=""
    fi
    printf -v "$__var" '%s' "$__reply"
}

# prompt_secret <varname> <prompt-text> -- as prompt, but the reply is not echoed.
prompt_secret() {
    local __var="$1" __text="$2" __reply=""
    if [ "$ASSUME_DEFAULTS" = "1" ]; then
        printf '%s[default]\n' "$__text"
    else
        read -rsp "$__text" __reply || __reply=""
        echo
    fi
    printf -v "$__var" '%s' "$__reply"
}

# --- Scope ---------------------------------------------------------------------
# user    -> $HOME/.claude            (token renders to ~/.claude/agent-pack/references)
# project -> <project>/.claude        (token renders to .claude/agent-pack/references)
# The project directory is validated (real dir, not /, not $HOME, not this pack
# repo, inside a git work tree) before any path under it is computed, let alone
# removed. With --scope user, --project-dir is only read, for the conflict check.
pack_init_scope "$SCOPE" "$PROJECT_DIR_GIVEN" "$PROJECT_DIR_ARG" "$SCRIPT_DIR" || exit 1

if [ "$PACK_SCOPE" = "user" ] && [ ! -d "$PACK_SCOPE_ROOT" ]; then
    echo "ERROR: Claude Code directory not found at $PACK_SCOPE_ROOT"
    echo "Install Claude Code first: https://code.claude.com"
    exit 1
fi

VERSION=$(cat "$SCRIPT_DIR/VERSION")
echo "Claude Agent Pack v$VERSION"
echo "  scope:  $PACK_SCOPE ($(pack_sanitize "$PACK_SCOPE_ROOT"))"
echo ""

# --- Refuse a second scope ------------------------------------------------------
# Claude Code resolves agents project-over-user but skills user-over-project, so
# with the pack in both scopes a session runs a project agent next to a user
# skill -- possibly from two different pack versions -- and nothing reports it.
#
# The other scope counts as holding the pack only under pack_scope_has_pack: its
# agent-pack/.installed marker exists, or at least half the pack's agent names are
# there (installs made before the marker). A single same-named foreign agent or
# skill is never a collision.
#
# LIMITATION: from user scope the only project visible is --project-dir or the
# current directory's git toplevel; a project-scope install elsewhere is not seen.
OTHER_ROOT="$(pack_other_scope_root "$PACK_SCOPE" "$PACK_PROJECT_ROOT")"
if [ -n "$OTHER_ROOT" ] && pack_scope_has_pack "$OTHER_ROOT" "$SCRIPT_DIR"; then
    if [ "$FORCE" = "1" ]; then
        echo "  ************************************************************************"
        echo "  WARNING: --force -- installing into $PACK_SCOPE scope while the $PACK_OTHER_SCOPE"
        echo "  scope already holds this pack: $(pack_sanitize "$OTHER_ROOT")"
        echo "  ($(pack_sanitize "$PACK_HAS_PACK_WHY"))."
        echo "  Agents resolve project-over-user; skills resolve user-over-project."
        echo "  Sessions in that project will MIX the two copies. Run"
        echo "  scripts/check-updates.sh to see which copy wins for each name."
        echo "  ************************************************************************"
        echo ""
    else
        {
            echo "ERROR: the $PACK_OTHER_SCOPE scope already holds an install of this pack:"
            echo "       $(pack_sanitize "$OTHER_ROOT")"
            echo "       ($(pack_sanitize "$PACK_HAS_PACK_WHY"))"
            echo ""
            echo "  Agents resolve project-over-user but skills resolve user-over-project, so"
            echo "  both scopes installed means one session mixes two copies, possibly of"
            echo "  different pack versions. Choose one:"
            echo ""
            if [ "$PACK_OTHER_SCOPE" = "user" ]; then
                echo "  a) Remove the user-scope install first:  bash uninstall.sh --scope user"
                echo "     CAUTION: that also removes the Obsidian env vars, the Obsidian hook"
                echo "     scripts, and the settings.json hook entries the pack manages."
            else
                echo "  a) Remove the project-scope install first:"
                echo "       bash uninstall.sh --scope project --project-dir $(pack_shquote "${OTHER_ROOT%/.claude}")"
                echo "     CAUTION: that deletes the pack-named agents and skills from that"
                echo "     project's .claude/ -- files teammates get once the removal is committed."
            fi
            echo "  b) Install anyway with --force. Both copies stay live; check-updates.sh"
            echo "     then reports which copy wins for each name."
            echo ""
            echo "  Note: from user scope this check only sees --project-dir or the current"
            echo "  directory's git toplevel; project installs elsewhere are not detected."
        } >&2
        exit 1
    fi
elif [ -n "$OTHER_ROOT" ]; then
    _same_named="$(pack_list_shipped_in "$OTHER_ROOT" "$SCRIPT_DIR" | wc -l | tr -d ' ')"
    if [ "$_same_named" -gt 0 ]; then
        echo "  [note] $_same_named same-named agent/skill file(s) in $(pack_sanitize "$OTHER_ROOT"), but no pack"
        echo "         install there (no marker, fewer than half the agent names) -- continuing."
        echo ""
    fi
fi

# --- Run state ----------------------------------------------------------------------
# Every variable the EXIT trap or the swap functions read is initialised here,
# before any of them is defined or can run.
STAGE=""                 # this run's staging dir
ASIDE=""                 # $STAGE/$AGENT_PACK_ASIDE_NAME -- previous copies set aside during the swap
KEEP_STAGE=0             # 1 = never delete $STAGE (it holds the only copy of something)
SWAP_ACTIVE=0            # 1 between the first and the last rename of the swap
SWAP_TARGETS=()          # every target recorded BEFORE its first rename
SWAP_ASIDES=()           # its aside path
SWAP_HAD=()              # 1 if the target existed when recorded
SWAP_RESTORE_FAILED=0    # 1 once any rollback step failed
KEPT_REPORTED=0          # 1 once the kept-staging message has been printed
_claude_created=0
_agent_pack_created=0

# --- Stage ------------------------------------------------------------------------
# Everything is rendered into a staging directory first and checked there. Only a
# staged tree that passes the token assert is swapped in, so a failed render or a
# failed assert leaves the previous install exactly as it was.
#
# The staging dir lives under <scope>/agent-pack/ -- the namespace this installer
# owns -- so the final moves are same-filesystem renames, and it is never inside
# agents/ or skills/ where the router would see it. agent-pack/.gitignore ignores
# staging, temp and backup entries so none of them can be committed.
pack_check_scope_links "$PACK_SCOPE_ROOT" || exit 1
[ -d "$PACK_SCOPE_ROOT" ] || _claude_created=1
[ -d "$PACK_NS_DIR" ] || _agent_pack_created=1
mkdir -p "$PACK_NS_DIR"
pack_check_scope_links "$PACK_SCOPE_ROOT" || exit 1
if [ ! -f "$PACK_NS_DIR/$AGENT_PACK_GITIGNORE" ] \
        || [ "$(cat "$PACK_NS_DIR/$AGENT_PACK_GITIGNORE")" != "$AGENT_PACK_GITIGNORE_CONTENT" ]; then
    printf '%s\n' "$AGENT_PACK_GITIGNORE_CONTENT" \
        | pack_write_ns_file "$PACK_NS_DIR" "$AGENT_PACK_GITIGNORE" "$PACK_SCOPE_ROOT" || exit 1
fi

# Sweep staging dirs left by an earlier run that was killed (SIGKILL, power loss).
# A staging dir whose aside/ still holds files is the only copy of a previous
# install that a failed rollback could not restore: stop, show it, delete nothing.
# Not safe against a second install.sh running concurrently on the same scope.
while IFS= read -r -d '' _stale; do
    if pack_staging_has_aside "$_stale"; then
        {
            echo "ERROR: a staging dir from an earlier run still holds set-aside copies of a"
            echo "       previous install (its rollback failed). Nothing has been changed."
            pack_show_staging "$_stale"
            echo "       Move those files back into $(pack_sanitize "$PACK_SCOPE_ROOT") by hand, or delete the"
            echo "       directory if you do not need them, then re-run install.sh."
        } >&2
        exit 1
    fi
    pack_safe_rm_staging "$_stale" "$PACK_NS_DIR" "$PACK_SCOPE_ROOT" || exit 1
    echo "  [rm] stale staging dir from an interrupted run: $(pack_sanitize "$_stale")"
done < <(pack_list_staging "$PACK_NS_DIR")

# rollback_swap -- undo every recorded swap, newest first, judged by what is on
# disk: an entry may have been recorded and then interrupted before either rename.
#
# KEEP_STAGE is raised on entry and lowered only after every step succeeded. A
# second signal arriving mid-rollback runs `exit 130`; the EXIT trap then sees
# SWAP_ACTIVE=0 (no second rollback) but KEEP_STAGE=1, so the staging dir -- which
# still holds the set-aside copies not yet restored -- is kept, not deleted.
#
# A target is only ever deleted on an explicit SWAP_HAD of 0 (it did not exist
# before, so whatever is there now is the new copy) or 1 with its aside copy
# present (the old copy is safe in aside/). swap_one appends to the three arrays
# BEFORE either rename, so an entry whose HAD is empty or missing -- a signal
# between the appends -- had no rename at all: its target is the user's original
# and is left exactly as it is.
rollback_swap() {
    local i t a h
    KEEP_STAGE=1
    SWAP_ACTIVE=0
    for (( i=${#SWAP_TARGETS[@]}-1; i>=0; i-- )); do
        t="${SWAP_TARGETS[$i]}"; a="${SWAP_ASIDES[$i]:-}"; h="${SWAP_HAD[$i]:-}"
        case "$h" in
            1) if [ -z "$a" ] || [ ! -e "$a" ]; then continue; fi ;;   # old copy never moved
            0) ;;
            *) continue ;;                                              # incompletely recorded: touch nothing
        esac
        if [ -e "$t" ] && ! pack_safe_rm_tree "$t" "$PACK_SCOPE_ROOT"; then
            echo "  CRITICAL: could not remove the new copy $(pack_sanitize "$t") during rollback" >&2
            SWAP_RESTORE_FAILED=1
            continue
        fi
        if [ "$h" = "1" ] && ! mv -- "$a" "$t"; then
            echo "  CRITICAL: could not restore $(pack_sanitize "$t") from $(pack_sanitize "$a")" >&2
            SWAP_RESTORE_FAILED=1
        fi
    done
    if [ "$SWAP_RESTORE_FAILED" = "1" ]; then
        return 1                          # KEEP_STAGE stays 1
    fi
    SWAP_TARGETS=(); SWAP_ASIDES=(); SWAP_HAD=()
    KEEP_STAGE=0
    return 0
}

_report_kept_stage() {
    [ "$KEPT_REPORTED" = "1" ] && return 0
    KEPT_REPORTED=1
    {
        echo "       ROLLBACK INCOMPLETE -- see the CRITICAL lines above. The set-aside"
        echo "       copies of the previous install are kept in:"
        echo "         $(pack_sanitize "$ASIDE")"
        echo "       Move them back by hand. install.sh, uninstall.sh and check-updates.sh"
        echo "       will not delete that directory while it holds files."
    } >&2
}

# _rollback_and_report -- roll back and say how it went (die_swap and the EXIT trap).
_rollback_and_report() {
    if rollback_swap; then
        echo "       Swap rolled back -- the previous install in $(pack_sanitize "$PACK_SCOPE_ROOT") is intact." >&2
    else
        _report_kept_stage
    fi
}

_cleanup_stage() {
    # errexit off for the whole handler: after a SIGHUP stderr may be gone, and a
    # failing echo must not end the handler before the rollback below has run.
    set +e
    # An abort in the middle of the swap (set -e, a signal) must put the previous
    # install back BEFORE the staging dir -- which holds the set-aside copies -- is
    # removed, and must never remove it when that rollback failed.
    if [ "$SWAP_ACTIVE" = "1" ]; then
        echo "" >&2
        echo "ERROR: interrupted during the swap -- rolling back." >&2
        _rollback_and_report
    fi
    if [ "$KEEP_STAGE" = "1" ] && [ -n "$STAGE" ] && [ -d "$STAGE" ]; then
        # Reached when a rollback failed, or was itself interrupted by a second
        # signal: say where the un-restored copies are.
        if [ "$SWAP_RESTORE_FAILED" = "0" ]; then
            echo "" >&2
            echo "ERROR: interrupted during the rollback." >&2
        fi
        _report_kept_stage
    fi
    if [ "$KEEP_STAGE" = "0" ] && [ -n "$STAGE" ] && [ -d "$STAGE" ]; then
        pack_safe_rm_staging "$STAGE" "$PACK_NS_DIR" "$PACK_SCOPE_ROOT" own || true
    fi
    if [ "$KEEP_STAGE" = "0" ] && [ "$_agent_pack_created" = "1" ] \
            && [ ! -d "$PACK_REFS_INSTALL_DIR" ]; then
        rm -f -- "$PACK_NS_DIR/$AGENT_PACK_GITIGNORE"
        rmdir -- "$PACK_NS_DIR" 2>/dev/null || true
    fi
    if [ "$KEEP_STAGE" = "0" ] && [ "$_claude_created" = "1" ]; then
        rmdir -- "$PACK_SCOPE_ROOT" 2>/dev/null || true
    fi
}
trap _cleanup_stage EXIT
trap 'exit 130' INT TERM HUP

STAGE="$(mktemp -d "$PACK_NS_DIR/${AGENT_PACK_STAGING_PREFIX}XXXXXX")"
ASIDE="$STAGE/$AGENT_PACK_ASIDE_NAME"

die_staging() {
    echo "" >&2
    echo "ERROR: $*" >&2
    echo "       Nothing was swapped in -- the previous install in $(pack_sanitize "$PACK_SCOPE_ROOT") is untouched." >&2
    exit 1
}

src_token_files=0
rendered_token_targets=()

# stage_file <src> <dst> -- render one file and record whether it held the token.
stage_file() {
    local src="$1" dst="$2" rc=0
    pack_file_has_token "$src" || rc=$?
    case "$rc" in
        0) src_token_files=$((src_token_files + 1)); rendered_token_targets+=("$dst") ;;
        1) ;;
        *) die_staging "could not scan $(pack_sanitize "$src") for the token" ;;
    esac
    render_pack_file "$src" "$dst" "$PACK_REFS_REPLACEMENT" || die_staging "failed to render $(pack_sanitize "$src")"
}

# stage_tree <src-dir> <dst-dir> -- every file, recursively, relative paths kept.
stage_tree() {
    local src="$1" dst="$2" list rc=0 f
    mkdir -p "$dst"
    list="$(mktemp)"
    find "$src" -type f -print0 > "$list" || rc=$?
    [ "$rc" -eq 0 ] || { rm -f "$list"; die_staging "find failed (exit $rc) listing $(pack_sanitize "$src")"; }
    while IFS= read -r -d '' f; do
        stage_file "$f" "$dst/${f#"$src"/}"
    done < "$list"
    rm -f "$list"
}

if [ -d "$SCRIPT_DIR/references" ]; then
    stage_tree "$SCRIPT_DIR/references" "$STAGE/$AGENT_PACK_REFS_NAME"
else
    mkdir -p "$STAGE/$AGENT_PACK_REFS_NAME"
fi

mkdir -p "$STAGE/agents"
for agent_file in "$SCRIPT_DIR/agents/"*.md; do
    [ -f "$agent_file" ] || continue
    stage_file "$agent_file" "$STAGE/agents/$(basename "$agent_file")"
done

mkdir -p "$STAGE/skills"
for skill_dir in "$SCRIPT_DIR/skills/"*/; do
    [ -d "$skill_dir" ] || continue
    skill_dir="${skill_dir%/}"
    skill_name="$(basename "$skill_dir")"
    [ -f "$skill_dir/SKILL.md" ] || die_staging "skills/$skill_name has no SKILL.md"
    stage_tree "$skill_dir" "$STAGE/skills/$skill_name"
done

# --- Assert on the staged tree ----------------------------------------------------
# 1. Zero occurrences of the exact token remain anywhere in the staged tree. A
#    token in a file that is not rendered (anything but *.md) survives the copy and
#    is caught here rather than shipped as a dead pointer.
# 2. Positive control: when any *.md source held the token, every one of them now
#    contains the replacement, and the staged tree's total is > 0. Without this, a
#    render that silently dropped the token (or the line) would pass check 1.
_leftover=""
_rc=0
_leftover="$(grep -rlF -- "$AGENT_PACK_TOKEN" "$STAGE")" || _rc=$?
case "$_rc" in
    0) die_staging "token $AGENT_PACK_TOKEN survived rendering in:
$(printf '         %s\n' "$(pack_sanitize "${_leftover//"$STAGE"/<stage>}")")
       Only *.md files are rendered; move the pointer into a .md file." ;;
    1) ;;
    *) die_staging "grep failed (exit $_rc) asserting the staged tree is token-free" ;;
esac
if [ "$src_token_files" -gt 0 ]; then
    _rendered="$(count_fixed "$PACK_REFS_REPLACEMENT" "$STAGE")" || die_staging "could not count rendered pointers"
    [ "$_rendered" -gt 0 ] || die_staging "positive control failed: $src_token_files source file(s) held the token but the staged tree has no '$PACK_REFS_REPLACEMENT'"
    for _t in "${rendered_token_targets[@]}"; do
        _rc=0
        grep -qF -- "$PACK_REFS_REPLACEMENT" "$_t" || _rc=$?
        [ "$_rc" -eq 0 ] || die_staging "positive control failed: $(pack_sanitize "${_t#"$STAGE"/}") held the token but has no '$PACK_REFS_REPLACEMENT' after rendering (grep exit $_rc)"
    done
    echo "  [ok] render: $src_token_files file(s) with pointers, $_rendered rendered to '$PACK_REFS_REPLACEMENT', 0 tokens left"
else
    echo "  [ok] render: no pointers yet (no source file contains $AGENT_PACK_TOKEN); 0 tokens left"
fi
echo ""

# --- Local files the skill swap would remove ----------------------------------------
# A pack-named skill directory is replaced whole. Any file inside it that the pack
# does not ship is listed BEFORE anything is swapped. Interactively the user must
# agree (default No). Non-interactively (--yes / no TTY) nothing is asked, but the
# files are first copied to <scope>/agent-pack/removed-<UTC timestamp>/<skill>/
# so nothing becomes unrecoverable.
declare -A EXTRA_NAMES=()
declare -A EXTRA_COUNT=()
extra_all=()
for staged in "$STAGE/skills/"*/; do
    [ -d "$staged" ] || continue
    staged="${staged%/}"
    skill_name="$(basename "$staged")"
    target="$PACK_SKILLS_DIR/$skill_name"
    [ -d "$target" ] || continue
    while IFS= read -r -d '' _f; do
        _rel="${_f#"$target"/}"
        if [ ! -f "$staged/$_rel" ]; then
            extra_all+=("$skill_name/$_rel")
            EXTRA_COUNT[$skill_name]=$(( ${EXTRA_COUNT[$skill_name]:-0} + 1 ))
            EXTRA_NAMES[$skill_name]="${EXTRA_NAMES[$skill_name]:+${EXTRA_NAMES[$skill_name]} }$(pack_sanitize "$_rel")"
        fi
    done < <(find "$target" -type f -print0)
done
if [ ${#extra_all[@]} -gt 0 ]; then
    echo "  These ${#extra_all[@]} file(s) inside pack-named skill directories are not shipped by"
    echo "  the pack and will be REMOVED when those directories are replaced:"
    for _e in "${extra_all[@]}"; do echo "    skills/$(pack_sanitize "$_e")"; done
    if [ "$ASSUME_DEFAULTS" = "1" ]; then
        _backup="$PACK_NS_DIR/${AGENT_PACK_REMOVED_PREFIX}$(date -u +%Y%m%dT%H%M%SZ)"
        [ -e "$_backup" ] && _backup="$_backup-$$"
        pack_guard_inside "$_backup" "$PACK_SCOPE_ROOT" || die_staging "refused to create a backup dir"
        for _e in "${extra_all[@]}"; do
            mkdir -p -- "$(dirname -- "$_backup/$_e")" || die_staging "could not create backup dir"
            cp -p -- "$PACK_SKILLS_DIR/$_e" "$_backup/$_e" || die_staging "could not back up skills/$(pack_sanitize "$_e")"
        done
        echo "  Non-interactive: copied them first to $(pack_sanitize "$_backup")"
    else
        _reply=""
        prompt _reply "  Remove them? [y/N] "
        if [ "$_reply" != "y" ] && [ "$_reply" != "Y" ]; then
            die_staging "aborted -- move those files out of the skill directories, then re-run."
        fi
    fi
    echo ""
fi

# --- Swap: references, then agents, then skills -------------------------------------
# Each target is recorded first, then renamed ASIDE (into $STAGE/aside, same
# filesystem), then the staged copy is renamed into its place. If anything fails or
# a signal arrives, rollback_swap puts back every recorded target, newest first,
# and the run exits non-zero. The aside copies are deleted (with $STAGE) only after
# the whole swap has succeeded, and never when a rollback step failed.
#
# References first so that no installed agent or skill can point at a references
# file that has not landed yet. The references dir is owned wholesale, so a renamed
# or deleted reference needs no retired list.

# swap_one <staged> <target> <aside>
swap_one() {
    local staged="$1" target="$2" aside="$3" had=0
    pack_guard_inside "$target" "$PACK_SCOPE_ROOT" || return 1
    mkdir -p -- "$(dirname -- "$aside")" || return 1
    [ -e "$target" ] && had=1
    SWAP_TARGETS+=("$target"); SWAP_ASIDES+=("$aside"); SWAP_HAD+=("$had")
    if [ "$had" = "1" ]; then
        mv -- "$target" "$aside" || { echo "  swap: could not set aside $(pack_sanitize "$target")" >&2; return 1; }
    fi
    mv -- "$staged" "$target" || { echo "  swap: could not move the new copy into $(pack_sanitize "$target")" >&2; return 1; }
}

die_swap() {
    echo "" >&2
    echo "ERROR: $*" >&2
    _rollback_and_report
    exit 1
}

pack_guard_refs_target "$PACK_REFS_INSTALL_DIR" "$PACK_SCOPE_ROOT" || die_staging "refused to replace $(pack_sanitize "$PACK_REFS_INSTALL_DIR")"
_ok_lines=()
SWAP_ACTIVE=1

swap_one "$STAGE/$AGENT_PACK_REFS_NAME" "$PACK_REFS_INSTALL_DIR" "$ASIDE/$AGENT_PACK_REFS_NAME" \
    || die_swap "could not swap in references"
_ok_lines+=("  [ok] references: $(count_files "$PACK_REFS_INSTALL_DIR") file(s) -> $(pack_sanitize "$PACK_REFS_INSTALL_DIR")" "")

mkdir -p "$PACK_AGENTS_DIR"
for staged in "$STAGE/agents/"*.md; do
    [ -f "$staged" ] || continue
    filename="$(basename "$staged")"
    swap_one "$staged" "$PACK_AGENTS_DIR/$filename" "$ASIDE/agents/$filename" \
        || die_swap "could not swap in agent $(pack_sanitize "$filename")"
    _ok_lines+=("  [ok] agent:  $(pack_sanitize "${filename%.md}")")
done
_ok_lines+=("")

mkdir -p "$PACK_SKILLS_DIR"
for staged in "$STAGE/skills/"*/; do
    [ -d "$staged" ] || continue
    staged="${staged%/}"
    skill_name="$(basename "$staged")"
    [ -n "$skill_name" ] || continue
    target="$PACK_SKILLS_DIR/$skill_name"
    swap_one "$staged" "$target" "$ASIDE/skills/$skill_name" \
        || die_swap "could not swap in skill $(pack_sanitize "$skill_name")"
    if [ -n "${EXTRA_COUNT[$skill_name]:-}" ]; then
        _ok_lines+=("  [ok] skill:  $(pack_sanitize "$skill_name")  (directory replaced whole: $(count_files "$target") file(s) installed, ${EXTRA_COUNT[$skill_name]} local file(s) REMOVED: ${EXTRA_NAMES[$skill_name]})")
    else
        _ok_lines+=("  [ok] skill:  $(pack_sanitize "$skill_name")")
    fi
done

# Commit point: everything is in place. The aside copies go with $STAGE.
SWAP_ACTIVE=0
printf '%s\n' "${_ok_lines[@]}"

# Marker read by the second-scope check (pack_scope_has_pack) in either scope.
# Written through a temp file + rename, never through an existing link.
printf 'version=%s\nscope=%s\ninstalled=%s\n' "$VERSION" "$PACK_SCOPE" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    | pack_write_ns_file "$PACK_NS_DIR" "$AGENT_PACK_MARKER" "$PACK_SCOPE_ROOT" \
    || echo "  WARNING: could not write $(pack_sanitize "$PACK_NS_DIR/$AGENT_PACK_MARKER")" >&2

# Retired agents and skills (PACK_RETIRED_* in scripts/lib/pack-common.sh).
# In project scope these are only REPORTED, never deleted: a project's .claude/ is
# committed, shared, and may hold a same-named skill a teammate wrote on purpose.
deprecated_removed=0
for name in "${PACK_RETIRED_SKILLS[@]}"; do
    target="$PACK_SKILLS_DIR/$name"
    if [ -d "$target" ]; then
        if [ "$PACK_SCOPE" = "project" ]; then
            echo "  [!!] skill:  $name (retired from the pack -- NOT removed in project scope; delete $(pack_sanitize "$target") and commit if it is the pack's)"
        else
            pack_safe_rm_tree "$target" "$PACK_SCOPE_ROOT" || exit 1
            echo "  [rm] skill:  $name (deprecated)"
        fi
        deprecated_removed=$((deprecated_removed + 1))
    fi
done
for name in "${PACK_RETIRED_AGENTS[@]}"; do
    target="$PACK_AGENTS_DIR/$name.md"
    if [ -f "$target" ]; then
        if [ "$PACK_SCOPE" = "project" ]; then
            echo "  [!!] agent:  $name (retired from the pack -- NOT removed in project scope; delete $(pack_sanitize "$target") and commit if it is the pack's)"
        else
            pack_safe_rm_file "$target" "$PACK_SCOPE_ROOT" || exit 1
            echo "  [rm] agent:  $name (deprecated)"
        fi
        deprecated_removed=$((deprecated_removed + 1))
    fi
done
[ "$deprecated_removed" -gt 0 ] && echo ""

# --- Project scope ends here ---------------------------------------------------------
# Everything below writes ~/.claude/settings.json (worktree.baseRef, Obsidian env
# and hooks with absolute node paths, Codex model). None of it may land in a
# project's .claude/settings.json, which is committed -- so project scope only
# READS settings, to warn, and stops.
if [ "$PACK_SCOPE" = "project" ]; then
    echo ""
    _ign_rc=0
    git -C "$PACK_PROJECT_ROOT" check-ignore -q .claude/agents 2>/dev/null || _ign_rc=$?
    case "$_ign_rc" in
        0)   echo "  WARNING: .claude/ is git-ignored in $(pack_sanitize "$PACK_PROJECT_ROOT") -- teammates and worktrees will not get these agents." ;;
        1)   ;;
        *)   echo "  WARNING: could not determine whether .claude/ is git-ignored (git check-ignore exit $_ign_rc)." ;;
    esac
    echo "  commit .claude/ so teammates and worktrees get the same agents"

    # Effective worktree.baseRef: settings.local.json > settings.json > user settings.
    _br_local="$(pack_sanitize "$(pack_read_base_ref "$PACK_SCOPE_ROOT/settings.local.json")")"
    _br_proj="$(pack_sanitize "$(pack_read_base_ref "$PACK_SCOPE_ROOT/settings.json")")"
    _br_user="$(pack_sanitize "$(pack_read_base_ref "$HOME/.claude/settings.json")")"
    _br_eff="${_br_local:-${_br_proj:-$_br_user}}"
    if [ "$_br_eff" != "head" ]; then
        echo "  WARNING: effective worktree.baseRef is '${_br_eff:-unset, defaults to fresh}', not \"head\""
        echo "           (project .claude/settings.local.json: '${_br_local:-unset}', .claude/settings.json: '${_br_proj:-unset}',"
        echo "            ~/.claude/settings.json: '${_br_user:-unset}'). Engineer worktrees will base off main"
        echo "           instead of your feature branch. Not changed -- project scope never writes settings."
    fi

    echo ""
    echo "Next steps:"
    echo ""
    echo "  1. Commit the installed files:"
    echo "     git -C $(pack_shquote "$PACK_PROJECT_ROOT") add .claude/agents .claude/skills .claude/$AGENT_PACK_NS_NAME"
    echo ""
    echo "  2. Verify:"
    echo "     $(pack_shquote "$SCRIPT_DIR/scripts/check-readiness.sh") --scope project --project-dir $(pack_shquote "$PACK_PROJECT_ROOT")"
    echo ""
    echo "Skipped in project scope: settings.json (worktree.baseRef), Obsidian, and Codex setup."
    echo "Those are user-level; set them in ~/.claude/settings.json. (A --scope user install"
    echo "would also install the agents into ~/.claude and is refused while this project has them.)"
    exit 0
fi

# User scope only from here on. Every settings.json read and write below goes
# through the library (pack_settings_* / pack_py / pack_node): one secure writer
# -- exclusive 0600 temp file, the original's mode copied onto it, UTF-8,
# symlink-safe, atomic rename, python always -I -- and a 0600 .bak of the file is
# taken before the first modification.
# shellcheck disable=SC2088  # "~/..." is expanded by the interpreter, not the shell
SETTINGS_PATH="~/.claude/settings.json"
pack_settings_backup "$SETTINGS_PATH" \
    || echo "  WARNING: could not back up ~/.claude/settings.json to settings.json.bak" >&2

# settings_write_failed <what> -- a settings write failed. Under set -e a bare
# failing writer used to exit silently; say what failed, and that the previous
# file is intact (writes are atomic), then stop.
settings_write_failed() {
    echo "  ERROR: failed to update ~/.claude/settings.json ($1)." >&2
    echo "         The previous file is unchanged; re-run install.sh after fixing the cause above." >&2
    exit 1
}

# Ensure worktree.baseRef is set so isolation:"worktree" (used by every engineer
# agent in the pipeline) branches from the current HEAD instead of the harness
# default ("fresh" -- local/origin main). Without this, engineer worktrees are
# silently based on main regardless of the feature branch you're working on --
# see agents/git-engineer.md and skills/implement/SKILL.md step 5b.
echo ""
# One probe for the whole settings section (pack_find_json_tool): python3, python,
# then node, each liveness-tested (Windows ships a python3 Store stub that fails).
pack_find_json_tool || true
json_tool="$PACK_JSON_TOOL"

if [ -z "$json_tool" ]; then
    echo "  WARNING: python3 or node is required to set worktree.baseRef -- neither found."
    echo "           Add \"worktree\": { \"baseRef\": \"head\" } to ~/.claude/settings.json manually."
elif [ "$json_tool" = "node" ]; then
    pack_node - "$SETTINGS_PATH" <<'JSEOF' || settings_write_failed "worktree.baseRef"
const p=process.argv[2];
const s=packLoad(p);
if(!s.worktree)s.worktree={};
if(!s.worktree.baseRef){
  s.worktree.baseRef='head';
  packWrite(p,s);
  console.log('  [ok] settings: worktree.baseRef=head');
}else{
  console.log('  [skip] worktree.baseRef already set to "'+s.worktree.baseRef+'" -- leaving as-is');
}
JSEOF
else
    pack_py - "$SETTINGS_PATH" <<'PYEOF' || settings_write_failed "worktree.baseRef"
import sys
p = sys.argv[1]
s = pack_load(p)
wt = s.setdefault("worktree", {})
if not wt.get("baseRef"):
    wt["baseRef"] = "head"
    pack_write(p, s)
    print('  [ok] settings: worktree.baseRef=head')
else:
    print('  [skip] worktree.baseRef already set to "%s" -- leaving as-is' % wt["baseRef"])
PYEOF
fi

# Optional: Obsidian vault integration
echo ""

# Same JSON tool as above ($json_tool from pack_find_json_tool).
if [ -z "$json_tool" ]; then
    echo "  WARNING: python3 or node is required for Obsidian setup — neither found."
    echo "  Install either and re-run install.sh to complete Obsidian setup."
else
    # Existing values (empty if not previously configured)
    current_vault="$(pack_settings_get_env "$SETTINGS_PATH" OBSIDIAN_VAULT_PATH)"
    current_projects_folder="$(pack_settings_get_env "$SETTINGS_PATH" OBSIDIAN_PROJECTS_FOLDER)"
    current_api_key="$(pack_settings_get_env "$SETTINGS_PATH" OBSIDIAN_REST_API_KEY)"

    obsidian_setup=false
    vault_path=""
    projects_folder=""

    if [ -n "$current_vault" ]; then
        echo "Obsidian integration is active (vault: $(pack_sanitize "$current_vault"))"
        prompt keep_response "  Keep Obsidian integration? [Y/n] "
        if [ "$keep_response" = "n" ] || [ "$keep_response" = "N" ]; then
            # Remove all Obsidian env vars and all hook entries from settings.json:
            # the library's one implementation (python). Node-only machines keep a
            # node branch, because the library's remover needs python.
            if [ "$json_tool" = "node" ]; then
                pack_node - "$SETTINGS_PATH" "${PACK_OBSIDIAN_ENV_KEYS[@]}" <<'JSEOF' || settings_write_failed "Obsidian removal"
const [p,...envKeys]=process.argv.slice(2);
const s=packLoad(p);
if(s.env){envKeys.forEach(k=>delete s.env[k]);}
const obsidianMarkers=['obsidian-stop-hook','obsidian-prompt-hook','obsidian-agent-hook','obsidian-context-hook','obsidian-memory-hook'];
const isObsidian=e=>e&&Array.isArray(e.hooks)&&e.hooks.some(h=>obsidianMarkers.some(m=>h.command&&h.command.includes(m)));
['Stop','SessionEnd','UserPromptSubmit','SubagentStop','SessionStart','PostToolUse'].forEach(k=>{
  if(s.hooks&&s.hooks[k]){
    if(!Array.isArray(s.hooks[k]))throw new Error('"hooks.'+k+'" is not a list');
    s.hooks[k]=s.hooks[k].filter(e=>!isObsidian(e));if(!s.hooks[k].length)delete s.hooks[k];
  }
});
if(s.permissions&&s.permissions.allow){
  s.permissions.allow=s.permissions.allow.filter(p=>!p.includes('session-decisions'));
  if(!s.permissions.allow.length)delete s.permissions.allow;
}
packWrite(p,s);
JSEOF
            else
                pack_settings_remove_obsidian "$SETTINGS_PATH" env   || settings_write_failed "Obsidian env removal"
                pack_settings_remove_obsidian "$SETTINGS_PATH" hooks || settings_write_failed "Obsidian hook removal"
            fi
            echo "  [rm] Obsidian integration removed from ~/.claude/settings.json"
        else
            # Confirm or update the vault path (Enter keeps the current value)
            prompt new_vault "  Vault path [$current_vault]: "
            vault_path="${new_vault:-$current_vault}"
            _pf_default="${current_projects_folder:-Claude/Projects}"
            prompt new_pf "  Projects folder in vault [$_pf_default]: "
            projects_folder="${new_pf:-$_pf_default}"
            if [ -n "$current_api_key" ]; then
                prompt_secret new_key "  REST API key [Enter to keep existing]: "
            else
                prompt_secret new_key "  REST API key (optional, leave blank for filesystem writes): "
            fi
            rest_api_key="${new_key:-$current_api_key}"
            obsidian_setup=true
        fi
    else
        prompt obsidian_response "Set up Obsidian vault integration? [y/N] "
        if [ "$obsidian_response" = "y" ] || [ "$obsidian_response" = "Y" ]; then
            prompt vault_path "  Obsidian vault path (absolute path to your vault directory): "
            prompt projects_folder "  Projects folder in vault [Claude/Projects]: "
            projects_folder="${projects_folder:-Claude/Projects}"
            prompt_secret rest_api_key "  REST API key (optional, leave blank for filesystem writes): "
            obsidian_setup=true
        fi
    fi

    if [ "$obsidian_setup" = "true" ] && [ -n "$vault_path" ]; then
        # Write OBSIDIAN_VAULT_PATH (resolved to an absolute real path first)
        if [ "$json_tool" = "node" ]; then
            pack_node - "$SETTINGS_PATH" "$vault_path" <<'JSEOF' || settings_write_failed "OBSIDIAN_VAULT_PATH"
const os=require('os'),path=require('path');
const [p,raw]=process.argv.slice(2);
const vp=path.resolve(raw.replace(/^~/,os.homedir()));
const s=packLoad(p);
if(!s.env)s.env={};s.env.OBSIDIAN_VAULT_PATH=vp;
packWrite(p,s);
JSEOF
        else
            pack_py - "$SETTINGS_PATH" "$vault_path" <<'PYEOF' || settings_write_failed "OBSIDIAN_VAULT_PATH"
import os, sys
p, vault_path = sys.argv[1], sys.argv[2]
vault_path = os.path.realpath(os.path.expanduser(vault_path))
s = pack_load(p)
s.setdefault("env", {})["OBSIDIAN_VAULT_PATH"] = vault_path
pack_write(p, s)
PYEOF
        fi
        echo "  [ok] env:    OBSIDIAN_VAULT_PATH=$(pack_sanitize "$vault_path")"

        # Set CLI mode based on REST API key presence
        # Key present = rest-api mode (port 27124, HTTPS); absent = filesystem
        if [ -n "${rest_api_key:-}" ]; then
            cli_mode="rest-api"
            rest_port="27124"
            rest_https="true"
        else
            cli_mode="filesystem"
            rest_port=""
            rest_https=""
        fi

        # Write CLI mode env vars and REST API key
        if [ "$json_tool" = "node" ]; then
            pack_node - "$SETTINGS_PATH" "$cli_mode" "$rest_port" "$rest_https" "${rest_api_key:-}" <<'JSEOF' || settings_write_failed "OBSIDIAN_CLI_MODE"
const [p, mode, port, https_, key] = process.argv.slice(2);
const s=packLoad(p);
if(!s.env)s.env={};
s.env.OBSIDIAN_CLI_MODE=mode;
if(mode==='rest-api'){
  s.env.OBSIDIAN_REST_API_PORT=port;
  s.env.OBSIDIAN_REST_API_HTTPS=https_;
  if(key)s.env.OBSIDIAN_REST_API_KEY=key; else delete s.env.OBSIDIAN_REST_API_KEY;
}else{
  delete s.env.OBSIDIAN_REST_API_PORT;
  delete s.env.OBSIDIAN_REST_API_HTTPS;
  delete s.env.OBSIDIAN_REST_API_KEY;
}
packWrite(p,s);
JSEOF
        else
            pack_py - "$SETTINGS_PATH" "$cli_mode" "$rest_port" "$rest_https" "${rest_api_key:-}" <<'PYEOF' || settings_write_failed "OBSIDIAN_CLI_MODE"
import sys
p, mode, port, https_, key = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5]
s = pack_load(p)
s.setdefault("env", {})["OBSIDIAN_CLI_MODE"] = mode
if mode == "rest-api":
    s["env"]["OBSIDIAN_REST_API_PORT"] = port
    s["env"]["OBSIDIAN_REST_API_HTTPS"] = https_
    if key:
        s["env"]["OBSIDIAN_REST_API_KEY"] = key
    else:
        s["env"].pop("OBSIDIAN_REST_API_KEY", None)
else:
    for k in ["OBSIDIAN_REST_API_PORT", "OBSIDIAN_REST_API_HTTPS", "OBSIDIAN_REST_API_KEY"]:
        s.get("env", {}).pop(k, None)
pack_write(p, s)
PYEOF
        fi
        if [ "$cli_mode" = "rest-api" ]; then
            echo "  [ok] env:    OBSIDIAN_CLI_MODE=rest-api (port ${rest_port}, HTTPS=${rest_https}, API key set)"
        else
            echo "  [ok] env:    OBSIDIAN_CLI_MODE=filesystem (no REST API key)"
        fi

        # Write OBSIDIAN_PROJECTS_FOLDER. A blank answer writes the default, so the
        # env var is always explicit.
        _pf_note=""
        if [ -z "$projects_folder" ]; then
            projects_folder="Claude/Projects"
            _pf_note=" (default)"
        fi
        pack_settings_set_env "$SETTINGS_PATH" OBSIDIAN_PROJECTS_FOLDER "$projects_folder" \
            || settings_write_failed "OBSIDIAN_PROJECTS_FOLDER"
        echo "  [ok] env:    OBSIDIAN_PROJECTS_FOLDER=$(pack_sanitize "$projects_folder")$_pf_note"

        # Install hook scripts (stop, prompt journal, agent tracker, context loader, memory mirror)
        mkdir -p "$HOME/.claude/scripts"
        cp "$SCRIPT_DIR/scripts/obsidian-stop-hook.js"    "$HOME/.claude/scripts/"
        cp "$SCRIPT_DIR/scripts/obsidian-prompt-hook.js"  "$HOME/.claude/scripts/"
        cp "$SCRIPT_DIR/scripts/obsidian-agent-hook.js"   "$HOME/.claude/scripts/"
        cp "$SCRIPT_DIR/scripts/obsidian-context-hook.js" "$HOME/.claude/scripts/"
        cp "$SCRIPT_DIR/scripts/obsidian-memory-hook.js"  "$HOME/.claude/scripts/"
        echo "  [ok] hook:   obsidian hook scripts installed (stop, prompt, agent, context, memory)"

        # Build hook commands. Pure Node.js — works identically on Windows and macOS/Linux.
        # Use `type -P` to find the actual node binary; `command -v` may return an alias.
        node_posix="$(type -P node 2>/dev/null || true)"
        if [ -z "$node_posix" ]; then
            _cv="$(command -v node 2>/dev/null || true)"
            case "$_cv" in /*) node_posix="$_cv" ;; esac
        fi

        if [ -n "$node_posix" ]; then
            if command -v cygpath &>/dev/null; then
                node_cmd="$(cygpath -w "$node_posix")"
                stop_js="$(cygpath -w "$HOME/.claude/scripts/obsidian-stop-hook.js")"
                prompt_js="$(cygpath -w "$HOME/.claude/scripts/obsidian-prompt-hook.js")"
                agent_js="$(cygpath -w "$HOME/.claude/scripts/obsidian-agent-hook.js")"
                context_js="$(cygpath -w "$HOME/.claude/scripts/obsidian-context-hook.js")"
                memory_js="$(cygpath -w "$HOME/.claude/scripts/obsidian-memory-hook.js")"
            else
                node_cmd="$node_posix"
                stop_js="$HOME/.claude/scripts/obsidian-stop-hook.js"
                prompt_js="$HOME/.claude/scripts/obsidian-prompt-hook.js"
                agent_js="$HOME/.claude/scripts/obsidian-agent-hook.js"
                context_js="$HOME/.claude/scripts/obsidian-context-hook.js"
                memory_js="$HOME/.claude/scripts/obsidian-memory-hook.js"
            fi
            stop_cmd="\"${node_cmd}\" \"${stop_js}\""
            session_end_cmd="\"${node_cmd}\" \"${stop_js}\" \"SessionEnd\""
            prompt_cmd="\"${node_cmd}\" \"${prompt_js}\""
            agent_cmd="\"${node_cmd}\" \"${agent_js}\""
            context_cmd="\"${node_cmd}\" \"${context_js}\""
            memory_cmd="\"${node_cmd}\" \"${memory_js}\""
        else
            echo "  WARNING: node not found — Obsidian hooks not registered."
            echo "           Install Node.js and re-run install.sh to enable auto-logging."
            stop_cmd=""
        fi

        # Register all six hooks, replacing any existing obsidian entries.
        # Stop/SessionEnd: auto-log on every response and at session end.
        # UserPromptSubmit: journal user prompts for "What was discussed" section.
        # SubagentStop: track which agents completed for "Agents invoked" section.
        # SessionStart: load the project's _current.md back into context.
        # PostToolUse (Write|Edit): mirror auto-memory writes to the vault.
        if [ -n "$stop_cmd" ]; then
        if [ "$json_tool" = "node" ]; then
            pack_node - "$SETTINGS_PATH" "$stop_cmd" "$session_end_cmd" "$prompt_cmd" "$agent_cmd" "$context_cmd" "$memory_cmd" <<'JSEOF' || settings_write_failed "hook registration"
const [p, stopCmd, sessionEndCmd, promptCmd, agentCmd, contextCmd, memoryCmd]=process.argv.slice(2);
const s=packLoad(p);
if(!s.hooks)s.hooks={};
// matcher is optional: event hooks take none, tool hooks (PostToolUse) require one
// so the command does not run after every single tool call.
const setHook=(k,cmd,marker,matcher)=>{
  s.hooks[k]=(s.hooks[k]||[]).filter(e=>!(e&&Array.isArray(e.hooks)&&e.hooks.some(h=>h.command&&h.command.includes(marker))));
  s.hooks[k].push(matcher?{matcher,hooks:[{type:'command',command:cmd}]}:{hooks:[{type:'command',command:cmd}]});
};
setHook('Stop',       stopCmd,       'obsidian-stop-hook');
setHook('SessionEnd', sessionEndCmd, 'obsidian-stop-hook');
setHook('UserPromptSubmit', promptCmd, 'obsidian-prompt-hook');
setHook('SubagentStop',     agentCmd,  'obsidian-agent-hook');
setHook('SessionStart',     contextCmd, 'obsidian-context-hook');
setHook('PostToolUse',      memoryCmd, 'obsidian-memory-hook', 'Write|Edit');
// Drop any hook key left holding an empty array (cruft from earlier versions).
Object.keys(s.hooks).forEach(k=>{if(Array.isArray(s.hooks[k])&&!s.hooks[k].length)delete s.hooks[k];});
if(!s.permissions)s.permissions={};
if(!s.permissions.allow)s.permissions.allow=[];
const decPerm='Bash(echo *session-decisions*)';
if(!s.permissions.allow.includes(decPerm))s.permissions.allow.push(decPerm);
packWrite(p,s);
JSEOF
        else
            pack_py - "$SETTINGS_PATH" "$stop_cmd" "$session_end_cmd" "$prompt_cmd" "$agent_cmd" "$context_cmd" "$memory_cmd" <<'PYEOF' || settings_write_failed "hook registration"
import sys
p = sys.argv[1]
s = pack_load(p)
hooks = s.setdefault("hooks", {})
stop_cmd, session_end_cmd, prompt_cmd, agent_cmd, context_cmd, memory_cmd = sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5], sys.argv[6], sys.argv[7]
# matcher is optional: event hooks take none, tool hooks (PostToolUse) require one
# so the command does not run after every single tool call.
def set_hook(key, cmd, marker, matcher=None):
    entries = [e for e in hooks.get(key, []) if not any(marker in h.get('command', '') for h in e.get('hooks', []))]
    entry = {"hooks": [{"type": "command", "command": cmd}]}
    if matcher:
        entry = {"matcher": matcher, "hooks": entry["hooks"]}
    entries.append(entry)
    hooks[key] = entries
set_hook("Stop",            stop_cmd,        "obsidian-stop-hook")
set_hook("SessionEnd",      session_end_cmd, "obsidian-stop-hook")
set_hook("UserPromptSubmit", prompt_cmd,     "obsidian-prompt-hook")
set_hook("SubagentStop",    agent_cmd,       "obsidian-agent-hook")
set_hook("SessionStart",    context_cmd,     "obsidian-context-hook")
set_hook("PostToolUse",     memory_cmd,      "obsidian-memory-hook", "Write|Edit")
# Drop any hook key left holding an empty list (cruft from earlier versions).
for k in [k for k, v in hooks.items() if isinstance(v, list) and not v]:
    del hooks[k]
perms = s.setdefault("permissions", {})
allow = perms.setdefault("allow", [])
dec_perm = "Bash(echo *session-decisions*)"
if dec_perm not in allow:
    allow.append(dec_perm)
pack_write(p, s)
PYEOF
        fi
        echo "  [ok] hook:   Stop, SessionEnd, UserPromptSubmit, SubagentStop, SessionStart, PostToolUse hooks registered"
        fi
    elif [ "$obsidian_setup" = "true" ] && [ -z "$vault_path" ]; then
        echo "  [skip] No vault path provided — skipping Obsidian setup."
    fi

    # Optional: Codex CLI model configuration
    echo ""
    if command -v codex &>/dev/null; then
        current_codex_model="$(pack_settings_get_env "$SETTINGS_PATH" CODEX_CLI_MODEL)"

        if [ -n "$current_codex_model" ]; then
            echo "Codex CLI detected (model: $(pack_sanitize "$current_codex_model"))"
            prompt new_codex_model "  Update model? [Enter to keep, new model name, or 'none' for CLI default]: "
        else
            echo "Codex CLI detected."
            prompt new_codex_model "  Model for codex-reviewer [e.g. o3, o4-mini — Enter for CLI default]: "
        fi

        if [ "$new_codex_model" = "none" ]; then
            if [ "$json_tool" = "node" ]; then
                pack_node - "$SETTINGS_PATH" <<'JSEOF' || settings_write_failed "CODEX_CLI_MODEL"
const p=process.argv[2];
const s=packLoad(p);
if(s.env)delete s.env.CODEX_CLI_MODEL;
packWrite(p,s);
JSEOF
            else
                pack_py - "$SETTINGS_PATH" <<'PYEOF' || settings_write_failed "CODEX_CLI_MODEL"
import sys
p = sys.argv[1]
s = pack_load(p)
s.get("env", {}).pop("CODEX_CLI_MODEL", None)
pack_write(p, s)
PYEOF
            fi
            echo "  [ok] env:    CODEX_CLI_MODEL cleared (codex-reviewer will use CLI default)"
        elif [ -n "$new_codex_model" ]; then
            pack_settings_set_env "$SETTINGS_PATH" CODEX_CLI_MODEL "$new_codex_model" \
                || settings_write_failed "CODEX_CLI_MODEL"
            echo "  [ok] env:    CODEX_CLI_MODEL=$(pack_sanitize "$new_codex_model")"
        elif [ -n "$current_codex_model" ]; then
            echo "  [ok] env:    CODEX_CLI_MODEL=$(pack_sanitize "$current_codex_model") (unchanged)"
        else
            echo "  [skip] No model set — codex-reviewer will use CLI default"
        fi
    else
        echo "  [skip] Codex CLI not found — codex-reviewer installed but inactive until \`codex\` is in PATH."
    fi
fi

echo ""
echo "Next steps:"
echo ""
echo "  1. Scaffold a project (copies CLAUDE.md, docs, and memory/ structure):"
echo "     $SCRIPT_DIR/scripts/setup-project.sh <your-project-path>"
echo ""
echo "  2. Verify everything is ready:"
echo "     $SCRIPT_DIR/scripts/check-readiness.sh <your-project-path>"
echo ""
echo "  3. In Claude Code, try: /plan add a payment processing feature"
echo ""
echo "To verify: open Claude Code and run /agents -- your new agents should appear in the list."
