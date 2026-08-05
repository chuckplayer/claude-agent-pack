**Date:** 2026-08-05
**Type:** finding
**Status:** active
**Superseded-by:** n/a
**Scope:** `skills/devops-azure/SKILL.md` batch write mode — 8a area/team resolution and 8f create
**Overrides-convention:** no
**Related-to:** docs/plans/devops-azure-area-iteration-placement.md (its `## Challenge` section holds the full narrative), 2026-08-05-ado-node-name-restrictions-are-ui-only.md, 2026-08-05-ado-team-backlog-filters-by-iteration-too.md

## Summary

Challenged `docs/plans/devops-azure-area-iteration-placement.md` before implementation: a plan fixing
two live defects in batch write mode — 8a's unstated area-path normalisation (whose real failure is
**silence**, since the shipped file has no zero-candidate branch at all) and 8f's create setting
neither `--area` nor `--iteration`. **The plan's central decision — set the two arguments rather than
correct 8e item 1's promise — is correct, and two of its three stated justifications are weaker than
presented.** Nine concerns raised; two are substantive gaps nothing else caught. Eight bars edited or
added. The session ended without the operator resolving them, so every concern below is recorded with
its state.

## Context

`/plan` produced an 11-bar plan that passes `scripts/lint-plans.sh` 17/0 structurally. Structure is
not soundness, and bar auditing is `devils-advocate`'s exclusive job in this pipeline. The defects
were found by **executing** the skill on 2026-08-05 (`docs/plans/ado-pair-report-v4.md`, `## EXECUTED
2026-08-05 (second)`), not by reading it — the 120-item batch wrote every item to the project-root
iteration.

## Concerns Raised

- **`M` is undefined in the skill file — Unresolved.** `N` is defined ("the project's total team
  count"); `M` occurs twice, only inside `1 + N + M`, and is defined nowhere. Its meaning is
  recoverable only from a plan file. BAR-003 instructs a walk with `M = 0` against an unresolvable
  symbol, and no edit site authorises defining it (site 3 forbids touching the budget table). Bar
  edited to require the definition. **Second-order, out of this cut's scope but recorded:** `M` is the
  candidate count, known only *after* all `N` reads, so the budget test cannot be evaluated before the
  cost it gates has been paid.

- **The transformation table omits the route that produces the iteration path, and includes one never
  read — Unresolved as a GAP IN THE PLAN. The underlying premise is verified.** 8a resolves iterations
  from `az boards iteration project list`, which appears in **no row**; row 3's
  `teamsettings`/`backlogIteration.path` route is **never invoked** (the per-team read is explicitly
  rejected). BAR-001 tested the phantom inputs and not the live one.

  **The premise question is closed by observation, and this bullet was wrong on it for one revision.**
  An earlier revision of this file called the iteration route's returned form unobserved. It has been
  observed on two projects, zero writes: `\<project>\Iteration\<node>` for a child, `\<project>\Iteration`
  for the root — **symmetric with the area route in fact, not by analogy**, segment 2 being the literal
  classification name at the same position. And the transformation is closed **end to end**: the observed
  raw form canonicalises to a value the service was observed to store **identically**, for both routes.
  Forms and both tables are recorded in `2026-08-05-ado-node-name-restrictions-are-ui-only.md`, which is
  their durable home — they existed only in agent messages until then.

  **What remains is the shipped text, and it is BAR-001's whole job.** "8a as written implements this
  rule" is unverified because the text is unwritten, and the missing table row is the specific way it
  could fail: text handling only the area route passes every area-side check while leaving the iteration
  route untransformed. Consequence if that ships: the probe turns it into a **false stop on item 1 of
  every batch on a correctly configured project** — the same class of defect as the `--query` false
  negative 8f documents.

  **Row 3 is a sharper problem after the observations, not a softer one:** `backlogIteration.path`
  returns `\<node>`, a form **no other route returns and which cannot arrive here**, while the route
  actually read returns `\<project>\Iteration\<node>`. The table carries the unreachable form and omits
  the reachable one.

  **BAR-005 does not close BAR-001, and the distinction is still the most useful thing in this file.**
  BAR-005 verified the **write** side (which form the two arguments accept). BAR-001 is about whether the
  **shipped text** maps an observed read form onto that accepted value. And BAR-005's evidence line says
  to "canonicalise them by the shipped rule", which did not exist when it ran, so its inputs were
  normalised **by hand** — the same confound that made the 2026-08-05 derivation probe find candidates
  the shipped file cannot, recurring one layer up. **A hand-normalised input verifies the argument, never
  the rule.**

- **`--fields` as an alternative — WITHDRAWN as a recommendation; residually open only as
  bookkeeping.** The entire reason to prefer it was form certainty, and BAR-005 removed the form
  question, so the two flags are the right mechanism. What remains true is only that neither `--fields`
  nor `az boards work-item update` (which also carries both flags) is recorded as consciously
  rejected — closable with one sentence citing the run. **Do not revive this as a design argument.**

- **The trade-off table leans on bars that will not run — Accepted risk, justification needs
  repair; practical sting removed.** Call 1 costs option B partly as falsifying a phrase "protected by
  BAR-015" of a **merged** plan. Plan consumption is opt-in per invocation, so BAR-015 and
  `devops-azure-batch-write.md` BAR-002 will **not** be evaluated on this changeset; they are
  documented intent, not live gates. The decision survives without them, and BAR-005 has since verified
  option A outright, so the cascade no longer needs defending at all. Revisit only if anyone cites
  those bars as a live constraint.

- **The no-validation call is argued on the wrong axis — Unresolved.** Call 7 argues from
  **provenance**; 8f's own reasoning is about the **sink** (the value becomes a literal inside
  generated script text before argument passing helps), and 8f calls discrete-argument passing
  "hardening … never a substitute". See
  `2026-08-05-ado-node-name-restrictions-are-ui-only.md`: the backtick and `;` are legal in node
  names, and the character restrictions are **UI-only**. The plan is nonetheless **right** that a
  title-style guard must not be applied — space, `(`, `)`, `'`, `.` are all legal. BAR-008 edited to
  fail on a provenance-only justification. The privilege gap (project admin vs. text editor) is a
  legitimate acceptance reason; the stated premise is not.

