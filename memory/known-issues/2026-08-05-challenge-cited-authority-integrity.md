**Date:** 2026-08-05
**Type:** finding
**Status:** active
**Superseded-by:** n/a
**Scope:** global
**Overrides-convention:** no
**Related-to:** docs/plans/cited-authority-integrity.md

## Summary

Challenged `docs/plans/cited-authority-integrity.md` before implementation — a three-change cut adding
(1) single-writer discipline on the plan file, (2) a `docs/rules/authorities.tsv` manifest plus
`scripts/lint-authorities.sh` and a new blocking gate 2d, and (3) a probe of whether agent `skills:`
frontmatter binds outside a plugin. **The plan received no author narrative: `tech-lead` wrote it and
then went idle twice without reporting, including once after re-dispatch**, so this challenge was the
only judgement the plan got. Verdict: **change 1 is shippable with BAR-007 corrected; change 2 has two
unanswered design questions that must be closed before the checker can be written; change 3's bar
enforces only a file's existence.** Fourteen bars reviewed, eight edited, six left alone. The dominant
finding is that **the "shared literal" the checker is built around is two different strings with
different consumers, and the plan treats them as one** — no byte-equality rule can be written from the
plan as it stands. Nine concerns below, all recorded as unresolved: the session ended without the
operator deciding.

## Context

The team lead dispatched devils-advocate against the plan on `main` (clean tree at `7819005`), after
`scripts/lint-plans.sh` passed it 22/0 with 14 bars and the `## Deviations` sentinel intact. The cut is
motivated by an observed loss earlier the same day: `tech-lead` and `devils-advocate` both wrote
`BAR-008` of `docs/plans/devops-azure-area-iteration-placement.md`, tech-lead's whole-file `Write` won,
and three of devils-advocate's clauses vanished with no signal — caught only because merge-reviewer
happened to ask devils-advocate to vouch for its own edits and got an honest "I cannot."

## Concerns Raised

### 1. The declared shared literal is two strings, not one — the checker is unspecifiable as written
**Unresolved.** The plan describes the `## Deviations` sentinel as "one literal string across four
files." The tree holds two strings with different failure consequences:

- **The grep needle** `Deviations not yet reviewed` — held by `scripts/lint-plans.sh:61`,
  `agents/merge-reviewer.md:419`, `skills/implement/SKILL.md:182`, `scripts/lint-plans.sh:100` (the
  script's own self-test fixture), and quoted in
  `memory/context/2026-08-05-pipefail-plus-short-circuiting-grep-returns-141.md:32`. If this changes,
  four greps break.
- **The full three-line template** — held in full only at `agents/tech-lead.md:95`.
  `scripts/lint-plans.sh:100` holds a **truncated one-line** copy. If the wording *after* the prefix
  changes, nothing breaks.

A byte-equality rule fails at four sites if it picks the template, and matches every file in
`docs/plans/` plus a memory quotation if it picks the needle. **The design does not distinguish a
must-match site from a file that merely quotes the string**, which is the distinction the rule needs to
exist at all. Verified count: **six occurrences across five non-plan files**, not the plan's
four-files/five-occurrences — but the class is the defect, not the count.

### 2. The checker's excluded scope exists only inside one bar's `grep -v`
**Unresolved.** BAR-004's evidence filters `./docs/plans/` and `./memory/` out of "the tree's actual
set" while the bar asserts equality *with* the tree — bar-soundness row 5, self-exemption. Both
exclusions are load-bearing: without them BAR-011's "`lint-authorities.sh` exits 0 on the post-change
tree" is unsatisfiable on day one. Yet the exclusions appear in no call, no narrative section, and no
responsibility-matrix block. Sharpest form: **BAR-004's own evidence line contains the literal it
counts**, so any file documenting the rule violates it. Edited into BAR-004 and BAR-011 as a
precondition; not resolved, because deciding the scope is the operator's call, not the reviewer's.

### 3. BAR-007 cannot distinguish a compliant revision from a stalled agent
**Unresolved; bar edited.** The reproduction compares one bar's text before and after a `tech-lead`
revision. A `tech-lead` that stalls and writes nothing produces a byte-identical bar exactly as a
compliant `Edit` does — bar-soundness row 3, and not hypothetical: it is what happened to this plan's
own author twice the same day. Edited to require the revised section be shown to have changed as well,
so "target bar unchanged **and** revised section changed" is the pass.

### 4. BAR-009's `git diff --stat` was blind to a staged change
**Unresolved; bar edited.** Bare `git diff --stat <path>` compares working tree to **index**, so a
`git add`-ed modification prints the same empty output as no modification — in the half the bar itself
calls load-bearing. Edited to name a ref.

### 5. The `skills:` probe latently conflicts with BAR-009, and its file has no stated home
**Unresolved; bar edited.** BAR-008 tests an agent frontmatter field while BAR-009 requires
`scripts/lint-agents.sh` byte-unchanged and passing, and `AGENT_VALID_FIELDS` at
`scripts/lint-agents.sh:18` rejects `skills:`. Adding the field anywhere under `agents/` in this repo
fails BAR-009 *and* blocks the linter. The probe is producible only against an installed agent under
`~/.claude/agents/`, and the plan never says so — a reader following BAR-008 literally breaks two gates.
Separately, BAR-008's own text concedes it proves nothing (nothing depends on the outcome, a verdict
could be fabricated) and it is `NOT RUN` in this cut, so it reduces to "a file exists." Whether change 3
warrants a bar or is a task with a recorded verdict was left to the operator.

