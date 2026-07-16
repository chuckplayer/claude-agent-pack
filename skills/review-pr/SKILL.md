---
name: review-pr
description: "Review changed files or an open PR with code-reviewer, smell-reviewer, security-reviewer, and performance-reviewer. Use when the user wants a quality check on a diff, a PR number, or the current working-tree changes without running the full implement pipeline. Trigger this when someone says: review my PR, check my code, look at this diff, quality check, code review, does this look good, review PR #123, give me feedback on these changes, smell check, structural review. Do NOT use when the user wants to implement new changes — use /implement instead."
---

# Review PR / Changed Files

Run a focused multi-reviewer pass on a set of changed files or an open pull request.

## 1. Determine the change set

- If the user supplied a **PR number**, first resolve which platform it's on, using the same signals as `/devops`: repo name matching `GITHUB_REPOS`, project name matching `AZURE_DEVOPS_PROJECTS`, "work item"/"board" language, or the local git remote's host. If signals conflict or neither is present, ask directly rather than guessing.

  - **GitHub PR:** Before fetching anything, apply devops-github's setup verification and repo-targeting steps (`skills/devops-github/SKILL.md` §1–2) — confirm `gh` is installed and authenticated, and resolve the target repo from `GITHUB_REPOS`/local git remote. Then run `gh pr diff <number> --repo <org>/<repo>` for the diff and `gh pr view <number> --repo <org>/<repo>` for the title, description, and author.
  - **Azure DevOps PR:** Apply devops-azure's setup verification and org/project-resolution steps (`skills/devops-azure/SKILL.md` §1, §3–4) — confirm `az` and the `devops` extension are installed and authenticated, and resolve the org (PR IDs are org-scoped, so per devops-azure §2 only the org is strictly required). Fetch metadata with `az repos pr show --id <number> --org https://dev.azure.com/<org>`. The `az` CLI has no direct diff command — read the source/target branches from that output, `git fetch` both, and run `git diff <target>...<source>` locally to get the diff.
- If the user supplied **file paths**, use those directly.
- If neither was supplied, run `git diff main...HEAD --name-only` (or `git diff HEAD --name-only` if on main) to discover the changed files. Confirm the list with the user before proceeding.

## 1a. Probe mergeability against the target branch

Advisory check — surfaces merge conflicts *before* the PR reaches GitHub/Azure's automatic review. Run it whenever there is a **branch** to compare (a PR, or a working-tree review off a feature branch). Skip it for loose-file-path reviews with no branch context.

Resolve the two refs:

- **GitHub PR:** target and head come from `gh pr view <number> --repo <org>/<repo> --json baseRefName,headRefName`. Fetch both first — they may not exist locally: `git fetch <remote> <baseRefName> <headRefName>`.
- **Azure DevOps PR:** you already read the source (head) and target branches from `az repos pr show` in Step 1, and already `git fetch`ed them to reconstruct the diff. Reuse those refs.
- **Working-tree / branch review:** head is the current branch; the target is the repo default — prefer `origin/HEAD`, falling back to a local `main` then `master`:
  ```bash
  base=$(git symbolic-ref -q refs/remotes/origin/HEAD 2>/dev/null | sed 's#^refs/remotes/##')
  [ -z "$base" ] && for c in main master; do git rev-parse --verify -q "$c" >/dev/null && { base="$c"; break; }; done
  ```

Probe **without touching the working tree or index** using `git merge-tree` (Git 2.38+):

```bash
git merge-tree --write-tree --name-only "<target>" "<head>"; echo "exit=$?"
```

- **exit 0:** merges cleanly — report *Mergeable*.
- **exit 1:** conflicts — stdout is the synthetic tree OID on line 1, then the conflicting paths. Report those paths.
- **exit 128 / unknown option:** older Git without `--write-tree`. Fall back to the legacy three-arg form, which always exits 0 but prints conflict hunks to stdout:
  ```bash
  git merge-tree "$(git merge-base <target> <head>)" "<target>" "<head>" | grep -q '^<<<<<<<' && echo "CONFLICTS" || echo "CLEAN"
  ```

Do not run `git merge`/`git merge --abort` to test this — it mutates the working tree and can strand the user mid-merge. `merge-tree` is read-only by design.

