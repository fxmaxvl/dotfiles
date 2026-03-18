---
name: review-impl
description: Review implementation against spec and plan for completeness and quality.
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

## Output Format

For each criterion, output one of:
- **PASS** — no concerns
- **CONCERN** — describe the issue and what needs to change

If any criterion has a CONCERN:
1. List all concerns with specific file paths and line numbers
2. Create new items in the todo file for each fix needed
3. Ask the user: "Should I fix these concerns?"
4. If yes, implement fixes and re-run this review
5. Maximum 3 review cycles — after that, pause and ask the user to intervene

If all criteria PASS:
1. State "Implementation review passed — ready to finalize"
2. Ask the user for approval to proceed
