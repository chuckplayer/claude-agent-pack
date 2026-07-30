**Date:** 2026-07-30
**Type:** decision
**Status:** active
**Superseded-by:** n/a
**Scope:** agents/tech-lead.md, agents/merge-reviewer.md, skills/implement/SKILL.md, docs/plans/
**Overrides-convention:** no
**Related-to:** 2026-07-30-plan-gate-does-not-check-narrative-vs-implementation.md, 2026-07-30-challenge-durable-plan-spine-first-cut.md, 2026-07-30-agent-output-must-be-attributable-to-be-evidence.md

## Summary

The plan file's `## Deviations` section, and gate 4a's three-tier enforcement of it. Closes the gap
where a plan could ship committed alongside code contradicting a design call it recorded — the
"reviewer reads intended shape against implementation" benefit was real but unenforced.

Proven live before shipping: three deliberate FAILs (one per tier) and one PASS, each verified by
effect rather than by the reviewer's report.

## Context

Cut one committed the plan and kept it, so a reviewer could read intent against implementation. Gate
4a checked that every acceptance bar carried evidence. Nothing checked the *narrative* half. A live
run then demonstrated the hole: a plan stated the test runner would be Vitest, the code shipped
`node` + `assert`, and the gate returned PASS.

## Rationale

**Three tiers, cheapest and most certain first.** The gate's teeth are in the cheap tiers; only the
third needs judgment.

1. **Sentinel present** (mechanical) — tech-lead writes `## Deviations` as a self-describing sentinel
   line, never an empty heading. An empty section is indistinguishable from an unfilled one, and
   *"indistinguishable from nobody looking"* is this pack's recurring failure. Three states get three
   verdicts: section absent → FAIL malformed; sentinel intact → FAIL not reviewed; section filled →
   continue.
2. **Engineer claim unrecorded** (near-mechanical) — a departure reported in a handoff that never
   reached the section is a FAIL *regardless of whether the claim was accurate*. It is a
   record-keeping check, not a code check.
3. **Stated call contradicted, nothing recorded** (judgment, bounded).

**Tier 3 works from the calls, never from the diff.** This is the load-bearing choice. merge-reviewer
starts from each stated call, extracts the concrete artifact it names, and looks only for that. It
never scans the diff hunting for surprises. A call naming nothing specific yields **no lookup target**
and drops out of scope *by construction* — the agent is never asked "is this too vague to judge?",
only "what artifact does this name?", to which the answer is "none". That is the difference between a
rule and a coin flip, and it is why the tier cannot cry wolf on prose.

**Pattern names are explicitly out of scope**, and this is the case worth remembering because it
looks checkable and is not. "Use the repository pattern for data access" names a pattern, not an
artifact; whether a given `DbContext` reference violates it is an architecture judgment with
legitimate readings on both sides. **That judgment already has an owner** — `code-reviewer` reads
`docs/CONVENTIONS.md` and reviews pattern compliance, `smell-reviewer` catches the structural form,
both run earlier, and a code-reviewer Critical already blocks. Re-adjudicating it in the one agent
holding `Bash` and the commit would be a worse ruling on a settled question.

**The burden sits on the writer.** A call is gateable only if written falsifiably — the same
requirement an acceptance bar carries. `"No DbContext outside Infrastructure/Repositories/"` is
checkable; `"use the repository pattern"` is not. tech-lead is told this at write time; the definition
lives once, in `agents/merge-reviewer.md`.

**Ambiguity advises rather than fails, inverting the rule for bars** — with the reason recorded in the
file so it does not read as a contradiction. An unverifiable *bar* means verification did not happen,
which is what the gate exists to establish. An ambiguous *call* means the plan was imprecise: a
defect belonging to tech-lead, stages back, in a file the coordinating session can no longer usefully
change. Failing there punishes the wrong party, and a gate that fails on someone else's imprecision
gets switched off within a week.

**The remedy is one line in `## Deviations`, and the finding says so.** A gate whose cheapest correct
response is "record it" induces the behaviour wanted. One whose cheapest response is "argue with the
reviewer" gets disabled.

**Bar amendment is sanctioned but bounded.** A recorded deviation can falsify a bar's premise, leaving
it unsatisfiable rather than unmet — testing an abandoned design. The coordinating session may amend
it under four conditions: a named consequence of a recorded deviation, original wording quoted,
narrowly scoped to the invalidated clause, session only. merge-reviewer FAILs a bar amended with no
deviation behind it. Unbounded, this would gut acceptance bars entirely — "unsatisfiable" would always
be cheaper to fix by rewriting the bar than by fixing the code.

## Alternatives rejected

- **Commit the plan before engineers run**, so worktree-isolated engineers could read it. Correct in
  isolation but reopens commit timing, the most contested question of cut one. Instead `/implement`
  step 5 pastes the relevant calls **verbatim** into each dispatch prompt — paraphrase is where the
  signal dies.
- **Advisory-only enforcement.** Cheaper and avoids false FAILs, but an unrecorded override still
  commits — today's failure with an extra heading.
- **Diff-driven scanning.** Unbounded, and the route by which the tier would learn to wave everything
  through while still looking like enforcement.
- **Deviation ids and a pairing contract.** Bars need ids because a downstream stage maps evidence
  onto each. Nothing maps onto a deviation, so an id would be ceremony.
- **Editing engineer agent files.** The duty is delivered at dispatch time, as devils-advocate's
  bar-review duty already is. The tradeoff is recorded, not fixed: an engineer invoked by any other
  caller carries no departure duty, because the duty belongs to one caller rather than to the agent.

## Implications

- Gate coverage is now a function of **how well tech-lead writes its calls.** A planner writing only
  vague calls gets an empty Tier 3 reporting PASS. Same shape as cut one's accepted "weak bars" risk,
  same conditional mitigation (devils-advocate). Not closed; if it bites, the fix is a
  devils-advocate duty to flag non-falsifiable calls in the pass where it already pressure-tests
  bars — one line of dispatch prose, no new file.
- **If Tier 3 cries wolf in practice, demote it to advisory and keep Tiers 1 and 2 blocking.** Tier 1
  alone forces someone to look on every plan-governed run, which retains most of the value. Prefer
  that over disabling gate 4a.
- Instructions that read correctly to a human can still fail to execute. tech-lead omitted the whole
  section on its first run against the new template — the section was the only one arriving with
  pre-filled content, and that content said "do not fill this in", which read as "leave it out". Fixed
  by unambiguous wording plus a **self-check requiring tech-lead to read its own plan back**. The
  self-check is the durable half; the wording was cosmetic by comparison.
