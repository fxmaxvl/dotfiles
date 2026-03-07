---
name: build-feature
description: Orchestrate the full brainstorm → plan → execute workflow with review gates between phases.
disable-model-invocation: true
argument-hint: [idea description]
allowed-tools: Read, Write, Grep, Glob, Bash(git *)
---

Orchestrate the full development workflow for a feature. Manage state via `build-state.json` and delegate to existing skills with approval gates between each phase.

## Phase Flow

```
init → brainstorm → review-design ⇄ fix → plan → execute → review-impl ⇄ fix → finalize → done
```

## On Invocation

1. Check if `build-state.json` exists in the project root
2. If it exists: read it and resume from the current phase (skip to the relevant phase section below)
3. If it does not exist: start from Phase 0 (init)

## Phase 0 — Init

1. Derive a short kebab-case slug from the idea (e.g., "add dark mode" → "dark-mode")
2. Ask the user: "Where should I store plan artifacts? Default: `docs/plans/`"
   - If the user provides a path, use it
   - If the user accepts the default (or just says "yes"/"ok"/etc.), use `docs/plans/`
   - Create the directory if it doesn't exist
3. Create and switch to branch `feat/<slug>` from master
4. Create `build-state.json` in the project root:

```json
{
  "idea": "$ARGUMENTS",
  "slug": "<slug>",
  "plans_dir": "<user-chosen or docs/plans/>",
  "phase": "brainstorm",
  "phase_status": "in_progress",
  "artifacts": {
    "spec": null,
    "plan": null,
    "todo": null
  },
  "created_at": "<current ISO timestamp>",
  "updated_at": "<current ISO timestamp>"
}
```

5. Proceed to Phase 1.

**Artifact naming convention:** All artifact filenames are prefixed with the slug. For example, if the slug is `dark-mode`, the artifacts are `dark-mode-spec.md`, `dark-mode-plan.md`, and `dark-mode-todo.md`. All artifact paths are relative to `plans_dir`. For example, if `plans_dir` is `docs/plans/` and slug is `dark-mode`, then the spec lives at `docs/plans/dark-mode-spec.md`.

## Phase 1 — Brainstorm

1. Invoke the `brainstorm` skill with the idea from `build-state.json`
2. The brainstorm skill will ask questions one at a time and produce the spec (instruct it to save to `<plans_dir>/<slug>-spec.md`)
3. When `<plans_dir>/<slug>-spec.md` is detected:
   - Update `build-state.json`: set `artifacts.spec` to `"<slug>-spec.md"`, `phase_status` to `"awaiting_approval"`
   - Tell the user: "Spec complete. Ready to run design review?"
4. On approval: update `phase` to `"review-design"`, `phase_status` to `"in_progress"`, proceed to Phase 2

## Phase 2 — Review Design

1. Invoke the `review-design` skill
2. The review skill will evaluate `<slug>-spec.md` and report PASS/CONCERN
3. If concerns are found, the review skill handles the fix loop (max 3 cycles)
4. When review passes:
   - Update `build-state.json`: `phase_status` to `"awaiting_approval"`
   - Tell the user: "Design review passed. Ready to start planning?"
5. On approval: update `phase` to `"plan"`, `phase_status` to `"in_progress"`, proceed to Phase 3

## Phase 3 — Plan

1. Invoke the `plan` skill (it reads `<plans_dir>/<slug>-spec.md` and produces `<plans_dir>/<slug>-plan.md` + `<plans_dir>/<slug>-todo.md`)
2. When both files are detected:
   - Update `build-state.json`: set `artifacts.plan` to `"<slug>-plan.md"`, `artifacts.todo` to `"<slug>-todo.md"`, `phase_status` to `"awaiting_approval"`
   - Tell the user: "Plan complete. Ready to start execution?"
3. On approval: update `phase` to `"execute"`, `phase_status` to `"in_progress"`, proceed to Phase 4

## Phase 4 — Execute

1. Invoke the `do-todo` skill to pick up the next unchecked item from `<slug>-todo.md`
2. After each item is completed, check if all items in `<slug>-todo.md` are checked (`[x]`)
3. If unchecked items remain: invoke `do-todo` again
4. When all items are checked:
   - Update `build-state.json`: `phase_status` to `"awaiting_approval"`
   - Tell the user: "All tasks complete. Ready to run implementation review?"
5. On approval: update `phase` to `"review-impl"`, `phase_status` to `"in_progress"`, proceed to Phase 5

## Phase 5 — Review Implementation

1. Invoke the `review-impl` skill
2. The review skill will evaluate the implementation against `<slug>-spec.md` + `<slug>-plan.md`
3. If concerns are found, the review skill handles the fix loop (max 3 cycles)
4. When review passes:
   - Update `build-state.json`: `phase_status` to `"awaiting_approval"`
   - Tell the user: "Implementation review passed. Ready to finalize?"
5. On approval: update `phase` to `"finalize"`, `phase_status` to `"in_progress"`, proceed to Phase 6

## Phase 6 — Finalize

1. Stage all changes
2. Commit using conventional commit format (see `docs/git.md`):
   - Use `feat:` prefix with a concise description of the feature
   - Add `#pr` tag since this is the feature branch
3. Push the branch to remote
4. Update `build-state.json`: `phase` to `"done"`, `phase_status` to `"in_progress"`
5. Tell the user: "Feature branch pushed. Build complete!"

## State Updates

After every phase transition, update `build-state.json`:
- Set the new `phase` and `phase_status`
- Update `updated_at` to the current ISO timestamp
- Write the file to disk

## Error Recovery

- If the session ends mid-phase, the next `/build` invocation reads `build-state.json` and resumes
- If the branch `feat/<slug>` already exists, switch to it instead of creating a new one
- If `build-state.json` shows phase `done`, tell the user the build is already complete

Here is the idea:
$ARGUMENTS
