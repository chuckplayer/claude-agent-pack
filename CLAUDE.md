@docs/CLAUDE.template.md

## This repository

This repository is the pack itself. The rules above are `docs/CLAUDE.template.md`, the block that
`scripts/setup-project.sh` copies into a consuming project -- edit them there, not here. Everything below
applies only to changing the pack, and a consuming project has none of these scripts. In this
repository the long-form rules the template points to are `references/orchestration-rules.md`.

Four checks guard a change to the pack. Full text and the incident behind each: `docs/pack-development.md`.

- **`bash scripts/lint-agents.sh`** when the changeset touches `agents/`, `skills/`, `references/`,
  `CLAUDE.md` or `docs/CLAUDE.template.md`, after the files are written and before code-reviewer.
  Blocking on non-zero exit; exit **2** means the linter's own self-test failed, which is also a FAIL.
  Enforced by merge-reviewer gate 2a. Skip it, saying so, when none of those paths changed.
- **`node scripts/obsidian-stop-hook.test.js`** when the changeset touches `scripts/obsidian-stop-hook.js`
  or `scripts/obsidian-context-hook.js`. The trigger is those two filenames, not the `scripts/` directory.
  Blocking; enforced by gate 2b.
- **`bash scripts/lint-identifiers.sh`** on **every** changeset. This repository is public, so it fails on
  a real organisation, project, host, user path or email where a placeholder is required. Blocking and
  enforced by gate 2c; there is no legitimate skip, so if it was not run, say so rather than implying it
  passed. It reads `git ls-files`, so **stage new files first** (`git add -N <path>`), or the clean result
  says nothing about them.
- **`bash scripts/lint-memory.sh`** when the changeset touches `memory/`. Blocking for the coordinating
  session; no merge-reviewer gate enforces it, so an unrun check here is simply unrun.
