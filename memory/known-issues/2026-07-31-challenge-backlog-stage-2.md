**Date:** 2026-07-31
**Type:** finding
**Status:** active
**Superseded-by:** n/a
**Scope:** skills/backlog/, agents/backlog-auditor.md, docs/ado-delivery-pipeline-brief.md
**Overrides-convention:** no
**Related-to:** docs/plans/backlog.md

## Summary

Pressure-tested the `/backlog` + `backlog-auditor` plan (Stage 2 of the ADO delivery pipeline, branch
`feat/backlog`, seven files, two new) before any file was edited. **Eleven bars were reviewed; seven
were rewritten and a twelfth was added.** Three named evidence that cannot be produced, one was
satisfiable by the exact failure it exists to prevent, and one could only pass on a *defective*
implementation. Five stated calls had non-falsifiable halves and were labelled in place. The dominant
substantive finding is not any of the three concerns tech-lead nominated: it is that **the item cap
and audit dimension 4 contradict each other**, so the first real run that trips the cap produces an
audit that fires `High` on every story in the tree. The second is that the design's own registry call
is applied to three sections that are genuinely derived, which is what makes seam 3's stale-tree risk
as large as it is. Tested against the real 15-requirement `vendor-sync` spec: the blocking rule blocks
**7 of 15** requirements, and one of those blocks rests on a typo the spec itself records as already
resolved.

## Context

The team lead dispatched devils-advocate against `docs/plans/backlog.md` with a mandate to edit the
bars and label non-falsifiable calls in place, to aim first at three points tech-lead named as its own
weakest (the writer-less `ado_id:` field, inferred bar↔story attachment, and whether
`## Delivery waves` earns its place), and to test the plan's rules against a real spec produced the
same morning. Nothing had been built. Two factual corrections were supplied with the dispatch: HEAD is
`a62ebb0` and `memory/architecture/repo-map.md` is stamped `b6da418`, one commit stale — the plan's
`## Inputs` still names `e824bfe` as HEAD.

## Concerns Raised

### 1. The item cap and audit dimension 4 contradict each other
**Unresolved. Blocking.** Above 50 items the skill narrows **by depth** — "stop at story level, tasks
deferred". `backlog-auditor` dimension 4 fires **High** on any story with zero tasks, naming each
story. So a tree that correctly obeyed the cap is audited as defective in every story it contains, and
the operator's first experience of the audit on a large real spec is a wall of High findings produced
by the skill following its own rule. Nothing reconciles them: no frontmatter state records "narrowed by
depth", and `## Not decomposed` is prose the auditor is not told to read as an exemption. This is the
cheapest high-value fix in the plan and it is the one nobody has looked at, because the cap and the
auditor were reasoned about in different sections.

### 2. BAR-011 was satisfiable by the failure it exists to prevent, in two independent ways
**Addressed in the plan file.** (a) `grep 'REQ-001' <tree>` shows no `STORY-` line citing it — a
citation lives on its own `REQ refs:` line and *never* contains the token `STORY-`, so the grep passes
unchanged when a story cites REQ-001. (b) The bar asserted only that `REQ-001` is blocked; the stated
rule blocks seven requirements on that spec, so a run that blocks REQ-001 and silently decomposes the
other six passed. Rewritten to require the blocked set to be **exactly** `REQ-001, 008, 009, 010, 011,
013, 014` and the decomposed set exactly the other eight, checked in both directions, and to inspect
`REQ refs:` lines rather than a bare grep.

### 3. BAR-011 could only pass on a defective implementation
**Addressed.** It required `backlog-auditor` to name "at least one finding by item id with a
severity". On the run it describes — no plan handed, no reference epic — a *correct* implementation
produces **zero** findings: dimension 5 is told not to treat `Bars: none` as a defect and dimension 7
is told `unpointed` alongside `reference_epic: none` is not a finding. So the bar was passable only if
the skill or the auditor misbehaved. Split: BAR-011 now asserts a clean audit with its coverage summary
and "what I did not check" section, and a new **BAR-012** plants three defects and checks that they are
named by item id with severities.

### 4. Audit dimension 5 — the design's self-named weakest join — had no bar exercising it
**Addressed by BAR-012.** BAR-011 hands in no plan, so nothing anywhere in the bar set exercised bar
attachment, dangling-reference detection, or the wave drift check. All three shipped verified only as
*text present in a prompt file*. BAR-012 hands in this plan file itself (twelve real bars), plants
`#BAR-099` as a dangling reference, deletes one story's tasks, and desynchronises the waves.

