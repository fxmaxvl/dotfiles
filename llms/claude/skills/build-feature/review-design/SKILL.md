---
name: review-design
description: Review a spec for architecture completeness, edge cases, and missing requirements.
disable-model-invocation: true
model: haiku
---

Read `.claude/.build-feature-temp/build-state.json` to find the `slug`. Review `.claude/.build-feature-temp/<slug>-spec.md` and evaluate it against the following criteria. For each criterion, state whether it passes or has concerns.

If `.claude/.build-feature-temp/<slug>-qa.md` exists, read it as well — use it to check that the spec faithfully represents what the user said during brainstorm, and flag any requirements that were mentioned in the Q&A but are missing or misrepresented in the spec.

## Review Criteria

### 0. Q&A faithfulness (if `<slug>-qa.md` exists)
- Does the spec reflect what the user actually said during brainstorm?
- Are there constraints or requirements from the Q&A answers that didn't make it into the spec?

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
