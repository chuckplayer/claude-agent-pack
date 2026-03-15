---
name: check-updates
description: Checks whether installed agents and skills are current with the pack source. Runs scripts/check-updates.sh and reports what is outdated or missing. Use before pulling updates or when something seems off after a git pull.
---

# Check Updates

Compare installed agents and skills against the pack source to identify anything outdated or missing.

## 1. Locate the pack

Find the pack directory by locating `scripts/check-updates.sh`. If you cannot locate it, ask the user where they cloned the pack.

## 2. Run the update check

```bash
bash <pack-dir>/scripts/check-updates.sh
```

Capture the full output.

## 3. Interpret the results

The script reports three states for each agent and skill:

| State | Meaning |
|-------|---------|
| `[ok]` | Installed and matches the pack source |
| `[!!] (outdated)` | Installed but differs from the pack source |
| `[--] (not installed)` | Not installed at all |

## 4. Report

- List any outdated or missing agents and skills.
- If everything is current, confirm that all agents and skills are up to date.
- If anything is outdated or missing, recommend running the installer:

```bash
# macOS
bash <pack-dir>/install.sh

# Windows
& "<pack-dir>\install.ps1"
```

- Offer to run the installer on the user's behalf if they confirm.
