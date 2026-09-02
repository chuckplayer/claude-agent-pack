#!/usr/bin/env bash
set -euo pipefail

# Fail if a file under memory/ does not conform to the ONE frontmatter dialect
# that docs/MEMORY-WRITING.md mandates: fenced lowercase YAML, seven required
# keys.
#
#   bash scripts/lint-memory.sh [dir]     # dir defaults to memory/
#
# EXIT CONTRACT -- three-way, mirroring scripts/lint-identifiers.sh:
#   0  every file conforms (or there is nothing to check)
#   1  a finding: at least one file does not conform
#   2  the SELF-TEST failed, so this script's verdict means nothing
#
# TRIGGER: any changeset touching memory/. The coordinating session runs it, on
# the lint-plans.sh model. NO merge-reviewer gate enforces it -- there is no gate
# 2d. So an unrun check here is simply unrun: say so, do not imply it passed.
#
# ---------------------------------------------------------------------------
# WHAT THIS CHECKS, AND -- MORE IMPORTANTLY -- WHAT IT DOES NOT
#
# DIALECT CONFORMANCE ONLY. It has no opinion on whether a memory file is true,
# current, or well written. Four non-checks are deliberate and each would be a
# bug if "fixed":
#
#   1. AN UNRECOGNISED KEY IS NOT A FINDING. The seven required keys are a
#      MINIMUM, not a closed schema. A memory file records facts; a schema that
#      rejected unlisted keys would force DELETING facts to satisfy a format.
#      `discovered:`, `resolved:`, `last-updated:`, `verified-at-commit:` are
#      sanctioned by name in MEMORY-WRITING.md, and CLAUDE.md's Engineer write
#      permission section *mandates* `discovered:`.
#
#   2. THE `type:` VALUE VOCABULARY IS NOT ENFORCED. Seven values are in use,
#      including `context` and `platform quirk`. Closing the list would force
#      rewriting two files' `type:` -- and rewriting a recorded fact is not a
#      formatting change. Presence of the key is required; its value is free.
#
#   3. `superseded-by:` IS PRESENCE-CHECKED, NEVER RESOLVED. Two files
#      legitimately carry prose there ("fixed in place 2026-07-30; see Revisit
#      trigger" and "wiki family removed 2026-05-16; ..."). A checker that
#      required a real filename would fail both.
#
#   4. `description:` IS OPTIONAL. Six files carry one; no new file needs one.
#      Requiring it would add a key the old spec never asked for, breaking the
#      rule that a corpus satisfying the old spec's key requirements still
#      passes here.
#
# ---------------------------------------------------------------------------
# WHY THERE IS ALMOST NO grep IN THE RULE LOGIC
#
# Two active memory files in this repo record shell hazards that have already
# shipped as bugs here, and both are avoided by construction rather than worked
# around:
#
#   memory/context/2026-08-04-grep-iF-aborts-on-this-machine.md
#     `grep -iF` SIGABRTs on this machine (exit 134, empty output), which is
#     indistinguishable from "no matches" to any caller writing `|| true`.
#
#   memory/context/2026-08-05-pipefail-plus-short-circuiting-grep-returns-141.md
#     under `set -o pipefail`, `producer | grep -q` returns 141 when the match
#     is found EARLY, because the producer dies of SIGPIPE. Size-dependent, so
#     it passes every small fixture and breaks on real data.
#
# The rule matching here therefore uses bash's own `[[ =~ ]]` and `case`, which
# fork no process, have no -F flag to abort, and cannot be cut by a pipe. Where a
# variable must reach an external matcher anyway, it goes in via a HERESTRING,
# never a pipe. A `grep_strict` helper is kept for any FUTURE external match: it
# treats exit >=2 as an ERROR rather than as "no matches". Stated honestly:
# nothing calls it today and the self-test does NOT exercise it, so it is
# unproven code rather than a verified guarantee. Whatever starts calling it must
# add a self-test that drives it with a deliberately failing command.

cd "$(dirname "$0")/.."

ROOT="${1:-memory}"

REQUIRED_KEYS=(date type status superseded-by scope overrides-convention related-to)

FINDINGS=0
FILES=0

# NEVER let a grep failure look like "no matches": 0 = matched, 1 = no match,
# >=2 = ERROR. A `|| true` collapses all three into "clean", which is how the
# first draft of lint-identifiers.sh printed a pass while core-dumping.
grep_strict() {
    local out rc
    set +e
    out=$( "$@" ); rc=$?
    set -e
    if [ "$rc" -ge 2 ]; then
        echo "  [!!] grep FAILED (exit $rc) -- not 'no matches'. Command: $*" >&2
        echo "       Refusing to report a clean result on a broken mechanism." >&2
        exit 2
    fi
    printf '%s' "$out"
}

