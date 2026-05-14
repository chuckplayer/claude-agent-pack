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

    if [ -n "$current_vault" ]; then
        echo "Obsidian integration is active (vault: $current_vault)"
        read -rp "  Keep Obsidian integration? [Y/n] " keep_response
        if [ "$keep_response" = "n" ] || [ "$keep_response" = "N" ]; then
            # Remove all Obsidian env vars and the Stop hook entry from settings.json
            if [ "$json_tool" = "node" ]; then
                node <<'JSEOF'
const fs=require('fs'),os=require('os'),path=require('path');
const p=path.join(os.homedir(),'.claude','settings.json');
const s=fs.existsSync(p)?JSON.parse(fs.readFileSync(p,'utf8')):{};
if(s.env){['OBSIDIAN_VAULT_PATH','OBSIDIAN_CLI_MODE','OBSIDIAN_REST_API_PORT','OBSIDIAN_REST_API_HTTPS','OBSIDIAN_PROJECTS_FOLDER'].forEach(k=>delete s.env[k]);}
if(s.hooks&&s.hooks.Stop){
  s.hooks.Stop=s.hooks.Stop.filter(e=>!(e&&Array.isArray(e.hooks)&&e.hooks.some(h=>h.command&&h.command.includes('obsidian-stop-hook'))));
  if(!s.hooks.Stop.length)delete s.hooks.Stop;
}
fs.writeFileSync(p,JSON.stringify(s,null,2)+'\n');
JSEOF
            else
                "$json_tool" - <<'PYEOF'
import json, os
p = os.path.expanduser("~/.claude/settings.json")
s = json.load(open(p)) if os.path.exists(p) else {}
for k in ['OBSIDIAN_VAULT_PATH','OBSIDIAN_CLI_MODE','OBSIDIAN_REST_API_PORT','OBSIDIAN_REST_API_HTTPS','OBSIDIAN_PROJECTS_FOLDER']:
    s.get('env', {}).pop(k, None)
if 'hooks' in s and 'Stop' in s['hooks']:
    s['hooks']['Stop'] = [
        e for e in s['hooks']['Stop']
        if not any('obsidian-stop-hook' in h.get('command', '') for h in e.get('hooks', []))
    ]
    if not s['hooks']['Stop']:
        del s['hooks']['Stop']
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
            if [ -n "$current_projects_folder" ]; then
                read -rp "  Projects folder in vault [$current_projects_folder]: " new_pf
            else
                read -rp "  Projects folder in vault (blank for Claude/<repo> layout): " new_pf
            fi
            projects_folder="${new_pf:-$current_projects_folder}"
            obsidian_setup=true
        fi
    else
        read -rp "Set up Obsidian vault integration? [y/N] " obsidian_response
        if [ "$obsidian_response" = "y" ] || [ "$obsidian_response" = "Y" ]; then
            read -rp "  Obsidian vault path (absolute path to your vault directory): " vault_path
            read -rp "  Projects folder in vault (blank for Claude/<repo> layout): " projects_folder
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

        # Detect CLI mode — probe HTTP then HTTPS on ports 27123 and 27124
        cli_mode="filesystem"
        rest_port=27123
        rest_https="false"
        if command -v curl &>/dev/null; then
            for probe_port in 27123 27124; do
                if curl -s --max-time 1 "http://127.0.0.1:${probe_port}/" &>/dev/null 2>&1; then
                    cli_mode="rest-api"; rest_port=$probe_port; rest_https="false"; break
                elif curl -sk --max-time 1 "https://127.0.0.1:${probe_port}/" &>/dev/null 2>&1; then
                    cli_mode="rest-api"; rest_port=$probe_port; rest_https="true"; break
                fi
            done
        fi

        # Write CLI mode env vars
        if [ "$json_tool" = "node" ]; then
            node - "$cli_mode" "$rest_port" "$rest_https" <<'JSEOF'
const fs=require('fs'),os=require('os'),path=require('path');
const p=path.join(os.homedir(),'.claude','settings.json');
const s=fs.existsSync(p)?JSON.parse(fs.readFileSync(p,'utf8')):{};
if(!s.env)s.env={};
s.env.OBSIDIAN_CLI_MODE=process.argv[2];
if(process.argv[2]==='rest-api'){s.env.OBSIDIAN_REST_API_PORT=process.argv[3];s.env.OBSIDIAN_REST_API_HTTPS=process.argv[4];}
else{delete s.env.OBSIDIAN_REST_API_PORT;delete s.env.OBSIDIAN_REST_API_HTTPS;}
fs.writeFileSync(p,JSON.stringify(s,null,2)+'\n');
JSEOF
        else
            "$json_tool" - "$cli_mode" "$rest_port" "$rest_https" <<'PYEOF'
