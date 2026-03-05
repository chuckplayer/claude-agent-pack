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
- Always: implementation -> code-reviewer -> (if applicable) security-reviewer

## Always invoke after implementation:
- **code-reviewer** after any output from csharp-engineer or typescript-engineer
- **security-reviewer** when changes touch authentication, authorization,
  data access, PII handling, API endpoints, or configuration with secrets
- **test-engineer** after any new public methods or API endpoints are created

## Never invoke automatically:
- **devils-advocate** on small bug fixes or trivial changes
- **tech-lead** when the task is already well-defined and scoped
- **test-engineer** before implementation is complete and reviewed

## Conventions
If ./docs/CONVENTIONS.md exists, all agents must read it before acting.
Team standards in that file take precedence over agent defaults.

## Memory
If ./memory/ exists, all agents must check it before acting on any non-trivial task.
Use Glob on memory/**/*.md to discover files. Skip any file with
`status: superseded` or `status: archived` -- these are history only.

The tech-lead and devils-advocate agents write new memory files after significant
decisions. All other agents are read-only with respect to ./memory/.

**Precedence rules:**
- Active memory files without `Overrides-convention: yes` take lower precedence
  than CONVENTIONS.md and higher precedence than agent defaults
- Active memory files with `Overrides-convention: yes` take higher precedence
  than CONVENTIONS.md, but only within the Scope they document
- Narrower scope always wins over broader scope when two files conflict
- When two active files conflict at the same scope, flag the conflict -- do not
  pick one silently
