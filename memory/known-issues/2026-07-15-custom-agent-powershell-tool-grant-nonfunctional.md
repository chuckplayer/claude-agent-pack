---
date: 2026-07-15
type: known-issue
status: active
superseded-by: n/a
scope: n/a
overrides-convention: no
related-to: n/a
discovered: 2026-07-15
description: Listing "PowerShell" in a custom agent's tools frontmatter does not actually grant that agent the PowerShell tool -- the subagent only gets Bash
---

`agents/codex-reviewer.md` originally declared `tools: Bash, PowerShell` and documented a Windows fallback: if Bash returns suspiciously empty output (see [[2026-07-10-bash-tool-silent-failure-windows]]), retry via "the PowerShell tool" instead. In a live test, the spawned codex-reviewer subagent reported having only Bash available -- no PowerShell tool at all -- despite the frontmatter declaration. Every other agent in the pack that needs a shell only ever lists `Bash` in `tools:`; `codex-reviewer` was the only file attempting to grant `PowerShell` this way, and it does not work.

**Observed impact:** with Bash silently dead in the session (see [[2026-07-10-bash-tool-silent-failure-windows]]), the codex-reviewer subagent had no way to escape the broken channel. It correctly refused to fabricate a Codex response (per its hard constraints) and reported the failure honestly, but the documented recovery path was unreachable.

**Workaround:** Don't rely on a custom agent's `tools:` frontmatter to grant `PowerShell` to a subagent. If a task may need to fall back from a dead Bash tool to PowerShell, that fallback has to happen in a context that already has both tools available -- i.e., the main session -- not inside a spawned subagent restricted to `Bash` alone. For codex-reviewer specifically: on a machine with this Bash issue, run `codex exec` from the main session (which does have PowerShell) and hand the raw output to codex-reviewer for synthesis only, rather than expecting the subagent to shell out itself.

**Revisit trigger:** a Claude Code release note stating that a custom agent's `tools:` frontmatter can grant the `PowerShell` tool to a spawned subagent. Verified absent through 2.1.220 — 2.1.216's "Improved validation of git and gh command arguments in the PowerShell tool" is about command validation, not tool grant, and nothing else in the 2.1.187–2.1.220 window touches this. Re-test by spawning any agent with `tools: Bash, PowerShell` and asking it to list its available tools; if `PowerShell` appears, mark this file `resolved` and restore codex-reviewer's documented Windows fallback.

**How to apply:** When writing or reviewing any custom agent's `tools:` frontmatter, do not list `PowerShell` as a way to give it a Windows-safe shell fallback -- it silently doesn't grant anything extra. If Windows Bash breakage is a real risk for an agent's task, either keep the agent's shell-dependent steps in the main session, or explicitly document that the subagent should stop and report rather than attempt an unreachable fallback.
