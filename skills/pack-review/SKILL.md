---
name: pack-review
description: "Run the scheduled Claude Agent Pack review: version-diff Claude Code against the last reviewed version, carry forward open items from the previous review doc, verify every claim against actual file diffs, and write docs/claude-agent-pack-review-YYYY-MM-DD.md. Writes the file, then asks before committing. Trigger this when someone says: run the pack review, do the scheduled review, check the pack against Claude Code, is the pack behind upstream, daily pack review, version review, review the pack against Claude Code. Do NOT use to verify an installation — use /system-check instead. Do NOT use to validate agent and skill frontmatter — use /lint-agents instead. Do NOT use to review code changes — use /review-pr instead."
---

# Pack Review

Compare the Claude Agent Pack against the current Claude Code release, carry forward
unresolved items, and write a dated review doc. Read-only with respect to the pack:
the review reports, it does not fix. The only file it writes is its own review doc.

## 1. Establish the baseline

Find the most recent review: `ls docs/claude-agent-pack-review-*.md | sort | tail -1`.
Read it whole and extract:

- The Claude Code version it reviewed against
- The pack commit it reviewed
- Every numbered open item, **and each item's stated revisit trigger**

If no prior review exists, this is the first cycle — skip to step 2 and treat every
finding as new.

## 2. Determine current state

```bash
claude --version                    # installed Claude Code version
git log --oneline -1                # current pack HEAD
git log --oneline <last-reviewed-commit>..HEAD   # what moved since last review
```

Fetch the official Claude Code changelog for releases newer than the last reviewed
version. If the changelog URL has moved, search for it rather than guessing.

**Count, never carry forward a count:**

```bash
ls agents/*.md | wc -l
ls -d skills/*/ | wc -l
```

A count quoted from a prior review is how the 2026-07-25 cycle propagated "25 skills"
for three days when the real number was 26. Recount every cycle; it costs one command.

## 3. Choose the cycle type

| State | Cycle |
|-------|-------|
| No new Claude Code release, no pack change | **Confirmation pass** — check revisit triggers only (step 4). Do not re-derive prior analysis. |
| New Claude Code release, no pack change | **Version-diff pass** — steps 4 and 5. |
| Pack changed | **Verification pass** — steps 4, 5, and 6. |

State which cycle you are running and why, in the doc's Summary.

## 4. Check carried items by their revisit trigger

For each open item from step 1, evaluate **its stated trigger condition** — not a fresh
changelog re-scan. A trigger is a single checkable condition ("a release note saying X",
"spawn an agent with `tools: Bash, PowerShell` and see if PowerShell appears").

- **Trigger not met:** report as still open in one line. Do not re-argue the item.
- **Trigger met:** verify directly, then mark the item resolved and update the
  corresponding `memory/known-issues/` file's status.
- **Item has no revisit trigger:** that is itself a finding. Note that the item needs one
  added to its memory file, so the next cycle checks a condition instead of re-reading a
  changelog.

If an item was closed by a decision record, **cite the record** rather than re-deriving
its reasoning. Re-litigating a settled decision every cycle is the failure mode these
records exist to prevent.

## 5. Verify pack changes against the diffs

When the pack moved, verify against `git diff`, **never against the commit messages.**
A commit message states intent; the diff states what happened. For each change claimed:

- Read the actual hunks (`git diff <last-reviewed-commit>..HEAD -- <path>`)
- Confirm the fix reaches every file it needs to, not just the headline one — a fix to an
  agent that requires a matching change in its calling skills is incomplete without both
- Confirm tool grants support the instructions added. An instruction an agent cannot
  execute (no `Bash` for a shell check, no `Agent` for a dispatch) is a latent bug, not a fix

## 6. Redundancy and adoption pass

Run this **only** when agent or skill *directories* were added or removed, or when a
Claude Code release shipped a feature that overlaps something the pack does by hand.
Content edits to existing files do not warrant it.

- Redundancy: any two agents or skills whose descriptions would route the same request
- Adoption: any new Claude Code or CLI capability that replaces pack machinery

When skipping, say so and name the prior cycle whose pass still stands.

## 7. Write the review doc

Write `docs/claude-agent-pack-review-<YYYY-MM-DD>.md`:

```markdown
# Claude Agent Pack vs. Current Claude Code — Scheduled Review
**Run date:** <YYYY-MM-DD> · **Installed/latest Claude Code version:** <version + date>
· **Pack version:** <VERSION file> (commit `<sha>`, <moved or unchanged since last review>)

## Summary
<which cycle type and why; what moved; what this cycle concluded>

## Carried-forward items — resolved this cycle
<numbered, each naming the commit or release that resolved it>

## Carried-forward items — still open
<numbered, each with its revisit trigger and the trigger's current state>

## Redundancy / adoption pass
<findings, or which prior pass still stands and why this cycle skipped it>

## Next steps
<only genuinely actionable items; "keep watching X" is not an action item>
```

Keep item numbering stable across cycles so an item can be tracked by number.

## 8. Ask before committing

Show the user the review doc and ask whether to commit it. Do not commit unprompted.

On approval, commit the review doc **alone** — never bundled with pack fixes, so the
review stays an independent record of what was observed:

```bash
git add docs/claude-agent-pack-review-<date>.md
git commit -m "docs(review): <date> scheduled review — <one-line outcome>"
```

Commit same-day rather than batching. Batched review docs collapse several days of dated
observations into one timestamp, which degrades the history the reviews exist to check.

## Gotchas

- **Do not fix what you find.** This review reports. Applying fixes mid-review means the
  next cycle has no independent record of what the state actually was. Surface findings
  and let the user decide; if they ask for fixes, that is a separate piece of work.
- **Commit messages are not evidence.** Step 5 exists because a message describes what
  someone meant to do. Read the hunks.
- **A dormant bug is still a bug.** An instruction an agent cannot execute because it
  lacks the tool grant has not "not caused problems" — it has silently never run. Report
  it at full weight; the moment someone widens the tool grant it becomes live.
- **Counts drift.** Recount agents and skills every cycle (step 2). Never quote a count
  from a prior review.
- **"Still open, no movement" is a complete report.** An item blocked upstream needs one
  line and its trigger state, not a re-derivation. Length is not thoroughness.
- **No trigger mechanism exists.** As of 2026-07-27 nothing schedules this review — no
  cloud routine, no cron, no scheduled task. It runs when invoked. If a routine is added
  later, it should invoke this skill rather than re-describing the process in a prompt.
