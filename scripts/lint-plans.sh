#!/usr/bin/env bash
set -euo pipefail

# Validate the structure of a durable plan file.
#
#   bash scripts/lint-plans.sh <path-to-plan.md> [<path> ...]
#
# Takes explicit paths ONLY. It never globs a plan directory, because plan
# consumption in this pack is opt-in per invocation: a glob would let one run
# validate — and report on — a plan belonging to unrelated work. See CLAUDE.md
# "Consumption is opt-in per invocation".
#
# Checks structure, never truth. It cannot know whether a bar's evidence proves
# anything or whether a stated cost is accurate; those are a reader's job, and
# the bar-soundness table in agents/tech-lead.md is where that judgement lives.

PASS=0
FAIL=0

pass() {
    echo "  [ok] $1"
    PASS=$((PASS + 1))
}

fail() {
    echo "  [!!] $1  -- $2"
    FAIL=$((FAIL + 1))
}

# --- never pipe into a short-circuiting matcher under pipefail ---------------
# `grep -q`/`grep -m1`/`head -1` exit as soon as they have what they need. When
# the producer is still writing, it dies of SIGPIPE (141), and `set -o pipefail`
# on line 2 makes THAT the pipeline's status -- so a successful match reports
# failure. It is size-dependent: below the pipe buffer the producer finishes
# first and the bug is invisible, which is why this survived every small plan.
#
# Observed 2026-08-05: a plan whose Deviations body reached 83 KB reported
# "## Deviations filled in" while the sentinel sat untouched on the section's
# first line -- the checker reporting the opposite of the truth on the one
# question the sentinel exists to answer. That is the second time this exact
# check has done that, for a different cause (see the comment above it).
#
# So: feed a variable to a matcher with a HERESTRING, never a pipe.

