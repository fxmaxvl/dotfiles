---
name: review-design
description: Review a spec for architecture completeness, edge cases, and missing requirements.
disable-model-invocation: true
---

Read `build-state.json` to find the `slug` and `plans_dir`. Review `<plans_dir>/<slug>-spec.md` and evaluate it against the following criteria. For each criterion, state whether it passes or has concerns.

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
2. Ask the user: "Should I update the spec to address these concerns?"
3. If yes, update the spec and re-run this review
4. Maximum 3 review cycles — after that, pause and ask the user to intervene

If all criteria PASS:
1. State "Design review passed — spec is ready for planning"
2. Ask the user for approval to proceed
