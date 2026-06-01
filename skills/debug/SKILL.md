---
name: debug
description: "Diagnose and fix a failing test, error, or unexpected behavior. Routes to the appropriate engineer based on the error context. Lighter than /implement — no worktree isolation, no full pipeline ceremony. Trigger this when someone says: something is broken, fix this error, my test is failing, why is this not working, I'm getting an exception, this is throwing an error, debug this, why does this crash. Do NOT use when the root cause is already known and the fix is small — use /hotfix instead. Do NOT use for architectural changes — use /implement instead."
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

If the error is localized to one layer, select based on file type:

| File type | Engineer |
|-----------|----------|
| `.cs` / .NET | **csharp-engineer** |
| `.ts` / `.vue` | **frontend-engineer** |
| `.ts` in an MCP server | **mcp-engineer** |
| SQL / migration | **database-engineer** |

**Multi-layer errors:** If the error spans layers (e.g., a frontend test failing because a backend API is broken), route to the layer containing the root cause first. Fix that layer, verify the downstream symptom resolves, then return here if the downstream layer also needs changes.

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

Run **code-reviewer** on the changed files only.

Skip security-reviewer and performance-reviewer unless:
- The fix touches auth, authorization, data access, or secrets → invoke **security-reviewer**
- The fix touches a hot path → invoke **performance-reviewer**

> **Hot-path examples:** tight loops over large collections, API endpoints handling high traffic, database queries in critical flows (login, checkout, search). If uncertain, include performance-reviewer.

State your reasoning either way.

## 7. Wrap up

Report:
- Root cause (confirmed or best explanation)
- What was changed and why
- Whether any follow-up work is needed (e.g., the fix revealed a broader pattern issue)

This skill is diagnosis-and-fix, not full pipeline delivery. Do not run test-engineer, merge-reviewer, or git-engineer unless the user asks.

**If the user asks to commit the fix**, apply these minimum gates before git-engineer commits:

1. Run the project's test suite (`dotnet test`, `npm run test`, or `pytest`) and confirm all tests pass. If any fail, loop back to the engineer before proceeding.
2. Route through **merge-reviewer** as the commit gate — do not use git-engineer Mode B directly. merge-reviewer will run the test suite (Step 0b), apply the gate checklist, and produce the commit.

> The purpose of /debug is speed of diagnosis. The purpose of committing is permanence. Once the user decides to commit, the same safety guarantees as /implement apply.

## Gotchas

- **Fixing the symptom, not the root cause:** Always state your root-cause hypothesis before routing to an engineer. If the hypothesis turns out to be wrong after the fix, loop back — do not close out just because the immediate error is gone.
- **Multi-layer errors:** A frontend error that says "404 Not Found" is often a backend routing bug, not a frontend bug. Read the network request and the backend logs before deciding which layer to fix. Route to the root-cause layer first.
- **Fix breaks other tests:** After the engineer returns, run the full test suite (or at minimum the suite for the changed module), not just the originally failing test. A fix that breaks three other tests is not a fix.
- **Hypothesis not passed to the engineer:** If you route to an engineer without a clear hypothesis, the engineer will re-investigate from scratch. Save time by passing the exact error, the files involved, and your best theory.
- **Escalating too quickly to /implement:** Debug is the right skill for most errors. Only escalate to /implement if the fix requires new files, new dependencies, or an architectural change that is out of scope for a targeted patch.
