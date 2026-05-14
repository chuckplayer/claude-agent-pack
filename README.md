# Claude Code Agent Pack

Twenty-one specialized Claude Code subagents for enterprise software development teams, plus a personal LLM wiki skill family, an Obsidian vault integration, and persistent knowledge management.

## Why

Claude Code works best on large, complex tasks when it can delegate to focused specialists rather than context-switching across domains in a single session. This pack provides twenty-one agents that Claude Code orchestrates automatically -- routing to the right specialist based on what the task requires, running parallel agents when there are no dependencies, and sequencing reviews after implementation.

Without orchestration, a single session planning an architecture change, writing C# services, reviewing them, and writing tests quickly loses coherence. With the pack, each agent is narrow enough to be consistently good at its job, and session context is automatically logged to an Obsidian vault on Stop.



## Agents

| Agent | Role | When invoked |
|---|---|---|
| tech-lead | Decomposes complex tasks and orchestrates specialist agents | Ambiguous or multi-step tasks spanning multiple files or layers |
| devils-advocate | Pressure-tests reasoning before implementation begins | New patterns, architectural decisions, irreversible changes |
| api-designer | Designs REST contracts before implementation begins | Creating or significantly modifying API endpoints |
| git-engineer | Git lifecycle specialist: branch setup, conventional commits, push, and PR | Before any engineer agent; after merge-reviewer for push/PR |
| csharp-engineer | C# and .NET implementation | Writing or modifying .cs files |
| python-engineer | Python implementation: FastAPI, Django, Flask, and plain Python | Writing or modifying .py files |
| frontend-engineer | TypeScript and Vue 3 frontend implementation | Writing or modifying .ts or .vue files |
| mcp-engineer | MCP server implementation: tools, resources, prompts, Zod schemas | Building or modifying MCP servers |
| infrastructure-engineer | Infrastructure-as-code: Terraform, Docker, GitHub Actions, Kubernetes | Writing or modifying .tf, Dockerfiles, .yml in .github/, and K8s manifests |
| ts-linter | Type checking (tsc) and ESLint on changed TS/Vue files | After frontend-engineer or mcp-engineer, before code-reviewer |
| database-engineer | Schema changes, EF Core migrations, and SQL | Any task requiring schema changes or migrations |
| code-reviewer | Code quality, readability, and convention compliance | After any engineer agent output |
| security-reviewer | Security-focused review only | Changes touching auth, data access, PII, or secrets |
| performance-reviewer | Performance-focused review only | Changes with database queries, endpoints, or hot-path code |
| smell-reviewer | Structural anti-pattern detection: God classes, long methods, dead code, feature envy, comment smells (TODO/HACK/FIXME/XXX). Offers to record accepted patterns as suppressions in CONVENTIONS.md | After code-reviewer on every code change; parallel with security-reviewer and performance-reviewer |
| test-engineer | Test generation matching established project patterns | After code-reviewer has completed its review |
| merge-reviewer | Final pipeline gate -- verifies all stages passed and commits to the feature branch | After test-engineer completes; never merges to main |
| wiki-ingestor | Reads a source from `raw/`, creates or updates `wiki/` pages, updates `index.md` | Dispatched by `/wiki-ingest`; never modifies `raw/` |
| wiki-librarian | Answers queries against the wiki with citations; can file synthesis pages back | Dispatched by `/wiki-query`; read-only except for filed-back synthesis pages |
| wiki-linter | Health checks the wiki for orphans, broken links, missing frontmatter, and schema violations | Dispatched by `/wiki-lint`; strictly read-only |
| obsidian-writer | Writes session logs and capture notes to the vault; skips the main file if the calling skill already wrote it via REST API and only appends the daily note | Dispatched by Obsidian skills; never writes outside allowed vault directories |

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

Twenty-six slash-command entry points are included. Invoke them directly in Claude Code without knowing the agent sequence:

