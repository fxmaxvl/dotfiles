---
name: bfeature
description: Orchestrate the full brainstorm → plan → execute workflow with review gates between phases.
disable-model-invocation: false
argument-hint: [--quick] [idea description, Jira ticket URL, or GH-ISSUE:<number>]
allowed-tools: Read, Write, Grep, Glob, Bash(git *), Bash(gh *), mcp__*__jira__*
---

Orchestrate the full development workflow for a feature. Manage state via `.claude/.bfeature-temp/build-state.json` and delegate to existing skills with approval gates between each phase.

## Artifacts Directory

All build artifacts (spec, plan, todo, backlog, build-state.json) live in `<project_root>/.claude/.bfeature-temp/`. This is the project's `.claude/` directory (NOT `~/.claude/`). The directory is created via `mkdir -p` during init and the state file is removed at the end of finalization.

## Model Routing

Each sub-skill declares a `model` field in its SKILL.md frontmatter. When delegating to a sub-skill via the Agent tool, **always pass the declared model**. The current routing:

| Sub-skill | Skill name | Invocation | Model | Rationale |
|-----------|------------|------------|-------|-----------|
| brainstorm (gather) | `brainstorm-gather` | Skill tool (inline) | — | Interactive Q&A — must stay in main conversation |
| brainstorm/generate | `brainstorm-generate` | Agent tool | opus | Spec synthesis from Q&A — reasoning-heavy, no interaction needed |
| refine | `bfeature-refine` | Skill tool (inline) | — | Interactive Q&A — must stay in main conversation (quick mode only) |
| review-design | `review-design-analyze` | Agent tool | opus | Architectural analysis — produces report, no user interaction |
| review-design/fix | `review-design-fix` | Agent tool | sonnet | Applies spec fixes — execution task |
| plan | `plan` | Agent tool | opus | Deep reasoning for TDD blueprints |
| do-todo | `do-todo` | Agent tool | sonnet | Fast, execution-focused coding |
| verify | `verify` | Agent tool | sonnet | Quality gates — runs tests (monorepo-aware) and lint with auto-fix |
| review-impl | `review-impl-analyze` | Agent tool | opus | Implementation analysis — produces report, no user interaction |
| review-impl/fix | `review-impl-fix` | Agent tool | sonnet | Applies code fixes — execution task |
| collect-todos (Phase 7, optional) | `collect-todos` | Agent tool | sonnet | Mechanical scanning task — skipped if user declines |

`brainstorm-gather` and `bfeature-refine` are the only sub-skills invoked inline via the Skill tool — do **not** wrap them in an Agent call. All others use the Agent tool with the declared model.

**Phase 6 (Finalize) and Phase 8 (Cleanup) are executed directly by the orchestrator** — they have no sub-skill files. The finalize logic is defined inline in this file (see Phase 6 below).

## Phase Flow

**Full mode** (default):
```
init → brainstorm → review-design ⇄ fix → plan → execute → verify → review-impl ⇄ fix → verify (silent) → finalize (commit/push/ticket) → collect-todos? → cleanup → done
```

**Quick mode** (invoked via `/bfeature --quick`):
```
init → refine → plan (from Q&A) → execute → verify → review-impl ⇄ fix → verify (silent) → finalize (commit/push/ticket) → collect-todos? → cleanup → done
```

Quick mode skips spec generation and design review. The `refine` phase replaces brainstorm with a lighter Q&A that feeds directly into planning.

## On Invocation

1. **Detect `--quick` flag:** Check if `$ARGUMENTS` starts with or contains `--quick`. If it does:
   - Set `quick_mode` to `true`
   - Strip `--quick` from `$ARGUMENTS` before using the remainder as the idea
2. Check if `.claude/.bfeature-temp/build-state.json` exists
3. If it does not exist: start from Phase 0 (init)
4. If it exists: read it and resume:
   - If `worktree_path` is set: the session CWD may be the main repo, not the worktree. Use `Bash(cd <worktree_path>)` to switch into it before doing any work. Do NOT call `EnterWorktree` again — the worktree already exists.
   - If `phase_status` is `"awaiting_approval"`: ask the user "Paused before [current phase]. Ready to proceed?" — if yes, set `phase_status` to `"in_progress"`, update state, and execute the current phase; if no, exit
   - Otherwise: resume the current phase from where it left off

## Phase 0 — Init

1. **Detect GitHub issue:** Check if `$ARGUMENTS` contains a `GH-ISSUE:<number>` marker. If it does:
   - Extract the issue number
   - Set `github_issue.enabled` to `true` and `github_issue.number` to the extracted number in state (see below)
   - Use the issue number as slug prefix: `gh-<number>-<short-description>` (e.g., `gh-12-token-refresh`)