- **The placement stop has no sanctioned recovery — Unresolved; new bar added.** This mode never
  updates a work item, and a re-run matches item 1 by key tag and routes it to `skip`/`repair` — so a
  mis-placed item 1 is **never re-placed** and the batch proceeds past it. 8f gets this shape right for
  the tag failure (a human re-adds the tag; deleting `external_refs:` double-creates) and the plan
  supplies neither half. Added as **BAR-012**.

- **The unverified argument form — RESOLVED by execution, 2026-08-05.** BAR-005 was RUN before
  implementation on operator authorisation: two live creates, non-root values, `System.AreaPath` and
  `System.IterationPath` stored **byte-exact** from the project-rooted canonical form. Neither argument
  is silently ignored; `az`'s project-relative-looking help example is a red herring; the plan's
  contingency is unneeded. **The pre-evidence analysis is retained because its conclusion outlived its
  subject:** every failure mode was already no worse than the status quo (rejected → loud stop;
  wrong form → ADO does not auto-create classification nodes so it rejects, also loud;
  accepted-and-ignored → today's behaviour plus a probe stop). **The residual irony is the finding worth
  keeping:** the probe was built as the fail-safe for the form, which turned out fine, and it **cannot**
  be a fail-safe for a wrong canonical rule — it compares against the value 8a produced, so a bad rule
  yields a false stop indistinguishable from a real failure.

- **BAR-005's `Gated:`/`Cost:` — Addressed, after one wrong correction of my own.** The original line
  said "No other project or item is written" while the bar requires a **non-root** area and iteration
  path; I first corrected this by pricing classification-node creation as a fallback. **That fallback is
  unproducible here:** `az boards area project create` is refused for this account (`TF50309`, "Create
  child nodes") in a project where work-item creation succeeds. So the precondition is a **hard gate**,
  not a cost — bar-soundness row 4, not row 6 — and the original sentence is true once the gate is hard.
  Corrected again in place. **BAR-005 is the only bar of the twelve whose evidence could require creating
  a classification node**, checked explicitly, so nothing else inherits this.

- **Recording `BASE` is a new unowned duty — Accepted risk.** BAR-006, BAR-007(iii) and BAR-010 depend
  on it; no build step or matrix row owns it. Notable because the plan's centrepiece matrix exists
  *because* "the defect being fixed is an unowned duty". Recoverable in practice: the plan is committed
  at `HEAD`, one file changes, gate 4a runs before merge-reviewer commits.

- **Scope item 3 (8a's board overclaim) — recommended KEEP.** One to two sentences, no new read;
  BAR-009 already exists; and this cut makes the overclaim *worse*, because once placement is real the
  operator acts on the team list. Cutting it costs a permanent documented overclaim recorded in
  `## Deviations` — a bad trade for two sentences. Decision belongs to the operator.

## Implications

- **The distinction to carry forward is premise vs. shipped text, and it survived two corrections.**
  Every factual premise of this cut is now verified by execution: which form each read route returns,
  which form the two arguments accept, and that the transformation between them round-trips. **What is
  unverified is whether the prose will implement it** — which is `files` evidence and exactly what
  BAR-001 exists for. Anyone who reads "the premises are verified" as "the cut is safe" has skipped the
  only remaining check.
- **A probe handed hand-normalised inputs cannot test the normalisation rule.** This confound has now
  appeared twice in this work — once in the 2026-08-05 derivation probe and once in BAR-005 — and both
  times it produced a result that read as broader than it was. Worth recognising on sight.
- **Concerns 2 and 6 are the two nothing else would have caught**, and both are about the *iteration*
  half of the work rather than the area half. Anyone re-reviewing this cut should start there.
- The plan's **conclusion is sound; three of its arguments were not, and two are now verified outright.**
  Do not re-litigate the create-argument decision — it is settled by evidence, not by argument.
- **This file was wrong twice and corrected twice, both times by evidence arriving after the analysis.**
  Recorded deliberately: the challenge's value was in the two structural gaps (concern 2's missing table
  row, concern 6's absent recovery path), neither of which any amount of execution would have surfaced,
  while its risk assessments were superseded by cheap live reads. **Prefer executing a premise to
  arguing about it** — but note that both surviving findings are about *unwritten text* and *unowned
  duties*, which execution cannot reach.
- **A live observation narrowed the validation question without closing it.** Space-carrying,
  multi-segment values round-tripped byte-exact as discrete arguments with no validator, so call 7's
  choice of the probe as the control is evidence-backed **for the space hazard**. It is one benign
  observation: the backtick and `;` remain legal in node names, the restriction list remains UI-only,
  and no hostile or non-cp1252 value has traversed this path. See
  `2026-08-05-ado-node-name-restrictions-are-ui-only.md`.
- **That verdict trigger has fired, in the plan's favour.** An earlier revision said the verdict would
  change to "reconsider" if `az boards iteration project list` returned a form the canonical rule
  mishandles. **It does not** — the rule is correct for both observed routes. What would now change the
  verdict is narrower and entirely internal: shipped 8a text that transforms only the area route, or a
  third classification segment turning up in a configuration beyond the two probed.
