# Claude Code Agent Pack

Eight specialized Claude Code subagents for enterprise C# and TypeScript development teams.

## Why

Claude Code works best on large, complex tasks when it can delegate to focused specialists rather than context-switching across domains in a single session. This pack provides eight agents that Claude Code orchestrates automatically -- routing to the right specialist based on what the task requires, running parallel agents when there are no dependencies, and sequencing reviews after implementation.

Without orchestration, a single session planning an architecture change, writing C# services, reviewing them, and writing tests quickly loses coherence. With the pack, each agent is narrow enough to be consistently good at its job.

## Agents

| Agent | Role | When invoked |
|---|---|---|
| tech-lead | Decomposes complex tasks and orchestrates specialist agents | Ambiguous or multi-step tasks spanning multiple files or layers |
| devils-advocate | Pressure-tests reasoning before implementation begins | New patterns, architectural decisions, irreversible changes |
| branch-manager | Ensures work happens on the correct git branch | Before any engineer agent when the working branch has not been confirmed |
| csharp-engineer | C# and .NET implementation | Writing or modifying .cs files |
| typescript-engineer | TypeScript and Vue 3 frontend implementation | Writing or modifying .ts or .vue files |
| code-reviewer | Code quality, readability, and convention compliance | After any engineer agent output |
| security-reviewer | Security-focused review only | Changes touching auth, data access, PII, or secrets |
| test-engineer | Test generation matching established project patterns | After implementation is complete and reviewed |

## Installation

Clone the repo anywhere, then run the installer:

```powershell
# Windows (PowerShell)
git clone https://github.com/chuckplayer/claude-agent-pack.git
& ".\claude-agent-pack\install.ps1"
```

```bash
# macOS
git clone https://github.com/chuckplayer/claude-agent-pack.git
bash ./claude-agent-pack/install.sh
```

After the installer runs, complete setup in each project. Replace `<pack-dir>` with the path to your clone:

```powershell
# Windows -- run from your project root
Copy-Item "<pack-dir>\CLAUDE.md" ".\CLAUDE.md"
New-Item -ItemType Directory -Force -Path ".\docs" | Out-Null
Copy-Item "<pack-dir>\docs\CONVENTIONS.template.md" ".\docs\CONVENTIONS.md"
Copy-Item -Recurse -Force "<pack-dir>\memory" "."
```

```bash
# macOS -- run from your project root
cp <pack-dir>/CLAUDE.md ./CLAUDE.md
mkdir -p ./docs
cp <pack-dir>/docs/CONVENTIONS.template.md ./docs/CONVENTIONS.md
cp -r <pack-dir>/memory .
```

Fill in `docs/CONVENTIONS.md` with your project's standards. Commit the `memory/` scaffold.

## Quick Start

Invoke agents in natural language inside Claude Code:

1. "Use the tech-lead agent to plan adding a payment processing feature."
2. "Use the csharp-engineer to add a `GetByExternalId` method to `OrderRepository`."
3. "Use the code-reviewer to review the changes in `OrderService.cs`."
4. "Use the test-engineer to write xUnit tests for the new `OrderService.GetById` method."

## Workflow

```
task -> [tech-lead] -> [devils-advocate] -> branch-manager -> engineer -> code-reviewer -> [security-reviewer] -> test-engineer
```

Bracketed agents are conditional. For well-defined tasks, invoke the specialist directly and skip orchestration. `branch-manager` is skipped for read-only tasks (reviews, planning).

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

```powershell
# Windows (PowerShell) -- from your clone directory
cd <pack-dir>
git pull
& ".\install.ps1"
```

```bash
# macOS -- from your clone directory
cd <pack-dir>
git pull
bash install.sh
```

Agents are updated in-place. Re-running the installer is safe -- it is idempotent.

## Uninstalling

```powershell
# Windows (PowerShell) -- from your clone directory
& "<pack-dir>\uninstall.ps1"
```

```bash
# macOS -- from your clone directory
bash <pack-dir>/uninstall.sh
```

The uninstaller removes agents from `~/.claude/agents/` after confirmation. Project-level `memory/` directories are not touched.

## License

MIT. See LICENSE.