import json, os, sys
port = int(sys.argv[2])
assert 1 <= port <= 65535, f"Invalid port: {port}"
p = os.path.expanduser("~/.claude/settings.json")
s = json.load(open(p)) if os.path.exists(p) else {}
s.setdefault("env", {})["OBSIDIAN_CLI_MODE"] = sys.argv[1]
if sys.argv[1] == "rest-api":
    s["env"]["OBSIDIAN_REST_API_PORT"] = sys.argv[2]
    s["env"]["OBSIDIAN_REST_API_HTTPS"] = sys.argv[3]
else:
    for k in ["OBSIDIAN_REST_API_PORT", "OBSIDIAN_REST_API_HTTPS"]:
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
            echo "  [ok] env:    OBSIDIAN_CLI_MODE=rest-api (Local REST API on port ${rest_port}, HTTPS=${rest_https})"
        else
            echo "  [ok] env:    OBSIDIAN_CLI_MODE=filesystem"
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
            # Clear the key if it was previously set and the user blanked it
            if [ -n "$current_projects_folder" ]; then
                if [ "$json_tool" = "node" ]; then
                    node <<'JSEOF'
const fs=require('fs'),os=require('os'),path=require('path');
const p=path.join(os.homedir(),'.claude','settings.json');
const s=fs.existsSync(p)?JSON.parse(fs.readFileSync(p,'utf8')):{};
if(s.env)delete s.env.OBSIDIAN_PROJECTS_FOLDER;
fs.writeFileSync(p,JSON.stringify(s,null,2)+'\n');
JSEOF
                else
                    "$json_tool" <<'PYEOF'
import json, os
p = os.path.expanduser("~/.claude/settings.json")
s = json.load(open(p)) if os.path.exists(p) else {}
s.get("env", {}).pop("OBSIDIAN_PROJECTS_FOLDER", None)
with open(p, "w") as f:
    json.dump(s, f, indent=2)
    f.write("\n")
PYEOF
                fi
                echo "  [rm] env:    OBSIDIAN_PROJECTS_FOLDER (cleared — using Claude/<repo> layout)"
            fi
        fi

        # Install hook script
        mkdir -p "$HOME/.claude/scripts"
        cp "$SCRIPT_DIR/scripts/obsidian-stop-hook.js" "$HOME/.claude/scripts/"
        echo "  [ok] hook:   obsidian-stop-hook.js installed"

        # Build hook command. The hook is pure Node.js — no bash dependency — so it
        # works identically on Windows and macOS/Linux without path or fork issues.
        # On Windows we need Windows-format paths (cygpath -w); everywhere else we
        # use the POSIX path straight from command -v.
        hook_cmd=""
        if command -v node &>/dev/null; then
            if command -v cygpath &>/dev/null; then
                node_cmd="$(cygpath -w "$(command -v node)")"
                js_cmd="$(cygpath -w "$HOME/.claude/scripts/obsidian-stop-hook.js")"
            else
                node_cmd="$(command -v node)"
                js_cmd="$HOME/.claude/scripts/obsidian-stop-hook.js"
            fi
            hook_cmd="\"${node_cmd}\" \"${js_cmd}\""
        else
            echo "  WARNING: node not found — Obsidian Stop hook not registered."
            echo "           Install Node.js and re-run install.sh to enable auto-logging."
        fi

        # Replace any existing obsidian Stop hook (handles path format changes across
        # installs) then write the canonical entry.
        if [ -n "$hook_cmd" ]; then
        if [ "$json_tool" = "node" ]; then
            node - "$hook_cmd" <<'JSEOF'
const fs=require('fs'),os=require('os'),path=require('path');
const p=path.join(os.homedir(),'.claude','settings.json');
const s=fs.existsSync(p)?JSON.parse(fs.readFileSync(p,'utf8')):{};
if(!s.hooks)s.hooks={};
s.hooks.Stop=s.hooks.Stop||[];
s.hooks.Stop=s.hooks.Stop.filter(e=>!(e&&Array.isArray(e.hooks)&&e.hooks.some(h=>h.command&&h.command.includes('obsidian-stop-hook'))));
s.hooks.Stop.push({hooks:[{type:'command',command:process.argv[2]}]});
fs.writeFileSync(p,JSON.stringify(s,null,2)+'\n');
JSEOF
        else
            "$json_tool" - "$hook_cmd" <<'PYEOF'
import json, os, sys
p = os.path.expanduser("~/.claude/settings.json")
s = json.load(open(p)) if os.path.exists(p) else {}
hooks = s.setdefault("hooks", {})
stop_hooks = hooks.get("Stop", [])
cmd = sys.argv[1]
stop_hooks = [
    e for e in stop_hooks
    if not any('obsidian-stop-hook' in h.get('command', '') for h in e.get('hooks', []))
]
stop_hooks.append({"hooks": [{"type": "command", "command": cmd}]})
hooks["Stop"] = stop_hooks
with open(p, "w") as f:
    json.dump(s, f, indent=2)
    f.write("\n")
PYEOF
        fi
        if [ $? -ne 0 ]; then
            echo "  ERROR: failed to update ~/.claude/settings.json"
        fi
        echo "  [ok] hook:   Stop hook registered in ~/.claude/settings.json"
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
