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

# Detect JSON tool: prefer python3/python, fall back to node.
# Liveness-test each candidate — Windows ships a python3 Store stub in PATH
# that exits non-zero when called non-interactively, so we cannot trust
# command -v alone.
json_tool=""
_try_json_tool() {
    command -v "$1" &>/dev/null || return 1
    case "$1" in
        python*) "$1" -c 'import sys; sys.exit(0)' &>/dev/null 2>&1 || return 1 ;;
        node)    "$1" -e  'process.exit(0)'         &>/dev/null 2>&1 || return 1 ;;
    esac
    json_tool="$1"
}
_try_json_tool python3 || _try_json_tool python || _try_json_tool node || true

if [ -z "$json_tool" ]; then
    echo "  WARNING: python3 or node is required for Obsidian setup — neither found."
    echo "  Install either and re-run install.sh to complete Obsidian setup."
else
    # Read existing vault path from settings.json (empty if not previously configured)
    if [ "$json_tool" = "node" ]; then
        current_vault="$(node -e "
const fs=require('fs'),os=require('os'),path=require('path');
const p=path.join(os.homedir(),'.claude','settings.json');
try{const s=JSON.parse(fs.readFileSync(p,'utf8'));process.stdout.write((s.env&&s.env.OBSIDIAN_VAULT_PATH)||'');}catch(e){}
" 2>/dev/null || true)"
    else
        current_vault="$("$json_tool" - <<'PYEOF' 2>/dev/null || true
import json, os, sys
p = os.path.expanduser("~/.claude/settings.json")
try:
    s = json.load(open(p))
    sys.stdout.write(s.get("env", {}).get("OBSIDIAN_VAULT_PATH", ""))
except Exception:
    pass
PYEOF
)"
    fi

    # Read existing projects folder (empty string if not configured)
    if [ "$json_tool" = "node" ]; then
        current_projects_folder="$(node -e "
const fs=require('fs'),os=require('os'),path=require('path');
const p=path.join(os.homedir(),'.claude','settings.json');
try{const s=JSON.parse(fs.readFileSync(p,'utf8'));process.stdout.write((s.env&&s.env.OBSIDIAN_PROJECTS_FOLDER)||'');}catch(e){}
" 2>/dev/null || true)"
    else
        current_projects_folder="$("$json_tool" - <<'PYEOF' 2>/dev/null || true
import json, os, sys
p = os.path.expanduser("~/.claude/settings.json")
try:
    s = json.load(open(p))
    sys.stdout.write(s.get("env", {}).get("OBSIDIAN_PROJECTS_FOLDER", ""))
except Exception:
    pass
PYEOF
)"
    fi

    obsidian_setup=false
    vault_path=""
    projects_folder=""

    # Read existing REST API key (empty if not configured)
    if [ "$json_tool" = "node" ]; then
        current_api_key="$(node -e "
const fs=require('fs'),os=require('os'),path=require('path');
const p=path.join(os.homedir(),'.claude','settings.json');
try{const s=JSON.parse(fs.readFileSync(p,'utf8'));process.stdout.write((s.env&&s.env.OBSIDIAN_REST_API_KEY)||'');}catch(e){}
" 2>/dev/null || true)"
    else
        current_api_key="$("$json_tool" - <<'PYEOF' 2>/dev/null || true
import json, os, sys
p = os.path.expanduser("~/.claude/settings.json")
try:
    s = json.load(open(p))
    sys.stdout.write(s.get("env", {}).get("OBSIDIAN_REST_API_KEY", ""))
except Exception:
    pass
PYEOF
)"
    fi

    if [ -n "$current_vault" ]; then
        echo "Obsidian integration is active (vault: $current_vault)"
        read -rp "  Keep Obsidian integration? [Y/n] " keep_response
        if [ "$keep_response" = "n" ] || [ "$keep_response" = "N" ]; then
            # Remove all Obsidian env vars and all hook entries from settings.json
            if [ "$json_tool" = "node" ]; then
                node <<'JSEOF'
