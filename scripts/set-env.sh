#!/usr/bin/env bash
# Set one or more env vars in ~/.claude/settings.json's "env" object.
# Reusable by any skill that needs to persist config across sessions without
# depending on the user's shell profile (which varies by OS/shell) --
# settings.json lives at the same relative path on macOS, Linux, and Windows.
#
# Usage: scripts/set-env.sh KEY=VALUE [KEY=VALUE ...]
set -euo pipefail

if [ "$#" -eq 0 ]; then
    echo "Usage: $0 KEY=VALUE [KEY=VALUE ...]" >&2
    exit 1
fi

# Detect JSON tool: prefer python3/python, fall back to node.
# Liveness-test each candidate -- Windows ships a python3 Store stub in PATH
# that exits non-zero when called non-interactively, so we cannot trust
# command -v alone. (Mirrors the detection in install.sh.)
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
    echo "ERROR: python3 or node is required to update settings.json -- neither found." >&2
    exit 1
fi

for pair in "$@"; do
    key="${pair%%=*}"
    value="${pair#*=}"
    if [ "$key" = "$pair" ]; then
        echo "ERROR: '$pair' is not in KEY=VALUE form" >&2
        exit 1
    fi

    if [ "$json_tool" = "node" ]; then
        node - "$key" "$value" <<'JSEOF'
const fs=require('fs'),os=require('os'),path=require('path');
const [key,value]=process.argv.slice(2);
const p=path.join(os.homedir(),'.claude','settings.json');
const s=fs.existsSync(p)?JSON.parse(fs.readFileSync(p,'utf8')):{};
if(!s.env)s.env={};
s.env[key]=value;
fs.mkdirSync(path.dirname(p),{recursive:true});
fs.writeFileSync(p,JSON.stringify(s,null,2)+'\n');
JSEOF
    else
        "$json_tool" - "$key" "$value" <<'PYEOF'
import json, os, sys
key, value = sys.argv[1], sys.argv[2]
p = os.path.expanduser("~/.claude/settings.json")
s = json.load(open(p)) if os.path.exists(p) else {}
s.setdefault("env", {})[key] = value
os.makedirs(os.path.dirname(p), exist_ok=True)
with open(p, "w") as f:
    json.dump(s, f, indent=2)
    f.write("\n")
PYEOF
    fi

    echo "[ok] env: $key=$value"
done
