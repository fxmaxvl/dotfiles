---
name: build-feature
description: Orchestrate the full brainstorm → plan → execute workflow with review gates between phases.
disable-model-invocation: false
argument-hint: [idea description, Jira ticket URL, or GH-ISSUE:<number>]
allowed-tools: Read, Write, Grep, Glob, Bash(git *), mcp__*__jira__*
---

Orchestrate the full development workflow for a feature. Manage state via `.claude/.build-feature-temp/build-state.json` and delegate to existing skills with approval gates between each phase.

## Artifacts Directory

All build artifacts (spec, plan, todo, backlog, build-state.json) live in `<project_root>/.claude/.build-feature-temp/`. This is the project's `.claude/` directory (NOT `~/.claude/`). The directory is created via `mkdir -p` during init and the state file is removed at the end of finalization.

## Model Routing

Each sub-skill declares a `model` field in its SKILL.md frontmatter. When delegating to a sub-skill via the Agent tool, **always pass the declared model**. The current routing:

| Sub-skill | Model | Rationale |
|-----------|-------|-----------|
| `brainstorm` | opus | Conversational nuance, iterative Q&A |
| `review-design` | opus | Critical architectural analysis |
| `plan` | opus | Deep reasoning for TDD blueprints |
| `do-todo` | sonnet | Fast, execution-focused coding |
| `review-impl` | opus | Critical code review |
| `collect-todos` | sonnet | Mechanical scanning task |
| `finalize` (Phase 7) | sonnet | Mechanical git/PR operations |

When invoking sub-skills as agents, set the `model` parameter accordingly. For example: `Agent(model: "sonnet", ...)` for `do-todo`.

## Phase Flow

```
init → brainstorm → review-design ⇄ fix → plan → execute → review-impl ⇄ fix → collect-todos → finalize → done
```

## On Invocation

1. Check if `.claude/.build-feature-temp/build-state.json` exists
2. If it exists: read it and resume from the current phase (skip to the relevant phase section below)
3. If it does not exist: start from Phase 0 (init)

## Phase 0 — Init

1. **Detect GitHub issue:** Check if `$ARGUMENTS` contains a `GH-ISSUE:<number>` marker. If it does:
   - Extract the issue number
   - Set `github_issue.enabled` to `true` and `github_issue.number` to the extracted number in state (see below)
   - Use the issue number as slug prefix: `gh-<number>-<short-description>` (e.g., `gh-12-token-refresh`)
2. **Detect Jira ticket:** Check if `$ARGUMENTS` contains a Jira ticket URL (e.g., `https://<domain>.atlassian.net/browse/PROJ-123` or similar). If it does:
   - Extract the ticket key (e.g., `PROJ-123`)
   - Invoke the `jira` skill to verify Jira MCP tools are available. If not available, stop.
   - Set `jira.ticket_key` in state (see below)
   - Use the ticket key as slug prefix: `<ticket-key>-<short-description>` (e.g., `PROJ-123-dark-mode`)
   - Invoke the `jira` skill: `transition-to(ticket_key, "In Progress")`