# ---------------------------------------------------------------------------
# check_file <path>
#
# Prints one `RULE<TAB>detail` line per finding and nothing at all for a
# conforming file. This is THE predicate: the self-test drives this same
# function against fixtures, so a rule cannot pass its test and then behave
# differently on the repo.
# ---------------------------------------------------------------------------
check_file() {
    local f="$1"
    local -a lines=()
    local line

    # Strip a trailing CR so a CRLF checkout is not reported as a broken fence.
    while IFS= read -r line || [ -n "$line" ]; do
        lines+=("${line%$'\r'}")
    done < "$f"

    if [ "${#lines[@]}" -eq 0 ]; then
        printf 'empty-file\tfile is empty; expected fenced frontmatter\n'
        return 0
    fi

    # R1 -- the opening fence must BE line 1. This one rule rejects both retired
    # unfenced dialects (bold `**Date:**` keys, and bare lowercase keys) without
    # needing to recognise either of them specifically.
    if [ "${lines[0]}" != "---" ]; then
        printf 'no-open-fence\tline 1 is not "---" (found: %s)\n' "$(printf '%.60s' "${lines[0]}")"
        return 0   # nothing further is meaningful without a fence
    fi

    # R2 -- and it must be closed.
    local close=-1 i
    for (( i = 1; i < ${#lines[@]}; i++ )); do
        if [ "${lines[$i]}" = "---" ]; then close=$i; break; fi
    done
    if [ "$close" -lt 0 ]; then
        printf 'unclosed-fence\topening "---" is never closed\n'
        return 0
    fi

    # Walk the frontmatter region once, collecting top-level keys.
    local -a top_keys=()
    local key
    for (( i = 1; i < close; i++ )); do
        line="${lines[$i]}"
        [[ -z "${line// /}" ]] && continue

        # R4 -- a bold key inside the fence is the retired dialect leaking in.
        if [[ "$line" =~ ^\*\*[A-Za-z] ]]; then
            printf 'bold-key\tline %d uses the retired bold dialect: %s\n' \
                "$((i + 1))" "$(printf '%.60s' "$line")"
            continue
        fi

        if [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_-]*):(.*)$ ]]; then
            key="${BASH_REMATCH[1]}"
            local val="${BASH_REMATCH[2]}"

            # R5 -- lowercase, hyphenated. Catches `Date:` / `Superseded-By:`.
            if [[ "$key" =~ [A-Z_] ]]; then
                printf 'key-not-lowercase\tline %d key "%s" must be lowercase and hyphenated\n' \
                    "$((i + 1))" "$key"
            fi

            local lkey="${key,,}"

            # R6 -- `name:` was dropped; it duplicated the filename.
            if [ "$lkey" = "name" ]; then
                printf 'name-key\tline %d carries the dropped "name:" key\n' "$((i + 1))"
            fi

            # R7 -- the retired nested dialect is recognised by its `metadata:`
            # map, which is a key with an empty value followed by indented keys.
            if [ "$lkey" = "metadata" ] && [ -z "${val// /}" ]; then
                printf 'nested-metadata\tline %d nests frontmatter under "metadata:"; flatten it\n' \
                    "$((i + 1))"
            fi

            # R9 -- `status:` must hold one of the four documented values.
            # This is the ONE value vocabulary this script closes. `type:` is
            # deliberately left open (non-check 2) because the corpus holds seven
            # type values and closing it would mean rewriting a fact; `status:` is
            # different -- the pack's skip filters branch on it, so an undocumented
            # value silently changes which files agents read. Kept in sync with
            # docs/MEMORY-WRITING.md's four-value table.
            #
            # `resolved` is accepted here and is NOT in any skip filter, on purpose.
            # See that table's note: a resolved file can still carry live guidance.
            if [ "$lkey" = "status" ]; then
                case "${val# }" in
                    active|superseded|archived|resolved) ;;
                    *) printf 'status-value\tline %d status "%s" is not one of active|superseded|archived|resolved\n' \
                           "$((i + 1))" "$(printf '%.40s' "${val# }")" ;;
                esac
            fi

            top_keys+=("$lkey")

            # R8 -- a required key must carry a value. `n/a` is the filler.
            if [ -z "${val// /}" ] && _is_required "$lkey" && [ "$lkey" != "metadata" ]; then
                printf 'empty-value\tline %d key "%s" has no value; write n/a\n' "$((i + 1))" "$key"
            fi
            continue
        fi

        # NON-CHECK 5 -- an INDENTED key line is never a finding on its own.
        # An indented line is usually the legitimate continuation of a
        # soft-wrapped scalar, and five files rely on that. Matching a bare
        # `indented + colon` would flag any wrapped prose containing a colon,
        # which is the prose-vs-structure mistake lint-plans.sh made twice.
        #
        # The retired nested dialect's indented children are not counted here
        # either, deliberately: R7 above already reports `nested-metadata` on the
        # parent `metadata:` line, so the file is flagged before this point is
        # reached. Counting the children would add N duplicate lines per nested
        # file and no detection power. An earlier draft kept an `indent_key`
        # counter here that nothing read -- removed rather than promoted to a
        # finding, for that reason.
    done

    # R3 -- every required key present. Exactly the seven; no more. A corpus
    # written to the OLD spec's key requirements therefore still passes, because
    # the old spec asked for these same seven names.
    local want have found
    for want in "${REQUIRED_KEYS[@]}"; do
        found=0
        for have in "${top_keys[@]:-}"; do
            [ "$have" = "$want" ] && { found=1; break; }
        done
        [ "$found" -eq 0 ] && printf 'missing-key\trequired key "%s:" is absent\n' "$want"
    done

    # ALWAYS return 0. The findings are the stdout, never the exit status. A
    # short-circuiting `&&` as the last statement returns 1 on a CLEAN file, and
    # under `set -e` that aborted the whole script inside `out="$(check_file ..)"`
    # -- printing nothing and exiting 1, i.e. a clean corpus reported as a
    # failure with no explanation. Same family as every other "the checker's own
    # mechanism failed silently" bug this repo has shipped.
    return 0
}