### 5. A `Bars:` line citing a plan not handed to the audit is unverifiable, and looks like traceability
**Unresolved.** Dimension 5 resolves references "for each handed plan", and the never-glob rule means
the auditor cannot look up any other plan. The sanctioned way to attach a later cut's bars is a **hand
edit**, and nothing requires that later audits be handed the plan that edit cited. So
`Bars: cut-3#BAR-007` where `cut-3` was never handed in is silently unchecked — and the auditor is
explicitly told that missing bars are not defects. That is precisely the "unresolvable reference is
worse than a copied bar" failure the design set out to avoid, reached through its own sanctioned
repair path. Two mechanical checks would close most of it without touching the never-glob property:
report every `<plan_id>` cited in the tree that was **not** handed to this dispatch as a named
"unverified references" category, and check that every `<plan_id>` in a `Bars:` line appears in
frontmatter `plans:` — a wholly in-file comparison. Neither is in the plan. BAR-007 was amended to at
least require the auditor to *state* the scope limit in its own file.

### 6. Seam 1's registry call is right in kind and over-applied in scope
**Unresolved.** The claim that decides seam 1 is that the tree is a second registry because tree
shape, points, and dependencies "exist in no other artifact". Points and `depends_on:` survive the
strongest available test — they are human decisions, operator-confirmed, unreproducible by re-running.
Tree *shape* does not: the plan's own `## Risks` says "`/backlog` invents no numbers but it does invent
structure", which is the definition of a derived view. The artifact is a **hybrid**, and calling the
whole file a registry forbids regenerating the three parts that are purely derived: `## Coverage`
(derived from the spec's `REQ` set and statuses), `## Blocked requirements` (derived from
`## Open questions`), and `## Delivery waves` (derived from `depends_on:`). Consequence: when the spec is
amended the operator must hand-write coverage rows and blocked entries that a re-derivation could
produce mechanically, and dimension 1 fires Critical until they do. The alternative the plan never
considered — the tree is a registry, and *these three named sections* are derived views inside it that
may be regenerated in place — preserves the inherited spec-intake constraint and removes most of the
hand-edit burden that makes seam 3 risky. The plan evaluated only "regenerate everything" against
"regenerate nothing".

### 7. `## Delivery waves`' drift owner is assigned at the one moment drift cannot exist
**Unresolved.** The waves survived because their drift was given an owner: dimension 6. But the audit
runs at step 7, immediately after the tree is written, when the waves are correct by construction.
Drift arises **after** a hand edit to `depends_on:`, and the plan's own `## Risks` states that nothing
forces a re-audit. So the owner exists at creation time and is absent at every moment the risk is real.
The counter-argument for keeping the section ("a wave list nobody can read later") is also weak:
`depends_on:` is itself readable, waves are derivable by any reader on demand, and fan-out — the only
thing that would have consumed a wave grouping — is cancelled by decision. That makes waves the
second write-path-with-no-read-path in this cut. Not blocking; but the stated justification does not
hold as written, and the plan should say so rather than record the drift as owned.

### 8. `ado_id:` — the "already-emitted trees would lack it" argument is much weaker here than for a spec
**Known risk, accepted with a caveat worth recording.** The precedent cited is concern 9 of
`2026-07-30-challenge-spec-intake-stage-0.md`, which was about **lineage in a spec of record** whose
ids are permanent joins. Two disanalogies: the tree is hand-editable **by decision**, so a field added
later can be added by hand; and the field's writer must in any case parse and edit the tree to write
it, so whether an `ado_id: —` line pre-exists changes almost nothing for that writer. Against it, the
same memory file's Implications section argues the *opposite* of what the plan cites it for:
"Freezing a format against unbuilt readers is how every already-emitted artifact becomes stale the
moment a reader deviates." The plan quotes the half that supports the field and not the half that
cuts against it. Concretely at risk: whether one scalar `ado_id` per item is the right shape at all
(re-created items, an item mapping to more than one work item), and the id-freeze rule keyed to
"once any item carries an `ado_id`" — a condition that **cannot become true in this cut**, so the rule
is inert and unobservable. Also note the alternative in `## Risks` is a false dichotomy: a third option
is for batch mode to *append* `ado_id:` at first write, with no reserved line and no unbounded query.

