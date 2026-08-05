# Claude Code Agent Pack

Twenty specialized Claude Code subagents for enterprise software development teams, an Obsidian vault integration, and persistent knowledge management.

## Why

Claude Code works best on large, complex tasks when it can delegate to focused specialists rather than context-switching across domains in a single session. This pack provides twenty agents that Claude Code orchestrates automatically -- routing to the right specialist based on what the task requires, running parallel agents when there are no dependencies, and sequencing reviews after implementation.

Without orchestration, a single session planning an architecture change, writing C# services, reviewing them, and writing tests quickly loses coherence. With the pack, each agent is narrow enough to be consistently good at its job, and session context is automatically logged to an Obsidian vault on Stop.

## Agents

| Agent | Role | When invoked |
|---|---|---|
| tech-lead | Decomposes complex tasks and orchestrates specialist agents | Ambiguous or multi-step tasks spanning multiple files or layers |
| devils-advocate | Pressure-tests reasoning before implementation begins | New patterns, architectural decisions, irreversible changes |
| codex-reviewer | Cross-model second opinion via the OpenAI Codex CLI | After devils-advocate, on architectural or irreversible decisions; requires `codex` CLI installed and authenticated |
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
| obsidian-writer | Owns the entire vault write chain -- Obsidian CLI, then Local REST API, then filesystem -- verifying each rung before accepting it, and writes both the main note and the daily note append | Dispatched by Obsidian skills; never writes outside allowed vault directories |
| backlog-auditor | Independent audit of a `/backlog` decomposition tree across seven dimensions -- recomputes coverage from the spec and reports drift, never regenerating it | Dispatched by `/backlog` after the tree is written; never on code changes |

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

## Choosing a flow

The five build flows differ mainly in **ceremony** -- how much planning and review the work must pass before it can be committed. Picking the wrong one is the most common mistake: too much wastes a morning, too little ships an unreviewed change.

| When you are... | Use | Ceremony | Why |
|---|---|---|---|
| Building a feature or change end to end | `/implement` | Full | The complete pipeline: planning, challenge, isolated writers, four review lenses, a commit gate |
| Building something new across every layer | `/scaffold` | Full | Same rigour, fixed order: contract → schema → backend → frontend |
| Restructuring with no behaviour change | `/refactor` | Full | Leads with blast-radius analysis; treats lost test coverage as a blocker |
| Diagnosing something broken | `/debug` | Light | Find the cause first. No isolation, no planning stage |
| Fixing a known production break | `/hotfix` | Light | Deliberately skips planning and structural review. Keeps code review and the commit gate |
| Checking a diff or open PR | `/review-pr` | Review only | Four reviewers in parallel; changes nothing |
| Unsure how to approach it | `/plan` | Planning | Decompose, pressure-test, then optionally a cross-model second opinion |
| Holding a vague idea | `/interview-me` | Planning | Structured questioning until the shape is agreed |
| Holding a requirements document | `/spec-intake` | Planning | Transcribes it into an authoritative spec of record with a field inventory |
| Holding a spec of record and needing a backlog | `/backlog` | Planning | Decomposes it into a feature/story/task tree sized by comparison to reference stories, then audits it |
| Holding a reviewed backlog tree and needing work items | `/devops-azure` | Delivery | Previews the whole tree, takes one confirmation, creates the items with per-item reporting, and writes the ids back into the tree |

Every skill also states what it is *not* for and names the alternative -- `/hotfix` points at `/debug` when the cause is unknown, and `/debug` points back when it is known. That reciprocity is what stops a fast path becoming the default path.

## Skills

Twenty-nine slash-command entry points are included. Invoke them directly in Claude Code without knowing the agent sequence:

