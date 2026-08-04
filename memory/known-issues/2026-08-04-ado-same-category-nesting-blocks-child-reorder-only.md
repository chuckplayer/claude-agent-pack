**Date:** 2026-08-04
**Type:** finding
**Status:** active
**Superseded-by:** n/a
**Scope:** skills/devops-azure/SKILL.md batch write mode (8c, 8f), and any future pair-report design
**Overrides-convention:** no
**Related-to:** 2026-08-04-challenge-ado-pair-report.md, 2026-08-03-ado-workitemtypes-lists-blocked-types.md, docs/plans/bar-cost-and-first-run.md

## AMENDED 2026-08-04 (same day) — the UI was then tested, and two "NOT REPRODUCED" rows below were wrong

**Read this section before the table.** The findings below are correct **for the REST surface** and are
left unedited. But the table marked *hidden items* and *the board will not reorder* as **NOT
REPRODUCED**, and a human then drove the Azure DevOps UI against the same fixture. **On the sprint
backlog, both reproduce.** The file caveated that only REST had been tested and still wrote "not
reproduced" in a results column — which reads as a finding about the world rather than as an untested
surface. **That is this pack's recurring failure in a new costume: the caveat was present and the table
still overstated.** State "not tested on the surface where the claim lives," never "not reproduced."

**What the UI does, on the Sprint backlog page, verbatim from the warning it displays:**

```
There is same category hierarchy on this backlog. You cannot reorder work items and
work item(s) 706828 are not shown. See work item(s) 706829, 706830 to either remove
the parent to child link or change the link type to 'Related'
```

Three things in that message that no REST call revealed:

1. **Reordering is disabled for the entire sprint backlog**, not for the offending item. The docs'
   "a board that will not reorder" was right about the sprint board.
2. **The item hidden is the PARENT (`706828`), not the nested child.** Every earlier version of this
   pack's text, and the intuition behind it, assumed intermediate *children* go missing. It is the
   other way round, and a check written on the intuition would look for the wrong item.
3. The UI **names the offending children and both remedies**, so it is loud where it fires.

**The UI diverges from the API in BOTH directions**, which is why neither surface alone is sufficient:

| | REST | UI |
|---|---|---|
| Reorder same-category **child** | refused, `SameTypeHierarchyException`, at **both** product and iteration scope | **succeeded and persisted** on the backlog page (pending a refresh re-check) |
| Reorder a **clean** item in the affected sprint | **allowed**, exit 0, iteration scope | **blocked** — board-wide disable |
| Sprint backlog contents | returns all three, **including** the parent | **hides the parent** |

So the API rule is simple and consistent — *the same-category child cannot be reordered, everything
else can* — and the **UI guard is a different rule entirely**, stricter on the sprint board and more
permissive on the product backlog. **Do not derive one from the other.** The iteration-scoped reorder
route (`_apis/work/iterations/{id}/workitemsorder`) was missed in the first probe and is a distinct
endpoint from the product-scope one; both were tested for this amendment.

**Still unconfirmed:** whether the UI's successful drag of the child survives a hard page refresh. The
child carries a computed-looking `BacklogPriority` and its parent link is intact, which is consistent
with a real write, but a UI that optimistically renders a move it later reverts would look identical at
that moment.

## Summary

**The board-degradation claim was finally executed against a real project, and it is narrower and
louder than this pack has been saying for three revisions.** Nesting a work item under a parent in the
**same backlog category** makes **that child** unreorderable — HTTP 400,
`SameTypeHierarchyException`, with remediation text. It does **not** break the board: the parent and
every other item on the same backlog reorder normally. The child is **not hidden** from the product
backlog and **not missing** from the sprint backlog. So `8f`'s justification — "a board that will not
reorder, and items missing from sprint backlogs … with no failed command, no non-zero exit" — is
**wrong on three of its four clauses**, and this is the **third** time that paragraph's reasoning has
been wrong while its STOP stayed right.

**The trigger is category, not type.** The exception is *named* `SameTypeHierarchyException` but fires
on same-**category**: `User Story → Bug` fails identically to `User Story → User Story`, because
`Microsoft.RequirementCategory` holds `Product Backlog Item`, `User Story`, **and** `Bug`. Any rule
keyed on "same type" misses `User Story → Bug` entirely.

## What was executed

