# shellcheck shell=bash
# shellcheck disable=SC2034  # PACK_* / AGENT_PACK_* globals are set here for the sourcing script
#
# scripts/lib/pack-common.sh -- sourced, never executed.
#
# Shared by install.sh, uninstall.sh, scripts/check-updates.sh,
# scripts/check-readiness.sh and scripts/set-env.sh, so they cannot drift apart
# on any of:
#
#   1. Layout constants and the retired-name lists.
#   2. render_pack_file -- the ONE function that turns a pack source file into its
#      installed form. install.sh writes its output; check-updates.sh compares its
#      output against what is installed, so a rendered file never reports false drift.
#   3. Scope resolution (pack_init_scope) -- which .claude directory a run targets,
#      the project-dir validation, and whether the OTHER scope holds a pack install.
#   4. Path guards -- the checks that must pass before anything is removed or moved.
#   5. settings.json -- the ONE secure writer (pack_write in python, packWrite in
#      node, defined in the preludes that pack_py / pack_node feed in front of
#      every script), plus the readers and editors built on it.
#
# Nothing here calls `exit`. Every function returns non-zero and prints to stderr;
# the calling script decides whether that is fatal.
#
# Every python invocation uses -I (isolated mode). Without it, `python -` and
# `python -c` put the current directory on sys.path, and a project-scope run
# executes inside the target repository -- a json.py there would be imported.
# -I also ignores PYTHONUTF8, so every call adds -X utf8 and every open() of
# settings.json names encoding="utf-8": on a cp1252 Windows locale the default
# would otherwise mangle a non-ASCII value.

# --- Layout -----------------------------------------------------------------------

# The only token rendered. Matched literally and exactly: other {{...}} text in a
# pack file (agents/codex-reviewer.md carries {{plan_or_decision_text}}) is data.
AGENT_PACK_TOKEN='{{AGENT_PACK_REFS}}'

AGENT_PACK_NS_NAME='agent-pack'          # <scope>/agent-pack/ -- owned wholesale by the pack
AGENT_PACK_REFS_NAME='references'        # <scope>/agent-pack/references/
AGENT_PACK_STAGING_PREFIX='.staging.'    # <scope>/agent-pack/.staging.XXXXXX/ (install.sh)
AGENT_PACK_WRITE_PREFIX='.write.'        # temp files for atomic writes into agent-pack/
AGENT_PACK_REMOVED_PREFIX='removed-'     # backups of local files a skill swap removed
AGENT_PACK_ASIDE_NAME='aside'            # <staging>/aside/ -- previous copies set aside by a swap
AGENT_PACK_GITIGNORE='.gitignore'
AGENT_PACK_MARKER='.installed'

# The Obsidian env keys the pack manages -- the single list every reader, writer,
# detector and printed message uses.
PACK_OBSIDIAN_ENV_KEYS=(
    OBSIDIAN_VAULT_PATH OBSIDIAN_CLI_MODE OBSIDIAN_REST_API_PORT
    OBSIDIAN_REST_API_HTTPS OBSIDIAN_PROJECTS_FOLDER OBSIDIAN_REST_API_KEY
)

# What the token renders to, per scope: literal strings written into installed
# files, NOT paths resolved here. The user-scope value keeps its `~`; the
# project-scope value is relative to the project root (pointer sentences carry
# their own "if relative, prefix with the project root" clause).
AGENT_PACK_REFS_PROJECT=".claude/$AGENT_PACK_NS_NAME/$AGENT_PACK_REFS_NAME"
# shellcheck disable=SC2088  # the tilde is meant to be literal
AGENT_PACK_REFS_USER="~/$AGENT_PACK_REFS_PROJECT"
# Every wiped references directory must end in exactly this.
AGENT_PACK_REFS_SUFFIX="/$AGENT_PACK_REFS_PROJECT"

# What agent-pack/.gitignore holds: transient and recovery entries are never
# committed; references/ and the .installed marker are.
AGENT_PACK_GITIGNORE_CONTENT="${AGENT_PACK_STAGING_PREFIX}*
${AGENT_PACK_WRITE_PREFIX}*
${AGENT_PACK_REMOVED_PREFIX}*"

# Agents and skills this pack has retired. An installed copy stays routable until
# its file is deleted -- the router reads the .claude directory, not this repo --
# so every removal from agents/ or skills/ must be added here in the same commit.
# install.sh removes these (user scope) or reports them (project scope);
# check-updates.sh reports them as orphans. This was missed twice: the wiki family
# (removed 2026-05-16, d11bfb1) and skill-writer (removed 2026-05-25, 3eebfda)
# stayed live for over two months.
PACK_RETIRED_AGENTS=(
    "branch-manager"                                             # -> git-engineer
    "typescript-engineer"                                        # -> frontend-engineer
    "wiki-ingestor" "wiki-librarian" "wiki-linter"               # removed d11bfb1
)
PACK_RETIRED_SKILLS=(
    "agent-plan" "challenge" "check-readiness" "check-updates" "obsidian-log"
    "skill-writer"                                               # removed 3eebfda
    "wiki" "wiki-ingest" "wiki-init" "wiki-lint" "wiki-query"    # removed d11bfb1
)

# --- Output hygiene ----------------------------------------------------------------

