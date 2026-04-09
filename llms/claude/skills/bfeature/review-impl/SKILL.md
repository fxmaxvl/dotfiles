---
name: review-impl-analyze
description: Review implementation against spec and plan for completeness and quality. Produces a structured PASS/CONCERN report file.
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash(git *)
model: opus
---

Read `.claude/.bfeature-temp/build-state.json` to find the `slug`, `build_timestamp`, and `mode`. Review the implementation by comparing what was built against the plan and requirements. Use git diff from the feature branch to see all changes.

## Mode-aware input

- **Full mode** (`mode` = `"full"`): Compare against `.claude/.bfeature-temp/<build_timestamp>-<slug>-spec.md` and `.claude/.bfeature-temp/<build_timestamp>-<slug>-plan.md`.
- **Quick mode** (`mode` = `"quick"`): No spec exists. Compare against `.claude/.bfeature-temp/<build_timestamp>-<slug>-qa.md` and `.claude/.bfeature-temp/<build_timestamp>-<slug>-plan.md`.

## Review Criteria

### 1. Feature completeness
- Read the spec and list every functional requirement
- For each requirement, verify it is implemented by checking the actual code
- Flag any requirement that is missing or partially implemented

### 2. Dev conventions
- Check against the project's `conventions/dev.md` conventions:
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

Do **not** run the test suite — `verify` already ran it before this phase. If tests need re-running (e.g., after `review-impl/fix`), the silent verify in finalize handles that.

### 4. Code style
- Naming is evergreen (no "new", "improved", "enhanced")
- Code is simple and readable over clever
- No orphaned or dead code

## Output

Save a report to `.claude/.bfeature-temp/<build_timestamp>-<slug>-impl-report.md`.

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