const fs=require('fs'),os=require('os'),path=require('path');
const p=path.join(os.homedir(),'.claude','settings.json');
const s=fs.existsSync(p)?JSON.parse(fs.readFileSync(p,'utf8')):{};
if(s.env){['OBSIDIAN_VAULT_PATH','OBSIDIAN_CLI_MODE','OBSIDIAN_REST_API_PORT','OBSIDIAN_REST_API_HTTPS','OBSIDIAN_PROJECTS_FOLDER','OBSIDIAN_REST_API_KEY'].forEach(k=>delete s.env[k]);}
const obsidianMarkers=['obsidian-stop-hook','obsidian-prompt-hook','obsidian-agent-hook'];
const isObsidian=e=>e&&Array.isArray(e.hooks)&&e.hooks.some(h=>obsidianMarkers.some(m=>h.command&&h.command.includes(m)));
['Stop','SessionEnd','UserPromptSubmit','SubagentStop'].forEach(k=>{
  if(s.hooks&&s.hooks[k]){s.hooks[k]=s.hooks[k].filter(e=>!isObsidian(e));if(!s.hooks[k].length)delete s.hooks[k];}
});
if(s.permissions&&s.permissions.allow){
  s.permissions.allow=s.permissions.allow.filter(p=>!p.includes('session-decisions'));
  if(!s.permissions.allow.length)delete s.permissions.allow;
}
fs.writeFileSync(p,JSON.stringify(s,null,2)+'\n');
JSEOF
            else
                "$json_tool" - <<'PYEOF'
import json, os
p = os.path.expanduser("~/.claude/settings.json")
s = json.load(open(p)) if os.path.exists(p) else {}
for k in ['OBSIDIAN_VAULT_PATH','OBSIDIAN_CLI_MODE','OBSIDIAN_REST_API_PORT','OBSIDIAN_REST_API_HTTPS','OBSIDIAN_PROJECTS_FOLDER','OBSIDIAN_REST_API_KEY']:
    s.get('env', {}).pop(k, None)
markers = ['obsidian-stop-hook', 'obsidian-prompt-hook', 'obsidian-agent-hook']
def is_obsidian(e):
    return any(m in h.get('command', '') for h in e.get('hooks', []) for m in markers)
for key in ('Stop', 'SessionEnd', 'UserPromptSubmit', 'SubagentStop'):
    if key in s.get('hooks', {}):
        s['hooks'][key] = [e for e in s['hooks'][key] if not is_obsidian(e)]
        if not s['hooks'][key]:
            del s['hooks'][key]
allow = s.get('permissions', {}).get('allow', [])
s.get('permissions', {})['allow'] = [a for a in allow if 'session-decisions' not in a]
with open(p, 'w') as f:
    json.dump(s, f, indent=2)
    f.write('\n')
PYEOF
            fi
            echo "  [rm] Obsidian integration removed from ~/.claude/settings.json"
        else
            # Confirm or update the vault path (Enter keeps the current value)
            read -rp "  Vault path [$current_vault]: " new_vault
            vault_path="${new_vault:-$current_vault}"
            _pf_default="${current_projects_folder:-Claude/Projects}"
            read -rp "  Projects folder in vault [$_pf_default]: " new_pf
            projects_folder="${new_pf:-$_pf_default}"
            if [ -n "$current_api_key" ]; then
                read -rp "  REST API key [keep existing, blank to remove]: " new_key
            else
                read -rp "  REST API key (optional, leave blank for filesystem writes): " new_key
            fi
            rest_api_key="${new_key:-$current_api_key}"
            obsidian_setup=true
        fi
    else
        read -rp "Set up Obsidian vault integration? [y/N] " obsidian_response
        if [ "$obsidian_response" = "y" ] || [ "$obsidian_response" = "Y" ]; then
            read -rp "  Obsidian vault path (absolute path to your vault directory): " vault_path
            read -rp "  Projects folder in vault [Claude/Projects]: " projects_folder
            projects_folder="${projects_folder:-Claude/Projects}"
            read -rp "  REST API key (optional, leave blank for filesystem writes): " rest_api_key
            obsidian_setup=true
        fi
    fi

    if [ "$obsidian_setup" = "true" ] && [ -n "$vault_path" ]; then
        # Write OBSIDIAN_VAULT_PATH
        if [ "$json_tool" = "node" ]; then
            node - "$vault_path" <<'JSEOF'
