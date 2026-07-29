---
name: install-sh-silently-skips-obsidian-block-noninteractive
description: install.sh blocks on an interactive `read` prompt; run without a TTY it exits 0 having skipped the entire Obsidian block, so hook scripts are never copied and edits to them never go live
metadata:
  type: known-issue
  status: active
  discovered: 2026-07-29
---

`install.sh:205` prompts `read -rp "  Keep Obsidian integration? [Y/n] "` whenever
`$current_vault` is already set — i.e. on every re-install on a configured machine.

Run through a tool call or any other stdin-less context, `read` hits EOF immediately and
`keep_response` stays empty. That is neither `n` nor `N`, so the teardown branch is skipped
— but nothing sets `obsidian_setup=true` or `vault_path` either, so the block guarded by
`if [ "$obsidian_setup" = "true" ] && [ -n "$vault_path" ]` (install.sh:274) never runs.
That block contains the `cp` of all five hook scripts to `~/.claude/scripts/`
(install.sh:419-425).

**Observed impact:** a fix to `scripts/obsidian-stop-hook.js` was edited, tested (126 tests
green), and "installed" via `bash install.sh`. The installer printed `[ok]` for all 19 agents
and 27 skills, printed `Obsidian integration is active (vault: …)`, and exited 0 — while the
installed hook remained the previous build. The repo copy was 38597 bytes; the installed copy
was still 37296 bytes from two days earlier. Verified only because the installed file's size
and hash were checked afterwards.

This is the same defect class as
[[2026-07-27-obsidian-cli-silent-failure-modes]] and
[[2026-07-10-bash-tool-silent-failure-windows]]: **exit 0 plus a success message, no effect.**
Agents and skills *do* copy, because those loops run before the Obsidian block — which makes
the output look complete and is exactly why it goes unnoticed.

**Workaround:**

1. **Never trust `install.sh`'s exit code or output for the Obsidian hook scripts.** Confirm
   by hash, not by reading the log:
   ```powershell
   (Get-FileHash scripts\obsidian-stop-hook.js).Hash -eq `
     (Get-FileHash "$env:USERPROFILE\.claude\scripts\obsidian-stop-hook.js").Hash
   ```
   The absence of a `[ok] hook:   obsidian hook scripts installed …` line in the output is the
   direct tell that the block was skipped.
2. **To install interactively**, have the user run it themselves so the prompt gets a TTY —
   in Claude Code, `! bash install.sh` runs it in the session with output in the transcript.
3. **For a hook-script-only change**, copying the changed file to `~/.claude/scripts/` is
   equivalent to what line 421-425 would have done and touches nothing else — the hook
   registrations in `settings.json` already point at `~/.claude/scripts/<name>.js`, so no
   re-registration is needed. Confirm the other four are in sync first so the copy does not
   quietly ship unrelated drift.

**Revisit trigger:** `install.sh` gaining a non-interactive path — either a `--yes`/`--keep`
flag, or defaulting `keep_response` when stdin is not a TTY (`[ -t 0 ]`). Either would make
this file `resolved`. Until then, keep step 1's hash check: an installer that reports success
without acting is worse than one that fails.

**How to apply:** Editing any file under `scripts/` in this repo changes nothing on the
machine until it reaches `~/.claude/scripts/`. Treat "ran install.sh" as an unverified claim
and check the installed artifact directly — the same rule `obsidian-writer` applies to CLI
writes, for the same reason.