## 2. Classify the change set

Before dispatching reviewers, classify what the changes touch:

- **Always invoke:** code-reviewer, smell-reviewer (for any code changes — skip for docs/config/migrations only)
- **Invoke if** changes touch authentication, authorization, data access, PII, external endpoints, or secrets: **security-reviewer**
- **Invoke if** changes include database queries, API endpoints, loops over collections, or caching logic: **performance-reviewer**

State which reviewers you are invoking and why before starting.

## 3. Dispatch reviewers (in parallel)

Pass each reviewer:
- The list of changed file paths
- The PR title and description (if available)
- Any relevant context the user provided

Run code-reviewer, smell-reviewer, security-reviewer, and performance-reviewer in parallel — their inputs are independent.

## 4. Synthesize findings

After all reviewers complete, produce a consolidated report:

```
## Review Summary — <PR title or branch name>

### Mergeability
- <Mergeable into `<target>`, no conflicts.> — OR —
- <Conflicts with `<target>` in: path/a, path/b. Resolve before merging.> — OR —
- <Not checked: loose-file review with no branch context.>

### Critical
- <finding> [source: code-reviewer | security-reviewer | performance-reviewer | smell-reviewer]

### Major
- <finding> [source: ...]

### Minor / Advisory
- <finding> [source: ...]

### No findings
- <reviewer> found no issues.
```

Group by severity (Critical → Major → Minor). Include the source reviewer for each finding.

Map each reviewer's severity vocabulary into the three buckets:

| Bucket | code-reviewer / smell-reviewer | security-reviewer | performance-reviewer |
|---|---|---|---|
| Critical | Critical | Critical, High | — |
| Major | Warning | Medium | High |
| Minor / Advisory | Suggestion | Low | Medium, Low |

(security High maps to Critical because it blocks merge-reviewer; performance findings are always advisory, so even High is Major at most.)

## 5. Recommend next steps

- If there are Critical findings: recommend routing back to the responsible engineer before merging.
- If there are only Minor/Advisory findings: surface them and ask the user whether to fix or accept.
- If no findings: confirm the PR looks clean and suggest merging when ready.
- If the mergeability probe reported conflicts: call this out prominently even when the code review is clean — a clean review does not mean the branch will merge. Recommend rebasing onto / merging the target branch and resolving conflicts before opening or updating the PR.

## Gotchas

- **No PR number and no files supplied:** Running `git diff main...HEAD --name-only` on a fresh branch returns nothing. Confirm with the user that the branch has commits before proceeding.
- **Skipping security-reviewer for API changes:** Even small endpoint changes can introduce authorization gaps. When in doubt, include security-reviewer — it is faster to run it than to explain why you didn't.
- **Reviewing stale diffs:** If the PR has been updated since the user last looked at it, re-fetch the diff (`gh pr diff <number>` or the `git diff` reconstructed from Azure DevOps branches) rather than relying on a diff the user pasted. Cached diffs miss new commits.
- **Conflating review with implementation:** This skill surfaces findings — it does not fix them. If the user asks you to fix a Critical finding during review, pause and confirm whether they want to switch to /implement or /debug.
- **Auth/setup failures, ambiguous repo or project targeting:** Don't troubleshoot these here — they're devops-github's and devops-azure's concern. Follow their gotchas sections (`skills/devops-github/SKILL.md`, `skills/devops-azure/SKILL.md`) instead of improvising a workaround.
- **Azure DevOps diff reconstruction fails (branch not found locally):** `git fetch` the source/target refs from the PR's remote (`az repos pr show` output includes the repository) before diffing — don't assume they're already present locally.
- **Mergeability probe on unfetched refs:** `git merge-tree` compares whatever the refs point at locally. If you probe a stale `main` (or a head ref you never fetched), the result is wrong — a phantom conflict or a false "clean". Always `git fetch` both refs immediately before the probe, and probe the remote-tracking ref (`origin/main`), not a stale local `main`.
- **Reporting mergeability as a code finding:** Conflicts against the target are a *state* of the branch, not a code-quality defect — keep them in the dedicated Mergeability section, not mixed into Critical/Major. A branch can be perfectly written and still conflict because the target moved.
