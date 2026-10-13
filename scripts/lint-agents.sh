#!/usr/bin/env bash
# shellcheck disable=SC2016  # fixtures and patterns hold literal `$`, `${` and backticks ON PURPOSE
set -euo pipefail

# Lint agents/ and skills/ frontmatter, and the on-demand pointers they carry.
#
#   bash scripts/lint-agents.sh
#
# EXIT CONTRACT -- three-way, mirroring scripts/lint-memory.sh and
# scripts/lint-identifiers.sh:
#   0  every file passes (warnings do not change this)
#   1  a finding: at least one file or pointer fails a rule
#   2  the SELF-TEST failed, so this script's verdict means nothing
#
# TWO HALVES
#   1. Per-file frontmatter/body checks on agents/*.md and skills/*/SKILL.md.
#      The checks themselves are the original ones; what changed is how file
#      content is handled. A frontmatter key is never pathname-expanded, a value
#      taken from a file is never given to `echo` (a name of `-n` is an echo
#      option, not a name), and a symlinked agent or skill is skipped rather than
#      read through.
#      R6 (skill directories): ONLY SKILL.md is linted and name must match the
#      directory. Any other file in a skill directory is not a malformed skill, and
#      a directory with no SKILL.md is skipped, not flagged.
#   2. Pack-reference rules R1-R5 and R7 over the pointers that agents, skills,
#      references/, CLAUDE.md and docs/CLAUDE.template.md use to name files under
#      the top-level references/ directory. The token `{{AGENT_PACK_REFS}}` is
#      rendered to a real path by the installer, so a pointer is written
#      `{{AGENT_PACK_REFS}}/<path>.md` and means references/<path>.md in this repo.
#
#   R1 pointer resolves   every `{{AGENT_PACK_REFS}}/<path>.md` must name an
#                         existing file references/<path>.md. A dangling pointer
#                         fails OPEN at runtime (the agent just never reads it).
#                         `..` segments, a leading `/` and a case mismatch all
#                         fail: resolution is EXACT-string against the listing of
#                         references/, never `[ -f ]`, because NTFS resolves
#                         `Name.md` to `name.md` and Linux does not.
#                         A token followed by `/` and a non-empty path run that does
#                         NOT end in .md (`/name`, `/name.mdd`, `/name.md.txt`) also
#                         fails: "pointer must name a .md file" -- a forgotten
#                         extension fails open exactly like a dangling one.
#                         Path characters are [A-Za-z0-9_./-]; the underscore matters
#                         (`plan_template.md` was once read as the run `plan`).
#                         Scope: agents/, skills/ (every .md), references/,
#                         CLAUDE.md, docs/CLAUDE.template.md.
#   R2 no bare pointer    a `references/<path>.md` NOT carried by the token fails
#                         in agents/ and skills/ only: written bare it resolves
#                         only inside this repo. A line containing
#                         `<!-- lint-ok: bare-ref -->` is skipped (R2 ONLY -- the
#                         marker does not excuse a dangling pointer on that line).
#                         `references/` with no .md filename never matches.
#   R3 port hygiene       CLAUDE_PLUGIN_ROOT anywhere in agents/, skills/ or
#                         references/, or an agent/skill NAME (frontmatter `name:`,
#                         the agent filename, the skill directory) starting
#                         `delivery-`. Names only: prose such as
#                         `ado-delivery-pipeline-brief.md` is not a name.
#   R4 token spelling     any `{{AGENT_PACK_` that is not exactly
#                         `{{AGENT_PACK_REFS}}`, including a lowercase variant,
#                         spaces inside the braces (`{{ AGENT_PACK_REFS }}`), and
#                         the shell-variable forms `$AGENT_PACK_*` / `${AGENT_PACK_*`,
#                         none of which the installer renders.
#   R5 orphans            a references/ file nothing points at is a WARNING only.
#                         A pointer from another references/ file counts; a file
#                         pointing at itself does not.
#   R7 tree integrity     a symlink anywhere under agents/, skills/ or references/
#                         (or CLAUDE.md / docs/CLAUDE.template.md being one), or a
#                         file name containing a control character (a newline in a
#                         name splits a line-based listing, so `a<LF>b.md` made a
#                         pointer to `b.md` resolve). Symlinks are never followed
#                         or read -- a link to a file outside the pack would
#                         otherwise print its matching lines into the CI log. Both
#                         kinds are reported and EXCLUDED from every scan.
#
# DELIBERATE NON-CHECKS (each would be a bug if "fixed" without a decision):
#   - A token followed by NO path run (`{{AGENT_PACK_REFS}}/<path>.md`,
#     `{{AGENT_PACK_REFS}}/*.md`, `{{AGENT_PACK_REFS}}/ ` alone) or by a run ending in
#     `/` (`{{AGENT_PACK_REFS}}/sub/`) is a placeholder or a directory mention, not a
#     pointer, and is compliant. That is what lets prose DESCRIBE the mechanism.
#   - Prose that quotes a REAL-looking pointer must name a file that exists, or
#     use a `<path>` placeholder. R1 has no escape hatch by design.
#
# WHY THE RULE LOGIC USES NO grep. Two memory files record hazards that already
# shipped as bugs here: memory/context/2026-08-04-grep-iF-aborts-on-this-machine.md
# (-i with -F aborts, exit 134, indistinguishable from "no matches") and
# memory/context/2026-08-05-pipefail-plus-short-circuiting-grep-returns-141.md
# (`producer | grep -q` returns 141 under pipefail once the match is early and the
# input is large). The pointer rules use bash's own `case`, `[[ ]]` and parameter
# expansion -- no process, no -F flag to abort, no pipe to cut -- and no bash-4-only
# feature, so they run on the bash 3.2 that macOS ships. The per-file half still
# uses small `printf | grep` calls on short name strings, far below the pipe buffer.
#
# SELF-TEST runs BEFORE any scan. It drives the SAME check_pack the real scan
# uses against fixture trees: every rule must fire on a violating fixture at the
# exact file:line AND stay silent on a compliant one, and the good tree must scan
# a known number of files (a scanner that reads nothing reports a clean repo).
# Any failure exits 2, distinct from a finding's exit 1.
#
# KNOWN LIMIT of the self-test on a machine that cannot create symlinks (Git Bash
# without developer mode copies instead): the link fixtures then run against a
# STUB of `_is_link` / `_find_flagged`. That proves the skip-and-report logic, not
# the bodies of those two one-line functions. See _selftest_r7.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_DIR="$(dirname "$SCRIPT_DIR")"

PASS=0
FAIL=0
WARN=0

# Validate pack directory
if [ ! -d "$PACK_DIR/agents" ] || [ ! -d "$PACK_DIR/skills" ]; then
    echo "Error: agents/ and skills/ directories not found in $PACK_DIR"
    echo "Run this script from the pack repository root: bash scripts/lint-agents.sh"
    exit 1
fi

# Valid frontmatter fields by file type
AGENT_VALID_FIELDS="name description tools model effort permissionMode version"
SKILL_VALID_FIELDS="name description license compatibility metadata allowed-tools"

# EVERY line printed through pass/fail has its control characters replaced by `?`.
# Messages quote values taken from the files under test (a frontmatter name, an
# unknown key), and a hostile file could otherwise carry ESC/CR/BS to overwrite the
# adjacent "[!!]" text in a terminal or a CI log.
pass() {
    local LC_ALL=C
    local a="${1//[[:cntrl:]]/?}"
    echo "  [ok] $a"
    PASS=$((PASS + 1))
}

fail() {
    local LC_ALL=C
    local a="${1//[[:cntrl:]]/?}" b="${2//[[:cntrl:]]/?}"
    echo "  [!!] $a  -- $b"
    FAIL=$((FAIL + 1))
}

# The seam for every symlink decision. `[ -f ]` and a glob both FOLLOW symlinks,
# so a link in agents/ to a file outside the pack was read and its matching lines
# printed. Everything that opens a pack file asks this first.
_is_link() {
    [ -L "$1" ]
}

# THE FRONTMATTER HELPERS FAIL CLOSED. They used to end in `|| true` / `|| echo 0`,
# so an awk that died (missing binary, a crash) read as "no unknown fields",
# "description length 0" or "body has 0 lines" and the file passed. Now an awk
# failure makes the helper return nonzero, and every caller turns that into
# `_fatal` (exit 2) -- a caller, because a helper run inside $(...) can only exit its
# own subshell. has_field is the one helper whose exit status carries an answer
# (1 = not found), so it separates "not found" (1) from "awk failed" (2+) itself.

# Extract the value of a frontmatter field from a file.
# Returns empty string if not found; returns 1 if awk itself failed.
get_field() {
    local file="$1"
    local field="$2"
    # Match lines like: field: value  OR  field: >  (multi-line)
    local val
    val=$(awk "/^---/{fm++} fm==1 && /^${field}:/{found=1; sub(/^${field}:[[:space:]]*/,\"\"); print; exit} /^---/{if(fm>=2)exit}" "$file") || return 1
    printf '%s\n' "$val"
}

# Check if a frontmatter field is present (non-empty line starting with field:).
# 0 = present, 1 = absent; an awk failure is fatal here (not a "no").
has_field() {
    local file="$1"
    local field="$2" rc=0
    awk "/^---/{fm++} fm==1 && /^${field}:/{found=1; exit} /^---/{if(fm>=2)exit} END{exit !found}" "$file" || rc=$?
    case "$rc" in
        0) return 0 ;;
        1) return 1 ;;
        *) _fatal "awk failed (exit $rc) reading frontmatter of $file (has_field)" ;;
    esac
}

