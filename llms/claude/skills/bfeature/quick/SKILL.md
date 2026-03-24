---
name: bfeature-quick
description: Orchestrate a lightweight refine → plan → execute workflow for small changes. Skips spec generation and design review.
disable-model-invocation: false
argument-hint: [idea description, Jira ticket URL, or GH-ISSUE:<number>]
allowed-tools: Read, Write, Grep, Glob, Bash(git *), mcp__*__jira__*
---

Orchestrate a lightweight development workflow for small bugfixes and focused changes. This is the quick-mode variant of `bfeature` — it replaces brainstorm with a lighter `refine` phase and skips spec generation and design review entirely.

Manage state via `.claude/.bfeature-temp/build-state.json` and delegate to existing skills with approval gates between each phase.

## Quick Mode Phase Flow

```
init → refine → plan (from Q&A) → execute → verify → review-impl ⇄ fix → verify (silent) → finalize → done
```

## On Invocation

1. Check if `.claude/.bfeature-temp/build-state.json` exists
2. If it does not exist: start from Phase 0 (init)
3. If it exists: read it and resume:
   - If `worktree_path` is set: use `Bash(cd <worktree_path>)` to switch into the worktree. Do NOT call `EnterWorktree` again.
   - If `phase_status` is `"awaiting_approval"`: ask the user "Paused before [current phase]. Ready to proceed?" — if yes, set `phase_status` to `"in_progress"`, update state, and execute the current phase; if no, exit
   - Otherwise: resume the current phase from where it left off

## Phase 0 — Init

Identical to the full-mode `bfeature` init, except:
- Set `"mode": "quick"` in state
- Set `"phase": "refine"` (not `"brainstorm"`)

Follow the same logic for GitHub issue detection, Jira ticket detection, slug derivation, branch selection, and worktree creation as documented in the main `bfeature/SKILL.md` Phase 0.

Create `.claude/.bfeature-temp/build-state.json` with:

```json
{
  "idea": "$ARGUMENTS",
  "slug": "<slug>",
  "mode": "quick",
  "phase": "refine",
  "phase_status": "in_progress",
  "github_issue": {
    "enabled": false,
    "number": null
  },
  "jira": {
    "enabled": false,
    "ticket_key": null,
    "ticket_url": null,
    "pending_questions": null
  },
  "artifacts": {
    "spec": null,
    "plan": null,
    "todo": null,
    "backlog": null
  },
  "worktree_path": null,
  "created_at": "<current ISO timestamp>",
  "updated_at": "<current ISO timestamp>"
}
```

Proceed to Phase 1.

## Phase 1 — Refine

1. Invoke the `refine` skill **inline** (via Skill tool, not Agent) with the idea from state
   - Runs in the main conversation — user interaction is fully available
   - Saves Q&A to `.claude/.bfeature-temp/<slug>-qa.md`
2. When `.claude/.bfeature-temp/<slug>-qa.md` is detected:
   - Update state: set `phase` to `"plan"`, `phase_status` to `"awaiting_approval"`, `updated_at` to current timestamp
   - Ask the user: "Q&A saved. Ready to proceed to planning?"
   - If yes: set `phase_status` to `"in_progress"`, update state, proceed to Phase 2
   - If no: **Exit** (re-invoke `/bfeature:quick` when ready)

## Phase 2 — Plan

1. Invoke the `plan` skill as an Agent (model: opus)
   - The plan skill reads `mode` from state and uses `<slug>-qa.md` directly (no spec exists in quick mode)
   - Produces `.claude/.bfeature-temp/<slug>-plan.md` + `.claude/.bfeature-temp/<slug>-todo.md`
2. When both files are detected:
   - Update state: set `artifacts.plan` to `"<slug>-plan.md"`, `artifacts.todo` to `"<slug>-todo.md"`, `phase` to `"execute"`, `phase_status` to `"awaiting_approval"`, `updated_at` to current timestamp
   - Ask the user: "Plan written. Ready to start execution?"
   - If yes: proceed to Phase 3
   - If no: **Exit**

## Phase 3 — Execute

Invoke the `do-todo` skill as an Agent (model: sonnet) — it loops internally until all items are checked.

When it completes:
- Update state: `phase` to `"verify"`, `phase_status` to `"awaiting_approval"`
- Ask the user: "All tasks complete. Ready to run quality gates (tests + lint)?"
- If yes: set `phase_status` to `"in_progress"`, update state, proceed to Phase 3.5
- If no: **Exit**

## Phase 3.5 — Verify

Same as full-mode Phase 4.5. Invoke the `verify` skill as an Agent (model: sonnet).

When tests and lint are green:
- Update state: `phase` to `"review-impl"`, `phase_status` to `"awaiting_approval"`
- Ask the user: "Quality gates passed. Ready to proceed to implementation review?"

## Phase 4 — Review Implementation

Same as full-mode Phase 5. Run up to 3 analyze → fix cycles using `review-impl` and `review-impl/fix`.

The review-impl skill reads `mode` from state and compares against Q&A + plan (not spec).

## Phase 5 — Finalize

Same as full-mode Phase 6. Commit, push, create PR, cleanup.

Fewer ephemeral files to clean (no spec, no design report).

## Model Routing

| Sub-skill | Invocation | Model |
|-----------|------------|-------|
| `refine` | Skill tool (inline) | — |
| `plan` | Agent tool | opus |
| `do-todo` | Agent tool | sonnet |
| `verify` | Agent tool | sonnet |
| `review-impl` | Agent tool | opus |
| `review-impl/fix` | Agent tool | sonnet |
| `finalize` (Phase 5) | Agent tool | sonnet |

Here is the idea:
$ARGUMENTS
