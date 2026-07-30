---
plan_id: plan-spine-deviations
branch: feat/plan-deviations
origin_skill: plan
created: 2026-07-30
---

## What ships

A `## Deviations` section in the plan file, and enforcement of it in gate 4a. Three moving parts:

1. **tech-lead writes the section empty** — as a self-describing sentinel line, not a bare
   heading. An empty section cannot be told apart from an unfilled one, and "indistinguishable
   from nobody looking" is the exact failure class this pack has produced six times. The sentinel
   makes "nothing diverged" and "nobody checked" two different states.
2. **`/implement` carries the stated calls out and the departures back.** Step 5 pastes the
   plan's relevant `## Calls made for you` entries *verbatim* into each engineer's dispatch prompt
   and requires a departures line in the handoff — including an explicit "none". Step 10 replaces
   the sentinel with either `None.` or a list of entries, then hands merge-reviewer the plan plus
   each engineer's departure claims.
3. **Gate 4a refuses on three tiers**, cheapest and most certain first: sentinel still present
   (mechanical), an engineer-reported departure missing from the section (near-mechanical), and a
   stated call the branch diff contradicts with nothing recorded (judgment, tightly bounded — see
   `## Calls made for you`).

Also: README's `Known limitation` paragraph goes away, and the memory finding that motivated this
cut is flipped to `superseded`.

## What does not ship

- **No engineer agent file is edited.** The departure-reporting duty is delivered at dispatch
  time, exactly as devils-advocate's bar-review duty is (that duty lives in `/plan` step 3's
  prose; `agents/devils-advocate.md` contains no plan-file instructions at all — verified).
- **No new pipeline stage, and no reordering.** Steps 5 and 10 gain duties inside their existing
  slots.
- **No status field, no lifecycle, no deletion.** Cut one settled that; nothing here reopens it.
- **No change to `/hotfix`, `/debug`, `/scaffold`, or `/refactor`.** They pass no `plan_id`, so
  they are exempt by construction. They stay untouched, which is the whole point of that property.
- **No deviation ids, no counting, no pairing contract.** Bars needed ids because a downstream
  stage maps evidence onto each one. Nothing maps onto a deviation, so an id would be ceremony.
- **`agents/test-engineer.md` is not edited.** It already reports when a bar's actual evidence
  type differs from what the bar predicted. That is bar-level divergence, which gate 4a already
  owns; narrative divergence is a different thing with a different owner. Deliberate non-edit.

## Calls made for you

- **The sentinel is a self-describing line, not a bare empty section or a bare token.** Its own
  text names who replaces it and when. This is in-band documentation aimed at the agent most
  likely to trip over it: devils-advocate holds `Write`, edits the plan in place during `/plan`
  step 3, and has no instructions in its own file about the plan's shape — so a bare
  `NOT REVIEWED` token risks being "helpfully" filled in or deleted by the only other writer.
  Self-description closes that without a sixth file.
- **`## Deviations` goes in the narrative half, immediately after `## Calls made for you`.** Its
  only job is to correct the calls, and a reviewer reads the two together. Sixty lines and a
  horizontal rule between a claim and its correction is how a correction goes unread.
- **The section is written at step 10, immediately before dispatching merge-reviewer — not at
  step 9.** The retry loop re-runs steps 6–10, so writing at step 10 means a retry that changes
  the implementation rewrites the section for free. Written at step 9, a retry leaves it stale
  and the gate then enforces a stale record, which is worse than no record.
- **Tier 3 is a call-driven lookup, never a diff-driven scan.** merge-reviewer starts from each
  stated call, extracts the concrete artifact it names, and looks *only* for that. It does not
  read the diff hunting for surprises. This is the load-bearing choice for keeping the gate from
  crying wolf: a vague call yields no lookup target, so it falls out of scope **by construction**
  rather than by the agent deciding it is "too vague to judge." Nothing is asked of the gate that
  it cannot do deterministically.
- **A Tier-3 FAIL requires quoting both sides.** The gate may only fail when it can produce (a)
  the stated call verbatim, (b) a specific `file:line` in branch scope — or a specific named
  artifact provably absent from it — that contradicts the call, and (c) one sentence on why both
  cannot be true. Missing any of the three, it emits an advisory in the PASS report instead.
- **Ambiguity advises; it does not fail.** This deliberately inverts merge-reviewer's rule for
  bars ("when you cannot tell, FAIL"), so the inversion's reason is written into the agent file
  rather than left to look like a contradiction: an unverifiable *bar* means verification did not
  happen, which is the thing the gate exists to establish. An ambiguous *narrative call* means
  the plan was imprecise — a defect belonging to tech-lead, three stages back, in a file the
  session can no longer usefully change. Failing there punishes the wrong party, and a gate that
  fails on someone else's imprecision is disabled within a week.