# Check for unknown frontmatter fields; returns 1 if awk itself failed.
unknown_fields() {
    local file="$1"
    local valid="$2" keys key v found
    keys=$(awk '
        /^---/{fm++; next}
        fm==1 && /^[a-zA-Z]/{
            key=$0; sub(/:.*$/,"",key)
            print key
        }
        fm>=2{exit}
    ' "$file") || return 1
    while IFS= read -r key; do
        if [ -z "$key" ]; then
            continue
        fi
        found=0
        for v in $valid; do
            if [ "$key" = "$v" ]; then
                found=1
                break
            fi
        done
        if [ "$found" -eq 0 ]; then
            printf '%s\n' "$key"
        fi
    done <<< "$keys"
    return 0
}

# Count body content lines (after the closing ---); returns awk's status (nonzero
# if awk itself failed).
body_line_count() {
    local file="$1"
    # awk is the last command, so its failure IS this function's status.
    awk '/^---/{fm++; next} fm>=2{lines++} END{print lines+0}' "$file"
}

# Get description length (handles multi-line > style); returns awk's status
# (nonzero if awk itself failed).
description_length() {
    local file="$1"
    # Extract everything between description: and the next top-level key or closing ---
    awk '
        /^---/{fm++; next}
        fm==1 && /^description:/{in_desc=1; sub(/^description:[[:space:]]*/,""); if($0!=">" && $0!=""){buf=buf $0}; next}
        fm==1 && in_desc && /^[[:space:]]/{buf=buf " " $0; next}
        fm==1 && in_desc{in_desc=0}
        fm>=2{exit}
        END{print length(buf)}
    ' "$file"
}

# grep -q over a herestring, for a file-derived value. 0 = match, 1 = no match,
# and grep exiting 2 or more (missing binary, abort -- `grep -iF` aborts on this
# machine) is FATAL, never "no match": a name check that cannot run must not pass the
# name. A herestring, not a pipe, so this runs in the CURRENT shell (a pipeline
# element's `exit` would only end the pipeline stage) and cannot SIGPIPE.
# LC_ALL=C: in a UTF-8 locale an invalid byte can make grep treat the line as
# binary and report "no match". <grep args...> reads the value from stdin.
_grep_q() {
    local rc
    LC_ALL=C grep -q "$@" && return 0
    rc=$?
    if [ "$rc" -ge 2 ]; then
        _fatal "grep failed (exit $rc): grep -q $*"
    fi
    return 1
}

lint_file() {
    local file="$1"
    local type="$2"  # "agent" or "skill"
    local label
    label="$(basename "$(dirname "$file")")/$(basename "$file")"
    [ "$type" = "agent" ] && label="agents/$(basename "$file")"

    local file_pass=1

    # Check required: name
    if ! has_field "$file" "name"; then
        fail "$label" "Missing required field: \`name\`"
        file_pass=0
    else
        local name_val
        name_val=$(get_field "$file" "name") || _fatal "awk failed reading the name of $file (get_field)"
        # Max 64 characters
        if [ "${#name_val}" -gt 64 ]; then
            fail "$label" "name exceeds 64 characters (${#name_val} chars)"
            file_pass=0
        fi
        # A herestring through _grep_q, never `echo` and never a pipe: `echo -n` /
        # `echo -e` swallow a name like `-n` as an option, so the hyphen check below
        # saw an empty string and passed it; and a grep that cannot run is fatal,
        # not "no match" (see _grep_q).
        # Lowercase alphanumeric + hyphens only
        if _grep_q -E '[^a-z0-9-]' <<< "$name_val"; then
            fail "$label" "name contains invalid characters (only a-z, 0-9, and hyphens allowed): \`$name_val\`"
            file_pass=0
        fi
        # No leading or trailing hyphen
        if _grep_q -E '^-|-$' <<< "$name_val"; then
            fail "$label" "name must not start or end with a hyphen: \`$name_val\`"
            file_pass=0
        fi
        # No consecutive hyphens
        if _grep_q -F -- '--' <<< "$name_val"; then
            fail "$label" "name must not contain consecutive hyphens: \`$name_val\`"
            file_pass=0
        fi
        # For skills: name must match parent directory name
        if [ "$type" = "skill" ]; then
            local dir_name
            dir_name=$(basename "$(dirname "$file")")
            if [ "$name_val" != "$dir_name" ]; then
                fail "$label" "name \`$name_val\` does not match directory \`$dir_name\`"
                file_pass=0
            fi
        fi
    fi

    # Check required: description
    if ! has_field "$file" "description"; then
        fail "$label" "Missing required field: \`description\`"
        file_pass=0
    else
        local desc_len desc_limit
        desc_len=$(description_length "$file") || _fatal "awk failed measuring the description of $file (description_length)"
        [ "$type" = "skill" ] && desc_limit=1024 || desc_limit=1536
        if [ "$desc_len" -gt "$desc_limit" ]; then
            fail "$label" "Description exceeds ${desc_limit} characters (${desc_len} chars)"
            file_pass=0
        fi
    fi

    # Check for unknown fields
    local valid_fields
    [ "$type" = "agent" ] && valid_fields="$AGENT_VALID_FIELDS" || valid_fields="$SKILL_VALID_FIELDS"
    local unknown unk_key
    unknown=$(unknown_fields "$file" "$valid_fields") || _fatal "awk failed listing the frontmatter keys of $file (unknown_fields)"
    if [ -n "$unknown" ]; then
        # Read line by line. `for f in $unknown` word-split AND pathname-expanded
        # the keys, so a frontmatter key such as `a*` globbed against the cwd and
        # was reported as whatever files happened to match.
        while IFS= read -r unk_key; do
            fail "$label" "Unknown frontmatter field: \`$unk_key\`"
            file_pass=0
        done <<< "$unknown"
    fi

    # Check body content exists
    local body_lines
    body_lines=$(body_line_count "$file") || _fatal "awk failed counting the body of $file (body_line_count)"
    if [ "$body_lines" -lt 3 ]; then
        fail "$label" "Missing body content (found ${body_lines} lines after frontmatter)"
        file_pass=0
    fi

    # `if`, not `[ ] && pass`: as the LAST statement of a function the && form
    # returns 1 for a failing file, and under `set -e` that aborted the whole
    # script at the first failure -- no remaining files, no summary line. Exit
    # status was still 1, so it went unnoticed. Same family as lint-memory.sh's
    # check_file note.
    if [ "$file_pass" -eq 1 ]; then
        pass "$label"
    fi
    return 0
}

# Lint every skills/<name>/SKILL.md under <root>. Takes a root so the self-test
# can point it at a fixture tree.
#
# ENUMERATED WITH THE SAME `find` THE POINTER RULES USE, not a glob. A glob (a)
# skips dotfiles, so a hidden skills/.d/SKILL.md dodged the name and description
# checks while R1-R4 still scanned it; (b) matches a control-character name, whose
# newline then forged a log line through `label`; and (c) follows a symlinked
# skills/ itself. Here a linked skills/, a linked skill directory and a linked
# SKILL.md are all skipped (R7 reports them), and a control-character path never
# reaches the listing. A find/sort failure is fatal (exit 2), never "no skills".
lint_skills_dir() {
    _each_pack_file "$1" skills _lint_skill -mindepth 2 -maxdepth 2 -name SKILL.md
    _none_note skill
}

# Lint every agents/*.md under <root>; enumerated and guarded exactly as
# lint_skills_dir is (see there).
lint_agents_dir() {
    _each_pack_file "$1" agents _lint_agent -maxdepth 1
    _none_note agent
}

# Callbacks for _each_pack_file.
_lint_skill() {
    lint_file "$1" "skill"
}
_lint_agent() {
    lint_file "$1" "agent"
}

# The "(no X files found)" tail shared by both per-file loops; reads EACH_COUNT.
_none_note() {
    if [ "$EACH_COUNT" -eq 0 ]; then
        echo "  (no $1 files found)"
    fi
    return 0
}

# ===========================================================================
# PACK REFERENCE RULES R1-R5, R7 (see the header for what each one means)
# ===========================================================================

# THE one place a reported rule is declared: "<id> <title>". It prints an [ok] line
# when clean and a [!!] line per finding (R5 is a warning with its own line).
# RULES, the id list the report loop, the known-rule test and the self-test message
# use, is DERIVED from this table, and rule_title reads it too -- so a rule added
# here is picked up by all of them, and the self-test asserts none of them is left
# untitled. (A finding under an id NOT in this table is still PRINTED by the report
# layer, as "(unlisted rule)".)
RULE_TABLE=(
    "R1 pointers resolve to files under references/"
    "R2 no bare references/<path>.md in agents or skills"
    "R3 port hygiene: no CLAUDE_PLUGIN_ROOT, no delivery- names"
    "R4 pointer token spelled exactly {{AGENT_PACK_REFS}}"
    "R7 no symlinks or control-character names in the scanned trees"
)
RULES=""
for _e in "${RULE_TABLE[@]}"; do
    RULES+="${_e%% *} "
done
RULES="${RULES% }"
unset _e

TOKEN_PREFIX='{{AGENT_PACK_'
TOKEN_TAIL='REFS}}'

# Contract check: the token this linter enforces must be the token the install
# library renders. If the two drift, every pointer lints clean and then survives
# rendering unrendered at install time. Skipped when the library is absent, which
# is a stated gap and not a failure. Matches the single-quoted assignment in
# scripts/lib/pack-common.sh literally, so re-quoting that line breaks this check
# loudly (exit 2) rather than silently.
if [ -f "$SCRIPT_DIR/lib/pack-common.sh" ]; then
    _lib_token="$(sed -n "s/^AGENT_PACK_TOKEN='\(.*\)'\$/\1/p" "$SCRIPT_DIR/lib/pack-common.sh")"
    if [ "$_lib_token" != "${TOKEN_PREFIX}${TOKEN_TAIL}" ]; then
        echo "ERROR: token drift: scripts/lib/pack-common.sh AGENT_PACK_TOKEN is '${_lib_token}', linter enforces '${TOKEN_PREFIX}${TOKEN_TAIL}'" >&2
        exit 2
    fi
    unset _lib_token
fi
BARE_MARKER='<!-- lint-ok: bare-ref -->'
PATH_CLASS='[A-Za-z0-9_./-]'
DELIVERY_NAME_RE="^name:[[:space:]]*[\"']?delivery-"
SPACED_TOKEN_RE='\{\{[[:space:]]+[Aa][Gg][Ee][Nn][Tt]_[Pp][Aa][Cc][Kk]_'
NL=$'\n'

# Results of the most recent check_pack call. Globals rather than stdout so the
# scan never runs in a subshell (counters and sets survive) and the self-test can
# inspect them directly. Each FINDS entry is `RULE<TAB>file:line<TAB>detail`.
FINDS=()
WARNS=()
SCANNED=0
HAS_REFS=0
REF_NL="$NL"        # newline-delimited exact listing of references/ (relative paths)
POINTED_NL="$NL"    # newline-delimited set of references/ files something points at
RUN=""
TRIMMED=""
STRIPPED=""         # the current line minus every valid token pointer (for R2)
IN_FM=0
BARE_HITS=()
ENUM=""             # _enum's result: newline-delimited, control-character-free listing
NUL_LIST=()         # _nul_find's result

# _add_find <rule> <file:line> <what> <offending line>
_add_find() {
    # Control characters become `?` in the detail and the excerpt: both can quote a
    # hostile file (the R4 token, the offending line), and this is also what keeps a
    # TAB or newline from corrupting the TAB-separated entry.
    local LC_ALL=C
    local d="${3//[[:cntrl:]]/?}" s="${4//[[:cntrl:]]/?}"
    FINDS+=("$1"$'\t'"$2"$'\t'"$d  | ${s:0:100}")
}

# A name made printable: control characters (a newline would also break the
# TAB-separated FINDS entry) are shown as bash $'..' escapes.
_display() {
    local LC_ALL=C
    if [[ "$1" == *[[:cntrl:]]* ]]; then
        printf '%q' "$1"
    else
        printf '%s' "$1"
    fi
}

# Leading run of path characters in $1 -> RUN (possibly empty).
_path_run() {
    RUN=""
    if [[ "$1" =~ ^(${PATH_CLASS}+) ]]; then
        RUN="${BASH_REMATCH[1]}"
    fi
    return 0
}

# Strip trailing sentence punctuation (. - /) from $1 -> TRIMMED, so that
# "see {{AGENT_PACK_REFS}}/x.md." names x.md.
_trim_punct() {
    local s="$1"
    while [[ "$s" == *[./-] ]]; do
        s="${s%?}"
    done
    TRIMMED="$s"
    return 0
}

_mark_pointed() {
    case "$POINTED_NL" in
        *"$NL$1$NL"*) ;;
        *) POINTED_NL+="$1$NL" ;;
    esac
    return 0
}

