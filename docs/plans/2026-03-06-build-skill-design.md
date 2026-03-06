# Build Skill — Design Document

## Overview

A meta-skill that orchestrates the full development workflow: brainstorm → review-design → plan → execute → review-impl → finalize. It invokes existing skills (`brainstorm`, `plan`, `do-todo`) and two new review skills, with approval gates between each phase.

## Problem

The brainstorm → plan → execute workflow requires manually invoking each skill and managing handoffs. Context and momentum are lost between phases.

## Solution

A single `/build <idea>` skill that manages the entire lifecycle with:
- A state machine tracked via `build-state.json`
- Artifact-based phase detection
- Approval gates at each transition
- Review loops that catch issues before moving forward

## Phase Flow

```
init → brainstorm → review-design ⇄ fix → plan → execute → review-impl ⇄ fix → finalize → done
```

All transitions require user approval.

## Phases

### Phase 0 — init
- Creates feature branch from master: `feat/<short-slug-from-idea>`
- Creates `build-state.json`

### Phase 1 — brainstorm
- Invokes existing `brainstorm` skill with `$ARGUMENTS` as the idea
- Artifact: `spec.md`
- Detection: `spec.md` exists in project root

### Phase 2 — review-design
- New `review-design` skill reviews `spec.md` for:
  - Architecture completeness
  - Cases and edge cases (happy path, errors, boundaries)
  - Missing requirements or ambiguities
- If concerns found → fix loop: updates `spec.md`, re-reviews (max 3 cycles)
- No new artifact — refines `spec.md`
- Approval gate after clean review

### Phase 3 — plan
- Invokes existing `plan` skill with `spec.md` as input
- Artifacts: `plan.md` + `todo.md`
- Detection: both files exist
- Approval gate

### Phase 4 — execute
- Invokes existing `do-todo` skill in a loop until all items in `todo.md` are checked
- Detection: all checkboxes in `todo.md` are `[x]`
- Approval gate

### Phase 5 — review-impl
- New `review-impl` skill reviews implementation against `spec.md` + `plan.md`:
  - Feature completeness (is everything in the spec actually built?)
  - Dev conventions (per `docs/dev.md`)
  - Test coverage (per `docs/testing.md`)
  - Code style consistency
- Uses git diff from the branch to see all changes
- If concerns found → fix loop: creates new todo items, executes, re-reviews (max 3 cycles)
- Approval gate after clean review

### Phase 6 — finalize
- Commits all changes using conventional commit format (per `docs/git.md`)
- Pushes branch to remote
- Phase → `done`

## State File — `build-state.json`

Created in the project root. Structure:

```json
{
  "idea": "add dark mode to the app",
  "phase": "brainstorm",
  "phase_status": "in_progress",
  "artifacts": {
    "spec": null,
    "plan": null,
    "todo": null
  },
  "created_at": "2026-03-06T10:00:00Z",
  "updated_at": "2026-03-06T10:00:00Z"
}
```

- `phase` — one of: `init`, `brainstorm`, `review-design`, `plan`, `execute`, `review-impl`, `finalize`, `done`
- `phase_status` — `in_progress` or `awaiting_approval`
- `artifacts` — paths to produced files (null until created)

## New Files

### Skills
```
llms/claude/skills/
├── build/SKILL.md           # The orchestrator meta-skill
├── review-design/SKILL.md   # Design review (spec, architecture, edge cases)
└── review-impl/SKILL.md     # Implementation review (completeness, conventions, tests)
```

### Per-project artifacts (created during a build run)
```
<project-root>/
├── build-state.json
├── spec.md
├── plan.md
└── todo.md
```

No changes to existing skills — `brainstorm`, `plan`, `do-todo` stay as-is.

## Error Handling

- **Session dies mid-phase:** Next `/build` reads `build-state.json` and resumes
- **`/build` on existing state:** Resumes the existing flow
- **Review fix loops:** Max 3 cycles per review phase, then pause for manual intervention
- **Branch already exists:** Switch to it and resume
- **`build-state.json` is source of truth** for which phase we're in
