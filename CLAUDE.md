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

### When both tech-lead and devils-advocate are warranted:
Run tech-lead first to decompose the task into a plan. Then run devils-advocate
to challenge that plan. Only after devils-advocate completes should api-designer
(if needed) and engineer agents be invoked.

### Parallel dispatch (run simultaneously):
- Tasks with no shared files and no output dependencies
- Independent reviews of separate files or modules
- Example: csharp-engineer and frontend-engineer on separate layers

### Sequential dispatch (run in order):
- Any task where agent B depends on output from agent A
- Any two tasks that modify the same file
- Always: frontend-engineer -> ts-linter -> code-reviewer -> (if applicable) security-reviewer
- Always: mcp-engineer -> ts-linter -> code-reviewer -> (if applicable) security-reviewer
- Always: csharp-engineer -> code-reviewer -> (if applicable) security-reviewer

## Always invoke before implementation:
- **git-engineer** before any engineer agent when the task involves code
  changes and the working branch has not already been confirmed:
  - If on `main` or `master`: ask whether to pull latest and create a new branch
  - If on any other branch: confirm with the user that it is the correct branch
    for this work before proceeding
- **api-designer** before csharp-engineer or frontend-engineer when the task
  creates or significantly modifies API endpoints

## Always invoke after implementation:
- **ts-linter** immediately after frontend-engineer or mcp-engineer, before code-reviewer.
  Pass the list of modified `.ts` files. Block on FAIL -- route
  back to the originating engineer before proceeding.
  If both frontend-engineer and mcp-engineer ran in parallel, invoke ts-linter
  once after both complete, passing all modified `.ts` and `.vue` files together.
- **code-reviewer** after any output from csharp-engineer, frontend-engineer, or mcp-engineer
- **security-reviewer** when changes touch authentication, authorization,
  data access, PII handling, API endpoints, or configuration with secrets
- **performance-reviewer** when changes include database queries, API endpoints,
  loops over collections, or caching logic
- **smell-reviewer** after every code change that introduces or modifies classes,
  methods, or files. Skip for documentation-only, config-only, or SQL-migration-only
  changes with no application logic.
- Run security-reviewer, performance-reviewer, and smell-reviewer in parallel
  after code-reviewer completes -- they are independent of each other. Omit
  security-reviewer and performance-reviewer when their trigger conditions are
  not met; smell-reviewer always runs on code changes.
- **test-engineer** after any new public methods or API endpoints are created, or
  when existing methods are modified -- engineer agents must verify test coverage
  and assess test impact (which existing tests are affected) before handoff
- **merge-reviewer** as the final gate in the implement pipeline, after
  test-engineer completes. Verifies all required stages passed and commits
  to the feature branch if clean. Never merges to main.

## Engineer responsibilities (csharp-engineer, frontend-engineer, mcp-engineer, database-engineer)
Before handing off to code-reviewer, every engineer agent must:
1. **Verify unit test coverage** — identify which changed methods/functions lack
   adequate test coverage and flag gaps explicitly in the handoff summary.
2. **Run existing tests** — execute the existing test suite (or the relevant subset
   that covers the changed code) and confirm all tests pass. If any tests fail,
   fix them before handing off. Do not proceed to code-reviewer with failing tests.
3. **Do not skip this step** even for small changes -- a one-line fix can break
   multiple tests or leave a coverage gap.

## Never invoke automatically:
- **devils-advocate** on small bug fixes or trivial changes
- **tech-lead** when the task is already well-defined and scoped
- **test-engineer** before implementation is complete, reviewed, and test impact assessed
- **git-engineer** when the task involves no file changes (read-only tasks,
  reviews, planning)
- **api-designer** for internal refactors that do not change the API surface
- **performance-reviewer** when no database queries, endpoints, or hot-path
  code is involved
- **smell-reviewer** for documentation-only, config-only, or SQL-migration-only
  changes with no application logic
- **merge-reviewer** before the full pipeline (engineer → code-reviewer →
  test-engineer) has completed

## Built-in agent disambiguation

Claude Code ships two built-in agent types that overlap with pack agents. When both
are available, always prefer the pack agent -- it carries the full pack conventions
and memory integration that the built-in lacks.

| Built-in agent | Pack equivalent | Notes |
|---|---|---|
| `branch-manager` | `git-engineer` | git-engineer handles all three modes: branch setup, commit, and push/PR |
| `typescript-engineer` | `frontend-engineer` | frontend-engineer also covers Vue 3, Pinia, React, and other frameworks |
| `claude-code-guide` | N/A — use built-in directly | Use the built-in for Claude Code feature questions (how /X works, hooks, MCP, API). Do not answer inline with Opus — that wastes planning tokens. |

Never route to `branch-manager` or `typescript-engineer` directly -- use the pack agents.

## Worktree policy
See `skills/implement/SKILL.md` for the full worktree branching and isolation rules.

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

- **`memory/decisions/`** — Architectural and design decisions with rationale.
- **`memory/architecture/`** — Module boundaries, data flow, and integration patterns.
- **`memory/context/`** — Environmental constraints, platform quirks, and tooling workarounds.
- **`memory/known-issues/`** — Bugs, limitations, and workarounds that remain unresolved.

### Precedence rules

- Active files without `Overrides-convention: yes` rank below CONVENTIONS.md and above agent defaults.
- Active files with `Overrides-convention: yes` rank above CONVENTIONS.md, but only within their declared Scope.
- Narrower scope wins over broader scope when two files conflict.
- When two active files conflict at the same scope, flag the conflict -- do not pick one silently.