# Every `references/<path>.md` in $1 that is not glued to a longer word
# ("notreferences/x.md") -> BARE_HITS. Callers pass text with every valid token
# pointer already removed, so `{{AGENT_PACK_REFS}}/sub/references/z.md` is not
# misread as a bare `references/z.md`.
_bare_hits() {
    BARE_HITS=()
    local rest="$1" pre prev=" " run
    while [[ "$rest" == *references/* ]]; do
        pre="${rest%%references/*}"
        rest="${rest#*references/}"
        if [ -n "$pre" ]; then
            prev="${pre: -1}"
        fi
        _path_run "$rest"
        run="$RUN"
        rest="${rest#"$run"}"
        if [[ ! "$prev" =~ [A-Za-z0-9_] ]]; then
            _trim_punct "$run"
            if [[ "$TRIMMED" == ?*.md ]]; then
                BARE_HITS+=("references/$TRIMMED")
            fi
        fi
        if [ -n "$run" ]; then
            prev="${run: -1}"
        else
            prev="/"
        fi
    done
    return 0
}

# ---- file enumeration ------------------------------------------------------
#
# EVERY listing is checked for failure. `done < <(find | sort)` hides a failure
# inside the process substitution: an unreadable directory, or the wrong `find`
# (Windows puts C:\Windows\System32\find.exe, a text-search tool, ahead of the MSYS
# one on some PATHs) gave a truncated or EMPTY listing, and every rule then printed
# "[ok] (N files scanned)". Both helpers below exit 2 on any find or sort failure.
# `LC_ALL=C` is scoped to the find/sort commands: `[[:cntrl:]]` and the sort order
# must not depend on the locale, and an invalid UTF-8 byte can defeat a UTF-8
# locale's pattern matching.
_fatal() {
    echo "  [!!] lint-agents: FATAL: $* -- the checker's own mechanism failed, so no result is reported (exit 2)" >&2
    exit 2
}

# Regular .md files AND symlinks named *.md under <dir>, sorted, newline
# delimited. A path with a control character is excluded AT THE find LEVEL, so no
# listed name can contain a newline and split into two list entries -- the
# false-pass R7 exists for. Callers skip links with _is_link; _find_flagged
# reports what was skipped. Extra args (e.g. -maxdepth 1) go first.
_list_md() {
    local dir="$1"
    shift
    LC_ALL=C find "$dir" "$@" \( -type f -o -type l \) -name '*.md' ! -path '*[[:cntrl:]]*' | LC_ALL=C sort
}

# ENUM <- _list_md output; exits 2 if find or sort failed (pipefail carries find's
# status through the pipe, and an assignment from $(...) carries it out).
_enum() {
    local dir="$1"
    shift
    ENUM="$(_list_md "$dir" "$@")" || _fatal "listing $dir failed"
    return 0
}

# THE ONE ITERATOR over a pack directory, used by both per-file lints and by the
# pointer scans. <root>/<sub> must be a real directory (absent or LINKED => nothing,
# and R7 reports a link); the listing is _enum's (failure fatal, control-character
# names excluded); an empty line or a link -- the file itself OR its parent
# directory -- is skipped. For each remaining file it calls <callback> <file>
# (EACH_ROOT holds <root> for callbacks) and counts it in EACH_COUNT, which callers
# read for the "(no X files found)" tail and for the per-tree floor.
# <root> <sub> <callback> [find args...]
EACH_COUNT=0
EACH_ROOT=""
_each_pack_file() {
    local root="$1" sub="$2" cb="$3" f
    shift 3
    EACH_COUNT=0
    EACH_ROOT="$root"
    if [ ! -d "$root/$sub" ] || _is_link "$root/$sub"; then
        return 0
    fi
    _enum "$root/$sub" "$@"
    while IFS= read -r f; do
        if [ -n "$f" ] && ! _is_link "${f%/*}" && ! _is_link "$f"; then
            EACH_COUNT=$((EACH_COUNT + 1))
            "$cb" "$f"
        fi
    done <<< "$ENUM"
    return 0
}

# NUL_LIST <- every path `find <args> -print0` prints, NUL-delimited so a name can
# hold anything. The subshell appends `RC=<find's status>` after find's output; no
# marker (find died and errexit ended the subshell first) or a nonzero one is fatal.
# A real path always starts with / or a drive letter, so it cannot collide with RC=.
_nul_find() {
    local f rc=""
    NUL_LIST=()
    while IFS= read -r -d '' f || [ -n "$f" ]; do
        case "$f" in
            RC=*) rc="${f#RC=}" ;;
            *) NUL_LIST+=("$f") ;;
        esac
    done < <(LC_ALL=C find "$@" -print0; printf 'RC=%s' "$?")
    if [ "$rc" != 0 ]; then
        _fatal "find failed (status '${rc:-none}'): $*"
    fi
    return 0
}

# ONE find for both R7 conditions (a process spawn is the dominant cost on Windows):
# every path under <targets> that is a symlink OR whose name holds a control
# character. Takes paths that exist; fills NUL_LIST. _check_names then classifies
# each path in bash with _is_link and a pattern match, so the self-test's stub of
# this function and of _is_link covers both.
_find_flagged() {
    _nul_find "$@" \( -type l -o -path '*[[:cntrl:]]*' \)
}

# R7 -- report every symlink and control-character name in the scanned trees.
# A linked agents/, skills/, references/ or docs/ is reported by name and is NOT
# handed to find: `find link` does not descend, so the link would be the only thing
# it ever looked at. docs/ is only tested as a parent of the one template file.
# <root>
_check_names() {
    local root="$1" t p LC_ALL=C
    local -a targets=()
    for t in agents skills references docs; do
        if _is_link "$root/$t"; then
            _add_find R7 "$t:1" "symlinked directory: never followed or read, excluded from every scan" "$t"
        elif [ "$t" != docs ] && [ -e "$root/$t" ]; then
            targets+=("$root/$t")
        fi
    done
    if [ -e "$root/CLAUDE.md" ] || [ -L "$root/CLAUDE.md" ]; then
        targets+=("$root/CLAUDE.md")
    fi
    if ! _is_link "$root/docs" && { [ -e "$root/docs/CLAUDE.template.md" ] || [ -L "$root/docs/CLAUDE.template.md" ]; }; then
        targets+=("$root/docs/CLAUDE.template.md")
    fi
    if [ "${#targets[@]}" -eq 0 ]; then
        return 0
    fi
    _find_flagged "${targets[@]}"
    for p in "${NUL_LIST[@]+"${NUL_LIST[@]}"}"; do
        t="$(_display "${p#"$root"/}")"
        if _is_link "$p"; then
            _add_find R7 "$t:1" "symlink: never followed or read, excluded from every scan" "$t"
        fi
        if [[ "$p" == *[[:cntrl:]]* ]]; then
            _add_find R7 "$t:1" "file name contains a control character (newline, tab, ...); excluded from every scan" "$t"
        fi
    done
    return 0
}

# ---- per-line checks (each takes what it needs; globals only where noted) ----

# R3, file level: the NAME of an agent is its filename; of a skill, its directory.
# <kind> <rel>
_check_r3_name() {
    local kind="$1" rel="$2" base sname
    if [ "$kind" = agent ]; then
        base="${rel##*/}"
        if [[ "$base" == delivery-* ]]; then
            _add_find R3 "$rel:1" "agent filename starts with delivery-" "$base"
        fi
    elif [ "$kind" = skill ] && [ "${rel##*/}" = SKILL.md ]; then
        sname="${rel#skills/}"
        sname="${sname%%/*}"
        if [[ "$sname" == delivery-* ]]; then
            _add_find R3 "$rel:1" "skill directory starts with delivery-" "$sname"
        fi
    fi
    return 0
}

# R3, frontmatter `name:` starting delivery-. Anchored to the key, so prose like
# `ado-delivery-pipeline-brief.md` is never a name. Tracks IN_FM across lines.
# <kind> <line-number> <loc> <line>
_check_r3_fm() {
    local kind="$1" n="$2" loc="$3" line="$4"
    if [ "$kind" != agent ] && [ "$kind" != skill ]; then
        return 0
    fi
    if [ "$n" -eq 1 ] && [ "$line" = "---" ]; then
        IN_FM=1
    elif [ "$IN_FM" -eq 1 ] && [ "$line" = "---" ]; then
        IN_FM=0
    elif [ "$IN_FM" -eq 1 ] && [[ "$line" =~ $DELIVERY_NAME_RE ]]; then
        _add_find R3 "$loc" "name starts with delivery- (not part of this pack)" "$line"
    fi
    return 0
}

# R3, plugin-only variable. Broader than `${CLAUDE_PLUGIN_ROOT}`: the bare
# `$CLAUDE_PLUGIN_ROOT` form leaks exactly as badly. Not applied to docs.
# <kind> <loc> <line>
_check_r3_root() {
    if [ "$1" != doc ] && [[ "$3" == *CLAUDE_PLUGIN_ROOT* ]]; then
        _add_find R3 "$2" "plugin-only variable CLAUDE_PLUGIN_ROOT; not set outside a plugin" "$3"
    fi
    return 0
}

# R1 on ONE pointer run (the characters after `{{AGENT_PACK_REFS}}/`).
# <loc> <line> <run> <own: the references/ file being scanned, or empty>
_check_pointer() {
    local loc="$1" line="$2" run="$3" own="$4" cand dir tok
    _trim_punct "$run"
    cand="$TRIMMED"
    # `dir` is the run minus sentence punctuation (. and -), so a run ending in
    # `/` is a directory mention however the sentence closes. `/<path>.md`, `/*.md`
    # and `/ ` alone stop the run at once (empty) and are placeholders.
    dir="$run"
    while [[ "$dir" == *[.-] ]]; do
        dir="${dir%?}"
    done
    tok="${TOKEN_PREFIX}${TOKEN_TAIL}/${cand}"
    if [ -z "$cand" ] || [[ "$dir" == */ ]]; then
        return 0   # placeholder or directory mention: compliant
    fi
    if [[ "$cand" != ?*.md ]]; then
        _add_find R1 "$loc" "pointer must name a .md file: $tok" "$line"
    elif [[ "$cand" == /* ]] || [[ "/$cand/" == */../* ]]; then
        _add_find R1 "$loc" "unsafe pointer path (leading / or .. segment): $tok" "$line"
    else
        case "$REF_NL" in
            *"$NL$cand$NL"*)
                if [ "$cand" != "$own" ]; then
                    _mark_pointed "$cand"
                fi
                ;;
            *)
                _add_find R1 "$loc" "dangling pointer, no file references/$cand: $tok" "$line"
                ;;
        esac
    fi
    return 0
}

# R1 + R4 -- walk every `{{AGENT_PACK_` occurrence in one line. Sets STRIPPED to
# the line minus each token pointer, which R2 needs.
# <loc> <line> <own>
_scan_tokens() {
    local loc="$1" line="$2" own="$3" rest="$2" run tok
    STRIPPED=""
    while [[ "$rest" == *"$TOKEN_PREFIX"* ]]; do
        STRIPPED+="${rest%%"$TOKEN_PREFIX"*}"
        rest="${rest#*"$TOKEN_PREFIX"}"
        if [[ "$rest" == "$TOKEN_TAIL"* ]]; then
            rest="${rest#"$TOKEN_TAIL"}"
            if [[ "$rest" == /* ]]; then
                rest="${rest#/}"
                _path_run "$rest"
                run="$RUN"
                rest="${rest#"$run"}"
                _check_pointer "$loc" "$line" "$run" "$own"
            fi
        else
            tok="${rest%%[[:space:]]*}"
            _add_find R4 "$loc" "misspelled token, must be exactly ${TOKEN_PREFIX}${TOKEN_TAIL}: ${TOKEN_PREFIX}${tok:0:30}" "$line"
        fi
    done
    STRIPPED+="$rest"
    return 0
}

# R4 spellings the exact-prefix walk above cannot see. Needs STRIPPED.
# <loc> <line>
_check_r4_variants() {
    local loc="$1" line="$2"
    # Every exact-case prefix was consumed by _scan_tokens, so a match left in
    # STRIPPED can only be a different case.
    case "$STRIPPED" in
        *'{{'[Aa][Gg][Ee][Nn][Tt]_[Pp][Aa][Cc][Kk]_*)
            _add_find R4 "$loc" "token spelled with the wrong case, must be exactly ${TOKEN_PREFIX}${TOKEN_TAIL}" "$line"
            ;;
    esac
    # Spaces inside the braces, and the shell-variable forms: neither contains the
    # exact `{{AGENT_PACK_` prefix, and the installer renders neither.
    if [[ "$line" =~ $SPACED_TOKEN_RE ]]; then
        _add_find R4 "$loc" "spaces inside the braces, must be exactly ${TOKEN_PREFIX}${TOKEN_TAIL}" "$line"
    fi
    case "$line" in
        *'$'[Aa][Gg][Ee][Nn][Tt]_[Pp][Aa][Cc][Kk]_*|*'${'[Aa][Gg][Ee][Nn][Tt]_[Pp][Aa][Cc][Kk]_*)
            _add_find R4 "$loc" "shell-variable form is not rendered, must be exactly ${TOKEN_PREFIX}${TOKEN_TAIL}" "$line"
            ;;
    esac
    return 0
}

# R2 -- agents and skills only; the marker excuses this rule alone. Needs STRIPPED.
# <kind> <loc> <line>
_check_r2() {
    local kind="$1" loc="$2" line="$3" hit
    if [ "$kind" != agent ] && [ "$kind" != skill ]; then
        return 0
    fi
    case "$line" in
        *"$BARE_MARKER"*) return 0 ;;
    esac
    if [[ "$STRIPPED" == *references/* ]]; then
        _bare_hits "$STRIPPED"
        for hit in "${BARE_HITS[@]+"${BARE_HITS[@]}"}"; do
            _add_find R2 "$loc" "bare pointer resolves only inside this repo; use ${TOKEN_PREFIX}${TOKEN_TAIL}/<path>.md: $hit" "$line"
        done
    fi
    return 0
}

# _scan_file <root> <file> <kind: agent|skill|ref|doc>
_scan_file() {
    local root="$1" f="$2" kind="$3"
    local rel="${f#"$root"/}" line n=0 loc own=""

    SCANNED=$((SCANNED + 1))
    if [ "$kind" = ref ]; then
        own="${rel#references/}"
    fi
    IN_FM=0
    _check_r3_name "$kind" "$rel"

    while IFS= read -r line || [ -n "$line" ]; do
        n=$((n + 1))
        line="${line%$'\r'}"
        loc="$rel:$n"
        _check_r3_fm "$kind" "$n" "$loc" "$line"

        # Cheap prefilter: nearly every line holds none of the three triggers, and
        # a regex per line over a few hundred files is needless work.
        case "$line" in
            *[Aa][Gg][Ee][Nn][Tt]_[Pp][Aa][Cc][Kk]_*|*references/*|*CLAUDE_PLUGIN_ROOT*) ;;
            *) continue ;;
        esac

        _check_r3_root "$kind" "$loc" "$line"
        _scan_tokens "$loc" "$line" "$own"
        _check_r4_variants "$loc" "$line"
        _check_r2 "$kind" "$loc" "$line"
    done < "$f"
    return 0
}

# Callbacks for _each_pack_file in check_pack.
_scan_agent() {
    _scan_file "$EACH_ROOT" "$1" agent
}
_scan_skill() {
    _scan_file "$EACH_ROOT" "$1" skill
}
# Records a references/ file for exact-match resolution (REF_NL) and for R5.
REF_FILES=()
_collect_ref() {
    local rel="${1#"$EACH_ROOT"/references/}"
    REF_FILES+=("$rel")
    REF_NL+="$rel$NL"
}

# check_pack <root> -- THE predicate. The real scan and the self-test both call
# this, so a rule cannot pass its test and then behave differently on the repo.
# Missing agents/, skills/, references/, CLAUDE.md or docs/ are all fine: there
# is simply nothing to check there. LAST_ROOT records which root FINDS/WARNS/
# SCANNED now describe.
LAST_ROOT=""
check_pack() {
    local root="$1" rel
    LAST_ROOT=""
    FINDS=()
    WARNS=()
    SCANNED=0
    HAS_REFS=0
    REF_NL="$NL"
    REF_FILES=()
    POINTED_NL="$NL"

    _check_names "$root"

    if [ -d "$root/references" ] && ! _is_link "$root/references"; then
        HAS_REFS=1
        _each_pack_file "$root" references _collect_ref
    fi

    _each_pack_file "$root" agents _scan_agent -maxdepth 1
    _each_pack_file "$root" skills _scan_skill

    if [ "${#REF_FILES[@]}" -gt 0 ]; then
        for rel in "${REF_FILES[@]}"; do
            _scan_file "$root" "$root/references/$rel" ref
        done
    fi

    if [ -f "$root/CLAUDE.md" ] && ! _is_link "$root/CLAUDE.md"; then
        _scan_file "$root" "$root/CLAUDE.md" doc
    fi
    # docs/ itself may be the link: the template would be read THROUGH it.
    if [ -f "$root/docs/CLAUDE.template.md" ] && ! _is_link "$root/docs" && ! _is_link "$root/docs/CLAUDE.template.md"; then
        _scan_file "$root" "$root/docs/CLAUDE.template.md" doc
    fi

    # R5 -- computed last, once every pointer in every file has been seen.
    if [ "${#REF_FILES[@]}" -gt 0 ]; then
        for rel in "${REF_FILES[@]}"; do
            case "$POINTED_NL" in
                *"$NL$rel$NL"*) ;;
                *) WARNS+=("references/$rel") ;;
            esac
        done
    fi
    LAST_ROOT="$root"
    return 0
}

# The title of rule $1, looked up in RULE_TABLE; "(unlisted rule)" for an id that
# is not in it.
rule_title() {
    local e
    for e in "${RULE_TABLE[@]}"; do
        if [ "${e%% *}" = "$1" ]; then
            echo "${e#* }"
            return 0
        fi
    done
    echo "(unlisted rule)"
    return 0
}

# Print every entry of FINDS in the script's own [ok]/[!!] format: one [ok] per
# clean rule in $RULES, one [!!] per finding.
#
# THE REPORT LAYER IS A SECOND PLACE A FINDING CAN VANISH. check_pack can be
# right and this loop still drop a finding whose rule name it does not list -- the
# script would then print "[ok]" for everything and exit 0. So findings under any
# rule name this loop does not know are printed too, and the number of [!!] lines
# emitted must equal ${#FINDS[@]} or the script exits 2 (the checker is broken).
_report_findings() {
    local rule entry r loc detail count printed total="${#FINDS[@]}" fail_before="$FAIL"
    for rule in $RULES; do
        count=0
        for entry in "${FINDS[@]+"${FINDS[@]}"}"; do
            IFS=$'\t' read -r r loc detail <<< "$entry"
            if [ "$r" = "$rule" ]; then
                fail "$loc" "$rule: $detail"
                count=$((count + 1))
            fi
        done
        if [ "$count" -eq 0 ]; then
            pass "$rule $(rule_title "$rule") ($SCANNED files scanned)"
        fi
    done
    for entry in "${FINDS[@]+"${FINDS[@]}"}"; do
        IFS=$'\t' read -r r loc detail <<< "$entry"
        case " $RULES " in
            *" $r "*) ;;
            *) fail "$loc" "$r: $detail" ;;
        esac
    done
    # Counted from fail() itself (it increments FAIL once per [!!] line it
    # emits), not from this function's own loop counters, which would agree with
    # themselves by construction.
    printed=$((FAIL - fail_before))
    if [ "$printed" -ne "$total" ]; then
        echo "  [!!] report layer printed $printed finding(s) but check_pack produced $total -- refusing to report a clean result" >&2
        exit 2
    fi
    return 0
}

# check_pack on <root> (default: the real pack), then report it, orphans included.
report_pack_rules() {
    local w root="${1:-$PACK_DIR}"
    check_pack "$root"
    # A floor under every listing check: real agents/ or skills/ directories that
    # yielded NOT ONE scanned file mean the enumeration is broken, whatever it
    # reported. (A linked directory is a finding, not a broken listing.)
    if [ "$SCANNED" -eq 0 ] \
        && { { [ -d "$root/agents" ] && ! _is_link "$root/agents"; } \
            || { [ -d "$root/skills" ] && ! _is_link "$root/skills"; }; }; then
        _fatal "agents/ or skills/ exists but nothing in it was scanned"
    fi
    _report_findings

    if [ "$HAS_REFS" -eq 0 ]; then
        echo "  [--] R5 orphans: no references/ directory -- nothing to check"
    elif [ "${#WARNS[@]}" -eq 0 ]; then
        pass "R5 every references/ file is pointed at"
    else
        for w in "${WARNS[@]}"; do
            echo "  [warn] $w  -- R5 orphan: nothing points at it (warning only)"
            WARN=$((WARN + 1))
        done
    fi
    return 0
}

# ===========================================================================
# THE REAL SCAN, and the guard that keeps a crash from reading as a finding.
# ===========================================================================

# Per-tree floor: a real (non-link) <root>/<sub> directory that the per-file half
# linted NOT ONE file from means that half's enumeration is broken -- and the global
# SCANNED floor in report_pack_rules cannot see it while the other tree still
# scans. Call straight after lint_<sub>_dir, which leaves EACH_COUNT. A
# legitimately empty directory exits 2 as well; that is accepted.
_require_scanned() {
    if [ -d "$1/$2" ] && ! _is_link "$1/$2" && [ "$EACH_COUNT" -eq 0 ]; then
        _fatal "$2/ exists but the per-file half linted nothing in it"
    fi
    return 0
}

# Exit 2 for ANY unexpected failure once the real scan has started. Without it a
# crash under `set -e` exits 1 -- the code that means "findings".
_on_err() {
    _fatal "unexpected error near line $1: the real scan crashed"
}
_guarded() {
    set -E
    trap '_on_err "$LINENO"' ERR
    "$@"
}

# The whole real run against <root>. EXITS: 0 clean, 1 findings.
_real_phase() {
    local root="$1"
    echo "-- Agents"
    lint_agents_dir "$root"
    _require_scanned "$root" agents
    echo ""
    echo "-- Skills"
    lint_skills_dir "$root"
    _require_scanned "$root" skills
    echo ""
    echo "-- Pack references"
    report_pack_rules "$root"
    echo ""
    echo "----"
    if [ "$WARN" -gt 0 ]; then
        echo "  $PASS passed, $FAIL failed, $WARN warning(s)"
    else
        echo "  $PASS passed, $FAIL failed"
    fi
    echo ""
    if [ "$FAIL" -ne 0 ]; then
        exit 1
    fi
    exit 0
}

# ===========================================================================
# SELF-TEST -- runs BEFORE any scan; exits 2 on failure (a finding exits 1).
# ===========================================================================
ASSERTS=0
BROKEN=0
SELFTEST_TMP=""
CC_PASS=0
CC_FAIL=0
CC_WARN=0
CC_OUT=/dev/null
COUNT=0
FIXTURE_GEN=0
CACHED_GEN=-1

# check_pack costs a handful of process spawns, which dominate on Windows, and a
# fixture is usually asserted against many times. A cached result is reused only
# when BOTH hold: check_pack's own record of what its results describe (LAST_ROOT)
# is this root, AND no fixture has been written since the result was computed
# (CACHED_GEN, snapshotted from FIXTURE_GEN here, still equals it). Every fixture
# writer, every raw fixture write and every stub install calls _fixture_dirty --
# the ONLY invalidation, so there is no variable to forget to clear. Production
# code references none of this but LAST_ROOT. _selftest_cache proves a stale hit
# cannot happen.
_fixture_dirty() {
    FIXTURE_GEN=$((FIXTURE_GEN + 1))
}
_check_cached() {
    if [ "$1" != "$LAST_ROOT" ] || [ "$CACHED_GEN" -ne "$FIXTURE_GEN" ]; then
        check_pack "$1"
        CACHED_GEN="$FIXTURE_GEN"
    fi
    return 0
}

# Run a command with PASS/FAIL/WARN zeroed, leave what it counted in
# CC_PASS/CC_FAIL/CC_WARN, and put the real counters back. Its stdout goes to
# $CC_OUT (default /dev/null). Never a subshell, so the command's own side effects
# (FINDS, SCANNED) survive.
_with_clean_counters() {
    local sp="$PASS" sf="$FAIL" sw="$WARN"
    PASS=0
    FAIL=0
    WARN=0
    "$@" > "$CC_OUT"
    CC_PASS="$PASS"
    CC_FAIL="$FAIL"
    CC_WARN="$WARN"
    PASS="$sp"
    FAIL="$sf"
    WARN="$sw"
    return 0
}

# COUNT <- number of lines of <file> starting with / containing <text> (literal).
_count_starting() {
    local l
    COUNT=0
    while IFS= read -r l; do
        case "$l" in
            "$2"*) COUNT=$((COUNT + 1)) ;;
        esac
    done < "$1"
    return 0
}
_count_containing() {
    local l
    COUNT=0
    while IFS= read -r l; do
        case "$l" in
            *"$2"*) COUNT=$((COUNT + 1)) ;;
        esac
    done < "$1"
    return 0
}

# lint_file with <dir> as the working directory, in THIS shell so counters survive.
# <dir> <file> <type>
_lint_in() {
    local old="$PWD"
    cd "$1"
    lint_file "$2" "$3"
    cd "$old"
    return 0
}

# <message...> -- print a self-test failure and mark the run broken.
_broken() {
    echo "  [SELFTEST] $*"
    BROKEN=1
}

# <root> <rule> <file:line> [detail-substring] -- the rule must fire at exactly that
# location. With a 4th argument the finding's DETAIL must also contain it: two
# sub-checks of one rule can otherwise fire at the same place and mask each other
# (dropping the ".md required" check still leaves a "dangling" R1 on the same line).
_expect_fires() {
    local e hit=0 want="${4:-}"
    ASSERTS=$((ASSERTS + 1))
    _check_cached "$1"
    for e in "${FINDS[@]+"${FINDS[@]}"}"; do
        case "$e" in
            "$2"$'\t'"$3"$'\t'*"$want"*) hit=1 ;;
        esac
    done
    if [ "$hit" -ne 1 ]; then
        _broken "rule $2 did NOT fire at $3${want:+ with detail \"$want\"} on fixture ${1##*/}"
        for e in "${FINDS[@]+"${FINDS[@]}"}"; do echo "             got: $e"; done
    fi
    return 0
}

# <root> <rule> <file:line> -- the rule must NOT fire at that location.
_expect_absent() {
    local e hit=0
    ASSERTS=$((ASSERTS + 1))
    _check_cached "$1"
    for e in "${FINDS[@]+"${FINDS[@]}"}"; do
        case "$e" in
            "$2"$'\t'"$3"$'\t'*) hit=1 ;;
        esac
    done
    if [ "$hit" -eq 1 ]; then
        _broken "rule $2 fired at $3 on fixture ${1##*/} where it must stay silent (false positive)"
    fi
    return 0
}

# <root> -- no finding and no warning at all.
_expect_silent() {
    local e
    ASSERTS=$((ASSERTS + 1))
    _check_cached "$1"
    if [ "${#FINDS[@]}" -gt 0 ] || [ "${#WARNS[@]}" -gt 0 ]; then
        _broken "COMPLIANT fixture ${1##*/} produced output (false positive):"
        for e in "${FINDS[@]+"${FINDS[@]}"}"; do echo "             finding: $e"; done
        for e in "${WARNS[@]+"${WARNS[@]}"}"; do echo "             warning: $e"; done
    fi
    return 0
}

# mkdir -p without the process spawn when the directory is already there; on
# Windows a spawn is the dominant cost and the writers below call this ~100 times.
_mkd() {
    if [ ! -d "$1" ]; then
        mkdir -p "$1"
    fi
    return 0
}

# Fixture writers. _fx_agent / _fx_skill emit a 4-line frontmatter, so the first
# body line is line 5 -- every expected location below depends on that.
# <root> <file.md> <name> <body line>...
_fx_agent() {
    local root="$1" file="$2" name="$3"
    shift 3
    _fixture_dirty
    _mkd "$root/agents"
    {
        printf -- '---\nname: %s\ndescription: fixture\n---\n' "$name"
        printf '%s\n' "$@"
    } > "$root/agents/$file"
}
# <root> <dir> <name> <body line>...
_fx_skill() {
    local root="$1" dir="$2" name="$3"
    shift 3
    _fixture_dirty
    _mkd "$root/skills/$dir"
    {
        printf -- '---\nname: %s\ndescription: fixture\n---\n' "$name"
        printf '%s\n' "$@"
    } > "$root/skills/$dir/SKILL.md"
}
# <root> <relpath> <line>...   (no frontmatter; line 1 is the first argument)
_fx_file() {
    local root="$1" rel="$2"
    shift 2
    _fixture_dirty
    # A bare filename has no slash for ${rel%/*} to strip, which would turn
    # CLAUDE.md itself into a directory.
    if [[ "$rel" == */* ]]; then
        _mkd "$root/${rel%/*}"
    else
        _mkd "$root"
    fi
    printf '%s\n' "$@" > "$root/$rel"
}
# <target> <linkpath> -- a real symlink where the machine can make one; otherwise a
# plain copy (Git Bash's `ln -s` copies and still returns 0), which _selftest_r7
# detects with `[ -L ]` and then covers with stubs. Never fatal.
_link_or_copy() {
    _fixture_dirty
    _mkd "${2%/*}"
    ln -s "$1" "$2" 2>/dev/null || cp -r "$1" "$2"
    return 0
}

# ---- compliant trees and empty/absent inputs -------------------------------
_selftest_good() {
    local tmp="$SELFTEST_TMP" g="$SELFTEST_TMP/good"

    # Realistic prose that merely DESCRIBES the mechanism.
    _fx_agent "$g" a.md a \
        'Long-form material lives in the references/ directory and is loaded on demand.' \
        'The token {{AGENT_PACK_REFS}}/name.md is rendered to a real path at install time.' \
        'Placeholders read {{AGENT_PACK_REFS}}/<path>.md, or just {{AGENT_PACK_REFS}} on its own.' \
        'Read `{{AGENT_PACK_REFS}}/sub/deep.md`, then stop; see also {{AGENT_PACK_REFS}}/name.md.' \
        'Legacy notes live in references/legacy.md for history. <!-- lint-ok: bare-ref -->' \
        'Unrelated prose: docs/ado-delivery-pipeline-brief.md, and notreferences/x.md.' \
        'Files live under {{AGENT_PACK_REFS}}/ and are read on demand.' \
        'Subfolders are directory mentions too: {{AGENT_PACK_REFS}}/sub/.' \
        'Fill in {{AGENT_PACK_REFS}}/plan_template.md before starting.'
    _fx_file "$g" references/plan_template.md '# Template' 'Companion: {{AGENT_PACK_REFS}}/name.md'
    _fx_skill "$g" s s 'Pointer: {{AGENT_PACK_REFS}}/name.md' 'second line' 'third line'
    _fx_file "$g" skills/s/extra.md \
        'Extra file beside SKILL.md. See {{AGENT_PACK_REFS}}/sub/deep.md and the references/ directory.'
    _fx_file "$g" references/name.md '# Name' 'Companion: {{AGENT_PACK_REFS}}/sub/deep.md'
    _fx_file "$g" references/sub/deep.md '# Deep' 'Leaf. A bare references/name.md is fine here: R2 does not scan references/.'
    _fx_file "$g" CLAUDE.md '# Doc' \
        'Pointer {{AGENT_PACK_REFS}}/name.md; a bare references/name.md is fine in this file too.'
    _fx_file "$g" docs/CLAUDE.template.md 'Template pointer {{AGENT_PACK_REFS}}/name.md'
    _expect_silent "$g"
    # A scanner that reads nothing reports a clean repo: 1 agent + 2 skill files
    # + 3 references + CLAUDE.md + the template.
    ASSERTS=$((ASSERTS + 1))
    if [ "$SCANNED" -ne 8 ]; then
        _broken "the compliant tree scanned $SCANNED files, expected 8 -- the scanner is not reading what it should"
    fi

    # EMPTY and ABSENT inputs must pass without error.
    mkdir -p "$tmp/empty"
    _fixture_dirty
    _expect_silent "$tmp/empty"
    mkdir -p "$tmp/empty-refs/references"
    _fixture_dirty
    _expect_silent "$tmp/empty-refs"
    _expect_silent "$tmp/does-not-exist"
    _fx_agent "$tmp/no-refs" a.md a 'Prose about the references/ directory, with no pointer at all.'
    _expect_silent "$tmp/no-refs"

    # The per-file loops say so when there is nothing to lint (the shared tail).
    CC_OUT="$tmp/none-a.out"
    _with_clean_counters lint_agents_dir "$tmp/empty"
    CC_OUT="$tmp/none-s.out"
    _with_clean_counters lint_skills_dir "$tmp/empty"
    CC_OUT=/dev/null
    ASSERTS=$((ASSERTS + 2))
    _count_containing "$tmp/none-a.out" '(no agent files found)'
    if [ "$COUNT" -ne 1 ]; then
        _broken "lint_agents_dir printed no '(no agent files found)' tail for an empty tree"
    fi
    _count_containing "$tmp/none-s.out" '(no skill files found)'
    if [ "$COUNT" -ne 1 ]; then
        _broken "lint_skills_dir printed no '(no skill files found)' tail for an empty tree"
    fi
    return 0
}

_selftest_r1() {
    local tmp="$SELFTEST_TMP" d

    d="$tmp/r1"
    _fx_file "$d" references/name.md 'x'
    _fx_agent "$d" x.md x 'Valid: {{AGENT_PACK_REFS}}/name.md' 'Dangling: {{AGENT_PACK_REFS}}/missing.md.'
    _expect_fires "$d" R1 agents/x.md:6
    _expect_absent "$d" R1 agents/x.md:5

    d="$tmp/r1-skill"
    _fx_file "$d" references/name.md 'x'
    _fx_skill "$d" s s 'ok' 'ok' 'ok'
    _fx_file "$d" skills/s/extra.md 'Dangling in a non-SKILL file: {{AGENT_PACK_REFS}}/gone.md'
    _expect_fires "$d" R1 skills/s/extra.md:1

    d="$tmp/r1-ref-and-docs"
    _fx_file "$d" references/r.md 'Dangling from a reference: {{AGENT_PACK_REFS}}/gone.md'
    _fx_file "$d" CLAUDE.md 'Dangling from CLAUDE.md: {{AGENT_PACK_REFS}}/gone.md'
    _fx_file "$d" docs/CLAUDE.template.md 'Dangling from the template: {{AGENT_PACK_REFS}}/gone.md'
    _expect_fires "$d" R1 references/r.md:1
    _expect_fires "$d" R1 CLAUDE.md:1
    _expect_fires "$d" R1 docs/CLAUDE.template.md:1

    d="$tmp/r1-traversal"
    _fx_file "$d" references/name.md 'x'
    _fx_agent "$d" x.md x 'Escapes: {{AGENT_PACK_REFS}}/../agents/x.md'
    _expect_fires "$d" R1 agents/x.md:5 'unsafe pointer path'

    d="$tmp/r1-case"
    _fx_file "$d" references/name.md 'x'
    _fx_agent "$d" x.md x 'Wrong case: {{AGENT_PACK_REFS}}/Name.md'
    _expect_fires "$d" R1 agents/x.md:5

    d="$tmp/r1-no-refs-dir"
    _fx_agent "$d" x.md x 'No references/ dir exists: {{AGENT_PACK_REFS}}/name.md'
    _expect_fires "$d" R1 agents/x.md:5

    # A token followed by a path run that does not end in .md is a pointer with a
    # wrong or forgotten extension, and fails open exactly like a dangling one.
    # A directory mention, a placeholder and the bare token stay compliant.
    d="$tmp/r1-ext"
    _fx_file "$d" references/name.md 'x'
    _fx_agent "$d" x.md x \
        'No extension: {{AGENT_PACK_REFS}}/name here.' \
        'Wrong extension: {{AGENT_PACK_REFS}}/name.mdd here.' \
        'Double extension: {{AGENT_PACK_REFS}}/name.md.txt.' \
        'Compliant: {{AGENT_PACK_REFS}}/sub/ and {{AGENT_PACK_REFS}}/ and {{AGENT_PACK_REFS}}.' \
        'Underscore name that does not exist: {{AGENT_PACK_REFS}}/plan_missing.md'
    _expect_fires "$d" R1 agents/x.md:5 'must name a .md file'
    _expect_fires "$d" R1 agents/x.md:6 'must name a .md file'
    _expect_fires "$d" R1 agents/x.md:7 'must name a .md file'
    _expect_absent "$d" R1 agents/x.md:8
    # `_` is a path character: this must be read as a pointer and found dangling,
    # not silently truncated to the run `plan`.
    _expect_fires "$d" R1 agents/x.md:9 'dangling pointer, no file references/plan_missing.md'
    return 0
}

_selftest_r2() {
    local tmp="$SELFTEST_TMP" b

    b="$tmp/r2"
    _fx_file "$b" references/sub/references/z.md 'x'
    _fx_agent "$b" x.md x \
        'Read references/x.md first.' \
        'Read references/x.md.' \
        'See skills/foo/references/y.md for more.' \
        'Valid, and nested under a directory also named references: {{AGENT_PACK_REFS}}/sub/references/z.md' \
        'Marked prose: references/x.md <!-- lint-ok: bare-ref -->' \
        'The references/ directory alone is not a file.' \
        'Underscore name: references/plan_template.md'
    _expect_fires "$b" R2 agents/x.md:11
    _expect_fires "$b" R2 agents/x.md:5
    _expect_fires "$b" R2 agents/x.md:6
    _expect_fires "$b" R2 agents/x.md:7
    _expect_absent "$b" R2 agents/x.md:8
    _expect_absent "$b" R2 agents/x.md:9
    _expect_absent "$b" R2 agents/x.md:10

    b="$tmp/r2-skill"
    _fx_skill "$b" s s 'Bare: references/x.md' 'ok' 'ok'
    _fx_file "$b" skills/s/extra.md 'Bare in a non-SKILL file: references/x.md'
    _expect_fires "$b" R2 skills/s/SKILL.md:5
    _expect_fires "$b" R2 skills/s/extra.md:1
    return 0
}

_selftest_r3() {
    local tmp="$SELFTEST_TMP" p n

    p="$tmp/r3-root"
    _fx_agent "$p" x.md x 'Run ${CLAUDE_PLUGIN_ROOT}/scripts/x.sh'
    _fx_skill "$p" s s 'Run $CLAUDE_PLUGIN_ROOT/bin/y' 'ok' 'ok'
    _fx_file "$p" references/r.md 'Run ${CLAUDE_PLUGIN_ROOT}/z'
    _fx_file "$p" CLAUDE.md 'Outside R3 scope: ${CLAUDE_PLUGIN_ROOT}'
    _expect_fires "$p" R3 agents/x.md:5
    _expect_fires "$p" R3 skills/s/SKILL.md:5
    _expect_fires "$p" R3 references/r.md:1
    _expect_absent "$p" R3 CLAUDE.md:1

    n="$tmp/r3-name"
    _fx_agent "$n" foo.md delivery-foo 'body'
    _fx_agent "$n" delivery-bar.md bar 'body'
    _fx_agent "$n" quoted.md '"delivery-z"' 'body'
    _fx_agent "$n" ok.md ado-delivery-x 'body'
    _fx_skill "$n" delivery-q q 'ok' 'ok' 'ok'
    _fx_skill "$n" delivery-s2 delivery-s2 'ok' 'ok' 'ok'
    _expect_fires "$n" R3 agents/foo.md:2
    _expect_fires "$n" R3 agents/delivery-bar.md:1
    _expect_fires "$n" R3 agents/quoted.md:2
    _expect_fires "$n" R3 skills/delivery-q/SKILL.md:1
    _expect_fires "$n" R3 skills/delivery-s2/SKILL.md:2
    _expect_absent "$n" R3 agents/ok.md:2
    _expect_absent "$n" R3 agents/ok.md:1
    return 0
}

_selftest_r4() {
    local t="$SELFTEST_TMP/r4"

    _fx_file "$t" references/name.md 'x'
    _fx_agent "$t" x.md x \
        'Typo {{AGENT_PACK_REF}}/name.md here.' \
        'Typo {{AGENT_PACK_REFSS}}/name.md here.' \
        'Typo {{agent_pack_refs}}/name.md here.' \
        'Typo {{AGENT_PACK_REFS }}/name.md here.' \
        'Mixed {{AGENT_PACK_REFS}}/name.md and {{AGENT_PACK_REF}}/name.md.' \
        'Spaced {{ AGENT_PACK_REFS }}/name.md here.' \
        'Shell variable $AGENT_PACK_REFS/name.md here.' \
        'Braced shell variable ${AGENT_PACK_REFS}/name.md here.'
    _fx_file "$t" references/r.md 'Typo {{AGENT_PACK_ROOT}}/name.md'
    _fx_file "$t" CLAUDE.md 'Typo {{AGENT_PACK_REF}}/name.md'
    _expect_fires "$t" R4 agents/x.md:5
    _expect_fires "$t" R4 agents/x.md:6
    _expect_fires "$t" R4 agents/x.md:7 'wrong case'
    _expect_fires "$t" R4 agents/x.md:8
    _expect_fires "$t" R4 agents/x.md:9
    _expect_fires "$t" R4 agents/x.md:10 'spaces inside the braces'
    _expect_fires "$t" R4 agents/x.md:11 'shell-variable form'
    _expect_fires "$t" R4 agents/x.md:12 'shell-variable form'
    _expect_fires "$t" R4 references/r.md:1
    _expect_fires "$t" R4 CLAUDE.md:1
    # a misspelled token is not a pointer, so it must not ALSO read as dangling
    _expect_absent "$t" R1 agents/x.md:5
    # ...and the valid half of a mixed line still resolves
    _expect_absent "$t" R1 agents/x.md:9
    return 0
}

# R5 is a warning, never a finding.
_selftest_r5() {
    local o="$SELFTEST_TMP/r5" e

    _fx_file "$o" references/used.md 'x'
    _fx_file "$o" references/lonely.md 'Points only at itself: {{AGENT_PACK_REFS}}/lonely.md'
    _fx_agent "$o" x.md x 'Read {{AGENT_PACK_REFS}}/used.md'
    ASSERTS=$((ASSERTS + 1))
    check_pack "$o"
    e=" ${WARNS[*]+"${WARNS[*]}"} "
    if [ "${#FINDS[@]}" -ne 0 ] || [ "${#WARNS[@]}" -ne 1 ] || [ "$e" != " references/lonely.md " ]; then
        _broken "R5 must warn on exactly references/lonely.md and produce no finding; got ${#FINDS[@]} finding(s), warnings:$e"
    fi
    # ...and the report layer must print it as a warning, count it, and not fail.
    ASSERTS=$((ASSERTS + 1))
    _with_clean_counters report_pack_rules "$o"
    if [ "$CC_WARN" -ne 1 ] || [ "$CC_FAIL" -ne 0 ]; then
        _broken "R5 report: expected 1 warning and 0 failures, counted $CC_WARN warning(s) and $CC_FAIL failure(s)"
    fi
    return 0
}

# R6, and the per-file half's three hardening fixes.
_selftest_r6() {
    local tmp="$SELFTEST_TMP" r6="$SELFTEST_TMP/r6" gd="$SELFTEST_TMP/glob" out="$SELFTEST_TMP/lint.out"

    # Extra files in a skill directory are not a malformed skill.
    mkdir -p "$r6/skills/good-skill" "$r6/skills/only-extra" "$r6/skills/wrong"
    printf -- '---\nname: good-skill\ndescription: fixture skill\n---\nline one\nline two\nline three\n' > "$r6/skills/good-skill/SKILL.md"
    printf 'Extra reference material with no frontmatter.\n' > "$r6/skills/good-skill/extra.md"
    printf 'Notes only; this directory has no SKILL.md.\n' > "$r6/skills/only-extra/notes.md"
    _fixture_dirty
    # ...while the existing name-matches-directory check still fires beside them.
    # One run proves both: exactly one pass (good-skill, with extra.md beside it),
    # exactly one failure (wrong's name mismatch), and nothing for only-extra -- an
    # extra file or a SKILL.md-less directory flagged would make the failures 2.
    printf -- '---\nname: other\ndescription: fixture skill\n---\nline one\nline two\nline three\n' > "$r6/skills/wrong/SKILL.md"
    _fixture_dirty
    ASSERTS=$((ASSERTS + 1))
    _with_clean_counters lint_skills_dir "$r6"
    if [ "$CC_PASS" -ne 1 ] || [ "$CC_FAIL" -ne 1 ]; then
        _broken "R6: expected 1 pass (good-skill) and 1 failure (wrong's name mismatch), extra files and a SKILL.md-less directory unflagged; got pass=$CC_PASS fail=$CC_FAIL"
    fi

    # A frontmatter key must not be pathname-expanded: `a*` is ONE unknown field
    # named `a*`, not a glob against whatever the cwd holds (here: aa and ab).
    mkdir -p "$gd/cwd" "$gd/pack"
    : > "$gd/cwd/aa"
    : > "$gd/cwd/ab"
    printf -- '---\nname: k\ndescription: d\na*: 1\n---\nb1\nb2\nb3\n' > "$gd/pack/k.md"
    _fixture_dirty
    CC_OUT="$out"
    ASSERTS=$((ASSERTS + 1))
    _with_clean_counters _lint_in "$gd/cwd" "$gd/pack/k.md" agent
    CC_OUT=/dev/null
    _count_containing "$out" 'Unknown frontmatter field'
    if [ "$COUNT" -ne 1 ]; then
        _broken "per-file: key 'a*' produced $COUNT unknown-field lines, expected exactly 1 (pathname expansion?)"
    fi
    _count_containing "$out" 'Unknown frontmatter field: `a*`'
    if [ "$COUNT" -ne 1 ]; then
        _broken "per-file: the unknown field was not reported under its own name a*"
    fi

    # A value taken from a file is not an echo option: a name of `-n` must fail
    # the hyphen rule instead of being swallowed.
    _fx_agent "$tmp/hy" a.md -n 'b' 'b' 'b'
    CC_OUT="$out"
    ASSERTS=$((ASSERTS + 1))
    _with_clean_counters lint_file "$tmp/hy/agents/a.md" agent
    CC_OUT=/dev/null
    _count_containing "$out" 'name must not start or end with a hyphen'
    if [ "$COUNT" -ne 1 ] || [ "$CC_FAIL" -lt 1 ]; then
        _broken "per-file: a name of '-n' was not reported as starting with a hyphen (echo swallowed it?)"
    fi

    # An invalid UTF-8 byte inside a name VALUE (file content, which any machine can
    # hold) must fail the character rule, not slip past a locale-dependent grep.
    # NOTE: this machine cannot make an invalid-byte FILE NAME (MSYS re-encodes the
    # byte as U+00FF), so the LC_ALL=C on the control-character `find` is not
    # exercised against one here; and because the ambient locale here is already C,
    # dropping the LC_ALL=C from these greps is not caught either.
    mkdir -p "$tmp/ib/agents"
    printf -- '---\nname: bad\xff\ndescription: d\n---\nb\nb\nb\n' > "$tmp/ib/agents/a.md"
    _fixture_dirty
    CC_OUT="$out"
    ASSERTS=$((ASSERTS + 1))
    _with_clean_counters lint_file "$tmp/ib/agents/a.md" agent
    CC_OUT=/dev/null
    _count_containing "$out" 'name contains invalid characters'
    if [ "$COUNT" -ne 1 ]; then
        _broken "per-file: a name holding an invalid byte was not reported as having invalid characters"
    fi
    return 0
}

# Symlink support probe, and the stubs for a machine without it. Where the machine
# cannot create a link (Git Bash copies instead), `_is_link` and `_find_flagged` are
# STUBBED so the skip-and-report logic is still exercised; the bodies of those two
# one-liners are then not. The stubs name EXACT paths only, never "anything under
# it": a file reached through a linked directory is not itself a link, and the
# checks that skip the directory and the file must each be able to fail alone.
LINK_REAL=0
ORIG_IS_LINK=""
ORIG_FIND_LINKS=""
_link_stubs_on() {
    : > "$SELFTEST_TMP/probe-target"
    _fixture_dirty
    _link_or_copy "$SELFTEST_TMP/probe-target" "$SELFTEST_TMP/probe-link"
    if [ -L "$SELFTEST_TMP/probe-link" ]; then
        LINK_REAL=1
    else
        LINK_REAL=0
        ORIG_IS_LINK="$(declare -f _is_link)"
        ORIG_FIND_LINKS="$(declare -f _find_flagged)"
        _is_link() {
            case "$1" in
                */linkme.md|*/linkdir|*/linkfile/SKILL.md|*/r7-linkdoc/CLAUDE.md) return 0 ;;
                */r7-linkagents/agents|*/r7-linkskills/skills|*/r7-linkdocs/docs|*/r7-linkrefs/references) return 0 ;;
                */r7-linktpl/docs/CLAUDE.template.md) return 0 ;;
            esac
            return 1
        }
        _find_flagged() {
            _nul_find "$@" \( -name linkme.md -o -name linkdir -o -path '*/linkfile/SKILL.md' -o -path '*/r7-linkdoc/CLAUDE.md' -o -path '*/r7-linktpl/docs/CLAUDE.template.md' -o -path '*[[:cntrl:]]*' \)
        }
        echo "  [--] self-test: no symlink support here; _is_link/_find_flagged are stubbed for the link fixtures"
    fi
    _fixture_dirty   # the stubs change what check_pack returns for an unchanged tree
}
_link_stubs_off() {
    if [ "$LINK_REAL" -eq 0 ]; then
        eval "$ORIG_IS_LINK"
        eval "$ORIG_FIND_LINKS"
    fi
    _fixture_dirty
}