### 9. Seam 3 does guarantee stale trees, and there is a cheap detector the plan does not use
**Unresolved, known risk.** On `vendor-sync`: one tree, written at cut 1, then ~7 spike resolutions each
requiring a spec amendment plus a tree hand-edit, plus one `Bars:` attachment per later cut, plus a
wave re-derivation after any `depends_on:` edit — none forced, none re-audited. The plan says as much in
`## Risks` and ends "nothing enforces re-running". Something cheap could: record the hash of the tree
body beside `audited:`, so a reader — and batch mode, which already must refuse `audit: not run` — can
tell mechanically that the tree changed after the audit. That converts "a reader can see the status
predates the edit" from a judgement into a lookup, and it needs no new component.

### 10. The blocking rule blocks 7 of 15 on the real spec, and one block is on an already-answered question
**Unresolved.** Applying "named inside `## Open questions`" to `vendor-sync` blocks REQ-001, 008, 009,
010, 011, 013, 014. Three of those are field- or name-level ambiguities rather than requirements the
spec leaves open: REQ-009 (message-name casing), REQ-008/014 (`companyNumber` vs `ambestNumber` for one
value), and **REQ-011, whose open question records its own resolution** — "Confirmed against the
Messaging section as `InternalBus.OperatingCompanyUpdated`, but flagged in case". REQ-011 is four of the six
workflows, i.e. the core of the feature, blocked on a diagram typo the spec already adjudicated. A rule
that blocks the centre of a spec on a resolved typo is the kind of rule that gets switched off in week
two. Also note REQ-012 (the only path that creates an RBE) is *not* blocked while REQ-008 (the store it
writes to) and REQ-014 (the API it calls) both are — so the tree will carry a buildable-looking story
whose two dependencies are unanswered questions. The plan's severity choice (an implementation story on
a blocked REQ is **Critical**) makes the false-positive cost high, not low.

### 11. The open-question matching rule is undefined, and the plan's flagship case turns on it
**Addressed in BAR-006.** The rule says a `REQ` "named inside `## Open questions`" blocks. On the real
spec, five bullets are labelled `**REQ-nnn:**` and two are labelled `**Not in either source:**` — and
one of *those* names REQ-001 mid-sentence. So a model matching on the bullet's leading label classifies
REQ-001 as an unattributed question and **decomposes it**, which is the exact outcome the plan holds up
as the reason seam 4 exists ("writing a story for REQ-001 would mean inventing the UI"). Section-wide
text matching gets it right; label matching gets it exactly wrong. Nothing in the plan says which.
BAR-006 now requires the skill to state the matching rule explicitly.

### 12. BAR-001 named README evidence that cannot be produced, twice
**Addressed.** It required `Twenty` at both `:3` and `:7`. Verified in the tree: `:3` reads
`Nineteen specialized...` (capitalised) and `:7` reads `...provides nineteen agents...`
(**lower-case**, mid-sentence) — so one literal check passes one site and silently misses the other,
which is the failure the "two sites, not one" observation was meant to prevent. Separately, all three
pinned line numbers shift, because this cut inserts an agents-table row above all of them. That drift
is already demonstrated: `docs/plans/spec-intake.md` BAR-008 pinned `README.md:71` for the skill-count
sentence and it now sits at `:72`. Rewritten to match sentences with their required casing, never line
numbers.

### 13. BAR-004's `grep -c '\baz\b' returns 1` was contradicted by the plan's own step 4
**Addressed.** `grep -c` counts **lines**, not occurrences, and step 4 mandates the prohibition
sentence, the `/devops-azure` operator pointer, *and* a Gotchas restatement — so a correct file has at
least three matching lines and the bar fails against a correct implementation. Rewritten to
`grep -n` and classify every hit, plus "no hit inside a fenced block", which is what actually
distinguishes "does not shell out" from "mentions `az`".

### 14. Two bars diffed against `main` for a file that may not exist there
**Addressed.** BAR-009 and BAR-010 used `git diff main -- <file>`. `skills/spec-intake/SKILL.md` is
new on the unmerged `feat/spec-intake` branch, and this branch's visible history shows no merge of it
into `main`, yet the plan's `## Inputs` calls that cut "merged". If the file is new relative to `main`,
`git diff main` renders it wholly added and the bar can neither pass nor fail meaningfully. Both
rewritten to diff against a `BASE` recorded before the first edit of the cut, with the merge state
named as something to record rather than assume.

