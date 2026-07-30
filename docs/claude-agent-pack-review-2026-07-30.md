# Claude Agent Pack vs. Current Claude Code — Scheduled Review
**Run date:** 2026-07-30 · **Installed/latest Claude Code version:** 2.1.220 (July 25, 2026 — confirmed against the official changelog; nothing dated after it, so still the newest release) · **Pack version:** 1.0.0 (commit `869549a`, moved from `2195b30` — 18 commits since the last review doc's stated baseline)

## Summary

This is a **verification pass** (steps 4, 5, and 6 per `pack-review`): Claude Code shipped nothing new since 2.1.220, but the pack moved substantially — a full "durable plan spine" feature landed (tech-lead writes a plan file with acceptance bars and a deviations section, devils-advocate pressure-tests it, merge-reviewer gate 4a enforces it in three tiers, test-engineer maps evidence to bars), plus a same-day worktree fix, an install.sh non-interactive-mode fix, and three new memory findings from live exercises run today.

All five carried items from the 2026-07-29 review were checked against their stated triggers. **None met** — no Claude Code release exists to satisfy any of them. Two items grew new evidence this cycle without resolving: the Obsidian CLI known-issue gained a third silent-failure symptom, and a new, *distinct* PowerShell gotcha was discovered that should not be conflated with the still-open PowerShell tool-grant item. Recount confirms **19 agents / 27 skills** — unchanged, no new directories, so the redundancy pass is skipped per the standing 07-28 pass.

One baseline discrepancy is worth flagging: the 2026-07-29 review doc states the pack was "unchanged since 07-28" at commit `2195b30` with zero commits in `2195b30..HEAD`. That was accurate only up to the moment that doc was committed (`f5c101d`) — a further 17 commits landed later the same day and into today. This is the same "possible double-firing" pattern the 07-29 review itself flagged in passing; noting it here rather than re-deriving it, since the effect (a stale "unchanged" claim) is now visible in the record two cycles running.

## Carried-forward items — resolved this cycle

None. No Claude Code release, and none of the five items' stated triggers were met by pack-side work (a pack mitigation is not trigger satisfaction, per the 07-29 review's own closing note).

## Carried-forward items — still open

1. **`worktree.baseRef` defaults to main, not HEAD.** Still `active`. Trigger: a release note stating `isolation:"worktree"` bases on current HEAD by default. **Not met** — no release since 2.1.220. Note: today's *separate* worktree fix (item below, "step 5b passes on uncommitted worktree") addressed a different failure mode in the same subsystem — a branch with good ancestry but zero commits — and does not touch this item's trigger.

2. **PowerShell tool grant via custom-agent `tools:` frontmatter nonfunctional.** Still `active`. Trigger: a release note stating a custom agent's `tools:` frontmatter can grant the `PowerShell` tool to a spawned subagent. **Not met** — no release since 2.1.220. A new, unrelated PowerShell finding landed today (`memory/context/2026-07-30-powershell-mangles-native-exe-arguments.md`): PowerShell 5.1 mangles `${...}` expansions and unquoted spaces when handing a command to a native executable, and `(Get-Command bash).Source` resolves to the WSL stub rather than Git Bash on this machine. This is a shell-invocation gotcha, not a tool-grant one — it does not resolve or extend item 2, it's a distinct entry.

3. **Dynamic Workflows adoption — declined 2026-07-27.** Reopen condition: a release letting a workflow script pause for user input. **Not met.** No new release; the decision record stands.

4. **Official Obsidian CLI silent-failure modes.** Still `active`, but the file grew a third symptom this cycle: a large `content=` argument (~23 KB observed) creates a **0-byte file while still printing `Created:` and exiting 0** — argv-size truncation at the native-command boundary, no established threshold. This is the first live case confirming why the pack's "verify on the filesystem, never through the CLI" workaround earns its place: the stdout check passed and only the filesystem read-back caught the empty file. Trigger (an Obsidian release fixing exit codes/vault targeting/success reporting) is **still not met** — the installed CLI is unchanged.