# pack_sanitize <string> -- the string with every control character (0x00-0x1F,
# 0x7F) removed. Use on any file name or settings value before echoing it.
pack_sanitize() {
    local LC_ALL=C s="$1"
    printf '%s' "${s//[[:cntrl:]]/}"
}

# pack_shquote <string> -- single-quoted for safe copy-paste into a POSIX shell.
pack_shquote() {
    local s="$1" q="'\\''"
    printf "'%s'" "${s//\'/"$q"}"
}

# --- Rendering ---------------------------------------------------------------------

# pack_file_has_token <src>
#   0 = <src> is a *.md file containing $AGENT_PACK_TOKEN (it will be rendered)
#   1 = no token, or not a *.md file (it will be copied byte-for-byte)
#   2 = grep itself failed
# A token in a non-.md file is deliberately reported as 1: it is not rendered, so
# it survives into the staged tree, where install.sh's zero-token assert fails.
# Reads the file directly (no pipe: no SIGPIPE/pipefail 141) and never pairs -i
# with -F (that aborts grep on this machine; see memory/context).
pack_file_has_token() {
    local rc=0
    case "$1" in *.md) ;; *) return 1 ;; esac
    grep -qF -- "$AGENT_PACK_TOKEN" "$1" || rc=$?
    case "$rc" in
        0|1) return "$rc" ;;
        *)   echo "pack_file_has_token: grep failed (exit $rc) on $1" >&2; return 2 ;;
    esac
}

# render_pack_file <src> <dst> <replacement>
# Writes the installed form of <src> to <dst> (parent dirs created). 0 on
# success, 2 on any error. Files without the token are copied with cp --
# byte-identical by construction, never re-emitted through a shell variable.
render_pack_file() {
    local src="$1" dst="$2" rep="$3" rc=0
    if [ ! -f "$src" ]; then
        echo "render_pack_file: no such file: $src" >&2
        return 2
    fi
    mkdir -p -- "$(dirname -- "$dst")" || return 2
    pack_file_has_token "$src" || rc=$?
    case "$rc" in
        0) _render_substitute "$src" "$dst" "$rep" ;;
        1) cp -- "$src" "$dst" || return 2 ;;
        *) return 2 ;;
    esac
}

# _render_substitute <src> <dst> <replacement>
# Reads the whole file with `read -d ''` (keeps CR bytes and a missing or present
# trailing newline), checks the byte count against `wc -c` (a NUL byte or CR
# stripping is an error, not a silently truncated file), and replaces every exact
# token. The replacement is never passed through sed and is quoted inside
# ${var//pat/rep}: under bash 5.2+ patsub_replacement an unquoted `&` would
# expand to the matched text. LC_ALL=C gives byte semantics whatever the caller's
# locale; the token is ASCII, so multibyte text around it is opaque bytes.
_render_substitute() {
    local src="$1" dst="$2" rep="$3" content="" out want_bytes
    local LC_ALL=C
    IFS= read -r -d '' content < "$src" || true
    want_bytes=$(wc -c < "$src") || return 2
    if [ "${#content}" -ne "$want_bytes" ]; then
        echo "render_pack_file: read ${#content} of $want_bytes bytes from $src (NUL byte or CR stripping?) -- refusing to render" >&2
        return 2
    fi
    out="${content//"$AGENT_PACK_TOKEN"/"$rep"}"
    printf '%s' "$out" > "$dst" || return 2
}

# count_fixed <needle> <file-or-dir> -- literal occurrences under the path.
# Returns 2 if grep itself fails, so "0" can never mean "grep died".
count_fixed() {
    local needle="$1" path="$2" tmp rc=0 n
    tmp="$(mktemp)" || return 2
    grep -roF -- "$needle" "$path" > "$tmp" 2>/dev/null || rc=$?
    if [ "$rc" -ge 2 ]; then
        rm -f -- "$tmp"
        echo "count_fixed: grep failed (exit $rc) under $path" >&2
        return 2
    fi
    n=$(wc -l < "$tmp")
    rm -f -- "$tmp"
    printf '%d\n' "$n"
}

# count_files <dir> -- regular files under <dir>, recursively; 0 if absent.
# Portable: no GNU/BSD-specific find primaries.
count_files() {
    [ -d "$1" ] || { echo 0; return 0; }
    find "$1" -type f | wc -l | tr -d ' '
}

# --- JSON tool ----------------------------------------------------------------------

# pack_find_json_tool -- sets PACK_JSON_TOOL to python3, python or node (first
# that runs), or "" when none does. Each candidate is liveness-tested: Windows
# ships a python3 Store stub that is on PATH but fails when run. Python is probed
# with -I, the mode every python call here uses.
pack_find_json_tool() {
    local cand
    PACK_JSON_TOOL=""
    for cand in python3 python node; do
        command -v "$cand" >/dev/null 2>&1 || continue
        case "$cand" in
            python*) "$cand" -I -X utf8 -c 'import sys; sys.exit(0)' >/dev/null 2>&1 || continue ;;
            node)    "$cand" -e 'process.exit(0)' >/dev/null 2>&1 || continue ;;
        esac
        PACK_JSON_TOOL="$cand"
        return 0
    done
    return 1
}

# --- Scope ----------------------------------------------------------------------------

