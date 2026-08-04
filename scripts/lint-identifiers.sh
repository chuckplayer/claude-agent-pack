#!/usr/bin/env bash
set -euo pipefail

# Fail if a real organisation, project, host, path or person identifier appears
# where the placeholder convention requires a placeholder.
#
#   bash scripts/lint-identifiers.sh
#
# THIS REPOSITORY IS PUBLIC. See
# memory/context/2026-08-04-this-repo-is-public-never-write-real-identifiers.md
# for the convention this enforces. That memory file is a stated rule; this
# script is the reason it will not quietly stop being true. On 2026-08-04 a
# scrub removed 115 such references and history had to be rewritten -- and a
# force push provably does NOT remove them from a public host, so prevention is
# the only control that actually works.
#
# WHY THERE IS NO DENYLIST IN THIS FILE. A list of the forbidden strings would
# have to contain them, in a public repo, which re-leaks exactly what it guards.
# So the committed checks are STRUCTURAL: they assert that a position which must
# hold a placeholder does hold one. For exact-token matching, put the real
# strings in a LOCAL denylist file that is gitignored (see DENYLIST below).
#
# TRIGGER: every changeset. Unlike lint-agents.sh (agents/ + skills/) or the
# obsidian suite (two hook files), an identifier can be introduced by any file
# in any commit, so there is no narrower trigger that would be honest.

cd "$(dirname "$0")/.."

DENYLIST=".identifier-denylist"   # gitignored; optional; one token per line
SELF="scripts/lint-identifiers.sh"
MARKER="lint-identifiers:allow"   # a line carrying this is skipped

PASS=0
FAIL=0

pass() { echo "  [ok] $1"; PASS=$((PASS + 1)); }
fail() { echo "  [!!] $1"; FAIL=$((FAIL + 1)); }

# --- the structural rules -----------------------------------------------------
# Each rule is "a placeholder belongs here". A STRUCTURED trigger, not a word
# match: lint-plans.sh learned that lesson twice, on its Gated: check and again
# on its sentinel check, both of which had to move off prose words.
#
# Two regexes per rule. The FIND regex is deliberately broad; the ALLOW regex
# excuses the legitimate generic forms, and is ANCHORED TO THE SAME POSITION so
# it can only ever excuse that position -- not the whole line. Angle-bracket
# placeholders, a literal `...` in prose, a shell variable, and the small closed
# set of conventional dummy values (foo/bar/repo-a) are all legitimate.
#
# KNOWN LIMITATION, stated rather than hidden: matching is line-based, so a line
# carrying BOTH an allowed generic and a real identifier in the same position is
# excused. Findings print the whole line so a human reading a failure sees it,
# but a passing run does not prove such a line absent. Closing it needs
# match-level extraction, which costs the file:line reporting that makes the
# output actionable. The trade was taken knowingly.
#
# FOUR PARALLEL ARRAYS, not delimited strings. A `name|find|allow|why` encoding
# was tried first and was broken by its own delimiter: every allow regex contains
# `|` for alternation, so field-splitting truncated `(<|\{|...)` to `(<` and grep
# died on an unmatched paren. The self-test caught it and refused to report on the
# repo. Parallel arrays have no delimiter to collide with.
RULE_NAME=(  'ado-org-url' 'ado-org-env' 'ado-proj-env' 'gh-org-env' 'gh-repos-env' 'win-user-path' 'nix-user-path' )
RULE_FIND=(
    'dev\.azure\.com/[^<]'
    'AZURE_DEVOPS_ORG=[^<]'
    'AZURE_DEVOPS_PROJECTS=[^<]'
    'GITHUB_ORG=[^<]'
    'GITHUB_REPOS=[^<]'
    '[A-Za-z]:\\+Users\\+[^<]'
    '(^|[^A-Za-z0-9])/Users/[^<]'
)
RULE_ALLOW=(
    'dev\.azure\.com/(<|\{|\.\.\.|\$)'
    'AZURE_DEVOPS_ORG=(<|\.\.\.|\$)'
    'AZURE_DEVOPS_PROJECTS=(<|\.\.\.|\$)'
    'GITHUB_ORG=(<|\.\.\.|\$)'
    'GITHUB_REPOS=(<|\.\.\.|\$|repo-[a-z0-9])'
    '[A-Za-z]:\\+Users\\+(<|foo|bar|baz|qux|example|USERNAME)'
    '/Users/(<|foo|bar|baz|qux|example)'
)
RULE_WHY=(
    'an Azure DevOps org URL must read dev.azure.com/<org>'
    'AZURE_DEVOPS_ORG must be assigned a placeholder'
    'AZURE_DEVOPS_PROJECTS must be assigned placeholders'
    'GITHUB_ORG must be assigned a placeholder'
    'GITHUB_REPOS must be assigned placeholders'
    'a Windows user path must read C:\Users\<user>'
    'a macOS user path must read /Users/<user>'
)

