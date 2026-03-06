# Build Skill Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create three new Claude Code skills — `build` (orchestrator), `review-design`, and `review-impl` — that chain together the brainstorm → plan → execute workflow with review gates.

**Architecture:** Three independent SKILL.md files following the existing skill format (YAML front matter + markdown instructions). `build` is the orchestrator that manages state via `build-state.json` and delegates to existing skills + the two new review skills. No executable code — these are instruction-only skills (`disable-model-invocation: true`).

**Tech Stack:** Claude Code skills (markdown), JSON (state file)

---

### Task 1: Create `review-design` skill

**Files:**
- Create: `llms/claude/skills/review-design/SKILL.md`

**Step 1: Write the skill file**

Create `llms/claude/skills/review-design/SKILL.md` with this exact content:

```markdown
---
name: review-design
description: Review a spec.md for architecture completeness, edge cases, and missing requirements.
disable-model-invocation: true
---

Review `spec.md` and evaluate it against the following criteria. For each criterion, state whether it passes or has concerns.

## Review Criteria

### 1. Architecture completeness
- Are all major components identified?
- Are the boundaries between components clear?
- Are external dependencies and integrations specified?

### 2. Cases and edge cases
- Is the happy path clearly described?
- Are error cases and failure modes covered?
- Are boundary conditions addressed (empty inputs, large inputs, concurrent access, etc.)?

### 3. Requirements completeness
- Are all functional requirements specified with enough detail to implement?
- Are non-functional requirements addressed (performance, security, accessibility)?
- Are there ambiguities or unstated assumptions?

## Output Format

For each criterion, output one of:
- **PASS** — no concerns
- **CONCERN** — describe the issue and suggest a fix

If any criterion has a CONCERN:
1. List all concerns with suggested fixes
2. Ask the user: "Should I update spec.md to address these concerns?"
3. If yes, update `spec.md` and re-run this review
4. Maximum 3 review cycles — after that, pause and ask the user to intervene

If all criteria PASS:
1. State "Design review passed — spec.md is ready for planning"
2. Ask the user for approval to proceed
```

**Step 2: Verify the file**

Run: `cat llms/claude/skills/review-design/SKILL.md`
Expected: The file contents match the above.

**Step 3: Commit**

```bash
git add llms/claude/skills/review-design/SKILL.md
git commit -m "feat: add review-design skill for spec review"
```

---

### Task 2: Create `review-impl` skill

**Files:**
- Create: `llms/claude/skills/review-impl/SKILL.md`

**Step 1: Write the skill file**

Create `llms/claude/skills/review-impl/SKILL.md` with this exact content:

```markdown
---
name: review-impl
description: Review implementation against spec.md and plan.md for completeness and quality.
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash(git *)
---

Review the implementation by comparing what was built against `spec.md` and `plan.md`. Use git diff from the feature branch to see all changes.

## Review Criteria

### 1. Feature completeness
- Read `spec.md` and list every functional requirement
- For each requirement, verify it is implemented by checking the actual code
- Flag any requirement that is missing or partially implemented

### 2. Dev conventions
- Check against the project's `docs/dev.md` conventions:
  - All code files start with `ABOUTME:` comments (2 lines)
  - Code style matches surrounding code
  - No unrelated changes
  - No mock implementations
  - No `--no-verify` in any commits
  - Comments are evergreen (no temporal references)

### 3. Test coverage
- Check against `docs/testing.md` conventions:
  - Unit tests exist for new functionality
  - Integration tests exist
  - End-to-end tests exist
  - Test output is pristine (no unexpected warnings/errors)
- Run the test suite and verify all tests pass

### 4. Code style
- Naming is evergreen (no "new", "improved", "enhanced")
- Code is simple and readable over clever
- No orphaned or dead code

## Output Format

For each criterion, output one of:
- **PASS** — no concerns
- **CONCERN** — describe the issue and what needs to change

If any criterion has a CONCERN:
1. List all concerns with specific file paths and line numbers
2. Create new items in `todo.md` for each fix needed
3. Ask the user: "Should I fix these concerns?"
4. If yes, implement fixes and re-run this review
5. Maximum 3 review cycles — after that, pause and ask the user to intervene

If all criteria PASS:
1. State "Implementation review passed — ready to finalize"
2. Ask the user for approval to proceed
```

**Step 2: Verify the file**

Run: `cat llms/claude/skills/review-impl/SKILL.md`
Expected: The file contents match the above.

**Step 3: Commit**

```bash
git add llms/claude/skills/review-impl/SKILL.md
git commit -m "feat: add review-impl skill for implementation review"
```

---

### Task 3: Create `build` orchestrator skill

