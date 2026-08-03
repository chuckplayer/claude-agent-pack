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
   a read-only reviewer is cheap. Re-dispatch is always available; reconstructing a verdict nobody
   received is not.
3. **Prefer a check you can re-run yourself over a report you have to trust.** Where a stage's output
   is mechanically reproducible — `scripts/lint-agents.sh`, `node scripts/obsidian-stop-hook.test.js`,
   a test suite, a `git` fact — run it rather than reading a claim about it. merge-reviewer holds
   `Bash` precisely so it need not trust a report for anything reproducible. This is why gates 2a and
   2b instruct it to run the checks itself.
4. **For stages whose only artifact *is* the report** — code-reviewer, security-reviewer,
   performance-reviewer, smell-reviewer, devils-advocate — there is nothing to re-run and no
   artifact to inspect, so rule 1 is the whole defence. Say "did not report, re-dispatched" in the
   record rather than quietly counting it as a pass.

**Not fixed, and cannot be fixed from inside the pack.** The stall is in the harness, not in any
agent file. What the pack can do is stop treating silence as assent, which is what the rules above
and merge-reviewer's "verify mechanically" language do.

**Related:** [[2026-07-10-bash-tool-silent-failure-windows]] is the same shape one layer down — blank
output that reads as success. The general lesson both share: **on this machine, absence of a signal is
never evidence that the signal would have been positive.**
