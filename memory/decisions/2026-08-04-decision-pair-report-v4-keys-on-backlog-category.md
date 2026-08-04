**Date:** 2026-08-04
**Type:** decision
**Status:** active
**Superseded-by:** n/a
**Scope:** skills/devops-azure/SKILL.md batch write mode (8c/8e preview) — design not yet implemented
**Overrides-convention:** no
**Related-to:** 2026-08-04-ado-same-category-nesting-blocks-child-reorder-only.md, 2026-08-04-challenge-ado-pair-report.md, 2026-08-04-decision-ado-pair-report-states-facts-only.md, docs/plans/bar-cost-and-first-run.md

## AMENDED 2026-08-04 after devils-advocate — read this before the table below

**Challenged in `memory/known-issues/2026-08-04-challenge-ado-pair-report-v4.md`. Verdict: build it, but
as a warning requiring acknowledgement, not a hard stop.** Three corrections land on *this file*, each
verified rather than accepted on the agent's word:

1. **`category(type)` is TEAM-scoped, and this file called it a project fact.** `team` is a **required**
   path parameter on the backlog-levels route — the verification run passed one without noticing what
   that implied — and bug placement is a per-**team** setting, so a bug type can sit in a different
   category for two teams in the same project. **This mode resolves no team at all:** verified that
   `skills/devops-azure/SKILL.md:305` resolves org, project, area path and iteration path, and nothing
   in the skill resolves a team. So "one zero-write read" quietly requires a **new resolved input**, and
   the flagship `story-type -> bug-type` row is precisely the row that moves between configurations.
   Reading one team and reporting a project verdict is bar-soundness **row 2** — a category claim on
   instance evidence.
2. **"All six agree with executed behaviour" overstates the table below.** Two rows put *reasoning* in
   the executed-truth column (`conventional`; `unconventional, different category, fine`). **No nested
   different-category child was ever reorder-tested.** So `same category => refused` has executed
   evidence in **one** category, while `different category => fine` — the direction the check relies on
   for its **silence** — has none. Every false negative this check can produce lives in the untested
   half. That is bar-soundness **row 1** applied to this file's own claim.
3. **The `SPIKE` note in open decision 4 is vacuous.** `SPIKE` maps to the *same ADO type* as `STORY`,
   so `FEATURE -> SPIKE` **is** the same type pair as `FEATURE -> STORY`, and the check can never produce
   a SPIKE-specific finding. Saying "the check finds it" credits a capability the fixed mapping makes
   impossible.

**Open decision 2 is settled:** no second confirmation. Verified that `SKILL.md:306` (8e item 2) already
carries "including any warning requiring acknowledgement", so acknowledgement is reachable **inside the
single confirmation at zero cost** — and it lands the feature inside the numbered nine that BAR-002
checks, rather than in the un-numbered bucket nothing checks. **Disposition and checkability turn out to
be the same question.** But `SKILL.md:321` **is** an edit site: the pair verdict becomes a fourth thing
that follows from the mapping.

**A precedent worth naming, which the original version of this file did not discuss:** every existing
stop in 8c–8h fires on an **observed service response** or a **reconciliation mismatch**. A stop here
would be the first on a **derived prediction** — the least reversible thing in the design.

## SECOND REVIEW 2026-08-04 — cross-model (Codex, `gpt-5.5`), read-only, exit 0

**It converged with devils-advocate on every major call, independently.** Same disposition
(warning-with-acknowledgement, not a stop), and it reproduced the *reversible-vs-irreversible asymmetry*
argument without being handed that framing — blocking a removable link while permanent item and tag
creation proceeds under a preview line is an indefensible policy boundary. It also independently arrived
at the need for an explicit third state. **Two models reaching the same conclusion from different priors
is the strongest signal this design has had**, and it is the first time any version of this feature got
one.

**Adopt these four, all new relative to the internal review:**

1. **Three states, and the middle one is not "safe".** `RISK` (both types resolve to the same category for
   the selected team) · `NO_KNOWN_RISK` (both resolve and differ — **no guarantee**) · `UNKNOWN` (a type is
   missing, ambiguous, duplicated across levels, or the read shape is suspect). **`UNKNOWN` is surfaced
   separately and folded into neither bucket.** The check may say "this pair matches a configuration
   pattern empirically observed to break reordering"; it may **never** say or imply "unflagged pairs are
   safe". Given amendment 2 — the OK direction is inferred, not executed — that phrasing constraint is
   the honest ceiling on what this check can claim.
2. **Separate the classifier from the policy.** Type→category lookup (team-scoped, predictive) should be
   architecturally distinct from disposition logic (what to do with `RISK`/`UNKNOWN`/read failure). Cheap
   now, before any text exists; it makes a later disposition change local instead of a rewrite.
