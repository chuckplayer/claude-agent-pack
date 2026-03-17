---
name: setup-project
description: Scaffolds a project with the Claude Agent Pack structure: copies CLAUDE.md, docs/CONVENTIONS.md (from template), docs/MEMORY-WRITING.md, and creates the memory/ subdirectories. Runs scripts/setup-project.sh (macOS/Linux) or scripts/setup-project.ps1 (Windows) and guides the user through next steps.
---

# Setup Project

Scaffold a project directory with the Claude Agent Pack structure.

## 1. Confirm the target directory

The target defaults to the current working directory. If the user specified a different path, use that. Confirm with the user if there is any ambiguity.

## 2. Locate the pack

Find the pack directory by locating `scripts/setup-project.sh` (macOS/Linux) or `scripts/setup-project.ps1` (Windows). If you cannot locate it, ask the user where they cloned the pack.

## 3. Run the setup script

```bash
# macOS / Linux
bash <pack-dir>/scripts/setup-project.sh <target-dir>
```

```powershell
# Windows
& "<pack-dir>\scripts\setup-project.ps1" <target-dir>
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

After the script completes, prompt the user through the recommended follow-up:

1. **Fill in `docs/CONVENTIONS.md`** — if it was created from the template, it needs to be populated with the project's naming conventions, architectural rules, error handling strategy, logging standards, and compliance requirements. Offer to run `/conventions` to do this interactively.

2. **Commit the scaffolding** — suggest the commit command printed by the script:
   ```bash
   git add CLAUDE.md docs/ memory/ && git commit -m 'chore: add Claude Agent Pack scaffolding'
   ```

3. **Run `/onboard`** — once committed, offer to run `/onboard` to generate a structured orientation for the project.
