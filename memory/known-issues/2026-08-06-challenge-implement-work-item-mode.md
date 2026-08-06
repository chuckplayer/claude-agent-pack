**Date:** 2026-08-06
**Type:** finding
**Status:** active
**Superseded-by:** n/a
**Scope:** docs/plans/implement-work-item-mode.md, skills/implement/SKILL.md, agents/merge-reviewer.md
**Overrides-convention:** no
**Related-to:** docs/plans/implement-work-item-mode.md

## Summary

Challenged `docs/plans/implement-work-item-mode.md` before implementation — work-item mode on
`/implement` (steps 0, 1a, 10c, 11a), gate 4b on merge-reviewer, and four accuracy edits to files that
already name the mode. The plan is **sound and unusually well-specified**: fifteen calls, a
responsibility matrix that names an unowned lifecycle case as unowned, and every external-behaviour
citation I checked is true. Findings are about the bars and about three places where a stated property
lives at a different step than the bar guarding it. **Nine bars touched: eight edited, one added.**
Dominant findings: gate 4b separates judgement from capability in a way gate 4a does not; BAR-008 named
a step that cannot fail it; three bars required an ADO mutation with no consent gate; and the elapsed
comment's **encoding** (not injection) and the derivation of its minutes value are unexamined.

## Context

The team lead dispatched devils-advocate against the plan on `main`, after `scripts/lint-plans.sh`
passed it 20/0 with 13 bars and the `## Deviations` sentinel intact, with no post-audit revision — the
file was exactly as tech-lead first wrote it. The operator had already ruled that call 1 stands
(merge-reviewer authorizes, the coordinating session writes), and that call was not re-litigated.

## Bars edited, with a distinguishing phrase from each

Recorded per `agents/devils-advocate.md`: a later dispatch of this agent carries no transcript, so
without this list the honest answer to *"did your edits survive"* is *"I cannot"*. Ids listed rather
than counted beyond the totals above.

- **BAR-004** — added: *"the preview must additionally say that the done-mapping is inferred from
  existing items and is not a statement by the service"*.