3. **A failed read must not be silent.** "Degrade to unavailable and proceed" is right, but *silently*
   proceeding makes "check failed" indistinguishable from "checked and clean" — the exact failure class
   this repo keeps producing. **Proceed, yes; silently, no.** Emit a visible "backlog hierarchy risk check
   unavailable" line. This tightens open decision 3 rather than restating it.
4. **A silent default team is unacceptable, not merely under-specified.** If a team is chosen implicitly
   that choice must be visible in the preview, because the same work items are viewed through other
   teams' boards. Acceptable claim forms are scoped ones: *"using team `<team>`'s configuration, these
   links may degrade reordering on that team's boards"*, or *"no team selected, so backlog-category risk
   could not be determined"*. **"This pair is invalid for the project" is overclaiming.**

Also: the `SPIKE` alias needs **display-side normalisation**, not just corrected wording. Two logical tree
names mapping to one ADO type must dedupe in the output, or an operator reads two independent risks where
one exists. Amendment 3 called the claim vacuous; this extends it to the report's rendering.

**Framing both models endorse:** a *preflight advisory*, not a validation gate. Hard-fail on deterministic
contract violations; warn or require acknowledgement for configuration-scoped predictions and provider
quirks. Wording follows: "may degrade under the observed configuration", never "will fail".

**What Codex did not address, so these stay open rather than resolved:** the `workitemtypecategories`
trap (open decision 0), type→category being a **relation** so a type on two levels makes the inversion
order-dependent (open decision 3's third bullet — Codex folded this into `UNKNOWN` without treating
order-dependence as its own hazard), and the **precedent** question of this being the first check in this
mode to act on a derived prediction. Its recommendation implicitly accepts that precedent by shipping an
advisory rather than a stop, but it did not argue the point.

**One correction to the handoff, recorded so it does not propagate.** The synthesis characterised the
flagship `story-type -> bug-type` row as vendor-recommended parenting that the check would flag.
devils-advocate said the reverse: under *track bugs as Tasks* those types sit in **different** categories
and the check **correctly stays silent**. The real objection is narrower and still stands — that row is
the **most configuration-volatile** one in the table, so it is a poor choice of headline evidence even
though the check handles both configurations correctly.

## Summary

**The pair report finally has a mechanism that was verified before any design text was written**, which
is the one thing all three previous attempts got wrong. It keys on **backlog category**, derived from a
single zero-write read, and it was checked against six pairs — **two genuinely executed; see amendment 2
for what the other four actually rest on** — including the case a "same type" rule cannot see.

**Nothing is implemented.** This records the mechanism and the open decisions so the next attempt starts
from executed ground instead of re-deriving it.

## The mechanism, and the check that it is right

One read gives every backlog level and the work item types in it:

```bash
az devops invoke --area work --resource backlogs \
  --route-parameters project=<project> team=<team> \
  --org https://dev.azure.com/<org> --http-method GET --api-version 7.1
```

Invert it into `type -> category`. The **executed** direction is: a required parent/child pair is refused
when `category(parent) == category(child)`. **Do not write `iff`** — see the evidence column below, and
read this table as one team's configuration, not a project's.

| pair | derived | status of the "truth" column |
|---|---|---|
| `story-type -> story-type` | **FLAG** | **EXECUTED** — `SameTypeHierarchyException`, both API scopes |
| `story-type -> bug-type` | **FLAG** | **EXECUTED** — `SameTypeHierarchyException`, both API scopes |
| `story-type -> task-type` | OK | **executed for a *flat* item and for the parent** — not for a nested different-category child |
| `feature-type -> story-type` | OK | same as above |
| `epic-type -> feature-type` | OK | **INFERRED.** "Conventional" is reasoning, not a result |
| `feature-type -> task-type` | OK | **INFERRED.** "Different category, fine" is reasoning, not a result |

**Both FLAG rows are executed, and both sit in the SAME category.** No nested *different-category* child
was ever reorder-tested, so the OK direction — the direction the check relies on for its **silence** — is
inferred throughout. **Every false negative this check can produce lives in that untested half.**

The `story-type -> bug-type` row is still the reason to key on category rather than type: those are
different *types* in the same *category*, so a same-type rule reports it safe while the service refuses
it. In the team configuration that was read, the backlog-item types shared one category and the task
types shared another — **but bug placement is a per-team setting, so that grouping is exactly what varies
between teams.**

## Why this survives what killed v1, v2 and v3