3. If neither GitHub issue nor Jira ticket: derive a short kebab-case slug from the idea as before (e.g., "add dark mode" → "dark-mode")
4. Create the artifacts directory: `mkdir -p <project_root>/.claude/.build-feature-temp/`
5. **Branch selection:**
   - Check the current git branch
   - If on `master` (or the repo's main branch): create and switch to `feat/<slug>` from master
   - If on a non-master branch (e.g., `feat/something`): ask the user — "You're currently on `<branch>`. Do you want to continue working here, or create a new branch `feat/<slug>` from master?"
     - If the user chooses to continue: stay on the current branch, use the current branch name to derive the slug (strip `feat/` prefix if present)
     - If the user chooses a new branch: create and switch to `feat/<slug>` from master
6. Create `.claude/.build-feature-temp/build-state.json`:

```json
{
  "idea": "$ARGUMENTS",
  "slug": "<slug>",
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
  "created_at": "<current ISO timestamp>",
  "updated_at": "<current ISO timestamp>"
}
```

   - If a Jira ticket was detected, set `jira.enabled` to `true`, `jira.ticket_key` to the extracted key, and `jira.ticket_url` to the original URL.

7. Proceed to Phase 1.

**Artifact naming convention:** All artifact filenames are prefixed with the slug. For example, if the slug is `dark-mode`, the artifacts are `dark-mode-spec.md`, `dark-mode-plan.md`, and `dark-mode-todo.md`. All artifacts live in `.claude/.build-feature-temp/`. For example, if slug is `dark-mode`, the spec lives at `.claude/.build-feature-temp/dark-mode-spec.md`.

## Phase 1 — Brainstorm

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
3. Invoke the `brainstorm` skill with this synthesized description as the idea
   - The brainstorm skill may still ask clarifying questions if needed — but it starts from a much richer context
4. The brainstorm skill produces the spec (saved to `.claude/.build-feature-temp/<slug>-spec.md`)

### If `jira.enabled` is `false`:
1. Invoke the `brainstorm` skill with the idea from state
2. The brainstorm skill will ask questions one at a time and produce the spec (instruct it to save to `.claude/.build-feature-temp/<slug>-spec.md`)

### Escalating questions to Jira
If during brainstorm the user cannot answer a clarifying question and asks to post it to Jira (`jira.enabled` must be `true`):
1. Invoke the `jira` skill: `ask-author(jira.ticket_key, questions)` — this tags the ticket author and posts the questions as a comment
2. Save the questions to `jira.pending_questions` in state
3. Set `phase_status` to `"waiting_answer"`
4. Tell the user: "Questions posted to Jira ticket. Run `/build-feature` again later to check for answers."

### In all cases:
When `.claude/.build-feature-temp/<slug>-spec.md` is detected:
   - Update state: set `artifacts.spec` to `"<slug>-spec.md"`, `phase_status` to `"awaiting_approval"`
   - Tell the user: "Spec complete. Ready to run design review?"
On approval: update `phase` to `"review-design"`, `phase_status` to `"in_progress"`, proceed to Phase 2

## Phase 2 — Review Design

1. Invoke the `review-design` skill
2. The review skill will evaluate `<slug>-spec.md` and report PASS/CONCERN
3. If concerns are found, the review skill handles the fix loop (max 3 cycles)
4. When review passes:
   - Update state: `phase_status` to `"awaiting_approval"`
   - Tell the user: "Design review passed. Ready to start planning?"
5. On approval: update `phase` to `"plan"`, `phase_status` to `"in_progress"`, proceed to Phase 3

## Phase 3 — Plan

1. Invoke the `plan` skill (it reads `.claude/.build-feature-temp/<slug>-spec.md` and produces `.claude/.build-feature-temp/<slug>-plan.md` + `.claude/.build-feature-temp/<slug>-todo.md`)
2. When both files are detected:
   - Update state: set `artifacts.plan` to `"<slug>-plan.md"`, `artifacts.todo` to `"<slug>-todo.md"`, `phase_status` to `"awaiting_approval"`
   - Tell the user: "Plan complete. Ready to start execution?"
3. On approval: update `phase` to `"execute"`, `phase_status` to `"in_progress"`, proceed to Phase 4

## Phase 4 — Execute

1. Invoke the `do-todo` skill to pick up the next unchecked item from `<slug>-todo.md`
2. After each item is completed, check if all items in `<slug>-todo.md` are checked (`[x]`)
3. If unchecked items remain: invoke `do-todo` again
4. When all items are checked:
   - Update state: `phase_status` to `"awaiting_approval"`
   - Tell the user: "All tasks complete. Ready to run implementation review?"
5. On approval: update `phase` to `"review-impl"`, `phase_status` to `"in_progress"`, proceed to Phase 5

## Phase 5 — Review Implementation

1. Invoke the `review-impl` skill
2. The review skill will evaluate the implementation against `<slug>-spec.md` + `<slug>-plan.md`
3. If concerns are found, the review skill handles the fix loop (max 3 cycles)
4. When review passes:
   - Update state: `phase_status` to `"awaiting_approval"`
   - Tell the user: "Implementation review passed. Ready to collect TODOs?"
5. On approval: update `phase` to `"collect-todos"`, `phase_status` to `"in_progress"`, proceed to Phase 6

## Phase 6 — Collect TODOs

1. Invoke the `collect-todos` skill
2. The skill scans changes introduced by the feature branch for TODO comments, classifies them, and generates `.claude/.build-feature-temp/<slug>-backlog.md`
3. When complete:
   - Update state: set `artifacts.backlog` to `"<slug>-backlog.md"` (or `null` if no items found), `phase_status` to `"awaiting_approval"`
   - Tell the user: "Backlog collected. Ready to finalize?"
4. On approval: update `phase` to `"finalize"`, `phase_status` to `"in_progress"`, proceed to Phase 7

## Phase 7 — Finalize

1. Stage implementation changes only — do **not** `git add` anything in `.claude/.build-feature-temp/`.
2. Commit using conventional commit format (see `conventions/git.md`):
   - Use `feat:` prefix with a concise description of the feature
   - If `github_issue.enabled`, include the issue number in the commit message (e.g., `feat(#12): fix token refresh`)
   - If `jira.enabled`, include the ticket key in the commit message (e.g., `feat(PROJ-123): add dark mode`)
   - Add `#pr` tag since this is the feature branch
3. Push the branch to remote
4. Create a PR using `gh pr create`:
   - **If `github_issue.enabled` is `true`:** include `Closes #<github_issue.number>` in the PR body. This automatically closes the issue when the PR is merged.
   - Include a summary of the feature in the PR body
5. **If `jira.enabled` is `true`:**
   - Invoke the `jira` skill: `transition-to(jira.ticket_key, "To Review")`
   - Invoke the `jira` skill: `add-comment(jira.ticket_key, "PR: <pr_url>")`
6. **Cleanup:** Delete `.claude/.build-feature-temp/build-state.json`
7. Tell the user: "Feature branch pushed. Build complete!"

## State Updates

After every phase transition, update `.claude/.build-feature-temp/build-state.json`:
- Set the new `phase` and `phase_status`
- Update `updated_at` to the current ISO timestamp
- Write the file to disk

## Error Recovery

- If the session ends mid-phase, the next `/build` invocation reads `.claude/.build-feature-temp/build-state.json` and resumes
- If the branch `feat/<slug>` already exists, switch to it instead of creating a new one
- If state shows phase `done`, tell the user the build is already complete

Here is the idea:
$ARGUMENTS