# _pack_realdir <dir> -- physical absolute path, or fail. CDPATH cleared so a
# relative name can never resolve somewhere unexpected.
_pack_realdir() {
    [ -n "$1" ] && [ -d "$1" ] || return 1
    ( CDPATH='' cd -- "$1" 2>/dev/null && pwd -P )
}

# _pack_same <a> <b> -- same directory on disk? `-ef` (device + inode), so a
# differently-cased spelling, C:/ vs /c/, or a trailing slash cannot slip past.
_pack_same() {
    [ -e "$1" ] && [ -e "$2" ] && [ "$1" -ef "$2" ]
}

# pack_resolve_project_root <was-given:0|1> <dir> <pack-dir>
# Sets PACK_PROJECT_ROOT to the validated physical project directory. When
# <was-given> is 0 the current directory's git toplevel is used. Refuses: an
# empty value, a non-directory, `/` (and a bare drive root on Windows), $HOME,
# the pack repository itself, and anything not inside a git work tree.
pack_resolve_project_root() {
    local given_flag="$1" dir="$2" pack_dir="$3" real inside top shown
    PACK_PROJECT_ROOT=""
    if [ "$given_flag" = "0" ]; then
        top="$(git rev-parse --show-toplevel 2>/dev/null)" || top=""
        if [ -z "$top" ]; then
            echo "ERROR: --scope project without --project-dir requires the current directory to be inside a git work tree." >&2
            return 1
        fi
        dir="$top"
    fi
    shown="$(pack_sanitize "$dir")"
    if [ -z "$dir" ]; then
        echo "ERROR: --project-dir is empty -- refusing." >&2
        return 1
    fi
    if ! real="$(_pack_realdir "$dir")" || [ -z "$real" ]; then
        echo "ERROR: --project-dir '$shown' is not an existing directory -- refusing." >&2
        return 1
    fi
    shown="$(pack_sanitize "$real")"
    if [ "$real" = "/" ] || _pack_same "$real" /; then
        echo "ERROR: --project-dir resolves to / -- refusing." >&2
        return 1
    fi
    if command -v cygpath >/dev/null 2>&1; then
        case "$real" in
            /[A-Za-z]|/[A-Za-z]/) echo "ERROR: --project-dir resolves to a drive root ($shown) -- refusing." >&2; return 1 ;;
        esac
    fi
    if _pack_same "$real" "$HOME"; then
        echo "ERROR: --project-dir resolves to \$HOME ($shown) -- that is user scope; use --scope user." >&2
        return 1
    fi
    if _pack_same "$real" "$pack_dir"; then
        echo "ERROR: --project-dir is the agent pack repository itself ($shown) -- refusing." >&2
        return 1
    fi
    inside="$(git -C "$real" rev-parse --is-inside-work-tree 2>/dev/null)" || inside=""
    if [ "$inside" != "true" ]; then
        echo "ERROR: --project-dir '$shown' is not inside a git work tree -- refusing." >&2
        return 1
    fi
    PACK_PROJECT_ROOT="$real"
}

# pack_init_scope <scope> <project-dir-given:0|1> <project-dir> <pack-dir>
#
# The single entry point all four scripts use. --project-dir means:
#   --scope project : the project to install into / check / uninstall from.
#   --scope user    : a project to inspect for a second-scope install. It is
#                     validated exactly the same way, and only ever read.
# Sets:
#   PACK_SCOPE              user | project
#   PACK_OTHER_SCOPE        the other one
#   PACK_PROJECT_ROOT       validated project dir, or "" (user scope, none given)
#   PACK_SCOPE_ROOT         $HOME/.claude | <project>/.claude
#   PACK_AGENTS_DIR         <scope-root>/agents
#   PACK_SKILLS_DIR         <scope-root>/skills
#   PACK_NS_DIR             <scope-root>/agent-pack
#   PACK_REFS_INSTALL_DIR   <scope-root>/agent-pack/references
#   PACK_REFS_REPLACEMENT   what the token renders to in this scope
pack_init_scope() {
    local scope="$1" given="$2" dir="$3" pack_dir="$4"
    case "$scope" in
        user|project) ;;
        *) echo "ERROR: --scope must be 'user' or 'project' (got '$(pack_sanitize "$scope")')" >&2; return 1 ;;
    esac
    PACK_SCOPE="$scope"
    PACK_PROJECT_ROOT=""
    if [ "$scope" = "project" ] || [ "$given" = "1" ]; then
        pack_resolve_project_root "$given" "$dir" "$pack_dir" || return 1
    fi
    if [ "$scope" = "user" ]; then
        PACK_OTHER_SCOPE="project"
        PACK_SCOPE_ROOT="$HOME/.claude"
        PACK_REFS_REPLACEMENT="$AGENT_PACK_REFS_USER"
    else
        PACK_OTHER_SCOPE="user"
        PACK_SCOPE_ROOT="$PACK_PROJECT_ROOT/.claude"
        PACK_REFS_REPLACEMENT="$AGENT_PACK_REFS_PROJECT"
    fi
    PACK_AGENTS_DIR="$PACK_SCOPE_ROOT/agents"
    PACK_SKILLS_DIR="$PACK_SCOPE_ROOT/skills"
    PACK_NS_DIR="$PACK_SCOPE_ROOT/$AGENT_PACK_NS_NAME"
    PACK_REFS_INSTALL_DIR="$PACK_NS_DIR/$AGENT_PACK_REFS_NAME"
}

