---
name: system-check
description: Verify the Claude Agent Pack installation and current project scaffolding in one pass. Runs check-readiness.sh and check-updates.sh, reports all failures and outdated items together, and offers to run remediation. Use before starting work on a project or when something seems off after a git pull.
---

# System Check

Verify the Claude Agent Pack installation and current project scaffolding in a single pass.

## 1. Locate the pack

Find the pack directory by locating `scripts/check-readiness.sh`. The pack is typically cloned to a fixed location (e.g., `~/claude-agent-pack`). If you cannot locate it, ask the user where they cloned the pack.

## 2. Run both checks

Run readiness and update checks, passing the current project directory to readiness:

```bash
bash <pack-dir>/scripts/check-readiness.sh <project-dir>
bash <pack-dir>/scripts/check-updates.sh
```

Capture the full output of both.

## 3. Interpret readiness results

For each `[!!]` failure in check-readiness output:

| Failure | Remediation |
|---------|-------------|
| `~/.claude directory` | Claude Code is not installed — direct the user to install it |
| Agents not installed | `bash <pack-dir>/install.sh` |
| Skills not installed | `bash <pack-dir>/install.sh` |
| `CLAUDE.md` missing | `bash <pack-dir>/scripts/setup-project.sh <project-dir>` |
| `docs/CONVENTIONS.md` missing | `bash <pack-dir>/scripts/setup-project.sh <project-dir>` |
| `docs/MEMORY-WRITING.md` missing | `bash <pack-dir>/scripts/setup-project.sh <project-dir>` |
| `memory/<subdir>/` missing | `bash <pack-dir>/scripts/setup-project.sh <project-dir>` |

Group multiple project-scaffolding failures under a single `setup-project.sh` invocation.

## 4. Interpret update results

The update check reports three states for each agent and skill:

| State | Meaning |
|-------|---------|
| `[ok]` | Installed and matches the pack source |
| `[!!] (outdated)` | Installed but differs from the pack source |
| `[--] (not installed)` | Not installed at all |

List any outdated or missing agents and skills. If anything is outdated or missing, the fix is:

```bash
bash <pack-dir>/install.sh
```

## 5. Report and offer to remediate

Present a unified summary:
- All readiness failures with their remediation commands
- All outdated or missing agents/skills
- If everything is clean, confirm the pack and project are fully set up and ready

Offer to run the remediation commands on the user's behalf if they confirm.
