**Date:** 2026-08-03
**Type:** finding
**Status:** active
**Superseded-by:** n/a
**Scope:** skills/devops-azure/SKILL.md, skills/backlog/SKILL.md, agents/backlog-auditor.md, docs/ado-delivery-pipeline-brief.md
**Overrides-convention:** no
**Related-to:** docs/plans/devops-azure-batch-write.md

## Summary

Pressure-tested the batch-write plan (Stage 2's ADO write path, branch `feat/devops-azure-batch-write`,
six files, none new) before any file was edited. **Fifteen bars were reviewed; nine were rewritten and
two were added. Five stated calls had non-falsifiable halves and were labelled in place.** Two bars
named evidence that does not exist in the tree, one of them satisfiable by the exact failure it exists
to prevent. The dominant substantive finding is not a bar defect: **the plan's `## Risks` contradicts its
own four-row reconciliation table.** Risks says that when a human deletes the recovery tag but the tree
write-back landed, "recovery is unaffected"; row 4 of the table makes that state a **stop for the whole
batch**, with no sanctioned path forward and an obvious operator move (delete the tree entry) that
reaches the `create` row and produces the duplicate the table exists to prevent. Second: **the WIQL key
query — the single mechanism the entire resume design rests on — is never verified, and BAR-014's
negative evidence used that same unverified query as its own falsifier**, so a broken query form would
have read as proof that nothing was created. Third: the compensating control the brief and the plan both
call *load-bearing* — per-item result reporting — was the one thing no bar checked.

## Context

The team lead dispatched devils-advocate against `docs/plans/devops-azure-batch-write.md` with a mandate
to edit the bars and label non-falsifiable calls in place, and deliberately withheld tech-lead's
self-assessment so this pass would be uncontaminated. Independent judgement was requested on five
points: the resume design's reliance on a tracker query, partial-write survival, one confirmation for
the whole batch, the non-persisted type mapping, and whether the cut is too large. Nothing had been
built. Verified during the pass: HEAD `7748e8d`; `memory/architecture/repo-map.md` stamped `40a0b2e`;
`skills/devops-azure/SKILL.md` is 109 lines with the write-op gotcha at `:108`; README counts read
`Twenty` (`:3`), `twenty` (`:7`), `Twenty-nine` (`:74`).

## Concerns Raised

### 1. `## Risks` contradicts the four-row table, and a removed tag bricks every later run
**Unresolved. The highest-value finding in the pass.** Risks: "If the write-back landed, the tree still
holds the id and recovery is unaffected." Row 4 (`external_refs:` present, key not found) is a **stop**,
and "the item with its tag removed" is explicitly one of the three states it reports. So one tag removed
by a human who has never heard of this pack halts creation of every remaining item in the tree, not just
that one — and the mode never updates a work item, so it cannot re-add the tag. The only operator move
that clears the stop is deleting the tree entry, which reaches row 1's `create` case and double-creates.
Risks discusses only the *narrow* unrecoverable case (tag deleted **and** write-back never landed) and
misdescribes the broad one. Recorded in BAR-004(iv): the file must name the path forward (a human
re-adds the tag in ADO) or the bar fails, and the Risks sentence must be corrected with it.

### 2. The WIQL key query is unverified, and BAR-014 used it as its own falsifier
**Addressed in the bar; the design residual is unresolved.** Recovery rests entirely on
`[System.Tags] CONTAINS '<feature>:'` — a *partial*-tag match containing a colon. `## Risks` names the
colon-in-a-tag question and turns it into the round-trip probe, but names the **query** question nowhere;
the probe verifies the write and nothing verifies the read. BAR-014's negative half ("no work item was
created — verify by the same WIQL key query, returning zero rows") is satisfied identically by a query
form that does not work. Rewritten to require the invocation to **succeed** with well-formed empty JSON
(`$LASTEXITCODE` 0, not blank per the machine known-issue), which distinguishes "nothing tagged" from
"query malformed", plus a positive check against a known-tagged item where BAR-015's gate is met and an
explicit record that the query form ships unverified where it is not.

### 3. The query's identity function is unspecified, so a substring feature slug silently under-creates
**Addressed in BAR-004(i).** The plan states the query and then keys four dispositions on "key found",
never saying that a returned row counts only when its tag set holds a member **exactly equal** to
`<feature>:<item-id>`. `CONTAINS` is a substring filter: a run for feature `rbe` matches items tagged
`vendor-sync:STORY-3`, classifies them as already created, and **skips** them. Silent under-creation is
the failure the whole table exists to prevent, and it passes every other check in the bar.