# pack_other_scope_root <scope> <project-root-or-empty>
# Prints the .claude directory of the OTHER scope, or nothing when there is none
# to compare against. Read-only use only.
#
# LIMITATION: from user scope the only project visible is --project-dir or the
# current directory's git toplevel. A project elsewhere on disk is not seen.
pack_other_scope_root() {
    local scope="$1" project_root="$2" top other
    if [ "$scope" = "project" ]; then
        printf '%s\n' "$HOME/.claude"
        return 0
    fi
    if [ -n "$project_root" ]; then
        other="$project_root/.claude"
    else
        top="$(git rev-parse --show-toplevel 2>/dev/null)" || top=""
        [ -n "$top" ] || return 0
        top="$(_pack_realdir "$top")" || return 0
        other="$top/.claude"
    fi
    # A git-tracked $HOME makes the "project" .claude the user .claude.
    if _pack_same "$other" "$HOME/.claude"; then
        return 0
    fi
    printf '%s\n' "$other"
}

# pack_list_shipped_in <claude-dir> <pack-dir>
# Prints "agent <name>" / "skill <name>" for every agent or skill this pack ships
# that is present under <claude-dir>, by name only. Informational; use
# pack_scope_has_pack to decide whether that scope holds a pack INSTALL.
pack_list_shipped_in() {
    local root="$1" pack_dir="$2" f d name
    [ -n "$root" ] && [ -d "$root" ] || return 0
    for f in "$pack_dir/agents/"*.md; do
        [ -f "$f" ] || continue
        name="$(basename "$f")"
        [ -f "$root/agents/$name" ] && printf 'agent %s\n' "${name%.md}"
    done
    for d in "$pack_dir/skills/"*/; do
        [ -d "$d" ] || continue
        name="$(basename "$d")"
        [ -d "$root/skills/$name" ] && printf 'skill %s\n' "$name"
    done
    return 0
}

# pack_scope_has_pack <claude-dir> <pack-dir>
# 0 when <claude-dir> holds an install of this pack: the agent-pack/.installed
# marker exists, OR (installs made before the marker) at least half the pack's
# agent names are present. One same-named foreign file is never enough.
# Sets PACK_HAS_PACK_WHY.
pack_scope_has_pack() {
    local root="$1" pack_dir="$2" f total=0 present=0
    PACK_HAS_PACK_WHY=""
    [ -n "$root" ] && [ -d "$root" ] || return 1
    if [ -f "$root/$AGENT_PACK_NS_NAME/$AGENT_PACK_MARKER" ]; then
        PACK_HAS_PACK_WHY="marker $root/$AGENT_PACK_NS_NAME/$AGENT_PACK_MARKER"
        return 0
    fi
    for f in "$pack_dir/agents/"*.md; do
        [ -f "$f" ] || continue
        total=$((total + 1))
        [ -f "$root/agents/$(basename "$f")" ] && present=$((present + 1))
    done
    if [ "$total" -gt 0 ] && [ $((present * 2)) -ge "$total" ]; then
        PACK_HAS_PACK_WHY="$present of $total pack agent names present (pre-marker install)"
        return 0
    fi
    return 1
}

# --- Path guards ----------------------------------------------------------------------

# _pack_is_link <path> -- the one place the symlink primitive is used, so tests can
# substitute it on machines where symlinks cannot be created.
_pack_is_link() {
    [ -L "$1" ]
}

# pack_check_scope_links <scope-root>
# Refuses when the scope root, its agent-pack/, agents/ or skills/ child, or one of
# the two files the installer writes in place (agent-pack/.gitignore and
# agent-pack/.installed) is a symlink: a removal, rename or write through a link
# lands outside the scope root.
pack_check_scope_links() {
    local root="$1" ns="$1/$AGENT_PACK_NS_NAME" p
    for p in "$root" "$ns" "$root/agents" "$root/skills" \
             "$ns/$AGENT_PACK_GITIGNORE" "$ns/$AGENT_PACK_MARKER"; do
        if _pack_is_link "$p"; then
            echo "REFUSED: '$(pack_sanitize "$p")' is a symlink -- refusing to remove, replace or write through it" >&2
            return 1
        fi
    done
    return 0
}

