---
name: review-pr
description: Review changed files or an open PR with code-reviewer, security-reviewer, and performance-reviewer. Use when the user wants a quality check on a diff, a PR number, or the current working-tree changes without running the full implement pipeline.
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
