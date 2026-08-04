**Date:** 2026-08-04
**Type:** decision
**Status:** active
**Superseded-by:** n/a
**Scope:** skills/devops-azure/SKILL.md batch write mode (8c/8e preview) — design not yet implemented
**Overrides-convention:** no
**Related-to:** 2026-08-04-ado-same-category-nesting-blocks-child-reorder-only.md, 2026-08-04-challenge-ado-pair-report.md, 2026-08-04-decision-ado-pair-report-states-facts-only.md, docs/plans/bar-cost-and-first-run.md

## Summary

**The pair report finally has a mechanism that was verified before any design text was written**, which
is the one thing all three previous attempts got wrong. It keys on **backlog category**, derived from a
single zero-write read, and it was checked against six pairs whose real behaviour had already been
executed — including the case a "same type" rule cannot see.

**Nothing is implemented.** This records the verified mechanism and the open decisions so the next
attempt starts from executed ground instead of re-deriving it.

## The mechanism, and the check that it is right

One read gives every backlog level and the work item types in it:

```bash
az devops invoke --area work --resource backlogs \
  --route-parameters project=<project> team=<team> \
  --org https://dev.azure.com/<org> --http-method GET --api-version 7.1
```

Invert it into `type -> category`, then a required parent/child pair degrades **iff
`category(parent) == category(child)`**. Verified 2026-08-04 against a live project:

| pair | derived | executed truth |
|---|---|---|
| `User Story -> Task` | OK | reorders fine |
| `Feature -> User Story` | OK | reorders fine |
| `Epic -> Feature` | OK | conventional |
| `Feature -> Task` | OK | unconventional, different category, fine |
| `User Story -> User Story` | **FLAG** | `SameTypeHierarchyException` |
| `User Story -> Bug` | **FLAG** | `SameTypeHierarchyException` |

**All six agree.** The last row is the whole reason this keys on category: `User Story` and `Bug` are
different *types* in the same *category*, so a same-type rule reports it as safe while ADO refuses it.
In that project `Product Backlog Item`, `User Story` and `Bug` share `Microsoft.RequirementCategory`,
and `Task` shares `Microsoft.TaskCategory` with `Defect`.

## Why this survives what killed v1, v2 and v3

- **v1** rested on "a link needs two created items to test" — false, a link target can be any existing item.
- **v2** rested on "the template refuses a bad pair" — false, ADO accepts with exit 0.
- **v3** asserted no ADO behaviour at all, but computed **false project history**: it published 101
  parent-child edges against 96 possible children. Its axis (has this project used the pair before?)
  was also uncorrelated with the harm, and *inverted* on the one case where they met.
- **v4 needs no edge list, no client-side join, no `MODE` question, no history, and no inference.**
  Category membership **is** the harm's trigger, and the mapping is read from the target project so it
  cannot be wrong about a different process template.

**This is the first version permitted to predict**, because the consequence was executed on 2026-08-04
rather than taken from documentation: the child cannot be reordered at either API scope, and on the
sprint board the UI disables reordering **board-wide** and hides the **parent**.

## Open decisions — do not implement before settling these

1. **Disposition.** Informational line, warning requiring acknowledgement, or a stop? Batch mode has no
   delete path, and the damage is invisible afterwards to every read available to this pack. That argues
   for more than an informational line — but v2 died from making a check fatal on a false premise, so
   the bar for a stop is high even now that the premise is true.
2. **Where the mapping comes from.** The operator confirms `type` per tree level in preview item 2, so
   the pairs are derivable there without new questions. Confirm it adds no second confirmation —
   step 7's one-confirmation rule and 8e's single-confirmation rule are **not** edit sites.
3. **Read failure.** If the levels read returns nothing, the report must degrade to "unavailable" and
   let the batch proceed — never a stop. Needs a positive control: at least two levels, each with at
   least one type. `az devops invoke` is known to serve a **sibling route** silently when route params
   do not disambiguate, so an unguarded read can manufacture a wrong answer.
4. **`SPIKE`.** It maps to the same ADO type as `STORY`. Under the fixed grammar
   `FEATURE -> STORY|SPIKE -> TASK` a SPIKE is a *sibling* of STORY, so no same-category pair arises
   from it by default — but it does if the operator maps `FEATURE` to a requirement-category type.
   That is exactly the case worth catching, and it is worth stating that the check finds it.
5. **Review.** This feature has killed three designs. It should get an adversarial pass before shipping,
   and the session that verified the mechanism is not the right check on its own design.

## Reproducing

`scripts/` holds no helper for this. The derivation is ten lines: read levels, invert to `type ->
category`, compare the two categories per required pair. The verification harness used on 2026-08-04
lived in the session scratchpad and was intentionally not committed — it asserted six known answers and
would rot the moment a process template changed. **Re-derive against the target project rather than
trusting this table**; the table is evidence that the method works, not a cache of the answer.