# pack_guard_inside <path> <scope-root>
# Succeeds only when both are non-empty, <path> is strictly inside <scope-root>,
# carries no `.` or `..` component, and no scope directory is a symlink.
pack_guard_inside() {
    local path="$1" root="$2"
    if [ -z "$path" ] || [ -z "$root" ]; then
        echo "REFUSED: empty path or scope root in a removal" >&2
        return 1
    fi
    case "$path" in
        "$root"/?*) ;;
        *) echo "REFUSED: '$(pack_sanitize "$path")' is not inside scope root '$(pack_sanitize "$root")'" >&2; return 1 ;;
    esac
    case "/$path/" in
        */../*|*/./*) echo "REFUSED: '$(pack_sanitize "$path")' contains a . or .. component" >&2; return 1 ;;
    esac
    pack_check_scope_links "$root" || return 1
}

# pack_safe_rm_tree <path> <scope-root>  -- rm -rf, but only inside the scope root.
pack_safe_rm_tree() {
    pack_guard_inside "$1" "$2" || return 1
    rm -rf -- "$1"
}

# pack_safe_rm_file <path> <scope-root>  -- rm -f of one file (or link), never a dir.
pack_safe_rm_file() {
    pack_guard_inside "$1" "$2" || return 1
    if [ -d "$1" ] && ! _pack_is_link "$1"; then
        echo "REFUSED: '$(pack_sanitize "$1")' is a directory, not a file" >&2
        return 1
    fi
    rm -f -- "$1"
}

# pack_guard_refs_target <path> <scope-root>
# The references directory is owned wholesale and is replaced. Beyond the
# scope-root guard, the path must end EXACTLY in $AGENT_PACK_REFS_SUFFIX and its
# real parent must be <scope-root>/agent-pack.
pack_guard_refs_target() {
    local path="$1" root="$2" parent want
    pack_guard_inside "$path" "$root" || return 1
    case "$path" in
        *"$AGENT_PACK_REFS_SUFFIX") ;;
        *) echo "REFUSED: '$(pack_sanitize "$path")' does not end in $AGENT_PACK_REFS_SUFFIX" >&2; return 1 ;;
    esac
    parent="$(_pack_realdir "$(dirname -- "$path")")" || {
        echo "REFUSED: parent of '$(pack_sanitize "$path")' does not exist" >&2; return 1; }
    want="$(_pack_realdir "$root")/$AGENT_PACK_NS_NAME"
    if [ "$parent" != "$want" ] || ! _pack_same "$parent" "$root/$AGENT_PACK_NS_NAME"; then
        echo "REFUSED: real parent of '$(pack_sanitize "$path")' is '$(pack_sanitize "$parent")', not '$(pack_sanitize "$want")'" >&2
        return 1
    fi
}

# pack_safe_wipe_refs <path> <scope-root>
pack_safe_wipe_refs() {
    pack_guard_refs_target "$1" "$2" || return 1
    rm -rf -- "$1"
}

# --- Staging dirs -----------------------------------------------------------------------

# pack_list_staging <ns-dir> -- every <ns-dir>/.staging.* directory, NUL-delimited
# (read with `read -r -d ''`), so no file name can split into extra paths.
pack_list_staging() {
    [ -d "$1" ] || return 0
    find "$1" -mindepth 1 -maxdepth 1 -type d -name "${AGENT_PACK_STAGING_PREFIX}*" -print0
}

# _pack_list_entries <dir> <outfile> -- the direct entries of <dir>, NUL-delimited,
# into <outfile> (dotfiles included; find does no globbing, so GLOBIGNORE,
# nullglob, dotglob and failglob cannot change the answer). Non-zero when find
# fails -- e.g. an unreadable directory -- and every caller then FAILS CLOSED.
_pack_list_entries() {
    find "$1" -mindepth 1 -maxdepth 1 -print0 > "$2" 2>/dev/null
}

# _pack_aside_interesting <entry-of-aside> -- the one rule for what in aside/
# counts: 0 for ANY entry (a file, a directory such as an empty set-aside skill or
# references dir, a link, a FIFO, anything) EXCEPT the agents/ and skills/
# container dirs swap_one creates, when those are real, readable and empty.
_pack_aside_interesting() {
    local e="$1" tmp
    case "${e##*/}" in agents|skills) ;; *) return 0 ;; esac
    if [ ! -d "$e" ] || _pack_is_link "$e"; then return 0; fi
    tmp="$(mktemp)" || return 0
    if _pack_list_entries "$e" "$tmp" && [ ! -s "$tmp" ]; then
        rm -f -- "$tmp"; return 1
    fi
    rm -f -- "$tmp"; return 0
}

# pack_staging_has_aside <staging-dir>
# 0 when its aside/ holds anything _pack_aside_interesting counts -- or when that
# cannot be established (aside/ is not a plain directory, cannot be listed, or a
# temp file cannot be made). Such a staging dir may hold the only copy of a
# previous install that a failed rollback could not put back, and must never be
# swept. 1 only when aside/ is absent, or provably holds nothing that counts.
pack_staging_has_aside() {
    local aside="$1/$AGENT_PACK_ASIDE_NAME" tmp e held=1
    if [ ! -e "$aside" ] && ! _pack_is_link "$aside"; then return 1; fi
    if [ ! -d "$aside" ] || _pack_is_link "$aside"; then return 0; fi
    tmp="$(mktemp)" || return 0
    if ! _pack_list_entries "$aside" "$tmp"; then rm -f -- "$tmp"; return 0; fi
    # The list file is removed only after the loop has closed it.
    while IFS= read -r -d '' e; do
        if _pack_aside_interesting "$e"; then held=0; break; fi
    done < "$tmp"
    rm -f -- "$tmp"
    return "$held"
}

