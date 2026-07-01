---
name: setup-project
description: "Scaffolds a project with the Claude Agent Pack structure: copies CLAUDE.md, docs/CONVENTIONS.md (from template), docs/MEMORY-WRITING.md, and creates the memory/ subdirectories. Runs scripts/setup-project.sh and guides the user through next steps. Trigger this when someone says: set up this project, initialize the agent pack, scaffold the project structure, add Claude Agent Pack to this repo, new project setup, onboard this repo. Do NOT use to verify an existing installation — use /system-check instead."
---

# Setup Project

Scaffold a project directory with the Claude Agent Pack structure.

## 1. Confirm the target directory

The target defaults to the current working directory. If the user specified a different path, use that. Confirm with the user if there is any ambiguity.

## 2. Locate the pack

Find the pack directory by locating `scripts/setup-project.sh`. If you cannot locate it, ask the user where they cloned the pack.

## 3. Run the setup script

```bash
bash <pack-dir>/scripts/setup-project.sh <target-dir>
```

Capture the full output.

## 4. Interpret the output

| Line | Meaning |
|------|---------|
| `[ok] CLAUDE.md` | Copied successfully (overwrites any existing file) |
| `[ok] docs/CONVENTIONS.md  (from template)` | Template copied — needs to be filled in |
| `[--] docs/CONVENTIONS.md already exists, skipped` | Existing file preserved — no action needed |
| `[ok] docs/MEMORY-WRITING.md` | Copied successfully |
| `[ok] memory/<subdir>/` | Directory created with `.gitkeep` |

## 5. Guide next steps

After the script completes, work through these follow-up steps with the user:

1. **Commit the scaffolding** — suggest the commit command printed by the script:
   ```bash
   git add CLAUDE.md docs/ memory/ && git commit -m 'chore: add Claude Agent Pack scaffolding'
   ```

2. **Ask about conventions** — if `docs/CONVENTIONS.md` was created from the template, ask:
   > "The conventions file was created from a template and needs to be filled in. Would you like me to run `/conventions` now to document your team's standards interactively?"

3. **Ask about onboarding** — after the commit, ask:
   > "Would you like me to run `/onboard` to generate a structured orientation for this codebase?"

4. **Ask about the repo map** — offer to seed a durable structure map:
   > "Would you like me to run `/repo-map` to generate a directory-level map of this codebase? It gets stored in `memory/architecture/` (so it shares across sessions and syncs to Obsidian) and is read by `/onboard`, tech-lead, `/plan`, `/refactor`, and `/scaffold`."

All follow-up skills are optional. None blocks the others.

## Gotchas

- **Script not found:** If `scripts/setup-project.sh` cannot be located, ask the user where they cloned the agent pack. Do not attempt to recreate the script manually — the script has specific file content and permissions that are not reproducible from memory.
- **Running setup on a non-empty project:** The script preserves existing files (e.g., `docs/CONVENTIONS.md already exists, skipped`). This is intentional — existing content is not overwritten. Confirm with the user if they expected a file to be replaced.
- **Forgetting to commit the scaffolding:** The scaffolded files (CLAUDE.md, docs/, memory/) are meaningless until committed. Always suggest the commit command in step 5.1 before moving to follow-up skills.
- **Target directory confusion:** If the user's working directory and the target project directory differ (e.g., they want to set up a sibling repo), confirm the target path explicitly before running the script.
