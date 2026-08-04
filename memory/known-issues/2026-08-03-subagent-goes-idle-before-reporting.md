---
type: known-issue
status: active
discovered: 2026-08-03
scope: any pipeline that verifies stages from agent reports
---

# A subagent can finish its work and go idle **before** sending its report

Observed **seven times in one session** on 2026-08-03: `obsidian-writer`, `codex-reviewer`,
`code-reviewer`, `security-reviewer`, `git-engineer` (twice), and `test-engineer` each completed
their work correctly and then went idle **without emitting a report**.

**The work was right every time. Only the reporting failed.** That combination is what makes this
dangerous rather than merely annoying:

- A failure that loses the *work* is loud — the files are not there, the next stage breaks.
- A failure that loses only the *report* is silent, and it looks exactly like success from the
  outside: an agent was dispatched, a process ran, it finished without error.

**Why it corrupts a merge verdict.** `agents/merge-reviewer.md` verifies that required stages ran by
reading their findings out of conversation context. An agent that did its job and never reported
leaves **no evidence in the only place the gate looks**. Both available readings are wrong:

| Reading | Result |
|---|---|
| "no report → the stage did not run" | a **false FAIL** on work that was completed correctly |
| "the agent went idle → it must have passed" | a **false PASS**, and a merge record asserting a review happened that produced no findings anyone read |

The second is the one that actually happens, because the coordinating session watched the agent
launch and finish and has every reason to believe it completed. This already produced a concrete
bad outcome: `codex-reviewer` stalled on the batch-write cut, and the merge record read as though a
cross-model opinion had been obtained on a change that was architectural, irreversible, and spanned
systems — see [[2026-08-03-codex-reviewer-stalls-without-synthesis]], where the same agent stalled
in a differently-shaped way and two of its own unanswered search targets turned out to be the
questions that mattered.

**Workaround — the rule is: a stage with no report content did not run.**

1. **Never infer completion from process state.** Idle, exited, "completed" in a task list — none of
   these are evidence the stage produced a judgement. Only the report's *content* is.
2. **Re-dispatch rather than proceed.** A silent agent is a failed run of that stage, and re-running
   a read-only reviewer is cheap. Reconstructing a verdict nobody received is not.

   **Amended the same day: re-dispatch is NOT always available, and this workaround originally said
   it was.** A `devils-advocate` run on `docs/plans/bar-cost-and-first-run.md` went idle without
   reporting, was asked directly for its findings via `SendMessage` — which resumes an agent from its
   transcript, so the context was intact — and **went idle a second time without reporting.** It made
   no further file edits between the two. So the escalation path has a floor:

   - **One direct re-request.** Ask for the report specifically, naming what is missing.
   - **If that also returns silence, stop.** A third attempt on the same agent is not a different
     experiment. Declare the judgement **unrecoverable**, record that in the artifact, and either
     spawn a **fresh** agent or do the work in the lead session — saying which.

3. **Beware the case where the artifacts are complete and the judgement is not.** This is the most
   dangerous variant and it is what happened above. The agent held `Write`, and its **entire bar
   audit landed in the plan file** — high quality, several real defects fixed in place. What never
   arrived was its ranked concerns and its implement/smaller/reconsider verdict. A reader finding a
   thoroughly-edited plan will reasonably conclude it was fully reviewed.

   So when an agent's output is *partly* an artifact and *partly* a judgement, **name the half that
   is missing in the artifact itself.** "Bars audited in place; narrative challenge and verdict never
   received" is a sentence a later reader needs, and no diff will supply it.
4. **Prefer a check you can re-run yourself over a report you have to trust.** Where a stage's output
   is mechanically reproducible — `scripts/lint-agents.sh`, `node scripts/obsidian-stop-hook.test.js`,
   a test suite, a `git` fact — run it rather than reading a claim about it. merge-reviewer holds
   `Bash` precisely so it need not trust a report for anything reproducible. This is why gates 2a and
   2b instruct it to run the checks itself.
5. **For stages whose only artifact *is* the report** — code-reviewer, security-reviewer,
   performance-reviewer, smell-reviewer, and `devils-advocate` when no plan file was handed to it —
   there is nothing to re-run and no artifact to inspect, so rule 1 is the whole defence. Say "did not
   report" in the record rather than quietly counting it as a pass. Note that `devils-advocate` **with**
   a plan file path is the partial case in rule 3 instead, not this one.

**The one mitigation that worked is now shipped, as of 2026-08-04.** `agents/devils-advocate.md`
carries a **Persist Your Judgement Before Composing Your Reply** section requiring the narrative
findings into the plan as a `## Challenge` section *before* the reply is composed — with the
memory-file write as the equivalent ordering rule when no plan file was handed to it. That is the
inverse of rule 3 above: rule 3 tells a reader how to describe the half that went missing; this stops
the narrative half being the half that goes missing at all. It does not fix the stall and it does not
soften rule 1 — a plan carrying a `## Challenge` section from an agent that never reported is still an
incomplete stage, and the most misleading state of all, because it reads as fully reviewed. `/plan`
step 3 and `/implement` step 3 both say so explicitly.

**Not fixed, and cannot be fixed from inside the pack.** The stall is in the harness, not in any
agent file. What the pack can do is stop treating silence as assent, which is what the rules above
and merge-reviewer's "verify mechanically" language do.

**Related:** [[2026-07-10-bash-tool-silent-failure-windows]] is the same shape one layer down — blank
output that reads as success. The general lesson both share: **on this machine, absence of a signal is
never evidence that the signal would have been positive.**