_is_required() {
    local k="$1" r
    for r in "${REQUIRED_KEYS[@]}"; do
        [ "$k" = "$r" ] && return 0
    done
    return 1
}

# ---------------------------------------------------------------------------
# scan_dir <dir> -- run the predicate over every .md beneath dir.
# Takes a directory so the self-test can point it at fixtures and at an EMPTY
# directory. An absent or empty corpus is a PASS: a freshly scaffolded project
# must not be born failing.
# ---------------------------------------------------------------------------
scan_dir() {
    local dir="$1" quiet="${2:-}"
    local f out n=0 bad=0

    if [ ! -d "$dir" ]; then
        [ -z "$quiet" ] && echo "  [--] $dir/ does not exist -- nothing to check."
        return 0
    fi

    # `find | while` would put the loop in a subshell and lose the counters, so
    # read the list into an array first. No pipe into a short-circuiting matcher
    # anywhere in here.
    local -a list=()
    while IFS= read -r f; do
        [ -n "$f" ] && list+=("$f")
    done < <(find "$dir" -type f -name '*.md' | sort)

    if [ "${#list[@]}" -eq 0 ]; then
        [ -z "$quiet" ] && echo "  [--] no .md files under $dir/ -- nothing to check."
        return 0
    fi

    for f in "${list[@]}"; do
        n=$((n + 1))
        out="$(check_file "$f")"
        if [ -n "$out" ]; then
            bad=$((bad + 1))
            [ -z "$quiet" ] && {
                echo "  [!!] $f"
                while IFS=$'\t' read -r rule detail; do
                    [ -n "$rule" ] && printf '         %-20s %s\n' "$rule" "$detail"
                done <<< "$out"
            }
        fi
    done

    FILES="$n"
    FINDINGS="$bad"
    return 0
}