# Echoes one of: empty | sentinel | filled
deviations_state() {
    local plan="$1" body
    # Bounded at the NEXT '## ' heading, never end-of-file. The bar-body loop
    # below already learned this and says why; reading to EOF here swept
    # ## Risks, ## Acceptance bars and ## Challenge into the "Deviations body",
    # so an empty section was undetectable whenever any later section existed --
    # and it is what inflated the body past the pipe buffer above.
    body=$(awk '
        /^## Deviations[[:space:]]*$/ { f=1; next }
        f && /^## / { exit }
        f { print }
    ' "$plan" | grep -v '^[[:space:]]*$' || true)

    if [ -z "$body" ]; then
        echo empty
    elif grep -qF 'Deviations not yet reviewed' <<< "$body"; then
        echo sentinel
    else
        echo filled
    fi
}

# --- self-test: prove the mechanism before trusting any result ---------------
# A checker that cannot demonstrate its own detection reports a clean plan for
# the wrong reason. The filler below is deliberately larger than the pipe buffer,
# because a small fixture cannot catch the regression described above.
selftest() {
    local d rc=0 got
    d=$(mktemp -d)

    _st_plan() {  # $1 = the Deviations body line ('' for none), $2 = output path
        {
            echo '---'
            echo 'plan_id: zzselftest'
            echo 'branch: main'
            echo 'origin_skill: /plan'
            echo 'created: 2026-01-01'
            echo '---'
            echo
            echo '## Deviations'
            echo
            if [ -n "$1" ]; then echo "$1"; fi
            echo
            echo '## Filler'
            echo
            awk 'BEGIN{ for (i=0; i<1200; i++) print "filler line pushing this section past the pipe buffer, which is where the SIGPIPE regression lived." }'
            echo
            echo '## Acceptance bars'
            echo
            echo '- BAR-001: a bar'
            echo '  Evidence: files -> something'
        } > "$2"
    }

    _st_plan '_Deviations not yet reviewed. The coordinating session replaces this line before' "$d/sentinel.md"
    _st_plan 'None.' "$d/filled.md"
    _st_plan '' "$d/empty.md"

    for case in sentinel filled empty; do
        got=$(deviations_state "$d/$case.md")
        if [ "$got" != "$case" ]; then
            echo "  [!!] self-test: $case fixture reported '$got'"
            rc=1
        fi
    done

    rm -rf "$d"
    if [ "$rc" -ne 0 ]; then
        echo "  self-test FAILED -- not scanning. A checker that cannot detect its own cases proves nothing."
        exit 2
    fi
    echo "  [ok] self-test: sentinel, filled and empty all detected on a section larger than the pipe buffer"
    echo
}

selftest

if [ "$#" -eq 0 ]; then
    echo "Error: no plan file given."
    echo "Usage: bash scripts/lint-plans.sh <path-to-plan.md> [<path> ...]"
    echo "This script never globs a plan directory -- pass the plan handed to your run."
    exit 1
fi

REQUIRED_FRONTMATTER="plan_id branch origin_skill created"

for plan in "$@"; do
    echo "$plan"

    if [ ! -f "$plan" ]; then
        fail "$plan" "file not found"
        continue
    fi

    # --- frontmatter ---------------------------------------------------------
    if ! head -1 "$plan" | grep -q '^---[[:space:]]*$'; then
        fail "frontmatter" "file does not open with a --- fence on line 1"
    else
        fm_end=$(awk 'NR>1 && /^---[[:space:]]*$/{print NR; exit}' "$plan")
        if [ -z "${fm_end:-}" ]; then
            fail "frontmatter" "opening --- fence is never closed"
        else
            fm=$(sed -n "2,$((fm_end - 1))p" "$plan")
            missing=""
            for field in $REQUIRED_FRONTMATTER; do
                if ! grep -q "^${field}:[[:space:]]*[^[:space:]]" <<< "$fm"; then
                    missing="$missing $field"
                fi
            done
            if [ -n "$missing" ]; then
                fail "frontmatter" "missing or empty:$missing"
            else
                pass "frontmatter ($REQUIRED_FRONTMATTER)"
            fi
        fi
    fi

    # --- required sections --------------------------------------------------
    for section in "## Acceptance bars" "## Deviations"; do
        if grep -qF "$section" "$plan"; then
            pass "section present: $section"
        else
            fail "section missing: $section" "a plan without it cannot be enforced by merge-reviewer"
        fi
    done

    # --- bars ---------------------------------------------------------------
    # A bar is a top-level list item of the form: - BAR-nnn: <subject>
    bar_lines=$(grep -n '^- BAR-[0-9][0-9]*:' "$plan" || true)
    if [ -z "$bar_lines" ]; then
        fail "bars" "no '- BAR-nnn:' items found under ## Acceptance bars"
    else
        bar_count=$(printf '%s\n' "$bar_lines" | wc -l | tr -d '[:space:]')
        pass "found $bar_count bar(s)"

        # duplicate ids
        dupes=$(printf '%s\n' "$bar_lines" | sed 's/^[0-9]*:- \(BAR-[0-9]*\):.*/\1/' | sort | uniq -d || true)
        if [ -n "$dupes" ]; then
            fail "duplicate bar ids" "$(printf '%s' "$dupes" | tr '\n' ' ')"
        else
            pass "bar ids unique"
        fi

        # Per-bar checks. A bar's body runs to the next bar or the next ## heading.
        starts=$(printf '%s\n' "$bar_lines" | cut -d: -f1)
        headings=$(grep -n '^## ' "$plan" | cut -d: -f1 || true)
        total_lines=$(wc -l < "$plan" | tr -d '[:space:]')
        prev_start=""
        for start in $starts $((total_lines + 1)); do
            if [ -n "$prev_start" ]; then
                end=$((start - 1))

                # Stop the LAST bar's body at the next ## heading rather than at
                # end-of-file. Everything below the bars -- ## Deviations, and the
                # ## Challenge section devils-advocate writes before composing its
                # reply -- would otherwise be read as that bar's own body, so a
                # Gated: or Evidence: line in prose *about* bars gets attributed to
                # whichever bar happens to be last. Observed: a ## Challenge section
                # discussing a gate failed an unrelated final bar for row 6.
                # $headings is ascending, so the first match is the nearest.
                for h in $headings; do
                    if [ "$h" -gt "$prev_start" ] && [ "$h" -le "$end" ]; then
                        end=$((h - 1))
                        break
                    fi
                done
                body=$(sed -n "${prev_start},${end}p" "$plan")
                # `head -1` and `grep -m1` short-circuit; herestrings keep them
                # off the downstream end of a pipe. See the note above fail().
                id=$(sed -n '1s/^- \(BAR-[0-9]*\):.*/\1/p' <<< "$body")

                # Evidence: required, and must name a recognised kind.
                ev=$(grep -m1 '^[[:space:]]*Evidence:' <<< "$body" || true)
                if [ -z "$ev" ]; then
                    fail "$id" "no Evidence: line"
                elif ! grep -qE '^[[:space:]]*Evidence:[[:space:]]*(tests|manual|files)\b' <<< "$ev"; then
                    fail "$id" "Evidence: must begin with tests, manual, or files"
                else
                    pass "$id Evidence: present and typed"
                fi

                # Row 6 of the bar-soundness table, mechanised: a bar marked
                # Gated: is asking a human to authorize a cost, so it must
                # state that cost. Presence only -- accuracy is a reader's job
                # and this script makes no claim about it.
                #
                # The trigger is the STRUCTURED field, never the prose word
                # "gated". Matching the word flagged bars that merely *mention*
                # gating -- a bar describing this very check, and two bars that
                # only referenced another bar's gate. That is bar-soundness
                # row 5 (pattern fragility) in the checker itself. A field
                # cannot be tripped by a bar talking about gates.
                if grep -qE '^[[:space:]]*Gated:[[:space:]]*[^[:space:]]' <<< "$body"; then
                    if grep -qE '^[[:space:]]*Cost:[[:space:]]*[^[:space:]]' <<< "$body"; then
                        pass "$id Gated: -> Cost: present"
                    else
                        fail "$id" "has a Gated: field but no Cost: line (bar-soundness row 6)"
                    fi
                fi
            fi
            prev_start="$start"
        done
    fi

    # --- Deviations sentinel ------------------------------------------------
    # An unfilled sentinel is NOT a failure: it is correct until step 10. But an
    # empty section is indistinguishable from one nobody looked at, so say which.
    #
    # Match the sentinel by its LITERAL TEXT, never by the word "sentinel". This
    # is the same structured-vs-prose distinction the Gated: check above already
    # makes, and it was missed here in the same commit that made it there: a
    # case-insensitive search for "sentinel" matched two plans whose *filled-in*
    # departure prose discusses the sentinel mechanism (spec-intake.md, 5 hits;
    # plan-spine-deviations.md, 15 -- the plan that introduced the sentinel), so
    # both completed sections were reported as unfilled. That is bar-soundness
    # row 5 in the checker itself, and it reports the opposite of the truth on
    # the one question the sentinel exists to answer.
    #
    # This literal is the single authority shared with agents/merge-reviewer.md
    # Tier 1, which greps the same string. Keep them identical: if tech-lead's
    # sentinel line in agents/tech-lead.md ever changes, all three move together.
    if grep -qF "## Deviations" "$plan"; then
        case "$(deviations_state "$plan")" in
            empty)
                fail "## Deviations" "section is empty -- must hold the sentinel, 'None.', or one bullet per departure" ;;
            sentinel)
                echo "  [--] ## Deviations still holds its sentinel (correct before step 10)" ;;
            filled)
                pass "## Deviations filled in" ;;
        esac
    fi

    echo
done

echo "----"
echo "  $PASS passed, $FAIL failed"

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
exit 0