# pack_show_staging <staging-dir> -- describe a staging dir for a refusal message,
# listing exactly what pack_staging_has_aside counted (not the empty containers).
pack_show_staging() {
    local aside="$1/$AGENT_PACK_ASIDE_NAME" top f n=0 tmp
    echo "  $(pack_sanitize "$1")" >&2
    tmp="$(mktemp)" || return 0
    if ! _pack_list_entries "$aside" "$tmp"; then
        echo "    ($AGENT_PACK_ASIDE_NAME/ cannot be listed -- treated as holding set-aside copies)" >&2
    fi
    while IFS= read -r -d '' top; do
        _pack_aside_interesting "$top" || continue
        while IFS= read -r -d '' f; do
            n=$((n + 1))
            [ "$n" -le 20 ] && echo "    $(pack_sanitize "${f#"$1"/}")" >&2
        done < <(find "$top" \( -type d -empty -o ! -type d \) -print0 2>/dev/null)
    done < "$tmp"
    rm -f -- "$tmp"
    [ "$n" -gt 20 ] && echo "    ... and $((n - 20)) more" >&2
    return 0
}

# pack_safe_rm_staging <path> <ns-dir> <scope-root> [own]
# The only way a staging dir is removed. Requires: the parent is exactly <ns-dir>,
# the base name is .staging.<alnum> with no other characters (so no newline or
# control character can be part of it), the usual scope-root guard, and -- unless
# "own" is passed by the run that created it, after a committed swap -- no
# set-aside copies inside.
pack_safe_rm_staging() {
    local path="$1" ns="$2" root="$3" own="${4:-}" base re
    if [ "${path%/*}" != "$ns" ]; then
        echo "REFUSED: staging path '$(pack_sanitize "$path")' is not directly inside '$(pack_sanitize "$ns")'" >&2
        return 1
    fi
    base="${path##*/}"
    re="^${AGENT_PACK_STAGING_PREFIX//./\\.}[A-Za-z0-9]+\$"
    if ! [[ "$base" =~ $re ]]; then
        echo "REFUSED: '$(pack_sanitize "$base")' is not a staging dir name (${AGENT_PACK_STAGING_PREFIX}<alnum>)" >&2
        return 1
    fi
    if [ "$own" != "own" ] && pack_staging_has_aside "$path"; then
        echo "REFUSED: staging dir holds set-aside copies from a failed rollback -- not removing it:" >&2
        pack_show_staging "$path"
        return 1
    fi
    pack_guard_inside "$path" "$root" || return 1
    rm -rf -- "$path"
}

# pack_write_ns_file <ns-dir> <name> <scope-root>  -- content on stdin.
# Writes <ns-dir>/<name> through a temp file in <ns-dir> and `mv -f`: the rename
# replaces whatever directory entry is there (including a link) instead of writing
# through it. Refuses first if the leaf or any scope dir is a link.
pack_write_ns_file() {
    local ns="$1" name="$2" root="$3" tmp
    pack_guard_inside "$ns/$name" "$root" || return 1
    tmp="$(mktemp "$ns/${AGENT_PACK_WRITE_PREFIX}XXXXXX")" || return 1
    if ! cat > "$tmp"; then rm -f -- "$tmp"; return 1; fi
    mv -f -- "$tmp" "$ns/$name" || { rm -f -- "$tmp"; return 1; }
}

# --- settings.json -------------------------------------------------------------------------
#
# Every settings.json read and write in the pack goes through pack_py / pack_node,
# which feed a prelude in front of the caller's script. The preludes hold the ONE
# secure writer (pack_write / packWrite) and its helpers:
#
#   pack_settings_path(p)  "~/..." is expanded the way the interpreter always has
#                          (python expanduser, node os.homedir()); then the REAL
#                          path is resolved, so a symlinked settings.json keeps its
#                          link and its target is the file updated.
#   pack_load(p)           {} when absent; UTF-8 always.
#   pack_write(p, s)       a fresh temp file beside the real target, created
#                          exclusively (python mkstemp / node 'wx') with mode 0600
#                          and an unpredictable name -- never a pre-planted path;
#                          the original's permission bits are copied onto it (a
#                          failure to read or apply them aborts the write; only
#                          "no original yet" is tolerated, and a new file stays
#                          0600); UTF-8; then renamed over the target. Any failure
#                          unlinks the temp, and the original is untouched.
#
# Paths passed to the functions below may be "~/.claude/settings.json" (expanded by
# the interpreter, as install.sh and set-env.sh always have) or an absolute path.

PACK_PY_PRELUDE='import json as _pj, os as _po, tempfile as _pt
def pack_settings_path(p):
    if p.startswith("~/"):
        p = _po.path.expanduser(p)
    return _po.path.realpath(p)
def pack_load(p):
    p = pack_settings_path(p)
    if not _po.path.exists(p):
        return {}
    with open(p, encoding="utf-8") as f:
        return _pj.load(f)
def pack_write(p, s):
    p = pack_settings_path(p)
    d = _po.path.dirname(p) or "."
    _po.makedirs(d, exist_ok=True)
    try:
        mode = _po.stat(p).st_mode & 0o7777
    except FileNotFoundError:
        mode = None
    fd, tmp = _pt.mkstemp(dir=d, prefix=".settings.", suffix=".tmp")
    done = False
    try:
        with _po.fdopen(fd, "w", encoding="utf-8") as f:
            _pj.dump(s, f, indent=2)
            f.write("\n")
        if mode is not None:
            _po.chmod(tmp, mode)
        _po.replace(tmp, p)
        done = True
    finally:
        if not done:
            try:
                _po.unlink(tmp)
            except OSError:
                pass
'

PACK_NODE_PRELUDE='const __pfs=require("fs"),__pp=require("path"),__pos=require("os"),__pc=require("crypto");
function packSettingsPath(p){
  if(p.startsWith("~/"))p=__pp.join(__pos.homedir(),p.slice(2));
  try{return __pfs.realpathSync(p);}catch(e){if(e.code==="ENOENT")return p;throw e;}
}
function packLoad(p){p=packSettingsPath(p);return __pfs.existsSync(p)?JSON.parse(__pfs.readFileSync(p,"utf8")):{};}
function packWrite(p,s){
  p=packSettingsPath(p);
  const d=__pp.dirname(p);__pfs.mkdirSync(d,{recursive:true});
  let mode=null;
  try{mode=__pfs.statSync(p).mode&0o7777;}catch(e){if(e.code!=="ENOENT")throw e;}
  const tmp=__pp.join(d,".settings."+process.pid+"."+__pc.randomBytes(8).toString("hex")+".tmp");
  const fd=__pfs.openSync(tmp,"wx",0o600);
  let done=false;
  try{
    try{__pfs.writeSync(fd,JSON.stringify(s,null,2)+"\n",null,"utf8");}finally{__pfs.closeSync(fd);}
    if(mode!==null)__pfs.chmodSync(tmp,mode);
    __pfs.renameSync(tmp,p);done=true;
  }finally{if(!done){try{__pfs.unlinkSync(tmp);}catch(e){}}}
}
'

# pack_py <python args...>  -- script on stdin. Runs the JSON tool (python) with -I
# (no cwd on sys.path, so a planted json.py is never imported) and -X utf8 (the
# UTF-8 default -I would otherwise drop), with PACK_PY_PRELUDE in front.
pack_py() {
    { printf '%s\n' "$PACK_PY_PRELUDE"; cat; } | "$PACK_JSON_TOOL" -I -X utf8 "$@"
}

# pack_node <node args...>  -- script on stdin, with PACK_NODE_PRELUDE in front.
pack_node() {
    { printf '%s\n' "$PACK_NODE_PRELUDE"; cat; } | node "$@"
}

# _pack_bash_settings_path <path> -- the bash-side spelling of a settings path.
_pack_bash_settings_path() {
    # shellcheck disable=SC2088  # matching a literal "~/" prefix, deliberately
    case "$1" in
        "~/"*) printf '%s' "$HOME/${1#"~/"}" ;;
        *)     printf '%s' "$1" ;;
    esac
}