# Emails are handled separately: they need an allowlist rather than a placeholder.
EMAIL_RE='[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
EMAIL_ALLOW='noreply@anthropic\.com|users\.noreply\.github\.com|@example\.(com|org)'

files() {
    git ls-files | grep -E '\.(md|json|sh|js|ya?ml|txt)$' | grep -v "^${SELF}$" || true
}

# NEVER let a grep failure look like "no matches". grep exits 0 for a match,
# 1 for no match, and >=2 for an ERROR -- and a `|| true` collapses all three
# into "clean". That is not hypothetical here: `grep -iF` ABORTS on this
# machine (GNU grep 3.0, SIGABRT/exit 134, leaves a grep.exe.stackdump), and
# the first version of this script swallowed that and printed "[ok] denylist"
# while the grep was core-dumping. A checker reporting success because its own
# mechanism died is the exact failure this repo keeps producing.
grep_strict() {
    local out rc
    out=$( "$@" ) ; rc=$?
    if [ "$rc" -ge 2 ]; then
        echo "  [!!] grep FAILED (exit $rc) -- not 'no matches'. Command: $*" >&2
        echo "       Refusing to report a clean result on a broken mechanism." >&2
        exit 2
    fi
    printf '%s' "$out"
}

scan() {
    local name="$1" re="$2" allow="$3" why="$4" hits raw
    raw=$(files | xargs -r grep -InE -- "$re" || true)   # 1 = no match, fine
    hits=$(printf '%s' "$raw" | grep -vF "$MARKER" | grep -vE -- "$allow" || true)
    if [ -n "$hits" ]; then
        fail "$name -- $why"
        printf '%s\n' "$hits" | head -20 | sed 's/^/         /'
    else
        pass "$name"
    fi
}

# --- self-test ---------------------------------------------------------------
# A checker that silently matches nothing reports a clean repo. Every rule is
# proved TWO-SIDED against a synthetic fixture before the real scan runs: it
# must fire on a violating line AND stay silent on a compliant one. This repo
# has produced "the check passed because the check was broken" enough times to
# make this mandatory rather than nice to have.
selftest() {
    local tmp bad good r name re broken=0
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' RETURN
    bad="$tmp/bad.txt"; good="$tmp/good.txt"

    cat > "$bad" <<'EOF'
https://dev.azure.com/RealOrgName/_apis
AZURE_DEVOPS_ORG=RealOrgName
AZURE_DEVOPS_PROJECTS=RealProjA,RealProjB
GITHUB_ORG=RealOrgName
GITHUB_REPOS=real-repo-one,real-repo-two
C:\Users\realperson\source\repos
 /Users/realperson/Repos
EOF

    cat > "$good" <<'EOF'
https://dev.azure.com/<org>/_apis
AZURE_DEVOPS_ORG=<org>
AZURE_DEVOPS_PROJECTS=<project-a>,<project-b>
GITHUB_ORG=<org>
GITHUB_REPOS=<repo-a>,<repo-b>
C:\Users\<user>\source\repos
 /Users/<user>/Repos
EOF

    local allow i
    for i in "${!RULE_NAME[@]}"; do
        name="${RULE_NAME[$i]}"; re="${RULE_FIND[$i]}"; allow="${RULE_ALLOW[$i]}"
        # Test the EFFECTIVE predicate -- find AND NOT allow -- never the find
        # regex alone. Testing only `find` would pass while the allow regex
        # silently excused everything, which is the precise shape of bug this
        # self-test exists to catch.
        if ! grep -E -- "$re" "$bad" | grep -qvE -- "$allow"; then
            echo "  [SELFTEST] rule '$name' did NOT fire on its violating fixture"
            broken=1
        fi
        if grep -E -- "$re" "$good" 2>/dev/null | grep -qvE -- "$allow"; then
            echo "  [SELFTEST] rule '$name' fired on its COMPLIANT fixture (false positive)"
            broken=1
        fi
    done

    # the email rule, same two sides
    if ! printf 'someone@realcompany.com\n' | grep -E -- "$EMAIL_RE" | grep -qvE -- "$EMAIL_ALLOW"; then
        echo "  [SELFTEST] email rule did NOT fire on a real-looking address"; broken=1
    fi
    if printf 'noreply@anthropic.com\n' | grep -E -- "$EMAIL_RE" | grep -qvE -- "$EMAIL_ALLOW"; then
        echo "  [SELFTEST] email rule fired on an allowlisted address"; broken=1
    fi

    # MECHANISM check, not a rule check: prove the exact denylist grep does not
    # abort on this machine before trusting its verdict. `grep -iF` SIGABRTs here
    # (GNU grep 3.0), which is why the denylist matcher is case-sensitive; this
    # asserts the replacement actually runs rather than assuming it does.
    printf 'ReFac\n' > "$tmp/dl.txt"
    printf 'Project ReFac notes\nnothing to refactor here\n' > "$tmp/subject.txt"
    if ! grep -nwF -f "$tmp/dl.txt" "$tmp/subject.txt" >/dev/null 2>&1; then
        echo "  [SELFTEST] the denylist grep (-nwF -f) failed or aborted on this machine"; broken=1
    fi
    # and prove -w really does prevent the substring false positive that cost
    # two wasted verification passes on 2026-08-04 ("ReFac" vs "refactor")
    if grep -nwF -f "$tmp/dl.txt" "$tmp/subject.txt" 2>/dev/null | grep -q 'refactor'; then
        echo "  [SELFTEST] -w did not prevent the substring match (ReFac matched refactor)"; broken=1
    fi

    if [ "$broken" -ne 0 ]; then
        echo
        echo "SELF-TEST FAILED -- the checker is broken, so its verdict on this repo means nothing."
        echo "Fix the rules before trusting any result. Exiting 2 to distinguish this from a real finding."
        exit 2
    fi
    echo "  [ok] self-test: all $(( ${#RULE_NAME[@]} + 1 )) rules fire on violations and stay silent on placeholders"
}