### 6. Registry rot is already present in the pack's existing registry, and BAR-013 passed through it
**Unresolved; bar edited.** The caller's worry that `authorities.tsv` becomes the enumeration that rots
is stronger than predicted, because it has already happened to `memory/architecture/repo-map.md`: line
33 enumerates merge-reviewer's gates as **2a and 2b, omitting 2c**, and **`scripts/lint-identifiers.sh`
has no entry anywhere in the file** — the most recently added gate is absent from the map twice.
BAR-013 as written would pass by adding two entries while that stays wrong and 2d joins 2c in absence
(row 2: instances named, category asserted). This is evidence about *this repo's* capacity to maintain a
registry, not a general argument against manifests — and the only mitigation that has worked here is a
checker that fails on its own registry rather than a habit of updating it.

### 7. Gate 2d's trigger set omits the directory its own manifest lives in
**Unresolved; recorded in BAR-012.** Call 5 sets the trigger to `agents/`, `skills/`, `scripts/`,
`CLAUDE.md`. `docs/rules/authorities.tsv` is under `docs/`, so a changeset editing **only the manifest**
— adding a row, the most likely edit it will ever receive — does not trigger the checker that validates
it. Call 5's justification ("an authority and its pointers live in those four places **today**") is
itself an unchecked temporal claim, which is the defect class the cut exists to remove.

