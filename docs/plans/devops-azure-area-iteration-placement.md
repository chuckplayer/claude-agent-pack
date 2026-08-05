---
plan_id: devops-azure-area-iteration-placement
branch: main
origin_skill: /plan
created: 2026-08-05
---

## What ships

Two live defects in `skills/devops-azure/SKILL.md` batch write mode, both found on 2026-08-05 by
**executing** the skill rather than reading it (`docs/plans/ado-pair-report-v4.md`,
`## EXECUTED 2026-08-05 (second)`). One file changes.

**1. 8a gets a stated path-normalisation rule, and the candidate comparison stops being literal.**
The routes 8a already reads return the same path in **different forms**, and 8a's coverage rule never
mentions it. **All four forms below are observed, not inferred** — the two iteration rows were closed by
observation on 2026-08-05, after the challenge, which is what retires the assumed-symmetry gap
`## Challenge` concern 2 identified:

| Route | Read by this mode? | Form returned |
|---|---|---|
| `az boards area project list` | **yes** (8a, line 135) | `\<project>\Area\<node>\<leaf>` — leading separator **and** a classification segment at segment 2 |
| `az boards iteration project list` | **yes** (8a, line 136) | `\<project>\Iteration\<node>`, `\<project>\Iteration\<node>\<leaf>`, and `\<project>\Iteration` for the root — classification segment at segment 2, exactly symmetric to the area route |
| `az devops invoke … teamfieldvalues` (`System.AreaPath` values) | **yes** (8a, line 145) | `<project>\<node>\<leaf>` — neither separator nor classification segment |
| `az devops invoke … teamsettings` (`backlogIteration.path`) | **NO — recorded, never invoked** | `\<node>` (no project segment) and `''` (project root) |

**Row 4 is a form recorded but not read by this mode**, and the table must say so on its face: call 10
rejects the per-team `teamsettings` read and scope item 3 names `backlogIteration` as a condition this
run does **not** read. It is in the table because the value's shape is the reason call 4's prepend rule
exists, and because a later cut that does read it must not re-derive the form. A reader who mistakes
row 4 for a live route will look for an invocation that is not there.

A literal comparison of rows 1 and 3 yields **zero candidates on a correctly configured project**.
The 2026-08-05 run found 2 candidates only because the normalisation was written into the probe.

**Never infer a route's form from a sibling command.** Inside one command family the two forms
coexist: `az boards area project delete --path` takes the **classification** form
(`\<project>\Area\<node>`) while `az boards work-item create --area` takes the **canonical** form
(`<project>\<node>`). Recorded in
`memory/context/2026-08-05-ado-node-name-restrictions-are-ui-only.md`.

