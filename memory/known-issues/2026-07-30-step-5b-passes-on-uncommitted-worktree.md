**Date:** 2026-07-30
**Type:** finding
**Status:** superseded
**Superseded-by:** fixed in place 2026-07-30; see Revisit trigger
**Scope:** global
**Overrides-convention:** no
**Related-to:** 2026-07-15-worktree-isolation-bases-off-main.md, skills/implement/SKILL.md, agents/merge-reviewer.md

## Summary

> **Fixed 2026-07-30.** All four call sites now check for commits as well as ancestry:
> `/implement` step 5b, `/refactor`, `/scaffold`, and `merge-reviewer` Step 0. An empty commit list
> routes to the transplant path instead of `git merge --no-ff`. Retained because the composition that
> produced it — engineers told not to commit, Step 0 transferring commits — is worth remembering.

`/implement` step 5b's ancestor check passes when an engineer's worktree branch has **no commits at
all**, so merge-reviewer's Step 0 then runs `git merge --no-ff` on a branch with nothing to merge
and the engineer's work is silently stranded. Step 5b detects a stale **base**; nothing in the
pipeline detects uncommitted **content**. The failure arrives through the *green* path, which is why
it survived the fix for [[2026-07-15-worktree-isolation-bases-off-main]].

## Symptoms

Observed live on 2026-07-30 with `infrastructure-engineer` dispatched at `isolation: "worktree"`:

```
$ git merge-base --is-ancestor feat/durable-plan-spine worktree-agent-af50377807aa954df
$ echo $?
0                                    # step 5b says "safe, proceed"

$ git log --oneline feat/durable-plan-spine..worktree-agent-af50377807aa954df
                                     # empty -- zero commits on the worktree branch

$ git -C <worktree-path> status --short
 M scripts/setup-project.sh          # the work is here, uncommitted
```

The agent's handoff was accurate and its verification was sound — it had explicitly been told not to
commit, since merge-reviewer owns commits. Nothing misbehaved. The gap is in the procedure.

## Root cause

Two correct rules compose into a hole:

1. Engineer agents are told not to commit — merge-reviewer owns commits. So leaving changes
   uncommitted in the worktree is the *expected* behaviour, not a mistake.
2. merge-reviewer integrates worktrees with `git merge --no-ff` (`agents/merge-reviewer.md` Step 0,
   exit-0 branch), which transfers **commits**. A branch with no commits merges nothing and reports
   success.

`git merge-base --is-ancestor A B` is trivially true when `B` is at the same commit as `A`, so a
worktree that has done work but committed nothing satisfies step 5b perfectly. The non-zero branch of
Step 0 *does* handle this — it captures `git diff` including uncommitted changes — but it only runs
when ancestry is *bad*. Good ancestry plus no commits is the one combination nobody checks.

## Workaround

Applied on 2026-07-30, and the pattern to repeat until the pipeline is fixed:

After step 5b's ancestor check passes, **also confirm the worktree branch has commits**:

```bash
git log --oneline <feature-branch>..<worktree-branch>    # empty output = nothing to merge
git -C <worktree-path> status --short                    # non-empty = uncommitted work exists
```

If the branch has no commits but the worktree has modifications, do **not** rely on
`git merge --no-ff`. Either diff the worktree and apply the change in the primary tree, or use Step
0's transplant recipe. On 2026-07-30 the change was five lines, so the cheaper route was taken:

```bash
diff <(git diff -- <file>) <(git -C <worktree-path> diff -- <file>)   # prove parity FIRST
# apply the same edit in the primary tree, then:
git worktree remove <worktree-path> --force && git branch -D <worktree-branch>
```

Proving diff parity before discarding the worktree is the load-bearing step — it is what makes
"re-apply it myself" safe rather than a silent re-implementation that might differ.

## Revisit trigger

Fix properly by amending `skills/implement/SKILL.md` step 5b to check for commits as well as
ancestry, and `agents/merge-reviewer.md` Step 0 to treat "ancestor OK but zero commits" as a case
requiring the transplant path rather than the plain merge. Until then, expect this on every
worktree-isolated dispatch where the engineer was told not to commit — which is all of them.