- **The remedy for a Tier-3 finding is one line in `## Deviations`, not a code change** — and the
  finding text says so. A gate whose cheapest correct response is "record it" induces the
  behaviour the cut wants. A gate whose cheapest response is "argue with the reviewer" gets
  switched off.
- **README.md is added to the four-file scope, making five.** Not scope growth — `README.md:285`
  currently states this exact limitation as shipped fact and cites the memory file by name. Ship
  the cut without it and the repo's front-page documentation asserts a limitation that no longer
  exists, pointing at a file whose status now reads `superseded`. The cut would introduce the lie
  it is closing.

## Deviations

- **"README.md is added to the four-file scope, making five." → shipped six files.**
  `docs/obsidian-cli-and-plan-spine-brief.md` was also edited, adding a "Cut two — `## Deviations`,
  shipped 2026-07-30" note. The plan raised this as Open question 1 and left it out of scope pending a
  decision; the decision was to include it, because Design C is marked authoritative and still listed
  Deviations as deferred, which this cut makes stale.
  Decided by: coordinating session.

- **The build steps did not include a self-check in `agents/tech-lead.md` → one was added.**
  A five-point "read your own plan file back" list now closes that section. Added in response to a
  live failure during this cut: tech-lead omitted `## Deviations` entirely on its first run against
  the new template, so corrected wording alone was not sufficient. This is the durable half of that
  fix; the other two changes were wording.
  Decided by: coordinating session.

- **The build steps did not touch Step 0c → its branch-scope derivation was fixed.**
  Step 0c built branch scope from `git diff --name-only <merge-base>` alone, whose comment claimed
  "committed + uncommitted". `git diff` reports only *tracked* files, so every newly created file was
  omitted from scope while `git add -A` would still commit it. Gate 4 searches that scope for test
  files, so a run whose only tests lived in a new file would have been told no tests exist — a false
  FAIL blocking good work. `git ls-files --others --exclude-standard` is now unioned in.
  Found during this cut's own Tier-3 exercise, by merge-reviewer noticing the gap and working around
  it unprompted. Pre-existing bug, unrelated to Deviations, but Tier 3 depends on branch scope being
  complete to name a contradicting `file:line` — an untracked contradiction would have been invisible.
  Decided by: coordinating session.

- **The build steps did not cover bar amendment → a four-condition rule was added.**
  Recording a deviation during the live exercise made an acceptance bar unsatisfiable rather than
  unmet — its text asserted a structural fact the deviation had just falsified, so it tested an
  abandoned design. Nothing in the plan said who may amend such a bar, or whether that differs from
  the retconning the mechanism exists to prevent. `skills/implement/SKILL.md` step 10 now sanctions it
  under four conditions (named consequence of a recorded deviation, original wording quoted, narrowly
  scoped, coordinating session only), and `agents/merge-reviewer.md` fails a bar amended without a
  deviation behind it. Prompted by merge-reviewer's advisory during the exercise, which warned that an
  unbounded licence would let any inconvenient bar be edited back into satisfiability.
  Decided by: coordinating session.

- **This plan file has no sentinel, and this section was added by hand.**
  tech-lead wrote the plan before `## Deviations` existed in the template, so it was emitted against
  the old shape. Recorded so a future reader is not confused as to why the plan for the Deviations
  feature arrived without a Deviations section. A gate run against this plan would have failed Tier 1
  with `plan has no Deviations section` — correctly — until this section was added.
  Decided by: coordinating session.

## Risks

- **Tier 3 is the one that can cry wolf.** The quote-both-sides rule and the call-driven-lookup
  restriction bound it, but neither is provable from a file read; only running it does that. If it
  produces a false FAIL in practice, the escalation is to **demote Tier 3 to advisory and keep
  Tiers 1 and 2 blocking** — that retains most of the value, because Tier 1 alone forces someone
  to look on every plan-governed run. Prefer that demotion over disabling gate 4a.
- **Tier 2 is unproven on its primary path by this cut.** This is a prompt-file-only change, so
  no engineer agent runs and no engineer handoff exists to contain a departure. BAR-003's scratch
  exercise covers Tier 1's refusal; the engineer→handoff→section path is exercised in the same
  run only if the scratch task is chosen to include an engineer dispatch. Until it has refused
  something, Tier 2 is intent, not enforcement — the repo's own standard, and it should be stated
  that way rather than claimed as shipped.
- **A new literal becomes a cross-file contract.** The sentinel string appears in
  `agents/tech-lead.md` (written), `skills/implement/SKILL.md` (replaced), and
  `agents/merge-reviewer.md` (grepped). Same class as the two-space `Evidence:` indent, which the
  pack already accepts and documents as load-bearing. Mitigated by keeping the string short and
  by BAR-003, which cannot pass for the right reason unless the literals agree.