const fs=require('fs'),os=require('os'),path=require('path');
const vp=path.resolve(process.argv[2].replace(/^~/,os.homedir()));
const p=path.join(os.homedir(),'.claude','settings.json');
const s=fs.existsSync(p)?JSON.parse(fs.readFileSync(p,'utf8')):{};
if(!s.env)s.env={};s.env.OBSIDIAN_VAULT_PATH=vp;
fs.mkdirSync(path.dirname(p),{recursive:true});
fs.writeFileSync(p,JSON.stringify(s,null,2)+'\n');
JSEOF
        else
            "$json_tool" - "$vault_path" <<'PYEOF'
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
        fi
        if [ $? -ne 0 ]; then
            echo "  ERROR: failed to update ~/.claude/settings.json"
        fi
        echo "  [ok] env:    OBSIDIAN_VAULT_PATH=$vault_path"

        # Set CLI mode based on REST API key presence
        # Key present = rest-api mode (port 27124, HTTPS); absent = filesystem
        if [ -n "${rest_api_key:-}" ]; then
            cli_mode="rest-api"
            rest_port="27124"
            rest_https="true"
        else
            cli_mode="filesystem"
            rest_port=""
            rest_https=""
        fi

        # Write CLI mode env vars and REST API key
        if [ "$json_tool" = "node" ]; then
            node - "$cli_mode" "$rest_port" "$rest_https" "${rest_api_key:-}" <<'JSEOF'
const fs=require('fs'),os=require('os'),path=require('path');
const p=path.join(os.homedir(),'.claude','settings.json');
const s=fs.existsSync(p)?JSON.parse(fs.readFileSync(p,'utf8')):{};
if(!s.env)s.env={};
const [,, mode, port, https_, key] = process.argv;
s.env.OBSIDIAN_CLI_MODE=mode;
if(mode==='rest-api'){
  s.env.OBSIDIAN_REST_API_PORT=port;
  s.env.OBSIDIAN_REST_API_HTTPS=https_;
  if(key)s.env.OBSIDIAN_REST_API_KEY=key; else delete s.env.OBSIDIAN_REST_API_KEY;
}else{
  delete s.env.OBSIDIAN_REST_API_PORT;
  delete s.env.OBSIDIAN_REST_API_HTTPS;
  delete s.env.OBSIDIAN_REST_API_KEY;
}
fs.writeFileSync(p,JSON.stringify(s,null,2)+'\n');
JSEOF
        else
            "$json_tool" - "$cli_mode" "$rest_port" "$rest_https" "${rest_api_key:-}" <<'PYEOF'
import json, os, sys
mode, port, https_, key = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
p = os.path.expanduser("~/.claude/settings.json")
s = json.load(open(p)) if os.path.exists(p) else {}
s.setdefault("env", {})["OBSIDIAN_CLI_MODE"] = mode
if mode == "rest-api":
    s["env"]["OBSIDIAN_REST_API_PORT"] = port
    s["env"]["OBSIDIAN_REST_API_HTTPS"] = https_
    if key:
        s["env"]["OBSIDIAN_REST_API_KEY"] = key
    else:
        s["env"].pop("OBSIDIAN_REST_API_KEY", None)
else:
    for k in ["OBSIDIAN_REST_API_PORT", "OBSIDIAN_REST_API_HTTPS", "OBSIDIAN_REST_API_KEY"]:
        s.get("env", {}).pop(k, None)
os.makedirs(os.path.dirname(p), exist_ok=True)
with open(p, "w") as f:
    json.dump(s, f, indent=2)
    f.write("\n")
PYEOF
        fi
        if [ $? -ne 0 ]; then
            echo "  ERROR: failed to update ~/.claude/settings.json"
        fi
        if [ "$cli_mode" = "rest-api" ]; then
            echo "  [ok] env:    OBSIDIAN_CLI_MODE=rest-api (port ${rest_port}, HTTPS=${rest_https}, API key set)"
        else
            echo "  [ok] env:    OBSIDIAN_CLI_MODE=filesystem (no REST API key)"
        fi

        # Write or clear OBSIDIAN_PROJECTS_FOLDER
        if [ -n "$projects_folder" ]; then
            if [ "$json_tool" = "node" ]; then
                node - "$projects_folder" <<'JSEOF'