### 15. Two absence claims were unbounded, and one collided with a mandated instruction
**Addressed.** "The file nowhere describes regenerating an existing tree" (BAR-005) and "Neither file
contains any instruction to search, glob, or list `docs/plans`" (BAR-008) are unbounded negatives with
no lookup target. The second is also directly contradicted by the auditor's own required
`Glob("memory/**/*.md")`. Both rewritten to enumerate-and-classify (`grep -n`, then confirm every hit
sits in a prohibition), which is checkable where a global negative is not.

### 16. Five stated calls had non-falsifiable halves; all five labelled in place
**Addressed by labelling**, following the precedent set in `docs/plans/spec-intake.md`. Of ~26 calls,
21 name a file, field, literal token, enum value, or path and are genuinely reachable by gate 4a
Tier 3. The five split calls: the **matrix three-way authority split** (binds an unbuilt cut; only
"the brief contains the sentence" is checkable); the **transport-boundary sanctioned copy** (same);
**"the points scale is inherited from the reference stories and never chosen by the skill"** (the
`Points basis:` field is enforceable, "never chosen" is a claim about a model's reasoning and a
fabricated basis line satisfies every mechanical check); the **id-freeze clause** keyed to a condition
that cannot become true in this cut; and **"routing splits on the input, not on a judgement about the
task"** (the two `Do NOT use` literals are the enforceable half). Each now carries an inline label
naming which half the gate can reach.

### 17. The 50-item cap is defensible as a number and weak as a mechanism
**Known risk.** 50 rather than `/smell`'s 20 is justified: on `vendor-sync` the tree lands near 36
items (1 feature, 8 stories, ~20 tasks, 7 spikes), so a 20-cap would fire on the motivating case and
50 would not. But the *mechanism* is weaker than the number: the cap is evaluated by the same model
that is producing the items while it produces them, so a run that narrates "48 items" while emitting 63
is undetectable — the same class as `/spec-intake`'s intake report, and inherited rather than closed.
Nothing in the audit counts items, which would be the one mechanical check available (the auditor
already reads the whole tree).

### 18. Smaller-version check
**Unresolved, worth a decision.** The materially smaller cut is `/backlog` with the auditor and
**without** `ado_id:` and `## Delivery waves` — the two write-paths-with-no-read-path in this design.
That removes one drift surface with a mistimed owner, one inert freeze rule, one auditor exemption
("an empty `ado_id` is never a finding") that exists only because the field exists, and 40+ lines of
`ado_id: —` in every emitted tree. Everything else in the cut has a reader on the first run: a human,
and the auditor.

### 19. Minor factual corrections not applied
**Unresolved, cosmetic.** `## Inputs` names HEAD as `e824bfe`; it is `a62ebb0`. It also cites
`skills/smell/SKILL.md:50-52` as "precedent for resolving a variable input target in a numbered step
1" — verified, the 20-file cap at those lines sits under `## Gotchas`, not in a numbered step. Neither
affects a call or a bar; both were left for the coordinating session so the correction is visible in
the diff rather than silently folded in.

## Implications

- **Highest-value unaddressed question is not one of the three tech-lead nominated.** It is concern 1:
  the cap and dimension 4 disagree, and the disagreement only becomes visible on the first large real
  spec — the exact run the design was chosen against. It is also the cheapest to fix.
- **Concern 6 is the one that changes a decision rather than sharpening it.** Naming three sections as
  derived views *inside* a registry preserves everything seam 1 was protecting and removes most of
  seam 3's hand-edit burden. The plan reached a binary it did not need to.
- **The bar set now has one bar that can only pass on a clean run (BAR-011) and one that can only pass
  on a planted-defect run (BAR-012).** That pairing is deliberate and should survive any later edit:
  merging them recreates the defect in concern 3.
- **`ado_id:` and `## Delivery waves` are both write paths with no read path in this cut** — the pack's
  signature failure class, twice, in one plan. Each is individually defensible; the pair is the reason
  concern 18 is worth answering out loud rather than assumed.
- **Concern 10 is a live design question, not a bar defect.** BAR-011 now pins the exact 7-of-15
  outcome deliberately, so if the human disagrees with blocking REQ-011 on a resolved typo, the bar
  fails and the disagreement surfaces before implementation rather than after the first real backlog is
  handed to a BA.
- Concern 12's method — never pin a line number in a bar whose own cut inserts lines above it — has now
  produced a demonstrated failure across two consecutive cuts. It belongs in the bar-writing guidance,
  not only in individual bars.