# R7: control-character names, symlinks, and the per-file half's enumeration.
_selftest_r7() {
    _selftest_r7_ctrl
    _link_stubs_on
    _selftest_r7_links
    _selftest_r7_dirs
    _link_stubs_off
    _selftest_r7_hidden
    _selftest_find
    return 0
}

_selftest_r7_ctrl() {
    local d="$SELFTEST_TMP/r7-ctrl" pf="$SELFTEST_TMP/r7-pf" out="$SELFTEST_TMP/pf.out"
    local nl=$'a\nb.md' tb=$'t\tab.md' forged=$'zz\n  [ok] forged.md'

    # -- control characters. A newline in a name once split the line-based listing,
    # so a file `a<LF>b.md` made a pointer to `b.md` (and to `a`) RESOLVE.
    mkdir -p "$d/references" "$d/agents"
    if printf 'x\n' > "$d/references/$nl" 2>/dev/null \
        && printf 'x\n' > "$d/references/$tb" 2>/dev/null \
        && printf '%s\n' '---' 'name: n' 'description: d' '---' 'body' > "$d/agents/$nl" 2>/dev/null; then
        _fixture_dirty
        _fx_agent "$d" x.md x \
            'Half of the name: {{AGENT_PACK_REFS}}/b.md' \
            'Other half: {{AGENT_PACK_REFS}}/a.md'
        _expect_fires "$d" R1 agents/x.md:5 'dangling pointer, no file references/b.md'
        _expect_fires "$d" R1 agents/x.md:6 'dangling pointer, no file references/a.md'
        _expect_fires "$d" R7 "\$'references/a\\nb.md':1" 'control character'
        _expect_fires "$d" R7 "\$'references/t\\tab.md':1" 'control character'
        _expect_fires "$d" R7 "\$'agents/a\\nb.md':1" 'control character'
    else
        echo "  [--] self-test: this filesystem refuses control-character file names; the R7 control-character fixtures were skipped"
    fi

    # The per-file half enumerates with the same control-character-free listing, so
    # a name carrying a newline cannot forge a log line through `label` (a glob
    # matched it, and `pass "$label"` then printed a fake "[ok] forged.md" line).
    _fx_agent "$pf" ok.md ok 'l1' 'l2' 'l3'
    if printf '%s\n' '---' 'name: zz' 'description: d' '---' 'l1' 'l2' 'l3' > "$pf/agents/$forged" 2>/dev/null; then
        _fixture_dirty
        CC_OUT="$out"
        ASSERTS=$((ASSERTS + 1))
        _with_clean_counters lint_agents_dir "$pf"
        CC_OUT=/dev/null
        _count_starting "$out" '  [ok] forged'
        if [ "$COUNT" -ne 0 ] || [ "$CC_PASS" -ne 1 ] || [ "$CC_FAIL" -ne 0 ]; then
            _broken "per-file: a newline in a file name forged a log line or was linted (forged lines=$COUNT pass=$CC_PASS fail=$CC_FAIL, expected 0/1/0)"
        fi
    fi
    return 0
}

