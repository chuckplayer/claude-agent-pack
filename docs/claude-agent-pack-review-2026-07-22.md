# Claude Agent Pack vs. Current Claude Code — Scheduled Review
**Run date:** 2026-07-22 · **Installed Claude Code version:** 2.1.217 · **Pack version:** 1.0.0 (per `VERSION`, last commit `1ab139c`)

## 1. Top finding: background-agent auto-commit/push/PR conflicts with the pipeline's gates

As of **v2.1.198 (July 1, 2026)**, Claude Code subagents run in the background by default, and any background agent that finishes code work inside a `worktree`-isolated session now **auto-commits, auto-pushes, and opens a draft PR on its own** instead of stopping to ask ([source](https://aiagentsfirst.com/claude-code-v2-1-198-background-agents), [GitHub issue #73197](https://github.com/anthropics/claude-code/issues/73197)). No setting to disable this existed as of the issue filing.

This is a direct conflict with the pack's design:
- `skills/implement/SKILL.md` dispatches every engineer agent with `isolation: "worktree"`.
- `agents/merge-reviewer.md` is documented as "the final gate" and the only agent allowed to commit; `agents/git-engineer.md` Mode C is the only one allowed to push/open a PR.
- If the underlying engine now auto-commits/pushes/opens a draft PR the moment an engineer agent's worktree session finishes — before ts-linter, code-reviewer, security-reviewer, test-engineer, or merge-reviewer ever run — the pipeline's review gates can be silently bypassed and an unreviewed draft PR can land on origin.

**Recommendation:** Before the next `/implement` run, verify actual behavior on 2.1.217 (test with a throwaway branch), and if auto-publish is still on by default, add an explicit permission deny rule (e.g. `Bash(git push:*)`, per the workaround requested in #73197) scoped to engineer-agent worktree sessions, or note in `CLAUDE.md`/`skills/implement/SKILL.md` that engineers must be launched in a mode that suppresses auto-publish until this is configurable natively.

## 2. New engine feature worth adopting: Dynamic Workflows

Anthropic shipped **Dynamic Workflows** (June 2026): the lead agent writes a short deterministic JavaScript orchestration script (`agent()`, `parallel()`, `pipeline()` primitives) that fans work out to up to ~1,000 subagents, rather than relying on the lead model to remember and correctly follow prose sequencing rules ([source](https://claude.com/blog/introducing-dynamic-workflows-in-claude-code)).

Much of `CLAUDE.md`'s "Sub-Agent Routing" section — the sequential/parallel dispatch rules, the "always run X after Y" ordering, the ts-linter/code-reviewer/security-reviewer/performance-reviewer/smell-reviewer fan-out — is exactly the kind of fixed, deterministic sequencing that keeps having to be re-documented in prose (and re-broken, per the worktree-base gotchas already logged in `memory/known-issues/`) because the lead agent has to *interpret* the rules correctly on every run.

**Recommendation:** Consider expressing the fixed portions of `/implement` and `/review-pr` as a Dynamic Workflow script instead of (or alongside) the current prose pipeline in `skills/implement/SKILL.md`. Candidates: the deterministic "engineer → ts-linter (gate) → code-reviewer → {security, performance, smell in parallel} → test-engineer → merge-reviewer" chain has no branching that depends on judgment except which engineer(s) to invoke — a good fit for `pipeline()`/`parallel()` primitives, leaving the lead model to only decide the fan-out inputs.

## 3. Other redundancy / consolidation candidates

- **`skills/devops-github` and `skills/devops-azure`** shell out to `gh`/`az` specifically to avoid requiring an MCP server. This environment (and current Cowork/plugin ecosystem) now has native GitHub and Atlassian connectors available as installable plugins (seen connecting in this session: `plugin:engineering:github`, `plugin:productivity:atlassian`). Worth evaluating whether the CLI-based skills should defer to a connector when one is installed and authenticated, falling back to `gh`/`az` only when it isn't — rather than being the CLI-only path unconditionally.
- **Bespoke `memory/` system vs. native persistent memory.** Claude Code/Cowork now ships a first-class, cross-session memory system (typed `user`/`feedback`/`project`/`reference` memory files with an index) at the account level. The pack's `memory/decisions/architecture/context/known-issues` convention is project-scoped and serves a different purpose (engineering decisions tied to a specific repo), so this is not a duplicate to delete — but it's worth a short note in `docs/AGENT-GUIDE.md` clarifying the boundary (project memory vs. account memory) so a new contributor doesn't try to use one where the other belongs.
- **`known-issues/2026-07-15-custom-agent-powershell-tool-grant-nonfunctional.md`** — this describes a bug on a now-superseded version window. Worth a quick re-test on 2.1.217: confirm whether declaring `PowerShell` in a subagent's `tools:` frontmatter still silently grants nothing. If fixed, mark the memory file `status: superseded`; if not, no action needed.

## 4. Features that don't change anything in the pack

- The built-in **Explore** agent (fast read-only search) and **claude-code-guide** agent don't overlap with any pack agent — the pack's read-only reviewers (code-reviewer, security-reviewer, performance-reviewer, smell-reviewer) are lens-specific critics, not general-purpose search, and `repo-map`/`onboard` produce a persisted, git-commit-stamped artifact that Explore doesn't.
- The new **Notification hook** events (`agent_needs_input` / `agent_completed`) are additive and don't obsolete anything, but could be wired up alongside the existing Stop hook to fire an Obsidian capture or a user notification when a long `/implement` pipeline subagent finishes in the background — a genuinely new capability, not a replacement.
- `/dataviz` (native) and the Explore-agent model change are unrelated to this pack's scope.

## Summary of actions, in priority order
1. Verify whether background-agent auto-commit/push/draft-PR is still on by default in 2.1.217 for worktree-isolated engineer agents; if so, add a permission guard before the next `/implement` run.
2. Evaluate porting the deterministic portion of the `/implement` pipeline to a Dynamic Workflow script.
3. Decide whether `devops-github`/`devops-azure` should prefer an installed GitHub/Atlassian connector over `gh`/`az` when available.
4. Re-test the PowerShell tool-grant issue on 2.1.217 and update/supersede the memory file accordingly.
5. Add a one-line boundary note distinguishing project `memory/` from native account memory.