### 4. The table has no row for an ADO key matching no item in the tree
**Addressed in BAR-004(ii).** Causes are ordinary: a renumbered id (forbidden but not enforced — the tree
is hand-editable), the wrong `<feature>`, a tree item deleted after creation. The table covers a
duplicate key but not an orphan key, and as written the mode proceeds silently past it.

### 5. The write-back-failure report instructs the exact act the inherited rule forbids
**Addressed in BAR-005; the decision is open.** On write-back failure the mode "reports the ADO id and
the exact `external_refs:` block for the operator to paste". `docs/plans/backlog.md:922-924` names an
`external_refs:` entry as one of exactly two things the operator never hand-edits, and
`skills/backlog/SKILL.md:230` puts that sentence into **every emitted tree** — so the operator is told
to violate the artifact they are editing, while the plan's own duty matrix asserts that rule is
"untouched". The design already holds a strictly better route it did not notice: **re-run, and row 1
repairs the entry** — its own repair path, no new machinery, no new permission. Either that, or a
labelled narrowing of the inherited rule.

### 6. The load-bearing compensating control had no bar
**Addressed by a new BAR-016.** The brief (`:171-177`) and this plan both name **per-item result
reporting** as the load-bearing replacement for the per-write confirmation that step 7 gives up. The
preview it replaces has BAR-002; section 8i's report had nothing. BAR-016 also requires the run to
reconcile the count of `az` write invocations it actually made against the count the preview stated —
without which the previewed count is decoration and the operator confirmed a number nothing ever checks.

### 7. One confirmation plus an in-band type override invalidates the confirmed preview
**Unresolved, labelled in place.** The single confirmation bundles four judgements into one answer:
proceed, confirm-or-override the type mapping, accept the `SPIKE` mapping, and acknowledge
`audit: findings open`. If the operator overrides the mapping, the preview they just read is stale in its
type mapping, its verbatim `az` command, and possibly its link validity — and no second preview is
specified. An audit acknowledgement discharged by the same "yes" that starts the batch is weaker than the
plan claims.

### 8. Type divergence on resume is named and then has no disposition
**Addressed in BAR-008.** The plan surfaces an already-created item whose type differs from this run's
proposal "in the preview" and stops there. Parent/child validity in ADO is constrained by the process
template's type hierarchy, so a tree holding a `User Story` parent from run 1 and a
`Product Backlog Item` parent from run 2 can fail the link pass at a specific item and stop the batch
mid-run. The file must state either "divergence is a stop during reconciliation" or "mixed types are
accepted and links may fail". Also: `az devops invoke --area wit --resource workitemtypes` returns the
type **list**, not the hierarchy, so if the hierarchy is not discovered the file must say the link pass
learns it by attempting a link and failing.

### 9. `System.Tags` pollutes a tag namespace, and that is the objection that killed the title prefix
**Scope overstated — tags are per-project, not org-wide.** The argument below is left exactly as it was
written, both of its "org-wide" claims intact, because this file records what devils-advocate argued and
editing the argument would misrepresent it. The verified scope, and the part of the concern that
survives, are in the correction block at the end of this section. **Read that before acting on
anything here.**

**Unresolved, labelled.** Every created item adds a tag value visible in tag autocomplete to **every user
in the org** — a 36-item tree adds 36. The four rejected alternatives were all evaluated on
queryability; a title prefix was rejected specifically because it "pollutes the board", and the same
objection applied to the chosen field is unexamined. The choice may still be right, but the preview
should say so out loud, and BAR-015's gate is not "throwaway items" — the mode has no delete path, so it
is permission to create ~10 permanent work items plus ~10 permanent org-wide tags. *(This is the sentence
that propagated into BAR-015's consent gate. `org-wide` is its false half — the permanence, and the absent
delete path that makes it permanent, are not.)*