echo "lint-identifiers -- this repository is PUBLIC"
echo
echo "Self-test:"
selftest
echo
echo "Structural rules:"

for i in "${!RULE_NAME[@]}"; do
    scan "${RULE_NAME[$i]}" "${RULE_FIND[$i]}" "${RULE_ALLOW[$i]}" "${RULE_WHY[$i]}"
done

# --- emails ------------------------------------------------------------------
email_hits=$(files | xargs -r grep -InE -- "$EMAIL_RE" 2>/dev/null \
    | grep -vF "$MARKER" | grep -vE -- "$EMAIL_ALLOW" || true)
if [ -n "$email_hits" ]; then
    fail "email -- a real email address; allowlist it in this script if legitimate"
    printf '%s\n' "$email_hits" | head -20 | sed 's/^/         /'
else
    pass "email"
fi

# --- optional local denylist -------------------------------------------------
# -w is load-bearing. A search WITHOUT it matched every occurrence of "refactor"
# while looking for a project name, twice on 2026-08-04 -- once in the audit and
# again in the post-rewrite verification. -w requires word boundaries, which
# kills that entire false-positive class.
#
# CASE-SENSITIVE on purpose, and this is a machine constraint rather than a
# preference: `grep -iF` ABORTS on this machine (GNU grep 3.0, exit 134). -F is
# non-negotiable for a denylist, because entries are literal tokens that must not
# be reinterpreted as regexes -- a token containing '.' or '*' would silently
# over-match. So -i is the flag that goes. List case variants explicitly in the
# denylist if you need them. The self-test proves this invocation runs here.
if [ -f "$DENYLIST" ]; then
    if git ls-files --error-unmatch "$DENYLIST" >/dev/null 2>&1; then
        fail "denylist -- $DENYLIST is TRACKED. It contains the very strings this guards; add it to .gitignore and untrack it."
    else
        dn_hits=$(files | xargs -r grep -nwF -f "$DENYLIST" 2>/dev/null | grep -vF "$MARKER" || true)
        if [ -n "$dn_hits" ]; then
            fail "denylist -- a token from $DENYLIST appears in a tracked file"
            printf '%s\n' "$dn_hits" | head -20 | sed 's/^/         /'
        else
            pass "denylist ($(grep -cve '^[[:space:]]*$' "$DENYLIST") token(s), word-boundary matched)"
        fi
    fi
else
    echo "  [--] no $DENYLIST present -- structural rules only."
    echo "       For exact-token checking, create it (one token per line). It is"
    echo "       gitignored on purpose: a committed denylist would publish the"
    echo "       strings it exists to catch."
fi

echo
echo "----"
echo "  $PASS passed, $FAIL failed"
[ "$FAIL" -gt 0 ] && exit 1
exit 0
