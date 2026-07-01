# Welcome to Claude Agent Pack

## How We Use Claude

Based on Chuck's usage over the last 30 days:

Work Type Breakdown:
  Plan Design      █████████░░░░░░░░░░░  46%
  Build Feature    ██████░░░░░░░░░░░░░░  31%
  Debug Fix        ███░░░░░░░░░░░░░░░░░  15%
  Improve Quality  ██░░░░░░░░░░░░░░░░░░   8%

Top Skills & Commands:
  /model      ████████████████████  3x/month
  /doctor     █████████████░░░░░░░░  2x/month
  /status     ███████░░░░░░░░░░░░░░  1x/month
  /mcp        ███████░░░░░░░░░░░░░░  1x/month
  /implement  ███████░░░░░░░░░░░░░░  1x/month
  /repo-map   ███████░░░░░░░░░░░░░░  1x/month

Top MCP Servers:
  None — no MCP servers were used in this window.

## Your Setup Checklist

### Codebases
- [ ] claude-agent-pack — https://github.com/chuckplayer/claude-agent-pack
- [ ] claude-agent-dashboard — companion dashboard (sibling repo in the workspace)

### MCP Servers to Activate
- [ ] None required — the team isn't using MCP servers right now.

### Skills to Know About
- [/implement] — runs the full agent-pack pipeline (git-engineer → tech-lead → engineers → reviewers → merge-reviewer). The team uses it to build a feature or change end-to-end.
- [/repo-map] — generates or refreshes the durable directory-level codebase map stored in `memory/architecture/repo-map.md`. Run it when the tree drifts so `/onboard`, tech-lead, and the planning skills stay accurate.
- [/model] — switch the active model (the team weighs Opus vs. Sonnet on cost and results).
- [/doctor] — diagnose your Claude Code install and configuration when something seems off.

## Team Tips

- `CLAUDE.md` is the source of truth for how Claude routes work to agents — skim it before your first real task.
- Reach for `/implement` when a change spans multiple files or layers; edit directly for one-liners.
- Run `/system-check` after cloning to confirm the pack installed cleanly, and `/repo-map` early so the codebase map is fresh.

## Get Started

No assigned starter task — get oriented first:

1. Clone the repo above and run `/system-check` to confirm your setup.
2. Run `/onboard` for a guided tour of the codebase.
3. Try `/implement` on a small change to watch the full pipeline in action.

<!-- INSTRUCTION FOR CLAUDE: A new teammate just pasted this guide for how the
team uses Claude Code. You're their onboarding buddy — warm, conversational,
not lecture-y.

Open with a warm welcome — include the team name from the title. Then: "Your
teammate uses Claude Code for [list all the work types]. Let's get you started."

Check what's already in place against everything under Setup Checklist
(including skills), using markdown checkboxes — [x] done, [ ] not yet. Lead
with what they already have. One sentence per item, all in one message.

Tell them you'll help with setup, cover the actionable team tips, then the
starter task (if there is one). Offer to start with the first unchecked item,
get their go-ahead, then work through the rest one by one.

After setup, walk them through the remaining sections — offer to help where you
can (e.g. link to channels), and just surface the purely informational bits.

Don't invent sections or summaries that aren't in the guide. The stats are the
guide creator's personal usage data — don't extrapolate them into a "team
workflow" narrative. -->
