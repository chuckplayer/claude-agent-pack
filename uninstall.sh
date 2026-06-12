#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

AGENTS_DIR="$HOME/.claude/agents"
SKILLS_DIR="$HOME/.claude/skills"
SETTINGS="$HOME/.claude/settings.json"

to_remove_agents=()
to_remove_skills=()

# Obsidian hook detection
remove_obsidian_env=false
remove_obsidian_hooks=false
HOOK_SH="$HOME/.claude/scripts/obsidian-stop-hook.sh"
HOOK_STOP_JS="$HOME/.claude/scripts/obsidian-stop-hook.js"
HOOK_PROMPT_JS="$HOME/.claude/scripts/obsidian-prompt-hook.js"
HOOK_AGENT_JS="$HOME/.claude/scripts/obsidian-agent-hook.js"
HOOK_CONTEXT_JS="$HOME/.claude/scripts/obsidian-context-hook.js"

if [ -f "$SETTINGS" ] && command -v python3 &>/dev/null; then
    has_obsidian_env=$(python3 - "$SETTINGS" <<'PYEOF'
import json, sys
try:
    s = json.load(open(sys.argv[1]))
    env = s.get("env", {})
    if any(k in env for k in ("OBSIDIAN_VAULT_PATH", "OBSIDIAN_CLI_MODE", "OBSIDIAN_REST_API_PORT", "OBSIDIAN_PROJECTS_FOLDER", "OBSIDIAN_REST_API_KEY")):
        print("yes")
except Exception:
    pass
PYEOF
    )
    [ "$has_obsidian_env" = "yes" ] && remove_obsidian_env=true
fi

if [ -f "$HOOK_SH" ] || [ -f "$HOOK_STOP_JS" ] || [ -f "$HOOK_PROMPT_JS" ] || [ -f "$HOOK_AGENT_JS" ] || [ -f "$HOOK_CONTEXT_JS" ]; then
    remove_obsidian_hooks=true
fi

if [ -d "$AGENTS_DIR" ]; then
    for agent_file in "$SCRIPT_DIR/agents/"*.md; do
        filename="$(basename "$agent_file")"
        target="$AGENTS_DIR/$filename"
        if [ -f "$target" ]; then
            to_remove_agents+=("$target")
        fi
    done
fi

if [ -d "$SKILLS_DIR" ]; then
    for skill_dir in "$SCRIPT_DIR/skills/"*/; do
        skill_name="$(basename "$skill_dir")"
        target="$SKILLS_DIR/$skill_name"
        if [ -d "$target" ]; then
            to_remove_skills+=("$target")
        fi
    done
fi

if [ ${#to_remove_agents[@]} -eq 0 ] && [ ${#to_remove_skills[@]} -eq 0 ] \
        && [ "$remove_obsidian_env" = false ] && [ "$remove_obsidian_hooks" = false ]; then
    echo "Nothing to remove -- no matching agents, skills, or Obsidian config found."
    exit 0
fi

echo "The following will be removed:"
echo ""
for path in "${to_remove_agents[@]}"; do echo "  agent: $(basename "$path")"; done
for path in "${to_remove_skills[@]}"; do echo "  skill: $(basename "$path")"; done
[ "$remove_obsidian_env" = true ] && echo "  env:   OBSIDIAN_VAULT_PATH, OBSIDIAN_CLI_MODE, OBSIDIAN_REST_API_PORT, OBSIDIAN_REST_API_KEY, OBSIDIAN_PROJECTS_FOLDER (~/.claude/settings.json)"
[ "$remove_obsidian_hooks" = true ] && echo "  hook:  obsidian hook scripts (~/.claude/scripts/obsidian-{stop,prompt,agent,context}-hook.js)"

echo ""
read -p "Remove these? [y/N] " response

if [ "$response" != "y" ] && [ "$response" != "Y" ]; then
    echo "Cancelled."
    exit 0
fi

echo ""
for path in "${to_remove_agents[@]}"; do
    rm -f "$path"
    echo "  Removed agent: $(basename "$path")"
done
for path in "${to_remove_skills[@]}"; do
    rm -rf "$path"
    echo "  Removed skill: $(basename "$path")"
done

if [ "$remove_obsidian_env" = true ] && [ -f "$SETTINGS" ] && command -v python3 &>/dev/null; then
    python3 - "$SETTINGS" <<'PYEOF'
import json, sys
p = sys.argv[1]
with open(p) as f:
    s = json.load(f)
env = s.get("env", {})
for key in ("OBSIDIAN_VAULT_PATH", "OBSIDIAN_CLI_MODE", "OBSIDIAN_REST_API_PORT", "OBSIDIAN_REST_API_HTTPS", "OBSIDIAN_PROJECTS_FOLDER", "OBSIDIAN_REST_API_KEY"):
    env.pop(key, None)
if not env:
    s.pop("env", None)
with open(p, "w") as f:
    json.dump(s, f, indent=2)
    f.write("\n")
PYEOF
    echo "  Removed env:   OBSIDIAN_VAULT_PATH, OBSIDIAN_CLI_MODE, OBSIDIAN_REST_API_PORT, OBSIDIAN_REST_API_KEY"
fi

if [ "$remove_obsidian_hooks" = true ]; then
    rm -f "$HOOK_SH" "$HOOK_STOP_JS" "$HOOK_PROMPT_JS" "$HOOK_AGENT_JS" "$HOOK_CONTEXT_JS"
    # Remove all Obsidian hook entries and the decisions permission from settings.json
    if [ -f "$SETTINGS" ] && command -v python3 &>/dev/null; then
        python3 - "$SETTINGS" <<'PYEOF'
import json, sys
p = sys.argv[1]
with open(p) as f:
    s = json.load(f)
hooks = s.get("hooks", {})
markers = ['obsidian-stop-hook', 'obsidian-prompt-hook', 'obsidian-agent-hook', 'obsidian-context-hook']
def is_obsidian(entry):
    return isinstance(entry, dict) and any(
        m in h.get('command', '')
        for h in entry.get('hooks', [])
        for m in markers
    )
for key in ("Stop", "SessionEnd", "UserPromptSubmit", "SubagentStop", "SessionStart"):
    old = hooks.get(key, [])
    new = [h for h in old if not is_obsidian(h)]
    if new != old:
        if new:
            hooks[key] = new
        else:
            del hooks[key]
if not hooks:
    s.pop("hooks", None)
allow = s.get("permissions", {}).get("allow", [])
s.get("permissions", {})["allow"] = [a for a in allow if "session-decisions" not in a]
with open(p, "w") as f:
    json.dump(s, f, indent=2)
    f.write("\n")
PYEOF
    fi
    echo "  Removed hook:  obsidian hook scripts and settings entries"
fi

echo ""
echo "${#to_remove_agents[@]} agent(s) and ${#to_remove_skills[@]} skill(s) removed."

echo ""
echo "Note: project-level memory/ directories are not removed -- those live"
echo "in your repositories and are managed like any other project file."
