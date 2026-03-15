---
name: check-readiness
description: Verifies that Claude Code, all agents, all skills, and the current project's scaffolding are fully installed. Runs scripts/check-readiness.sh and interprets any failures with specific remediation steps. Use before starting work on a project or after a fresh clone.
---

# Check Readiness

Verify that the Claude Agent Pack and the current project are correctly set up.

## 1. Locate the pack

Find the pack directory by locating the `scripts/check-readiness.sh` file. The pack is typically cloned to a fixed location (e.g., `~/claude-agent-pack`). If you cannot locate it, ask the user where they cloned the pack.

## 2. Run the readiness check

Run the script, passing the current project directory as the argument:

```bash
bash <pack-dir>/scripts/check-readiness.sh <project-dir>
```

Capture the full output.

## 3. Interpret the results

For each `[!!]` failure in the output:

| Failure | Remediation |
|---------|-------------|
| `~/.claude directory` | Claude Code is not installed — direct the user to install it |
| Agents not installed | Run `bash <pack-dir>/install.sh` |
| Skills not installed | Run `bash <pack-dir>/install.sh` |
| `CLAUDE.md` missing | Run `bash <pack-dir>/scripts/setup-project.sh <project-dir>` |
| `docs/CONVENTIONS.md` missing | Run `bash <pack-dir>/scripts/setup-project.sh <project-dir>` |
| `docs/MEMORY-WRITING.md` missing | Run `bash <pack-dir>/scripts/setup-project.sh <project-dir>` |
| `memory/<subdir>/` missing | Run `bash <pack-dir>/scripts/setup-project.sh <project-dir>` |

## 4. Report

- If all checks pass: confirm the pack and project are fully set up and ready.
- If any checks failed: list each failure with its remediation command. Group multiple project-scaffolding failures under a single `setup-project.sh` invocation — do not repeat the same command for each missing file.
- Offer to run remediation commands on the user's behalf if they confirm.