**Files:**
- Create: `llms/claude/skills/build/SKILL.md`

**Step 1: Write the skill file**

Create `llms/claude/skills/build/SKILL.md` with this exact content:

````markdown
---
name: build
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
2. Ask the user: "Where should I store plan artifacts (spec.md, plan.md, todo.md)? Default: `docs/plans/`"
   - If the user provides a path, use it
   - If the user accepts the default (or just says "yes"/"ok"/etc.), use `docs/plans/`
   - Create the directory if it doesn't exist
3. Create and switch to branch `feat/<slug>` from master
4. Create `build-state.json`:

```json
{
  "idea": "$ARGUMENTS",
  "plans_dir": "docs/plans/",
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

**All artifact paths** (`spec.md`, `plan.md`, `todo.md`) are relative to `plans_dir`. For example, if `plans_dir` is `docs/plans/`, then `spec.md` lives at `docs/plans/spec.md`.

## Phase 1 — Brainstorm

1. Invoke the `brainstorm` skill with the idea from `build-state.json`
2. The brainstorm skill will ask questions one at a time and produce `spec.md` (instruct it to save to `<plans_dir>/spec.md`)
3. When `<plans_dir>/spec.md` is detected:
   - Update `build-state.json`: set `artifacts.spec` to `"spec.md"`, `phase_status` to `"awaiting_approval"`
   - Tell the user: "Spec complete. Ready to run design review?"
4. On approval: update `phase` to `"review-design"`, `phase_status` to `"in_progress"`, proceed to Phase 2

## Phase 2 — Review Design

1. Invoke the `review-design` skill
2. The review skill will evaluate `spec.md` and report PASS/CONCERN
3. If concerns are found, the review skill handles the fix loop (max 3 cycles)
4. When review passes:
   - Update `build-state.json`: `phase_status` to `"awaiting_approval"`
   - Tell the user: "Design review passed. Ready to start planning?"
5. On approval: update `phase` to `"plan"`, `phase_status` to `"in_progress"`, proceed to Phase 3

## Phase 3 — Plan

1. Invoke the `plan` skill (it reads `<plans_dir>/spec.md` and produces `<plans_dir>/plan.md` + `<plans_dir>/todo.md`)
2. When both files are detected:
   - Update `build-state.json`: set `artifacts.plan` to `"plan.md"`, `artifacts.todo` to `"todo.md"`, `phase_status` to `"awaiting_approval"`
   - Tell the user: "Plan complete. Ready to start execution?"
3. On approval: update `phase` to `"execute"`, `phase_status` to `"in_progress"`, proceed to Phase 4

## Phase 4 — Execute

1. Invoke the `do-todo` skill to pick up the next unchecked item from `todo.md`
2. After each item is completed, check if all items in `todo.md` are checked (`[x]`)
3. If unchecked items remain: invoke `do-todo` again
4. When all items are checked:
   - Update `build-state.json`: `phase_status` to `"awaiting_approval"`
   - Tell the user: "All tasks complete. Ready to run implementation review?"
5. On approval: update `phase` to `"review-impl"`, `phase_status` to `"in_progress"`, proceed to Phase 5

## Phase 5 — Review Implementation

1. Invoke the `review-impl` skill
2. The review skill will evaluate the implementation against `spec.md` + `plan.md`
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
````

**Step 2: Verify the file**

Run: `cat llms/claude/skills/build/SKILL.md`
Expected: The file contents match the above.

**Step 3: Commit**

```bash
git add llms/claude/skills/build/SKILL.md
git commit -m "feat: add build orchestrator skill"
```

---

### Task 4: Sync new skills to ~/.claude/

**Step 1: Invoke sync-dotfiles**

Run: `/sync-dotfiles` to symlink the three new skills into `~/.claude/skills/`

**Step 2: Verify symlinks exist**

Run: `ls -la ~/.claude/skills/ | grep -E "build|review-design|review-impl"`
Expected: Three symlinks pointing to the dotfiles repo.

**Step 3: Commit (if sync-dotfiles made changes)**

```bash
git add -A && git commit -m "chore: sync new skills to ~/.claude"
```

---

### Task 5: Final verification

**Step 1: Check all three skill files parse correctly**

Run: `head -6 llms/claude/skills/build/SKILL.md llms/claude/skills/review-design/SKILL.md llms/claude/skills/review-impl/SKILL.md`
Expected: Each file shows valid YAML front matter with correct `name` and `description`.

**Step 2: Verify no existing skills were modified**

Run: `git diff HEAD~3 -- llms/claude/skills/brainstorm/ llms/claude/skills/plan/ llms/claude/skills/do-todo/`
Expected: No output (no changes to existing skills).
