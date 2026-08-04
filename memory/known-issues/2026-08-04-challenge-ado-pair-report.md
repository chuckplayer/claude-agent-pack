**Date:** 2026-08-04
**Type:** finding
**Status:** active
**Superseded-by:** n/a
**Scope:** skills/devops-azure/SKILL.md batch write mode (8c pair report, 8e informational lines)
**Overrides-convention:** no
**Related-to:** 2026-08-04-decision-ado-pair-report-states-facts-only.md, docs/plans/bar-cost-and-first-run.md

## Outcome — the design was reverted 2026-08-04, and this file stays active

**The `skills/devops-azure/SKILL.md` edit challenged below was reverted before being committed**, on the
strength of concern 1. Its decision memory is now `archived`. Two of the findings were fixed
independently of the revert because they are defects in **committed** text rather than in the reverted
design:

- **Concern 4** — `8e`'s in-band-override paragraph claimed parent/child validity follows from the type
  mapping. Corrected; it now says what does follow (the command, the tag values, and creatability per
  `VS403074`) and states that validity does not, naming the correction it survived.
- **Concern 9** — `scripts/lint-agents.sh` was run: 49 passed, 0 failed.

**Concerns 1, 2, 3, 5, 6, 7 and 8 need no further action** — each describes the reverted design, and
reverting it is the disposition. They are kept because a fourth attempt at this feature would
re-encounter every one of them, and concern 2 in particular (the demonstrated/unused axis is
uncorrelated with the documented harm, and inverts where they meet) is a defect any version of this
report inherits regardless of how its numbers are computed.

**Read this file rather than its decision memory.** The lesson in `## Implications` — that a prose
constraint cannot reach mechanism-generated content — is the durable part and generalises past ADO.

**Unrelated finding from the same verification pass, fixed alongside:** `scripts/lint-plans.sh` matched
its `## Deviations` sentinel by the case-insensitive **word** "sentinel" instead of the sentinel's
literal text, so two plans with fully written-out departure sections were reported as unfilled. Same
structured-vs-prose distinction the script's own `Gated:` check makes, missed in the same commit that
made it. See the comment at that check.

## Summary

Pressure-tested the **third** design for the ADO batch-write pair report — the factual-only version
in `8c`'s `#### The pair report` subsection plus its informational line in `8e`. The design's central
claim is that it asserts nothing unexecuted about Azure DevOps, and **the prose largely honours that.**
But the mechanism does not: the executed numbers the file publishes as verified project history
(`101/20/1`, 122 edges) are **arithmetically impossible** against the same day's recorded item census
for `<project-a>` (96 Tasks, 15 User Stories, 113 items, one-parent-per-item), `MODE` is still unpinned on the
link query after the second-pass challenge required pinning it, and the only evidence the client-side
join worked ("zero edges had an endpoint outside the type map") is satisfied identically by a join
that silently drops null-target rows. So the third design's defect is not a false claim *about the
service* — it is a **false fact about the project**, produced by the mechanism rather than by the prose,
which is exactly where the "What it must never say" constraint cannot reach. Second, the report's
demonstrated/unused axis is uncorrelated with the only harm anyone has documented (same-type or
same-category nesting) and **inverts on the one case where they meet**: a project that habitually nests
same-type items shows that pair as *demonstrated with a high count*, i.e. reassuring.

## Context

`skills/devops-azure/SKILL.md` was edited in the lead session on 2026-08-04, uncommitted at challenge
time, adding a zero-write pair report to the batch-write preview: `8c` gains
`#### The pair report — a fact about this project, never a prediction about ADO` (mechanism, two reads,
an explicit "What it must never say" constraint, a provenance blockquote), and `8e` gains a second
informational line beyond its numbered nine. `memory/decisions/2026-08-04-decision-ado-pair-report-states-facts-only.md`
was written with it.

This is the third design for the feature. The first (a first-run pause stopping after two created
items) and second (a zero-write preflight making a refused link **fatal** for an undemonstrated pair)
were both withdrawn because each rested on Azure DevOps behaviour nobody had executed. **This third
design was built with no independent pressure-test before this challenge** — unlike both designs it
replaces, which is how their premises were caught. Its own decision memory records that honestly.

## Concerns Raised

### 1. The published pair counts are arithmetically impossible, and `MODE` is still unpinned
**Unresolved. Highest-value finding.** `8c` publishes as verified fact:
`User Story → Task` 101, `Feature → User Story` 20, `Epic → Feature` 1 — totalling the 122 edges. `memory/known-issues/2026-08-03-ado-workitemtypes-lists-blocked-types.md`
records the same project on the same day as **113 items: Task 96, User Story 15, Feature 2, Epic 1**
(which itself sums to 114, not 113 — a second unreconciled number in the same evidence chain).
`System.LinkTypes.Hierarchy` allows **one parent per item**, verified and stated in this very section,
so `Hierarchy-Forward` edges are bounded by the child count per type:

