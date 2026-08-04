**Date:** 2026-08-04
**Type:** finding
**Status:** active
**Superseded-by:** n/a
**Scope:** skills/devops-azure/SKILL.md 8c (line ~224) and any pair-report design; corrects a shipped claim
**Overrides-convention:** no
**Related-to:** 2026-08-04-ado-same-category-nesting-blocks-child-reorder-only.md, 2026-08-04-decision-pair-report-v4-keys-on-backlog-category.md, 2026-08-04-challenge-ado-pair-report-v4.md, docs/plans/ado-pair-report-v4.md

## Summary

**A backlog *level* and a work item type *category* are different things in Azure DevOps, they carry the
same reference names, and they disagree in practice.** Executed 2026-08-04 across eight projects in one
org, both routes, zero writes.

`SKILL.md` line ~224 states *"`Microsoft.RequirementCategory` holds `Product Backlog Item`, `User Story`,
**and** `Bug`"*. As a claim about the **work item type category** that is **false in 4 of the 6 projects
that returned data** and true in 1. As a claim about the **backlog level of the same name** it is true.
Nobody had ever read a category route; every probe in four design attempts read backlog levels and the
record called the result a category.

**The predicate the service actually enforces is backlog-level membership for a team, not category
membership.** The executed refusal on 2026-08-04 was `User Story -> Bug` (HTTP 400,
`SameTypeHierarchyException`). In that configuration `Bug` sits on the Requirement **level** and in the
**Bug category** — so a category-keyed rule would have found the two types in different groups and stayed
silent while the service refused. The error message's word "category" is the service's own loose usage and
must be quoted, never adopted as a derived claim.

## What was executed

Two zero-write reads per project, `--api-version 7.1`:

- **Team-scoped levels:** `az devops invoke --area work --resource backlogs --route-parameters project=<project> team=<team>`
- **Project-scoped categories:** `az devops invoke --area wit --resource workitemtypecategories --route-parameters project=<project>`

Comparing the `Microsoft.RequirementCategory` **level** against the `Microsoft.RequirementCategory`
**category** in each project:

| Project | `Bug` in the level | `Bug` in the category | Agree? |
|---|---|---|---|
| `<project-a>` | yes | **no** | **no** |
| `<project-b>` | yes | **no** | **no** |
| `<project-c>` | yes | yes | yes |
| `<project-d>` | level absent | no | n/a |
| `<project-e>` | yes | **no** | **no** |
| `<project-f>` | yes | **no** | **no** |

Two further projects could not be read at all — see the 500 finding below.

**The divergence is configuration-dependent, which is worse than a flat error.** One project agrees, so a
spot check against the wrong project ratifies the false claim. That is how this sentence survived four
design attempts.

## Four things found in the same probe, none of which had been predicted

1. **The `backlogs` response is an envelope, not an array.** It returns `{ "count": n, "value": [ … ] }`.
   Iterating the parsed object instead of its `.value` yields **one row with every field empty, exit 0** —
   a clean-looking empty result rather than an error. Under a naive implementation every type resolves to
   "no level", so the whole check degrades to silence while reporting success. This is the shape hazard the
   design's positive control exists for, and it fired on the very first live call.
2. **The route returns HTTP 500 for some teams that appear in the team list.** Two of eight projects
   failed with `too many 500 error responses` for their first-listed team, non-zero exit. So a
   **per-team** loop over candidate teams will routinely partially fail: some teams resolve, some do not.
   Any design that reads this route once per team needs a story for **partial** failure, not just for
   total failure.
3. **A team commonly has no area-path values at all.** In one three-team project, `teamfieldvalues`
   returned `field.referenceName = System.AreaPath` with an **empty `defaultValue` and no `values`
   array** for two of the three teams. Distinguish "read succeeded, team configures no area path" from
   "read failed" — they are different states and only one is `UNKNOWN`.
4. **A team can be missing whole backlog levels.** One team returned **two** levels (requirement and task)
   with no feature or epic level, and two other teams had no requirement level at all. So a mapped type
   resolving to **zero** levels is an ordinary configuration, not an exotic one, and any design treating
   it as anomalous will produce noise on real projects.

Also observed, smaller: `isHidden` is genuinely per team — the epic level came back `isHidden: true` in
one project and `false` in another with the same level set. `az devops team list` was **not** truncated at
81 teams (default result equalled `--top 1000`). And `az` emitted *"Unable to encode the output with cp1252
encoding. Unsupported characters are discarded"* on the largest project, so **a team name containing a
non-cp1252 character is silently mangled on output on this machine** — a real hazard for any design that
routes on team names.

## Impact

- **`SKILL.md` line ~224 is a shipped factual defect and should be corrected independently of any pair
  report.** This is the same situation as 8c's "learned only by attempting a link and having it fail",
  which was false, shipped, and fixed on its own in `3e320b5`. Correct it to say **backlog level**, and
  where the operator-facing text wants the word "category", quote ADO's warning rather than asserting it.
- **Any pair-report design must name its predicate as the backlog level for a named team.** Keying on
  categories loses the `User Story -> Bug` case entirely — the exact case that motivated keying on
  something other than type.
- **The cross-route comparison is a working control.** Two independent routes disagreeing is the first
  direct evidence in this line of work that the grouping is team-varying, and it is a control that is not
  the same call as the test — which is what
  `memory/known-issues/2026-08-04-challenge-ado-pair-report-v4.md` concern 7 said was missing.
- **Heavy process customisation is the norm here, so "the check can never fire under the sanctioned
  default mapping" is not safe.** Requirement levels in this org hold up to **nine** types, most of them
  process-specific rather than stock. Two ordinary mapping choices can land on one level with no operator
  override at all.

## Reproducing

Two reads per project, both zero-write, both listed above. Compare the `workItemTypes` list of the level
whose `id` is `Microsoft.RequirementCategory` against the `workItemTypes` list of the category whose
`referenceName` is the same string. **Parse `.value`, never the envelope.** Trust `$LASTEXITCODE`; blank
or envelope-shaped output is `UNKNOWN`, never an empty configuration.