2. **Detect Jira ticket:** Check if `$ARGUMENTS` contains a Jira ticket URL (e.g., `https://<domain>.atlassian.net/browse/PROJ-123` or similar). If it does:
   - Extract the ticket key (e.g., `PROJ-123`)
   - Invoke the `jira-issue` skill to verify Jira MCP tools are available. If not available, stop.
   - Set `jira.ticket_key` in state (see below)
   - Use the ticket key as slug prefix: `<ticket-key>-<short-description>` (e.g., `PROJ-123-dark-mode`)
   - Invoke the `jira-issue` skill: `transition-to(ticket_key, "In Progress")`
3. If neither GitHub issue nor Jira ticket: derive a short kebab-case slug from the idea as before (e.g., "add dark mode" → "dark-mode")
4. Create the artifacts directory: `mkdir -p <project_root>/.claude/.bfeature-temp/`
5. **Branch selection:**
   - Check the current git branch
   - If on `master` (or the repo's main branch): create `feat/<slug>` from master and set up a worktree (see below)
   - If on a non-master branch (e.g., `feat/something`): ask the user — "You're currently on `<branch>`. Do you want to continue working here, or create a new branch `feat/<slug>` from master?"
     - If the user chooses to continue: stay on the current branch, use the current branch name to derive the slug (strip `feat/` prefix if present); no worktree is created
     - If the user chooses a new branch: create `feat/<slug>` from master and set up a worktree (see below)

   **Creating a new branch with a worktree:**
   - Call `EnterWorktree(name: "feat/<slug>")` — this creates the branch from HEAD and switches the session into the worktree
   - The worktree is created at `.claude/worktrees/feat/<slug>` inside the project
   - Record the absolute worktree path in state as `worktree_path`

6. Create `.claude/.bfeature-temp/build-state.json`:

```json
{
  "idea": "$ARGUMENTS",
  "slug": "<slug>",
  "mode": "full",
  "phase": "brainstorm",
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

   - If a Jira ticket was detected, set `jira.enabled` to `true`, `jira.ticket_key` to the extracted key, and `jira.ticket_url` to the original URL.
   - If a worktree was created, set `worktree_path` to the absolute path of the worktree directory.
   - The `mode` field defaults to `"full"`. If `--quick` flag was detected, set `mode` to `"quick"` and `phase` to `"refine"` instead of `"brainstorm"`.

7. Proceed to Phase 1 (brainstorm for full mode, refine for quick mode).

**Artifact naming convention:** All artifact filenames are prefixed with the slug. For example, if the slug is `dark-mode`, the artifacts are `dark-mode-spec.md`, `dark-mode-plan.md`, and `dark-mode-todo.md`. All artifacts live in `.claude/.bfeature-temp/`. For example, if slug is `dark-mode`, the spec lives at `.claude/.bfeature-temp/dark-mode-spec.md`.

## Phase 1 — Brainstorm (full mode only)

Skipped entirely in quick mode — quick mode uses Phase 1Q (Refine) instead.

### Resuming from `waiting_answer`
If state has `phase` = `"brainstorm"` and `phase_status` = `"waiting_answer"`:
1. Invoke the `jira` skill: `check-for-answers(jira.ticket_key, jira.pending_questions)`
2. If all questions are answered in Jira: clear `jira.pending_questions`, set `phase_status` to `"in_progress"`, and continue the brainstorm with the new answers
3. If some questions are still unanswered in Jira: show the user the pending questions and ask — "No answer on Jira yet for these. Do you have the answers yourself, or should we keep waiting?"
   - If the user provides answers: use them, clear `jira.pending_questions`, set `phase_status` to `"in_progress"`, and continue the brainstorm
   - If the user wants to keep waiting: remain in `waiting_answer`

### If `jira.enabled` is `true`:
1. Invoke the `jira` skill: `read-ticket(jira.ticket_key)` to fetch the ticket's description, comments, and context
2. Synthesize an overall description from the ticket content
3. Invoke the `brainstorm-gather` skill **inline** (via Skill tool, not Agent) with the synthesized description
   - Runs in the main conversation — user interaction is fully available
   - Gather saves Q&A to `.claude/.bfeature-temp/<slug>-qa.md`
4. Invoke the `brainstorm-generate` skill as an Agent (model: opus) to produce the spec from the Q&A

### If `jira.enabled` is `false`:
1. Invoke the `brainstorm-gather` skill **inline** (via Skill tool, not Agent) with the idea from state
   - Runs in the main conversation — user interaction is fully available
   - Gather saves Q&A to `.claude/.bfeature-temp/<slug>-qa.md`
2. Invoke the `brainstorm-generate` skill as an Agent (model: opus) to produce the spec from the Q&A

### Escalating questions to Jira
If during brainstorm the user cannot answer a clarifying question and asks to post it to Jira (`jira.enabled` must be `true`):
1. Invoke the `jira` skill: `ask-author(jira.ticket_key, questions)` — this tags the ticket author and posts the questions as a comment
2. Save the questions to `jira.pending_questions` in state
3. Set `phase_status` to `"waiting_answer"`
4. Tell the user: "Questions posted to Jira ticket. Run `/bfeature` again later to check for answers."

### In all cases:
When `.claude/.bfeature-temp/<slug>-spec.md` is detected:
   - Update state: set `artifacts.spec` to `"<slug>-spec.md"`, `phase` to `"review-design"`, `phase_status` to `"awaiting_approval"`, `updated_at` to current timestamp
   - Ask the user: "Spec written to `.claude/.bfeature-temp/<slug>-spec.md`. Ready to proceed to design review?"
   - If yes: set `phase_status` to `"in_progress"`, update state, proceed to Phase 2
   - If no: **Exit** (re-invoke `/bfeature` when ready)

## Phase 1Q — Refine (quick mode only)

Skipped entirely in full mode — full mode uses Phase 1 (Brainstorm) instead.

1. Invoke the `bfeature-refine` skill **inline** (via Skill tool, not Agent) with the idea from state
   - Runs in the main conversation — user interaction is fully available
   - Saves Q&A to `.claude/.bfeature-temp/<slug>-qa.md`
2. When `.claude/.bfeature-temp/<slug>-qa.md` is detected:
   - Update state: set `phase` to `"plan"`, `phase_status` to `"awaiting_approval"`, `updated_at` to current timestamp
   - Ask the user: "Q&A saved. Ready to proceed to planning?"
   - If yes: set `phase_status` to `"in_progress"`, update state, proceed to Phase 3
   - If no: **Exit** (re-invoke `/bfeature` when ready)

## Phase 2 — Review Design (full mode only)

Skipped entirely in quick mode.

Run up to 3 analyze → fix cycles:

1. Invoke the `review-design-analyze` skill as an Agent (model: opus)
2. Read `.claude/.bfeature-temp/<slug>-design-report.md`
3. If `STATUS: PASS`: proceed to step 5
4. If `STATUS: CONCERN`:
   - Show the concerns to the user
   - Ask: "Should I fix these concerns?"
   - If yes: invoke `review-design-fix` as an Agent (model: sonnet), then go back to step 1
   - If no (user accepts as-is): proceed to step 5
   - If this was already the 3rd cycle: tell the user "Max review cycles reached — please review the spec manually" and stop
5. Update state: `phase` to `"plan"`, `phase_status` to `"awaiting_approval"`, `updated_at` to current timestamp
6. Ask the user: "Design review passed. Ready to proceed to planning?"
7. If yes: set `phase_status` to `"in_progress"`, update state, proceed to Phase 3
8. If no: **Exit** (re-invoke `/bfeature` when ready)

## Phase 3 — Plan

1. Invoke the `plan` skill (it reads the appropriate source based on `mode` and produces `.claude/.bfeature-temp/<slug>-plan.md` + `.claude/.bfeature-temp/<slug>-todo.md`)
2. When both files are detected:
   - Update state: set `artifacts.plan` to `"<slug>-plan.md"`, `artifacts.todo` to `"<slug>-todo.md"`, `phase` to `"execute"`, `phase_status` to `"awaiting_approval"`, `updated_at` to current timestamp
   - Ask the user: "Plan written to `.claude/.bfeature-temp/<slug>-plan.md`. Ready to start execution?"
   - If yes: set `phase_status` to `"in_progress"`, update state, proceed to Phase 4
   - If no: **Exit** (re-invoke `/bfeature` when ready)

## Phase 4 — Execute

1. Invoke the `do-todo` skill as an Agent (model: sonnet) — it loops internally until all items are checked
2. When it completes:
   - Update state: `phase` to `"verify"`, `phase_status` to `"awaiting_approval"`, `updated_at` to current timestamp
   - Ask the user: "All tasks complete. Ready to run quality gates (tests + lint)?"
   - If yes: set `phase_status` to `"in_progress"`, update state, proceed to Phase 4.5
   - If no: **Exit** (re-invoke `/bfeature` when ready)

## Phase 4.5 — Verify

1. Invoke the `verify` skill as an Agent (model: sonnet)
   - Detects project type, consults conventions, determines test and lint commands
   - Runs full test suite (monorepo-scoped if applicable) — fixes failures caused by our changes; surfaces unrelated failures to the user
   - Runs linter with auto-fix where available — fixes all remaining issues manually if needed
2. When tests and lint are green:
   - Update state: `phase` to `"review-impl"`, `phase_status` to `"awaiting_approval"`, `updated_at` to current timestamp
   - Ask the user: "Quality gates passed. Ready to proceed to implementation review?"
   - If yes: set `phase_status` to `"in_progress"`, update state, proceed to Phase 5
   - If no: **Exit** (re-invoke `/bfeature` when ready)

## Phase 5 — Review Implementation

Run up to 3 analyze → fix cycles:

1. Invoke the `review-impl-analyze` skill as an Agent (model: opus)
2. Read `.claude/.bfeature-temp/<slug>-impl-report.md`
3. If `STATUS: PASS`: proceed to step 5
4. If `STATUS: CONCERN`:
   - Show the concerns to the user
   - Ask: "Should I fix these concerns?"
   - If yes: invoke `review-impl-fix` as an Agent (model: sonnet), then go back to step 1
   - If no (user accepts as-is): proceed to step 5
   - If this was already the 3rd cycle: tell the user "Max review cycles reached — please review the implementation manually" and stop
5. Update state: `phase` to `"finalize"`, `phase_status` to `"awaiting_approval"`, `updated_at` to current timestamp
6. Ask the user: "Implementation review passed. Ready to finalize (commit, push, PR)?"
7. If yes: set `phase_status` to `"in_progress"`, update state, proceed to Phase 6
8. If no: **Exit** (re-invoke `/bfeature` when ready)

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
5. Create a PR using `gh pr create`:
   - **PR body:** Read `.claude/.bfeature-temp/<slug>-spec.md` and write a short summary (2–3 sentences max) of what the feature does and why — no test descriptions, no minor change lists, no implementation details
   - **If `github_issue.enabled` is `true`:** append `Closes #<github_issue.number>` to the PR body. This automatically closes the issue when the PR is merged.
   - **If `jira.enabled` is `true`:** append a link to the Jira ticket (`jira.ticket_url`) in the PR body
6. **If `jira.enabled` is `true`:**
   - Invoke the `jira-issue` skill: `transition-to(jira.ticket_key, "To Review")`
   - Invoke the `jira-issue` skill: `add-comment(jira.ticket_key, "PR: <pr_url>")`
7. Tell the user: "PR is up at <pr_url>. Build complete!"
8. Update state: `phase` to `"collect-todos"`, `phase_status` to `"awaiting_approval"`, `updated_at` to current timestamp
9. Ask the user: "Want me to scan the feature changes for TODO comments and add them to the backlog?"
   - If yes: set `phase_status` to `"in_progress"`, update state, proceed to Phase 7
   - If no: skip Phase 7, proceed directly to Phase 8 (Cleanup)

## Phase 7 — Collect TODOs (optional)

1. Invoke the `collect-todos` skill as an Agent (model: sonnet)
2. The skill scans changes introduced by the feature branch for TODO comments, classifies them, and generates `.claude/.bfeature-temp/<slug>-backlog.md`
3. When complete:
   - Update state: set `artifacts.backlog` to `"<slug>-backlog.md"` (or `null` if no items found)
4. Proceed to Phase 8 (Cleanup)

## Phase 8 — Cleanup

Run as a **background Agent** (`run_in_background: true`, model: sonnet) — fire and forget, do not wait for completion.

The agent should:
1. Delete `.claude/.bfeature-temp/build-state.json`
2. Delete these ephemeral handoff files if they exist: `<slug>-qa.md`, `<slug>-design-report.md`, `<slug>-impl-report.md`
3. If `worktree_path` is set in state:
   - If this session entered the worktree via `EnterWorktree`: call `ExitWorktree(action: "remove")`
   - Otherwise (resumed across sessions): run `git worktree remove <worktree_path>` via Bash

## State Updates

After every phase transition, update `.claude/.bfeature-temp/build-state.json`:
- Set the new `phase` and `phase_status`
- Update `updated_at` to the current ISO timestamp
- Write the file to disk

## Error Recovery

- If the session ends mid-phase, the next `/bfeature` invocation reads `.claude/.bfeature-temp/build-state.json` and resumes
- If the branch `feat/<slug>` already exists, switch to it instead of creating a new one
- If state shows phase `done`, tell the user the build is already complete

Here is the idea:
$ARGUMENTS
