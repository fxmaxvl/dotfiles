---
name: review-impl-analyze
description: Review implementation against spec and plan for completeness and quality. Produces a structured PASS/CONCERN report file.
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash(git *)
model: opus
---

Read `.claude/.build-feature-temp/build-state.json` to find the `slug`. Review the implementation by comparing what was built against `.claude/.build-feature-temp/<slug>-spec.md` and `.claude/.build-feature-temp/<slug>-plan.md`. Use git diff from the feature branch to see all changes.

## Review Criteria

### 1. Feature completeness
- Read the spec and list every functional requirement
- For each requirement, verify it is implemented by checking the actual code
- Flag any requirement that is missing or partially implemented

### 2. Dev conventions
- Check against the project's `conventions/dev.md` conventions:
  - All code files start with `ABOUTME:` comments (2 lines)
  - Code style matches surrounding code
  - No unrelated changes
  - No mock implementations
  - No `--no-verify` in any commits
  - Comments are evergreen (no temporal references)

### 3. Test coverage
- Check against `conventions/testing.md` conventions:
  - Unit tests exist for new functionality
  - Integration tests exist
  - End-to-end tests exist
  - Test output is pristine (no unexpected warnings/errors)
- Run the test suite and verify all tests pass

### 4. Code style
- Naming is evergreen (no "new", "improved", "enhanced")
- Code is simple and readable over clever
- No orphaned or dead code

## Output

Save a report to `.claude/.build-feature-temp/<slug>-impl-report.md`.

If all criteria pass:

```markdown
# Implementation Review Report
STATUS: PASS
```

If any criterion has concerns:

```markdown
# Implementation Review Report
STATUS: CONCERN

## Concerns

### <Criterion name>
- <file path>:<line> — <specific concern and what needs to change>
- <file path>:<line> — <specific concern and what needs to change>

### <Criterion name>
- <specific concern>
```

Do **not** ask the user any questions and do **not** modify any files — the orchestrator handles that.