const fs=require('fs'),os=require('os'),path=require('path');
const p=path.join(os.homedir(),'.claude','settings.json');
const s=fs.existsSync(p)?JSON.parse(fs.readFileSync(p,'utf8')):{};
if(!s.env)s.env={};s.env.OBSIDIAN_PROJECTS_FOLDER=process.argv[2];
fs.writeFileSync(p,JSON.stringify(s,null,2)+'\n');
JSEOF
            else
                "$json_tool" - "$projects_folder" <<'PYEOF'
import json, os, sys
p = os.path.expanduser("~/.claude/settings.json")
s = json.load(open(p)) if os.path.exists(p) else {}
s.setdefault("env", {})["OBSIDIAN_PROJECTS_FOLDER"] = sys.argv[1]
with open(p, "w") as f:
    json.dump(s, f, indent=2)
    f.write("\n")
PYEOF
            fi
            if [ $? -ne 0 ]; then
                echo "  ERROR: failed to update ~/.claude/settings.json"
            fi
            echo "  [ok] env:    OBSIDIAN_PROJECTS_FOLDER=$projects_folder"
        else
            # User left it blank — write the default so the env var is always explicit
            projects_folder="Claude/Projects"
            if [ "$json_tool" = "node" ]; then
                node - "$projects_folder" <<'JSEOF'
const fs=require('fs'),os=require('os'),path=require('path');
const p=path.join(os.homedir(),'.claude','settings.json');
const s=fs.existsSync(p)?JSON.parse(fs.readFileSync(p,'utf8')):{};
if(!s.env)s.env={};s.env.OBSIDIAN_PROJECTS_FOLDER=process.argv[2];
fs.writeFileSync(p,JSON.stringify(s,null,2)+'\n');
JSEOF
            else
                "$json_tool" - "$projects_folder" <<'PYEOF'
import json, os, sys
p = os.path.expanduser("~/.claude/settings.json")
s = json.load(open(p)) if os.path.exists(p) else {}
s.setdefault("env", {})["OBSIDIAN_PROJECTS_FOLDER"] = sys.argv[1]
with open(p, "w") as f:
    json.dump(s, f, indent=2)
    f.write("\n")
