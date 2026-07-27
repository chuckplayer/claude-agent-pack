**Date:** 2026-07-27
**Type:** decision
**Status:** active
**Superseded-by:** n/a
**Scope:** skills/implement, skills/refactor, skills/scaffold, skills/review-pr, CLAUDE.md Sub-Agent Routing
**Overrides-convention:** no
**Related-to:** implement, refactor, scaffold, review-pr, merge-reviewer, git-engineer

## Summary

The pack will **not** reimplement its pipelines as Dynamic Workflow scripts
(`Workflow` tool, `pipeline()`/`parallel()`). The prose routing rules in `CLAUDE.md` and
the numbered steps in each SKILL.md remain the orchestration mechanism. The standing
recommendation carried by the daily version reviews from 2026-07-22 through 2026-07-26 is
closed as declined, not deferred — the daily review should stop re-raising it and instead
watch for the specific reversal condition in **Implications** below.

## Context

Claude Code's Dynamic Workflows engine matured over 2.1.187–2.1.220: 2.1.202 added a
"Dynamic workflow size" `/config` setting plus `workflow.run_id`/`workflow.name`
OpenTelemetry attributes. Four consecutive scheduled reviews observed that the
deterministic spine of `/implement` — engineer → ts-linter gate → code-reviewer →
{security, performance, smell} in parallel → test-engineer → merge-reviewer — is exactly
the shape `pipeline()`/`parallel()` exists to express, and that encoding it as a script
would stop the lead model from having to re-interpret prose rules correctly on every run.

## Rationale

The pipeline is not purely deterministic. It contains three points where a human decides
what happens next, and workflow subagents cannot prompt the user:

1. **git-engineer** holds an `AskUserQuestion` grant and uses it — branch confirmation
   (step 1) and the push/PR decision (step 11) are user calls, not script branches.
2. **Finding adjudication.** Warning/Suggestion findings from code-reviewer,
   performance-reviewer, and smell-reviewer are advisory; the user decides whether to act.
   smell-reviewer additionally offers to record accepted patterns as CONVENTIONS.md
   suppressions — an interactive negotiation, not a return value.
3. **Retry routing.** On a merge-reviewer FAIL, which agent receives which finding is a
   judgment call, and the worktree stale-base repair (`implement` step 5b) can stop and
   hand a conflicting file list back to the user mid-run.

A workflow could only model these by returning early and letting the lead session resume —
at which point the script is a wrapper around the fan-out stage, not the pipeline, and the
prose rules still have to exist for everything around it. Two orchestration mechanisms
describing one pipeline is worse than one, especially since the pack's fan-outs are single
digits wide and sit far under both the concurrent-subagent cap (20) and the session spawn
cap (200) — there is no scale problem to solve.

Secondary factor: `Workflow` requires explicit per-invocation user opt-in. Skill
instructions do satisfy that, but it means a pack skill silently consuming dozens of
agents' worth of tokens on a task the user thought was ordinary — a poor default for a
pipeline that runs many times a day.

## Alternatives Rejected

- **Full `/implement` as a workflow script.** Rejected: the three interactive gates above
  cannot be expressed, and dropping them would remove the user from decisions that are
  theirs (which findings to accept, whether to push).
- **Workflow-ify only the reviewer fan-out in `/review-pr`** (code-reviewer →
  security/performance/smell). This one is genuinely viable — no interactive gates, no
  worktrees, results merge cleanly. Rejected for now on cost/benefit: it is a 3–4 agent
  fan-out that already runs in parallel via a single multi-tool message, so a workflow buys
  determinism the current mechanism already delivers, at the price of a second
  orchestration idiom in the pack. This is the piece to revisit first if the decision is
  ever reopened.
- **Adopt workflows only for the `/scaffold` vertical slice.** Rejected: `/scaffold`'s
  ordering (api-designer → database-engineer → csharp-engineer → frontend-engineer) is
  strictly sequential, which is the case a script helps least.

## Implications

- Daily version reviews should treat Dynamic Workflows as **decided, not open**, and cite
  this file rather than re-deriving the recommendation.
- **Reopen condition:** a Claude Code release that lets a workflow script pause for user
  input (an `AskUserQuestion`-equivalent hook, or a documented resume-on-user-response
  primitive). That removes the sole blocking objection, at which point `/implement`'s spine
  becomes a fair candidate and the `/review-pr` fan-out becomes the natural pilot.
- No file changes result from this decision. The `Workflow` tool remains available for
  ad-hoc user-requested orchestration; nothing here restricts a user who explicitly asks
  for a workflow.
