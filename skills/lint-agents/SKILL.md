---
name: lint-agents
description: Validates required frontmatter fields and body content in every agent and skill file. Runs scripts/lint-agents.sh (macOS/Linux) or scripts/lint-agents.ps1 (Windows) and interprets failures with specific fixes. Use before committing new or modified agents/skills, or as a CI gate.
---

# Lint Agents

Validate that all agent and skill files in the pack are well-formed.

## 1. Locate the pack

Find the pack directory by locating `scripts/lint-agents.sh` (macOS/Linux) or `scripts/lint-agents.ps1` (Windows). If you cannot locate it, ask the user where they cloned the pack.

## 2. Run the linter

```bash
# macOS / Linux
bash <pack-dir>/scripts/lint-agents.sh
```

```powershell
# Windows
& "<pack-dir>\scripts\lint-agents.ps1"
```

Capture the full output.

## 3. Interpret failures

For each file with errors:

| Error | What it means | Fix |
|-------|---------------|-----|
| `MISSING: frontmatter opening ---` | File does not start with `---` | Add `---` as the first line |
| `MISSING field: name` | No `name:` line in frontmatter | Add `name: <agent-name>` |
| `MISSING field: description` | No `description:` line in frontmatter | Add a clear, routing-quality description |
| `MISSING field: tools` | No `tools:` line in frontmatter (agents only) | Add `tools: *` or list specific tools |
| `MISSING field: model` | No `model:` line in frontmatter (agents only) | Add `model: claude-sonnet-4-6` or appropriate model |
| `MISSING: agent instructions body` | Nothing after the closing `---` | Add the agent's instruction content |
| `WARNING: SKILL.md is very short` | Fewer than 5 lines total | Expand the skill instructions |

## 4. Fix or report

- If there are failures, describe exactly which files need what changes.
- If the user asks, apply the fixes directly using Edit.
- If all checks pass, confirm that all agents and skills are well-formed.
