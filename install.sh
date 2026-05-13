#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CLAUDE_DIR="$HOME/.claude"
if [ ! -d "$CLAUDE_DIR" ]; then
    echo "ERROR: Claude Code directory not found at $CLAUDE_DIR"
    echo "Install Claude Code first: https://code.claude.com"
    exit 1
fi

AGENTS_DIR="$CLAUDE_DIR/agents"
mkdir -p "$AGENTS_DIR"

SKILLS_DIR="$CLAUDE_DIR/skills"
mkdir -p "$SKILLS_DIR"

VERSION=$(cat "$SCRIPT_DIR/VERSION")
echo "Claude Agent Pack v$VERSION"
echo ""

for agent_file in "$SCRIPT_DIR/agents/"*.md; do
    filename="$(basename "$agent_file")"
    cp "$agent_file" "$AGENTS_DIR/$filename"
    echo "  [ok] agent:  ${filename%.md}"
done

echo ""
for skill_dir in "$SCRIPT_DIR/skills/"*/; do
    skill_name="$(basename "$skill_dir")"
    mkdir -p "$SKILLS_DIR/$skill_name"
    cp "$skill_dir/SKILL.md" "$SKILLS_DIR/$skill_name/SKILL.md"
    echo "  [ok] skill:  $skill_name"
done

# Remove skills that were deprecated or merged in a previous version
deprecated_skills=("agent-plan" "challenge" "check-readiness" "check-updates")
deprecated_removed=0
for name in "${deprecated_skills[@]}"; do
    target="$SKILLS_DIR/$name"
    if [ -d "$target" ]; then
        rm -rf "$target"
        echo "  [rm] skill:  $name (deprecated)"
        deprecated_removed=$((deprecated_removed + 1))
    fi
done
[ "$deprecated_removed" -gt 0 ] && echo ""

# Optional: Obsidian vault integration
echo ""
read -p "Set up Obsidian vault integration? [y/N] " obsidian_response
if [ "$obsidian_response" = "y" ] || [ "$obsidian_response" = "Y" ]; then
    if ! command -v python3 &>/dev/null; then
        echo "  WARNING: python3 not found -- Obsidian setup requires python3."
        echo "  Install python3 and re-run install.sh to complete Obsidian setup."
    else
    read -p "  Obsidian vault path (absolute path to your vault directory): " vault_path
    if [ -n "$vault_path" ]; then
        python3 - "$vault_path" <<'PYEOF'
import json, os, sys
vault_path = sys.argv[1]
vault_path = os.path.realpath(os.path.expanduser(vault_path))
p = os.path.expanduser("~/.claude/settings.json")
s = json.load(open(p)) if os.path.exists(p) else {}
s.setdefault("env", {})["OBSIDIAN_VAULT_PATH"] = vault_path
os.makedirs(os.path.dirname(p), exist_ok=True)
with open(p, "w") as f:
    json.dump(s, f, indent=2)
    f.write("\n")
PYEOF
        if [ $? -ne 0 ]; then
            echo "  ERROR: failed to update ~/.claude/settings.json"
        fi
        echo "  [ok] env:    OBSIDIAN_VAULT_PATH=$vault_path"

        # Detect CLI mode
        rest_port=27123
        cli_mode="filesystem"
        if command -v curl &>/dev/null && curl -s --max-time 1 "http://127.0.0.1:${rest_port}/" &>/dev/null 2>&1; then
            cli_mode="rest-api"
        fi
        python3 - "$cli_mode" "$rest_port" <<'PYEOF'
import json, os, sys
port = int(sys.argv[2])
assert 1 <= port <= 65535, f"Invalid port: {port}"
p = os.path.expanduser("~/.claude/settings.json")
s = json.load(open(p)) if os.path.exists(p) else {}
s.setdefault("env", {})["OBSIDIAN_CLI_MODE"] = sys.argv[1]
if sys.argv[1] == "rest-api":
    s["env"]["OBSIDIAN_REST_API_PORT"] = sys.argv[2]
os.makedirs(os.path.dirname(p), exist_ok=True)
with open(p, "w") as f:
    json.dump(s, f, indent=2)
    f.write("\n")
PYEOF
        if [ $? -ne 0 ]; then
            echo "  ERROR: failed to update ~/.claude/settings.json"
        fi
        if [ "$cli_mode" = "rest-api" ]; then
            echo "  [ok] env:    OBSIDIAN_CLI_MODE=rest-api (Local REST API on port ${rest_port})"
        else
            echo "  [ok] env:    OBSIDIAN_CLI_MODE=filesystem"
        fi

        # Install hook scripts
        mkdir -p "$HOME/.claude/scripts"
        cp "$SCRIPT_DIR/scripts/obsidian-stop-hook.sh" "$HOME/.claude/scripts/"
        cp "$SCRIPT_DIR/scripts/obsidian-stop-hook.ps1" "$HOME/.claude/scripts/"
        chmod +x "$HOME/.claude/scripts/obsidian-stop-hook.sh"
        echo "  [ok] hook:   obsidian-stop-hook installed"

        # Register Stop hook
        if uname -s 2>/dev/null | grep -qi "mingw\|cygwin\|msys\|windows"; then
            hook_cmd="powershell.exe -ExecutionPolicy Bypass -File \"$HOME/.claude/scripts/obsidian-stop-hook.ps1\""
        else
            hook_cmd="bash \"$HOME/.claude/scripts/obsidian-stop-hook.sh\""
        fi
        python3 - "$hook_cmd" <<'PYEOF'
import json, os, sys
p = os.path.expanduser("~/.claude/settings.json")
s = json.load(open(p)) if os.path.exists(p) else {}
hooks = s.setdefault("hooks", {})
stop_hooks = hooks.setdefault("Stop", [])
new_hook = {"type": "command", "command": sys.argv[1]}
# Avoid duplicates
if not any(h.get("command") == sys.argv[1] for h in stop_hooks):
    stop_hooks.append(new_hook)
with open(p, "w") as f:
    json.dump(s, f, indent=2)
    f.write("\n")
PYEOF
        if [ $? -ne 0 ]; then
            echo "  ERROR: failed to update ~/.claude/settings.json"
        fi
        echo "  [ok] hook:   Stop hook registered in ~/.claude/settings.json"
    else
        echo "  [skip] No vault path provided — skipping Obsidian setup."
    fi
    fi
fi

echo ""
echo "Next steps:"
echo ""
echo "  1. Scaffold a project (copies CLAUDE.md, docs, and memory/ structure):"
echo "     $SCRIPT_DIR/scripts/setup-project.sh <your-project-path>"
echo ""
echo "  2. Verify everything is ready:"
echo "     $SCRIPT_DIR/scripts/check-readiness.sh <your-project-path>"
echo ""
echo "  3. In Claude Code, try: /plan add a payment processing feature"
echo ""
echo "To verify: open Claude Code and run /agents -- your new agents should appear in the list."
