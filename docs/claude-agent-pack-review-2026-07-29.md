# Claude Agent Pack vs. Current Claude Code — Scheduled Review
**Run date:** 2026-07-29 · **Installed/latest Claude Code version:** 2.1.220 (unchanged; confirmed newest entry in the upstream `CHANGELOG.md`, nothing dated July 26–29) · **Pack version:** 1.0.0 (commit `2195b30`, unchanged since the 2026-07-28 review — `git log 2195b30..HEAD` returns zero commits)

## Summary

This is a **confirmation pass**: Claude Code shipped nothing since 2.1.220 and the pack has not moved a commit since yesterday's review. Per the cycle table that means step 4 only — check each open item's revisit trigger, do not re-derive prior analysis, do not re-run the redundancy pass.

Five open items were checked against their stated triggers. **None met.** Two were checked by direct probe rather than changelog inference: GitHub issue #73197 is still `OPEN` with no assignee (last activity 2026-07-24, i.e. before yesterday's cycle), and the installed Obsidian CLI is still the 2026-03-23 build the silent-failure defects were confirmed against. Recount confirms **19 agents / 27 skills**, matching yesterday's figures — so 07-28's counts were accurate, not carried.

Two process findings surfaced, both about this review series rather than the pack: item numbering broke between cycles, and yesterday's review doc was never committed.

## Carried-forward items — resolved this cycle

None. No release, no pack change, no trigger met.

## Carried-forward items — still open

Numbering follows the 2026-07-28 review; item 5 is restored (see process findings).

1. **`worktree.baseRef` defaults to main, not HEAD.** Still `active`. Trigger: a Claude Code release note stating `isolation:"worktree"` bases on current HEAD by default, or that the `worktree.baseRef` default changed from `"fresh"` to `"head"`. **State: not met** — no release since 2.1.220, so no release note can exist. The pack's mitigation (settings + `git merge-base --is-ancestor` gates) is unaffected.

2. **PowerShell tool grant via custom-agent `tools:` frontmatter nonfunctional.** Still `active`. Trigger: a release note stating a custom agent's `tools:` frontmatter can grant the `PowerShell` tool to a spawned subagent. **State: not met** — no release since 2.1.220. The re-test procedure in the known-issue file is the verification step for *after* the trigger fires, not the trigger itself; running it absent a release would re-derive a known result.

3. **Dynamic Workflows adoption — declined 2026-07-27** (`memory/decisions/2026-07-27-decision-decline-dynamic-workflows-for-implement.md`). Reopen condition: a Claude Code release that lets a workflow script pause for user input. **State: not met**, and this cycle checked it against the live 2.1.220 `Workflow` tool contract rather than the changelog: the contract still offers no user-input primitive — an agent can be *skipped* mid-run (`agent()` returns `null`), which is the opposite of pausing to ask. Citing the decision record per its own instruction rather than re-arguing it.

4. **Official Obsidian CLI silent-failure modes** (`memory/known-issues/2026-07-27-obsidian-cli-silent-failure-modes.md`). Still `active`. Trigger: an Obsidian release note stating the CLI returns nonzero exit codes on error, or that an unrecognized `vault=` is rejected rather than ignored — an upstream Obsidian trigger, not a Claude Code one. **State: not met, checked directly** — `C:\Program Files\Obsidian\Obsidian.com` is still the **2026-03-23** build, the exact build both defects were probed against on 2026-07-27. No new Obsidian version has been installed, so there is nothing to re-probe.

5. **Background-agent auto-publish bypasses the merge gate** (`memory/known-issues/2026-07-27-background-agent-auto-publish-bypasses-merge-gate.md`, GitHub #73197, upstream since v2.1.198). Still `active`. Trigger: issue #73197 closing, or a release note mentioning a setting that disables background-agent auto-commit/auto-push/auto-PR. **State: not met, checked directly** — `gh issue view 73197` returns `state: OPEN`, `assignees: []`, `updatedAt: 2026-07-24T17:18:42Z`. The pack-side mitigation (the "never publish" hard constraint on all six engineer agents) was verified when it landed on 07-27 and needs no re-verification; the *upstream* bug remains live, which is why the memory file is correctly still `active`.

## Redundancy / adoption pass

**Skipped, correctly.** No agent or skill directory was added or removed (19/27, recounted, identical to 07-28), and no Claude Code release shipped anything to overlap. The **2026-07-28** pass still stands — it was the full pass triggered by the 26→27 skill count when `pack-review` itself was added, and it checked `pack-review` against `memory-audit` and `scripts/check-updates.sh` and found no merge or deprecation candidates. The 07-28 doc's standing note also holds: if `docs/ado-delivery-pipeline-brief.md` moves from brief to implementation it will add agent/skill directories and warrant a fresh pass at that point.

## Process findings on the review series itself

These concern this review's own record-keeping, not the pack's contents.

- **Item numbering broke between cycles.** The 2026-07-27 review numbered items 1–5, resolving 1–3 and leaving 4 (`worktree.baseRef`) and 5 (PowerShell tool grant) open. The 2026-07-28 review renumbered those same two items to **1** and **2**, which violates `pack-review`'s "keep item numbering stable across cycles so an item can be tracked by number." This cycle keeps 07-28's numbers as the working baseline rather than reverting — reverting would compound the churn — and adds item 5 for the background-agent issue. Future cycles should append, never renumber.

- **The 2026-07-28 review doc was never committed.** It is still untracked (`?? docs/claude-agent-pack-review-2026-07-28.md`), the sole entry in `git status`. `pack-review` step 8 requires same-day commit specifically so dated observations don't collapse into one timestamp. That deadline has already passed for 07-28; the recoverable outcome is two separate commits today, one per doc, so each retains its own date in the message even though both share a commit timestamp.

- **Item 5 was dropped from the 07-28 carried list, arguably by design.** The 07-27 review filed it under "resolved this cycle" because the *pack-side mitigation* landed, and the 07-28 review then had no carried entry to inherit. But the underlying memory file is `active` with an unmet upstream trigger, so the item was live the whole time and went unchecked for one cycle. The distinction worth preserving: "pack has mitigated it" is not the same closure as "trigger met." Only the latter should drop an item from the carried list.

## Next steps

1. Commit `docs/claude-agent-pack-review-2026-07-28.md` and `docs/claude-agent-pack-review-2026-07-29.md` as **two separate commits**, 07-28 first, each message naming its own review date.
2. Append future review items rather than renumbering, and keep an item on the carried list until its stated trigger is met — a landed pack mitigation is not trigger satisfaction.