- **`agents/tech-lead.md:109` says "the five sections above the rule".** A sixth section makes
  that count wrong. Small, but a stale count that reads as authoritative is exactly how this pack
  has failed before.
- **Every plan-governed `/implement` now mutates the plan file mid-pipeline.** The write lands in
  the primary working tree and is swept into merge-reviewer's `git add -A`, matching cut one's
  commit timing. But it means a plan is no longer immutable after `/plan`, so a plan read at two
  different times can differ. Acceptable and intended; worth knowing.
- **The `## Deviations` section can be written dishonestly** — a session that overrode a call can
  write `None.` Nothing detects that except Tier 3, which is the weakest tier. The cut narrows
  the hole; it does not close it.

## Out of scope

- Reaping or archiving plans, plan indexes, cross-plan reporting.
- Any change to how bars, evidence, or `test-engineer`'s mapping work.
- Recording deviations into `memory/` automatically. The existing rule stands: if a divergence is
  durable, it goes to `memory/decisions/` by the normal route.
- Appending a "cut two" section to `docs/obsidian-cli-and-plan-spine-brief.md`. Design C lists
  `## Deviations` as deferred, which this cut makes stale — but the brief is a dated design
  record and the repo's habit is to mark superseded material rather than rewrite it. Left as an
  open question for the team lead, not claimed here.

---

## Inputs

- `README.md` — "Plan Spine" section, including the `Known limitation` paragraph at line 285.
- `docs/obsidian-cli-and-plan-spine-brief.md` — "Design C — adopted 2026-07-30, authoritative".
  The two `SUPERSEDED` sections are read for reasoning only; nothing is built from them.
- `memory/known-issues/2026-07-30-plan-gate-does-not-check-narrative-vs-implementation.md` — the
  finding this cut closes, including its Revisit trigger.
- `memory/known-issues/2026-07-30-challenge-durable-plan-spine-first-cut.md` — concern 12's
  actor/file reconciliation method, applied below.
- `agents/tech-lead.md` — `## Plan File` (Shape block at :79-104, narrative-half note at :109).
- `agents/merge-reviewer.md` — gate 4a at :242-312, Step 0c branch scope at :126-160.
- `skills/implement/SKILL.md` — step 5 (:41-56), step 9 (:93-97), step 10 (:99-101), retry loop
  (:148-154).
- `CLAUDE.md` — `## Plan spine` at :118-166.
- `agents/devils-advocate.md` — confirmed to contain no plan-file instructions; the bar-review
  duty arrives via `/plan` step 3 prose. This is the precedent for delivering the engineer duty
  at dispatch time.
- Plan directory resolution: `docs/CONVENTIONS.md` has no `- **Plan directory:**` key, so the
  `docs/plans` fallback applies. Guard conditions all pass; `docs/plans/` did not previously
  exist and this file created it.

## Build steps

Responsibility matrix first, per the method finding in
`memory/known-issues/2026-07-30-challenge-durable-plan-spine-first-cut.md` — every duty named
below is reconciled against a file, so no duty is left owned by an actor with no edit.

```
Event: plan is created
Writer: tech-lead (agents/tech-lead.md)          Reader: the human, in the PR
Mutator: none                                    Verifier: none
Failure behavior: no sentinel -> gate 4a Tier 1 cannot fire; caught by BAR-003
Persisted state: <plan_dir>/<plan-id>.md, uncommitted, sentinel present

Event: engineer is dispatched
Writer: coordinating session (skills/implement/SKILL.md step 5, into the prompt)
Reader: the engineer agent                       Mutator: none
Verifier: none                                   Failure behavior: engineer cannot know the call
Persisted state: none — prompt only, because the plan is invisible inside a worktree

Event: engineer hands off
Writer: engineer, into its handoff text          Reader: coordinating session
Mutator: none                                    Verifier: gate 4a Tier 2
Failure behavior: silent departure -> Tier 3 only, the weakest tier
Persisted state: none until step 10

Event: pre-merge-reviewer
Writer: coordinating session (step 10)           Reader: merge-reviewer, then the human
Mutator: replaces the sentinel in the plan file  Verifier: gate 4a Tier 1
Failure behavior: sentinel intact -> Tier 1 FAIL
Persisted state: plan file, uncommitted, section filled

Event: gate 4a
Writer: none (reviewers are read-only)           Reader: merge-reviewer
Mutator: none                                    Verifier: itself, then the human in the PR
Failure behavior: FAIL routes to the coordinating session, never to an engineer
Persisted state: the plan is committed by the existing git add -A, unchanged from cut one
```

1. **`agents/tech-lead.md`** — add `## Deviations` to the Shape block between `## Calls made for
   you` and `## Risks`. Add a short subsection under the Shape block stating: the sentinel line
   verbatim, that tech-lead writes it and never fills it in (it cannot know deviations at plan
   time), and that the coordinating session replaces it during implementation. Fix "the five
   sections above the rule" at :109 to six.
