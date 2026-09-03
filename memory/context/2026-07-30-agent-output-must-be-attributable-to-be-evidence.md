---
date: 2026-07-30
type: constraint
status: active
superseded-by: n/a
scope: global
overrides-convention: no
related-to: 2026-07-10-bash-tool-silent-failure-windows.md, 2026-07-27-obsidian-cli-silent-failure-modes.md
---

## Summary

The pack's existing rule is **verify effects, not reports**. Running a live exercise on 2026-07-30
exposed a missing second clause: **verify the effect came from the thing you tested.** Subagents
outlive the step that spawned them, several can share one filesystem path, and two agents given the
same task produce the same filename. An artifact that looks like proof is worthless if you cannot
name what produced it — and it will look exactly like a pass.

## Discovery context

Three separate attribution failures inside one exercise, all producing a file that read as a clean
result:

1. **A stale agent silently repaired its own evidence.** An agent had omitted a required section
   from a plan file. Asked *why* it had done so — a diagnostic question, not an instruction — it
   answered by rewriting the plan file correctly instead of explaining. The next filesystem check
   found a correct plan and read as "the fix worked." It had not been re-tested at all; the artifact
   was a response to the question.
2. **Deleting the directory first was not isolation.** Before re-running, the target directory was
   emptied and verified empty. That was insufficient: the previous agent was still alive and wrote
   to the same path afterwards. Both agents had the same task, so both produced the same filename.
3. **Cleanup destroyed a test result mid-flight.** A reset ran 25 seconds after a second agent went
   idle, deleting the output it had just written before it could be attributed.

Only an accident caught the first one. A wording change unrelated to the test had altered one line of
the template between runs, so the file quoted text that no longer existed in any instruction file —
an unintended **version fingerprint**. Without that edit the file would have passed inspection and a
real bug would have shipped, "verified" by evidence from the wrong source.

## Impact

Any exercise that proves a gate, a format contract, or an agent's behaviour is only as good as its
attribution. On this pack that matters more than usual, because every component is a prompt file and
the *only* way to test one is to dispatch it and inspect what it wrote. A false pass here does not
look like a failure — it looks like the feature working.

The specific trap: the natural check is "is there a correct artifact at this path?" The question that
actually needs answering is "**who wrote this, and from which version of the instructions?**"

## Workaround

Four habits, each cheap:

- **Give every run a unique target.** Change the task so the output filename cannot collide with any
  prior or concurrent run. Same task means same slug means same filename.
- **Keep a version fingerprint.** When instructions change between runs, note a literal that changed.
  An artifact quoting the old literal cannot have come from the new instructions. This is what caught
  the failure above; make it deliberate rather than lucky.
- **Snapshot the artifact hash before the consumer runs, and re-check it after.** If it changed
  mid-run, the verdict is unattributable and the test does not count. One `git hash-object` call.
- **Do not message a stale agent that can still reach the evidence.** Asking an agent about work it
  can still modify invites it to fix the work instead of answering. If a diagnostic is needed, take
  the artifact out of its reach first, or accept that its answer is the only evidence you will get.

Corollary worth stating: an agent's account of its own reasoning is weak evidence. Ask for it if
useful, grant explicit permission to answer "I do not know", and never let it outweigh the files.

**Revisit trigger:** if the harness ever isolates subagent filesystem writes per dispatch, or
guarantees an agent cannot act after reporting idle, the first two habits become unnecessary. Until
then, assume any spawned agent may write at any time until the session ends.
