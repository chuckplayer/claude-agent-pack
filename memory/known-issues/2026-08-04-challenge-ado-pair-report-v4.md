---
date: 2026-08-04
type: finding
status: active
superseded-by: n/a
scope: skills/devops-azure/SKILL.md batch write mode (8c/8e/8i preview and report) — the fourth pair-report design, not implemented
overrides-convention: no
related-to: 2026-08-04-decision-pair-report-v4-keys-on-backlog-category.md, 2026-08-04-ado-same-category-nesting-blocks-child-reorder-only.md, 2026-08-04-challenge-ado-pair-report.md, docs/plans/bar-cost-and-first-run.md
---

## Summary

Pressure-tested the **fourth** pair-report design — derive `type -> backlog category` from one zero-write
read of the target project's backlog levels, flag any required parent/child pair where
`category(parent) == category(child)`. **The mechanism is the first one in four attempts that is keyed on
the property the service actually enforces, and that is a real advance**: v3's headline defect (an axis
uncorrelated with the harm, inverting where they met) is genuinely dissolved.

**But the derived value is team-scoped, and the design names no team.** Microsoft's own schema for the
read says the type list per level *"can be overridden by team settings for bugs"*, `team` is a **required**
path parameter on that route, and the "Working with bugs" setting is a **team** preference with three
options that move `Bug` between the Requirement, Task and Bug categories. So `category(x)` is not a fact
about the project — it is a fact about **one team's board configuration**, and two teams in the same
project can legitimately disagree. The design's flagship evidence row (`story-type -> bug-type` FLAG,
the case a same-*type* rule misses) is **Microsoft's documented recommended parenting** under
bugs-as-tasks. A hard stop keyed on this would refuse a shape the vendor recommends, on a project whose
team setting nobody read.

Second, **"all six agree" over-states the evidence.** One row of the six is labelled *conventional* in its
own "executed truth" column, and the executed record contains no reorder of a nested **different-category
child** at all — so the `iff`'s "different category ⇒ fine" direction, which is where every false
*negative* comes from, rests on inference. Third, **v3's concerns 3, 5, 6, 7 and 8 all survive** into v4
in new form; only concerns 1, 2 and 4 are actually retired.

**No verdict was reached in this session.** The five open decisions remain open; this file preserves the
concerns.

## Context

`memory/decisions/2026-08-04-decision-pair-report-v4-keys-on-backlog-category.md`, written after the
board-degradation probe was finally executed on 2026-08-04. Nothing is implemented. Three previous
designs were withdrawn: v1 (first-run pause), v2 (refused link made fatal), v3 (factual project-history
report, reverted unshipped). The design would land in `skills/devops-azure/SKILL.md` 8c/8e.

Two external references were read for this challenge rather than inferred, because the whole history of
this feature is unexecuted premises:

- `rest/api/azure/devops/work/backlogs/list` — `team` is **`path, Required: True`**; each level carries
  `id`, `name`, `rank`, `workItemTypes`, `isHidden`, `type`; and `workItemTypes` is documented as
  *"Work Item types participating in this backlog as known by the project/Process, **can be overridden by
  team settings for bugs**"*.
- `organizations/settings/show-bugs-on-backlog` — "Working with bugs" is a **team** setting (team
  administrator), three options, and under *track bugs as Tasks* the docs state *"User Stories (Agile),
  Product Backlog Items (Scrum), or Requirements (CMMI) are the natural parent work item type for Bugs."*

Both are **documentation, not execution.** They are cited as the reason a question must be answered, not
as findings about the target tenancy.

## Concerns Raised

### 1. `category(x)` is a team-scoped value and the design resolves no team
**Unresolved. Highest-value finding.** The read takes `team=<team>` and the route requires it. Batch mode
resolves org, project, area path and iteration path (`8e` item 1) and **never resolves a team** — no
environment variable carries one, and the operator is never asked. So the design as written either
hardcodes a convention (`<project> Team`), silently defaults, or acquires a new input nobody has priced.

This is not pedantic, for three compounding reasons:

- **The answer differs per team.** The bug placement override is per team, so `category(bug-type)` is
  `Requirement`, `Task`, or `Bug` depending on which team you asked.
- **The harm is also team-relative.** The executed refusal came from `{project}/{team}/_apis/work/workitemsorder`
  and the UI warning says *"same category hierarchy on **this backlog**"* — a backlog is team-scoped. So a
  pair can degrade one team's board and not another's, in one project.
- **Which team matters is decided by area path**, which `8e` item 1 already resolves: the teams that see
  these items are the teams whose area paths include the items' area path, and more than one team can.

Reading one team's configuration and reporting a project-level verdict is bar-soundness **row 2**
(category claim, instance evidence) in the design's own mechanism.