- `User Story → Task` ≤ 96 Tasks. Recorded: **101.**
- `Feature → User Story` ≤ 15 User Stories. Recorded: **20.**
- Total edges ≤ items − roots ≤ 112. Recorded: **122.**

Innocent explanations exist (the item census may predate the edge read; `<project-a>` is live and BAR-015
created items in it), but they are not recorded and the join is supposed to resolve edge endpoints
*against that same type map*. The non-innocent explanation is the one the second-pass challenge already
named and the third design dropped: **`MODE` is not pinned in the shipped text.** An unpinned
`WorkItemLinks` query returns rows the join must not count as edges (null-`rel` source rows, and
recursive descendant paths under `MayContain`). BAR-004(ii) required the file to pin it; the bar was
withdrawn with change 2 and the requirement went with it rather than being resolved.

**And the check that the join worked cannot detect this.** "Zero edges had an endpoint outside the type
map" is satisfied identically by a clean join and by a join that silently drops rows with a null
target — bar-soundness row 3, and the second-pass challenge predicted this exact pair of outcomes
("drops silently or resolves into a bogus pair"). So the one observation offered as evidence of a
working join is self-confirming.

**Why this is the same defect as the two withdrawn designs, arriving somewhere less obvious.** Those
asserted a falsehood about the *service*; this asserts a falsehood about the *project*. The report's
whole warrant is "it states only facts about this project's history", so a mis-joined edge list does not
degrade it — it destroys it. The "What it must never say" paragraph constrains prose and cannot see
mechanism-generated content.

Also dropped from the withdrawn design without resolution: the plan's `## Risks` required the file to
name the **PowerShell double-wrap** hazard (`memory/context/2026-08-03-powershell-convertfrom-json-array-double-wraps.md`)
*where it specifies the join*. It is absent. Its consequence under the new design: zero resolved pairs,
so **every** required pair prints "not used in this project" with exit 0 and no unavailability line.

### 2. The demonstrated/unused axis is uncorrelated with the documented harm, and inverts where they meet
**Unresolved.** `8c` cites Microsoft for the degradation: a hierarchy **nesting items of the same type
or category** prevents backlog reordering and can hide intermediate items. The report's trigger is
"not used in this project". Those two predicates barely intersect — `Epic → User Story` is
undemonstrated in most projects and is not same-type nesting, so it is flagged while nothing documented
applies to it. Conversely a project that habitually nests same-type items carries
`User Story → User Story` with a **high instance count**, and the report marks it **demonstrated** —
presenting the one pair the documentation calls harmful as the benign state.

This is second-pass finding 2 ("the variable it keys on has no causal relation to the failure")
surviving the redesign intact. Removing the fatal path removed the *cost* of the miscorrelation, not
the miscorrelation.

### 3. The stated purpose terminates in a forbidden claim, so the prose leaks by omission
**Unresolved.** The constraint forbids saying an unused pair is forbidden, will be refused, will fail,
or will degrade the board. The surrounding prose then gives the operator a reason to act without
naming one:

- "a thing worth knowing **before an irreversible batch**" — and links are the **reversible** part of
  this mode. `relation add`/`remove` was verified reversible on pre-existing items; item creation is
  what has no delete path. The urgency is borrowed from creation and attached to the one thing that can
  be undone.
- `8e`: "**draw no conclusion** … If a required pair is unused here, the operator **may want to revisit
  the type mapping**" — two clauses apart, and the second is a conclusion. Every available justification
  for revisiting is one of the four forbidden ones.

A legitimate non-ADO reason exists and is stated nowhere: **the project's board convention is a fact
about how this team's humans read the board**, independent of what the service permits. Without it, the
report asks the operator to act on an inference the file forbids it from supplying.

### 4. `8e` still asserts that parent/child validity follows from the type mapping
**Unresolved, and it is a survivor of a defect already fixed once.** `skills/devops-azure/SKILL.md:350`
(the in-band-override paragraph) reads "the verbatim command, the tag values, and the **parent/child
validity** all follow from the mapping." Per `8c` as it now stands, **every type pair is permitted** —
nothing about validity follows from the mapping. This is the same false premise `3e320b5` removed from
`8c`, surviving four lines below the new pair-report line, in a section this change edited. What
actually changes on a remap is the pair report's *content*.

### 5. The `invoke` route's empty-result behaviour was never executed, and `8d`'s rule does not transfer
**Unresolved.** "An unavailable read degrades to silence, never to a stop" keys on the read returning
**blank** or resolving to `UNKNOWN` "per 8d's ambiguity rule". Two gaps:

