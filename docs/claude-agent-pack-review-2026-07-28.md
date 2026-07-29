# Claude Agent Pack vs. Current Claude Code — Scheduled Review
**Run date:** 2026-07-28 · **Installed/latest Claude Code version:** 2.1.220 (July 24/25, 2026 — unchanged; no changelog entry dated July 26–28) · **Pack version:** 1.0.0 (commit `2195b30`, up from `451cb34` — 11 commits landed since the 2026-07-27 review, the most active cycle to date)

## Summary

This is a **verification pass** (steps 4, 5, and 6 all apply): Claude Code shipped nothing new, but the pack moved substantially — 11 commits unifying the Obsidian vault-write transport into a verified CLI→REST-API→filesystem chain, adding a new `pack-review` skill (which formalizes this very review process), two new hooks (`_current.md` session-state carry-forward, auto-memory mirroring to the vault), and a new known-issue documenting two silent-failure modes discovered in the official Obsidian CLI. Skill count moved 26→27, which per `pack-review`'s own rule triggers the redundancy/adoption pass this cycle.

## Carried-forward items — still open, no movement

1. **`worktree.baseRef` defaults to main, not HEAD.** Still `active`. Trigger (a release note saying `isolation:"worktree"` bases on current HEAD by default) not met — confirmed absent through 2.1.220, no release since.
2. **PowerShell tool grant via custom-agent `tools:` frontmatter nonfunctional.** Still `active`. Trigger (spawning an agent with `tools: Bash, PowerShell` and seeing PowerShell appear) not re-tested this cycle since no relevant release landed; nothing in 2.1.220 or earlier touches this per prior scans.
3. **Dynamic Workflows decline, closed 2026-07-27** (`memory/decisions/2026-07-27-decision-decline-dynamic-workflows-for-implement.md`). Reopen condition (a workflow script able to pause for user input) still not met — confirmed via search: nested subagents still cannot prompt the user, only main-thread permission prompts can pause a run. Citing the decision record per its own instruction rather than re-deriving it.

## New item discovered and same-day mitigated (not carried from a prior review)

4. **Official Obsidian CLI has two silent-failure modes**, found and fixed in one cycle (`memory/known-issues/2026-07-27-obsidian-cli-silent-failure-modes.md`, discovered 2026-07-27): every CLI error returns exit 0, and an unrecognized `vault=` argument is silently ignored, writing to whichever vault is active instead of failing. `agents/obsidian-writer.md` was rewritten to treat this as load-bearing rather than cosmetic — every CLI write is now verified by reading back the absolute filesystem path (never the CLI's own `read`, which would answer for the same wrong vault), and a detected misroute is treated as a data-disclosure event with delete-and-warn remediation. This is an upstream Obsidian defect, not a Claude Code one, so it has no "revisit trigger" tied to Claude Code releases — its trigger is an Obsidian CLI release note, which the known-issue file states explicitly. Tracking it here because it materially changed `obsidian-writer.md`, three calling `SKILL.md` files, and the README in the same window this review covers.

## Verification of pack changes against diffs (not commit messages)

Per `pack-review`'s own step 5 rule, verified against `git diff`, not commit text:

- **The transport unification reaches every caller, not just the headline agent file.** The now-dead `session_api_written`, `cli_mode`, `rest_api_port`, and `rest_api_https` parameters were confirmed removed from all three `SKILL.md` files that dispatch `obsidian-writer` for the "Obsidian sync request" path (`implement`, `plan`, `refactor`) — a fix that only touched `obsidian-writer.md` would have left stale parameters in three other files.
- **`obsidian-capture/SKILL.md`'s old inline PowerShell/curl REST-write logic (former Step 3a) was fully removed**, not just deprecated in a comment — confirmed by diff, the entire block is gone and replaced with a one-line delegation to `obsidian-writer`. This also removes a second place in the pack that referenced "the PowerShell tool" as a fallback, independent of the still-open `codex-reviewer` PowerShell known-issue.
- **New scripts exist on disk, not just in documentation.** `scripts/obsidian-context-hook.js` and `scripts/obsidian-memory-hook.js` are both present, both wired into `install.sh`'s hook-registration list (Node and Python variants both updated), and both added to `scripts/check-updates.sh`'s marker list — confirmed via grep, not assumed from the README.
- **README corrections check out.** Skill count (26→27) and script count (8→10, correctly excluding `obsidian-stop-hook.test.js` from the "utility scripts" count) both match a fresh recount. The new hook-inventory table entries match `install.sh`'s actual `setHook(...)` calls line-for-line.

## Redundancy / adoption pass (run this cycle — skill directory count changed)

Ran per the rule triggered by the 26→27 skill count. `pack-review` itself already disambiguates in its own description ("Do NOT use to verify an installation — use `/system-check`"; "Do NOT use to validate frontmatter — use `/lint-agents`"; "Do NOT use to review code — use `/review-pr`"). Checked the two overlaps its description doesn't explicitly rule out:
- **vs. `memory-audit`** — distinct target: `memory-audit` assesses staleness of `memory/` *content* against the current codebase; `pack-review` compares the *pack's own agents/skills* against upstream Claude Code releases. No overlap.
- **vs. `scripts/check-updates.sh`** (surfaced through `/system-check`) — distinct axis: `check-updates.sh` diffs a user's *installed* copy against this repo's source (drift from `git pull`); `pack-review` diffs this repo against Claude Code itself. No overlap.

No merge or deprecation candidates found. Agent count unchanged at 19. No Claude Code feature shipped since 2.1.220 overlaps anything the pack does by hand; the standing Dynamic Workflows decline (item 3 above) still stands un-reopened.

## Worth flagging, not acting on

`docs/ado-delivery-pipeline-brief.md` (dated 2026-07-27, present on disk but not yet a pack change) proposes closing coverage gaps at delivery Stages 0 (ground-truth spec), 2 (backlog decomposition), and 4 (verify-against-spec), grounded in a real BA/PM playbook from the <internal-repo> Claims module build. It is explicitly marked "not yet specified in full, not implemented," and is blocked on workstream 2 of the companion `obsidian-cli-and-plan-spine-brief.md` (a durable plan-file spine). This is exploratory design, not a pack change, so it doesn't factor into this cycle's verification or redundancy pass — but it signals the next likely expansion of the pack's agent/skill set, which would warrant a fresh redundancy pass whenever it lands.

## Next steps

Both upstream-blocked items (`worktree.baseRef`, PowerShell tool grant) remain open with no new movement — continue checking their stated triggers directly rather than re-scanning the changelog. No action needed on the pack's Obsidian transport work; it was independently verified against diffs and checks out. If `ado-delivery-pipeline-brief.md` moves from brief to implementation, run the redundancy/adoption pass again at that point, since it would add new agent/skill directories.
