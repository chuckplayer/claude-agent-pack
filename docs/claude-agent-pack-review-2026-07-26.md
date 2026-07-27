# Claude Agent Pack vs. Current Claude Code — Scheduled Review
**Run date:** 2026-07-26 · **Installed/latest Claude Code version:** 2.1.220 (July 25, 2026 — unchanged since yesterday's review) · **Pack version:** 1.0.0 (commit `1ab139c`, unchanged since 2026-07-22 — no pack changes in four consecutive days)

## Summary

No new Claude Code release since the 2026-07-25 review (still 2.1.220, dated July 25 — nothing shipped July 26 as of this run). The pack repo is also unchanged (`1ab139c`, same commit as the prior three reviews). Per the 2026-07-25 review's own stated plan ("re-run the redundancy pass only if new agents/skills are added to the pack; otherwise version-diffing is sufficient until the next actual pack change"), and since neither condition is met, this cycle is a confirmation pass rather than a new analysis. No new findings.

## Carried-forward open items (all confirmed still unresolved, no upstream or pack movement)

1. **`agents/tech-lead.md` / `agents/devils-advocate.md` self-invocation wording bug** — both still say "invoke the obsidian-writer agent" instead of "surface for the calling session to dispatch obsidian-writer." Still dormant (neither file grants the `Agent` tool), still unfixed. First flagged 2026-07-24.
2. **Background-agent auto-commit/push/draft-PR vs. merge-reviewer/git-engineer gate** — GitHub issue #73197, open since v2.1.198. No changelog entry addressing it through 2.1.220.
3. **`worktree.baseRef` defaults to main, not HEAD** — pack's `worktree.baseRef: "head"` + `git merge-base --is-ancestor` workaround remains necessary. `memory/known-issues/2026-07-15-worktree-isolation-bases-off-main.md` stays `active`.
4. **PowerShell tool grant via custom-agent `tools:` frontmatter nonfunctional** — `memory/known-issues/2026-07-15-custom-agent-powershell-tool-grant-nonfunctional.md` stays `active`.
5. **Dynamic Workflows adoption** — standing recommendation from 2026-07-22, reinforced but not changed by later releases. No action taken; pack's fan-outs remain well under the default size guideline either way.

## Redundancy / new-feature-adoption pass

Not re-run this cycle — the 2026-07-25 review already completed the first full pass across all 19 agents and 25 skills and found no redundancy candidates. No agents or skills were added, removed, or modified since then, so re-running would reproduce the same result. Will re-run when the pack next changes.

## Next steps
No action items beyond the five carried-forward open items above, all of which require either an upstream Claude Code fix or a deliberate pack edit (not something to apply automatically in a read-only scheduled review). Next cycle: keep watching for (a) a Claude Code release that touches subagent-spawn tooling, worktree base-ref behavior, or PowerShell tool grants, or (b) any change to the pack repo, which would warrant a fresh redundancy pass.