| Skill | What it does |
|---|---|
| `/implement` | Runs the full pipeline: git-engineer → [tech-lead] → engineer(s) → ts-linter → code-reviewer → [security-reviewer] → [performance-reviewer] → smell-reviewer → test-engineer → merge-reviewer → git-engineer (push/PR). Engineers run in isolated worktrees. |
| `/interview-me` | Shape a vague idea into an actionable brief through structured one-at-a-time questioning. Terminates when the user signals readiness or all major branches resolve; produces an optional design brief that feeds into `/plan` or `/implement`. |
| `/spec-intake` | Transcribe a requirements source — a file, a directory, or an `/interview-me` brief — into an authoritative spec of record with per-requirement source locators and a field inventory as Appendix A, plus a run manifest recording what the run saw. Conversion is capability-probed and inline; unread parts are reported with a severity the operator must acknowledge before anything is written. |
| `/backlog` | Decompose a spec of record into a feature/story/task tree at `<spec_dir>/<feature>.backlog.md`, then dispatch `backlog-auditor` over it. Reads acceptance bars from plans handed to the run rather than authoring criteria, sizes by relation to reference stories rather than inventing point values, and refuses an implementation story for any requirement the spec leaves open. Creates nothing in any tracker. |
| `/scaffold` | End-to-end feature scaffolding: api-designer → database-engineer → backend engineer → frontend-engineer, in dependency order. Use when building something new across all layers. |
| `/hotfix` | Abbreviated pipeline for production incidents. No worktree isolation, 1 retry max. Still requires code-reviewer and merge-reviewer. |
| `/refactor` | Refactor with impact analysis first: tech-lead → engineer(s) → mandatory test verification → code-reviewer. Enforces a no-behavior-delta constraint. |
| `/debug` | Diagnose and fix a failing test or error. Reads the stack trace, forms a hypothesis, routes to the right engineer, then runs a lightweight code-reviewer pass. |
| `/review-pr` | Runs code-reviewer, security-reviewer, performance-reviewer, and smell-reviewer against a PR or diff. Produces a consolidated findings report. |
| `/smell` | Run smell-reviewer against a file, directory, or working-tree changes. Detects structural anti-patterns and comment smells; offers to record accepted patterns in CONVENTIONS.md. |
| `/plan` | Decompose a task with tech-lead and optionally pressure-test the plan with devils-advocate before implementation begins. |
| `/onboard` | Reads the codebase, memory, and conventions to produce a structured orientation: architecture, entry points, data flow, and known gotchas. Reads the repo map (below) when present instead of re-exploring from scratch. |
| `/repo-map` | Generates, refreshes, or verifies `memory/architecture/repo-map.md` — a durable directory-level map of the codebase (what each directory does and its entry-point files), stamped with the git commit it was verified against. Refreshes re-describe only the directories that changed. |
| `/conventions` | Scaffolds or updates `docs/CONVENTIONS.md` by reading actual code patterns and interviewing the user. |
| `/memory-audit` | Reviews all active memory files for staleness, archives stale entries, and checks for unrecorded decisions. |
| `/memory-query` | Searches project memory for a specific topic, decision, or constraint and returns matching entries with citations. |
| `/lint-agents` | Validates all agent and skill files for required frontmatter fields and body content; interprets failures with specific fix instructions. |
| `/setup-project` | Scaffolds a project with `CLAUDE.md`, `docs/CONVENTIONS.md`, `docs/MEMORY-WRITING.md`, and the `memory/` structure, then guides through next steps |
| `/system-check` | Runs both readiness and update checks in one pass: verifies installation, project scaffolding, and whether agents/skills are current. |
| `/pack-review` | Compares the pack against the current Claude Code release: version-diffs, carries forward open items by their revisit trigger, verifies pack changes against actual diffs, and writes a dated review doc to `docs/`. Asks before committing. Read-only apart from its own review doc. |
| `/obsidian` | Help and routing entry point for the Obsidian skill family — dispatches to the right skill based on intent. |
| `/obsidian-brief` | Synthesizes a context brief from recent session logs and captures for the current project — what was built, decisions made, and open threads. Read-only; run before `/implement` to load project context. |
| `/obsidian-recap` | Synthesizes a narrative **daily recap** from the day's auto-logged session notes, git history, and current-state note, and writes it to the vault. Defaults to today; accepts a `YYYY-MM-DD` argument. |
| `/obsidian-capture` | Saves a user-supplied title and body as a timestamped capture note in `Claude/captures/`. |
| `/obsidian-daily` | Reads and displays today's project daily note (path depends on `OBSIDIAN_PROJECTS_FOLDER`). |
| `/obsidian-search` | Full-text search across Claude notes in the vault, scoped to the current project by default; pass `--global` to search all projects. Opens the best match in Obsidian if the REST API is available. |
| `/devops` | Help and routing entry point for the DevOps skill family — dispatches to `/devops-github` or `/devops-azure` based on intent. |
| `/devops-github` | Read and create GitHub PRs/issues via the `gh` CLI for repos configured in `GITHUB_ORG`/`GITHUB_REPOS`. Strict repo targeting (never guesses); write operations always preview and require confirmation. |
| `/devops-azure` | Read and create Azure DevOps work items/PRs via the `az` CLI (`devops` extension) for the org/projects configured in `AZURE_DEVOPS_ORG`/`AZURE_DEVOPS_PROJECTS`. Discovers work item type/field schemas at runtime per project; strict targeting and write-operation preview+confirm, same as `/devops-github`. Also provides **batch write mode**, which consumes a reviewed backlog tree from `/backlog` and creates the whole tree as work items in one pass, writing the resulting ids back into the tree. |
| `/what` | Restates the immediately preceding reply in ASD-STE100 Simplified Technical English, keeping the domain's own vocabulary as approved Technical Names. Every fact, qualifier, negation, count, and identifier survives verbatim — a status word such as `NOT RUN` is a Technical Name and is never simplified away. **Not a summariser:** STE output is normally longer than its source. |

