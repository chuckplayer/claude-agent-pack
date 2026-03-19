# Claude Code Agent Pack

Fourteen specialized Claude Code subagents for enterprise C# and TypeScript development teams.

## Why

Claude Code works best on large, complex tasks when it can delegate to focused specialists rather than context-switching across domains in a single session. This pack provides fourteen agents that Claude Code orchestrates automatically -- routing to the right specialist based on what the task requires, running parallel agents when there are no dependencies, and sequencing reviews after implementation.

Without orchestration, a single session planning an architecture change, writing C# services, reviewing them, and writing tests quickly loses coherence. With the pack, each agent is narrow enough to be consistently good at its job.



## Agents

| Agent | Role | When invoked |
|---|---|---|
| tech-lead | Decomposes complex tasks and orchestrates specialist agents | Ambiguous or multi-step tasks spanning multiple files or layers |
| devils-advocate | Pressure-tests reasoning before implementation begins | New patterns, architectural decisions, irreversible changes |
| api-designer | Designs REST contracts before implementation begins | Creating or significantly modifying API endpoints |
| git-engineer | Git lifecycle specialist: branch setup, conventional commits, push, and PR | Before any engineer agent; after merge-reviewer for push/PR |
| csharp-engineer | C# and .NET implementation | Writing or modifying .cs files |
| frontend-engineer | TypeScript and Vue 3 frontend implementation | Writing or modifying .ts or .vue files |
| mcp-engineer | MCP server implementation: tools, resources, prompts, Zod schemas | Building or modifying MCP servers |
| ts-linter | Type checking (tsc) and ESLint on changed TS/Vue files | After frontend-engineer or mcp-engineer, before code-reviewer |
| database-engineer | Schema changes, EF Core migrations, and SQL | Any task requiring schema changes or migrations |
| code-reviewer | Code quality, readability, and convention compliance | After any engineer agent output |
| security-reviewer | Security-focused review only | Changes touching auth, data access, PII, or secrets |
| performance-reviewer | Performance-focused review only | Changes with database queries, endpoints, or hot-path code |
| test-engineer | Test generation matching established project patterns | After code-reviewer has completed its review |
| merge-reviewer | Final pipeline gate -- verifies all stages passed and commits to the feature branch | After test-engineer completes; never merges to main |

## Installation

Clone the repo anywhere, then run the installer:

```bash
git clone https://github.com/chuckplayer/claude-agent-pack.git
bash ./claude-agent-pack/install.sh
```

After the installer runs, scaffold each project using the setup script. Replace `<pack-dir>` with the path to your clone and `<project>` with your project root:

```bash
bash <pack-dir>/scripts/setup-project.sh <project>
```

This copies `CLAUDE.md`, `docs/CONVENTIONS.md` (from the template), `docs/MEMORY-WRITING.md`, and the `memory/` scaffold into the project. Then fill in `docs/CONVENTIONS.md` with your project's standards and commit the result.

## Skills

Thirteen slash-command entry points are included. Invoke them directly in Claude Code without knowing the agent sequence:

| Skill | What it does |
|---|---|
| `/implement` | Runs the full pipeline: git-engineer → [tech-lead] → engineer(s) → ts-linter → code-reviewer → [security-reviewer] → [performance-reviewer] → test-engineer → merge-reviewer → git-engineer (push/PR). Engineers run in isolated worktrees. |
| `/scaffold` | End-to-end feature scaffolding: api-designer → database-engineer → backend engineer → frontend-engineer, in dependency order. Use when building something new across all layers. |
| `/hotfix` | Abbreviated pipeline for production incidents. No worktree isolation, 1 retry max. Still requires code-reviewer and merge-reviewer. |
| `/refactor` | Refactor with impact analysis first: tech-lead → engineer(s) → mandatory test verification → code-reviewer. Enforces a no-behavior-delta constraint. |
| `/debug` | Diagnose and fix a failing test or error. Reads the stack trace, forms a hypothesis, routes to the right engineer, then runs a lightweight code-reviewer pass. |
| `/review-pr` | Runs code-reviewer, security-reviewer, and performance-reviewer against a PR or diff. Produces a consolidated findings report. |
| `/plan` | Decompose a task with tech-lead and optionally pressure-test the plan with devils-advocate before implementation begins. |
| `/onboard` | Reads the codebase, memory, and conventions to produce a structured orientation: architecture, entry points, data flow, and known gotchas. |
| `/conventions` | Scaffolds or updates `docs/CONVENTIONS.md` by reading actual code patterns and interviewing the user. |
| `/memory-audit` | Reviews all active memory files for staleness, archives stale entries, and checks for unrecorded decisions. |
| `/setup-project` | Scaffolds a project with `CLAUDE.md`, `docs/CONVENTIONS.md`, `docs/MEMORY-WRITING.md`, and the `memory/` structure, then guides through next steps |
| `/skill-writer` | Scaffolds a new skill for the pack: interviews the user, writes `skills/<name>/SKILL.md`, updates the README, and validates with `/lint-agents` |
| `/system-check` | Runs both readiness and update checks in one pass: verifies installation, project scaffolding, and whether agents/skills are current. |