### 2. The flagship FLAG row is vendor-recommended under a different team setting
**Unresolved.** `story-type -> bug-type` is the row that justifies keying on category rather than type.
Under *track bugs as Tasks* Microsoft documents that exact parenting as natural and correct, and in that
configuration the two types are in **different** categories, so the check correctly stays silent. Fine so
far — but it means the check's verdict flips on a team setting, and **a false positive is now reachable
through ordinary configuration** rather than through a bug. v2's fatal rule died because its premise was
false; v4's premise is true, and a *stop* would still be mode-blocking on a configuration axis with no
sanctioned override. That is a new objection, not the old one restated.

### 3. "Verified against six pairs, all six agree" over-states what was executed
**Unresolved.** Row 1 of the bar-soundness table, applied to the design's own claim. In the decision
memo's table:

- `Epic -> Feature` has **"conventional"** in the *executed truth* column. That is not a result.
- `Feature -> Task` reads "unconventional, different category, fine" — reasoning, not an observation.
- The executed record
  (`2026-08-04-ado-same-category-nesting-blocks-child-reorder-only.md`) contains reorder results for: a
  flat item before nesting (control), the same-category **child** (refused, twice), the **parent**, and an
  **unrelated** item. It contains **no reorder of a nested different-category child.**

So the two FLAG rows are executed and both live in **one** category; the four OK rows are the direction
the check depends on for its silence, and that direction is inferred. **Every false negative this check
can produce lives in the untested half.** The memo's `## Reproducing` section is honest that the harness
was not committed — which also makes the six-row table unreproducible from the artifact, the same
weakness as v3 concern 8, one design later.

### 4. Disposition: a stop would protect the reversible half of the batch
**Unresolved — this is open decision 1 and the sharpest question.** The argument offered for more than an
informational line is "batch mode has no delete path, and the damage is invisible afterwards." Both halves
are weaker than they read:

- **The flagged thing is a link, and links are the reversible part of this mode.** `relation add`/`remove`
  was verified reversible; `8h` already states a failed link never invalidates the item's creation record;
  and the UI warning itself names the two remedies (remove the parent link, or change it to `Related`).
  Meanwhile the genuinely irreversible half — item creation and permanent per-project tag values —
  proceeds under a preview line. A stop that blocks the reversible thing while the irreversible thing is
  waved through has the asymmetry backwards. **This is v3 concern 3 (urgency borrowed from creation and
  attached to the reversible thing) surviving into v4 attached to a true premise.**
- **"Invisible afterwards" is false for the *condition*.** The same zero-write read re-derives it at any
  later time. What is invisible is the **board state** (sprint-wide reorder lockout, hidden parent). Say
  the narrow thing.

`8e` item 2 already carries "every gate verdict from 8a here, **including any warning requiring
acknowledgement**" (`skills/devops-azure/SKILL.md:306`), so an acknowledgement is reachable **inside the
single confirmation** and costs no second one. A stop is defensible only if someone can name a case where
the remedy is unavailable to the operator; none is on record.

### 5. The inversion assumes `type -> category` is a function; the schema makes it a relation
**Unresolved.** `workItemTypes` is a list per level, the bug override moves a type between levels, and
levels carry `isHidden`. Three unspecified cases:

- **A type present in two levels** makes "equal category" ill-defined, and a first-match inversion makes
  the verdict depend on array order.
- **`isHidden: true` levels** are returned by the read. Filtering them or not changes the map, and the
  design says nothing.
- **A level `id` is documented as "for Legacy Backlog Level from process config it **can** be categoryref
  name"** — so on an inherited process with a custom level the id may not be a category reference name at
  all. Equality still works as a test; a preview line printing the id may print something meaningless.

### 6. A type absent from every level has no category, and null == null must not read as "equal"
**Unresolved. Bar-soundness row 3.** Open decision 3 covers only "the read returns nothing". It does not
cover the read succeeding while the **mapped types are not in it** — a custom process type, a type on no
backlog level, or a level hidden for the team. Two failure paths, both silent:

- Both types unresolved → a naive comparison finds them **equal** → a false flag.
- One resolved, one not → **not equal** → silence, indistinguishable from a clean verdict.

The design needs a third per-pair state (`UNKNOWN`) that is printed, or its silence is produced
identically by the property holding and by the map missing the types.

### 7. The positive control is shape-only, and the parse hazards are unnamed at the site that parses
**Unresolved. v3 concern 5 surviving.** Open decision 3's control (at least two levels, each with at least
one type) tests **shape**, and the same call is both test and control — it cannot see that it read the
**wrong team's** configuration, and the response carries no team echo to check against. `8d`'s
drop-the-predicate control still has no analogue here, exactly as in v3.

Also dropped-not-resolved, again: this repo documents three hazards that all apply to this read and none
of which the design names at the point of the parse — `az devops invoke` silently serving a **sibling
route** (this route family is the documented instance), `@($json | ConvertFrom-Json)` **double-wrapping**
on PowerShell 5.1, and PowerShell **mangling native arguments** (the team name contains a space in the
conventional form). v3's challenge flagged the double-wrap requirement being lost with the withdrawn
bars; it is lost again.