PYEOF
            fi
            echo "  [ok] env:    OBSIDIAN_PROJECTS_FOLDER=$projects_folder (default)"
        fi

        # Install hook scripts (stop, prompt journal, agent tracker)
        mkdir -p "$HOME/.claude/scripts"
        cp "$SCRIPT_DIR/scripts/obsidian-stop-hook.js"   "$HOME/.claude/scripts/"
        cp "$SCRIPT_DIR/scripts/obsidian-prompt-hook.js" "$HOME/.claude/scripts/"
        cp "$SCRIPT_DIR/scripts/obsidian-agent-hook.js"  "$HOME/.claude/scripts/"
        echo "  [ok] hook:   obsidian hook scripts installed (stop, prompt, agent)"

        # Build hook commands. Pure Node.js — works identically on Windows and macOS/Linux.
        # Use `type -P` to find the actual node binary; `command -v` may return an alias.
        node_posix="$(type -P node 2>/dev/null || true)"
        if [ -z "$node_posix" ]; then
            _cv="$(command -v node 2>/dev/null || true)"
            case "$_cv" in /*) node_posix="$_cv" ;; esac
        fi

        if [ -n "$node_posix" ]; then
            if command -v cygpath &>/dev/null; then
                node_cmd="$(cygpath -w "$node_posix")"
                stop_js="$(cygpath -w "$HOME/.claude/scripts/obsidian-stop-hook.js")"
                prompt_js="$(cygpath -w "$HOME/.claude/scripts/obsidian-prompt-hook.js")"
                agent_js="$(cygpath -w "$HOME/.claude/scripts/obsidian-agent-hook.js")"
            else
                node_cmd="$node_posix"
                stop_js="$HOME/.claude/scripts/obsidian-stop-hook.js"
                prompt_js="$HOME/.claude/scripts/obsidian-prompt-hook.js"
                agent_js="$HOME/.claude/scripts/obsidian-agent-hook.js"
            fi
            stop_cmd="\"${node_cmd}\" \"${stop_js}\""
            session_end_cmd="\"${node_cmd}\" \"${stop_js}\" \"SessionEnd\""
            prompt_cmd="\"${node_cmd}\" \"${prompt_js}\""
            agent_cmd="\"${node_cmd}\" \"${agent_js}\""
        else
            echo "  WARNING: node not found — Obsidian hooks not registered."
            echo "           Install Node.js and re-run install.sh to enable auto-logging."
            stop_cmd=""
        fi

        # Register all four hooks, replacing any existing obsidian entries.
        # Stop/SessionEnd: auto-log on every response and at session end.
        # UserPromptSubmit: journal user prompts for "What was discussed" section.
        # SubagentStop: track which agents completed for "Agents invoked" section.
        if [ -n "$stop_cmd" ]; then
        if [ "$json_tool" = "node" ]; then
            node - "$stop_cmd" "$session_end_cmd" "$prompt_cmd" "$agent_cmd" <<'JSEOF'
const fs=require('fs'),os=require('os'),path=require('path');
const p=path.join(os.homedir(),'.claude','settings.json');
const s=fs.existsSync(p)?JSON.parse(fs.readFileSync(p,'utf8')):{};
if(!s.hooks)s.hooks={};
const [,, stopCmd, sessionEndCmd, promptCmd, agentCmd]=process.argv;
const setHook=(k,cmd,marker)=>{
  s.hooks[k]=(s.hooks[k]||[]).filter(e=>!(e&&Array.isArray(e.hooks)&&e.hooks.some(h=>h.command&&h.command.includes(marker))));
  s.hooks[k].push({hooks:[{type:'command',command:cmd}]});
};
setHook('Stop',       stopCmd,       'obsidian-stop-hook');
setHook('SessionEnd', sessionEndCmd, 'obsidian-stop-hook');
setHook('UserPromptSubmit', promptCmd, 'obsidian-prompt-hook');
setHook('SubagentStop',     agentCmd,  'obsidian-agent-hook');
if(!s.permissions)s.permissions={};
if(!s.permissions.allow)s.permissions.allow=[];
const decPerm='Bash(echo *session-decisions*)';
if(!s.permissions.allow.includes(decPerm))s.permissions.allow.push(decPerm);
fs.writeFileSync(p,JSON.stringify(s,null,2)+'\n');
JSEOF
        else
            "$json_tool" - "$stop_cmd" "$session_end_cmd" "$prompt_cmd" "$agent_cmd" <<'PYEOF'
import json, os, sys
p = os.path.expanduser("~/.claude/settings.json")
s = json.load(open(p)) if os.path.exists(p) else {}
hooks = s.setdefault("hooks", {})
stop_cmd, session_end_cmd, prompt_cmd, agent_cmd = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
def set_hook(key, cmd, marker):
    entries = [e for e in hooks.get(key, []) if not any(marker in h.get('command', '') for h in e.get('hooks', []))]
    entries.append({"hooks": [{"type": "command", "command": cmd}]})
    hooks[key] = entries
set_hook("Stop",            stop_cmd,        "obsidian-stop-hook")
set_hook("SessionEnd",      session_end_cmd, "obsidian-stop-hook")
set_hook("UserPromptSubmit", prompt_cmd,     "obsidian-prompt-hook")
set_hook("SubagentStop",    agent_cmd,       "obsidian-agent-hook")
perms = s.setdefault("permissions", {})
allow = perms.setdefault("allow", [])
dec_perm = "Bash(echo *session-decisions*)"
if dec_perm not in allow:
    allow.append(dec_perm)
os.makedirs(os.path.dirname(p), exist_ok=True)
with open(p, "w") as f:
    json.dump(s, f, indent=2)
    f.write("\n")
PYEOF
        fi
        if [ $? -ne 0 ]; then
            echo "  ERROR: failed to update ~/.claude/settings.json"
        fi
        echo "  [ok] hook:   Stop, SessionEnd, UserPromptSubmit, SubagentStop hooks registered"
        fi
    elif [ "$obsidian_setup" = "true" ] && [ -z "$vault_path" ]; then
        echo "  [skip] No vault path provided — skipping Obsidian setup."
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