## Scripts

Three utility scripts are included in `scripts/`.

| Script | What it does |
|---|---|
| `setup-project` | Copies `CLAUDE.md`, `docs/CONVENTIONS.md`, `docs/MEMORY-WRITING.md`, and the `memory/` scaffold into a project directory |
| `check-readiness` | Verifies Claude Code is installed, all agents and skills are installed, and the target project has full scaffolding |
| `check-updates` | Diffs installed agents and skills against the pack source; flags anything outdated |

```bash
bash scripts/setup-project.sh <project>
bash scripts/check-readiness.sh <project>
bash scripts/check-updates.sh
```

## Quick Start

Use skills as entry points:

```
/agent-plan add a payment processing feature
/implement add a GetByExternalId method to OrderRepository
/scaffold add a notifications feature with API, DB, backend, and frontend
/review-pr 42
/debug the OrderService.GetById test is failing with a null reference exception
/hotfix fix the null check in PaymentController.ProcessRefund
/refactor extract the retry logic in HttpClientWrapper into a separate class
/onboard
/conventions
/challenge we're considering migrating from REST to GraphQL
/memory-audit
/setup-project
/check-readiness
/check-updates
```

Or invoke agents directly in natural language:

1. "Use the tech-lead agent to plan adding a payment processing feature."
2. "Use the csharp-engineer to add a `GetByExternalId` method to `OrderRepository`."
3. "Use the code-reviewer to review the changes in `OrderService.cs`."
4. "Use the test-engineer to write xUnit tests for the new `OrderService.GetById` method."

## Workflow

```
task -> git-engineer -> [tech-lead] -> [devils-advocate] -> [api-designer] -> engineer(s) -> [ts-linter] -> code-reviewer -> [security-reviewer] -> [performance-reviewer] -> test-engineer -> merge-reviewer -> git-engineer (push/PR)
```

Bracketed agents are conditional. For well-defined tasks, invoke the specialist directly and skip orchestration. `git-engineer` is skipped for read-only tasks. `ts-linter` runs only when TypeScript or Vue files were modified. `database-engineer` runs in parallel with engineer agents when schema changes are needed. When invoked through `/implement`, engineer agents run in isolated git worktrees and merge-reviewer commits the result to the feature branch if all gates pass.

## Memory

The `memory/` directory gives agents a lightweight persistence layer. Decisions, architectural context, and known issues are stored as Markdown files that survive between sessions.

Memory is committed to version control so the full team shares accumulated context. When the tech-lead records an architectural decision, every future agent session in that codebase picks it up automatically.

**Who writes:** tech-lead (for decisions) and devils-advocate (for challenge sessions). All other agents are read-only.

**File naming:** `YYYY-MM-DD-[decision|challenge]-brief-slug.md` in the appropriate subdirectory.

**Agents skip** files with `status: superseded` or `status: archived` automatically.

See `docs/AGENT-GUIDE.md` for the full memory format, hygiene guidance, and scaling notes.

## Customization

Fill in `docs/CONVENTIONS.md` with your project's naming conventions, architectural rules, error handling strategy, logging standards, and compliance requirements. All agents read this file before acting. Team standards override agent defaults automatically -- no changes to agent files required.

## Project-Level Overrides

Place an agent file in `.claude/agents/` in the project root to override the global version for that project. The filename must match the global agent (e.g., `csharp-engineer.md`). The project-level version takes full precedence for sessions in that project.

## Updating

To check whether your installed agents and skills are current before pulling:

```bash
bash scripts/check-updates.sh
```

To pull and reinstall:

```bash
# from your clone directory
git pull
bash install.sh
```

Agents are updated in-place. Re-running the installer is safe -- it is idempotent.

## Uninstalling

```bash
bash <pack-dir>/uninstall.sh
```

The uninstaller removes agents from `~/.claude/agents/` after confirmation. Project-level `memory/` directories are not touched.

## Agent Dashboard

[claude-agent-dashboard](https://github.com/chuckplayer/claude-agent-dashboard) is a companion local web UI for monitoring Claude Code sessions in real time.

- **Live session feed** — agent Gantt timeline and scrolling event log, updated within 1 second of any Claude Code hook event
- **Memory browser** — browse and search `memory/*.md` files across all projects; renders full markdown on click
- **Session history** — SQLite-backed log of past sessions with duration, prompt counts, and agent invocation counts

The dashboard works with any Claude Code installation. The agent pack is optional — if both are installed, the memory browser surfaces the architectural decisions and challenge records that tech-lead and devils-advocate write during sessions.

Requires Node.js 22+ (uses the built-in `node:sqlite` module). Nothing leaves your machine — the server binds to `127.0.0.1` only.

## License

MIT. See LICENSE.
