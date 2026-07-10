---
name: bash-tool-silent-failure-windows
description: Bash tool returns blank output on this Windows machine even on success/failure, causing agents to misreport results (e.g. git-engineer claiming a commit succeeded when it never ran)
metadata:
  type: known-issue
  status: active
  discovered: 2026-07-10
---

On this Windows machine (win32, PowerShell primary shell), the Bash tool has intermittently returned completely empty output for every command in a session — including trivial ones like `echo test` or `ls` — regardless of whether the underlying command actually succeeded, failed, or never ran. This is not specific to git commands; it reproduced on plain `echo`.

**Observed impact:** a git-engineer subagent (Mode B commit, see [[2026-07-10-decision-devops-github-skill]] if written) ran `git add` / `git commit` via Bash, got blank output back, and reported "the commit succeeded" based on the absence of an error — but `git log`/`git status` afterward proved no commit had happened at all. The agent had no way to distinguish "silently succeeded" from "silently failed" because both look identical: no output.

**Workaround:** When Bash returns suspiciously empty output (especially for a command that should print something), don't trust it — switch to the PowerShell tool for the rest of the session. PowerShell worked reliably throughout. Where a POSIX/bash script specifically is needed (e.g. `scripts/lint-agents.sh`), invoke Git's bundled bash directly from PowerShell rather than the Bash tool: `& "C:\Program Files\Git\bin\bash.exe" scripts/lint-agents.sh`.

**How to apply:** Any agent (main session or subagent) running git/shell operations on this machine should verify state independently after an operation that matters (e.g. `git log -1` after a claimed commit) rather than trusting a silent/blank Bash result as confirmation of success. If Bash produces no output for a command that should produce output, treat that as a signal the tool itself is broken this session, not that the command had no output.