> **Correction, 2026-08-03 (after BAR-015 ran): the scope above is wrong — ADO work item tags are
> per-project, not org-wide.** Verified against `<org>`: `<project-a>` held one tag value and `<project-a>`
> seventeen, and each tag's REST URL is namespaced by the project GUID (`/_apis/wit/tags/` under the
> project id). A 36-item tree adds 36 tag values to **one project's** autocomplete, not the
> organization's. The concern's *substance* survives intact and is why this note amends rather than
> deletes it: the pollution cost is real, it was genuinely unexamined against the same objection that
> killed the title prefix, and **"throwaway" is still the wrong word** — the mode has no delete path,
> so what the operator grants is permission to create items and tag values this pack cannot remove.
> Only the blast radius was overstated. Fixed in `skills/devops-azure/SKILL.md` 8e item 8 and 8f, in
> `docs/ado-delivery-pipeline-brief.md`, and in the plan's `## Risks` and BAR-015 text — see
> [[2026-08-03-ado-workitemtypes-lists-blocked-types]] for the other correction the same run forced.

### 10. BAR-012 named evidence that does not exist, and passed on a two-of-three fix
**Addressed.** `grep -n 'does not exist yet' skills/backlog/SKILL.md` returns **two** lines, `:12` and
`:419`. The third site is line-wrapped — `:250` ends `...which does`, `:251` begins `not exist yet.` So
`grep -c 'does not exist yet'` returning **0** is satisfied by an implementation that fixed two sites and
left the copy-ready block still telling every emitted tree that batch mode does not exist. Second defect,
independent: the bar required "no hunk inside the copy-ready block", but `:250-251` sits **inside** that
block (`:205-346`), so the clause could only be satisfied by leaving the false statement in place.
Rewritten to `grep -n 'not exist yet'` returning 0 plus a diff confined to three sites with the shape
documentation byte-unchanged. Also switched the README count check to `git diff -U0` so a nearby
unchanged count sentence cannot fail the bar as a context line.