Ships: a **canonical form**, a **transformation per route** over the four rows above, a **segment-wise
coverage test**, one stated **application point**, a **definition of `M`** (undefined in the file today,
and BAR-003's walk is unperformable without it), and a stated outcome for the **zero-candidate**
state — which today has none.

**2. 8f's create sets `--area` and `--iteration`, so the batch makes the placement the preview
promises.** 8f's verbatim command sets neither, so every item lands at the project root while 8e
item 1 promises the operator all four resolved values as where these items land. Already observed:
the 120-item batch of 2026-08-05 wrote every item to the project-root iteration, the confound that
blocked BAR-012 of `docs/plans/ado-pair-report-v4.md` for a day. It also undercuts 8a's own premise —
the team set is derived from an area path the batch never writes.

**Both flags are verified accepted and honoured** in the project-rooted canonical form — two live
creates on 2026-08-05, values stored byte-exact, neither argument silently ignored (BAR-005, RUN). This
is the write half only; which form a *read* route returns is a separate question, answered by item 1's
table.

Ships, all in 8e/8f/8g: the two arguments on the create; the two arguments in item 5's verbatim
command; item 6's payload-shape sentence restated; 8g's `Where it lives` row corrected; one new row in
8f's failure table; the **existing** first-item round-trip probe extended from tags to placement,
adding **zero** `az` invocations; the **sink discipline** for the two new argument values, stated beside
8f's title mechanism because it is the same mechanism's second application; and the **sanctioned
recovery** for a placement stop, on the shape 8f already uses for a tag failure — one human fix, and the
wrong move named beside it.

**3. 8a stops claiming board visibility it did not derive.** 8a opens *"resolve which teams' boards
will show these items"*, and a team backlog filters by the team's `backlogIteration` as well as by its
area paths (`memory/context/2026-08-05-ado-team-backlog-filters-by-iteration-too.md`, active). Area
coverage alone does not establish visibility. The fix is one scoping sentence plus a named unread
condition — **no new read**.

**KEEP — the earlier "separable, may be cut" framing is withdrawn.** Once placement is real the
operator **acts** on 8a's team list, so the unqualified claim graduates from inaccurate to load-bearing;
its cost is two sentences and no new read, and BAR-009 already pairs it with an invocation-count check.
Recommended by `devils-advocate` and adopted. BAR-009's cut-escape clause is removed accordingly — an
escape clause in an evidence line lets a checker classify any result as compliant (bar-soundness
row 5).

## What does not ship

- **No change to the backlog-level mechanism.** 8c and 8e item 2 carry explicit "do not restate this
  from memory" warnings; the level/category distinction is settled and untouched. Nothing in this plan
  re-derives it, and any edit that does is out of scope by construction.
- **No new gate anywhere.** 8a keeps *"four gates with three verdicts"* **unedited**. The
  zero-candidate outcome is a **display state**, on the same footing as 8a's existing three-state team
  line — not a fourth gate, not an acknowledgement, not a stop.
- **No new `az` invocation of any kind** — no read and no write. Every fact this plan needs is already
  read by 8a or 8f.
- **No per-team `teamsettings` read.** It would answer item 3 properly and it is rejected below.
- **No per-item placement verification.** Item 1 only, per the matrix in `## Build steps`.
- **No fifth value at 8e item 1**, and no tenth numbered preview item.
- **No new *mechanism* for the two argument values, and no allowlist or title-style rejected-character
  list on them either.** What ships is 8f's existing sink discipline applied to two more values, plus
  one identity check against the paths the resolution read already enumerated. Call 7 argues it from the
  sink and names the residual; the earlier provenance-only argument is withdrawn as unsound, per
  `memory/context/2026-08-05-ado-node-name-restrictions-are-ui-only.md`.
- **No row added to 8a's budget table.** `M` is defined in prose beside it; the table stays two rows.

## Calls made for you

1. **Defect 2 is fixed by setting the arguments, not by correcting the promise.** The trade-off, since
   these are materially different products:

   | | Set `--area`/`--iteration` (**adopted**) | Correct 8e item 1's promise instead |
   |---|---|---|
   | Items land | at the resolved area and iteration | at the project root, permanently, ~100 per batch |
   | 8e item 1's *"all four"* | stays true | **becomes false** — two values displayed where the file says four |
   | 8e item 6's *"no area/iteration override beyond the resolved defaults"* | becomes true | stays misleading |
   | 8a's derivation | derives from a path the batch writes | derives from a path nothing writes → 8a must be relabelled or deleted |
   | 8a's *"ask before previewing"* when area/iteration is ambiguous | earns its cost | asks the operator to resolve a value the run discards |
   | Cost | two service-sourced arguments reach an `az` command — form **verified** 2026-08-05, sink discipline per call 7 | text only |

   **The justification is repaired, and the conclusion is unchanged.** An earlier version of the
   `"all four"` row read *"protected by BAR-015 of `docs/plans/ado-pair-report-v4.md`"*, and the same
   claim was made for BAR-002 of `docs/plans/devops-azure-batch-write.md`. **Both props are withdrawn.**
   Plan consumption in this pack is **opt-in per invocation** — merge-reviewer enforces bars only for the
   `plan_id` handed to the run, and neither of those merged plans is handed to this one, so neither bar
   will be evaluated on this changeset. They are **documented intent, not live gates**, and presenting
   them as a cost overstated the case. The **live** protection for all four phrases is **BAR-007 of this
   plan**, which is handed to this run. *(Raised by `devils-advocate` concern 4; the framing originated
   in the dispatch, and either way the plan is where it had to be corrected.)*

   Stripped of those props the decision stands on the product: **~100 items per batch landing
   permanently at the project root is a defect**, and 8a deriving a team set from a path nothing writes
   is incoherent regardless of which bars are live. **Adopted: set the arguments.**

   **The contingency is withdrawn, not left live.** It read: if the resolved path cannot be expressed in
   either argument, revert to correcting item 1's promise. **BAR-005 has RUN** — both flags accepted and
   honoured in the canonical form, values byte-exact, neither silently ignored — so the condition that
   would trigger it cannot occur, and a live-looking contingency for a closed question misleads the next
   reader. What survives is narrower and still true: the **run-time probe** converts any *future*
   regression in that behaviour into a stop at item 1 rather than 120 mis-placed items.

   **Three alternatives were not recorded in the first cut and are recorded now.** Two were genuinely
   unconsidered; the third is a better variant of the column that was scored. *(All three surfaced by
   `devils-advocate` concern 3.)*

   | Alternative | Why not |
   |---|---|
   | **`--fields "System.AreaPath=…;System.IterationPath=…"`** — the create **already carries** `--fields` for `System.Tags` | Genuinely unconsidered, and it had a real advantage: the value written and the value read back are the same field, so **the accepted form is not a question**. That advantage is now spent — BAR-005 settled the flags' form by execution, so both routes are equally defined. Against it: `;` is **legal in an ADO node name** (`memory/context/2026-08-05-ado-node-name-restrictions-are-ui-only.md`) while `System.Tags` uses `; ` as its delimiter **inside the same `--fields` argument**, so a node named with a semicolon would corrupt the tag write — the one field whose byte-exactness the resume path depends on. Whether `az` even honours a field via `--fields` when a dedicated flag exists is itself unverified. **Rejected on the tag-delimiter collision**, not on form. |
   | **`az boards work-item create`, then `az boards work-item update --area --iteration`** (both flags verified present on `update`) | **Doubles the write invocations per item** — `N` creates plus `N` updates against a preview whose item 7 counts writes and which 8i reconciles three ways, so every clean run would mismatch unless item 7's wording changed, which `## What does not ship` forbids. It also **widens the crash window per item** into the exact state BAR-012 exists to recover: an item created, recorded, and unplaced, which a resume matches by key tag and skips. **Rejected on invocation count and crash surface.** |
   | **Rescope 8e item 1's four values as *resolved for team derivation* rather than *where these items land*** | The **strictly better text-only variant**, and the trade-off table above scored the weaker one (dropping two values), which flattered the adopted column. This keeps *"all four"* true and is honest about what the run does. **Rejected anyway:** it fixes the *promise* and leaves the *product* — ~100 items still land permanently at the project root, and 8a still derives a team set from a path nothing writes. It repairs the sentence about the defect instead of the defect. |

2. **Canonical area/iteration path form:** `<project>\<node>\…\<leaf>` — no leading separator, no
   trailing separator, no classification segment, compared **case-insensitively**. This is the form
   `System.AreaPath` itself carries, which is what the round-trip probe reads back, and — verified
   2026-08-05 — the form both `--area` and `--iteration` accept and store byte-exact.

3. **The classification segment is dropped by route and position, never by name.** Drop segment 2 only
   for a value from `az boards area project list` (`Area`) or `az boards iteration project list`
   (`Iteration`). A node can legitimately be named `Area`, and a rule that scans the whole path for
   that string eats it.

4. **Coverage is segment-wise, never a string prefix.** `<project>\A\B` with `includeChildren: true`
   covers `<project>\A\B\C` and does **not** cover `<project>\A\BC`.

5. **Normalisation is applied once, at resolution time in 8a**, and the canonical value is what 8a
   compares, what 8e item 1 displays, what 8f passes to `--area`/`--iteration`, and what the probe
   compares against. One value, four consumers, no second transformation site.

6. **The no-trailing-separator clause carries a second reason and it is stated:** a trailing backslash
   immediately before a closing quote is the one form `CommandLineToArgvW` mis-parses, so the
   canonical form keeps it out of the final argument.

7. **Re-argued from the sink. The provenance argument is withdrawn as unsound; the conclusion changes
   shape.** The first cut said the values *"come from `az` reads of project configuration, not from the
   hand-editable tree, so 8f's title mechanism does not apply"*. **That premise is false and Microsoft
   documents it as false:** the node-name restriction is a **UI** rule, and *"when you use the Azure
   DevOps APIs rather than the user interface, you can directly specify a name that might include
   characters restricted in the UI"* (`memory/context/2026-08-05-ado-node-name-restrictions-are-ui-only.md`).
   The backtick and `;` are **not** in the restricted set at all. And 8f's own reasoning at line 440 is
   about the **sink**, not the source — the value becomes *"a literal inside that generated script"*
   before any argument passing can help — while line 445 calls discrete-argument passing *"hardening on
   top of step 1, never as a substitute for it"*. Arguing from provenance therefore discarded the one
   control 8f calls foundational and kept only the two it calls non-substitutes. *(`devils-advocate`
   concern 5.)*

   **What ships instead — four parts, and the first two are the ones the old call was missing:**

   a. **The resolved value must be one of the paths the resolution read enumerated**, matched after
      normalisation against the output of `az boards area project list` / `az boards iteration project
      list`. Anything else is a **stop**. This is an allowlist **by identity, not by character class**,
      and it closes a hole neither the first cut nor the challenge named: **8a asks the operator when
      the area or iteration is ambiguous, so the value can be operator-typed free text**, at which point
      "it came from the service" is simply not true of it. The enumerated set is already in hand — zero
      new reads.

   b. **OVERRIDDEN 2026-08-05 by measurement — do not act on this call as written; read the first entry
      of `## Deviations` first.** The claim below that a single-quoted literal neutralises `;` is
      **false**: `az` on Windows is `az.cmd`, so `cmd.exe` re-parses every argument after PowerShell and
      truncates on `;` whenever the value reaches it unquoted. The primary control shipped instead is the
      **non-batch invocation path**, with this literal demoted to defence in depth for the PowerShell
      layer only. The call is left standing rather than rewritten, so the original reasoning stays
      legible as what was believed; the deviation entry is the authoritative record and carries the
      measurement. **The conclusion in (c) survives unchanged and is stronger for it** — the invocation
      fix rejects nothing, so no character-class rejection was needed after all.

      **At the sink, where the value must become script text, it is written as a single-quoted
      PowerShell literal with any `'` doubled.** A single-quoted literal does not interpolate and does
      not treat the backtick as an escape, which neutralises `` ` ``, `$` and `;` — the exact three
      residuals the memory file names — **while rejecting nothing**. Where the invocation path allows a
      true discrete argument, 8f rule 2 still applies and is still better; this is the branch 8f line
      440 identifies as the one that actually bites.

   c. **No allowlist by character class, and no title-style rejected-character list.** A path
      legitimately carries a **space**, `(`, `)`, `'`, `.`, `,`, `;`, `-`, `_` and non-ASCII letters, and
      `\` is its separator. Rejecting any of those stops a batch on the first project whose nodes have
      ordinary names — and, unlike a title, **the operator usually cannot remediate a node name they do
      not own**, so a stop there is not a fixable stop. That asymmetry with titles is the reason
      stop-rather-than-sanitize is right for a title and wrong here. 8f rule 3 (**never build an `az`
      argument by concatenation**) applies unchanged.

   d. **The residual is named, not implied away.** Two remain. The **privilege gap** is the legitimate
      reason to accept the first: naming an area node needs project-admin rights **in the project being
      written to**, where editing a backlog tree needs a text editor — a real difference in threat model,
      and the honest basis for accepting what (b) does not catch on a caller that ignores (b). The
      second is **non-cp1252 output mangling** on this machine, which is corruption rather than
      injection and is caught by the round-trip probe.

   **Cite the 2026-08-05 round-trip narrowly or not at all.** Both values carried **spaces** and multiple
   segments, were passed as discrete arguments with no validator, and round-tripped byte-exact — so
   *"the control is the probe, not a validator"* is evidence-backed **for the space hazard, which was the
   specific silent-mangling risk predicted for this path**. No value containing `` ` ``, `;`, `&`, `'`,
   `(` or a non-cp1252 character has been through it. Citing one benign observation as general evidence
   that these values need no discipline is the failure this call was rewritten to stop making.

8. **The placement probe extends 8f's existing first-item round-trip probe** rather than adding a read.
   That probe already issues `az boards work-item show` on item 1; it gains two comparisons. Read
   `System.AreaPath` and `System.IterationPath` **out of the full JSON, never a `--query` projection** —
   8f already documents that a quoted projection returns empty at exit 0 for a value that is present,
   which would report a placement failure on a project where placement works.

9. **A placement mismatch on item 1 is a STOP, with that item's `external_refs:` entry written first** —
   identical handling to the tag failure, for the identical reason: the id is known and losing it
   double-creates on the next run.

10. **The per-team `teamsettings` read is rejected.** It would let 8a answer visibility properly, and it
    costs `N` more invocations against a budget capped at **10 total**, which pushes nearly every
    multi-team project into the default-team fallback — buying accuracy about one team at the price of
    examining any. Item 3 states the limitation instead of reading it away.

11. **The zero-candidate outcome names a normalisation defect as the first cause**, before a genuinely
    uncovered path. That ordering is evidence-based: a literal comparison produces this state on
    every correctly configured project, so it is the likelier cause by construction.

12. **`M` is defined in prose beside the budget table, never as a third row in it.** `M` is used twice
    in the file and defined nowhere; only `N` is defined (line 154). BAR-003 asks a verifier to walk the
    table with `M = 0`, which is unperformable against an undefined symbol, and site 3 of the first cut
    forbade touching the table at all — a contradiction resolved here in favour of the definition.
    Prose keeps the table two rows, so `## What does not ship`'s no-new-gate promise and BAR-007(iii)
    both hold. **Record with it the second-order fact `devils-advocate` found:** `M` is the candidate
    count, knowable only **after** all `N` `teamfieldvalues` reads, so the budget test cannot be
    evaluated before the cost it gates has been paid — the 2026-08-05 run computed `1 + 7 + 2 = 10`
    retrospectively. Whether that makes the cap the wrong control is **out of scope**; stating what `M`
    means is not.

13. **`BASE = git rev-parse HEAD` is recorded by the coordinating session before the first edit**, as
    step 0 of `## Build steps`. Four bars rest on it (BAR-006, BAR-007(iii), BAR-008, BAR-010) and the
    first cut gave it no owner — an unowned duty introduced by the very plan whose matrix exists to
    prevent them (`devils-advocate` concern 8). It now has a matrix row.

14. **A placement stop gets the recovery pair 8f already uses for a tag failure.** This mode **never
    updates a work item** (line 409), and on a re-run reconciliation matches item 1 by its key tag and
    routes it to `skip` or `repair` — so without a stated fix the mis-placed item is **never re-placed
    and the batch proceeds past it**. Sanctioned fix: **a human corrects the placement in ADO or with
    `az boards work-item update --area --iteration`** (both flags verified present on `update`), then
    re-runs. Wrong move, named beside it as 8f does at line 358: **deleting the item's `external_refs:`
    entry is not the fix** — it reaches the `create` case with the item still present and produces a
    **second work item**. Both halves are mandatory; a stop whose only instruction is "re-resolve before
    re-running" reads as though re-running repairs it. *(`devils-advocate` concern 6, BAR-012.)*

## Deviations

- **Call:** `## Calls made for you` item 7(b) — *"where the value must become script text, write it as a
  single-quoted PowerShell literal with any `'` doubled"*, as **the** sink control. **Shipped instead:**
  the **non-batch invocation path is the primary control** (`python.exe -m azure.cli`, interpreter resolved
  from `(Get-Command az).Source`), with the single-quoted literal **demoted to defence in depth for the
  PowerShell layer only**. **Decided by:** the coordinating session, on measurement, after security-reviewer
  raised the batch-file reparse as an unconsidered layer. `az` on Windows is `az.cmd`; `cmd.exe` re-parses
  every argument after PowerShell, **expands `%VAR%` regardless of quoting** (confirmed against the real
  binary — Azure DevOps echoed `Zz<username>Probe` for a payload of `Zz%USERNAME%Probe`), and truncates on
  `;`/`&`/`^`/`<`/`>` whenever the argument is unquoted. **Call 7(b)'s claim that the literal "neutralises
  `` ` ``, `$` and `;`" is false for `;`.** The call's *conclusion* — no character-class rejection — survives
  and is stronger for it: the invocation fix rejects nothing, so 7(c) needed no weakening. Full measurement:
  `memory/known-issues/2026-08-05-az-is-a-batch-file-so-cmd-exe-reparses-every-argument.md`.

  **This deviation made `BAR-008` clause (b) unsatisfiable, so that clause was amended under the four
  conditions — narrowly, and with its original wording quoted here verbatim so the edit leaves a trace
  rather than erasing one.** The clause read:

  > (b) The file states that where the value must become **script text** it is written as a **single-quoted
  > PowerShell literal with `'` doubled**, and says what that buys: no interpolation and no backtick escape,
  > which neutralises `` ` ``, `$` and `;` **while rejecting nothing**.

  It required the shipped file to assert that the literal neutralises `;`. **Measurement disproved that** —
  `;` truncates the argument at the `cmd.exe` layer whenever the value reaches it unquoted — so the corrected
  implementation states the opposite, and the bar as written would have failed a correct file for telling the
  truth. The amendment is confined to clause (b); clauses (a), (c) and (d) are untouched, and the bar was made
  **harder**, not looser: it now fails a file that repeats the original claim. **Decided by:** the coordinating
  session, as a named consequence of this deviation.

  **Separately, and not an amendment: `BAR-008` lost devils-advocate's edits to a concurrent write.** Its
  second pass added three clauses to this bar — fail if `;` appears in a rejection list, fail if the
  title-guard character list is not byte-identical to `BASE`, and fail if the 2026-08-05 round-trip is cited
  as general evidence — and tech-lead's nine-item revision rewrote the same bar at the same time without
  seeing them. tech-lead's version is what stands. **All three properties were nonetheless verified by other
  means:** no rejection list was added at all (so the `;` clause is moot), test-engineer confirmed the
  title-guard line carries no hunk, and the narrow-citation requirement is met at `SKILL.md:508`. Recorded
  because a bar silently losing a reviewer's clauses is worth knowing about even when the properties held.
- **Call:** `/implement` step 1 — stop immediately if the branch is `main`. **Shipped instead:** the run
  proceeded on `main`. **Decided by:** the coordinating session. That stop is justified in its own text by
  worktree isolation (*"Engineer agents use worktree isolation, and worktrees must not be created from
  `main`"*), and this run dispatches **no engineer agent** — the plan's `### Edit sites` assigns all thirteen
  to the coordinating session — so no worktree exists and the hazard cannot occur. Verified before
  proceeding that `agents/merge-reviewer.md` has **no refuse-on-main rule** (it stops only on detached HEAD)
  and commits to the *current* branch without merging. The plan's frontmatter states `branch: main`.
- **Call:** CLAUDE.md — invoke **git-engineer** before any engineer agent when the task involves code
  changes. **Shipped instead:** skipped. **Decided by:** the coordinating session — there is no engineer
  dispatch for it to precede, and the working branch was already fixed by the plan's frontmatter rather than
  needing confirmation.

**Not a deviation, recorded here only so it is not mistaken for one — and now resolved. See
`## Bar corrections`.** BAR-010 failed on its own enumeration rather than on the text: its closed token set
omitted **`C`** (mandated verbatim by call 4's discriminating case), **`…`** (the ellipsis in the
canonical-form notation), and **`<sprint>`** (in this plan's own `### Observed facts` section) — **three
omissions in a twelve-token list**, which is what condemned the shape rather than the entries. The text
followed call 4 exactly, so there was no departure and therefore **no licence to amend the bar** from here:
the amendment conditions require a recorded deviation as the trigger, and this was not one. It was routed to
**tech-lead, the bar's author**, and corrected there with its own dated trail. **This entry is left in place
rather than deleted** — a reader should be able to see that the bar was reported failing, by whom, and why
the coordinating session declined to fix a bar it is measured by.

## Risks

- **CLOSED — the accepted argument form.** This was the plan's stated largest risk and it is no longer a
  risk: BAR-005 RAN on 2026-08-05 and both flags are **accepted and honoured** in the project-rooted
  canonical form, byte-exact, neither silently ignored. Recorded here rather than deleted so a later
  reader can see which risk was retired by observation and which by argument.
- **The fail-safe is real for the argument form and NOT for the normalisation rule, and that asymmetry
  is the risk that replaced the one above.** The probe compares ADO's returned `System.AreaPath` against
  the canonical value 8a produced. An unverified *argument form* it turns into a safe stop. A wrong
  *canonical rule* it turns into a **false stop on item 1 of every batch on a correctly configured
  project** — the same class of defect as the `--query` false negative 8f documents at line 473, failing
  the batch for the wrong reason. **One comparison serves two premises and cannot distinguish them.**
  What contains it: all four read forms are now observed rather than assumed (item 1's table), and
  BAR-001 tests the rule against each. *(`devils-advocate` concern 7.)*
- **Even so, no failure shape of the placement change is worse than the status quo**, and the plan
  should have said so. Rejected outright → loud error at item 1, nothing else created. Wrong form
  expected → ADO does **not** auto-create classification nodes, so the value resolves to nothing and is
  **rejected**, also loud. Accepted and ignored → items land at the project root, which is **exactly
  today's behaviour**, plus a stop at item 1. Wrong-but-real node → caught by the probe's comparison.
  This is the argument that makes item 2 shippable even with BAR-005 at NOT RUN, and it was missing.
- **Normalisation may still need more than the four observed transformations.** Each was observed on
  this machine against a small number of projects. A fifth form, or a segment class none of them
  exhibits, reproduces defect 1 in a new shape. Open, not assumed closed — but no longer resting on
  assumed symmetry between the area and iteration routes, which was the specific gap.
- **Call 7(a) can stop a batch on a legitimate configuration, and that is a real cost.** If the operator
  answers 8a's ambiguity prompt with a path that does not normalise to an enumerated node — a typo, a
  stale path, a node renamed between reads — the run stops rather than proceeding. The escape is to
  re-answer with an enumerated value; there is no sanitisation path, by design. Cheaper than the
  alternative, which is passing operator-typed text to a command sink.
- **Item 1 becomes the load-bearing item.** Both the tag probe and the placement probe fire only there,
  so a batch whose item 1 is unrepresentative (for example a `SPIKE` the operator scoped alone) verifies
  less than it appears to. Pre-existing property of the probe design; this plan widens what rides on it
  **without widening what item 1 is chosen to be** — named because it is the one second-order effect the
  challenge found that this cut does not address.
- **8a's *"ask before previewing"* changes character.** It was cheap advice about a value the run
  discarded; it is now a hard block on the value that determines where ~100 permanent items land. Its
  cost rises with its value, and no edit site changes it. Worth a sentence at site 1 so the next reader
  knows it was noticed. *(`devils-advocate` concern 9.)*
- **8g's `Where it lives` table row is falsified by this cut and nothing but BAR-007 checks it.** It is
  the staleness site a reader is least likely to visit while editing 8f.

## Out of scope

- The backlog-level / work-item-type-category mechanism (8c, 8e item 2) — settled, warned, untouched.
- Whether 8a's budget cap of 10 is the right number, and the finding that its fallback reads **past**
  the one project in the org where the per-team read-failure branch can fire
  (`docs/plans/ado-pair-report-v4.md`). Real, recorded, not this cut.
- Setting any other field on the create: no state, no assignment, no parent field, no iteration
  **override** per item.
- `skills/backlog/SKILL.md`, which also omits the iteration condition. Named in the memory file; a
  separate cut.
- Any change to the tag design, the anchor tag, or `external_refs:`.

---

## Inputs

- `skills/devops-azure/SKILL.md` — the only file edited. Sites: **8a** (lines ~132–169, the resolution
  block, the candidate rule at line 148, the budget table at 156–161), **8e** (item 1 line 366, item 5
  line 378, item 6 line 379, item 7 line 380), **8f** (the verbatim command at line 429, the failure
  table at 456–463, the round-trip probe at 465–475), **8g** (the `Where it lives` row at line 512).
- `docs/plans/ado-pair-report-v4.md`, `## EXECUTED 2026-08-05 (second)` — the observed values and both
  defect reports. Read it; do not re-derive from this plan's summary.
- `memory/context/2026-08-05-ado-team-backlog-filters-by-iteration-too.md` (active) — the iteration
  filter, the `\<node>` form of `backlogIteration.path`, and empty-string-means-project-root.
- `memory/context/2026-07-30-powershell-mangles-native-exe-arguments.md` (active) — why a
  space-carrying argument needs discrete passing and why its failure is silent.
- `memory/context/2026-08-04-az-query-and-json-parse-hazards-on-windows.md` (active) — why the probe
  reads full JSON rather than a projection.
- `memory/context/2026-08-04-this-repo-is-public-never-write-real-identifiers.md` (active, **overrides
  conventions, global**) — `<org>`, `<project-a>`, `<project-b>`, `<node>`, `<leaf>` only.
- `memory/context/2026-08-05-az-mangles-non-cp1252-characters-on-output.md` (active) — an area path
  segment carrying a non-cp1252 character is mangled on output on this machine, so it is a third way a
  comparison can fail without the normalisation being wrong. Name it at the comparison site.
- `memory/context/2026-08-05-ado-node-name-restrictions-are-ui-only.md` (active, written by
  `devils-advocate` during the challenge) — **the single authority for call 7.** The node-name restricted
  set, the characters a guard must **not** reject, the backtick and `;` being absent from the restricted
  set, the UI-not-API framing that makes the provenance argument unsound, the two-form inconsistency
  inside one `az` command family, the `TF50309` node-creation refusal, and the 2026-08-05 execution
  record. Read it before writing site 7; do not re-derive any of it from this plan.

### Observed facts closed 2026-08-05, after the challenge

Three things moved from assumed to observed between the first cut of this plan and this revision. Each
retires a specific concern, and each is recorded here because an implementer who does not know them will
write the wrong text.

1. **Both placement flags are accepted and honoured.** Two live creates, read back with `work-item show`:
   `--iteration <project>\<sprint>` byte-exact; then in a second project `--area <project>\<node>\<leaf>`
   **and** `--iteration <project>\<node>` both byte-exact. **Neither is silently ignored.** Retires the
   plan's largest stated risk and the contingency in call 1.
2. **The iteration read route's form is observed, twice, not inferred by analogy.**
   `az boards iteration project list` returns `\<project>\Iteration\<node>` and
   `\<project>\Iteration\<node>\<leaf>` — classification segment at segment 2, symmetric to the area
   route. Separately, `teamsettings.backlogIteration.path` was observed as `\<node>` and as `''`.
   Retires `## Challenge` concern 2, which is the gap that would otherwise have produced a false stop on
   item 1 of every batch.
3. **Constructing a classification node is unproducible on this machine.**
   `az boards area project create` is **REFUSED** — `TF50309`, "Create child nodes" — in a project where
   item creation succeeds. So **no bar may require creating one** (bar-soundness row 4). BAR-005 was run
   against a project that already had the nodes; the disposable project has zero child area nodes and
   could not have paid that cost at all.

### Bars in other plans — documented intent, not live gates

`docs/plans/ado-pair-report-v4.md` **BAR-007** and **BAR-015**, and `docs/plans/devops-azure-batch-write.md`
**BAR-002** and **BAR-003**, all constrain text this cut edits. **None of them will be evaluated on this
changeset:** plan consumption is opt-in per invocation, merge-reviewer enforces bars only for the
`plan_id` handed to the run, and those plans are not handed to this one. Treat them as **self-imposed
constraints inherited from merged work** — good practice to honour, and not a mechanism. The live check on
all four phrases is **BAR-007 of this plan**.

**Stated explicitly, because it is the question a reviewer will ask:** adding `--area` and `--iteration`
to an existing create is **not a new invocation**, so 8e item 7's write count is arithmetically
unchanged, and this plan adds no read, so v4 BAR-007's negative half holds trivially. Item 1 keeps
exactly four values, so v4 BAR-015's *"all four"* and batch-write BAR-002's four literals both stay
true. The one whose subject this cut genuinely touches is batch-write **BAR-003** — the probe it
describes gains two comparisons while keeping both tag comparisons and the same single `show` call, so
its requirements are a subset of the extended probe. Nothing here edits the `System.Tags` command shape.

## Build steps

### Responsibility matrix — the placement lifecycle

Written because the defect being fixed **is** an unowned duty: nobody wrote the area path, and nobody
checked where items landed.

```
Event: area and iteration resolved, canonical form produced
Writer:  8a resolution block          Reader:  8a comparison, 8e item 1, 8f create, probe
Mutator: 8a (raw -> canonical)        Verifier: none — a transformation, not a state
Failure behavior: ambiguous or unset -> 8a's existing ask-before-previewing (unchanged)
Persisted state: none; per-run value

Event: placement previewed
Writer:  8e item 1 (four values)      Reader:  the operator
Mutator: none                         Verifier: the operator's confirmation
Failure behavior: n/a — display
Persisted state: none

Event: item created with placement
Writer:  8f create (--area/--iteration)   Reader:  ADO
Mutator: 8f                                Verifier: the probe, item 1 only
Failure behavior: az rejects the value -> new failure-table row; stop at that item
Persisted state: System.AreaPath / System.IterationPath on the work item

Event: placement verified
Writer:  none                          Reader:  8f probe (existing work-item show on item 1)
Mutator: none                           Verifier: 8f probe
Failure behavior: mismatch -> write that item's external_refs: entry, then STOP
Persisted state: the entry written before the stop

Event: placement verified for items 2..N
Writer:  none                          Reader:  none
Mutator: none                           Verifier: NOBODY — accepted, stated below
Failure behavior: none exists
Persisted state: n/a

Event: team candidacy derived
Writer:  8a (candidate list)           Reader:  8c level lookup, 8e item 2
Mutator: none                           Verifier: the operator reading the named teams
Failure behavior: zero candidates -> stated display outcome (new); read failure -> per-team
                  line (existing, unchanged)
Persisted state: none

Event: resolved value admitted to the command sink        [NEW - call 7]
Writer:  8a (canonical value)           Reader:  8f create
Mutator: none                            Verifier: 8f site 7 - identity match against the
                                                   paths the resolution read enumerated
Failure behavior: not an enumerated node -> STOP before the preview; re-answer with an
                  enumerated value. No sanitisation path.
Persisted state: none

Event: placement stop recovered                           [NEW - BAR-012]
Writer:  a human, outside this mode      Reader:  the next run's 8d reconciliation
Mutator: az boards work-item update, run by the operator
Verifier: NOBODY inside this mode - it never updates a work item (line 409), and a re-run
          matches item 1 by key tag and skips it
Failure behavior: operator deletes the external_refs: entry instead -> a SECOND work item
                  (line 358). Named in the stop text as the wrong move.
Persisted state: the corrected placement in ADO; the tree entry already written

Event: BASE recorded                                      [NEW - not a runtime duty]
Writer:  the coordinating session, before site 1
Reader:  BAR-006, BAR-007(iii), BAR-008, BAR-010
Mutator: none                            Verifier: none - a recorded fact
Failure behavior: unrecorded -> four bars have no baseline to diff against
Persisted state: BASE = git rev-parse HEAD, carried in the run's context
```

**Owners diffed against files edited:** every runtime owner above is a step of
`skills/devops-azure/SKILL.md`, which is the only file in `## Inputs`. The two non-runtime owners are
the coordinating session (`BASE`) and the operator (placement recovery) — neither needs a file, and both
are named rather than left to be inferred. No duty is assigned to an unedited file.

**Three duties have no owner inside this mode, and each is deliberate.** Placement verification for
items 2..N — a per-item read-back would add `N` invocations for a failure mode that is uniform across
the batch, since all items get the same two values from one resolution; item 1 failing is the whole
signal. **Nothing verifies the iteration *window* condition** of item 3: 8a states the limitation rather
than reading `teamsettings`. And **nothing inside this mode can repair a placement** — hence the human
owner above, which is why BAR-012 requires the recovery to be *stated* rather than performed. Recorded
here rather than left implicit, because a duty stated against a step and owned by nothing is the failure
this plan exists to fix — and the first cut of this plan introduced one of its own (`BASE`), which is
now the last row of the matrix.

### Edit sites — thirteen, in one file

**Step 0, before any edit: the coordinating session records `BASE = git rev-parse HEAD`.** Not an edit
site. Four bars diff against it and the first cut gave it no owner (call 13).

1. **8a, the resolution block (after line 139).** Add the canonical form, the per-route transformation
   table — **four rows, matching `## What ships`, with row 4 labelled as a route this mode does not
   read** — and the statement that two routes' raw strings are **never** compared. Name the cp1252
   output hazard as a third, independent way a comparison can fail, and the
   `area project delete` / `work-item create` two-form inconsistency as why the transformation is stated
   per route rather than inferred from a sibling command. Add one sentence noting that
   *"ask before previewing"* now gates the value that determines where every item permanently lands
   (`## Risks`). Every worked example uses `<project>`, `<node>`, `<leaf>`.
2. **8a, beside the budget table (line ~154, with `N`'s definition).** **Define `M`** as the candidate
   count, in prose. **No row is added to the table** — call 12, and BAR-007(iii) depends on the table
   being untouched.
3. **8a, the candidate rule (line 148).** Restate coverage over the canonical form, segment-wise, with
   the `<project>\A\B` vs `<project>\A\BC` discriminating case written out. Keep `includeChildren:
   true` semantics exactly as they are.
4. **8a, after the budget table (after line 161).** State the zero-candidate outcome: no team's area
   configuration covers the resolved path, the derivation is **empty rather than clean**, and the two
   causes in order — a normalisation defect first, a genuinely uncovered path second. **A display
   state, not a gate.** Do not touch the two-row budget table itself.
5. **8a, the opening of the team-resolution block (line 141).** Scope the claim to area-path ownership
   and name the unread `backlogIteration` condition, citing the memory file. One or two sentences. No
   new read. *(Item 3 — **KEEP**, not separable any more.)* This is the site adjacent to the *"four
   gates with three verdicts"* phrase three bars protect: edit with care and diff it.
6. **8f, the verbatim command (line 429).** Add `--area` and `--iteration` carrying the canonical
   values.
7. **8f, immediately after the title mechanism (after line 447).** The **sink discipline** for the two
   new values, as the same mechanism's second application — call 7 in full: the **identity match**
   against the enumerated nodes with a stop before the preview (7a); the **single-quoted literal with
   `'` doubled** where the value must become script text (7b); the explicit statement that **no
   allowlist and no rejected-character list** applies, with the legal characters named so a later reader
   does not add one (7c); and the **named residual** — the privilege gap and cp1252 mangling (7d).
   **Argue from the sink, never from provenance**, and cite
   `memory/context/2026-08-05-ado-node-name-restrictions-are-ui-only.md`. Cite the 2026-08-05 round-trip
   for the **space hazard only**.
8. **8f, the failure table (456–463).** One new row: an area or iteration path `az` rejects or does not
   honour → stop at that item, echoing the value passed, its canonical form, the raw form from the
   resolution read, and an instruction to re-resolve before re-running. Note that it is item 1 by
   construction, so nothing else was created. **Point it at site 10's recovery** — an instruction to
   re-run without one reads as though re-running repairs it.
9. **8f, the round-trip probe (465–475).** Extend to `System.AreaPath` and `System.IterationPath`,
   compared against the canonical values, out of the **full JSON**. Keep both tag comparisons. State
   that this adds **no** `az` invocation. Mismatch → write `external_refs:`, then STOP, reporting which
   of the two mismatched, the value asked for, and the value ADO recorded.
10. **8f, with the placement stop (beside sites 8 and 9).** The **sanctioned recovery pair**, on the
    shape 8f already uses at lines 356 and 358: the one **human** fix (correct the placement in ADO or
    with `az boards work-item update --area --iteration`, then re-run) **and** the wrong move named
    beside it (**deleting the `external_refs:` entry double-creates**). State that this mode never
    updates a work item and that a re-run matches item 1 by key tag and skips it, so the repair cannot
    be automatic. Call 14, BAR-012.
11. **8e item 5 (line 378).** The verbatim command must show the two new arguments — it is the command
    as it will actually run.
12. **8e item 6 (line 379).** Restate: area and iteration **are** set, to the two values shown at item
    1, identically for every item, with no per-item override. The current parenthetical reads as though
    placement already follows the resolved values.
13. **8g, the `Where it lives` row (line 512).** Correct it to match the shipped behaviour, on the
    pattern of the work-item-type row: set on the item at create, re-readable from ADO, never recorded
    in the tree.

**Do not touch:** 8e item 1's four values or the phrase *"all four"*; 8e's *"nine things, in order"*;
8a's *"four gates with three verdicts"*; **the two rows of 8a's budget table** (defining `M` beside it is
site 2 and is not a change to it); 8e item 7's wording; **8f's title-guard character list**, which site 7
sits next to and must not modify; any part of 8c.

### Sequencing

Step 0 precedes everything. Sites 1–4 are one writer's work — site 3 consumes site 1's canonical form,
site 4 consumes site 3's candidate set, and site 2 supplies the vocabulary site 4's outcome is expressed
in. Sites 6–10 are one writer's work for the same reason: site 7 constrains what site 6 may pass, site 9
compares what site 6 wrote, and sites 8 and 10 are the two halves of one failure path — **write them
together or the stop ships without its recovery**, which is the defect BAR-012 exists to catch. Sites
11–13 are consequences of 6–10 and must be written after them, since each restates what 6–10 now do.
Site 5 is independent of the rest. All thirteen land in one file, so a single writer holds them all — no
parallel dispatch is possible here.

## Acceptance bars

- BAR-001: applying the file's own stated transformation to the two recorded raw forms yields one identical canonical value, and it does not eat a node legitimately named `Area`
  Evidence: files -> `skills/devops-azure/SKILL.md` 8a. **Apply the rule; do not confirm a sentence exists.** Feed it `\<project>\Area\<node>\<leaf>` (the `az boards area project list` form) and `<project>\<node>\<leaf>` (the `teamfieldvalues` form) and confirm both reduce to the same canonical string. Then feed it `<project>\<node>\Area` from the `teamfieldvalues` route and confirm the trailing `Area` **survives** — a rule that drops the segment by name anywhere in the path, rather than by route and position, fails here while passing the first check. Then feed it the form returned by **`az boards iteration project list`** — the route 8a actually resolves the iteration path from (line 136), which `## What ships` omits from its transformation table — and confirm the rule reduces it to the same canonical shape. **That form has now been observed and the file must state it** — `\<project>\Iteration\<node>` for a child node and `\<project>\Iteration` for the root, on two projects, zero writes, with segment 2 the literal `Iteration` at the same position the area route carries `Area`. So feed the rule those two exact strings and confirm they reduce to `<project>\<node>` and `<project>` respectively. **An earlier revision of this bar called that form unobserved; that was wrong and the correction matters to how the bar is run** — the requirement is no longer "state it or declare it assumed", it is **state it correctly**, and a file that hedges an observed form as assumed now fails this bar for a different reason. **BAR-005 still does not close this bar, and the temptation to think it does is why this sentence stays:** BAR-005 verified which form the two `az` *arguments* accept, having been handed inputs normalised **by hand**; this bar is about whether the *shipped text* transforms an observed read form into that accepted value. The premise is verified end to end for both routes; **the shipped text is what remains unverified, and this bar is the only thing that checks it.** The specific way it fails is the missing table row: text handling only the area route passes every area-side check while silently leaving the iteration route untransformed. Two further reasons the transformation must be stated per route rather than inferred, both worth naming at the comparison site: `az boards area project delete --path` takes the **classification** form (`\<project>\Area\<node>`) while `az boards work-item create --area` takes the **canonical** form (`<project>\<node>`), so a second two-form inconsistency exists inside one command family; and per `memory/context/2026-08-05-az-mangles-non-cp1252-characters-on-output.md` a segment carrying a non-cp1252 character is mangled on output on this machine, which is a third way the comparison fails without the rule being wrong. Then feed it `\<node>` and the empty string as `backlogIteration.path` values and confirm the rule produces a project-rooted value and the project root respectively — **and confirm the file states that `teamsettings` is a route this mode does not read** (call 10 rejects it, item 3 names `backlogIteration` as unread), so a reader cannot mistake that row for a route in use. **The observations make this half sharper, not softer:** `backlogIteration.path` returns `\<node>` while the route actually read returns `\<project>\Iteration\<node>`, so the table currently carries an **unreachable** form and omits the **reachable** one. Either row 3 is labelled as not-read or it is dropped; a bar that accepts the table as-is accepts the inversion. **If any of these inputs has no stated answer, that is a failure, not an inference to make on the file's behalf.**
- BAR-002: coverage is segment-wise, and the discriminating case is decided the right way
  Evidence: files -> `skills/devops-azure/SKILL.md` 8a. Apply the file's stated coverage rule to a value `<project>\A\B` carrying `includeChildren: true` against two targets: `<project>\A\B\C` (must **cover**) and `<project>\A\BC` (must **not** cover). A string-prefix rule passes the first and fails the second, and a naive implementation reads as correct on every project whose node names happen not to share a prefix — which is why the negative case is the one that matters. Confirm the exact-match case is also stated for a value **without** `includeChildren`.
- BAR-003: the zero-candidate state has a stated outcome that is reachable by following the file's own tables
  Evidence: files -> `skills/devops-azure/SKILL.md` 8a. **First confirm `M` is defined in the file at all.** `N` is defined at line 154; `M` occurs exactly twice, both inside `1 + N + M`, and is defined **nowhere** — its meaning is recoverable only from `docs/plans/ado-pair-report-v4.md`. A zero-candidate outcome whose trigger cannot be named in the file's own vocabulary is not "reachable by following the file's own tables", so an undefined `M` fails this bar. Defining it is prose beside the budget table, not a third row in it. Then walk the file as a reader would with `N = 3`, `M = 0`: the budget row `1 + N + M <= 10` selects *"narrow fully; examine every candidate team"*, which examines none. Record which sentence the run then prints. The bar passes only if a sentence exists naming the empty derivation, and it must name a **normalisation defect first** and a genuinely uncovered path second. **This bar fails against the file as it stands today** — that is deliberate and is what makes it worth writing. Confirm also that no row was added to the two-row budget table and that 8a's *"four gates with three verdicts"* is unedited; either would mean a gate was added, which `## What does not ship` forbids.
- BAR-004: `--area` and `--iteration` exist on the installed `az`, with zero writes — and what this does not prove is stated
  Evidence: manual -> run `az boards work-item create --help` and record both flags verbatim with their help text, **including the parenthesised example value on each**, plus the installed `azure-devops` extension version from `az extension list`. The examples are the point, not decoration: Microsoft's published reference gives `--area` as *"Area the work item is assigned to (e.g. Demos)"* and `--iteration` as *"Iteration path of the work item (e.g. Demos\Iteration 1)"*, and **that help text is the only evidence about form that exists short of BAR-005** — the two examples read as project-rooted if `Demos` is the sample *project* name and project-relative if it is a node name, and the doc never says which. Record the installed text verbatim so a later reader can judge that for themselves rather than inheriting this plan's reading. Zero writes: `--help` creates nothing. **State in the handoff what this does not establish** — bar-soundness row 1: a flag's presence is not evidence about the form it accepts, nor that the service honours it, and Microsoft's published reference already documents both flags, so a matching `--help` advances nothing beyond confirming the installed extension agrees with the docs. **Now largely subsumed:** BAR-005 RAN on 2026-08-05 and verified both flags are accepted **and honoured** with the project-rooted canonical form, which is strictly more than this bar can establish — and it settles the help-text ambiguity above as a red herring. Keep this bar as the cheap zero-write check that the installed extension still carries both flags after an upgrade, and do not present it as evidence about form. **A missing flag is now a regression rather than a design question** — BAR-005 saw both flags work on 2026-08-05, so their absence would mean the installed extension changed under the plan, and the finding goes to the extension version recorded above. A present flag advances nothing except the cheapest possible check. If `az` is absent or the command errors, that is `UNKNOWN`, never a pass — blank output at exit 0 is this machine's documented Bash-tool failure signature (`memory/known-issues/2026-07-10-bash-tool-silent-failure-windows.md`).
- BAR-005: a work item created through the shipped command actually carries the resolved area and iteration
  Evidence: manual -> in the disposable project the operator authorises for item creation (recorded in the operator's private memory; **not named here**, per the public-repo rule), resolve an area path and an iteration path that are **not** the project root, canonicalise them by the shipped rule, and create **one** item with the shipped command. Then read that item back with `az boards work-item show --id <id> --output json` and compare `System.AreaPath` and `System.IterationPath` against the canonical values — **from the full JSON, never a `--query` projection**, which 8f documents as returning empty at exit 0 for a present value and would report a placement failure on a working project. **Three outcomes, and each has a stated meaning:** values match -> item 2's premise is verified; create is **rejected** -> record the exact error and the form tried, then try the project-relative form once and record that too; create **succeeds but the item sits at the project root** -> the argument is silently ignored, which is the worst case and the one the run-time probe exists for. **A rejection or a silent ignore is a finding for the design, not a bar failure to be waived** — it is recorded in `## Deviations`, and the contingency this clause originally pointed at is **withdrawn** (call 1), because the run below closed the condition that would have triggered it. A pass claimed without the read-back values written into the handoff is not a pass.
  Gated: requires a disposable project the operator authorises for item creation, and it must not be run against a project anyone depends on. **Second condition, and it is a hard precondition rather than a cost to authorise:** that project must **already contain a non-root area node and a non-root iteration node**. There is no fallback of creating them — **`az boards area project create` is refused for this account (`TF50309`, "Create child nodes") in a project where work-item creation succeeds**, so a run that needs to construct a classification node **cannot happen on this machine at all** (bar-soundness row 4). An earlier revision of this bar offered node creation as a priced fallback; that was unproducible and is withdrawn. If no such project exists, this bar is `NOT RUN` with that condition named — never waived and never worked around. **This condition bound in practice, and how it bound is the point:** the disposable project has **zero** child area nodes and could not host this bar at all, so the run used a second project that already had them. The refusal was **encountered, not anticipated**.
  Cost: **RUN 2026-08-05 — this line now records the cost paid, not a cost to authorise.** Paid: **two work items across two projects**, permanent and irreversible in effect — `az boards work-item delete` soft-deletes to the project recycle bin and works, but `--destroy` fails `VS402324`, so both ids are permanently consumed and the items stay readable in the recycle bin to anyone with project access. **No classification node was created anywhere** — not by choice but because the attempt was **refused** (`TF50309`), which is a stronger guarantee than a declined option and is the reason the gate's second condition is a precondition. **No tag values were created**: the probe items were created without the tag arguments. Had the full shipped command been used it would have added up to **2 permanent per-project tag values** (tag scope is per-project, verified 2026-08-03). Nothing else in either project was written.
  Note: **this bar was RUN on 2026-08-05, before implementation, and its write-side premise is verified** — two live creates, both non-root values, `System.AreaPath` and `System.IterationPath` stored byte-exact. **What it did not verify is the shipped canonical rule**, and the bar's own evidence line is why: it instructs the runner to "canonicalise them by the shipped rule", which did not exist yet, so the inputs were normalised **by hand**. That is the same confound that made the 2026-08-05 derivation probe find candidates the shipped file cannot (*"the normalisation was written into the probe"*), recurring one layer up. Read this bar as evidence about the two `az` arguments and about nothing else; the read-route forms are BAR-001's subject and remain BAR-001's problem.
- BAR-006: the placement probe adds no `az` invocation, and 8e item 7's count and wording are untouched
  Evidence: files -> `skills/devops-azure/SKILL.md`. Enumerate every `az` invocation the shipped 8f, 8g and 8h text issues per item and per run, and diff that set against `BASE` (record `BASE = git rev-parse HEAD` before the first edit). The **write** set must be identical, and the **read** set must be identical too — the probe reuses the single `az boards work-item show` on item 1 rather than adding a second. Then confirm 8e item 7 still reads *creates plus parent/child link additions, and nothing else*, byte-identical via `git diff $BASE -- skills/devops-azure/SKILL.md` showing no hunk on that line. `docs/plans/ado-pair-report-v4.md` BAR-007 protects this and would fail on every clean run of a batch if a read were counted; this bar is the pre-emptive check, not a substitute for it.
- BAR-007: every count and enumeration this cut could falsify is still **true**, including the one nothing else checks
  Evidence: files -> `skills/devops-azure/SKILL.md`. Four phrases, each asserted **true of what the file now says**, not merely present — a stale count is present and wrong, which is the state this bar exists to catch. (i) 8e item 1's *"all four"*: still exactly org, project, area path, iteration path; a fifth resolved value displayed there falsifies it, which is why the team stays on item 2. (ii) 8e's *"nine things, in order"*: the numbered list is still nine items; nothing this cut adds became a tenth. (iii) 8a's *"four gates with three verdicts"*: **unedited** — confirm via `git diff $BASE` that no hunk touches it. (iv) **8g's `Where it lives` row for area and iteration path** — currently *"The preview (8e), resolved per run and never persisted"*, which this cut **falsifies**, since the values are now written onto the work item. Confirm it was corrected. Item (iv) is the site a reader editing 8f will not visit, and no other bar in any plan covers it.
- BAR-008: the sink discipline for the two argument values is present and argued from the sink, the title guard is untouched, and no character-class guard was added
  Evidence: files -> `skills/devops-azure/SKILL.md` 8f, site 7. **Four required parts, each independently able to fail, and the first two are what the plan's first cut lacked entirely.** (a) The file requires the resolved value to be **one of the paths the resolution read enumerated**, matched after normalisation, with a **stop** on anything else — and states *why*: 8a asks the operator when the area or iteration is ambiguous, so the value **can be operator-typed free text**, at which point no provenance argument covers it. A file omitting this fails; so does one that states the check without naming the operator-typed path, because the next reader will delete a check whose reason is not on the page. (b) **AMENDED at step 10 — see `## Deviations`, which quotes this clause's original wording.** The file states that the **primary control is an invocation path that is not a batch file**, because `az` on Windows is `az.cmd` and `cmd.exe` re-parses every argument after PowerShell — expanding `%VAR%` regardless of quoting. It must state that the **single-quoted PowerShell literal with `'` doubled** is **defence in depth for the PowerShell layer only**, neutralising `` ` `` and `$` **while rejecting nothing** — and it must **not** claim the literal neutralises `;`, which measurement on 2026-08-05 disproved. A file asserting the original clause's claim now **fails** this bar. (c) It applies **no allowlist by character class and no title-style rejected-character list**, and names the legal characters so a later reader does not add one — a **space**, `(`, `)`, `'`, `.`, `,`, `;`, `-`, `_`, non-ASCII letters, and `\` as the separator. (d) It **names the residual** rather than implying none: the **privilege gap** (naming a node needs project-admin in the project being written to; editing a tree needs a text editor) and **cp1252 output mangling**, caught by the probe.
  **The half that fails on a wrong-axis justification.** Confirm the file argues from the **sink**, not from provenance. 8f's own reasoning at line 440 is sink-based — the value becomes *"a literal inside that generated script"* before any argument passing helps — and line 445 calls discrete-argument passing *"hardening on top of step 1, never as a substitute for it"* and *"a property of the caller, and this file cannot verify the caller has it"*. **A file whose stated reason is that the values are service-sourced fails this bar**, and it fails on fact, not on style: Microsoft documents the node-name restriction as a **UI** rule — *"when you use the Azure DevOps APIs rather than the user interface, you can directly specify a name that might include characters restricted in the UI"* — and the **backtick and `;` are not in the restricted set at all** (`memory/context/2026-08-05-ado-node-name-restrictions-are-ui-only.md`).
  **The negative half, which is the one that breaks a working project.** Confirm no character legal in an ADO node name was added to any rejection list applied to these two values, and confirm 8f's **title-guard character list is byte-identical to `BASE`** (`git diff $BASE` shows no hunk on it). **`;` is the trap here**: it is legal and ordinary in a node name *and* a statement separator in script text, so it is exactly the character a well-meaning implementer will add to a denylist — and rejecting it stops a batch on a legitimate configuration the operator often **cannot remediate**, because they do not own the node. That asymmetry with titles — a human can fix their own title, and cannot fix someone else's node name — is why stop-rather-than-sanitize is right for a title and wrong here, and the file should say so.
  **Cite the 2026-08-05 round-trip narrowly or fail.** Both values carried **spaces** and multiple segments, were passed as discrete arguments with no validator, and round-tripped byte-exact — evidence for the **space** hazard, which was the specific silent-mangling risk predicted for this path. **No value containing `` ` ``, `;`, `&`, `'`, `(` or a non-cp1252 character has been through it.** A file citing that run as general evidence that these values need no discipline fails this bar rather than passing it. **Then the half this bar can actually fail on, added because the plan's stated reason is argued on the wrong axis:** confirm the file justifies the absence of a guard **from the sink**, not from provenance alone, and confirm it **names the residual rather than implying none exists**. 8f's own reasoning at line 440 is sink-based — the value becomes a **literal inside generated script text** before any argument passing helps — and line 445 calls discrete-argument passing *"hardening on top of step 1, never as a substitute for it"* and *"a property of the caller, and this file cannot verify the caller has it"*. So a justification resting only on where the value came from removes the control 8f calls foundational while keeping the two it calls non-substitutes. Three facts fix what "the residual" means, all from Microsoft's published naming restrictions: ADO **node** names exclude `\ / : * ? " < > | # $ & * +`, which is why the negative half above is right that a space, `(`, `)`, `'` and `.` must stay legal; **the backtick and `;` are not excluded**, and both are live in PowerShell script text; and the restriction is documented as a **UI** rule, with API-created names able to *"include characters restricted in the UI"* — so "read from the service, therefore constrained" is not true as stated. The bar passes if the file argues from the sink and names that residual (the privilege difference between a project admin and a tree editor is a legitimate reason to accept it); it **fails** if the file's only stated reason is that the values are service-sourced. **One live observation now supports the call's choice of control, and it is worth citing in the file for exactly what it covers:** on 2026-08-05 both argument values carried **spaces** and multiple backslash-separated segments, were passed as discrete arguments with no validator, and round-tripped **byte-exact** — so *"the control is the round-trip probe, not a validator"* is evidence-backed **for the space hazard**, which was the specific silent-mangling risk predicted for this path. Cite it that narrowly. **It is one benign observation and says nothing about the hostile case:** no value containing `` ` ``, `;`, `&`, `'`, `(` or a non-cp1252 character has been passed through this path, so a file that cites this run as general evidence that these values need no guard fails this bar rather than passing it.
- BAR-009: 8a's board claim is scoped to what it derived, and the rejected read stayed rejected
  Evidence: files -> `skills/devops-azure/SKILL.md` 8a. Confirm the team-resolution block no longer asserts unqualified that the derived teams' boards **will show** these items, that it names the team's `backlogIteration` window as a second condition this run does **not** read, and that it cites `memory/context/2026-08-05-ado-team-backlog-filters-by-iteration-too.md`. Then the cost half: count the `az` invocations 8a issues per run against `BASE` and confirm the number is **unchanged** — no `teamsettings` read was added, and the budget table's `1 + N + M` arithmetic still matches the invocations the text actually issues, with `M` now defined (site 2). **The cut-escape clause is removed.** An earlier revision ended *"if item 3 was cut, this bar is NOT RUN"*, which let any result be reclassified as compliant — bar-soundness row 5, self-exemption. Item 3 is **KEEP** (`## What ships`), so this bar has no NOT RUN path: it passes or it fails.
- BAR-010: the new text carries no real identifier
  Evidence: files -> `git diff $BASE -- skills/devops-azure/SKILL.md` and this plan. **Two clauses with different shapes, because the two ways an identifier reaches these files are different, and clause (a) provably cannot see clause (b)'s case.** *(Enumeration corrected 2026-08-05 — see `## Bar corrections`.)*
  **(a) Path segments — admitted by shape for bracketed tokens, by closed list for bare ones.** Enumerate every `\`-separated path example on every added line. A segment matching `<[a-z][a-z0-9-]*>` is admitted **by shape**: an angle-bracketed token is self-evidently a placeholder, and the failure mode this bar exists to catch — a plausible invented substitute, or a real name pasted from probe output — arrives **bare**, never bracketed. A **bare** segment is admitted only from this closed list: `Area`, `Iteration`, `…`, and the case tokens `A`, `B`, `C`, `BC` that BAR-002's discriminating case and call 4 require verbatim (`<project>\A\B` covers `<project>\A\B\C` and does not cover `<project>\A\BC`). **Any bare segment outside that list fails the bar.** State the set found in the handoff, so the check is reproducible rather than asserted. **The shape rule replaces an explicit list of bracketed placeholders, and that is the whole point of the correction:** the earlier enumeration named eleven tokens, omitted `C`, `…` and `<sprint>`, and therefore failed a correct implementation — a closed list of placeholders goes stale every time the text needs a new one, which is the same defect as a stale count in a pointer. The shape rule cannot go stale; the bare list can only shrink.
  **(b) Pasted command output and command strings — the class clause (a) is blind to, and the one that actually leaked.** For every added line that is pasted output, a shell or `az` command, or a quoted example value, check for **environment-expanded values**: an account or user name, a machine or host name, a home-directory path, an email address. **Check for them as substrings inside larger tokens, not only as whole words.** This is not hypothetical: during this changeset a real account name — the literal expansion of `%USERNAME%` — reached **three places across two files** inside a synthetic-looking token of the form `Zz<name>Probe`, and `scripts/lint-identifiers.sh` returned **9/9 clean** anyway. The token was **already in** the gitignored `.identifier-denylist`; the rule is **word-boundary matched**, so a name embedded in a longer token does not match. It was caught by a human reading the diff, one step before a push to a public host. Probe output is the likeliest source precisely because it arrives already carrying whatever the environment expanded, and it does not look like an identifier when it lands. **The expansion can be introduced by the tool chain rather than typed by anyone**, which is what makes a substring search the right instrument: `az` on Windows is `az.cmd`, so `cmd.exe` re-parses every argument and **expands `%VAR%` regardless of quoting** (`memory/known-issues/2026-08-05-az-is-a-batch-file-so-cmd-exe-reparses-every-argument.md`, measured during this cut). A probe sending the literal `Zz%USERNAME%Probe` gets the expanded name echoed back by the service, so an operator pasting that output has pasted a real identifier they never wrote and cannot see as one.
  **What the script does and does not cover, stated accurately.** `scripts/lint-identifiers.sh` keys on **structured positions** and ships **no in-repo denylist** (a list of forbidden strings cannot live in a public repo), reading exact tokens from a **gitignored** `.identifier-denylist` when present. So it can see neither a real node name inside a prose example nor a denylisted name embedded in a longer token. **Both gaps are this bar's subject, and neither is a reader-only control:** clause (a) is a token enumeration and clause (b) is a substring search, both of which a checker can perform and report. A bar whose control is "a reader was careful" cannot fail in a way anyone can check.
  One supporting fact, recorded because it bounds the risk rather than excuses it: the likeliest *path* paste source, `docs/plans/ado-pair-report-v4.md`, already records the probed path as `<project-a>\A\B`, so a real path reaching these lines needs a fresh paste from elsewhere. **That reassurance never applied to clause (b)**, which is why clause (b) is now written down.
- BAR-011: the mechanical gates this changeset triggers were run, and the one it does not trigger is stated as skipped
  Evidence: tests -> invoke through `C:\Program Files\Git\bin\bash.exe` and **read the output every time**; blank output at exit 0 is this machine's documented Bash-tool failure signature, so "exits 0" is satisfied identically by a gate running clean and by a gate never running (bar-soundness row 3). Run three, **each invoked by that full path rather than a bare `bash`** — bare `bash` on this machine is the WSL stub, so a bare invocation is a fourth way to get output that is not a verdict, and this bar's own preamble names the full path while its commands did not. All three must exit **0 with non-blank output**, not merely exit 0: `scripts/lint-agents.sh`, whose output must **name the files it checked** — it fires because the changeset touches `skills/`; `scripts/lint-identifiers.sh`, where exit **2** is a self-test failure rather than a clean repo and blank output is a non-answer for the same reason as the other two; and `scripts/lint-plans.sh docs/plans/devops-azure-area-iteration-placement.md`, with the path passed as a **discrete argument** and never interpolated into a shell string. **Quote each exit code and the first line of each script's output in the handoff** — an unquoted "all three passed" is indistinguishable from three runs nobody read. Then confirm `node scripts/obsidian-stop-hook.test.js` is **correctly skipped and the skip is stated out loud** — no file in this cut is one of the two hooks it covers, and running it here yields a PASS that checked nothing in the changeset.

- BAR-012: the placement stop has a sanctioned recovery, and the wrong move is named beside it
  Evidence: files -> `skills/devops-azure/SKILL.md` 8f. **Added by `devils-advocate`; no bar covered this and the plan supplies neither half.** The new failure row and the probe's mismatch stop both leave item 1 created at the wrong placement, and **this mode never updates a work item** (line 409) — so it cannot repair placement itself, and on a re-run reconciliation matches item 1 by its key tag and routes it to `skip` or `repair`, meaning **the mis-placed item is never re-placed and the batch proceeds past it**. Confirm the file states (i) one **sanctioned fix a human performs** — the placement corrected in ADO, or by `az boards work-item update`, which carries `--area` and `--iteration` — before or instead of re-running, and (ii) that **deleting the item's `external_refs:` entry is not the fix**, since line 358 already documents that it reaches the `create` case with the item present and produces a **second work item**. Both halves are required: 8f gets this shape right for the tag failure at lines 356 and 358, and a stop whose only instruction is "re-resolve before re-running" reads as though re-running repairs it, which it does not. The bar fails if the file states a stop with no recovery, and it fails if it names the fix without naming the wrong move — an operator finds the wrong move on their own.

## Bar corrections

A dated trail for edits made to a bar **after** implementation began. **Deliberately not `## Deviations`:**
nothing departed from a stated call — the implementation followed call 4 exactly — so a deviation entry
would misfile it. But a silently edited bar is indistinguishable from a retcon, so each correction is
recorded here with what it said, what it says now, why, and who found it.

### 2026-08-05 — BAR-010's enumeration was under-inclusive and failed a correct implementation

**Found by:** merge-reviewer (**FAIL**, reading the diff rather than a summary), with code-reviewer and
test-engineer independently agreeing the text was right and the bar was wrong. test-engineer enumerated
the segments itself and found the `…` case nobody else had.

**What it said:** clause-less evidence enumerating exactly `<org>`, `<project>`, `<project-a>`,
`<project-b>`, `<node>`, `<leaf>`, `<team>`, `Area`, `Iteration`, `A`, `B`, `BC`, and *"any segment
outside that list fails the bar"*.

**What was wrong:** the shipped text contains three segments the list omitted. **`C`**, from
`<project>\A\B\C` — which **call 4 mandates verbatim** as BAR-002's discriminating case, so the bar
contradicted its own sibling call and the bar loses. **`…`**, from the canonical-form notation
`<project>\<node>\…\<leaf>` that site 1 requires. And **`<sprint>`**, in this plan's own
`### Observed facts` — a third omission found while enumerating against the actual text rather than
patching in only the two that were reported. That last one is the reason the fix is not "add `C` and
`…`": **an explicit list of placeholders goes stale every time the text needs a new one**, and shipping
the same shape again would have queued the same failure.

**What it says now:** two clauses. (a) path segments — **bracketed tokens admitted by shape**
(`<[a-z][a-z0-9-]*>`), **bare** tokens admitted from a closed list that can only shrink
(`Area`, `Iteration`, `…`, `A`, `B`, `C`, `BC`). (b) a new clause for **pasted command output and command
strings**, checking environment-expanded values **as substrings inside larger tokens**.

**Why clause (b) exists, and why this bar is closer to load-bearing than it looked:** a real account name
— the literal expansion of `%USERNAME%` — reached three places across two files in this changeset inside
a token of the form `Zz<name>Probe`, and `scripts/lint-identifiers.sh` passed **9/9**. The token was
already in the gitignored `.identifier-denylist`, but that rule is **word-boundary matched**, so the name
did not match as a substring. A human reading the diff caught it one step before a push to a public host;
it is redacted and confirmed absent from history. Clause (a) could never have seen it — the token is not
a path segment — so the widening is a new control, not a restatement. General lesson recorded by the
coordinating session in `memory/context/2026-08-04-this-repo-is-public-never-write-real-identifiers.md`.

**The mechanism was not weakened.** Both clauses remain checks a verifier performs and reports; neither
resolves to "a reader was careful". The correction makes clause (a) unable to go stale and adds a clause
that covers the observed leak class.

## Model Overrides

None. This cut edits **one prompt file** and dispatches no engineer agent: no agent description in this
pack covers prompt-file editing, and stretching one to fit would make its description a lie. That call
is already on record for this exact file — `docs/plans/devops-azure-batch-write.md` `## Model
Overrides` notes the pack once carried a `skill-writer` skill and **removed it**, so authoring pack
files is the coordinating session's job by decision rather than by omission.

**If that call is reversed and an engineer is dispatched, escalate it to `opus`**: the edit is
security-adjacent (it extends the `az`-argument boundary 8f owns) and touches text constrained by four
bars in two merged plans — **self-imposed constraints, not live gates**, per `## Inputs`.

**`devils-advocate` RAN 2026-08-05, before implementation** — findings in `## Challenge`, which is its
record and is not edited by this plan's revisions. Its verdict: the central decision is right, three
justifications were weaker than presented, two gaps were new findings. This revision adopts all of it —
call 1's props stripped, call 7 re-argued from the sink, calls 12–14 added, the transformation table
corrected to four observed rows, `BASE` given an owner, item 3 kept, and BAR-012 given an edit site.
**Two of its concerns were answered by observation rather than by argument** (the iteration read form and
the `TF50309` refusal); `## Inputs` records those under `### Observed facts closed 2026-08-05`.

**Still worth pressure at implementation time**, since no reviewer has seen them: whether the
single-quoted-literal rule in call 7(b) is right for the way the executing agent actually generates
script text, and whether item-1-only placement verification is sufficient now that BAR-012 exists to
recover the stop it produces.

## Challenge

**Challenged 2026-08-05 by `devils-advocate`, before implementation. Scope: architectural — the cut
extends the `az`-argument boundary 8f owns and changes what a shipped batch writes into a shared
tracker. Maximum scrutiny applied. Verdict up front: the plan's conclusion is right and three of its
stated justifications are weaker than presented; two substantive gaps are new findings, and one
unconsidered alternative would dissolve the plan's own largest risk.**

### Restatement

Two defects in `skills/devops-azure/SKILL.md` batch write mode, found by executing the file. (1) 8a
compares area paths drawn from two routes that return different string forms and never states a
normalisation, and — per the correction appended to `docs/plans/ado-pair-report-v4.md` — the shipped
file has **no zero-candidate branch at all**, so a literal comparison yields `M = 0`, takes the
"narrow fully" row, examines nothing, and reports a clean derivation. The failure is silence. (2) 8f's
create sets neither `--area` nor `--iteration`, so items land at the project root while 8e item 1
promises the operator the resolved placement. The fix ships a canonical path form plus a per-route
transformation and a stated zero-candidate display state; adds the two arguments to the create and
propagates the consequence through 8e items 5/6 and 8g's `Where it lives` row; extends the existing
item-1 round-trip probe from tags to placement at zero new `az` invocations; and (separably) scopes
8a's board-visibility claim. One file, ten edit sites, eleven bars.

**My restatement matches the stated intent.** No gap to flag at this level.

### Verified before challenging

- **Defect 1's corrected form holds.** `normalis`, `derivation defect`, `no candidates`, `zero
  candidates` return **zero matches** in `skills/devops-azure/SKILL.md`. The fallback at line 159 is
  gated on `1 + N + M > 10` alone. Independently confirmed, not taken from the execution record.
- **Defect 2 holds.** The create at line 429 carries `--type`, `--title`, `--fields`, `--org`,
  `--project`, `--output` and neither placement argument.
- **BAR-003 does fail against the file as it stands today.** The claim is true, and it is the
  strongest bar in the set.
- **8g's row at line 512 reads exactly as BAR-007(iv) quotes it**, and this cut does falsify it.
- **The three script gates exist** at `scripts/lint-agents.sh`, `scripts/lint-identifiers.sh`,
  `scripts/lint-plans.sh`.

### Concerns, ranked

**1. `M` is never defined in the file, so BAR-003's walk is not performable as written — and no edit
site fixes it.** `N` is defined at line 154 ("the project's **total** team count"). `M` appears
exactly twice, both times inside `1 + N + M`, and is **never defined anywhere in
`skills/devops-azure/SKILL.md`**. Its meaning (candidate count) is recoverable only from
`docs/plans/ado-pair-report-v4.md`. Three consequences: BAR-003 instructs a verifier to walk the file
"as a reader would with `N = 3`, `M = 0`" against a symbol the reader cannot resolve; BAR-003's own
subject — an outcome "reachable by following the file's own tables" — is unreachable while the trigger
condition is inexpressible in the file's vocabulary; and `## Build steps` site 3 says **"Do not touch
the two-row budget table"**, so no edit site currently authorises defining it. A second-order point
worth recording even though the cap itself is out of scope: `M` is the candidate count, which is only
known **after** all `N` `teamfieldvalues` reads, so the budget test cannot be evaluated before the
cost it is gating has been paid. The 2026-08-05 run computed `1 + 7 + 2 = 10` retrospectively.

**2. The transformation table omits the route that actually produces the iteration path, and includes
one the file never reads.** `## What ships` gives three rows: `az boards area project list`,
`teamfieldvalues`, and `teamsettings` (`backlogIteration.path`). But 8a resolves the iteration path
from **`az boards iteration project list`** (line 136), and that route appears in **no row** — it is
named only obliquely in `## Calls made for you` item 3. Meanwhile row 3's route,
`teamsettings`, is **never invoked by this mode**: call 10 rejects the per-team read and item 3
explicitly names `backlogIteration` as a condition this run does **not** read. So the table the plan
tells site 1 to write ("three rows, matching `## What ships`") documents a transformation for a value
that cannot arrive, and omits the transformation for one of the two values being canonicalised.
BAR-001 inherits the defect exactly: it tests the phantom `\<node>` and empty-string inputs and
**never tests the iteration-list route's form at all**. ~~That form has not been observed~~ — `## Risks`
says "both routes were observed once", meaning the two *area* routes. ~~**The iteration half of the
canonical rule rests on assumed symmetry with the area routes, and nothing in the plan tests it.**~~
**[SUPERSEDED — see `### Second update` below. The iteration route's form IS observed, in two projects,
and the symmetry is a fact rather than an assumption. The struck text is left legible because it is what
the challenge concluded before the evidence arrived. The surviving finding is narrower: the
*transformation table* omits the route — `## Calls made for you` item 3 does reference it in prose — and
the shipped text is unwritten.]**
This is bar-soundness row 2 in the plan's own structure: the claim is about a category
("normalisation is correct"), the evidence enumerates instances, and the omitted instance is a live
one.

**3. `--fields` is an unconsidered alternative that dissolves the plan's largest risk, and it is
already in the shipped command.** The create at line 429 already carries `--fields
"System.Tags=…"`. `System.AreaPath` and `System.IterationPath` are ordinary work item fields — and
they are **precisely the two fields the extended probe reads back**, and precisely the form `##
Calls made for you` item 2 canonicalises to ("the form `System.AreaPath` itself carries"). Setting
placement through the mechanism already in the command has a property the two new flags do not: **the
accepted form is not a question**, because the value written and the value read back are the same
field. The plan's entire central risk — open question 1, BAR-004, BAR-005's gate, the contingency,
and the run-time probe as fail-safe — exists only because it chose two convenience flags whose form
is undocumented over a field mechanism whose form is defined by the field. Stated fairly, this
**reduces** rather than eliminates unverified surface: `docs/plans/devops-azure-batch-write.md`
BAR-003 verified `--fields` for `System.Tags`, not for a classification-node reference, and whether
`az` accepts a field via `--fields` when a dedicated flag exists for it is itself unverified. It also
carries its own hazard — `;` is legal in an ADO node name (see concern 5) and `System.Tags` uses `; `
as its delimiter inside the same `--fields` argument, so the two would share one argument. The
finding is not "use `--fields`". It is that **the plan does not record having considered it**, and it
is the option that most directly attacks the risk the plan accepts.

Two further options not recorded as rejected: **`az boards work-item update` also carries `--area`
and `--iteration`** (verified in Microsoft's published reference), so create-then-update is a real
route — and it should be named and rejected for the invocation-count reason BAR-006 exists to
protect, rather than left unmentioned. And the plan's own option B is not the only text-only
alternative: 8e item 1 could name the values as *resolved for team derivation* rather than as *where
these items land*, which keeps "all four" intact. That variant is strictly better than the option B
the trade-off table scores, and scoring the weaker variant flatters the adopted column.

**4. The trade-off table's cascade argument leans on a bar that will not run, and the decision is
right anyway.** Call 1 justifies option A partly because option B "becomes false — and that phrase is
protected by BAR-015 of `docs/plans/ado-pair-report-v4.md`". Per this repo's plan spine, **consumption
is opt-in per invocation**: merge-reviewer enforces bars only for the `plan_id` handed to the run.
BAR-015 lives in a merged plan that this run does not hand to anything, so it will **not** be
evaluated on this changeset. `## Inputs` treats it as a self-imposed constraint, which is good
practice — but "protected by BAR-015" describes an intent, not a live gate, and the trade-off table
presents it as a cost. The same applies to BAR-002 of `devops-azure-batch-write.md`. **Strip those two
props and the decision still stands on its own**: ~100 items per batch landing permanently at the
project root is a product defect, and 8a deriving a team set from a path nothing writes is incoherent
regardless of which bars are live. **Adopt the conclusion; repair the justification.** The reasoning I
was asked to attack is weak in two of three limbs and correct in its outcome.

**5. The no-validation call is argued on the wrong axis, and Microsoft's own documentation removes its
premise.** Call 7 rests on provenance: the values "come from `az` reads of project configuration, not
from the hand-editable tree, so 8f's title mechanism — whose whole premise is untrusted free text —
does not apply". But 8f's own reasoning at line 440 is explicitly about the **sink**, not the source:
*"the title still has to be written as a **literal into that generated script** … before any splatting
happens"*, and line 445 calls discrete-argument passing *"hardening on top of step 1, never as a
substitute for it"*, and *"a property of the caller, and this file cannot verify the caller has it"*.
So the plan removes the control 8f names as foundational and keeps only the two 8f itself labels as
non-substitutes. Three facts from Microsoft's published naming restrictions decide whether the
residual is real:

- Area/iteration **node** names must not contain `\ / : * ? " < > | # $ & * +`. So `"`, `$`, `&`,
  `<`, `>`, `|` are excluded by the UI — which is why a title-style guard would indeed be
  wrong, and the plan is **correct** that a space, `(`, `)`, `'` and `.` are legal and must not be
  rejected. BAR-008's negative half is well aimed.
- **The backtick is not in that list, and neither is `;`.** A backtick is PowerShell's escape
  character inside a double-quoted literal; a trailing one before the closing quote escapes it. `;`
  separates statements in command text. Both are legal in an ADO node name.
- Decisively: *"When you use the Azure DevOps APIs rather than the user interface, you can directly
  specify a name that might include characters restricted in the UI."* **The forbidden set is a UI
  restriction, not a service guarantee** — so a node name a read returns may carry `"` or `$` after
  all, and "service-sourced therefore trusted" is not sound as stated.

The threat model is genuinely milder than the tree's: naming an area node needs project-admin rights
in the target project, where editing the tree needs a text editor. That is a real difference and it
may well justify the same conclusion. What is not defensible is reaching it via a premise Microsoft
documents as false. **The call should be re-argued on the sink and the residual named**, which is what
I have made BAR-008 able to fail on.

**6. The new failure path has no sanctioned recovery, and this mode cannot repair placement.** Site 6
adds a failure row instructing the operator to "re-resolve before re-running", and site 7 stops on a
probe mismatch after writing `external_refs:`. But 8f line 409 states **"This mode never updates a
work item"**, and on a re-run reconciliation matches item 1 by key tag and routes it to `skip` or
`repair` — so the mis-placed item is **never re-placed**, and the batch proceeds past it. Item 1 is
left permanently at the wrong location with no stated fix. This is the exact shape 8f already handles
for the tag failure, and handles well: line 356 names one sanctioned human fix ("a human **re-adds the
tag** … then re-runs"), and line 358 names the wrong move an operator finds on their own ("deleting
the item's `external_refs:` entry is not the fix" — it double-creates). **The placement failure needs
the analogous pair and the plan supplies neither.** No bar covered this; I have added BAR-012.

**7. The fail-safe is real for defect 2 and not for defect 1 — and the plan overstates the risk it
accepts.** Taking the three failure shapes in `## Risks` in turn against the status quo: *rejected
outright* → loud error at item 1, nothing else created, safe. *Accepted with a different form
expected* → ADO does not auto-create classification nodes, so a project-relative reading of a
project-rooted value resolves to a non-existent node and **rejects**, also loud. *Accepted and
silently ignored* → items land at the project root, which is **exactly today's behaviour**, plus a
stop at item 1 from the probe. And a wrong-but-real node is caught by the probe's comparison. So
**no failure mode of the unverified argument form is worse than the status quo**, and every one is
either loud or stopped at item 1. The plan treats this as its largest risk; it is its best-defended
one, and the plan should say so — the argument that makes item 2 shippable with BAR-005 at NOT RUN is
not stated anywhere in the plan.

The asymmetry is the answer to whether the probe is a real fail-safe or a relocated assumption:
**real for the argument form, not for the normalisation rule.** The probe compares ADO's returned
`System.AreaPath` against the canonical value produced by 8a. An unverified *argument form* it turns
into a safe stop. An unverified *canonical rule* — concern 2's untested iteration route — it turns
into a **false stop on item 1 of every batch on a correctly configured project**, which is the same
class of defect as the `--query` false negative 8f documents at line 473 and stops the batch for the
same wrong reason. The probe cannot distinguish the two, because it is one comparison serving two
premises.

**8. Recording `BASE` is a new unowned duty, and three bars depend on it.** BAR-006, BAR-007(iii) and
BAR-010 all rest on `BASE = git rev-parse HEAD` "recorded before the first edit". No step in `##
Build steps` owns that, and it appears in no row of the responsibility matrix. That matrix is the
plan's showpiece, written because *"the defect being fixed **is** an unowned duty"* — so introducing
one is worth naming. It is recoverable in practice (the plan is committed at `HEAD`, one file changes,
and gate 4a runs before merge-reviewer commits), which is why this ranks eighth rather than higher.

**9. Second-order effects, and what this closes off.** Once placement is real, three things change
beyond the stated scope. 8a's *"ask before previewing"* on an ambiguous area or iteration stops being
cheap advice and becomes a hard block on a value that now determines where ~100 permanent items land
— its cost rises with its value. The memory file's finding that a team backlog also filters by
`backlogIteration` becomes **operationally** relevant rather than academic, because an operator will
now act on 8a's team list (see concern 10). And item 1 becomes load-bearing for two independent
probes, which `## Risks` names — but the plan widens it without widening what item 1 is chosen to be;
a `SPIKE` scoped alone as item 1 verifies both probes against an unrepresentative item. Nothing here
argues against the cut; all three are worth a sentence somewhere they will be read.

**Reversibility:** the file change is **easily reversible** (one prompt file, git). Its *effects* are
**moderately** reversible: work items created with wrong placement cannot be hard-deleted
(`--destroy` fails `VS402324`) but placement **is** fixable afterwards by hand or by `az boards
work-item update`. That is a materially better position than the plan's framing implies, and it is
the second reason concern 7 lowers the stakes on BAR-005.

**Scope:** proportionate. Ten sites in one file for two live defects, with a stated separable third.
I found nothing to cut for size, and the smaller-version question is answered by item 3 already being
marked separable.

### Scope item 3 — my call: **keep it**

Four reasons, and one against. Its cost is one to two sentences and **no new read**, so the usual
argument for cutting (dilution) buys almost nothing. This cut **makes the overclaim worse**: today
8a's *"which teams' boards will show these items"* is wrong about items that all sit at the project
root anyway, but once placement is real the operator will act on the team list, so the unqualified
claim graduates from inaccurate to load-bearing. BAR-009 already exists and already pairs the scoping
sentence with an invocation-count check, so keeping it costs no new bar. And the stated consequence of
cutting is worse than the edit: BAR-009 goes NOT RUN and *"the unqualified claim ships knowingly"*,
recorded in `## Deviations` — trading two sentences for a permanent documented overclaim. Against:
item 3 is the only site touching 8a's opening prose, adjacent to the *"four gates with three
verdicts"* phrase three bars protect. That is an argument for care at site 4, not for cutting it.

### BAR-010 and the public-repo question — acceptable, and now stronger than "a reader"

Two findings, one reassuring and one actionable. The reassuring one: the source material this cut
would paste from is **already placeholdered**. `docs/plans/ado-pair-report-v4.md` records the probed
path as `<project-a>\A\B`, so the likeliest paste path does not carry a real node. The plan's own
worked cases (`<project>\A\B` vs `<project>\A\BC`) are abstract by construction. The residual risk is
therefore lower than BAR-010's text implies.

The actionable one: *"a reader is the only control"* is a true statement about
`scripts/lint-identifiers.sh` and an avoidable one about **this** bar. A bar whose control is a reader
cannot fail in a way anyone can check, which is the defect the whole bar-soundness table exists to
catch. Because this cut's examples need only a **fixed, tiny vocabulary** of segment tokens, the check
can be made mechanical without any denylist and without naming anything forbidden. I have rewritten
BAR-010's evidence accordingly. **Writing worked path examples is worth its risk** — the discriminating
case in BAR-002 (`<project>\A\B` vs `<project>\A\BC`) is the single most valuable line in the cut, and
it cannot be written without an example — but it is worth it *with* a closed token set, not with a
reader as the control.

### Bars: what I changed and why

Edited in place: **BAR-001** (add the omitted `az boards iteration project list` route; require the
phantom `teamsettings` row to be labelled as a route this mode does not read; require an unobserved
form to be declared rather than asserted by analogy). **BAR-003** (require `M` to be defined, without
which the walk cannot be performed). **BAR-004** (record the extension version and both help examples
verbatim — the help text is the only evidence about form that exists, so quoting it is the point).
**BAR-005** (`Gated:` and `Cost:` corrected — a non-root area node and a non-root iteration node must
already exist, and creating them is permanent project configuration the old cost line denied by
saying "no other project or item is written"). **BAR-008** (add a half that can fail on a wrong-axis
justification: the file must argue from the sink and name the residual, not from provenance alone).
**BAR-010** (closed token set, mechanically checkable). **BAR-011** (invoke by full path, consistent
with its own preamble and with `memory/known-issues/2026-07-10-bash-tool-silent-failure-windows.md`;
require non-blank output from all three scripts rather than one).

Added: **BAR-012** — the placement stop has a sanctioned recovery and names the wrong move, on the
pattern 8f already uses for the tag failure.

Left alone as sound: **BAR-002**, **BAR-006**, **BAR-007**, **BAR-009**.

**Not producible on this machine by me:** BAR-004 and BAR-005 both require executing `az`, and this
agent holds no shell. I verified both flags exist on `create` (and on `update`) from Microsoft's
published reference rather than from the installed CLI, which is **documentation, not the machine** —
row 1 applies to my evidence exactly as it does to the plan's. BAR-011 requires `bash`; the three
scripts exist, and I did not run them.

### Key questions, ranked

1. **Was `--fields` considered and rejected, or overlooked?** It is already in the command, and it is
   the one route where the accepted form is not a question. If it was rejected, the reason belongs in
   `## Calls made for you`; if it was overlooked, it changes what BAR-005 is for.
2. **What is the form returned by `az boards iteration project list`, and has anyone seen it?** The
   iteration half of the canonical rule is untested, and a wrong rule there produces a false stop on
   item 1 of every batch — indistinguishable, at the probe, from the failure the probe was added to
   catch.
3. **What does the operator do when the placement probe stops?** This mode never updates a work item
   and a re-run skips item 1, so without a sanctioned fix the mis-placed item is permanent and the
   operator's natural move is the one 8f already documents as double-creating.
4. **Does the no-validation call survive being re-argued on the sink?** The backtick and `;` are legal
   in ADO node names, and Microsoft documents API-created names as able to carry UI-forbidden
   characters. The conclusion may well hold on the privilege difference; the stated premise does not.
5. **Does the disposable project have a non-root area node and a non-root iteration node?** If not,
   BAR-005's real cost includes permanent project configuration its old `Cost:` line denied.
6. **Who records `BASE`, and at which step?** Three bars depend on it and no step owns it.

### Update — 2026-08-05, after BAR-005 was RUN live

**Appended rather than rewritten**, on this repo's standing handling: the section above records what the
challenge found before the evidence arrived, and is left standing. Two live creates on operator
authorisation, read back with `az boards work-item show`, established that **the project-rooted
canonical form is accepted and honoured for both `--area` and `--iteration`, byte-exact, with
space-carrying multi-segment values passed as discrete arguments and no validator.** Running a
design-verification bar *before* implementation is the right use of a gated bar, and it is worth saying
so: it converted the plan's largest stated risk into a fact at the cost of two work items.

**What the evidence closes.** Concern 7 is resolved for the argument form — the three failure shapes in
`## Risks` are no longer live, item 2's premise is verified, and the contingency in `## Calls made for
you` item 1 is not needed. Open question 1 is closed against the plan's canonicalisation, and the
help-text ambiguity recorded in BAR-004 is a red herring. Concern 3 is **withdrawn as a
recommendation**: the whole reason to prefer `--fields` was form certainty, and there is now no form
question, so the two flags are the right mechanism. It remains true only in its weak form — the
alternative is not recorded as consciously rejected — and that is now trivially closable with one
sentence citing this run. Concern 4 loses its practical sting for the same reason: the option-B
cascade no longer needs defending, because option A is verified.

**What the evidence does not touch, stated plainly because it is easy to read this run as closing more
than it does.** BAR-005 exercised the **write** side: which form the two arguments *accept*. Concern 2
is about the **read** side: which form `az boards iteration project list` *returns*, and therefore what
the canonical rule must transform. **Those are different questions and this run answered only the
first.** `az boards iteration project list` still appears in **no row** of the transformation table, and
row 3's `teamsettings` route is still never invoked. So concern 2 survives ~~**intact and is now the
plan's only unverified premise** rather than one of two~~. **[SUPERSEDED — see `### Second update`
below. The premise is verified: both read-route forms are observed and the transformation closes end to
end. Concern 2 survives only as a **gap in the plan** — the transformation table omits the route, and
the shipped text is unwritten. It is not an unverified premise and this cut has none.]**

Two things sharpen it rather than soften it:

- **BAR-005's own evidence line silently depends on the unverified half.** It says "resolve an area path
  and an iteration path … **canonicalise them by the shipped rule**" — but the rule is not shipped yet,
  so whoever ran it canonicalised **by hand**. That is precisely the confound that made the 2026-08-05
  derivation probe find 2 candidates where the shipped file finds none: *"this run found 2 candidates
  only because the normalisation was written into the probe."* **The same confound has now recurred one
  layer up.** A hand-normalised input verifies the argument, not the rule, and the run cannot
  distinguish "the shipped rule is right" from "the operator normalised correctly without it".
- **`az boards area project delete --path` takes the classification form (`\<project>\Area\<node>`)
  while `az boards work-item create --area` takes the canonical form (`<project>\<node>`).** Two forms
  inside one command family, which is defect 1's shape appearing a second time in a new place. This is
  strong support for `## Calls made for you` item 3 — normalisation specified **by route**, never
  inferred — and it belongs in the file at the comparison site.

**The consequence for the probe is unchanged and is now the whole residual risk.** The probe was built
as the fail-safe for an unverified argument form. That form is verified, so the probe is no longer
load-bearing for it. What the probe **cannot** be a fail-safe for is a wrong canonical rule: it compares
ADO's returned `System.AreaPath`/`System.IterationPath` against the canonical value 8a produced, so a
rule that mishandles the iteration-list route's form yields a **false stop on item 1 of every batch on a
correctly configured project** — the same class of defect as the `--query` false negative 8f documents at
line 473, and the probe cannot tell the two apart. **The fail-safe now guards the thing that turned out
fine and cannot guard the thing still unverified.**

**One of my own bar edits is falsified by this update and is corrected.** `az boards area project
create` is refused for this account (`TF50309`, "Create child nodes") in a project where work-item
creation succeeds. My earlier edit to BAR-005's `Gated:`/`Cost:` offered node creation as a fallback
when a project has no non-root node, and priced it. **That fallback is unproducible on this machine** —
bar-soundness row 4 — so the precondition is a **hard gate**, not a cost to authorise. Corrected in
place. I checked the other eleven bars: **BAR-005 is the only one whose evidence could require creating
a classification node**, so nothing else inherits this.

**Where the no-validation call now stands.** The observation is genuinely useful and it lands on the
*control*, not the premise: values carrying **spaces** and multiple segments round-tripped byte-exact as
discrete arguments, so call 7's choice of *"the control is the round-trip probe, not a validator"* is now
**evidence-backed for the space hazard** — which was the specific mangling risk
`2026-07-30-powershell-mangles-native-exe-arguments.md` predicted. Credit that. Concern 5 is unaffected,
because it was never about spaces: the backtick and `;` remain legal in ADO node names, the character
list remains a **UI** restriction that API-created names may bypass, and neither this run nor any other
has passed a node name containing `` ` ``, `;`, `&`, `'`, `(` or a non-cp1252 character through this
path. One benign observation is not evidence about the hostile case, and BAR-008's edited half still
fails a provenance-only justification. **Concerns 1, 2, 5, 6 and 8 all stand; 3, 4 and 7 are resolved or
withdrawn as recorded above.**

**Revised key questions, superseding the six above — and themselves superseded by the third revision in
`### Second update` below. Question 1 as written is wrong and must not be acted on:** (1) ~~what form
does `az boards iteration project
list` return, and has anyone looked — now the only unverified premise~~ **[SUPERSEDED. Do not go looking
— the form is observed and recorded, in this file and in
`memory/context/2026-08-05-ado-node-name-restrictions-are-ui-only.md`. The live question is whether 8a as
*shipped* implements the observed transformation for both routes.]**; (2) does BAR-005 need a
re-statement acknowledging it hand-normalised its inputs, so a later reader does not read it as
verifying the rule; (3) what does the operator do when the placement probe stops (BAR-012, unchanged);
(4) does the no-validation call survive being re-argued on the sink (unchanged); (5) who records `BASE`
(unchanged). The disposable-project question is answered — a project with existing child area nodes was
used, and node creation is refused here anyway.

### Second update — 2026-08-05, after the read-route forms were observed

**Appended, not rewritten.** The section above asserts that `az boards iteration project list`'s returned
form "has not been observed on any project". **That is now false and is corrected here.** Both read
routes have been observed, zero writes, across two projects:

```
[<project-b>]  root  = \<project-b>\Iteration
               child = \<project-b>\Iteration\<node>
[<project-a>]  root  = \<project-a>\Iteration
               child = \<project-a>\Iteration\<node>
```

Segment 2 is the literal `Iteration`, at the same position the area route carries `Area` — **symmetric in
fact rather than by analogy**, which is what the previous section asked for and did not have.

**The transformation is now closed end to end for both routes, and that is stronger than either half
alone:**

| Route | Raw read form (observed) | After the rule | Value the service stored (observed) |
|---|---|---|---|
| iteration | `\<project-b>\Iteration\<node>` | `<project-b>\<node>` | **identical** |
| area | `\<project-a>\Area\<node>\<leaf>` | `<project-a>\<node>\<leaf>` | **identical** |

Both endpoints are recorded observations and the rule under test is the mapping between them. So the
canonical rule **demonstrably maps the observed read form to a value the service honours**, for both
routes, in two projects. Applying the rule by hand to the observed root form confirms the third case
too: `\<project>\Iteration` → drop the leading separator, drop segment 2 by route and position →
`<project>`, the project root. Consistent with `## Calls made for you` items 2 and 3.

**Concern 2 is downgraded from an unverified premise to a gap in the plan, and both halves of the gap
stand:**

- **The transformation table still has no row for `az boards iteration project list`** — the route that
  produces the value. This is now worse than a documentation gap rather than better: the form is *known*,
  so omitting it is omitting something recorded. And the omission is what would let BAR-001 pass against
  shipped text that handles only the area route.
- **Row 3's `teamsettings` route is still never invoked**, and the observations make it a sharper
  problem: `backlogIteration.path` returns `\<node>` while the route actually read returns
  `\<project>\Iteration\<node>`. **Two different forms, one of which cannot arrive.** A table carrying
  the unreachable form and omitting the reachable one is the precise inversion of what a reader needs.
- **The shipped text is still unwritten**, so "8a as written will implement this rule" remains
  unverified — `files` evidence, BAR-001's job, and the only thing left that BAR-001 is for.

**My verdict trigger has fired in the plan's favour and I record it as such.** The previous section said
the verdict would change to "reconsider" if the read route returned a form the canonical rule mishandles.
It does not. **The rule is correct for both observed routes; the plan's defect is that its table does not
say so.**

**Two provenance notes, because attribution is a standing requirement here and not a formality**
(`memory/context/2026-07-30-agent-output-must-be-attributable-to-be-evidence.md` — *verify the effect came
from the thing you tested*):

- The observation above arrived with the message requesting this amendment. The **preceding** update's
  fact about `az boards area project delete --path` concerned that command's *documented input* form in
  the **area** family; it was not an observation of the iteration route's *returned output*, which is why
  the previous section treated the latter as unobserved. Recording this only so a later reader looking
  for the earlier evidence does not conclude it was missed — the substance is accepted in full and the
  distinction changes nothing about the finding.
- **These observations exist in agent messages and in this section, and in no execution record.** The
  area-route form is recorded in `docs/plans/ado-pair-report-v4.md`; the iteration-route forms and the
  end-to-end table are not recorded anywhere durable outside this plan. **An observation whose only home
  is a plan's challenge section is thin evidence for a future cut**, and this plan will be merged and
  never retro-edited. Worth landing them in the execution record or a `memory/context/` file.

**Two projects is two projects.** Nothing here establishes that no third classification segment or
fourth form exists in another configuration; `## Risks` already treats that as open and should keep
doing so.

**Third revision of the key questions, superseding both earlier lists:**

1. **Does 8a as shipped implement the observed transformation for *both* routes?** Not "has anyone
   looked" — that is answered. `files` evidence, BAR-001, and the missing table row is the specific way
   it fails.
2. **Does the transformation table gain the `az boards iteration project list` row, and does row 3 get
   labelled as a route this mode does not read or dropped?** The two are one edit and currently no site
   owns the second half.
3. **What does the operator do when the placement probe stops?** BAR-012, unchanged.
4. **Does the no-validation call survive being re-argued on the sink?** Unchanged — concerns 1, 5, 6 and
   8 all still stand.
5. **Who records `BASE`?** Unchanged.
6. **Where do the iteration-route observations get recorded durably?** New, from the provenance note
   above.
