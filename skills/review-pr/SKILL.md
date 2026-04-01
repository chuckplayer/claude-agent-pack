---
name: review-pr
description: Review changed files or an open PR with code-reviewer, security-reviewer, and performance-reviewer. Use when the user wants a quality check on a diff, a PR number, or the current working-tree changes without running the full implement pipeline. Trigger this when someone says: review my PR, check my code, look at this diff, quality check, code review, does this look good, review PR #123, give me feedback on these changes. Do NOT use when the user wants to implement new changes — use /implement instead.
---

# Review PR / Changed Files

Run a focused multi-reviewer pass on a set of changed files or an open pull request.

## 1. Determine the change set

- If the user supplied a **PR number**, run `gh pr diff <number>` to get the diff and `gh pr view <number>` to get the title, description, and author.
- If the user supplied **file paths**, use those directly.
- If neither was supplied, run `git diff main...HEAD --name-only` (or `git diff HEAD --name-only` if on main) to discover the changed files. Confirm the list with the user before proceeding.

## 2. Classify the change set

Before dispatching reviewers, classify what the changes touch:

- **Always invoke:** code-reviewer
- **Invoke if** changes touch authentication, authorization, data access, PII, external endpoints, or secrets: **security-reviewer**
- **Invoke if** changes include database queries, API endpoints, loops over collections, or caching logic: **performance-reviewer**

State which reviewers you are invoking and why before starting.

## 3. Dispatch reviewers (in parallel if all three are needed)

Pass each reviewer:
- The list of changed file paths
- The PR title and description (if available)
- Any relevant context the user provided

Run code-reviewer, security-reviewer, and performance-reviewer in parallel — their inputs are independent.

## 4. Synthesize findings

After all reviewers complete, produce a consolidated report:

```
## Review Summary — <PR title or branch name>

### Critical
- <finding> [source: code-reviewer | security-reviewer | performance-reviewer]

### Major
- <finding> [source: ...]

### Minor / Advisory
- <finding> [source: ...]

### No findings
- <reviewer> found no issues.
```

Group by severity (Critical → Major → Minor). Include the source reviewer for each finding.

## 5. Recommend next steps

- If there are Critical findings: recommend routing back to the responsible engineer before merging.
- If there are only Minor/Advisory findings: surface them and ask the user whether to fix or accept.
- If no findings: confirm the PR looks clean and suggest merging when ready.

## Gotchas

- **No PR number and no files supplied:** Running `git diff main...HEAD --name-only` on a fresh branch returns nothing. Confirm with the user that the branch has commits before proceeding.
- **Skipping security-reviewer for API changes:** Even small endpoint changes can introduce authorization gaps. When in doubt, include security-reviewer — it is faster to run it than to explain why you didn't.
- **Reviewing stale diffs:** If the PR has been updated since the user last looked at it, run `gh pr diff <number>` fresh rather than relying on a diff the user pasted. Cached diffs miss new commits.
- **Conflating review with implementation:** This skill surfaces findings — it does not fix them. If the user asks you to fix a Critical finding during review, pause and confirm whether they want to switch to /implement or /debug.
- **gh CLI not authenticated:** If `gh pr diff` fails with an auth error, ask the user to run `gh auth login` and retry. Do not try to work around it by parsing the URL manually.
