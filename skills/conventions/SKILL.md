---
name: conventions
description: "Scaffold or update docs/CONVENTIONS.md by reading the actual codebase and interviewing the user. Use when setting up a new project or when conventions have drifted and need to be documented. Trigger this when someone says: document our team standards, set up conventions, what are our coding standards, conventions are out of date, update our style guide, write our CONVENTIONS.md. Do NOT use to read or apply existing conventions — those are loaded automatically. Do NOT use for architectural decisions — use /memory-audit instead."
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

| Category | What to look for |
|----------|-----------------|
| **Naming** | Class/method/variable casing, file naming, interface prefix (`I`?) |
| **Architecture** | Directory layers, dependency flow (DI? static?), repo/service/controller separation |
| **Error handling** | Catch/log patterns, global error handler, return type (exception/Result\<T\>/tuple) |
| **Testing** | Framework, file location pattern, test class naming, mocks vs. real deps |
| **Frontend** | Options vs. Composition API, state management, API call pattern (fetch/axios/generated) |
| **Other** | Logging levels, auth patterns, compliance requirements visible in code |

## 3. Interview the user

For each category where you found ambiguity, inconsistency, or nothing at all, ask the user one focused question at a time. Do not ask all questions at once — work through them conversationally.

Examples (each asked separately, not together):
- "I see interface files in the codebase — should they be named `IFooService` or `FooService`?"
- "What's your preferred approach for error handling — exceptions, Result types, or something else?"
- "Should tests use mocks, real dependencies, or does it depend on the test type?"

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

## Gotchas

- **Documenting aspirations as facts:** The most common failure mode is writing conventions that describe how the team wants to work rather than how it actually works. If the codebase contradicts a stated convention, flag the inconsistency — do not silently adopt the aspirational version. Mark aspirational items explicitly with the blockquote template in step 4.
- **Asking all questions at once:** Step 3 says one question at a time. Dumping a list of questions causes the user to give shallow answers. Work through them conversationally.
- **Rewriting user-written content:** On an update run, only touch sections that are incorrect or incomplete. Preserve any user-written prose verbatim unless explicitly asked to change it.
- **No template found:** If `docs/CONVENTIONS.template.md` doesn't exist during a fresh scaffold, fall back to the structure used in step 2 (Naming, Architecture, Error handling, Testing, Frontend, Other) rather than inventing a format.
- **Conventions file already exists but is empty:** Treat an empty file the same as a missing template — run a fresh scaffold, not an update.
