---
name: brainstorm-generate
description: Generate a feature spec from brainstorm Q&A. Reads the Q&A file produced by the gather phase and produces the spec file.
disable-model-invocation: true
argument-hint: [slug]
model: opus
---

Generate a complete, implementation-ready feature specification from the gathered requirements.

## Input

1. Read `.claude/.bfeature-temp/build-state.json` to get the `slug`, `build_timestamp`, and context
2. Read `.claude/.bfeature-temp/<build_timestamp>-<slug>-qa.md` for the Q&A gathered interactively

## Step 0 — Explore all layers named in the Q&A

Before writing anything, scan the Q&A for any named layers, packages, services, files, or components — especially sections like "Layers Requiring Changes", "Affected Packages", or similar. For each one mentioned:

1. Find the actual directory or file in the codebase (use Glob/Grep)
2. Read enough of its structure to understand its types, interfaces, and boundaries (domain types, converters, facades, proto definitions, etc.)
3. Note any layers named in the Q&A that you could **not** find — flag them explicitly in the spec under Implementation Notes

This step exists to prevent the spec from omitting layers that were identified in Q&A but not explored. A layer that appears in Q&A under "what needs to change" **must** appear in the spec's implementation notes.

## Output

Write a thorough spec to `.claude/.bfeature-temp/<build_timestamp>-<slug>-spec.md`. Include:

- **Overview** — what this feature does and why
- **Goals** — what success looks like
- **Functional requirements** — what the system must do
- **Non-functional requirements** — performance, security, etc. (if applicable)
- **Out of scope** — explicit exclusions to prevent scope creep
- **Implementation notes** — key decisions, constraints, or considerations the planner should know

Do **not** commit or push the spec file.
