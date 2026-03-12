# Agent Orchestration Rules

## Sub-Agent Routing

The tech-lead agent routes tasks based on each agent's `description` field --
that description is the routing contract. To make a custom agent routable,
write a clear, specific description that unambiguously states when it should
be invoked. The tech-lead will route to it automatically.

### Invoke devils-advocate BEFORE implementation when:
- The task introduces a pattern not already present in the codebase
- The change affects more than two architectural layers
- The decision is difficult or impossible to reverse
- A new technology, library, or integration is being added

### Invoke tech-lead BEFORE implementation when:
- The task is ambiguous or spans multiple concerns
- You are unsure which agents to invoke or in what order
- The work touches more than three files across different layers

### Parallel dispatch (run simultaneously):
- Tasks with no shared files and no output dependencies
- Independent reviews of separate files or modules
- Example: csharp-engineer and typescript-engineer on separate layers

### Sequential dispatch (run in order):
- Any task where agent B depends on output from agent A
- Any two tasks that modify the same file
- Always: typescript-engineer -> ts-linter -> code-reviewer -> (if applicable) security-reviewer
- Always: csharp-engineer -> code-reviewer -> (if applicable) security-reviewer

## Always invoke before implementation:
- **branch-manager** before any engineer agent when the task involves code
  changes and the working branch has not already been confirmed:
  - If on `main` or `master`: ask whether to pull latest and create a new branch
  - If on any other branch: confirm with the user that it is the correct branch
    for this work before proceeding
- **api-designer** before csharp-engineer or typescript-engineer when the task
  creates or significantly modifies API endpoints

## Always invoke after implementation:
- **ts-linter** immediately after typescript-engineer, before code-reviewer.
  Pass the list of modified `.ts` and `.vue` files. Block on FAIL -- route
  back to typescript-engineer before proceeding.
- **code-reviewer** after any output from csharp-engineer or typescript-engineer
- **security-reviewer** when changes touch authentication, authorization,
  data access, PII handling, API endpoints, or configuration with secrets
- **performance-reviewer** when changes include database queries, API endpoints,
  loops over collections, or caching logic
- **test-engineer** after any new public methods or API endpoints are created
- **merge-reviewer** as the final gate in the implement pipeline, after
  test-engineer completes. Verifies all required stages passed and commits
  to the feature branch if clean. Never merges to main.

## Never invoke automatically:
- **devils-advocate** on small bug fixes or trivial changes
- **tech-lead** when the task is already well-defined and scoped
- **test-engineer** before implementation is complete and reviewed
- **branch-manager** when the task involves no file changes (read-only tasks,
  reviews, planning)
- **api-designer** for internal refactors that do not change the API surface
- **performance-reviewer** when no database queries, endpoints, or hot-path
  code is involved
- **merge-reviewer** before the full pipeline (engineer → code-reviewer →
  test-engineer) has completed

## Worktree policy
- Engineer agents (csharp-engineer, typescript-engineer, database-engineer)
  run with `isolation: "worktree"` only when invoked through the `implement`
  skill. Direct agent invocations do not use worktree isolation.
- Worktrees are always created from the **current branch** at the time the
  engineer agent is invoked -- never from `main` or `master` directly.
- If the current branch is `main` or `master` when engineer agents are about
  to be dispatched, **stop the pipeline** and prompt the user to switch to a
  feature branch first. Do not create a worktree from `main` or `master`.
- Worktree branches must never be `main` or `master`. branch-manager enforces
  this at the start of every engineer dispatch.
- merge-reviewer commits to the feature branch only. Merging to main is the
  developer's responsibility.

## Conventions
If ./docs/CONVENTIONS.md exists, all agents must read it before acting.
Team standards in that file take precedence over agent defaults.

## Memory
If ./memory/ exists, all agents must check it before acting on any non-trivial task.
Use Glob on memory/**/*.md to discover files. Skip any file with
`status: superseded` or `status: archived` -- these are history only.

The tech-lead and devils-advocate agents write new memory files after significant
decisions. All other agents are read-only with respect to ./memory/.

### Subdirectory taxonomy

Each subdirectory serves a distinct purpose. Writers must place files in the
correct subdirectory based on content type:

- **`memory/decisions/`** — Architectural and design decisions with rationale.
  Write here when: tech-lead dispatches a plan involving a new pattern, or a
  devils-advocate challenge resolves with a clear proceed/reject outcome.
- **`memory/architecture/`** — Structural descriptions of how major subsystems
  work, including module boundaries, data flow, and integration patterns.
  Write here when: a change alters module boundaries, data flow between
  components, or integration patterns with external systems.
- **`memory/context/`** — Environmental constraints, platform quirks, external
  dependency notes, and tooling workarounds.
  Write here when: a constraint is discovered that would surprise a future
  reader (e.g., a library incompatibility, a platform-specific behavior, a
  version requirement).
- **`memory/known-issues/`** — Bugs, limitations, or workarounds that remain
  unresolved.
  Write here when: a workaround is applied, a limitation is accepted, or a
  devils-advocate concern is acknowledged but left unresolved.

### Precedence rules

- Active memory files without `Overrides-convention: yes` take lower precedence
  than CONVENTIONS.md and higher precedence than agent defaults
- Active memory files with `Overrides-convention: yes` take higher precedence
  than CONVENTIONS.md, but only within the Scope they document
- Narrower scope always wins over broader scope when two files conflict
- When two active files conflict at the same scope, flag the conflict -- do not
  pick one silently
