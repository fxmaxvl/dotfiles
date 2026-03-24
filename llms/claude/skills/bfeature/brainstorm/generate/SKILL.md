---
name: brainstorm-generate
description: Generate a feature spec from brainstorm Q&A. Reads the Q&A file produced by the gather phase and produces the spec file.
disable-model-invocation: true
argument-hint: [slug]
model: opus
---

Generate a complete, implementation-ready feature specification from the gathered requirements.

## Input

1. Read `.claude/.bfeature-temp/build-state.json` to get the slug and context
2. Read `.claude/.bfeature-temp/<slug>-qa.md` for the Q&A gathered interactively

## Output

Write a thorough spec to `.claude/.bfeature-temp/<slug>-spec.md`. Include:

- **Overview** — what this feature does and why
- **Goals** — what success looks like
- **Functional requirements** — what the system must do
- **Non-functional requirements** — performance, security, etc. (if applicable)
- **Out of scope** — explicit exclusions to prevent scope creep
- **Implementation notes** — key decisions, constraints, or considerations the planner should know

Do **not** commit or push the spec file.