### 11. Two bars titled as behaviour while their evidence is textual
**Addressed by retitling.** BAR-003 ("its round-trip **is verified**") and BAR-005 ("**verified by**
read-back") are `files ->` bars: they check that a prompt file specifies a probe. A reader reporting
PASS has not verified that a colon survives an ADO tag. Both now say "the file **specifies**" and point
at the gated BAR-015 sub-check that exercises the behaviour.

### 12. BAR-006's absence check was self-exempting
**Addressed.** `grep -c 'ado_id' ... returns 0 unless the hit is a statement that the field does not
return, in which case classify it` has two defects: `grep -c` counts lines, and "returns 0 unless…" lets
the reporting agent reclassify any nonzero result as compliant. Both are
`2026-07-31-challenge-backlog-stage-2.md` concern 13 one cut later. Rewritten to `grep -n` plus an
expected hit set written down before the check runs.

### 13. BAR-014 stated a gate with no verdict; BAR-015(b) asked for an unperformable action
**Addressed.** BAR-015 says a failed gate returns NOT RUN; BAR-014 said only "gated on…", so a run
hitting a missing `az` had no sanctioned outcome and the available move was to let twelve passing text
bars imply coverage. BAR-014 now carries the same explicit NOT-RUN verdict and records the gate result
either way. BAR-015(b) asked the operator to "interrupt after two creates" — no mechanism exists for
interrupting a model-driven loop at a defined point — and then simulated the resulting state by hand
anyway, making the interrupt redundant. Rewritten to the deterministic form: complete a run, hand-delete
one `external_refs:` entry, re-run.

### 14. BAR-013's producibility gate was half-named
**Addressed.** The bar names the post-`install.sh` session gate but not the installer gate: on this
machine a blank result from the installer is tool breakage
(`2026-07-10-bash-tool-silent-failure-windows.md`) and the installer is already recorded as silently
skipping a block non-interactively (`2026-07-29-install-sh-silently-skips-obsidian-block-noninteractive.md`).
The bar's first step is now to read the **installed** agent copy back and confirm the new check is in it,
so "the check is absent" cannot read as "the installer never ran".

### 15. The link pass had no producible bar, and it is the seam if the cut is narrowed
**Addressed by a new two-state BAR-017; the scope decision is unresolved.** `## Risks` names the
dependency-link pass as the widest part of the cut and the first thing to cut, and it had no `files ->`
bar at all — its only verification sat inside the gated BAR-015(a). It also has no reader: `/implement`
takes one story, fan-out is cancelled by decision, and the matrix joins on ids. Cutting it removes a
second partial-failure surface, one discovered-not-known API name, the skipped-by-name path, and part of
the previewed write count, and costs nothing any consumer reads. **Parent/child links should stay** —
without hierarchy the result is a pile, and the plan's argument for that holds.

### 16. Five calls were non-falsifiable in part; all five labelled in place
**Addressed by labelling**, following the precedent in `docs/plans/backlog.md`. Of ~28 calls, most name a
file, field, literal token, or enum value and are reachable by gate 4a Tier 3. The five split calls: the
**no-string-concatenation rule** (the stated rule and the quoted-title clause are enforceable; "never
built by concatenation" is a claim about runtime assembly no artifact records); **tree-text-is-data**
(the stance sentence is enforceable, "never obeyed" is a claim about model reasoning); the **100-item
cap** (the literal and the refusal are enforceable, the *count* is computed by the same session about to
make the writes — concern 17 of the previous challenge, now with work items as the blast radius, and the
uncosted mechanical check is a `grep -c` of item-id lines); the **fan-out restatement** (presence is the
enforceable half; it binds a human and a later invocation); and the **preview contract** (the nine items
and `preview only` are enforceable, the preview's *accuracy* is not, since the session that produces it
executes it).

### 17. Alternatives that were never named, and should be consciously rejected rather than skipped
**Unresolved.** (a) **A write-ahead run journal** outside the tree — intent written before each create,
result after. It closes the crash window to zero rather than to one item and works even if the tag
mechanism fails entirely, which is precisely the unverified half. It probably *should* stay rejected
(a new file with no reader, in a repo where merge-reviewer's `git add -A` would sweep it into a commit),
but the plan rejected it by silence. (b) **A per-feature anchor work item**, with every created item
linked to it and enumeration by an ID-scoped read of the anchor's relations. That sidesteps both weak
points at once — no WIQL `CONTAINS`, and relations are far less likely to be casually deleted than tags
— at the cost of one extra work item per feature. Neither is advocated; both should be rejected on
purpose.

### 18. The field choice becomes irreversible for existing items on the first production run
**Unresolved, disclosure.** Because the mode never updates a work item, changing the recovery field later
recovers nothing already created. Risks names "a second key location" as the escalation, which is
additive and helps new items only. That raises the stakes on running BAR-014 and BAR-015 **before** any
production use rather than after.

### 19. Factual corrections left for the coordinating session, per the previous cut's precedent
**Unresolved, cosmetic.** `## What ships` item 2 quotes `:250` as a one-line phrase that is line-wrapped
in the file. `### Step 2` claims the copy-ready block at `:205-346` is byte-unchanged and, two sentences
later, requires editing `:250` — which is inside it. `## Inputs` puts the README slash-count sentence at
`:72`; it is `:74`. And the proposed `CLAUDE.md` clause states batch mode "passes no `plan_id`, and
enters no gate", creating a second home for that fact outside the **Plan spine** section — the same
confusion the existing `/backlog` paragraph in that section was written to prevent. Left visible in the
diff rather than folded in silently.

## Implications

- **The two findings that change a decision rather than sharpen it are 1 and 5.** Both are cases where
  the plan's prose asserts a property its own mechanism contradicts, and both have a fix already present
  in the design: for 1, name the human-re-adds-the-tag path; for 5, use row 1's repair instead of a paste
  instruction. Neither needs new machinery.
- **The resume path is this cut's charter and the part most likely to ship unverified.** It rests on one
  query form nothing checks, and its only behavioural bar (BAR-015) may legitimately return NOT RUN. If
  it does, the reconciliation table, the repair row, the round-trip probe, and the query all ship as
  prose. That belongs in the merge record, not only in a bar.
- **The bar set now has one bar with two satisfying states (BAR-017).** That is deliberate: the scope
  decision on the dependency-link pass is the lead's, and the bar should not force the wider version by
  existing.
- **A `files ->` bar can only ever prove a prompt file says something.** Twelve of seventeen bars here are
  that, which is the honest ceiling for a markdown pack — but two of them were *titled* as behavioural
  checks, and that is how a pack accumulates verified-looking coverage of behaviour nobody ran. Retitling
  is cheap; the pattern is worth watching in every later cut.
- **Concern 12's grep defect and concern 10's line-number-wrapping defect are both repeats.** The
  previous challenge recorded `grep -c` counting lines and never pinning a line number; both returned here
  in new clothing. A wrapped phrase defeating a grep is the new variant worth adding to bar-writing
  guidance: **check a phrase a file may reflow with a pattern short enough to survive the wrap.**
