---
date: 2026-05-14
type: finding
status: archived
superseded-by: 2026-05-14-decision-obsidian-hook-windows-resolution.md
scope: scripts/obsidian-stop-hook.*, install.sh hook registration block
overrides-convention: no
related-to: 2026-03-18-challenge-script-value-assessment.md, 2026-04-26-challenge-llm-wiki-skill-family.md
last-updated: 2026-05-14
---

> All items resolved or accepted same day. See superseded-by file for resolution
> of each concern. Archived — agents may skip this file.

## Summary

Pressure-tested the Obsidian Stop hook implementation after three weeks of
failed attempts to make it work on Windows. The hook currently uses a
node.exe launcher (`scripts/obsidian-stop-hook.js`) that spawns
`bash.exe --login` to run `scripts/obsidian-stop-hook.sh`. The
justification embedded in the launcher cites an "MSYS2 fork issue" that
is not cited from any source and is contradicted by Claude Code's
official hooks documentation. Multiple lower-cost approaches have not
been tried. A dormant `.ps1` variant is also present in the tree without
explanation, contradicting the recorded March 2026 decision that
removed all `.ps1` scripts.

## Context

User asked for a devils-advocate review of the bash-on-Windows debugging
loop. Three command formats have been attempted: direct bash with
`--login`, `/usr/bin/bash --login` form, and a node.exe launcher that
re-invokes bash. All produced exit 126 or quoting failures. The same
script runs cleanly when invoked manually from a Git Bash shell.

## Concerns Raised

### Critical

- **C1 — Claude Code hook invocation semantics were never read. Unresolved.**
  The official docs at https://code.claude.com/docs/en/hooks state
  that on Windows, shell form passes the command to **Git Bash** (or
  PowerShell as fallback), and exec form (when `args` is present)
  bypasses any shell entirely. Three weeks of trial-and-error were
  spent guessing at semantics that are documented. The exec-form path
  (`command: bash`, `args: [script]`) eliminates all quoting issues
  by construction and has not been tried.

- **C2 — Node.exe launcher addresses an uncited failure mode. Unresolved.**
  `scripts/obsidian-stop-hook.js` comment claims "Claude Code's bash
  hook runner cannot fork-exec bash (MSYS2 fork issue)." No source.
  Not in the official docs. The docs in fact say the hook runner IS
  Git Bash on Windows, meaning bash-launching-bash is the documented
  path. The launcher may be solving a problem that does not exist,
  while introducing a new dependency (Node on PATH) and another
  process boundary.

### High

- **H1 — `.ps1` reappeared with no memory record. Unresolved.**
  `memory/known-issues/2026-03-18-challenge-script-value-assessment.md`
  recorded that all `.ps1` scripts were removed in March 2026 because
  Git Bash runs `.sh` on Windows without issue. The current tree
  contains `scripts/obsidian-stop-hook.ps1` and README.md:112
  documents it. Either the March decision is superseded (memory needs
  an update) or the file is dead code (should be deleted). The
  ambiguity is itself a defect.

- **H2 — `--login` is loadbearing on an unnamed dependency. Unresolved.**
  The hook script uses `date`, `git`, `sed`, `tr`, `cut`, `basename`,
  `realpath`, `cat`, `mkdir`, `printf`, `echo`. All except `git` are
  in `/usr/bin` and available without `--login`. The `--login` flag
  sources `/etc/profile`, may prompt, and may interact with how Claude
  Code pipes JSON to the hook's stdin. It has not been confirmed which
  specific binary or env var requires it. Removing `--login` was not
  tried as a debugging step.

- **H3 — CRLF / encoding / shebang health unchecked. Unresolved.**
  `.sh` files checked out on Windows with `core.autocrlf=true` produce
  CRLF line endings that cause `exit 126` on bash's shebang parse.
  No `.gitattributes` policy is in place for the scripts directory.
  This is a more likely cause of exit 126 than an MSYS2 fork issue.
  Has not been verified on the failing machine.

- **H4 — Two concurrent writers to `Claude/daily/<today>.md`. Unresolved.**
  `agents/obsidian-writer.md` writes daily-note appends during a
  session; the Stop hook writes daily-note appends at session end.
  Both compute paths inside `Claude/`, neither holds a lock. A user
  who explicitly triggers the agent late in a session will race
  against the hook firing on Stop. The two writers are unaware of
  each other.

### Medium

- **M1 — Silent failure mode prevented diagnosis. Unresolved.**
  Hook uses `set -uo pipefail`, `2>/dev/null` everywhere, and
  `exit 0` on every guard. A failing installation produces zero output
  to anywhere. Three weeks of debugging without an instrumentation
  trace is a process problem. A `date >> $HOME/.claude/obsidian-hook.log`
  at the top would have eliminated half the ambiguity.

- **M2 — Pack-script install-path precedent established without
  resolving the 2026-04-26 C1 concern. Unresolved.**
  `memory/known-issues/2026-04-26-challenge-llm-wiki-skill-family.md`
  raised the lack of precedent for shipping pack scripts to
  `~/.claude/scripts/` and referencing them from skills. The Obsidian
  hook installer (`install.sh:233-256`) silently established that
  precedent. Future skills will copy this pattern. The wiki C1
  concern remains unresolved in memory but its open question has been
  resolved-by-default in code.

- **M3 — Marginal content value vs. cross-platform complexity.
  Unresolved.**
  Hook output is: branch, last 5 commits, diff stat, uncommitted
  files. All recoverable from `git reflog` / `git log` / `git stash
  list` post-hoc. The unique value is the session-end timestamp and
  the Obsidian daily-note rollup. Whether this justifies a
  three-script, two-language, three-platform support matrix has not
  been explicitly weighed against alternatives.

## Implications

- The node.exe launcher and its installer branch in `install.sh` are
  suspected to be a workaround for a symptom, not the cause. Before
  any further fix is attempted, the team must (a) read the official
  shell-form vs exec-form docs, (b) check the line endings of the
  installed `.sh` file on the failing machine, (c) try a minimal
  one-line `.sh` to isolate whether the issue is script content or
  invocation.
- The `.ps1` file's status is ambiguous. Either the March 2026 memory
  needs a superseded-by pointer, or the file should be deleted.
- The two-writer race condition between `obsidian-writer` agent and
  the Stop hook is a latent bug that exists independent of the
  Windows launcher question and should be addressed separately.
- If the team accepts removing the Stop hook entirely (relying on
  the `obsidian-writer` agent for explicit session capture), the
  scope of this problem collapses to zero. This option should be
  explicitly weighed before more engineering on launchers.

A future session resolving this should re-read this file and explicitly
mark each item as Addressed or Accepted risk in a follow-up file under
`memory/decisions/`.