# ---------------------------------------------------------------------------
# SELF-TEST -- two-sided, and it drives check_file itself.
#
# A checker that silently matches nothing reports a clean corpus. Every rule must
# FIRE on a violating fixture AND STAY SILENT on a compliant one. Exit 2 on
# failure, distinct from a finding's exit 1, because a broken checker's verdict on
# the real corpus is worthless rather than merely wrong.
# ---------------------------------------------------------------------------
selftest() {
    local tmp broken=0 out
    tmp="$(mktemp -d)"
    # shellcheck disable=SC2064
    trap "rm -rf '$tmp'" RETURN

    mkdir -p "$tmp/good" "$tmp/bad" "$tmp/empty"

    # --- COMPLIANT fixtures: must produce ZERO findings ---------------------

    # Everything the dialect allows at once: four sanctioned extras, an
    # UNRECOGNISED extra, an optional description, a `platform quirk` type, a
    # `resolved` status, prose in superseded-by, a soft-wrapped scalar with an
    # indented continuation, and a single-quoted value containing " #".
    cat > "$tmp/good/kitchen-sink.md" <<'EOF'
---
date: 2026-08-05
type: platform quirk
status: resolved
superseded-by: fixed in place 2026-07-30; see Revisit trigger
scope: any code path that parses a string printed by `az` on this machine — and
  per the section at the end, any checker whose own source contains a literal
overrides-convention: no
related-to: 'some-file.md (its ## Challenge section holds the narrative)'
discovered: 2026-08-05
resolved: 2026-08-06
last-updated: 2026-08-06
verified-at-commit: b7f59f2
description: an optional one-liner
some-future-key: must not be a finding
---

## Summary
EOF

    # The OLD spec's key requirements, in the new fence and nothing more. This is
    # the "old spec is a subset" guarantee: no extra key is required here.
    cat > "$tmp/good/old-spec-keys.md" <<'EOF'
---
date: 2026-07-01
type: pattern
status: active
superseded-by: n/a
scope: global
overrides-convention: no
related-to: n/a
---

body
EOF

    # --- VIOLATING fixtures: each must fire its named rule -------------------

    cat > "$tmp/bad/bold-unfenced.md" <<'EOF'
**Date:** 2026-08-04
**Type:** constraint
**Status:** active
**Superseded-by:** n/a
**Scope:** global
**Overrides-convention:** no
**Related-to:** n/a

body
EOF

    cat > "$tmp/bad/bare-unfenced.md" <<'EOF'
type: known-issue
status: active
discovered: 2026-08-03
scope: skills/devops-azure/SKILL.md

body
EOF

    cat > "$tmp/bad/unclosed.md" <<'EOF'
---
date: 2026-08-04
type: constraint
status: active
superseded-by: n/a
scope: global
overrides-convention: no
related-to: n/a

body
EOF

    cat > "$tmp/bad/missing-key.md" <<'EOF'
---
date: 2026-08-04
type: constraint
status: active
superseded-by: n/a
scope: global
overrides-convention: no
---

body
EOF

    # An UNDOCUMENTED status value. Every other key in this fixture is valid, so
    # it isolates R9: if the status rule stops firing, nothing else here catches
    # it. This fixture exists because the rule was missing from the first cut of
    # this script entirely -- the corpus passed, and a `status: pending` file
    # passed with it, while the plan's acceptance bar claimed the check was
    # proven. A rule with no fixture is indistinguishable from a rule that is
    # absent.
    cat > "$tmp/bad/bad-status.md" <<'EOF'
---
date: 2026-08-04
type: constraint
status: pending
superseded-by: n/a
scope: global
overrides-convention: no
related-to: n/a
---

body
EOF

    cat > "$tmp/bad/uppercase-key.md" <<'EOF'
---
Date: 2026-08-04
type: constraint
status: active
superseded-by: n/a
scope: global
overrides-convention: no
related-to: n/a
---

body
EOF

    cat > "$tmp/bad/nested-metadata.md" <<'EOF'
---
name: some-known-issue
description: a nested-dialect file
metadata:
  type: known-issue
  status: active
  discovered: 2026-07-10
---

body
EOF

    cat > "$tmp/bad/empty-value.md" <<'EOF'
---
date: 2026-08-04
type: constraint
status: active
superseded-by: n/a
scope:
overrides-convention: no
related-to: n/a
---

body
EOF

    cat > "$tmp/bad/bold-inside-fence.md" <<'EOF'
---
date: 2026-08-04
**Type:** constraint
status: active
superseded-by: n/a
scope: global
overrides-convention: no
related-to: n/a
type: constraint
---

body
EOF

    # --- assert: compliant fixtures are silent ------------------------------
    local g
    for g in "$tmp"/good/*.md; do
        out="$(check_file "$g")"
        if [ -n "$out" ]; then
            echo "  [SELFTEST] COMPLIANT fixture $(basename "$g") produced findings (false positive):"
            printf '%s\n' "$out" | sed 's/^/             /'
            broken=1
        fi
    done

    # --- assert: each violating fixture fires its rule ----------------------
    # Herestring, never a pipe: under `set -o pipefail`, `printf | grep -q`
    # returns 141 when the match is found early, because printf dies of SIGPIPE.
    _fires() {  # <fixture> <expected-rule>
        local file="$tmp/bad/$1" rule="$2" o
        o="$(check_file "$file")"
        if ! grep -qE "^${rule}"$'\t' <<< "$o"; then
            echo "  [SELFTEST] rule '$rule' did NOT fire on $1"
            [ -n "$o" ] && printf '%s\n' "$o" | sed 's/^/             got: /'
            [ -z "$o" ] && echo "             got: (no findings at all)"
            broken=1
        fi
    }

    _fires bold-unfenced.md      'no-open-fence'
    _fires bare-unfenced.md      'no-open-fence'
    _fires unclosed.md           'unclosed-fence'
    _fires missing-key.md        'missing-key'
    _fires uppercase-key.md      'key-not-lowercase'
    _fires nested-metadata.md    'nested-metadata'
    _fires nested-metadata.md    'name-key'
    _fires empty-value.md        'empty-value'
    _fires bold-inside-fence.md  'bold-key'
    _fires bad-status.md         'status-value'

    # --- assert: an EMPTY and an ABSENT corpus both pass ---------------------
    # A freshly scaffolded project has memory/ subdirectories and no files yet.
    # It must not be born failing. setup-project.sh writes no stub, by design.
    #
    # scan_dir ALWAYS returns 0 -- findings travel in $FINDINGS, never in its exit
    # status (see its closing comment). So `if ! scan_dir ...` could never fire,
    # and is deliberately not written here: the globals ARE the assertion.
    #
    # Seed a sentinel before each call. scan_dir's early-return paths (absent dir,
    # zero .md files) leave the globals UNTOUCHED, so asserting against their
    # initial 0 would pass without observing anything scan_dir did.
    FINDINGS=-1; FILES=-1
    scan_dir "$tmp/empty" quiet
    if [ "$FINDINGS" -gt 0 ]; then
        echo "  [SELFTEST] an empty corpus produced $FINDINGS finding(s)"; broken=1
    fi

    FINDINGS=-1; FILES=-1
    scan_dir "$tmp/nonexistent-dir" quiet
    if [ "$FINDINGS" -gt 0 ]; then
        echo "  [SELFTEST] an absent corpus produced $FINDINGS finding(s)"; broken=1
    fi

    # --- MECHANISM check, not a rule check ----------------------------------
    # Prove the external matchers the assertions above depend on actually run on
    # THIS machine rather than assuming they do. Two properties, and only two:
    #   (1) `grep -qE` against a herestring matches. `_fires` is built on it, so
    #       if this breaks, every rule assertion silently stops firing.
    #   (2) a >64KiB herestring into `grep -qF` returns 0, not 141 -- the SIGPIPE
    #       class recorded in
    #       memory/context/2026-08-05-pipefail-plus-short-circuiting-grep-returns-141.md,
    #       which passes every small fixture and breaks on real data.
    # `grep -iF` SIGABRTs here, so nothing in this script pairs -i with -F.
    #
    # What this does NOT prove: the two calls below are raw `grep -qE` /
    # `grep -qF`, so nothing here exercises `grep_strict` or shows that it treats
    # exit >=2 as an error. It has no caller yet -- see the header note.
    if ! grep -qE '^x' <<< "$(printf 'x\n')"; then
        echo "  [SELFTEST] the herestring grep used by _fires does not work here"; broken=1
    fi
    local big rc
    big="$(printf 'needle\n%s\n' "$(head -c 200000 /dev/zero | tr '\0' 'y')")"
    set +e
    grep -qF 'needle' <<< "$big"; rc=$?
    set -e
    if [ "$rc" -ne 0 ]; then
        echo "  [SELFTEST] a >64KiB herestring into grep -q returned $rc, not 0 (SIGPIPE class)"
        broken=1
    fi

    if [ "$broken" -ne 0 ]; then
        echo
        echo "SELF-TEST FAILED -- the checker is broken, so its verdict on this corpus means nothing."
        echo "Fix the rules before trusting any result. Exiting 2 to distinguish this from a finding."
        exit 2
    fi
    echo "  [ok] self-test: 10 rule assertions fire on violations, 2 compliant fixtures stay silent,"
    echo "       empty and absent corpora pass, and the herestring matcher works on this machine"
}

echo "lint-memory -- one frontmatter dialect, per docs/MEMORY-WRITING.md"
echo
echo "Self-test:"
selftest
FINDINGS=0
FILES=0
echo
echo "Corpus ($ROOT/):"
scan_dir "$ROOT"

echo
echo "----"
if [ "$FINDINGS" -gt 0 ]; then
    echo "  $((FILES - FINDINGS))/$FILES conform, $FINDINGS need fixing"
    echo "  See docs/MEMORY-WRITING.md for the dialect."
    exit 1
fi
echo "  $FILES file(s) checked, all conform"
exit 0