| Skill | What it does |
|---|---|
| `/implement` | Runs the full pipeline: git-engineer → [tech-lead] → engineer(s) → ts-linter → code-reviewer → [security-reviewer] → [performance-reviewer] → smell-reviewer → test-engineer → merge-reviewer → git-engineer (push/PR). Engineers run in isolated worktrees. |
| `/scaffold` | End-to-end feature scaffolding: api-designer → database-engineer → backend engineer → frontend-engineer, in dependency order. Use when building something new across all layers. |
| `/hotfix` | Abbreviated pipeline for production incidents. No worktree isolation, 1 retry max. Still requires code-reviewer and merge-reviewer. |
| `/refactor` | Refactor with impact analysis first: tech-lead → engineer(s) → mandatory test verification → code-reviewer. Enforces a no-behavior-delta constraint. |
| `/debug` | Diagnose and fix a failing test or error. Reads the stack trace, forms a hypothesis, routes to the right engineer, then runs a lightweight code-reviewer pass. |
| `/review-pr` | Runs code-reviewer, security-reviewer, performance-reviewer, and smell-reviewer against a PR or diff. Produces a consolidated findings report. |
| `/smell` | Run smell-reviewer against a file, directory, or working-tree changes. Detects structural anti-patterns and comment smells; offers to record accepted patterns in CONVENTIONS.md. |
| `/plan` | Decompose a task with tech-lead and optionally pressure-test the plan with devils-advocate before implementation begins. |
| `/onboard` | Reads the codebase, memory, and conventions to produce a structured orientation: architecture, entry points, data flow, and known gotchas. |
| `/conventions` | Scaffolds or updates `docs/CONVENTIONS.md` by reading actual code patterns and interviewing the user. |
| `/memory-audit` | Reviews all active memory files for staleness, archives stale entries, and checks for unrecorded decisions. |
| `/memory-query` | Searches project memory for a specific topic, decision, or constraint and returns matching entries with citations. |
| `/lint-agents` | Validates all agent and skill files for required frontmatter fields and body content; interprets failures with specific fix instructions. |
| `/setup-project` | Scaffolds a project with `CLAUDE.md`, `docs/CONVENTIONS.md`, `docs/MEMORY-WRITING.md`, and the `memory/` structure, then guides through next steps |
| `/skill-writer` | Scaffolds a new skill for the pack: interviews the user, writes `skills/<name>/SKILL.md`, updates the README, and validates with `/lint-agents` |
| `/system-check` | Runs both readiness and update checks in one pass: verifies installation, project scaffolding, and whether agents/skills are current. |
| `/wiki` | Help and discovery entry point for the wiki skill family — routes to the correct wiki skill based on intent. |
| `/wiki-init` | Bootstraps a new wiki vault for a knowledge domain (`vacation`, `research`, etc.) with directory structure, domain schema, and git history. |
| `/wiki-ingest` | Reads a source and integrates its knowledge into the wiki — creating/updating pages, refreshing the index, and logging the operation. |
| `/wiki-query` | Asks a question against the wiki; synthesizes an answer with citations and offers to file valuable answers back as synthesis pages. |
| `/wiki-lint` | Health-checks the wiki for orphaned pages, broken wikilinks, missing frontmatter, stale dates, and schema violations. |
| `/obsidian` | Help and routing entry point for the Obsidian skill family — dispatches to the right skill based on intent. |
| `/obsidian-log` | Logs the current session to the Obsidian vault: git branch, recent commits, and uncommitted changes. |
| `/obsidian-capture` | Saves a user-supplied title and body as a timestamped capture note in `Claude/captures/`. |
| `/obsidian-daily` | Reads and displays today's project daily note (path depends on `OBSIDIAN_PROJECTS_FOLDER`). |
| `/obsidian-search` | Full-text search across Claude notes in the vault, scoped to the current project by default; pass `--global` to search all projects. Opens the best match in Obsidian if the REST API is available. |

## Obsidian Vault Integration