## Obsidian Vault Integration

The installer optionally connects Claude Code to an [Obsidian](https://obsidian.md) vault. When enabled, every session is automatically logged to your vault when Claude Code stops.

**What gets written per session:**

- `<base>/sessions/YYYY-MM-DD-HHmm-<project>.md` — git branch, last 5 commits, diff stat, uncommitted changes, what was discussed (every prompt you sent), which agents ran, and any decisions Claude recorded
- `<base>/daily/YYYY-MM-DD.md` — one timestamped line per session linking to the session note, including a compact diff stat (`· 11 files +99 -87`)
- `<base>/_current.md` — a living per-project state note: where work left off, open threads, and the five most recent sessions. Rewritten on every Stop/SessionEnd and read back into context at the start of the next session by the SessionStart hook
- `<base>/decisions/<file>.md` — auto-captured when `memory/decisions/` gains a new or changed file; links into the daily note
- `<base>/memory-snapshot.md` — freeze of `./memory/**/*.md` (recursive) for vault-side search

Skills write two more, on demand rather than per session: `<base>/recaps/YYYY-MM-DD.md` (`/obsidian-recap`) and `<vault>/Claude/captures/YYYY-MM-DD-HHmm.md` (`/obsidian-capture`, which is always project-independent). Separately, a `PostToolUse` hook mirrors Claude Code's own auto-memory files into `<vault>/Claude/Memory/<project-slug>/` the moment they are written.

**How decisions get recorded:** a CLAUDE.md rule instructs Claude to append to `~/.claude/session-decisions-<session-id>.txt` whenever a significant architectural choice is made. The Stop hook reads this file and populates the `## Decisions made` section of the session log, then clears it for the next session.

**How open threads carry across sessions:** a companion rule instructs Claude to append to `~/.claude/session-state-<session-id>.txt`. A plain line records where work stands, `THREAD: <text>` opens an item that persists across sessions, and `DONE: <text>` resolves a previously recorded one. The Stop hook folds all three into `_current.md`, so the next session starts with the open threads already in context.

Where `<base>` is determined by two env vars set during install:

| Env var | Description |
|---|---|
| `OBSIDIAN_VAULT_PATH` | Absolute path to your vault (required) |
| `OBSIDIAN_PROJECTS_FOLDER` | Folder inside the vault for project logs (defaults to `Claude/Projects` if blank) |
| `OBSIDIAN_REST_API_KEY` | API key for the [Obsidian Local REST API](https://github.com/coddingtonbear/obsidian-local-rest-api) plugin (optional). When set, the REST API becomes an available transport rung. When absent, that rung is skipped entirely. |
| `OBSIDIAN_REST_API_PORT` | REST API port (default `27124` when key is set) |
| `OBSIDIAN_REST_API_HTTPS` | `true`/`false` — whether the REST API uses HTTPS (default `true`) |
| `OBSIDIAN_CLI_MODE` | Set by the installer to `rest-api` or `filesystem` depending on whether a REST API key was supplied; records which transports are configured |

With `OBSIDIAN_PROJECTS_FOLDER=Projects` and project `agent-pack`:
`<vault>/Projects/agent-pack/sessions/`, `<vault>/Projects/agent-pack/daily/`

Default (`OBSIDIAN_PROJECTS_FOLDER=Claude/Projects` when blank):
`<vault>/Claude/Projects/agent-pack/sessions/`, `<vault>/Claude/Projects/agent-pack/daily/`

**How writes reach the vault:** there are two write paths, and they use different transports.

- **Skill-driven writes** (`/obsidian-capture`, `/obsidian-recap`) go through the `obsidian-writer` agent, which owns the full chain: **Obsidian CLI → Local REST API → filesystem**, verifying each rung before accepting it and falling through on failure. The CLI rung needs no plugin — the binary ships with the desktop app and is located at runtime, so there is nothing to configure. The CLI returns exit 0 even on failure, so every CLI write is read back before it counts as done. The filesystem rung is unconditional: a vault write never fails because a transport did. Calling skills must not attempt the REST API themselves — that would run ahead of the agent and defeat the CLI-first ordering.
- **Hook-driven writes** (session notes, daily notes, `_current.md`, memory snapshot) are pure Node.js with no agent in the loop, so they use **REST API → filesystem**: the REST API when `OBSIDIAN_REST_API_KEY` is set, the filesystem otherwise.

Obsidian's file watcher picks up filesystem writes within seconds either way.

**Setup:** the installer prompts for your vault path, an optional projects folder, and an optional REST API key, then registers the Stop, SessionEnd, UserPromptSubmit, SubagentStop, SessionStart, and PostToolUse hooks.

**Manual skills:** use `/obsidian-brief`, `/obsidian-recap`, `/obsidian-capture`, `/obsidian-daily`, and `/obsidian-search` at any time regardless of the auto-log hook. Session notes are written automatically by the Stop/SessionEnd hooks; `/obsidian-recap` turns a day's worth of them into a readable narrative.

## DevOps CLI Setup

`/devops-github` and `/devops-azure` shell out to the `gh` and `az` CLIs directly — no MCP server required. Install whichever you need for your platform below, then invoke the skill: it walks through auth and env var setup itself (`GITHUB_ORG`/`GITHUB_REPOS`, `AZURE_DEVOPS_ORG`/`AZURE_DEVOPS_PROJECTS`), and persists your choice via `scripts/set-env.sh` (see [Scripts](#scripts)) rather than a shell profile, so it works the same way on macOS and Windows.

### GitHub CLI (`gh`)

| Platform | Install |
|---|---|
| macOS | `brew install gh` |
| Windows | `winget install --id GitHub.cli` (or `choco install gh`) |

Then authenticate once:

```bash
gh auth login
```

### Azure DevOps CLI (`az` + `devops` extension)

| Platform | Install |
|---|---|
| macOS | `brew install azure-cli` |
| Windows | `winget install --id Microsoft.AzureCLI` (or the MSI at https://aka.ms/installazurecliwindows) |

Then add the `devops` extension and authenticate once:

```bash
az extension add --name azure-devops
az login
```

## Scripts

Ten utility scripts are included in `scripts/`.

| Script | What it does |
|---|---|
| `setup-project` | Copies `CLAUDE.md`, `docs/CONVENTIONS.md`, `docs/MEMORY-WRITING.md`, and the `memory/` scaffold into a project directory |
| `check-readiness` | Verifies Claude Code is installed, all agents and skills are installed, and the target project has full scaffolding |
| `check-updates` | Diffs installed agents and skills against the pack source; flags anything outdated |
| `lint-agents` | Validates all agent and skill files for required frontmatter fields, description length, and body content |
| `set-env` | Writes one or more `KEY=VALUE` pairs into `~/.claude/settings.json`'s `env` object (node-first, python fallback) — used by `/devops-github` and `/devops-azure` to persist config that changes more often than a one-time install, without relying on a shell profile |
| `obsidian-stop-hook` | Auto-log hook (`.js`, pure Node.js) — installed to `~/.claude/scripts/`; fires on Stop and SessionEnd; writes the session note, daily note, `_current.md`, and memory snapshot; tries REST API when `OBSIDIAN_REST_API_KEY` is set, falls back to filesystem |
| `obsidian-prompt-hook` | Prompt capture hook (`.js`, pure Node.js) — installed to `~/.claude/scripts/`; fires on UserPromptSubmit; appends each user prompt to a per-session journal for inclusion in the session log |
| `obsidian-agent-hook` | Agent completion hook (`.js`, pure Node.js) — installed to `~/.claude/scripts/`; fires on SubagentStop; records which agents ran during the session for inclusion in the session log |
| `obsidian-context-hook` | Context injection hook (`.js`, pure Node.js) — installed to `~/.claude/scripts/`; fires on SessionStart; prints the project's `_current.md` to stdout so Claude Code loads where you left off and your open threads into context. Read-only |
| `obsidian-memory-hook` | PostToolUse hook (`.js`, pure Node.js) — installed to `~/.claude/scripts/`; fires on `Write`/`Edit` (matcher-scoped, so it does not run after every tool call); mirrors Claude Code's own auto-memory files (`~/.claude/projects/<project>/memory/*.md`, excluding `MEMORY.md`) into `<vault>/Claude/Memory/<project-slug>/` as they are written. Distinct from the repo `memory/` directory, which the stop hook snapshots on SessionEnd |

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
/obsidian-recap
/obsidian-capture my design decision: keep auth in middleware, not controllers
/smell
/smell src/services/OrderService.cs
/spec-intake docs/source/requirements.docx
/spec-intake docs/source/
/spec-intake docs/claims-intake-brief.md
```

Or invoke agents directly in natural language:

1. "Use the tech-lead agent to plan adding a payment processing feature."
2. "Use the csharp-engineer to add a `GetByExternalId` method to `OrderRepository`."
3. "Use the code-reviewer to review the changes in `OrderService.cs`."
4. "Use the test-engineer to write xUnit tests for the new `OrderService.GetById` method."

## Workflow

```
task -> git-engineer -> [tech-lead] -> [devils-advocate] -> [codex-reviewer] -> [api-designer] -> engineer(s) -> [ts-linter] -> code-reviewer -> [security-reviewer] -> [performance-reviewer] -> smell-reviewer -> test-engineer -> merge-reviewer -> git-engineer (push/PR)
```

Bracketed agents are conditional. For well-defined tasks, invoke the specialist directly and skip orchestration. `git-engineer` is skipped for read-only tasks. `ts-linter` runs only when TypeScript or Vue files were modified. `database-engineer` runs in parallel with engineer agents when schema changes are needed. `security-reviewer` and `performance-reviewer` run when their trigger conditions are met. `smell-reviewer` always runs on code changes and runs in parallel with security-reviewer and performance-reviewer. When invoked through `/implement`, engineer agents run in isolated git worktrees and merge-reviewer commits the result to the feature branch if all gates pass.

### What actually blocks

A reviewer's severity label is not the same as its authority. The two are separated deliberately, so a genuine defect halts the pipeline and a matter of taste does not. **A High finding is not automatically a blocker.**

| | |
|---|---|
| **Blocks** | Type or lint errors (they invalidate the code review that follows) · code-reviewer **Critical** · security **Critical** and **High** · structural **Critical** · missing tests where new public surface was added · merge conflicts or a detached HEAD |
| **Advises** | Performance findings, including High · code-reviewer Warning and Suggestion · conflicts against the base branch · a stale repo map |
| **Skips, on record** | Planning when the task is well scoped · challenge when the pattern is established · contract design when no API moves · security when nothing sensitive is touched · structural review for docs and config only |

Why security High blocks and performance High does not: a security High is an exploitable defect that can cause harm the moment it ships, while a performance High is a cost, and costs are a judgement call belonging to whoever owns the roadmap. Different risk profiles get different authority, and the reasoning lives in the agent file rather than in whoever is on duty.

A failing gate routes **back to whoever produced the problem**, never onward with a warning attached. That single rule is the difference between a pipeline and a checklist.

## Plan Spine

Complex work can carry a **durable plan file** that downstream stages act on and can fail against. Without it a plan lives in chat and dies there: nothing checks it off, and no stage can be blocked by it.

`tech-lead` writes `<plan_dir>/<plan-id>.md` — `plan_dir` comes from the `- **Plan directory:**` key in `docs/CONVENTIONS.md` and defaults to `docs/plans`. Frontmatter binds the plan to one run via `plan_id`, `branch`, and `origin_skill`. The body is a narrative half for the human and a working-memory half for the agents, the latter holding `## Acceptance bars`:

```markdown
## Acceptance bars

- BAR-001: /implement adopts an existing plan instead of writing a second one
  Evidence: manual -> run /plan then /implement on one task, confirm one plan file exists
- BAR-002: OrderService.Cancel rejects an already-cancelled order
  Evidence: tests -> OrderServiceTests.Cancel_AlreadyCancelled_Throws
```

Each bar carries a required `Evidence:` line naming `tests`, `manual`, or `files`, indented **exactly two spaces** — the gate counts and pairs those lines, so the whitespace is a contract. `manual` and `files` are complete answers; work with no test surface is fully satisfied by a concrete file reference or a repeatable command.

**Artifact path keys in `docs/CONVENTIONS.md`.** Three keys steer where generated artifacts land, and all three ship as `[e.g., ...]` placeholders in `docs/CONVENTIONS.template.md`. **An unfilled `[e.g., ...]` value counts as unset** — every reader rejects a value starting with `[` and falls back to its default, because `[` is a legal filename character and an unguarded placeholder would otherwise create a directory named `[e.g., docs`.

| Key | Default | Read by |
|---|---|---|
| `- **Plan directory:**` | `docs/plans` | `tech-lead` when a skill instructs it to write a plan |
| `- **Spec directory:**` | `docs/specs` | `/spec-intake`, for the spec of record and its run manifest |
| `- **Traceability directory:**` | `docs/traceability` | **nothing today.** Reserved for the traceability matrix, which is deferred to the cut that builds the ADO write path. It is seeded and documented so a BA discovers all three knobs at once while editing paths — not because anything reads it yet |

**Who does what**

- **tech-lead** writes the plan and its bars, but only when the invoking skill instructs it — never unconditionally. It guards the resolved plan directory before writing, because its `Write` tool creates parent directories.
- **devils-advocate** pressure-tests the bars in the file, editing in place. It is the only check on bar quality, since tech-lead both writes the bars and is measured by them.
- **Engineers never write the plan file.** They run under worktree isolation and would conflict on the one file every stage depends on.
- **test-engineer** maps evidence to every bar id in its handoff — the only consumer that makes bars load-bearing.
- **merge-reviewer** enforces the bars in gate 4a, an extension of the existing test-coverage gate rather than a new gate.

**Consumption is opt-in per invocation.** A stage acts on a plan only when handed an explicit `plan_id`; nothing ever globs the plan directory. This is a safety property rather than a style preference: five skills dispatch merge-reviewer, so a directory-glob trigger would let an unrelated `/hotfix` run enforce a plan belonging to different work. `/plan` and `/implement` pass a `plan_id`; `/hotfix`, `/debug`, `/scaffold`, and `/refactor` deliberately do not, so they are exempt **by construction** and carry no plan logic at all.

**Plans are committed and never deleted.** The plan lands in the same commit as the implementation so a reviewer can read intended shape against what was built. An accumulating `docs/plans/` is the intended end state, exactly as `memory/decisions/` accumulates.

**Overridden calls are recorded, not retconned.** The plan's `## Calls made for you` section states design decisions made on your behalf. When implementation overrides one, the override belongs in `## Deviations` — silently editing the original call would destroy the only signal that it was overridden.

tech-lead writes `## Deviations` as a self-describing sentinel line and never fills it in; it cannot know deviations at plan time. Engineers cannot read the plan at all (it is uncommitted and invisible inside a worktree), so `/implement` step 5 pastes the relevant calls verbatim into their prompts and requires an explicit "none" in the handoff. Step 10 replaces the sentinel with `None.` or one bullet per departure.

Gate 4a then enforces it in three tiers, cheapest and most certain first:

| Tier | Checks | Kind |
|---|---|---|
| 1 | The sentinel is still present -- the section was never reviewed | Mechanical |
| 2 | An engineer reported a departure that never reached the section | Near-mechanical |
| 3 | A stated call the branch diff contradicts, with nothing recorded | Judgment, bounded |

Tier 3 works **from the calls, never from the diff** — it looks up only the concrete artifact each call names, so a call naming nothing specific ("keep it maintainable") is out of scope by construction rather than by the gate guessing. It may only fail when it can quote the call verbatim *and* name a contradicting `file:line`; anything less becomes an advisory. **Ambiguity advises rather than fails**, deliberately inverting the rule for bars: an ambiguous call is a planning imprecision from several stages back, and a gate that fails on someone else's imprecision gets switched off. The remedy for a Tier-3 finding is one line in `## Deviations`, not a code change.

## Memory

The `memory/` directory gives agents a lightweight persistence layer. Decisions, architectural context, and known issues are stored as Markdown files that survive between sessions.

Memory is committed to version control so the full team shares accumulated context. When the tech-lead records an architectural decision, every future agent session in that codebase picks it up automatically.

**Who writes:** tech-lead (for decisions) and devils-advocate (for challenge sessions). Engineer agents (csharp, frontend, mcp, database) may also write to `memory/known-issues/`, but only for a genuine platform quirk or constraint that is non-obvious, affects future work, and is not already documented. All other agents are read-only.

**File naming:** `YYYY-MM-DD-[decision|challenge]-brief-slug.md` in the appropriate subdirectory.

**Agents skip** files with `status: superseded` or `status: archived` automatically.

**Repo map:** `memory/architecture/repo-map.md` is a singleton living document — a directory-level map of the codebase (what each directory does plus its entry-point files) maintained by the `/repo-map` skill and stamped with the git commit it was last verified against (`Verified-at-commit`). Unlike other memory files it uses a fixed, undated name because it is refreshed in place rather than written once. It rides the memory-snapshot hook to Obsidian for free. `/onboard`, tech-lead, `/plan`, `/refactor`, and `/scaffold` read it; merge-reviewer, git-engineer, and `/memory-audit` flag it for refresh when the tree drifts.

See `docs/AGENT-GUIDE.md` for the full memory format, hygiene guidance, and scaling notes.

## Design Patterns

The rules underneath the pipeline. None are specific to these agents or this stack -- they are decisions any team building multi-agent delivery has to make one way or another, and they are the transferable part of this repo.

**The description is the contract.** No orchestrator holds a hardcoded agent list; routing reads each agent's own description of when it should be invoked. A new specialist becomes routable by describing itself well, so the routing layer cannot drift out of step with the roster.

**Reviewers cannot edit.** code-reviewer, security-reviewer, and performance-reviewer hold read tools only. A reviewer that fixes what it finds leaves no independent record of what was wrong, and a review quietly becomes a rewrite.

**One agent may commit.** Everything funnels through a single final gate that verifies the required stages ran, then commits -- never to the main branch. One place to check when asking "was this reviewed?", and one place to fix when the answer is no.

**Severity is not authority.** Each finding class is assigned blocking or advisory status explicitly, with the reasoning recorded. Otherwise every reviewer's worst finding becomes a blocker and the pipeline stalls on taste.

**Isolate writers, not readers.** Agents that change code work in their own throwaway checkout; files every stage depends on are written by the coordinating session instead. Isolation buys parallelism without paying for it in merge conflicts.

**Fast paths, stated exemptions.** The emergency flows skip planning and structural review, and each skip is written into the flow as deliberate with its reason attached. An unwritten exemption is indistinguishable from a bug, and someone will eventually "fix" it.

**Challenge before build.** Significant or hard-to-reverse decisions get an adversarial pass first, and where it earns its cost, a second opinion from a different model -- which disagrees in different places than a second pass by the same one.

**Durable artifact over chat.** Anything that must outlive the conversation gets a file: decisions, constraints, known issues, and the plan a pipeline is measured against. Advice in a transcript cannot be enforced, searched, or handed over.

**Opt in, never discover.** A stage acts on an artifact only when handed a specific identifier. Ambient directory discovery lets an unrelated run pick up someone else's artifact and confidently judge the wrong work.

**Verify effects, not exit codes.** Where a tool reports success unreliably, success means a positive signal *and* the effect confirmed by reading it back independently. Established the hard way: a tool reported a file created and wrote zero bytes -- the success message passed, and only the read-back caught it.

**Match the model to the task.** Mechanical gates run on the cheapest capable tier, implementation on the middle, planning and adversarial review on the strongest. Reasoning capacity is the expensive input; spending it on a lint check and skimping on the architectural decision is backwards.

**Name an owner for every duty.** For each responsibility a design names, identify the file that will carry it, then diff that list against the files actually being changed. Learned from four duties that no component owned, found one at a time over three sessions -- the design assigned duties to *roles* while the work edited *files*, and nothing reconciled the two lists.

A gate is also **unproven until it has refused something**. Every flow here is defined in a prompt file, and a prompt that reads correctly can still fail to fire. Treat a new gate as intent rather than enforcement until you have deliberately handed it something bad and watched it refuse.

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

The uninstaller removes agents from `~/.claude/agents/`, skills from `~/.claude/skills/`, all five installed Obsidian hook scripts (`obsidian-stop-hook.js`, `obsidian-prompt-hook.js`, `obsidian-agent-hook.js`, `obsidian-context-hook.js`, `obsidian-memory-hook.js`) plus their `settings.json` hook entries, and all Obsidian env vars (`OBSIDIAN_VAULT_PATH`, `OBSIDIAN_PROJECTS_FOLDER`, `OBSIDIAN_CLI_MODE`, `OBSIDIAN_REST_API_KEY`, `OBSIDIAN_REST_API_PORT`, `OBSIDIAN_REST_API_HTTPS`) from `~/.claude/settings.json` — all after confirmation. Project-level `memory/` directories and anything already written to your vault are not touched.

## Agent Dashboard

[claude-agent-dashboard](https://github.com/chuckplayer/claude-agent-dashboard) is a companion local web UI for monitoring Claude Code sessions in real time.

- **Live session feed** — agent Gantt timeline and scrolling event log, updated within 1 second of any Claude Code hook event
- **Memory browser** — browse and search `memory/*.md` files across all projects; renders full markdown on click
- **Session history** — SQLite-backed log of past sessions with duration, prompt counts, and agent invocation counts

The dashboard works with any Claude Code installation. The agent pack is optional — if both are installed, the memory browser surfaces the architectural decisions and challenge records that tech-lead and devils-advocate write during sessions.

Requires Node.js 22+ (uses the built-in `node:sqlite` module). Nothing leaves your machine — the server binds to `127.0.0.1` only.

## License

MIT. See LICENSE.
