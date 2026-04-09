#!/usr/bin/env bash
# init-state.sh — Initialize build-state.json for a new bfeature run.
#
# Usage:
#   bash init-state.sh --slug <slug> --idea <idea> [--mode quick|full] \
#                      [--jira-key PROJ-123 --jira-url <url>] \
#                      [--gh-issue 42]
#
# Outputs JSON with the initialized state and computed artifact paths.
# Exits non-zero if git root cannot be found or state already exists.

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

def parse_args(argv):
    args = {}
    i = 0
    while i < len(argv):
        key = argv[i]
        if key in ('--slug', '--idea', '--mode', '--jira-key', '--jira-url', '--gh-issue'):
            if i + 1 >= len(argv):
                print(f"Error: {key} requires a value", file=sys.stderr)
                sys.exit(1)
            args[key.lstrip('-').replace('-', '_')] = argv[i + 1]
            i += 2
        else:
            print(f"Error: unknown argument '{key}'", file=sys.stderr)
            sys.exit(1)
    return args

args = parse_args(sys.argv[1:])

if 'slug' not in args:
    print("Error: --slug is required", file=sys.stderr)
    sys.exit(1)
if 'idea' not in args:
    print("Error: --idea is required", file=sys.stderr)
    sys.exit(1)

root      = git_root()
slug      = args['slug']
idea      = args['idea']
mode      = args.get('mode', 'full')
now       = datetime.now(timezone.utc)
ts        = now.strftime('%Y%m%dT%H')   # e.g. 20260409T14
iso_now   = now.isoformat()

adir   = os.path.join(root, '.claude', '.bfeature-temp')
state_path = os.path.join(adir, 'build-state.json')

if os.path.exists(state_path):
    print(f"Error: build-state.json already exists at {state_path}. Delete it or resume the existing run.", file=sys.stderr)
    sys.exit(1)

os.makedirs(adir, exist_ok=True)

jira_key = args.get('jira_key')
jira_url = args.get('jira_url')
gh_issue = args.get('gh_issue')

first_phase = 'refine' if mode == 'quick' else 'brainstorm'

state = {
    'idea': idea,
    'slug': slug,
    'build_timestamp': ts,
    'mode': mode,
    'phase': first_phase,
    'phase_status': 'in_progress',
    'github_issue': {
        'enabled': gh_issue is not None,
        'number': int(gh_issue) if gh_issue else None,
    },
    'jira': {
        'enabled': jira_key is not None,
        'ticket_key': jira_key,
        'ticket_url': jira_url,
        'pending_questions': None,
    },
    'collect_todos': None,
    'artifacts': {
        'spec': None,
        'plan': None,
        'todo': None,
        'backlog': None,
    },
    'created_at': iso_now,
    'updated_at': iso_now,
}

with open(state_path, 'w') as f:
    json.dump(state, f, indent=2)

prefix = f'{ts}-{slug}'

def artifact(name):
    return os.path.join(adir, f'{prefix}-{name}.md')

print(json.dumps({
    'slug': slug,
    'build_timestamp': ts,
    'mode': mode,
    'phase': first_phase,
    'artifacts_dir': adir,
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
    'github_issue': state['github_issue'],
    'jira':         state['jira'],
}, indent=2))
EOF
