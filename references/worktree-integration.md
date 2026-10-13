# Worktree integration (merge-reviewer Steps 0 and 0a)

Read by `merge-reviewer` **only when one or more worktree branch names were passed to it**. With none, Step 0
and Step 0a do not apply and this file is not read. The steps below are the whole of that work: verify each
worktree branch really branched from the feature branch, merge it (or transplant its uncommitted changes when
it has no commits), then remove the worktrees and branches. Step 0b onward stays in `merge-reviewer.md`.

## Step 0 — Merge worktree branches

If one or more worktree branch names were provided, first verify each one actually branched from the feature branch before attempting to merge it — `isolation: "worktree"` only branches from the feature branch's current HEAD when `worktree.baseRef` is `"head"` in settings.json. If that setting is unset or `"fresh"` (the harness default), the worktree was silently based on local/origin `main` instead, regardless of what the calling skill's docs assumed. Do not skip this check on the belief that upstream steps already verified it.

For each worktree branch:

```bash
git merge-base --is-ancestor <feature-branch> <worktree-branch>
```

**Ancestry is not the only question. Also ask whether the branch has any commits:**

```bash
git log --oneline <feature-branch>..<worktree-branch>   # empty = nothing to merge
```

Engineers are told not to commit — you own commits — so a worktree branch routinely has **zero
commits** while the work sits uncommitted in the worktree. `merge-base --is-ancestor` is trivially
satisfied in that state. Merging it transfers nothing and reports success, **silently stranding the
work.** Treat an empty commit list as the transplant case below regardless of what ancestry says.

- **Exit 0 and the commit list is non-empty:** the worktree contains every commit on
  `<feature-branch>` and has work of its own — safe to merge normally:

  ```bash
  git checkout <feature-branch>
  git merge --no-ff <worktree-branch> -m "Merge <worktree-branch> into <feature-branch>"
  ```

- **Exit 0 but the commit list is EMPTY:** do **not** run `git merge --no-ff` — there is nothing on
  the branch to merge. Check `git -C <worktree-path> status --short`. If it shows modifications, use
  the transplant recipe in the next bullet, which captures uncommitted changes by design. If the
  worktree is clean too, the engineer changed nothing: report that as a finding rather than a
  successful merge of an empty branch.

  If this merge produces conflicts (`git status` shows `UU` files), **stop immediately** and output:

  ```
  FAIL -- merge conflict when integrating worktree branch <branch>.

  Required actions:
  - Resolve conflicts in: <list of conflicting files>
  - Route back to the appropriate engineer agent for resolution.
  ```

- **Non-zero exit:** the worktree branch diverged from `main`, not from `<feature-branch>` — a plain `git merge` would merge two unrelated histories and can introduce unintended commits or silently drop the engineer's changes into an unmerged/uncommitted state. Do **not** run `git merge --no-ff` on it. Instead, transplant the engineer's actual file changes onto the feature branch directly:

  ```bash
  git -C <worktree-path> diff "$(git -C <worktree-path> merge-base main HEAD)" > /tmp/<worktree-branch>.patch
  git checkout <feature-branch>
  git apply --3way /tmp/<worktree-branch>.patch
  ```

  This captures the engineer's full delta (committed and uncommitted) relative to its true starting point and applies it directly — sidestepping the bad ancestry rather than merging incompatible histories. If `git apply` reports conflicts, **stop immediately** and output the same FAIL format as above, with a note that the worktree's base was stale (not a genuine content conflict from concurrent work).

Do not proceed to the checklist until all worktree branches are cleanly integrated by one path or the other.

## Step 0a — Clean up worktree branches

After all worktree branches are cleanly merged, remove each worktree and its branch, then prune stale entries. For each worktree branch:

```bash
# Find path, remove worktree, delete branch, then prune
path=$(git worktree list --porcelain | grep -B5 "branch refs/heads/<worktree-branch>" | grep "^worktree" | awk '{print $2}')
[ -n "$path" ] && git worktree remove "$path" --force
git branch -d <worktree-branch> || git branch -D <worktree-branch>
git worktree prune
```

If `git branch -d` falls back to `-D`, note it in the output.