5. **Background-agent auto-publish bypasses the merge gate (GitHub #73197).** Still `active`. Checked directly against the live issue page rather than inferred: **state is Open, no assignee**, filed 2026-07-02 against v2.1.198, no resolution activity visible. Trigger (issue closing, or a release note adding a setting/permission-rule path to disable auto-commit/push/PR) **not met**.

## Verification of this cycle's pack changes

Verified against `git diff 2195b30..HEAD`, not commit messages, via a dedicated pass over each changed file:

- **agents/tech-lead.md** — confirmed: writes the plan-directory guard (rejects placeholder/absolute/`..`/UNC/drive-prefixed/shell-metacharacter values, falls back to `docs/plans`), writes `## Acceptance bars` with `BAR-nnn` ids and required `Evidence:` lines, and writes `## Deviations` as a sentinel it never fills in.
- **agents/merge-reviewer.md** (bumped to 1.3.0) — confirmed: gate 4a's four-state plan resolution and bar verification are present; the three-tier `## Deviations` enforcement matches `memory/decisions/2026-07-30-decision-plan-deviations-gate-tiers.md` exactly (sentinel-present mechanical check, engineer-claim-unrecorded check, bounded stated-call-vs-diff check); Step 0 now detects "ancestor OK but zero commits" and routes to a transplant path instead of a blind `git merge --no-ff`.
- **agents/test-engineer.md** — confirmed: new evidence-to-bar mapping section, one row per `BAR-nnn`, `NONE` permitted, included only when a plan was passed.
- **skills/implement/SKILL.md** — confirmed: step 5 pastes plan calls verbatim into dispatch prompts and requires the `Departures from stated calls:` line; step 5b now checks for commits as well as ancestry; step 10 handles the `## Deviations` sentinel replacement and the bounded bar-amendment license.
- **install.sh / scripts/check-updates.sh** — confirmed: every prompt now routes through a `prompt()` helper with `--yes`/`--non-interactive`/`-y` and automatic no-TTY detection, fixing the same-day `install.sh` abort-on-EOF defect; retired-agent/skill detection and removal lists were expanded.
- **skills/refactor/SKILL.md, skills/scaffold/SKILL.md** — confirmed these received only the worktree zero-commit fix and no `plan_id`/plan-adoption logic, consistent with CLAUDE.md's statement that both deliberately stay exempt from plan handling.

No discrepancy was found between what the commits/CLAUDE.md claim and what the diffs actually contain.

Three new memory findings from today's live exercise are worth surfacing as a set, since they share a root cause: **an artifact that looks like a pass can be wrong in ways that don't show up as an error.** `2026-07-30-agent-output-must-be-attributable-to-be-evidence.md` documents a stale agent silently repairing its own evidence, two agents colliding on the same output filename, and a cleanup step destroying a result before it could be attributed — all inside one verification exercise for the plan-spine feature itself. That finding, plus the Obsidian 0-byte-write symptom and the install.sh abort-on-EOF defect, are three independent instances of the same "plausible output, no effect" failure class the pack has now hit repeatedly across CLI tools, install scripts, and its own subagent evidence chain.

## Redundancy / adoption pass

**Skipped, correctly.** No agent or skill directory was added or removed this cycle (19/27, recounted, identical to every prior cycle since 07-28) — three agent files and four skill files were edited in place, which does not trigger this pass. The 07-28 full pass still stands.

## Next steps

1. None of the five carried items are actionable right now — all are blocked on upstream releases or issue resolution outside this pack's control.
2. Consider whether `memory/known-issues/2026-07-27-obsidian-cli-silent-failure-modes.md`'s three accumulated symptoms warrant a standing pre-flight check (verify-by-filesystem-read-back) rather than a per-symptom workaround, since a fourth symptom in this family would otherwise just add another paragraph to the same file.
3. This review doc has been written but **not committed** — this run is unattended (scheduled task, no user present to approve per `pack-review` step 8). Commit on next interactive session if it looks correct: `git add docs/claude-agent-pack-review-2026-07-30.md && git commit -m "docs(review): 2026-07-30 scheduled review — verification pass, plan-spine feature confirmed against diffs"`.
