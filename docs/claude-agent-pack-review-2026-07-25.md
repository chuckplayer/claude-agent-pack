# Claude Agent Pack vs. Current Claude Code — Scheduled Review
**Run date:** 2026-07-25 · **Installed/latest Claude Code version:** 2.1.220 (July 25, 2026) · **Pack version:** 1.0.0 (commit `1ab139c`, unchanged since 2026-07-22 — no pack changes in the last three days)

Two releases shipped since the last scheduled review (2.1.218 → 2.1.219 → 2.1.220). This run checks both for anything relevant, re-verifies prior open items, and — per today's task — does a first real redundancy pass across the pack's 19 agents and 25 skills (prior two reviews focused mainly on version diffs).

## 1. New finding: nested-subagent depth cap reversed, but the pack's latent bug stays dormant

2.1.219 flipped the nested-subagent spawn default again: **subagents can now spawn nested subagents up to depth 3 by default** (was capped at depth 1 / effectively disabled in 2.1.217–2.1.218). This is the third change to this default in recent releases (5 levels → disabled → depth 3), so it's worth re-checking the depth-cap premise every cycle rather than assuming it's settled.

Re-verified against the 2026-07-24 finding (`agents/tech-lead.md` and `agents/devils-advocate.md` both instructing themselves to "invoke the obsidian-writer agent" directly, contradicting the calling-session-dispatches-agents rule): **still dormant, and for a different reason than before.** The depth cap was never the only guard — neither file grants the `Agent` tool in frontmatter (confirmed this cycle: none of the 19 files under `agents/` grant `Agent` to any agent), so the instruction remains unreachable regardless of the depth-cap default. The fix recommended on 2026-07-24 (change "invoke obsidian-writer" to "surface for the calling session to dispatch obsidian-writer") has not been applied — still open, still low urgency.

## 2. Prior open items — still unresolved as of 2.1.220

- **Background-agent auto-commit/push/draft-PR (since v2.1.198).** No changelog entry in 2.1.219 or 2.1.220 addresses this; GitHub issue #73197 status wasn't re-fetched this cycle (no version-relevant reason to expect movement in a two-release window) but no shipped setting appeared in either release's notes. Conflict with `merge-reviewer`/`git-engineer` being the sole commit/push/PR gate remains live.
- **`worktree.baseRef` still defaults to `"fresh"` (main).** 2.1.219 and 2.1.220 release notes contain no `baseRef`-related entries. `memory/known-issues/2026-07-15-worktree-isolation-bases-off-main.md` stays `active`.
- **PowerShell tool grant via custom-agent `tools:` frontmatter.** No new entries in 2.1.219/2.1.220 touch agent-frontmatter tool grants (2.1.219's changes are all model/sandbox/workflow/hook related). `memory/known-issues/2026-07-15-custom-agent-powershell-tool-grant-nonfunctional.md` stays `active`.

## 3. Checked and ruled out as non-issues this cycle

- **Opus 5 becoming the default Opus model, Opus 4.7 losing fast-mode eligibility (2.1.219).** All 18 agent files use tier aliases (`opus`/`sonnet`/`haiku`) in their `model:` frontmatter — none pin a dated snapshot like `claude-opus-4-7-*`. `tech-lead` and `devils-advocate` use `opus`; nine implementation/review agents use `sonnet`; `git-engineer`, `obsidian-writer`, and `ts-linter` use `haiku`. This rollout should resolve transparently with no file edits.
- **`sandbox.network.strictAllowlist` (2.1.219).** Relevant surface exists — `devops-github`/`devops-azure` shell out to `gh`/`az` hitting external APIs, and `mcp-engineer` notes `npm install` for new dependencies — but this is an opt-in setting with no evidence the pack's users have it enabled, and nothing in the pack currently configures it. No action; flag for the next cycle if the org starts enabling stricter sandboxing.
- **`DirectoryAdded` hook (2.1.219).** `skills/implement/SKILL.md` does create worktrees mid-pipeline, which is the kind of event this hook fires on, but the pack has no hook infrastructure reacting to directory changes today. Noted for awareness only — no actionable gap.
- **`workflowSizeGuideline` setting / dynamic workflows now defaulting to "medium" (fewer than 15 agents), added 2.1.219.** This reinforces rather than changes the standing Dynamic Workflows recommendation (see below) — the pack's largest fan-out (implement pipeline) is well under 15 agents per stage even at the new default guideline.
- **Nested subagent forwarding in stream-json (2.1.219), Fable/Opus `/model`-picker display fixes, Windows Git Bash path fix, Remote Control fixes.** None interact with anything in this pack.

## 4. Redundancy pass — 19 agents, 25 skills

No genuine redundancy found across the four clusters checked most likely to have overlap:

- **Obsidian (6 skills: `obsidian`, `obsidian-brief`, `obsidian-capture`, `obsidian-daily`, `obsidian-recap`, `obsidian-search`).** Each has a distinct trigger/output shape (router / ephemeral pre-work synthesis / ad-hoc single-note write / today's auto-generated note / narrative day-recap with persistence / keyword search). `obsidian-capture` (user-invoked, full structured vault note) is complementary to — not duplicative of — CLAUDE.md's own inline bash-based decision/session-state capture (terse one-liners to local flat files, folded in by the Stop hook automatically). Different destination, different granularity, different trigger.
- **DevOps (3 skills: `devops`, `devops-azure`, `devops-github`).** `devops` is a pure router by design (confirmed against `docs/azure-devops-github-skills-brief.md`); the vendor skills own their full CLI flows. No duplicated logic.
- **Memory (2 skills: `memory-audit`, `memory-query`).** Write/hygiene pass vs. read-only search — each explicitly excludes the other's use case. Also distinct in scope from the separately-installed `productivity:memory-management` plugin (personal shorthand/nickname decoding vs. this pack's project-scoped `memory/` tied to git commits).
- **Linting (`lint-agents` skill vs. `ts-linter` agent).** Different targets — pack's own `agents/*.md`/`SKILL.md` files vs. a consumer project's changed TypeScript/Vue source. No overlap.

No merge or deprecation candidates identified this cycle.

## Summary of actions, in priority order
1. Still open: fix `agents/tech-lead.md` and `agents/devils-advocate.md`'s Obsidian-sync sections to say "surface for the calling session to dispatch obsidian-writer" rather than "invoke obsidian-writer." Dormant but genuinely wrong; two-file fix.
2. Continue treating background-agent auto-publish as unresolved — no upstream fix in 2.1.219/2.1.220.
3. Leave `worktree.baseRef: "head"` and the `git merge-base --is-ancestor` gates in place.
4. Leave the PowerShell tool-grant known-issue as `active`.
5. No action needed on the Opus 5 rollout — tier-alias model pins absorb it automatically.
6. No redundancy found in this cycle's pass across agents/skills — nothing to merge or deprecate.
7. Dynamic Workflows recommendation stands, now further reinforced by the new medium/&lt;15-agent default guideline; still no action taken.
