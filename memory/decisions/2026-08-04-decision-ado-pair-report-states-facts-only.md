---
date: 2026-08-04
type: decision
status: archived
superseded-by: n/a
scope: skills/devops-azure/SKILL.md batch write mode (8c, 8e)
overrides-convention: no
related-to: 2026-08-04-challenge-ado-pair-report.md, 2026-08-03-challenge-devops-azure-batch-write.md, docs/plans/bar-cost-and-first-run.md
---

## REVERTED 2026-08-04 — the design below never shipped

**Archived rather than deleted, and archived rather than left active.** The `skills/devops-azure/SKILL.md`
edit this file records was **reverted before it was ever committed**, so nothing in this pack implements
it. It is `archived` so no agent acts on it as a live decision, and kept so the third attempt at this
feature leaves a record like the two before it.

**Why it was reverted.** `2026-08-04-challenge-ado-pair-report.md` found that the numbers this design
published as verified project history are arithmetically impossible against the same day's item census
for the same project: `101` `User Story → Task` edges against **96** Tasks, `20` `Feature → User Story`
against **15** User Stories, under a hierarchy that allows one parent per item. `MODE` was left unpinned
on the link query, which is the most likely cause and was a requirement of the withdrawn design that
went out with its bars.

**The correction that outlives the design.** Its prose constraint ("never predict what ADO will do")
was well-built and held. The falsehood arrived through the **mechanism** instead — a mis-joined edge
list producing false *project* history with exit 0 — where no prose rule could reach it. So this is a
third instance of the same failure as the two designs it replaced, not an escape from it: they asserted
an unexecuted premise about the service, this one asserted an executed premise whose numbers do not
reconcile, which is harder to notice because "verified 2026-08-03" sits beside it. **Constrain the
computation as well as the claim, or the constraint covers half the output.**

**What is still true and still blocked.** Everything in `## The decision, and what it deliberately
excludes` about *ADO's* verified behaviour stands — acceptance with exit 0, the `az boards query --wiql`
blank-with-exit-0 hazard, the unexecuted degradation. The original block also stands: do not design a
fourth version until the degradation probe has actually been run.

## Summary

Batch write mode's preview now reports which parent/child **type pairs** the tree needs beside the
pairs the target project has actually used, with instance counts. Zero writes, no fatal path, no new
confirmation, `8h` untouched. **It states project history and predicts nothing about Azure DevOps.**
This is the third design for this feature and the first to ship; the two before it were withdrawn.

## Context

The open thread after `docs/plans/bar-cost-and-first-run.md` change 2 was withdrawn. The plan's own
note said the surviving idea should not be designed *until the behaviour it depends on had been
executed*. The decision here is that the factual report **depends on no unexecuted behaviour**, which
is what dissolves that block rather than waiting it out.

## The decision, and what it deliberately excludes

**Included** — both reads were executed against `<org>/<project-a>` on 2026-08-03:

- The edge list via `az devops invoke --area wit --resource wiql` with a `WorkItemLinks` query
  (122 edges for `<project-a>`), joined client-side against 8c's existing in-use type map.
- The verified CLI hazard: `az boards query --wiql` returns **blank with exit 0** on that link query
  against a project that demonstrably has links. Same class as `[System.Tags] CONTAINS`.
- An unavailable read (blank, `UNKNOWN`, or the 20000-item ceiling) degrades to **silence**, never to
  a stop. The withdrawn design made it a permanent stop for any project above the ceiling.

**Excluded, and this is the load-bearing half of the decision.** The report must not state or imply
that an undemonstrated pair is forbidden, will be refused, will fail, or will degrade the board:

- ADO **accepts** an undemonstrated, hierarchy-inverting pair with exit 0 — verified (`Task → User
  Story` on `<project-a>`, accepted then removed cleanly). So a refusal-based control cannot fire.
- The **downstream degradation** — no backlog reordering, intermediate items missing from sprint
  backlogs — is Microsoft's documentation and **has never been executed here.**

## Implications

**A later reader will be tempted to add a warning to this report. That rebuilds a design that died
twice.** Both previous designs failed for one reason: each rested on an assertion about how Azure
DevOps behaves that nobody had run — first "a link needs two created items to test", then "the
template refuses a bad pair". Adding a consequence warning would be the third instance, because the
consequence is still unexecuted.

If someone wants the sharper language, the order is: **execute the degradation probe first**, then
design. Note the likely obstacle — backlog reordering is a UI-observable property and may not be
visible to `az` at all, so that probe may need the backlog REST API or a human looking at a board, and
it costs permanent items in a mode with no delete path.

This is bar-soundness row 1 in `agents/tech-lead.md` applied to a shipped feature rather than to a
bar, and row 6's instance column records the same pattern from BAR-015.

**Provenance note:** built in the lead session. `tech-lead` and `devils-advocate` were **not**
dispatched — this session is configured not to invoke agents unless asked — so this decision has had
no independent pressure-test, unlike the two designs it replaces. Recorded because that is a real
difference in how much review it received, not a formality.
