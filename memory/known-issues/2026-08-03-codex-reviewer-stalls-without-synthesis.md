---
date: 2026-08-03
type: known-issue
status: active
superseded-by: n/a
scope: agents/codex-reviewer.md
overrides-convention: no
related-to: n/a
discovered: 2026-08-03
---

# codex-reviewer can run, work visibly, and never produce a synthesis — the step looks done

During the `devops-azure` batch-write cut, `codex-reviewer` was dispatched for a cross-model second
opinion. It **launched successfully and did real work**, then stopped without ever answering.

**What was observed:**

- `codex --version` -> `codex-cli 0.144.4`, exit 0. Bare `codex` resolves fine; no PowerShell-wrapper
  problem, despite `codex` being `codex.ps1` on this machine.
- The run reached a real session: model `gpt-5.5`, sandbox read-only, and it **echoed the dispatch
  prompt back** before issuing roughly **17 distinct web searches** against `learn.microsoft.com`
  (ADO tag limits, WIQL `CONTAINS` semantics, `az boards`/`az devops invoke` behaviour, REST
  `validateOnly`/`suppressNotifications`/`bypassRules`, parent/child type constraints).
- Then it stopped. The output file **settled at 10,611 bytes** — byte-identical across a 75-second
  stability check and still identical five minutes later — with **no synthesis and no answer to any of
  the five questions asked.** CPU on both processes was flat (2.4s -> 2.5s over five minutes). They
  exited on their own some minutes later.
- The transcript contains **`hook: UserPromptSubmit Failed` twice**. That is the first suspect and has
  not been diagnosed.

**Why this matters more than a failed tool call.** The dispatch *appears* to have happened: an agent was
invoked, a process ran, output was produced. A later reader of a merge record — or `merge-reviewer`
itself, which verifies that required stages ran — can reasonably infer a cross-model opinion existed.
It did not. `dd5df72` shipped with **no external review at all**, on a cut that is architectural,
irreversible, and spans systems: exactly the profile `CLAUDE.md` names as warranting the check.

The gap was consequential rather than theoretical. Two of codex's own search targets were the questions
that mattered most, and both were later answered the hard way: whether `System.Tags` is what real ADO
deployments use for a machine-readable key, and `validateOnly` as a possible server-side dry run. A day
later a live probe found `[System.Tags] CONTAINS` to be whole-tag membership rather than substring
matching, invalidating the shipped resume path — see
[[2026-08-03-wiql-tags-contains-is-whole-tag-not-substring]]. A working cross-model pass looking at ADO
semantics might well have surfaced it before implementation.

**Compounding factor: the agent went idle without reporting.** `codex-reviewer`'s only tool is `Bash`,
and it had put the `codex` run in the background after a first foreground attempt hit a 5-minute cap
(exit 143). It then reported itself idle **while its own background job was still running**, so no
report ever arrived. Reading the output file directly was the only way to learn the run had produced
nothing. Several other agents in the same session also idled after finishing work but before reporting;
in each of those cases the work was fine and only the reporting failed, which is the shape that makes
this hard to notice.

**Workaround:**

1. **Never record `codex-reviewer` as having run without a synthesis in hand.** Absent output is not a
   quiet pass — it means the step did not happen, and it belongs in the plan's `## Risks` and the merge
   record as **a gap in the review**, not as a completed stage.
2. **Read the output file rather than trusting the agent's status.** It writes to a file; that file is
   the evidence. Idle is not the same as finished.
3. Distinguish this from genuine unavailability. `codex` being absent or unauthenticated is the
   documented skip case and is fine. This is different: the CLI works, the run starts, and the answer
   never arrives — so the "skip silently if unavailable" rule does not cover it and the run must be
   reported as failed rather than skipped.

Not investigated: whether `hook: UserPromptSubmit Failed` is the cause, whether a longer window would
have completed the synthesis, or whether the web-search phase is where it hangs. A re-run is cheap and
would either produce the missing opinion or confirm the failure is reproducible.