_selftest_r7_links() {
    local k="$SELFTEST_TMP/r7-link" p

    mkdir -p "$k/references" "$k/skills/s" "$k/agents"
    printf '%s\n' 'Leak if followed: {{AGENT_PACK_REFS}}/leak.md' > "$SELFTEST_TMP/outside.md"
    _fixture_dirty
    _fx_file "$k" references/name.md 'x'
    _fx_agent "$k" ok.md ok 'Valid: {{AGENT_PACK_REFS}}/name.md' 'second line' 'third line'
    _fx_skill "$k" s s 'ok' 'ok' 'ok'
    for p in agents references skills/s; do
        _link_or_copy "$SELFTEST_TMP/outside.md" "$k/$p/linkme.md"
    done
    _expect_fires "$k" R7 agents/linkme.md:1 'symlink'
    _expect_fires "$k" R7 references/linkme.md:1 'symlink'
    _expect_fires "$k" R7 skills/s/linkme.md:1 'symlink'
    # never read through: the target's dangling pointer must not be reported ...
    _expect_absent "$k" R1 agents/linkme.md:1
    _expect_absent "$k" R1 references/linkme.md:1
    _expect_absent "$k" R1 skills/s/linkme.md:1
    # ... and the links are not counted as scanned: ok.md, s/SKILL.md, name.md.
    ASSERTS=$((ASSERTS + 1))
    check_pack "$k"
    if [ "$SCANNED" -ne 3 ]; then
        _broken "link fixture scanned $SCANNED files, expected 3 -- a symlink was read"
    fi
    # The per-file half must skip links too: agents/linkme.md has no frontmatter,
    # so reading it through would FAIL the lint, and only ok.md may pass.
    ASSERTS=$((ASSERTS + 1))
    _with_clean_counters lint_agents_dir "$k"
    if [ "$CC_PASS" -ne 1 ] || [ "$CC_FAIL" -ne 0 ]; then
        _broken "lint_agents_dir read through a symlink (pass=$CC_PASS fail=$CC_FAIL, expected 1/0)"
    fi
    # A linked skill DIRECTORY and a linked SKILL.md are each skipped by the
    # per-file half, on their own: both targets are VALID skills, so reading either
    # through would add a pass and only s may pass.
    mkdir -p "$SELFTEST_TMP/linkedskill" "$k/skills/linkfile"
    printf -- '---\nname: linkdir\ndescription: d\n---\nl1\nl2\nl3\n' > "$SELFTEST_TMP/linkedskill/SKILL.md"
    printf -- '---\nname: linkfile\ndescription: d\n---\nl1\nl2\nl3\n' > "$SELFTEST_TMP/linkedskillfile.md"
    _fixture_dirty
    _link_or_copy "$SELFTEST_TMP/linkedskill" "$k/skills/linkdir"
    _link_or_copy "$SELFTEST_TMP/linkedskillfile.md" "$k/skills/linkfile/SKILL.md"
    _expect_fires "$k" R7 skills/linkdir:1 'symlink'
    _expect_fires "$k" R7 skills/linkfile/SKILL.md:1 'symlink'
    ASSERTS=$((ASSERTS + 1))
    _with_clean_counters lint_skills_dir "$k"
    if [ "$CC_PASS" -ne 1 ] || [ "$CC_FAIL" -ne 0 ]; then
        _broken "lint_skills_dir read through a linked skill directory or SKILL.md (pass=$CC_PASS fail=$CC_FAIL, expected 1/0)"
    fi

    # CLAUDE.md as a link: reported, and not read.
    _link_or_copy "$SELFTEST_TMP/outside.md" "$SELFTEST_TMP/r7-linkdoc/CLAUDE.md"
    _expect_fires "$SELFTEST_TMP/r7-linkdoc" R7 CLAUDE.md:1 'symlink'
    _expect_absent "$SELFTEST_TMP/r7-linkdoc" R1 CLAUDE.md:1
    return 0
}

