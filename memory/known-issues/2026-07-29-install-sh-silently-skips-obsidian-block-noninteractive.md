---
date: 2026-07-29
type: known-issue
status: resolved
superseded-by: n/a
scope: n/a
overrides-convention: no
related-to: n/a
discovered: 2026-07-29
resolved: 2026-07-29
description: install.sh aborted at its first interactive read when stdin had no TTY, stopping mid-run before the hook-script copy -- fixed same day by routing every prompt through a prompt() helper plus a --yes flag
---

**Corrected mechanism.** The first draft of this file attributed the skip to the
`if [ "$obsidian_setup" = "true" ]` guard evaluating false. That was wrong. Tracing it
properly: `install.sh` sets `set -euo pipefail` on line 2, and a `read` that hits EOF
returns non-zero. Under `set -e` that **aborted the script at the first prompt**
(`read -rp "  Keep Obsidian integration? [Y/n] "`), so nothing after it ran — not the
Obsidian env writes, not the hook-script copy, not the codex model prompts, not the
closing instructions.

The script therefore exited **1**, not 0. It read as success because the diagnosing
command piped output through `tail -25` and later `grep`; `pipefail` is set *inside*
install.sh and does not apply to the invoking shell's pipeline, so the pipeline reported
`tail`'s status. The tell in the output was that
`Obsidian integration is active (vault: …)` was the *last* line printed — the abort point,
immediately before the prompt on the next line — rather than a summary.

**Observed impact:** a fix to `scripts/obsidian-stop-hook.js` was edited, tested (126 tests
green), and "installed" via `bash install.sh`. The installer printed `[ok]` for all 19 agents
and 27 skills (those loops run before the Obsidian block) and appeared to finish, while the
installed hook stayed at the previous build — repo 38597 bytes, installed 37296 bytes from
two days earlier. Caught only by hashing the installed file afterwards.

Same defect class as [[2026-07-27-obsidian-cli-silent-failure-modes]] and
[[2026-07-10-bash-tool-silent-failure-windows]]: **plausible output, no effect.** Here the
exit code *was* honest; the observer discarded it.

## Fix applied (2026-07-29)

Every prompt now goes through a `prompt <varname> <text>` helper instead of a bare `read`:

- `read ... || __reply=""` inside the helper, so an EOF can never abort the run under `set -e`.
- `ASSUME_DEFAULTS` is set when stdin is not a TTY (`[ ! -t 0 ]`) or `--yes`/`-y`/
  `--non-interactive` is passed. In that mode prompts are printed with a `[default]` marker
  and not read at all, so the run is auditable rather than silent.
- An unknown option is now a hard error with exit 1 instead of being ignored.

Empty reply still means "take the default", which is what every call site's `${var:-default}`
already assumed — so behaviour with a TTY is unchanged. Verified across all four paths:
no-TTY (exit 0, 5 prompts defaulted, hook copied), `--yes` (exit 0, hook copied),
`--bogus` (exit 1), `--help` (exit 0). Verified by effect, not exit code: the installed hook
was deliberately perturbed first, and the copy was confirmed to have overwritten it by hash,
with vault path, projects folder, REST API key, and all six hook registrations preserved.

Fixed alongside: the API-key prompt read `[keep existing, blank to remove]` while the code
does `rest_api_key="${new_key:-$current_api_key}"` — a blank reply *keeps* the key. The text
now reads `[Enter to keep existing]`. This mattered more once non-interactive runs always
submit blank.

**How to apply:** Editing any file under `scripts/` in this repo changes nothing on the
machine until it reaches `~/.claude/scripts/`. `bash install.sh --yes` is now safe to run
unattended and updates hook scripts while preserving existing settings. The absence of an
`[ok] hook:   obsidian hook scripts installed …` line still means the copy did not happen —
and when checking whether an installer worked, hash the installed artifact rather than
reading the log, and never pipe away the exit status you are trying to read.