Against `<org>/<project-a>` on 2026-08-04, with four purpose-created items, all soft-deleted afterwards.
The project was returned to its exact 9-item requirement-backlog baseline in the same order.

Reads used, and why not the obvious ones:

- Backlog contents: `GET {project}/{team}/_apis/work/backlogs/{backlogId}/workItems` via **`az rest`**
  with `--resource 499b84ac-1321-427f-aa17-267ca6975798`.
- Reorder: `PATCH {project}/{team}/_apis/work/workitemsorder`, body `{"ids":[..],"previousId":n,"nextId":m}`.
- Sprint contents: `GET {project}/{team}/_apis/work/teamsettings/iterations/{id}/workitems`.

**Every result below was gated on a positive control first**, because three of this pack's ADO findings
have been false negatives from a read that looked fine. Controls run: the backlog read returns <project-a>'s 9
real items; a flat item reorders successfully before any nesting exists.

| Claim, as the pack has stated it | Executed result |
|---|---|
| Same-category pair is **accepted** at creation, exit 0 | **CONFIRMED** (re-confirmed; already known) |
| Nested child is **hidden** from the product backlog | **NOT REPRODUCED** — listed normally; 12 items before nesting, 12 after, nothing disappeared |
| Nested child is **missing** from the sprint backlog | **NOT REPRODUCED** — present, and its `System.LinkTypes.Hierarchy-Forward` relation is reported correctly |
| **The board** will not reorder | **FALSE as stated.** Only the child fails. Parent reorders exit 0; an unrelated item on the same backlog reorders exit 0 |
| The damage is **silent**, no non-zero exit | **HALF FALSE.** Silent at creation; any reorder attempt on the child returns HTTP 400, `typeKey: SameTypeHierarchyException`, naming the item and the two fixes |
| The trigger is same **type** | **FALSE** — same **category**. `User Story → Bug` fails identically |

The exact message, both times:

```
Work item <id> can't be reordered because its parent is on the same category.
Please remove the link between <id> and its parent or change the link type to
'Related' to fix the issue.
```

## Impact

- **The STOP in `8f` is still correct, now for a third reason.** A same-category child is permanently
  unreorderable until someone re-parents it or converts the link to `Related`. That is a real
  degradation, it is just narrow and self-announcing rather than broad and silent.
- **`8f`'s text must stop asserting the broad version.** It has now been corrected three times —
  first "ADO refuses the pair" (false), then "the board will not reorder, silently" (false), and the
  underlying behaviour was never executed until today. **The pattern is the lesson: that paragraph
  keeps acquiring a confident mechanism nobody ran.**
- **A future pair report gains a real, executable trigger, and it is not the one the withdrawn designs
  used.** The checkable property is "does this tree ask for a parent and child in the **same backlog
  category**" — derivable from `GET _apis/work/backlogs` (which returns each level's
  `workItemTypes`) plus the confirmed type mapping. **Zero writes, no client-side edge join, no
  `MODE` question, and no demonstrated/unused axis** — which is what killed the third design. Note it
  also answers the objection that the demonstrated/unused axis was uncorrelated with the documented
  harm: category membership *is* the harm's actual trigger.
- **Do not infer the UI from this.** Every result is the REST surface. Microsoft documents this as UI
  behaviour, and whether the backlog *page* renders a same-category child differently was not tested
  and needs a human or a browser.

## Cost, corrected

The recorded cost of this probe — "permanent items in a mode with no delete path" — **was wrong.**
`az boards work-item delete` soft-deletes to the recycle bin and works with this account; all four
probe items were removed and are unreadable. What does **not** work is `--destroy`: it fails
`VS402324` (permission), so the ids are permanently consumed and the items sit in the project recycle
bin. **"No delete path" is a decision inside batch write mode, not a limit of ADO or the CLI** — and
`skills/devops-azure/SKILL.md` says it three times in wording that invites the broader reading.

**Residue this probe created, stated because it was not intended.** The first reorder assigned
`Microsoft.VSTS.Common.BacklogPriority` to the **six** BAR-015 residue User Stories that previously had
none (`706526`, `706533`, `706535`, `706537`, `706539`, `706541`). The three real `Tech Debt:` items
kept their existing values and were not touched. See
[[2026-08-04-az-reorder-writes-beyond-the-ids-you-pass]] — the reorder API is not scoped to the ids in
the request body, which is what caused this.