# A linked agents/, skills/, references/ or docs/ ITSELF. The final-component test
# on each file never saw these: every file read through the link looked like a
# plain file. One fixture root each; the link target is a valid tree, so reading
# through the link would add a pass (or resolve a pointer) and each assertion can
# fail on its own.
_selftest_r7_dirs() {
    local t="$SELFTEST_TMP" r

    mkdir -p "$t/src-agents" "$t/src-skills/s" "$t/src-docs" "$t/src-refs"
    printf -- '---\nname: ok\ndescription: d\n---\nl1\nl2\nl3\n' > "$t/src-agents/ok.md"
    printf -- '---\nname: s\ndescription: d\n---\nl1\nl2\nl3\n' > "$t/src-skills/s/SKILL.md"
    printf '%s\n' 'Leak if read through docs: {{AGENT_PACK_REFS}}/leak.md' > "$t/src-docs/CLAUDE.template.md"
    printf '%s\n' 'x' > "$t/src-refs/name.md"
    _fixture_dirty

    r="$t/r7-linkagents"
    _link_or_copy "$t/src-agents" "$r/agents"
    _expect_fires "$r" R7 agents:1 'symlinked directory'
    ASSERTS=$((ASSERTS + 1))
    _with_clean_counters lint_agents_dir "$r"
    if [ "$CC_PASS" -ne 0 ] || [ "$CC_FAIL" -ne 0 ]; then
        _broken "lint_agents_dir read through a linked agents/ (pass=$CC_PASS fail=$CC_FAIL, expected 0/0)"
    fi
    ASSERTS=$((ASSERTS + 1))
    _with_clean_counters report_pack_rules "$r"   # must report, not die: a link is a finding
    if [ "$SCANNED" -ne 0 ] || [ "$CC_FAIL" -lt 1 ]; then
        _broken "a linked agents/ was scanned or not failed (scanned=$SCANNED fail=$CC_FAIL)"
    fi

    r="$t/r7-linkskills"
    _link_or_copy "$t/src-skills" "$r/skills"
    _expect_fires "$r" R7 skills:1 'symlinked directory'
    ASSERTS=$((ASSERTS + 1))
    _with_clean_counters lint_skills_dir "$r"
    if [ "$CC_PASS" -ne 0 ] || [ "$CC_FAIL" -ne 0 ]; then
        _broken "lint_skills_dir read through a linked skills/ (pass=$CC_PASS fail=$CC_FAIL, expected 0/0)"
    fi
    check_pack "$r"
    ASSERTS=$((ASSERTS + 1))
    if [ "$SCANNED" -ne 0 ]; then
        _broken "a linked skills/ was scanned ($SCANNED files)"
    fi

    r="$t/r7-linkdocs"
    _link_or_copy "$t/src-docs" "$r/docs"
    _expect_fires "$r" R7 docs:1 'symlinked directory'
    _expect_absent "$r" R1 docs/CLAUDE.template.md:1
    ASSERTS=$((ASSERTS + 1))
    if [ "$SCANNED" -ne 0 ]; then
        _broken "docs/CLAUDE.template.md was read through a linked docs/ ($SCANNED files)"
    fi

    # docs/ is a real directory here and only the template FILE is the link.
    r="$t/r7-linktpl"
    mkdir -p "$r/docs"
    _fixture_dirty
    _link_or_copy "$t/src-docs/CLAUDE.template.md" "$r/docs/CLAUDE.template.md"
    _expect_fires "$r" R7 docs/CLAUDE.template.md:1 'symlink'
    _expect_absent "$r" R1 docs/CLAUDE.template.md:1

    r="$t/r7-linkrefs"
    _link_or_copy "$t/src-refs" "$r/references"
    _fx_agent "$r" x.md x 'Valid only if references/ were followed: {{AGENT_PACK_REFS}}/name.md' 'l2' 'l3'
    _expect_fires "$r" R7 references:1 'symlinked directory'
    _expect_fires "$r" R1 agents/x.md:5 'dangling pointer'
    # a linked references/ is not "a references/ directory that holds nothing": the
    # R5 line must say there is none to check
    ASSERTS=$((ASSERTS + 1))
    if [ "$HAS_REFS" -ne 0 ]; then
        _broken "a linked references/ was entered (HAS_REFS=$HAS_REFS, expected 0)"
    fi
    return 0
}

