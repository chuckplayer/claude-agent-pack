---
name: debug
description: Diagnose and fix a failing test, error, or unexpected behavior. Routes to the appropriate engineer based on the error context. Lighter than /implement — no worktree isolation, no full pipeline ceremony.
---

# Debug

Diagnose and fix the error, failing test, or unexpected behavior the user described.

## 1. Gather context

Ask for (or extract from what the user provided):
- The **error message or stack trace** (exact text preferred)
- The **file(s)** involved, if known
- How to **reproduce** the problem (command, test name, steps)
- Whether the error is **new** (regression) or has existed for a while

If the user has already provided all of this, skip asking and proceed.

## 2. Confirm the working branch

Run `git branch --show-current`. If the branch is `main` or `master`, warn the user and ask whether to create a fix branch before making changes. Do not create or switch branches automatically — just ask.

## 3. Read before acting

Before routing to an engineer:
- Read the files mentioned in the error or stack trace.
- If a test is failing, read the test file and the code it exercises.
- Check `memory/**/*.md` (if the directory exists) for any known-issues entries that match the symptom.
- Form a hypothesis about the root cause. State it explicitly.

## 4. Route to the appropriate engineer

Select based on the file types involved:

| File type | Engineer |
|-----------|----------|
| `.cs` / .NET | **csharp-engineer** |
| `.ts` / `.vue` | **frontend-engineer** |
| `.ts` in an MCP server | **mcp-engineer** |
| SQL / migration | **database-engineer** |

Pass the engineer:
- The error message and stack trace
- The files to read and modify
- Your root-cause hypothesis
- How to verify the fix (the test command or repro steps)

## 5. Verify the fix

After the engineer returns:
- Run the failing test or repro steps to confirm the fix works.
- If the fix introduces new failures, loop back to the engineer with the new errors.

## 6. Lightweight review

Run **code-reviewer** on the changed files only. Skip security-reviewer and performance-reviewer unless the fix touches auth, data access, or a hot path — state your reasoning either way.

## 7. Wrap up

Report:
- Root cause (confirmed or best explanation)
- What was changed and why
- Whether any follow-up work is needed (e.g., the fix revealed a broader pattern issue)

Do not run test-engineer, merge-reviewer, or git-engineer unless the user asks. This skill is diagnosis-and-fix, not full pipeline delivery.
