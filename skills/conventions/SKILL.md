---
name: conventions
description: Scaffold or update docs/CONVENTIONS.md by reading the actual codebase and interviewing the user. Use when setting up a new project or when conventions have drifted and need to be documented.
---

# Conventions

Scaffold or update `docs/CONVENTIONS.md` by grounding it in the actual codebase — not templates or guesses.

This skill is interactive. It reads existing code to discover what conventions are already in use, then asks the user to confirm, correct, or extend them.

## 1. Check current state

- Does `docs/CONVENTIONS.md` already exist?
  - **Yes:** read it fully. This is an update run. Identify which sections need revision.
  - **No:** this is a fresh scaffold. Read `docs/CONVENTIONS.template.md` if it exists for the expected structure.

- Check `memory/**/*.md` for any architecture or design decisions that should be reflected in conventions.

## 2. Read the codebase to discover actual conventions

Use Glob and Grep to observe what the code actually does — conventions should describe reality, not aspiration. Sample across all layers:

**Naming:**
- Class, method, and variable naming style (PascalCase, camelCase, snake_case)
- File naming patterns
- Interface naming (prefix `I`? suffix `Interface`?)

**Architecture:**
- Directory structure and layer boundaries
- How dependencies flow between layers (DI? static? direct instantiation?)
- Whether repositories, services, and controllers are consistently separated

**Error handling:**
- How exceptions are caught and logged
- Whether a global error handler exists
- Return types for errors (exceptions, Result<T>, tuples?)

**Testing:**
- Test framework and file location pattern
- Naming convention for test classes and methods
- Whether mocks, fakes, or real dependencies are used

**Frontend (if present):**
- Component structure (Options API vs. Composition API)
- State management pattern
- How API calls are made (fetch, axios, generated client?)

**Other:**
- Logging framework and log level conventions
- Authentication/authorization patterns
- Any compliance or audit requirements visible in the code

## 3. Interview the user

For each category where you found ambiguity, inconsistency, or nothing at all, ask the user one focused question. Do not ask all questions at once — work through them conversationally, grouping related topics.

Examples:
- "I see both `IFooService` and `FooService` interfaces in the codebase. Which should be the standard going forward?"
- "Tests appear to use both mocks and real database connections. Is there a preferred approach?"
- "There's no explicit error-handling pattern. What's your preferred approach — exceptions, Result types, or something else?"

## 4. Write or update CONVENTIONS.md

After gathering all answers:

- If creating fresh: write the full file using `docs/CONVENTIONS.template.md` as the structure, filling every section with what you discovered and what the user confirmed.
- If updating: edit only the sections that changed. Do not rewrite sections that are already accurate. Preserve any user-written content verbatim unless the user asked to change it.

The file must describe actual conventions — not aspirational ones. If a convention is aspirational ("we plan to migrate to X"), mark it clearly:

```markdown
> **Aspirational:** This convention is the target state. Existing code may not yet comply.
```

## 5. Confirm with the user

Present a summary of what was written or changed. Ask: "Does this accurately reflect how you want the team to work?" Make any corrections requested before finishing.

## 6. Suggest memory updates

If the conventions session revealed significant architectural decisions that aren't already in `memory/decisions/`, note them and ask the user whether to create memory entries for them. Do not write memory files directly — this skill is read/write only for `docs/CONVENTIONS.md`.