# pack_read_base_ref <settings.json> -- worktree.baseRef, or nothing. Never writes.
pack_read_base_ref() {
    local file="$1"
    [ -f "$file" ] || return 0
    pack_find_json_tool || return 0
    case "$PACK_JSON_TOOL" in
        python*)
            pack_py - "$file" <<'PYEOF' 2>/dev/null || true
import sys
try:
    v = pack_load(sys.argv[1]).get("worktree", {}).get("baseRef", "")
    sys.stdout.write(v if isinstance(v, str) else "")
except Exception:
    pass
PYEOF
            ;;
        node)
            pack_node - "$file" <<'JSEOF' 2>/dev/null || true
try{const s=packLoad(process.argv[2]);const v=s.worktree&&s.worktree.baseRef;process.stdout.write(typeof v==="string"?v:"");}catch(e){}
JSEOF
            ;;
    esac
    return 0
}

# pack_settings_get_env <settings.json> <KEY> -- env.<KEY>, or nothing. Never writes.
pack_settings_get_env() {
    pack_find_json_tool || return 0
    case "$PACK_JSON_TOOL" in
        python*)
            pack_py - "$1" "$2" <<'PYEOF' 2>/dev/null || true
import sys
try:
    v = pack_load(sys.argv[1]).get("env", {}).get(sys.argv[2], "")
    sys.stdout.write(v if isinstance(v, str) else "")
except Exception:
    pass
PYEOF
            ;;
        node)
            pack_node - "$1" "$2" <<'JSEOF' 2>/dev/null || true
try{const s=packLoad(process.argv[2]);const v=s.env&&s.env[process.argv[3]];process.stdout.write(typeof v==="string"?v:"");}catch(e){}
JSEOF
            ;;
    esac
    return 0
}

# pack_settings_set_env <settings.json> KEY VALUE [KEY VALUE ...]
# Sets every pair in one write through the secure writer. 0 on success; 1 on any
# failure (the original file is untouched); 3 when no JSON tool is available.
pack_settings_set_env() {
    pack_find_json_tool || return 3
    case "$PACK_JSON_TOOL" in
        python*)
            pack_py - "$@" <<'PYEOF'
import sys
p, args = sys.argv[1], sys.argv[2:]
s = pack_load(p)
if not isinstance(s, dict) or not isinstance(s.setdefault("env", {}), dict):
    sys.exit("cannot update %s: settings or its env is not a JSON object" % p)
env = s["env"]
for k, v in zip(args[0::2], args[1::2]):
    env[k] = v
pack_write(p, s)
PYEOF
            ;;
        node)
            pack_node - "$@" <<'JSEOF'
const [p,...args]=process.argv.slice(2);
const s=packLoad(p);
if(typeof s!=="object"||s===null||Array.isArray(s))throw new Error("settings is not a JSON object");
if(!s.env)s.env={};
if(typeof s.env!=="object"||Array.isArray(s.env))throw new Error("env is not a JSON object");
for(let i=0;i+1<args.length;i+=2)s.env[args[i]]=args[i+1];
packWrite(p,s);
JSEOF
            ;;
    esac
}