2. **`skills/implement/SKILL.md` step 5** — before each engineer dispatch, when a plan governs the
   run, extract the `## Calls made for you` entries relevant to that engineer's slice and paste
   them **verbatim** into the prompt (paraphrase is where the signal dies). Require the handoff to
   carry a `Departures from stated calls` line, and require an explicit "none" when there were
   none — an absent line is not a "no".
3. **`skills/implement/SKILL.md` step 10** — before dispatching merge-reviewer, replace the
   sentinel with `None.` plus a one-clause affirmation, or with one bullet per departure naming
   the stated call, what shipped instead, and who decided (engineer or coordinating session).
   Both sources are in scope; the demonstrated case originated from the coordinating session.
   Add each engineer's departure claims to merge-reviewer's payload. Note in the retry text
   (step 11) that a retry cycle rewrites this section.
4. **`agents/merge-reviewer.md` gate 4a** — add the three tiers after the existing bars checks,
   with: the sentinel grep and its `reason:` string; the engineer-departure cross-check; the
   Tier-3 call-driven-lookup procedure; the positive definition of a checkable call; the
   quote-both-sides requirement; the ambiguity-advises rule *with its stated reason*; and the
   note that a Tier-3 remedy is one line in `## Deviations`. Reuse Step 0c branch scope — do not
   re-derive it. Keep the existing "never interpolate the plan path into a shell command" rule
   intact: the plan is read with `Read`/`Grep`; only branch-scope `git` commands use Bash.
5. **`CLAUDE.md` `## Plan spine`** — add `## Deviations` to the artifact description and one line
   each to the tech-lead, engineers, and merge-reviewer entries under "Who does what". Point at
   `agents/merge-reviewer.md` as the single authority on what Tier 3 checks; do not restate the
   checkable-call list, per the same anti-staleness rule the guard table already follows.
6. **`README.md`** — replace the `Known limitation` paragraph with a short description of the
   `## Deviations` mechanism and its three tiers. State plainly that Tier 3 advises on ambiguity
   and why. Do not claim Tier 2 is proven.
7. **After merge-reviewer passes**, flip the memory finding to `Status: superseded` with
   `Superseded-by:` populated, and write the decision record listed in Memory candidates. Not
   before — a decision record for unshipped work is the write-ahead version of the same problem.

Sequencing: steps 1–4 are one coupled edit set (the sentinel literal spans three of them) and
should be made sequentially by a single writer with full context. Steps 5 and 6 are documentation
and can run in parallel once the literal is settled. Step 7 is last.

## Acceptance bars

- BAR-001: `/implement` step 5 pastes the plan's relevant stated calls verbatim into each engineer dispatch and requires a `Departures from stated calls` line in the handoff, with an explicit "none" when there were none
  Evidence: files -> skills/implement/SKILL.md step 5
- BAR-002: `/implement` step 10 replaces the sentinel before dispatching merge-reviewer, passes each engineer's departure claims into the payload, and the retry text states the section is rewritten on a retry cycle
  Evidence: files -> skills/implement/SKILL.md steps 10 and 11
- BAR-003: gate 4a FAILs when the sentinel is still present, naming its reason string, and FAILs when an engineer-reported departure is absent from `## Deviations`
  Evidence: manual -> run install.sh, then in a scratch project dispatch the installed tech-lead to write a plan, leave the sentinel intact, dispatch merge-reviewer with that plan_id; confirm FAIL naming the sentinel reason. Using a tech-lead-produced plan rather than a hand-written one is what also proves the sentinel literal agrees across tech-lead.md and merge-reviewer.md
- BAR-004: gate 4a cannot issue a Tier-3 FAIL without quoting the stated call and naming a contradicting file:line or a provably absent named artifact in branch scope; ambiguity produces an advisory, and the reason for inverting the bars rule is written in the file
  Evidence: files -> agents/merge-reviewer.md gate 4a Tier 3, including the checkable-call definition
- BAR-005: README no longer states the narrative-vs-implementation limitation, and the memory finding carries `Status: superseded` with `Superseded-by:` populated
  Evidence: files -> README.md Plan Spine section, memory/known-issues/2026-07-30-plan-gate-does-not-check-narrative-vs-implementation.md frontmatter

## Model Overrides

None. The single coupled edit set (steps 1–4) meets two escalation criteria — a new pattern not
in the codebase, and a contract literal spanning three files with cascade risk — but no engineer
agent is dispatched: no agent description covers prompt-file editing, and stretching one to fit
would make its description a lie, which is this repo's first design pattern. The coordinating
session performs the edits and the review lenses run against them. If that call is reversed and
an engineer is dispatched after all, escalate it to `opus` on those two criteria.
