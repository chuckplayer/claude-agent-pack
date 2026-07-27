# Claude Agent Pack vs. Current Claude Code — Scheduled Review
**Run date:** 2026-07-24 · **Installed/latest Claude Code version:** 2.1.218 (July 22, 2026) · **Pack version:** 1.0.0 (commit `1ab139c`, unchanged since the 2026-07-22 review — no pack changes in the last two days)

Only one release shipped since the last scheduled review (2.1.217 → 2.1.218), so this run re-verifies the prior open items and checks the new release for anything else relevant.

## 1. New finding: latent nested-agent-spawn bug in tech-lead and devils-advocate

Claude Code 2.1.217 changed subagents to **no longer spawn nested subagents by default** (a depth cap now applies; override with `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH`). That prompted a check of whether any pack agent relies on nested spawning — an agent that is itself running as a subagent further invoking the Agent tool, rather than the top-level session doing the fan-out.

Result: the pack's design is correctly lead-session-orchestrated everywhere **except two files**, which is a genuine internal defect independent of the Claude Code version:

- `agents/tech-lead.md` (Obsidian sync section) and `agents/devils-advocate.md` (same section) both say, verbatim, *"If set, invoke the **obsidian-writer** agent for each written memory file..."* — instructing the agent to call another agent directly.
- Neither agent's `tools:` frontmatter grants `Agent` (tech-lead: `Read, Write, Edit, Grep, Glob`; devils-advocate: `Read, Write, Edit, Grep, Glob, WebFetch`), so this instruction is currently unreachable — it silently can't execute, which is presumably why it hasn't caused a visible failure.
- This also contradicts tech-lead's own later line: *"You do not dispatch agents yourself -- the calling session does, based on your plan."*

**Recommendation:** Fix both Obsidian-sync sections to say "surface for the calling session to dispatch obsidian-writer" instead of "invoke obsidian-writer." This is a two-file documentation/prompt fix, not a code change, and is worth doing regardless of the Claude Code version — but it's also exactly the kind of latent bug the new nested-spawn depth cap would have converted from "silently does nothing" into "silently capped/blocked" the moment someone added `Agent` to either file's tool grant. Low urgency, low effort.

## 2. Prior open items — still unresolved as of 2.1.218

- **Background-agent auto-commit/push/draft-PR (since v2.1.198).** [GitHub issue #73197](https://github.com/anthropics/claude-code/issues/73197) is still open with no assignee and no shipped setting as of 2.1.218's release notes — confirmed by re-reading the issue directly. The conflict with `merge-reviewer`/`git-engineer` Mode C being the only agents allowed to commit/push/PR (per `skills/implement/SKILL.md`'s `isolation: "worktree"` dispatch) remains live. No workaround has been added to the pack yet.
- **`worktree.baseRef` defaulting to `"fresh"` (main), not current HEAD.** Scanned every changelog entry from 2.1.187 through 2.1.218: the only worktree fixes in that window are about subagents *escaping* their worktree into the shared checkout (2.1.210, 2.1.216) or worktrees not being deletable/discoverable — none change the default `baseRef` behavior itself. `memory/known-issues/2026-07-15-worktree-isolation-bases-off-main.md`'s workaround (explicit `worktree.baseRef: "head"` setting + `git merge-base --is-ancestor` gates in implement/refactor/scaffold + merge-reviewer) is still necessary and still not superseded by an upstream fix.
- **PowerShell tool grant via a custom agent's `tools:` frontmatter.** No changelog entry between 2.1.187 and 2.1.218 addresses granting `PowerShell` through agent frontmatter (2.1.216's "Improved validation of git and gh command arguments in the PowerShell tool" is a different concern — command validation, not tool grant). `memory/known-issues/2026-07-15-custom-agent-powershell-tool-grant-nonfunctional.md` should stay `active`, not be marked superseded.

## 3. Checked and ruled out as non-issues for this pack

- **`context: fork` background-by-default change (2.1.218).** No skill in `skills/` uses `context: fork` frontmatter — this behavior change doesn't affect the pack.
- **Agent names containing `:` now rejected (2.1.218).** No file under `agents/` has a colon in its `name:` field — not applicable.
- **Concurrent-subagent cap (default 20) and per-session subagent spawn cap (default 200), added 2.1.217/2.1.212.** The pack's largest fan-outs (implement's engineer → ts-linter → code-reviewer → {security, performance, smell} → test-engineer → merge-reviewer chain) top out at single digits of concurrent agents per stage — well under either cap. Not a practical constraint today, but worth remembering if the pack ever adopts the Dynamic Workflows suggestion below at larger scale.

## 4. Dynamic Workflows — reinforcing the standing recommendation

2.1.202 added a "Dynamic workflow size" `/config` setting (small/medium/large agent counts, advisory not enforced) and `workflow.run_id`/`workflow.name` OpenTelemetry attributes — both signs this engine feature is maturing, not experimental. The prior review's recommendation stands: the deterministic portion of `CLAUDE.md`'s "Sub-Agent Routing" section (engineer → ts-linter gate → code-reviewer → {security, performance, smell} parallel → test-engineer → merge-reviewer, with no judgment calls except which engineer(s) to invoke) remains a strong candidate for a `pipeline()`/`parallel()` Dynamic Workflow script instead of prose rules the lead model has to re-interpret correctly every run. No action taken this cycle; still a "worth doing" item, not urgent.

## Summary of actions, in priority order
1. Fix the two-file latent bug: change "invoke obsidian-writer" to "surface for the calling session to dispatch obsidian-writer" in `agents/tech-lead.md` and `agents/devils-advocate.md`.
2. Continue treating background-agent auto-publish as unresolved; do not trust an `/implement` worktree session as unreviewed-safe without a permission guard (e.g. `Bash(git push:*)`) scoped to engineer-agent worktree sessions.
3. Leave `worktree.baseRef: "head"` and the `git merge-base --is-ancestor` gates in place — no upstream fix has arrived.
4. Leave the PowerShell tool-grant known-issue as `active`.
5. No new redundancy candidates found this cycle beyond the ones already logged on 2026-07-22 (devops-github/devops-azure vs. native connectors, memory/ vs. account memory boundary note).