# The settings editors below need python (uninstall.sh has always been
# python-only). Each returns 3 when no python is available.
_pack_need_python() {
    pack_find_json_tool || true
    case "$PACK_JSON_TOOL" in python*) return 0 ;; *) return 3 ;; esac
}

# pack_settings_parse <settings.json>
# 0 = parses as a JSON object; 1 = does not (the error is printed); 3 = no python.
pack_settings_parse() {
    _pack_need_python || return 3
    pack_py - "$1" <<'PYEOF'
import sys
try:
    s = pack_load(sys.argv[1])
except Exception as e:
    sys.stderr.write("cannot parse %s: %s\n" % (sys.argv[1], e))
    sys.exit(1)
if not isinstance(s, dict):
    sys.stderr.write("cannot parse %s: top level is not a JSON object\n" % sys.argv[1])
    sys.exit(1)
PYEOF
}

# pack_settings_backup <settings.json> -- copies it to <settings.json>.bak, once per
# process, before the first modification. Any existing .bak is removed first (so a
# pre-planted link is never written through) and the copy is made under umask 077,
# so the backup -- which holds the old settings, API key included -- is never
# wider than 0600.
pack_settings_backup() {
    local f
    f="$(_pack_bash_settings_path "$1")"
    [ "${PACK_SETTINGS_BACKED_UP:-}" = "$f" ] && return 0
    [ -f "$f" ] || return 0
    rm -f -- "$f.bak" || return 1
    ( umask 077 && cp -- "$f" "$f.bak" ) || return 1
    PACK_SETTINGS_BACKED_UP="$f"
}

# pack_settings_has_obsidian_env <settings.json> -- 0 when any key in
# PACK_OBSIDIAN_ENV_KEYS is set.
pack_settings_has_obsidian_env() {
    _pack_need_python || return 3
    [ "$(pack_py - "$1" "${PACK_OBSIDIAN_ENV_KEYS[@]}" <<'PYEOF'
import sys
try:
    env = pack_load(sys.argv[1]).get("env", {})
    if isinstance(env, dict) and any(k in env for k in sys.argv[2:]):
        print("yes")
except Exception:
    pass
PYEOF
)" = "yes" ]
}

# pack_settings_remove_obsidian <settings.json> <env|hooks> [check]
# Removes the PACK_OBSIDIAN_ENV_KEYS env keys, or the Obsidian hook entries plus
# the session-decisions permission, through the secure writer (backed up once).
#
#   check  Dry run: perform the transform in memory and write nothing. 0 = it
#          would succeed; 1 = it would fail (the reason is printed). uninstall.sh
#          runs this BEFORE deleting anything, so a wrong-shaped settings.json --
#          "hooks" or one of its keys, "env", "permissions" or "allow" not of the
#          expected type -- aborts with nothing removed.
pack_settings_remove_obsidian() {
    _pack_need_python || return 3
    if [ "${3:-}" != "check" ]; then
        pack_settings_backup "$1" || return 1
    fi
    pack_py - "$1" "$2" "${3:-write}" "${PACK_OBSIDIAN_ENV_KEYS[@]}" <<'PYEOF'
import sys
p, what, mode, env_keys = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4:]

def transform(s):
    if not isinstance(s, dict):
        raise ValueError("top level is not a JSON object")
    if what == "env":
        env = s.get("env", {})
        if not isinstance(env, dict):
            raise ValueError('"env" is %s, not an object' % type(env).__name__)
        for key in env_keys:
            env.pop(key, None)
        if not env:
            s.pop("env", None)
        return s
    hooks = s.get("hooks", {})
    if not isinstance(hooks, dict):
        raise ValueError('"hooks" is %s, not an object' % type(hooks).__name__)
    markers = ['obsidian-stop-hook', 'obsidian-prompt-hook', 'obsidian-agent-hook', 'obsidian-context-hook', 'obsidian-memory-hook']
    def is_obsidian(entry):
        return isinstance(entry, dict) and any(
            m in h.get('command', '')
            for h in entry.get('hooks', [])
            for m in markers
        )
    for key in ("Stop", "SessionEnd", "UserPromptSubmit", "SubagentStop", "SessionStart", "PostToolUse"):
        old = hooks.get(key, [])
        if not isinstance(old, list):
            raise ValueError('"hooks.%s" is %s, not a list' % (key, type(old).__name__))
        new = [h for h in old if not is_obsidian(h)]
        if new != old:
            if new:
                hooks[key] = new
            else:
                del hooks[key]
    # Drop any hook key left holding an empty list (cruft from earlier versions).
    for key in [k for k, v in hooks.items() if isinstance(v, list) and not v]:
        del hooks[key]
    if not hooks:
        s.pop("hooks", None)
    perms = s.get("permissions", {})
    if not isinstance(perms, dict):
        raise ValueError('"permissions" is %s, not an object' % type(perms).__name__)
    allow = perms.get("allow", [])
    if not isinstance(allow, list):
        raise ValueError('"permissions.allow" is %s, not a list' % type(allow).__name__)
    perms["allow"] = [a for a in allow if not (isinstance(a, str) and "session-decisions" in a)]
    return s

try:
    s = transform(pack_load(p))
except Exception as e:
    sys.stderr.write("cannot update %s (%s): %s\n" % (p, what, e))
    sys.exit(1)
if mode == "check":
    sys.exit(0)
pack_write(p, s)
PYEOF
}