### 8. Open decision 4's `SPIKE` claim is vacuous
**Unresolved, minor but it would ship as operator-facing text.** `SPIKE` maps to **the same ADO type as
`STORY`** (`8c`). So `FEATURE -> SPIKE` is the same type pair as `FEATURE -> STORY`, and the check can
never produce a `SPIKE` finding that the `STORY` row does not already produce. Saying "the check finds the
SPIKE case" is true only in the sense that it finds the `FEATURE` mapping error; naming it as a SPIKE
catch tells the operator the check has a capability it does not have.

### 9. Disposition and checkability are the same question
**Unresolved.** `docs/plans/devops-azure-batch-write.md` BAR-002 checks the **nine** numbered preview
items. Nothing checks the un-numbered informational bucket, so a report shipped as a tenth line is
omittable and every bar in the repo still passes — v3 concern 7, unchanged. Folding it into item 2 as an
acknowledgement puts it **inside** the checked nine. So the disposition choice determines whether anything
can ever enforce the feature, which is worth deciding on purpose rather than as a side effect.

### 10. This is not "one read and one preview line"
**Unresolved, scope.** Priced honestly it is: a new resolved input (team) with a display site in `8e`
item 1; an `UNKNOWN` state; edits to `8c`, `8e` and probably `8i`; a fourth thing that follows from the
mapping, which makes `8e`'s in-band-override list (`skills/devops-azure/SKILL.md:321`) an **edit site** —
open decision 2 says step 7 and 8e's single-confirmation rule are not edit sites, which is correct, but
that list is a third thing and it is. Possibly the environment contract and the delivery brief too.

Against that: **under the sanctioned default mapping the check can never fire.** Its entire yield is
catching a bad operator **override** — and an override triggers a full re-preview, so the read runs again
per cycle. That may still be worth it. It should be decided knowing the yield is one class of operator
error, not a general safety net.

### 11. What the check does not cover, and the health claim it must not make
**Unresolved.** The resume hole is **smaller** than it looks: a matched item whose ADO type diverges from
the mapping is already a STOP during 8d reconciliation (`8c`, and the comparison happens in 8d's pass), and
a matched item whose ADO parent differs from the tree's is already a STOP in `8h`. So the repair-path link
add is covered by the same mapping the check reads.

What is **not** covered: **pre-existing nesting the run neither creates nor touches** — the tree's root
matched to an item that already sits under a same-category parent. The report then flags nothing while the
board is already degraded. So a line reading "no same-category pairs" must be scoped to *the pairs this
tree requires*, or it becomes a board-health claim the read does not support.

### 12. The cheaper project-scoped read is a trap, and should be rejected consciously
**Unresolved, informational.** `GET {project}/_apis/wit/workitemtypecategories` needs **no team**, returns
`referenceName` plus `workItemTypes` per category, and looks like the obvious way to avoid concern 1. It
is the **wrong** read: it is project-scoped by construction, so it **cannot represent a per-team bug
override**, and the pair the whole design exists to catch is exactly the one that override moves. Recorded
so a later reader does not "simplify" the design into losing its flagship case.

### 13. Process gates on the changeset
**Unresolved, process.** Editing `skills/devops-azure/SKILL.md` makes `scripts/lint-agents.sh` **and**
`scripts/lint-identifiers.sh` blocking, and both runs must be stated. Separately: the v4 decision memo's
category table is the artifact most likely to become citable fact — v3's `101/20/1` table did exactly
that. Qualifying it as one team's configuration is cheap **now** and expensive after it is cited.

## Implications

- **The advance is real and should not be lost in the concern count.** v4 is keyed on the property the
  service enforces. v3 concerns **1** (impossible counts, unpinned `MODE`), **2** (uncorrelated axis) and
  **4** (`8e`'s false validity premise, fixed in committed text) are genuinely retired. Concerns **3, 5,
  6, 7, 8** survive in new form. A redesign retiring three of nine is progress; it is not a clean slate,
  and the surviving five are the ones that were never about the mechanism.
- **The failure surface moved once more.** v1/v2 asserted unexecuted service behaviour. v3 computed a
  false fact about the project. v4 computes a **true fact about one team** and is at risk of reporting it
  as a fact about the project. Each generation's defect is one level subtler than the last, and each was
  found by review rather than by the design's own checks.
- **`8c` line 219 says "Do not restate the mechanism from memory; the mechanism is what keeps being wrong
  here."** A preview line is a runtime restatement of that mechanism to an operator. Whatever ships must
  state the narrow, surface-qualified consequence (REST refuses the child's reorder at both scopes; on the
  sprint board the UI disables reorder board-wide and hides the parent) and must not reach for the broad
  version that has now been wrong three times.
- **Reversibility:** the SKILL.md text is easily reversible. The sticky parts are the committed decision
  memo, the category table becoming citable, and — if a stop ships — the precedent that this mode stops on
  a **derived prediction** rather than on an observed ADO response or a reconciliation mismatch. Every
  existing stop in 8c–8h is one of the latter two. That precedent is the least reversible thing in the
  design and is not discussed in it.
