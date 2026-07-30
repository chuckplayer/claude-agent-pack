**Date:** 2026-07-30
**Type:** finding
**Status:** active
**Superseded-by:** n/a
**Scope:** agents/merge-reviewer.md, docs/plans/
**Overrides-convention:** no
**Related-to:** docs/obsidian-cli-and-plan-spine-brief.md, 2026-07-30-challenge-durable-plan-spine-first-cut.md

## Summary

Gate 4a verifies that every acceptance bar carries evidence. It does **not** verify that the plan's
narrative half still describes what was actually built. So a plan can be committed alongside an
implementation that contradicts a call recorded in it, and the gate returns PASS. The
"reviewer reads intended shape against implementation" benefit — the entire justification for
committing the plan at all — is therefore real but **unenforced**.

Demonstrated live, not theorised. This is the concrete case for the `## Deviations` section that
Design C deliberately deferred past the first cut.

## Symptoms

During the 2026-07-30 gate exercise, `tech-lead` wrote a plan whose `## Calls made for you` section
stated:

```
- **Test runner: Vitest**, because test-engineer's contract is xUnit for C# and Vitest for ...
```

and whose Risks section separately flagged that Vitest is ESM-first and would be the largest single
change in the cut. The implementation then shipped the alternative — plain `node` plus `assert`,
with `package.json` declaring `"test": "node tests/slugify.test.js"` and **no devDependency at
all**.

`merge-reviewer` ran the full checklist and returned PASS. Gate 4a was satisfied: four bars, four
`Evidence:` lines, all correctly paired. Nothing in the gate looks at the narrative half, so the
contradiction committed silently alongside the code it contradicts.

## Root cause

The gate's scope is the working-memory half of the plan — bars and their evidence. That is
deliberate and correct: bars are checkable, and a narrative is not mechanically comparable to a
diff. But it leaves the narrative unowned once the plan is written:

- `tech-lead` writes the calls before the work happens, so it cannot know they were overridden.
- Engineers surface departures in their handoff, but Design C assigns nobody to *write* those
  departures into the plan — that is the deferred `## Deviations` duty.
- `merge-reviewer` never reads the narrative, so it cannot notice the divergence.

Worth noting this is a **fifth instance of the unowned-duty pattern** recorded in
[[2026-07-30-challenge-durable-plan-spine-first-cut]] — the design named a responsibility
("report departures from the plan") and no component in the shipped cut carries it.

## Workaround

Until `## Deviations` lands, treat the narrative half as **intent at time of writing, not a
description of what shipped.** Concretely:

- Do not silently amend a stated call to match the implementation. That destroys the only signal
  that the call was overridden, which is the one thing the record is for. `tech-lead` refused to do
  this unprompted during the exercise and was right to.
- When a reviewer trips on a divergence between the plan and the diff, that is the mechanism
  working as currently designed — a human noticing. Say so rather than treating it as a defect in
  the plan.
- If the divergence matters enough to record, add it to `memory/decisions/` where it is durable,
  rather than editing the plan.

## Revisit trigger

Implement the `## Deviations` section in the plan-spine's second cut: engineers report departures in
their handoff, the lead session writes them into the plan before merge-reviewer runs, and gate 4a
gains a check that any recorded deviation is non-empty when the implementation diverges. Note the
prerequisite from the same exercise — the plan is invisible inside engineer worktrees until it is
committed, so a worktree-isolated engineer cannot read the plan it is departing from.
