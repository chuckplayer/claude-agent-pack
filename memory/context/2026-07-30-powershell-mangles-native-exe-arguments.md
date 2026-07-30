**Date:** 2026-07-30
**Type:** constraint
**Status:** active
**Superseded-by:** n/a
**Scope:** global
**Overrides-convention:** no
**Related-to:** 2026-07-10-bash-tool-silent-failure-windows.md

## Summary

Windows PowerShell 5.1 rewrites arguments on their way to a **native executable**, so a bash
one-liner handed to `bash.exe` can arrive different from what was written — silently, with no error.
Two forms are known to be destroyed: `${...}` parameter expansions and unquoted embedded spaces.
Single-quoting in PowerShell does **not** protect them, because the mangling happens at the
native-command argument boundary, not during PowerShell's own string parsing.

Separately and just as costly: `(Get-Command bash).Source` on this machine resolves to
`C:\WINDOWS\system32\bash.exe` — the WSL stub — **not** Git Bash.

## Discovery context

Both were hit on 2026-07-30 while verifying a `.bashrc` edit.

**The argument mangling.** This command was intended to print the value of a shell variable:

```powershell
& $gb -lc 'echo "canary=${BASHRC_CANARY_LOADED:-NOT LOADED}"'
```

It printed `canary=$`. The `{...}` and the space inside `NOT LOADED` were eaten before bash saw them.
Read naively, that output says the variable is unset — a **false negative**. Re-running the same check
through the `Bash` tool directly returned `canary=[1]`: the variable was set all along, and the
`.bashrc` was loading correctly.

**The wrong bash.** Running `& (Get-Command bash).Source scripts/lint-agents.sh` produced a
UTF-16-mangled `T h e   s y s t e m   c a n n o t   f i n d   t h e   f i l e   s p e c i f i e d .`
plus exit 1 — which reads exactly like a failing script. The script was fine; the interpreter was the
WSL stub, which has no access to the Windows path being passed.

## Impact

Both failure modes produce output that looks like a **genuine negative result** rather than a broken
invocation. That is the dangerous property: a mangled verification command does not error, it
*reports failure*, and the natural next move is to go debug something that was never broken. On this
machine that compounds with [[2026-07-10-bash-tool-silent-failure-windows]] — one layer can lose
output, and this layer can corrupt input, so a shell check has two independent ways to lie.

## Workaround

- **Always invoke Git Bash by its literal path**, never via `(Get-Command bash)`:
  `& "C:\Program Files\Git\bin\bash.exe" <script>`
- **Do not embed `${...}` or unquoted spaces** in a shell string passed to a native exe from
  PowerShell. Use the plain `$VAR` form (`echo "canary=[$VAR]"`), or run the command through the
  `Bash` tool instead of shelling out through PowerShell.
- **When a verification command returns an unexpected negative, suspect the invocation before the
  subject.** Re-run it a second way. On 2026-07-30 that single habit was the difference between
  "the `.bashrc` edit broke the canary" and "the check was malformed."
- Note that stderr redirection is a third trap in the same family: PowerShell wraps a native
  command's stderr as `NativeCommandError` and flips `$?` to false even on exit 0. Trust the explicit
  `$LASTEXITCODE`, not `$?`, after calling a native exe.
