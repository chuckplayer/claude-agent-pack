**Date:** 2026-08-05
**Type:** constraint
**Status:** active
**Superseded-by:** n/a
**Scope:** any read of an Azure DevOps **team backlog** — `_apis/work/backlogs/{levelId}/workItems`, and the
Boards UI view it backs
**Overrides-convention:** no
**Related-to:** 2026-08-04-ado-backlog-level-is-not-work-item-type-category.md, 2026-08-04-az-devops-invoke-serves-sibling-routes.md, 2026-08-04-this-repo-is-public-never-write-real-identifiers.md

## Summary

**A team backlog filters by the team's `backlogIteration` as well as by its area paths.** Both conditions
must hold for an item to appear. Area-path ownership — including whether an ancestor area value with
`includeChildren: true` covers a descendant path — **cannot be observed without holding the iteration
constant**, because an item outside the team's iteration window is absent for a reason that has nothing to
do with area path and looks identical.

Read the window from `_apis/work/teamsettings` per team: `backlogIteration.path`. An empty string means the
**project root**, which is the permissive case — it admits every iteration. A named path such as `\I` admits
only that node and its descendants.

## Why it is dangerous rather than merely a second filter

**The two absences are indistinguishable in the response.** An item excluded by iteration and an item whose
area path the team does not own both simply do not appear in `value`; nothing in the payload says which
condition rejected it. So a run that reads a team backlog to answer an *area path* question, without stating
each team's iteration window, has not answered it — whatever it returns.

This cost a day on BAR-012 of `docs/plans/ado-pair-report-v4.md`. The 120-item batch of 2026-08-05 wrote
every item to the **project-root** iteration; the candidate ancestor team's window was a named node, so
reading those items returned nothing for that team — a false negative that reads exactly like
`includeChildren` not granting ownership. The bar was closed instead with four **pre-existing** items that
sit inside *both* teams' windows, making area path the only variable that moves. That also made the run
zero-write, which the bar required.

## Workaround

- **State each examined team's `backlogIteration` before comparing backlogs.** Treat it as a precondition of
  the read, not as context for the result.
- **Choose probe items inside every window under comparison**, rather than creating new ones — a created
  item lands on the project-root iteration by default, which is outside any narrowed window.
- **A team with a narrowed window is not a broken team.** It is ordinary configuration, on the same footing
  as the empty-`values` area configuration that `SKILL.md` 8c already prints as a benign state.
- **Ownership is not exclusive.** The ancestor and descendant teams both returned the same four items, so
  finding an item on one team's backlog does not exclude another team from owning it. Do not treat a team
  backlog read as a partition.

**Neither `skills/devops-azure/SKILL.md` nor `skills/backlog/SKILL.md` mentions the iteration condition.**
Any future team-ownership derivation in either file needs it, which is why this is recorded here rather than
left in the plan that discovered it.