# Hidden files. The per-file half used globs, which skip dotfiles, while the
# find-based R1-R4 scan included them -- so a hidden agent or skill dodged the name
# and description checks. Both halves now share one enumeration.
_selftest_r7_hidden() {
    local h="$SELFTEST_TMP/r7-hidden"

    _fx_agent "$h" .hidden.md 'Bad Name' 'l1' 'Typo {{AGENT_PACK_REF}}/x.md' 'l3'
    _fx_skill "$h" .d d 'l1' 'l2' 'l3'
    ASSERTS=$((ASSERTS + 1))
    _with_clean_counters lint_agents_dir "$h"
    if [ "$CC_FAIL" -lt 1 ]; then
        _broken "a hidden agents/.hidden.md skipped the per-file checks (nothing failed; its name has a space)"
    fi
    ASSERTS=$((ASSERTS + 1))
    _with_clean_counters lint_skills_dir "$h"
    if [ "$CC_FAIL" -lt 1 ]; then
        _broken "a hidden skills/.d/SKILL.md skipped the per-file checks (nothing failed; its name d does not match .d)"
    fi
    # ...and the pointer rules see the same hidden file, so the halves agree.
    _expect_fires "$h" R4 agents/.hidden.md:6 'misspelled token'
    return 0
}

# Every listing fails CLOSED. A find or sort that dies, or the wrong find
# (Windows' find.exe is a text-search tool), must exit 2 and not yield an empty
# listing that prints "[ok] (0 files scanned)". Each stub runs in a subshell.
# Run <command...> in a subshell (errexit on) after evaluating <stub definition>,
# and require its exit status AND a substring of its STDERR. Asserting the message
# is what tells a deliberate _fatal from the same exit 2 produced by a syntax error
# or an unrelated crash. Stdout is discarded.
# <want rc> <want stderr substring, or empty> <stub definition> <command...>
_expect_exit() {
    local want_rc="$1" want_err="$2" stub="$3" rc errf="$SELFTEST_TMP/err.out"
    shift 3
    ASSERTS=$((ASSERTS + 1))
    : > "$errf"
    set +e
    ( set -e; eval "$stub"; "$@" ) > /dev/null 2> "$errf"
    rc=$?
    set -e
    if [ "$rc" -ne "$want_rc" ]; then
        _broken "[$stub] expected exit $want_rc, got $rc for: $*"
    fi
    if [ -n "$want_err" ]; then
        _count_containing "$errf" "$want_err"
        if [ "$COUNT" -eq 0 ]; then
            _broken "[$stub] stderr lacks \"$want_err\" for: $*"
        fi
    fi
    return 0
}
# Exit 2 from _fatal, whose message starts with the given text.
# <message start> <stub definition> <command...>
_expect_fatal() {
    local want="$1"
    shift
    _expect_exit 2 "lint-agents: FATAL: $want" "$@"
}

_selftest_find() {
    local d="$SELFTEST_TMP/fx-find"
    _fx_agent "$d" a.md a 'l1' 'l2' 'l3'
    _fx_skill "$d" s s 'l1' 'l2' 'l3'
    # find fails: every listing, and the R7 find, must be fatal
    _expect_fatal 'listing' 'find() { return 3; }' _enum "$d/agents" -maxdepth 1
    _expect_fatal 'listing' 'find() { return 3; }' lint_agents_dir "$d"
    _expect_fatal 'listing' 'find() { return 3; }' lint_skills_dir "$d"
    _expect_fatal 'find failed' 'find() { return 3; }' check_pack "$d"
    # sort fails (find fine): the listing is fatal; the R7 find is not involved
    _expect_fatal 'listing' 'sort() { cat > /dev/null; return 2; }' _enum "$d/agents" -maxdepth 1
    _expect_fatal 'listing' 'sort() { cat > /dev/null; return 2; }' lint_agents_dir "$d"
    _expect_fatal 'listing' 'sort() { cat > /dev/null; return 2; }' lint_skills_dir "$d"
    _expect_fatal 'listing' 'sort() { cat > /dev/null; return 2; }' check_pack "$d"
    # find prints a path, THEN fails: a truncated listing is not a short listing.
    _expect_fatal 'find failed' 'find() { printf "%s\0" "$1/a.md"; return 1; }' _find_flagged "$d/agents"
    # Same, with errexit OFF in the process substitution's subshell: there the
    # `RC=` marker is the ONLY thing that reports find's status, because nothing
    # stops the subshell before it prints.
    _expect_fatal 'find failed' 'set +e; find() { printf "%s\0" "$1/a.md"; return 1; }' _find_flagged "$d/agents"
    _expect_fatal 'find failed' 'set +e; find() { return 3; }' _find_flagged "$d/agents"
    # the global floor: agents/ exists and holds nothing that was scanned
    mkdir -p "$SELFTEST_TMP/fx-empty/agents"
    _fixture_dirty
    _expect_fatal 'agents/ or skills/ exists' ':' report_pack_rules "$SELFTEST_TMP/fx-empty"
    return 0
}

# The per-file half's own mechanism: grep and awk. A check that cannot run must be
# fatal -- it used to read as "no match" / "no unknown fields" / "length 0" and the
# file PASSED. Each stub fails ONE awk program (selected by text only that program
# contains) or every grep, against a valid file, and must exit 2 with that site's
# own message.
_selftest_checks() {
    local tmp="$SELFTEST_TMP" out="$SELFTEST_TMP/lint.out" f="$SELFTEST_TMP/ck/agents/a.md"

    # `a--b` has no leading or trailing hyphen and only valid characters, so the
    # consecutive-hyphen check is the ONLY one that can flag it.
    _fx_agent "$tmp/dh" a.md a--b 'b' 'b' 'b'
    CC_OUT="$out"
    ASSERTS=$((ASSERTS + 1))
    _with_clean_counters lint_file "$tmp/dh/agents/a.md" agent
    CC_OUT=/dev/null
    _count_containing "$out" 'name must not contain consecutive hyphens'
    if [ "$COUNT" -ne 1 ] || [ "$CC_FAIL" -ne 1 ]; then
        _broken "per-file: a name of 'a--b' was not reported once as having consecutive hyphens (found $COUNT, failures $CC_FAIL)"
    fi

    _fx_agent "$tmp/ck" a.md a 'b' 'b' 'b'
    _expect_fatal 'grep failed (exit 2)' 'grep() { return 2; }' lint_file "$f" agent
    _expect_fatal 'awk failed (exit 2) reading frontmatter' \
        'awk() { case "$1" in *"END{exit !found}"*) return 2 ;; esac; command awk "$@"; }' lint_file "$f" agent
    _expect_fatal 'awk failed reading the name' \
        'awk() { case "$1" in *"print; exit"*) return 2 ;; esac; command awk "$@"; }' lint_file "$f" agent
    _expect_fatal 'awk failed measuring the description' \
        'awk() { case "$1" in *"in_desc"*) return 2 ;; esac; command awk "$@"; }' lint_file "$f" agent
    _expect_fatal 'awk failed listing the frontmatter keys' \
        'awk() { case "$1" in *"key=\$0"*) return 2 ;; esac; command awk "$@"; }' lint_file "$f" agent
    _expect_fatal 'awk failed counting the body' \
        'awk() { case "$1" in *"lines++"*) return 2 ;; esac; command awk "$@"; }' lint_file "$f" agent
    return 0
}

