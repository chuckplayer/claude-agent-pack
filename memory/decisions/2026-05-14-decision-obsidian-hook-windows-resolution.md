---
date: 2026-05-14
type: decision
status: active
superseded-by: n/a
scope: scripts/obsidian-stop-hook.js, install.sh hook registration
overrides-convention: no
related-to: 2026-05-14-challenge-obsidian-stop-hook-windows.md
---

## Summary

Resolved the Obsidian Stop hook Windows failure (exit 126) by porting the
hook entirely to pure Node.js. The bash-based approach (both direct and
node-launcher-spawning-bash) was abandoned. All concerns from the May 2026
devils-advocate session are now closed.

## Context

Three weeks of failed attempts to invoke a bash script from the Claude Code
Stop hook on Windows (exit 126, MSYS2 fork issue). The root cause was that
Claude Code uses `cmd.exe` on Windows to invoke hooks, not Git Bash. `cmd.exe`
cannot execute MSYS2 binaries that require forking, including bash itself.

## Resolution of Each Concern

### C1 — Hook invocation semantics never read
**Addressed.** Determined through testing that Claude Code uses `cmd.exe /c
"<command>"` on Windows. Node.exe (a native Windows binary) is executed
directly by cmd.exe without any fork. The exec-form path in the official docs
was not needed — the command-string form works fine with a native exe.

### C2 — Node.js launcher for uncited failure mode
**Addressed.** The MSYS2 fork issue was real — verified by testing. The
"node launcher spawning bash" approach failed for the same reason (cmd.exe
cannot launch MSYS2 bash). Solution: eliminate bash entirely. The hook is
now self-contained Node.js using `execFileSync('git', ...)` for all git
operations and `fs` for all file I/O.

### H1 — .ps1 reappeared without memory record
**Addressed.** `obsidian-stop-hook.ps1` and `obsidian-stop-hook.sh` have
been removed from the repository (May 2026). `obsidian-stop-hook.js` is
the sole hook file. The March 2026 memory record has been amended to reflect
this.

### H2 — --login flag loadbearing
**Addressed.** Moot — no bash at all. Node.js needs no shell flags.

### H3 — CRLF/encoding/shebang
**Addressed.** Moot — Node.js has no shebang. Line endings in .js are
irrelevant to execution.

### H4 — Two concurrent writers to daily note
**Accepted risk.** The obsidian-writer agent (triggered by /obsidian-log)
and the Stop hook both append to the project's daily note. In practice,
the Stop hook fires after the session ends and the agent fires during. No
lock mechanism exists. The risk of a corrupted append is low but non-zero.
Revisit trigger: if users report garbled daily notes after triggering
/obsidian-log late in a session.

### M1 — Silent failure mode
**Partially addressed.** The hook now uses Node.js `uncaughtException`
handler (exits 0, never blocks session end). Still no debug log file.
Accepted for now — the Node.js approach is far simpler than the bash version
and errors are less likely. Revisit if hook failures become hard to diagnose.

### M2 — Pack-script install-path precedent
**Accepted.** `install.sh` installing `~/.claude/scripts/obsidian-stop-hook.js`
is now the established pattern. The wiki skill family followed a pure-LLM
approach (no scripts to install), so no second precedent was set.

### M3 — Marginal content value
**Addressed.** The hook now also writes a `memory-snapshot.md` per project
(recursive scan of `./memory/**/*.md`) and uses project-scoped paths under
`OBSIDIAN_PROJECTS_FOLDER`. Content value is materially higher.

## Implications

- The hook is pure Node.js. Any future hook scripts for Claude Code on Windows
  should use Node.js or native Windows exe — never MSYS2/bash.
- The project-scoped path pattern (`OBSIDIAN_PROJECTS_FOLDER`) is now the
  standard for all Obsidian writes. Default: `Claude/Projects`.
- `install.sh` registers the hook as `"node.exe" "path\to\hook.js"` using
  Windows-format paths via `cygpath -w` on MSYS2.
