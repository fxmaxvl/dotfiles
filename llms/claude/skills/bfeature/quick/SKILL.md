---
name: bfeature-quick
description: Orchestrate a lightweight refine → plan → execute workflow for small changes. Skips spec generation and design review.
disable-model-invocation: false
argument-hint: [idea description, Jira ticket URL, or GH-ISSUE:<number>]
allowed-tools: Read, Write, Grep, Glob, Bash(git *), Bash(gh *), mcp__*__jira__*
---

Orchestrate a lightweight development workflow for small bugfixes and focused changes. This is the quick-mode variant of `bfeature` — it replaces brainstorm with a lighter `refine` phase and skips spec generation and design review entirely.

Manage state via `.claude/.bfeature-temp/build-state.json` and delegate to existing skills with approval gates between each phase.

## Quick Mode Phase Flow

```
init → refine → plan (from Q&A) → execute → verify → review-impl ⇄ fix → verify (silent) → finalize → cleanup → done
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
   - If yes: set `phase_status` to `"in_progress"`, update state, proceed to Phase 3
   - If no: **Exit** (re-invoke `/bfeature:quick` when ready)

## Phase 3 — Execute

1. Invoke the `do-todo` skill as an Agent (model: sonnet) — it loops internally until all items are checked
2. When it completes:
   - Update state: `phase` to `"verify"`, `phase_status` to `"awaiting_approval"`, `updated_at` to current timestamp
   - Ask the user: "All tasks complete. Ready to run quality gates (tests + lint)?"
   - If yes: set `phase_status` to `"in_progress"`, update state, proceed to Phase 4
   - If no: **Exit** (re-invoke `/bfeature:quick` when ready)

## Phase 4 — Verify

1. Invoke the `verify` skill as an Agent (model: sonnet)
   - Detects project type, consults conventions, determines test and lint commands
   - Runs full test suite (monorepo-scoped if applicable) — fixes failures caused by our changes; surfaces unrelated failures to the user
   - Runs linter with auto-fix where available — fixes all remaining issues manually if needed
2. When tests and lint are green:
   - Update state: `phase` to `"review-impl"`, `phase_status` to `"awaiting_approval"`, `updated_at` to current timestamp
   - Ask the user: "Quality gates passed. Ready to proceed to implementation review?"
   - If yes: set `phase_status` to `"in_progress"`, update state, proceed to Phase 5
   - If no: **Exit** (re-invoke `/bfeature:quick` when ready)

## Phase 5 — Review Implementation

Run up to 3 analyze → fix cycles:

1. Invoke the `review-impl` skill as an Agent (model: opus)
   - The skill reads `mode` from state and compares against Q&A + plan (no spec in quick mode)
2. Read `.claude/.bfeature-temp/<slug>-impl-report.md`
3. If `STATUS: PASS`: proceed to step 5
4. If `STATUS: CONCERN`:
   - Show the concerns to the user
   - Ask: "Should I fix these concerns?"
   - If yes: invoke `review-impl/fix` as an Agent (model: sonnet), then go back to step 1
   - If no (user accepts as-is): proceed to step 5
   - If this was already the 3rd cycle: tell the user "Max review cycles reached — please review the implementation manually" and stop
5. Update state: `phase` to `"finalize"`, `phase_status` to `"awaiting_approval"`, `updated_at` to current timestamp
6. Ask the user: "Implementation review passed. Ready to finalize (commit, push, PR)?"
7. If yes: set `phase_status` to `"in_progress"`, update state, proceed to Phase 6
8. If no: **Exit** (re-invoke `/bfeature:quick` when ready)

## Phase 6 — Finalize

1. **Silent quality gate:** Before touching git, invoke the `verify` skill as an Agent (model: sonnet) one final time.
   - This catches any regressions introduced by review-impl fix cycles
   - If tests or lint fail: stop, tell the user which checks failed, and ask how to proceed — do **not** commit broken code
   - If all green: continue
2. Check for uncommitted changes (verify and review-impl/fix cycles may have left changes unstaged). If any exist: stage them (do **not** `git add` anything in `.claude/.bfeature-temp/`) and commit following `conventions/git.md`:
   - Use `feat:` prefix with a concise description of the fixes/cleanup
   - If `github_issue.enabled`, include the issue number (e.g., `feat(#12): address review concerns`)
   - If `jira.enabled`, include the ticket key (e.g., `feat(PROJ-123): address review concerns`)
3. Push the branch to remote
4. Create a PR using `gh pr create`:
   - **If `github_issue.enabled` is `true`:** include `Closes #<github_issue.number>` in the PR body
   - Include a summary of the change in the PR body
5. **If `jira.enabled` is `true`:**
   - Invoke the `jira-issue` skill: `transition-to(jira.ticket_key, "To Review")`
   - Invoke the `jira-issue` skill: `add-comment(jira.ticket_key, "PR: <pr_url>")`
6. Tell the user: "PR is up at <pr_url>. Build complete!"
7. Update state: `phase` to `"cleanup"`, `phase_status` to `"in_progress"`, `updated_at` to current timestamp
8. Proceed immediately to Phase 7

## Phase 7 — Cleanup

Run as a **background Agent** (`run_in_background: true`, model: sonnet) — fire and forget, do not wait for completion.

The agent should:
1. Delete `.claude/.bfeature-temp/build-state.json`
2. Delete these ephemeral handoff files if they exist: `<slug>-qa.md`, `<slug>-impl-report.md`
3. If `worktree_path` is set in state:
   - If this session entered the worktree via `EnterWorktree`: call `ExitWorktree(action: "remove")`
   - Otherwise (resumed across sessions): run `git worktree remove <worktree_path>` via Bash

## Model Routing

| Sub-skill | Invocation | Model |
|-----------|------------|-------|
| `refine` | Skill tool (inline) | — |
| `plan` | Agent tool | opus |
| `do-todo` | Agent tool | sonnet |
| `verify` | Agent tool | sonnet |
| `review-impl` | Agent tool | opus |
| `review-impl/fix` | Agent tool | sonnet |

**Phase 6 (Finalize) and Phase 7 (Cleanup) are executed directly by the orchestrator** — they have no sub-skill files.

Here is the idea:
$ARGUMENTS