### 8. Change 1's detection step is real but weaker than the mechanism it sits beside
**Unresolved.** "Re-ask `devils-advocate` to confirm its edits survived" is genuine detection — an
honest "I cannot" is what recovered the original loss — but its failure behavior is prose ("neither
stated -> the run has an unverified write") with nothing that fails, and its verifier is the agent class
documented as prone to going idle
([[2026-08-03-subagent-goes-idle-before-reporting]]). The common failure is therefore silence, the exact
state `CLAUDE.md` says must never be read as assent. **Unconsidered alternative:** the pack already
solved the isomorphic "indistinguishable from nobody looking" problem *mechanically*, with a sentinel
string and a gate that greps it; `devils-advocate` already appends `## Challenge`, gate 4a already reads
the plan with `Grep`, and `lint-plans.sh` already parses sections. Whether a survival marker beats an
attestation is a real question the plan does not appear to have asked, and it needs no new script or
gate.

### 9. Smaller points, each verified
**Unresolved.**
- `## What ships` promises "the memory files listed under `## Calls made for you`" and that section
  lists none; only BAR-008 names a memory file. **The 2026-08-05 clause-loss incident — the cut's entire
  justification — is in no memory file** (checked across `memory/`), and the plan ships none, so a rule
  lands in `agents/tech-lead.md` with no recorded incident behind it. This file partly closes that gap.
- The plan's "18 files" pointer count is not reproducible: the three obvious phrasings appear in 14
  files, 7 of them plans or memory. An unchecked count in a plan whose thesis is that unchecked counts
  rot.
- BAR-005 checked the wrong half. `scripts/lint-plans.sh:264-265` holds **two** false claims — the
  count at :266 ("all three move together", stale by two sites within the needle class) and a
  sole-sharer claim naming only `agents/merge-reviewer.md` Tier 1. Deleting the number leaves the false
  claim intact. Bar edited.
- Call 8 ("the plan file does not restate the guard table") has no lookup target, so merge-reviewer's
  Tier 3 skips it by construction. Reclassified in place as documentation for the human.
- The plugin-context cost the caller raised is **already priced** in `## Out of scope`, correctly, as a
  different plan. One asymmetry worth knowing: change 1's rules land in `skills/plan/SKILL.md`,
  `agents/tech-lead.md`, `agents/devils-advocate.md` — all plugin components, so they travel. Only
  change 2's gate wiring in `CLAUDE.md` does not.
- Declining the component layer (no `skills:` frontmatter, no widening of `AGENT_VALID_FIELDS` before
  the field is known to bind) is sound and was not challenged.

## Implications

- **Answer concerns 1 and 2 before writing `scripts/lint-authorities.sh`.** Which string is the
  declared literal, which sites must match versus merely quote it, and what the checker excludes are
  not implementation details — they determine whether the rule can exist. If the author held these
  answers and did not write them down, change 2 is sound and concerns 1-2 are documentation defects.
- **Change 1 is the highest value per unit of risk in the cut** and is independently shippable: prose
  into three files, cheap, reversible, aimed at an observed loss. Its bar is a gated `NOT RUN`
  reproduction, so it ships unexercised either way — which is an argument for correcting BAR-007, not
  for delaying the change.
- **A second registry enters a repo whose first registry is already stale** (concern 6). Fix
  `repo-map.md:33` and the missing `lint-identifiers.sh` entry as part of this cut, or `authorities.tsv`
  starts life next to a live counterexample.
- The plan's responsibility matrix and owner-to-file diff are a direct improvement on the
  actors-versus-files leak recorded as concern 12 of
  [[2026-07-30-challenge-durable-plan-spine-first-cut]]; that methodological gap did not recur here.
- Because devils-advocate holds no `Bash`, the edited plan was **not re-linted** by this challenge.
  `/plan` step 3 and `/implement` step 3 already require `scripts/lint-plans.sh` after a
  devils-advocate edit — the edits were checked against the parser by reading it, which is not the same
  as running it.

## Re-audit 2026-08-06 — survival re-ask, and two coordinating-session appends reviewed

The coordinating session appended two sections to the plan **after it was committed** and re-asked
devils-advocate to confirm its edits survived, under the rule this cut shipped in `cfe2918`. The
narrative is in the plan's `## Challenge` under `### Re-audit 2026-08-06`. Summary of what is new:

### Survival: confirmed, with three stated limits — Addressed
Every concern in this file and every bar addendum it records is present in the plan. Confirmed against
two artifacts outside the plan (this file, and the session's scratchpad snapshot), because the re-asked
agent's context did not include the original audit transcript. **Limits:** this file is a summary and
cannot prove bar *text* intact; the snapshot covered only the second of two appends; and the
"eight bars edited" count in both this file and the plan is **wrong** — at least nine (BAR-011 is
recorded as edited in concern 2 above), with a tenth addendum on BAR-014 unattributed. Nothing lost; the
count was never checked, in a challenge that flagged an unchecked count.

### "A scratch-copy diff dominates the fingerprint and the token" — Unresolved, overclaimed
Six misses recorded in the plan. The two that matter: **(a)** the procedure triggers "after the writer
reports", and a writer that writes then stalls is this pack's documented failure mode
([[2026-08-03-subagent-goes-idle-before-reporting]]) — the trigger must be turn-end, not report; **(b)**
a diff detects *change*, not *loss*, so someone must still judge which removals were intended, and the
session is the party that wants the run to close. **Observed on its first live use:** only one snapshot
exists and it postdates the first append, so the bracket covered one of two writes, and the diff it
produced was read against an append rather than a rewrite. Session-scoped provenance also dies at the
session boundary — the exact mirror of the in-file scheme's death by whole-file overwrite. **Neither
dominates; they fail on orthogonal axes.**

### The marker and the fingerprint are layers, not alternatives — Unresolved, and the plan now recommends neither
The appends withdrew the plain survival marker (it would have passed the 2026-08-05 incident, whose loss
was in bar text while `## Challenge` was preserved) and then undercut the per-bar fingerprint that
replaced it (a whole-file overwrite removes the fingerprint block too, yielding a **vacuous pass**).
Both critiques are correct. **The conclusion is not:** a rule requiring `## Challenge` fires exactly on
the total-overwrite case the fingerprint misses, and the fingerprint fires on the partial rewrite the
marker misses. The plan holds both sections with no ordering statement, so a later planner finds two
answers to its own question 4.

### `## Challenge` is verified by nothing today — Addressed as a fact, Unresolved as a gap
`scripts/lint-plans.sh:164` requires only `## Acceptance bars` and `## Deviations`; it names
`## Challenge` in comments only. `agents/merge-reviewer.md` never mentions it. So an audit's entire
narrative can vanish with no gate noticing — and conversely the marker rule above is one line in an
existing check, not new machinery.

### Neither writing agent holds `Bash` — Addressed, claim verified
`agents/tech-lead.md:9` = `Read, Write, Edit, Grep, Glob`; `agents/devils-advocate.md:12` adds only
`WebFetch`. The append's hinge holds. One step of its reasoning is over-broad: a **session-issued** token
echoed back by the agent is not forgeable into another dispatch's token, unlike a self-invented
timestamp; the append folds both under "injected". Conclusion survives, the step does not.

### Should change 2 be abandoned rather than deferred? — Unresolved, but the framing is a category error
The manifest solves **cited-authority integrity**; the session-diff solves **lost update on one file**.
The diff removes the fingerprint's dependency on the manifest and nothing else. The honest narrowing is
different and is stronger after these appends, which *added* a dimension: ship the **`prose` class
alone** (dangling citation, uncited authority, row naming an absent file — all fully specified today,
covered by BAR-002 and BAR-014) and defer or drop the `literal` class, which is what cannot be specified.

### The literal's class is per (literal, consumer) pair, not per file — Unresolved; BAR-004 edited again
Extends concern 1 above. The two consumers apply the same string over **different extents**:
`lint-plans.sh` bounds its match to the `## Deviations` body (`:53-57`), `merge-reviewer` Tier 1
(`:419`) greps the whole file. A must-match/quotes-it flag per *file* cannot express this, and the
manifest schema in `## What ships` has nowhere to put it.

### Two live defects found while verifying — Unresolved
- **The plan would fail `merge-reviewer` Tier 1 as committed.** The needle survives in BAR-003, BAR-004
  and challenge concern 1. Its `## Deviations` says the quotation "was removed" — true only of
  `## Deviations`, which is what satisfied the bounded `lint-plans.sh` check. The file holds two accounts
  of its own gate state. Inert only because nothing hands this `plan_id` to a gate.
- **`memory/architecture/repo-map.md:33` is still wrong** — still enumerates merge-reviewer's gates as
  **2a and 2b**, omitting 2c. The cut added the missing `lint-identifiers.sh` entry (the narrower half)
  and left the enumeration. That is concern 6 recurring **inside its own remediation**, and exactly the
  pass-through BAR-013 was edited to prevent.

### Implications of the re-audit

- **A survival re-ask works, and its cost is that it needs an out-of-file record to be answerable.** This
  file is what made the confirmation possible; without it the honest answer would have been "I cannot",
  since the re-asked agent has no memory of what it wrote. **Any pack that relies on the re-ask must also
  require the auditor's memory write** — they are one mechanism, not two.
- **Every scheme proposed so far fails on some axis, and the axes are orthogonal**: in-file provenance
  dies to whole-file overwrite, session provenance dies to the session boundary, the attestation dies to
  a stalled agent, the diff dies to an unreported write. Layering is the only answer that has survived
  review; picking a single winner has now been attempted twice and failed twice.
- **`repo-map.md:33` should be fixed before anything else in this area ships.** It is the live
  counterexample the deferred manifest is meant to prevent, it was already flagged once, and the fix
  applied addressed the instance rather than the category.