- **Nobody has run the link query against a project with zero hierarchy edges.** If `az devops invoke`
  returns `{"workItemRelations": []}` with exit 0, the result is not blank, no unavailability line
  fires, and every required pair prints "not used in this project" — the **maximum-adverse, zero-
  information** output, on a fresh project, which is the normal case for a first batch.
- **`8d`'s control has no analogue here.** Its rule is "re-run the same query **without the tag
  predicate**" — a link query has no tag predicate to drop. The citation points at a procedure that
  cannot be executed for this read.

This is second-pass finding 3 (brittle exactly where it was meant to help) in a new costume: no longer
fatal, but noisiest and least informative precisely where the operator knows least. Note also that the
degrade-to-silence heading is a misnomer — the body correctly requires an explicit "the pair data is
unavailable" line, which is the right behaviour and the opposite of silence.

### 6. The report can only ever have two rows, and is blind to the one mapping `8c` flags as risky
**Unresolved, scope concern.** The tree grammar is fixed: `FEATURE → STORY|SPIKE → TASK`, and `SPIKE`
maps to **the same type as `STORY`**. So under any mapping the required pair set is at most
`{feature-type → story-type, story-type → task-type}` — two rows, fully determined by the mapping the
operator is already confirming in preview item 2, and **structurally incapable of saying anything about
`SPIKE`**, which `8c` itself names as "the one mapping most likely to be wrong". `8c`'s existing in-use
type cross-check already reports whether each of those three types has items; the report's marginal
information is only the case "both types are in use here, but never in this combination". Bought for:
one new read, a client-side join, an unrecorded JSON payload, an unpinned `MODE`, a documented
silent-failure CLI trap, and a permanent preview line — in a file where preview inflation is a named
harm.

### 7. The "beyond the nine" bucket becomes an extension point that nothing checks
**Unresolved, second-order.** `8e` promises "nine things, in order" plus informational lines beyond
them. `docs/plans/devops-azure-batch-write.md` BAR-002 checks the nine; **nothing checks the
informational lines**, so an implementation that omits the pair report entirely passes every bar in the
repo. This change is the second occupant of that bucket and the one that establishes it as the
sanctioned place to add operator-facing preview content without touching the numbered contract, the
confirmation, or any check. Related, unstated: the operator's only lever is the in-band override, which
triggers a full re-preview and therefore **re-runs both reads** — the report's cost is per preview
cycle, not per run.

### 8. The decision memory slightly overstates its evidence
**Unresolved, minor.** It lists both reads under "executed", which is true — but the file itself says
the verbatim JSON body was not recorded and puts payload confirmation on the first implementer, so the
execution is **unreproducible from the artifact**, which is weaker than "executed" conveys. "The first
to ship" describes text that is uncommitted. And it does not record that two named requirements of the
withdrawn design (pin `MODE`; name the double-wrap failure at the join) were **dropped rather than
resolved**. Its provenance note — that no agent pressure-tested it — is honest and is the best thing in
the file.

### 9. `scripts/lint-agents.sh` is a blocking gate for this changeset and nothing ran it
**Unresolved, process.** The changeset touches `skills/`, so per `CLAUDE.md` the script is blocking. It
checks frontmatter and body-existence only, and this change touches neither, so it will almost certainly
pass — but per the same rules the run must happen and be **stated**, and no pipeline ran it here.

## Implications

- **The prose constraint is well-built and is not the weak point.** "What it must never say" holds
  against the four claims it enumerates. The failure surface moved **into the mechanism**: a mis-joined
  edge list, a null-target row, or a double-wrapped parse all produce false project history with exit 0,
  and no prose rule can catch that. Any future factual-only report in this pack inherits the same
  asymmetry — **constrain the claim and the computation, or the constraint only covers half the output.**
- **Concern 1 is the reason the third design should not be trusted more than the first two just because
  it asserts less.** Both predecessors died of an unexecuted premise found by review. This one has an
  *executed* premise whose numbers do not reconcile, which is a harder failure to notice because
  "verified 2026-08-03" appears next to it.
- **Two findings from the second-pass challenge were lost with the withdrawn bars rather than
  resolved:** pinning `MODE` (BAR-004(ii)) and naming the double-wrap failure at the join (plan
  `## Risks`). When a design is withdrawn, its bars go with it — and the findings embedded only in those
  bars go too. Worth watching whenever a design is replaced rather than fixed.
- Reversibility: the SKILL.md text is easily reversible. The sticky parts are the committed decision
  memory, the `101/20/1` table becoming citable fact, and the precedent that the un-numbered preview
  bucket is where new operator-facing content goes.
