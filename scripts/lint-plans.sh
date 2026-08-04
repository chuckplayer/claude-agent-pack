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
                if ! printf '%s\n' "$fm" | grep -q "^${field}:[[:space:]]*[^[:space:]]"; then
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
                id=$(printf '%s\n' "$body" | head -1 | sed 's/^- \(BAR-[0-9]*\):.*/\1/')

                # Evidence: required, and must name a recognised kind.
                ev=$(printf '%s\n' "$body" | grep -m1 '^[[:space:]]*Evidence:' || true)
                if [ -z "$ev" ]; then
                    fail "$id" "no Evidence: line"
                elif ! printf '%s\n' "$ev" | grep -qE '^[[:space:]]*Evidence:[[:space:]]*(tests|manual|files)\b'; then
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
                if printf '%s\n' "$body" | grep -qE '^[[:space:]]*Gated:[[:space:]]*[^[:space:]]'; then
                    if printf '%s\n' "$body" | grep -qE '^[[:space:]]*Cost:[[:space:]]*[^[:space:]]'; then
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
        dev_body=$(sed -n '/^## Deviations/,$p' "$plan" | tail -n +2 | grep -v '^[[:space:]]*$' || true)
        if [ -z "$dev_body" ]; then
            fail "## Deviations" "section is empty -- must hold the sentinel, 'None.', or one bullet per departure"
        elif printf '%s\n' "$dev_body" | grep -qF 'Deviations not yet reviewed'; then
            echo "  [--] ## Deviations still holds its sentinel (correct before step 10)"
        else
            pass "## Deviations filled in"
        fi
    fi

    echo
done

echo "----"
echo "  $PASS passed, $FAIL failed"

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
exit 0
