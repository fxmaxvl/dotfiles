#!/usr/bin/env bash
# state-ops.sh — Read or update build-state.json.
#
# Usage:
#   bash state-ops.sh                          # read: output state + computed artifact paths as JSON
#   bash state-ops.sh key=value [key2=value2]  # update: set fields, auto-bumps updated_at
#
# Supports dot notation for nested fields:
#   phase=execute
#   phase_status=in_progress
#   artifacts.plan=20260409T14-dark-mode-plan.md
#   collect_todos=true
#   jira.enabled=true
#
# Boolean values (true/false) and null are written as JSON primitives, not strings.

set -euo pipefail

python3 - "$@" << 'EOF'
import json
import os
import subprocess
import sys
from datetime import datetime, timezone

def git_root():
    r = subprocess.run(['git', 'rev-parse', '--show-toplevel'], capture_output=True, text=True)
    if r.returncode != 0:
        print("Error: not inside a git repository", file=sys.stderr)
        sys.exit(1)
    return r.stdout.strip()

def set_nested(obj, dotted_key, value):
    keys = dotted_key.split('.')
    for key in keys[:-1]:
        if key not in obj or not isinstance(obj[key], dict):
            obj[key] = {}
        obj = obj[key]
    obj[keys[-1]] = value

def parse_value(raw):
    if raw == 'true':  return True
    if raw == 'false': return False
    if raw == 'null':  return None
    return raw

root = git_root()
state_path = os.path.join(root, '.claude', '.bfeature-temp', 'build-state.json')

if not os.path.exists(state_path):
    print(json.dumps({'error': f'build-state.json not found at {state_path}'}), file=sys.stderr)
    sys.exit(1)

with open(state_path) as f:
    state = json.load(f)

args = sys.argv[1:]  # argv[0] is the '-' placeholder from bash heredoc

if not args:
    # Read mode — output state + computed artifact paths
    slug = state['slug']
    ts   = state['build_timestamp']
    adir = os.path.join(root, '.claude', '.bfeature-temp')
    prefix = f'{ts}-{slug}'

    def artifact(name):
        return os.path.join(adir, f'{prefix}-{name}.md')

    print(json.dumps({
        'slug':           slug,
        'build_timestamp': ts,
        'mode':           state['mode'],
        'phase':          state['phase'],
        'phase_status':   state['phase_status'],
        'artifacts_dir':  adir,
        'artifact_prefix': prefix,
        'paths': {
            'spec':          artifact('spec'),
            'qa':            artifact('qa'),
            'plan':          artifact('plan'),
            'todo':          artifact('todo'),
            'design_report': artifact('design-report'),
            'impl_report':   artifact('impl-report'),
            'backlog':       artifact('backlog'),
            'deployment':    artifact('deployment'),
        },
        'github_issue': state.get('github_issue', {}),
        'jira':         state.get('jira', {}),
    }, indent=2))

else:
    # Update mode — apply key=value pairs
    for arg in args:
        if '=' not in arg:
            print(f"Error: invalid argument '{arg}' — expected key=value", file=sys.stderr)
            sys.exit(1)
        key, _, raw = arg.partition('=')
        set_nested(state, key.strip(), parse_value(raw))

    state['updated_at'] = datetime.now(timezone.utc).isoformat()

    with open(state_path, 'w') as f:
        json.dump(state, f, indent=2)

    print(f"Updated: {', '.join(args)}")
EOF
