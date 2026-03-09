---
name: implement
description: Orchestrates the full agent-pack pipeline for a task: branch-manager → [tech-lead] → engineer(s) → code-reviewer → [security-reviewer] → [performance-reviewer] → test-engineer. Use when implementing a feature, fix, or change end-to-end.
---

# Implement Task

Run the full agent pipeline for the task the user described:

1. **branch-manager** — always first. Confirm the working branch is correct before any code changes.

2. **tech-lead** — invoke if the task is ambiguous, spans multiple concerns, or touches more than three files. Skip for well-scoped, single-file tasks.

3. **devils-advocate** — invoke before implementation if the task introduces a new pattern, a new dependency, or an irreversible architectural change. Skip for small bug fixes and established patterns.

4. **api-designer** — invoke before engineer agents if the task creates or significantly modifies API endpoints. Skip for internal refactors that do not change the API surface.

5. **Engineer agents** — invoke based on the file types being changed:
   - C# / .NET changes: **csharp-engineer**
   - TypeScript / Vue 3 changes: **typescript-engineer**
   - Schema, migrations, SQL: **database-engineer**
   - Run csharp-engineer and typescript-engineer in parallel if both are needed and there are no shared files between them.

6. **code-reviewer** — always after any engineer agent output.

7. **security-reviewer** — invoke if changes touch authentication, authorization, data access, PII, external endpoints, or secrets.

8. **performance-reviewer** — invoke if changes include database queries, API endpoints, loops over collections, or caching logic.

9. **test-engineer** — always last, after code-reviewer completes. Never invoke before code-reviewer has finished.

Do not skip steps without stating a reason. State which agents you are skipping and why before beginning.
