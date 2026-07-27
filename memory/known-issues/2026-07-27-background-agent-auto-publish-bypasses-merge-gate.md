---
name: background-agent-auto-publish-bypasses-merge-gate
description: Background agents can auto-commit, auto-push, and open draft PRs with no opt-out setting, bypassing the pack's merge-reviewer/git-engineer publish gate
metadata:
  type: known-issue
  status: active
  discovered: 2026-07-27
---

Since Claude Code v2.1.198, background agents may automatically commit their work,
push the branch, and open a draft PR when they finish. There is no setting to disable
it. [GitHub issue #73197](https://github.com/anthropics/claude-code/issues/73197) has
been open since that release with no assignee and no shipped opt-out as of 2.1.220.

This conflicts directly with the pack's publish model, in which exactly two agents may
write to the remote: **merge-reviewer** commits to the feature branch, and only after
verifying that every required pipeline stage ran with no unresolved Critical findings;
**git-engineer** (Mode C) pushes and opens the PR, only after merge-reviewer returns
PASS. Every engineer agent is dispatched with `isolation: "worktree"` (see
`skills/implement/SKILL.md` step 5) and is supposed to hand back a diff, not a
published branch.

**Symptoms:** a worktree-isolated engineer's work appears as a commit — or a draft PR —
before code-reviewer, security-reviewer, smell-reviewer, or test-engineer has seen it.
merge-reviewer's gate checklist then runs against code that is already published, so a
FAIL verdict no longer prevents anything; the retry cycle rewrites history that is
already on the remote. Compounding factor: the auto-created branch may be based off
`main` rather than the feature branch — see
[[2026-07-15-worktree-isolation-bases-off-main]].

**Root cause:** harness-level behavior, not something the pack can configure away. The
pack can only constrain what its own agents are instructed to do and detect the result
after the fact.

**Workaround:**
1. Every engineer agent (csharp-, frontend-, mcp-, database-, python-,
   infrastructure-engineer) carries an explicit hard constraint: never run `git add`,
   `git commit`, `git push`, or open a PR; decline any auto-commit or auto-PR offer and
   report it in the handoff summary instead.
2. On a machine where this matters, scope a `deny` permission entry for
   `Bash(git push:*)` to engineer-agent sessions — git-engineer Mode C must keep the
   grant, so do not deny it globally.
3. After each engineer returns, `git log --oneline <feature-branch>..<worktree-branch>`
   and `gh pr list --head <worktree-branch>` reveal whether anything was published
   behind the gate. If so, tell the user before continuing the pipeline — do not
   silently proceed as if the gate held.

**Revisit trigger:** issue #73197 closing, or any Claude Code release note mentioning a
setting that disables background-agent auto-commit / auto-push / auto-PR. At that point
step 2 of the workaround can be dropped and this file marked `resolved`; keep step 1
regardless, since "engineers do not publish" is a pack design rule independent of the
harness bug.

**How to apply:** Treat any commit, branch, or PR that appears without merge-reviewer
having returned PASS as unreviewed, no matter how it got there. Do not let its existence
substitute for the gate.