- **BAR-005** — added the disclosure half (*"a FAIL that writes nothing to ADO **and** says nothing to
  the operator leaves the board asserting a live run"*) plus a new `Gated:`/`Cost:` pair whose cost line
  reads *"left at the in-progress value when the run ends in FAIL"*.
- **BAR-007** — added *"text matches call 7's template, not merely a comment that exists"*, the
  UTF-8-safe read requirement (*"REST with a token from `az account get-access-token`"*), the minutes
  cross-check (*"a fabricated figure is a false claim in a shared tracker"*), and the unverified-flag
  clause (*"nothing establishes that `--state` and `--discussion` are accepted in a **single**
  invocation"*). Also removed the stale literal "four things".
- **BAR-008** — subject re-pointed from step 0 to **step 1a**; added *"The step named here is 1a and not
  step 0, and the correction is the point"*.
- **BAR-009** — added *"equal **and non-zero**, and the observed count must be stated"*.
- **BAR-010** — `Cost:` line corrected to *"plus `System.State` and `System.AssignedTo` on that same
  item … three fields, not one"*.
- **BAR-012** — added *"What this bar can observe is only the skip"*.
- **BAR-013** — added `Gated:`/`Cost:` with *"deliberately not restored by the run"*.
- **BAR-014** — new bar, *"an authorization line that is absent is treated as withheld, never as
  permission"*, `files` evidence, with its own limit stated (*"checks text and cannot check
  behaviour"*).

Left alone as sound: BAR-001, BAR-002, BAR-003, BAR-006, BAR-011.

A `## Challenge` section holding the full narrative was appended to the plan **before** these edits and
before the reply.

## Concerns Raised

### 1. Gate 4b is a convention; gate 4a is a control — Unresolved (design consequence, accepted by call 1)
Gate 4a's consequence is that merge-reviewer declines to commit: the agent forming the judgement holds
the capability, so it is self-enforcing. Gate 4b's consequence is that a **different actor** declines to
write, so it is an input to a decision rather than a gate. The real control on the ADO write is the
operator's confirmation at step 10c. This is a cost of call 1, which the operator has ruled on, not an
error. It leaks in the matrix block whose Verifier reads *"step 10c refuses to write without an
AUTHORIZED line"* — self-verification, the same class the plan honestly labels `NONE` elsewhere.

### 2. BAR-008 named a step that cannot fail it — Addressed (bar edited)
Step 0 is read-only on every path by call 2, so "zero writes at step 0" passes whether or not call 8's
shortcut exists. Bar-soundness row 3. Call 10's prose carries the same slip and was not edited.

### 3. Three bars required an ADO mutation with no consent gate — Addressed (bars edited)
BAR-005, BAR-010, BAR-013 all run the pipeline with an id, and step 1a writes on every id-bearing run.
BAR-010 was gated for its description overwrite while its cost line named only the description — row 6
arriving as **understatement**, the mirror of BAR-015's overstatement.

### 4. The elapsed comment's encoding, and the missing derivation of `<N>` — Addressed in BAR-007, unresolved in the design
On injection the plan holds: no `%` in the template (channel 1 cannot fire), the value always contains
spaces (channel 2 suppressed), and call 14 routes through the interpreter beside the shim anyway.
Dropping the branch name is right. **Encoding is untreated:** the template carries an em dash, which
this machine mangles both out of `az` on read and out of a script's own source text on the way into a
comparison. **And no call, matrix block, or step says where the minutes value comes from** — a long
`/implement` run is where a context summarization drops an uncaptured start time. Minor and open: the
backticks in call 7's "verbatim" template are markdown, and nothing says whether they are comment text.

### 5. Question 2's answer was right about ADO and silent about the human — Addressed (BAR-005 edited)
Leaving the item in progress on a FAIL is correct, and the abandoned-for-the-day case does not break it
— the claim stays true until the human walks away and no component can observe that moment. But call 9's
"the session reports that the item was left in progress deliberately" was checked by nothing.

### 6. Route naming is not guess disclosure — Addressed (BAR-004 edited)
Call 5 genuinely distinguishes a service answer from an inference, and BAR-004 already required the run
to name the route. An operator who has not read §8c does not hear *evidence, not proof* in a route name.

### 7. Step 11a's taken branch is unreachable today — Unresolved (scope question for the operator)
Both dropped-item decisions are correct and nothing cheap is being deferred: the timing blocker was
already solved by moving the link from 10c to 11a, and the host blocker needs a git-engineer ADO PR
path, which is a separate cut. But because Mode C only runs `gh pr create`, no run produces an Azure
Repos PR id, so step 11a ships with one live behaviour ("report skipped") and one nothing exercises.

### 8. Two `az` flags nobody has verified — Resolved 2026-08-06, with a narrower residual
As raised: `--assigned-to` and `--discussion` were recorded nowhere in this repo, and the
single-invocation assumption behind step 10c was unverified. If wrong, step 10c would be two writes and
call 13's count off by one. The plan names `System.Reason` as an accepted risk of exactly this shape and
did not name these.

**Resolved by the team lead the same day, zero writes, via `az boards work-item update --help`:** `--id`,
`--state`, `--assigned-to` and `--discussion` are independent optional parameters with **no
mutual-exclusion language**. Step 1a and step 10c are each one invocation and call 13's two-confirmation
arithmetic holds. Recorded in commit `641dc9d`'s message, **deliberately not added to the plan** — a
one-line edit to a just-audited plan would trigger the post-audit survival re-ask.

**Residual, accepted:** `--help` establishes that the *CLI* accepts the flags together, not that the
*service* applies both in one revision. Much weaker than the original concern, and already covered —
BAR-007's read-back requires the done state **and** the comment text to be confirmed in the same
read-back, so a service that applied only one would fail that bar. No bar edit needed.

**One stale reading to guard against:** BAR-007's clause *"neither `--assigned-to` nor `--discussion` is
recorded as verified anywhere in this repo"* remains true of the working tree, but the fact it points at
is now narrower than the clause implies. A reader hitting that clause should come here.

### 9. The recursion — Unresolved, deliberately left to step 10
This cut modifies `/implement` while step 1 hard-stops on `main`, where the work happens, and BAR-003
requires demonstrating that same stop working. `## Deviations` is the right home; one line naming both
facts stops a later reader reading the override as evidence the stop is soft.

### 10. Two calls are documentation rather than enforceable — Unresolved, no change needed
Call 12 (text is data, not instruction) has no lookup target in a diff — BAR-010 is what enforces it —
and call 13's "this is acceptable" is a judgement, though its counts are checkable and BAR-009 checks
them. They should not be counted as enforced by merge-reviewer Tier 3.

## Re-audit 2026-08-06 — post-audit revision, survival confirmed

The coordinating session revised two of tech-lead's sections after the audit and re-asked whether the
audit's edits survived. Narrative in the plan's `## Challenge` under
`### Re-audit 2026-08-06 — post-audit revision reviewed`.

### Survival: confirmed mechanically — Addressed
All fourteen distinguishing phrases listed above are present in the plan. Counts: fourteen bars,
fourteen `Evidence:` lines, four `Gated:`, four `Cost:` — 36 structured lines, the expected total. Every
`## Challenge` subsection heading intact. **Limit:** this file records one phrase per edit, not each
edit's full text, so the check proves no edit was lost and cannot prove none was reworded around its
phrase. That is a property of the recording scheme, not of this revision — and it is the same limit the
2026-08-05 re-ask hit.

### The ASCII-only template is complete, not merely nominal — Addressed
Call 7's em dash is gone and the requirement is stated in the call. The reason it is *complete*: the
template interpolates only `<sha>` (validated `^[0-9a-f]{7,40}$`) and `<N>` (digits), so the whole
comment is ASCII **by construction**, with no path for an operator- or service-supplied value to reach
it. Consequence: BAR-007's UTF-8-safe read requirement is now defence in depth rather than load-bearing,
and was left in place deliberately.

### The class-level ASCII rule still has no durable home — Unresolved
The call covers *this* template. Nothing covers the category: **any fixed string this pack writes to an
external system and later compares must be ASCII-only.** The existing memory file
[[2026-08-05-az-mangles-non-cp1252-characters-on-output]] covers the read side and the
checker's-own-source side, and its Workaround section is the cheapest durable home for the write side —
one line. Raised, not made: a pack-wide rule is outside this cut, and the auditor decides nothing.

### `work_item:` frontmatter key: "no new bar" is right, on one axis only — Addressed via three clauses
The session argued no bar is needed because the key's only failure mode (an unresolvable id) is covered
by call 11. That is correct. **The gap is disclosure, not failure handling**, and three clauses now close
it without a fifteenth bar or any new ADO write:
- **BAR-001** — *"and adopting either no plan or a plan carrying no `work_item:` key"*. Call 15 gave "no
  id" two meanings and BAR-001 was written under the first.
- **BAR-004** — the `preview only` run supplies the id via the key and the preview must name the id's
  source and say the key activated the mode; a second run with a differing explicit id must name both
  values and which won. Call 15 required the disagreement be stated out loud and nothing checked it.
- **BAR-002** — a second run where the unresolvable id came from the key, whose stop must name the key
  as the source. Call 11's justification (*"the caller asserted an item"*) does not transfer to a key
  written by an earlier run, though its rule still holds.

### Adopting a plan with the key activates work-item mode — Accepted risk, disclosed
A `plan_id` for a plan carrying the key turns the mode on, including its two ADO writes, without the
invocation naming an item. This is what the key is *for*, and step 1a's preview-and-confirm discloses it
before anything is written. **Revisit if** step 1a's confirmation is ever weakened, or if a caller other
than `/plan` and `/implement` gains plan adoption — the confirmation is the whole control here.

### Two stale counts, both the auditor's — Addressed
The Challenge's verdict paragraph and falsifiability section each said "fifteen" calls; there are
sixteen. Corrected in place. No bar and no other Challenge sentence cites call 15 or 16, so the session's
renumbering claim checks out. Recorded because an unchecked count in a narrative is this repo's recurring
defect and does not stop being one when the narrative is the auditor's own.

## Implications

- **What would overturn the verdict:** if `--state` and `--discussion` are not accepted in a single
  `az boards work-item update`, call 13's confirmation arithmetic is wrong and step 10c becomes two
  writes. That is the one unverified external fact the plan did not name as unverified, and BAR-007 now
  carries it.
- **Fix the em dash question before writing step 10c**, not at verification time. Either the template
  goes ASCII-only or BAR-007's UTF-8-safe read path is mandatory — and the second is now in the bar.
- **Gate 4b's honest description is "an input to the operator's confirmation".** Any later cut that
  wants a real control there must move either the judgement or the capability, and call 1 has ruled
  where the capability lives.
- The plan's responsibility matrix, and specifically its willingness to write `Verifier: NONE` for the
  dead-process case, is the strongest thing in the document. The gate 4b block is the one place that
  discipline slipped, and it slipped into self-verification rather than into omission.