The installer optionally connects Claude Code to an [Obsidian](https://obsidian.md) vault. When enabled, every session is automatically logged to your vault when Claude Code stops.

**What gets written per session:**

- `<base>/sessions/YYYY-MM-DD-HHmm-<project>.md` — git branch, last 5 commits, diff stat, and uncommitted changes
- `<base>/daily/YYYY-MM-DD.md` — one-line entry linking to the session note
- `<base>/memory-snapshot.md` — freeze of `./memory/**/*.md` (recursive) for vault-side search

Where `<base>` is determined by two env vars set during install:

| Env var | Description |
|---|---|
| `OBSIDIAN_VAULT_PATH` | Absolute path to your vault (required) |
| `OBSIDIAN_PROJECTS_FOLDER` | Folder inside the vault for project logs (defaults to `Claude/Projects` if blank) |
| `OBSIDIAN_REST_API_KEY` | API key for the [Obsidian Local REST API](https://github.com/coddingtonbear/obsidian-local-rest-api) plugin (optional). When set, writes go through the REST API first with filesystem fallback. When absent, writes go directly to the filesystem. |
| `OBSIDIAN_REST_API_PORT` | REST API port (default `27124` when key is set) |
| `OBSIDIAN_REST_API_HTTPS` | `true`/`false` — whether the REST API uses HTTPS (default `true`) |

With `OBSIDIAN_PROJECTS_FOLDER=Projects` and project `agent-pack`:
`<vault>/Projects/agent-pack/sessions/`, `<vault>/Projects/agent-pack/daily/`

Default (`OBSIDIAN_PROJECTS_FOLDER=Claude/Projects` when blank):
`<vault>/Claude/Projects/agent-pack/sessions/`, `<vault>/Claude/Projects/agent-pack/daily/`

**Setup:** the installer prompts for your vault path, an optional projects folder, and an optional REST API key. If the key is provided, writes go through the Obsidian Local REST API first (filesystem fallback on any failure). Without a key, writes go directly to the filesystem — Obsidian's file watcher picks them up within seconds either way.

**Manual skills:** use `/obsidian-log`, `/obsidian-capture`, `/obsidian-daily`, and `/obsidian-search` at any time regardless of the auto-log hook.

## Scripts

Five utility scripts are included in `scripts/`.

| Script | What it does |
|---|---|
| `setup-project` | Copies `CLAUDE.md`, `docs/CONVENTIONS.md`, `docs/MEMORY-WRITING.md`, and the `memory/` scaffold into a project directory |
| `check-readiness` | Verifies Claude Code is installed, all agents and skills are installed, and the target project has full scaffolding |
| `check-updates` | Diffs installed agents and skills against the pack source; flags anything outdated |
| `lint-agents` | Validates all agent and skill files for required frontmatter fields, description length, and body content |
| `obsidian-stop-hook` | Auto-log hook (`.js`, pure Node.js) — installed to `~/.claude/scripts/` by the installer; fires on Claude Code Stop |

```bash
bash scripts/setup-project.sh <project>
bash scripts/check-readiness.sh <project>
bash scripts/check-updates.sh
bash scripts/lint-agents.sh
```

## Quick Start

Use skills as entry points:

```
/plan add a payment processing feature
/implement add a GetByExternalId method to OrderRepository
/scaffold add a notifications feature with API, DB, backend, and frontend
/review-pr 42
/debug the OrderService.GetById test is failing with a null reference exception
/hotfix fix the null check in PaymentController.ProcessRefund
/refactor extract the retry logic in HttpClientWrapper into a separate class
/onboard
/conventions
/memory-audit
/setup-project
/system-check
/obsidian-log
/obsidian-capture my design decision: keep auth in middleware, not controllers
/smell
/smell src/services/OrderService.cs
```

Or invoke agents directly in natural language:

1. "Use the tech-lead agent to plan adding a payment processing feature."
2. "Use the csharp-engineer to add a `GetByExternalId` method to `OrderRepository`."
3. "Use the code-reviewer to review the changes in `OrderService.cs`."
4. "Use the test-engineer to write xUnit tests for the new `OrderService.GetById` method."

## Workflow

```
task -> git-engineer -> [tech-lead] -> [devils-advocate] -> [api-designer] -> engineer(s) -> [ts-linter] -> code-reviewer -> [security-reviewer] -> [performance-reviewer] -> smell-reviewer -> test-engineer -> merge-reviewer -> git-engineer (push/PR)
```

Bracketed agents are conditional. For well-defined tasks, invoke the specialist directly and skip orchestration. `git-engineer` is skipped for read-only tasks. `ts-linter` runs only when TypeScript or Vue files were modified. `database-engineer` runs in parallel with engineer agents when schema changes are needed. `security-reviewer` and `performance-reviewer` run when their trigger conditions are met. `smell-reviewer` always runs on code changes and runs in parallel with security-reviewer and performance-reviewer. When invoked through `/implement`, engineer agents run in isolated git worktrees and merge-reviewer commits the result to the feature branch if all gates pass.

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

The uninstaller removes agents from `~/.claude/agents/`, skills from `~/.claude/skills/`, the Obsidian stop hook from `~/.claude/scripts/`, and the Obsidian env vars (`OBSIDIAN_VAULT_PATH`, `OBSIDIAN_PROJECTS_FOLDER`) from `~/.claude/settings.json` — all after confirmation. It also detects `~/.claude/wiki/` and prompts whether to remove wiki vaults. Project-level `memory/` directories are not touched.

## Agent Dashboard

[claude-agent-dashboard](https://github.com/chuckplayer/claude-agent-dashboard) is a companion local web UI for monitoring Claude Code sessions in real time.

- **Live session feed** — agent Gantt timeline and scrolling event log, updated within 1 second of any Claude Code hook event
- **Memory browser** — browse and search `memory/*.md` files across all projects; renders full markdown on click
- **Session history** — SQLite-backed log of past sessions with duration, prompt counts, and agent invocation counts

The dashboard works with any Claude Code installation. The agent pack is optional — if both are installed, the memory browser surfaces the architectural decisions and challenge records that tech-lead and devils-advocate write during sessions.

Requires Node.js 22+ (uses the built-in `node:sqlite` module). Nothing leaves your machine — the server binds to `127.0.0.1` only.

## License

MIT. See LICENSE.