- **v1** rested on "a link needs two created items to test" — false, a link target can be any existing item.
- **v2** rested on "the template refuses a bad pair" — false, ADO accepts with exit 0.
- **v3** asserted no ADO behaviour at all, but computed **false project history**: it published 101
  parent-child edges against 96 possible children. Its axis (has this project used the pair before?)
  was also uncorrelated with the harm, and *inverted* on the one case where they met.
- **v4 needs no edge list, no client-side join, no `MODE` question and no history.** Category membership
  **is** the harm's trigger — that part holds and is v4's real achievement. **But "no inference" was
  overclaimed** (amendment 2), and **"cannot be wrong about a different process template" was wrong for
  a different reason than process templates**: the read is *team*-scoped, so it can be right about the
  project's process and still wrong about the team whose board actually degrades (amendment 1).

**This is the first version permitted to predict**, because the consequence was executed on 2026-08-04
rather than taken from documentation: the child cannot be reordered at either API scope, and on the
sprint board the UI disables reordering **board-wide** and hides the **parent**.

## Open decisions — do not implement before settling these

0. **NEW, and it now precedes everything: which team's configuration is being read, and how is it
   resolved?** Until answered the derived value has no defined meaning, because `category(type)` is
   team-scoped (amendment 1) and this mode resolves no team. Area path is already resolved and does
   **not** uniquely determine a team — more than one team can include an area path. Note the trap: the
   project-scoped `wit/workitemtypecategories` route needs no team and looks like the fix, but it is
   project-scoped *by construction* and therefore cannot represent a per-team bug override — it would
   silently lose the flagship `story-type -> bug-type` row, the whole reason v4 keys on category. **Do
   not "simplify" the design into losing its best case.**
1. **Disposition — recommendation on record: warning requiring acknowledgement, not a stop.** The
   argument that changed the call: the flagged thing is a **link**, and links are the *reversible* part
   of this mode, while the irreversible half (item creation, permanent per-project tags) proceeds under a
   preview line. A stop would block the reversible half and wave through the irreversible one. Also
   "the damage is invisible afterwards" is **half false** — the *condition* is re-derivable by the same
   zero-write read at any time; what is invisible is the *board state*. **The bar for a stop is now
   specific: name a case where the remedy is unavailable to the operator.** None is on record — the UI
   warning itself names both remedies.
2. **SETTLED — no second confirmation.** `SKILL.md:306` already carries "including any warning requiring
   acknowledgement", so it fits inside the single confirmation at zero cost *and* lands inside the
   numbered nine that BAR-002 checks. `SKILL.md:321` **is** an edit site.
3. **Read failure — WIDER than first stated.** Three cases, not one:
   - the read returns nothing → degrade to "unavailable", never a stop;
   - **the read returns levels but a mapped type appears in none of them** → that type has no category.
     Naive comparison of two absent values says *equal* (false flag); one absent says *not equal*
     (silence indistinguishable from a clean verdict). **Bar-soundness row 3.** Needs a printed per-pair
     `UNKNOWN`, not a silent fallthrough;
   - the inversion assumes `type -> category` is a **function**; the schema makes it a relation. A type in
     two levels makes the result array-order-dependent, `isHidden` levels are returned and unfiltered, and
     a level id is only *"can be"* the category refname — so on an inherited process it may be neither
     meaningful nor printable.

   The positive control must also grow: "≥2 levels each with ≥1 type" is **shape-only** and cannot detect
   that the *wrong team's* configuration was read, and the response carries no team echo to check against.
   `az devops invoke` silently serves a **sibling route** when route params do not disambiguate — this
   route family is the documented instance — and the PS 5.1 `ConvertFrom-Json` double-wrap and native-arg
   mangling both apply at the parse site, the latter because a conventional team name contains a space.
4. **`SPIKE` — CORRECTED, see amendment 3.** It maps to the *same ADO type* as `STORY`, so
   `FEATURE -> SPIKE` is the identical type pair to `FEATURE -> STORY` and **the check can never yield a
   SPIKE-specific finding.** The original wording here credited it with exactly that capability. What
   remains true: if the operator maps `FEATURE` to a requirement-category type, `FEATURE -> STORY` flags
   — and that finding covers the SPIKE branch implicitly rather than distinctly. **Either correct the
   claim or drop it; do not state that the check finds SPIKE problems.**
5. **Review.** This feature has killed three designs. It should get an adversarial pass before shipping,
   and the session that verified the mechanism is not the right check on its own design.

## Reproducing

`scripts/` holds no helper for this. The derivation is ten lines: read levels, invert to `type ->
category`, compare the two categories per required pair. The verification harness used on 2026-08-04
lived in the session scratchpad and was intentionally not committed — it asserted six known answers and
would rot the moment a process template changed. **Re-derive against the target project rather than
trusting this table**; the table is evidence that the method works, not a cache of the answer.