# Control characters in anything a file can make us print. A hostile frontmatter
# name or key, or an R4 token, could carry ESC / CR / BS and overwrite the adjacent
# "[!!]" text on a terminal or in a log. They must come out as `?`.
_selftest_sanitize() {
    local tmp="$SELFTEST_TMP" out="$SELFTEST_TMP/san.out" e hostile=0
    local esc=$'\x1b' cr=$'\r' LC_ALL=C

    _mkd "$tmp/san/agents"
    printf -- '---\nname: bad%s[2K%sXX\ndescription: d\na%sb: 1\n---\nl1\nl2\nl3\n' "$esc" "$cr" "$esc" > "$tmp/san/agents/a.md"
    _fixture_dirty
    CC_OUT="$out"
    ASSERTS=$((ASSERTS + 1))
    _with_clean_counters lint_file "$tmp/san/agents/a.md" agent
    CC_OUT=/dev/null
    _count_containing "$out" "$esc"
    hostile=$COUNT
    _count_containing "$out" "$cr"
    hostile=$((hostile + COUNT))
    if [ "$hostile" -ne 0 ] || [ "$CC_FAIL" -lt 2 ]; then
        _broken "per-file: a hostile name/key reached the output with control characters (lines=$hostile) or was not reported (failures=$CC_FAIL)"
    fi

    # pass() sanitizes too (its label is a file name, which the enumeration already
    # keeps control-character-free, so this is the only way to reach that code).
    CC_OUT="$out"
    ASSERTS=$((ASSERTS + 1))
    _with_clean_counters pass "ok${esc}X${cr}Y"
    CC_OUT=/dev/null
    _count_containing "$out" "$esc"
    hostile=$COUNT
    _count_containing "$out" "$cr"
    if [ "$((hostile + COUNT))" -ne 0 ]; then
        _broken "pass() printed a control character"
    fi

    _fx_agent "$tmp/san2" a.md a "Typo {{AGENT_PACK_RE${esc}F}}/x.md" 'l2' 'l3'
    ASSERTS=$((ASSERTS + 1))
    check_pack "$tmp/san2"
    if [ "${#FINDS[@]}" -lt 1 ]; then
        _broken "the hostile-token fixture produced no finding at all"
    fi
    for e in "${FINDS[@]+"${FINDS[@]}"}"; do
        e="${e//$'\t'/}"
        if [[ "$e" == *[[:cntrl:]]* ]]; then
            _broken "a finding carries a raw control character: ${e//[[:cntrl:]]/?}"
        fi
    done
    return 0
}

# The result cache must never serve a stale hit.
_selftest_cache() {
    local d="$SELFTEST_TMP/cache"

    _fx_agent "$d" a.md a 'l1' 'l2' 'l3'
    _expect_silent "$d"                                  # computed, now cached
    _fx_agent "$d" b.md b 'Dangling: {{AGENT_PACK_REFS}}/gone.md' 'l2' 'l3'
    _expect_fires "$d" R1 agents/b.md:5                  # a stale hit would still say silent
    rm -f "$d/agents/b.md"
    _fixture_dirty                                       # a RAW write must announce itself
    _expect_silent "$d"
    # A direct check_pack on ANOTHER root between two cached calls moves what the
    # globals describe; the cache must notice (it asks check_pack's LAST_ROOT).
    check_pack "$SELFTEST_TMP/r1"                        # has an R1 finding
    _expect_silent "$d"
    return 0
}

# _expect_exit is itself a checker, and a checker that cannot fail is the failure
# this whole script exists to prevent: prove it flags a wrong exit status and a
# message that is not on stderr. Each probe runs its own copy in a subshell and the
# SELFTEST line it prints is what is looked for.
_selftest_meta() {
    local out
    ASSERTS=$((ASSERTS + 1))
    out="$( ( _expect_exit 2 'NO SUCH MESSAGE' 'f() { echo other >&2; exit 2; }' f ) )"
    case "$out" in
        *'stderr lacks'*) ;;
        *) _broken "_expect_exit accepted an exit whose stderr lacked the expected message" ;;
    esac
    ASSERTS=$((ASSERTS + 1))
    out="$( ( _expect_exit 2 '' ':' true ) )"
    case "$out" in
        *'expected exit 2, got 0'*) ;;
        *) _broken "_expect_exit accepted a wrong exit status" ;;
    esac
    return 0
}

# Every rule has a title, and rule_title says so for an unknown id.
_selftest_rules() {
    local r t
    for r in $RULES; do
        ASSERTS=$((ASSERTS + 1))
        t="$(rule_title "$r")"
        if [ -z "$t" ] || [ "$t" = "(unlisted rule)" ]; then
            _broken "rule $r in RULES has no title in RULE_TABLE (got \"$t\")"
        fi
    done
    ASSERTS=$((ASSERTS + 1))
    if [ "$(rule_title R99)" != "(unlisted rule)" ]; then
        _broken "rule_title invented a title for an id that is not in RULE_TABLE"
    fi
    return 0
}

# The real phase: findings exit 1, a crash exits 2, an empty tree exits 2.
_selftest_phase() {
    local d="$SELFTEST_TMP/ph" e="$SELFTEST_TMP/ph-find" fl="$SELFTEST_TMP/ph-fl" fl2="$SELFTEST_TMP/ph-fl2"

    # Deliberately tiny roots: a full phase over agents and skills costs several
    # seconds of process spawns, and each case needs only one branch of it.
    _fx_file "$d" references/name.md 'x'    # an orphan: a WARNING, still exit 0
    _expect_exit 0 '' ':' _guarded _real_phase "$d"
    # findings are exit 1 -- NOT 2: the guard must not eat a normal findings exit
    _fx_agent "$e" a.md a 'Dangling: {{AGENT_PACK_REFS}}/gone.md' 'l2' 'l3'
    _expect_exit 1 '' ':' _guarded _real_phase "$e"
    # a crash anywhere in the phase is exit 2 with the guard's message
    _expect_exit 2 'lint-agents: FATAL: unexpected error' 'lint_agents_dir() { false; }' _guarded _real_phase "$e"
    # the per-tree floor: a real directory that the per-file half linted NOTHING
    # from (here agents/ is empty; skills/ holds only a non-SKILL.md file, which the
    # pointer scan still counts, so the global SCANNED floor cannot see it)
    _mkd "$fl/agents"
    _fixture_dirty
    _expect_fatal 'agents/ exists but the per-file half' ':' _guarded _real_phase "$fl"
    _fx_file "$fl2" skills/only/notes.md 'a skills directory with no SKILL.md'
    _expect_fatal 'skills/ exists but the per-file half' ':' _guarded _real_phase "$fl2"
    return 0
}

# The report layer: check_pack being right is not enough. A finding can also
# vanish between check_pack and the printed [!!] lines, in which case the script
# prints [ok] and exits 0.
_selftest_report() {
    local ra="$SELFTEST_TMP/report-all" rep="$SELFTEST_TMP/report.out" rc nfind

    _fx_file "$ra" references/name.md 'x'
    _fx_agent "$ra" x.md x \
        'Dangling: {{AGENT_PACK_REFS}}/missing.md' \
        'Bare: references/x.md' \
        'Plugin: ${CLAUDE_PLUGIN_ROOT}/y' \
        'Typo: {{AGENT_PACK_REF}}/name.md' \
        'Valid so R5 stays quiet: {{AGENT_PACK_REFS}}/name.md'
    # Drive report_pack_rules itself, into a file (never a subshell, so the
    # counters survive), and count what it printed against what check_pack found.
    CC_OUT="$rep"
    ASSERTS=$((ASSERTS + 1))
    _with_clean_counters report_pack_rules "$ra"
    CC_OUT=/dev/null
    nfind="${#FINDS[@]}"
    _count_starting "$rep" '  [!!]'
    if [ "$nfind" -ne 4 ] || [ "$COUNT" -ne "$nfind" ] || [ "$CC_FAIL" -ne "$nfind" ]; then
        _broken "report layer: check_pack produced $nfind finding(s) (expected 4), printed $COUNT [!!] line(s), counted $CC_FAIL failure(s)"
    fi
    # R1-R4 each fired once, so only the rules in $RULES that did NOT fire (R7)
    # and R5 may print an [ok] line.
    _count_starting "$rep" '  [ok]'
    if [ "$COUNT" -ne 2 ] || [ "$CC_PASS" -ne 2 ]; then
        _broken "report layer: printed $COUNT [ok] line(s) / counted $CC_PASS pass(es), expected exactly 2 (R7 and R5)"
    fi
    # A finding under a rule name the report loop does not list must still print.
    FINDS=("R9"$'\t'"x.md:1"$'\t'"synthetic finding under an unlisted rule")
    CC_OUT="$rep"
    ASSERTS=$((ASSERTS + 1))
    _with_clean_counters _report_findings
    CC_OUT=/dev/null
    _count_starting "$rep" '  [!!] x.md:1  -- R9:'
    if [ "$COUNT" -ne 1 ] || [ "$CC_FAIL" -ne 1 ]; then
        _broken "report layer dropped a finding under an unlisted rule name (printed $COUNT, counted $CC_FAIL failure(s))"
    fi
    # The count guard itself: with fail() neutered in a subshell the printed count
    # cannot match, so the layer must refuse with exit 2 rather than go on.
    FINDS=("R1"$'\t'"x.md:1"$'\t'"synthetic")
    ASSERTS=$((ASSERTS + 1))
    set +e
    (
        fail() { :; }
        _report_findings
    ) > /dev/null 2>&1
    rc=$?
    set -e
    if [ "$rc" -ne 2 ]; then
        _broken "report layer count guard did not exit 2 when findings went unprinted (rc=$rc)"
    fi
    FINDS=()
    return 0
}

selftest() {
    local tmp sp="$PASS" sf="$FAIL" sw="$WARN"
    tmp="$(mktemp -d)"
    # An EXIT trap, not RETURN: the failure path below calls `exit 2`, and a
    # RETURN trap does not fire on exit. The trap reads a GLOBAL because `tmp`
    # is out of scope by the time an EXIT trap runs (and `set -u` would abort).
    SELFTEST_TMP="$tmp"
    trap 'rm -rf "$SELFTEST_TMP"' EXIT

    _selftest_good
    _selftest_r1
    _selftest_r2
    _selftest_r3
    _selftest_r4
    _selftest_r5
    _selftest_r6
    _selftest_r7
    _selftest_report
    _selftest_meta
    _selftest_rules
    _selftest_cache
    _selftest_checks
    _selftest_sanitize
    _selftest_phase

    # The self-test must leave the real counters exactly as it found them, or the
    # summary would count fixtures.
    ASSERTS=$((ASSERTS + 1))
    if [ "$PASS" -ne "$sp" ] || [ "$FAIL" -ne "$sf" ] || [ "$WARN" -ne "$sw" ]; then
        _broken "the self-test leaked into the real counters (pass $sp->$PASS, fail $sf->$FAIL, warn $sw->$WARN)"
        PASS="$sp"
        FAIL="$sf"
        WARN="$sw"
    fi

    rm -rf "$tmp"
    trap - EXIT

    if [ "$BROKEN" -ne 0 ]; then
        echo
        echo "SELF-TEST FAILED -- the checker is broken, so its verdict on this repo means nothing."
        echo "Fix the rules before trusting any result. Exiting 2 to distinguish this from a finding."
        exit 2
    fi
    echo "  [ok] self-test: $ASSERTS assertions -- each of $RULES and R5 fires at the exact file:line on a"
    echo "       violation, stays silent on realistic descriptive prose, and empty/absent trees pass"
    return 0
}

echo "Claude Agent Pack -- Lint Check"
echo ""

echo "-- Self-test"
# Run in a subshell with errexit ON, so that a crash INSIDE the self-test (a
# listing that splits a name, an unreadable fixture) exits 2, "the checker is
# broken", and not 1, which a caller reads as "a finding". Its own `exit 2` passes
# through. `set +e` around the call only keeps the outer shell alive to read $?.
set +e
( set -e; selftest )
selftest_rc=$?
set -e
if [ "$selftest_rc" -ne 0 ]; then
    if [ "$selftest_rc" -ne 2 ]; then
        echo
        echo "SELF-TEST ABORTED (exit $selftest_rc) -- the checker crashed before it could report."
        echo "Its verdict on this repo means nothing. Exiting 2 to distinguish this from a finding."
    fi
    exit 2
fi
echo ""

# The real scan. _real_phase EXITS (0 clean, 1 findings) and _guarded turns any
# other abnormal exit into 2. It is called PLAIN, never as `_guarded ... || x`: a
# command list disables the ERR trap for everything inside it.
_guarded _real_phase "$PACK_DIR"
