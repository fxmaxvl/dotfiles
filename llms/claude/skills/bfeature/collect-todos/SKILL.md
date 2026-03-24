---
name: collect-todos
description: Scan implementation changes for TODO comments and generate a backlog document.
disable-model-invocation: true
allowed-tools: Read, Write, Grep, Glob, Bash(git *)
model: sonnet
---

Scan the feature branch changes for `TODO` comments **that are related to this feature**. Ignore pre-existing TODOs that were not introduced or modified by this branch.

## Input

Read `.claude/.bfeature-temp/build-state.json` to find the `slug` and `mode`. Read the appropriate feature context to filter relevant vs. unrelated TODOs:

- **Full mode** (`mode` = `"full"`): Read `.claude/.bfeature-temp/<slug>-spec.md` for feature context.
- **Quick mode** (`mode` = `"quick"`): No spec exists. Read `.claude/.bfeature-temp/<slug>-qa.md` for feature context.

## Steps

### 1. Find TODOs introduced by this branch

Use `git diff master...HEAD` to get the actual diff. Only consider lines that were **added or modified** by this branch (lines starting with `+` in the diff). This ensures pre-existing TODOs in touched files are excluded.

Search the added/modified lines for `TODO` comments (case-insensitive).

For each match, capture:
- **File path** and **line number**
- **Comment text** (the rest of the line after `TODO`)
- **Context** — the surrounding code (2 lines above and below)

### 2. Assess feature relevance

Every TODO found in step 1 should be included — never silently drop items. Assess each one for its confidence of relevance to the feature:

- **tagged** — has `(<slug>)` tag (e.g., `TODO(<slug>):`). Always feature-related, highest confidence.
- **related** — untagged, but clearly relates to the feature based on context: references the feature's domain, components, dependencies, or describes workarounds made during this implementation.
- **unclear** — untagged, and the connection to the feature is ambiguous. Could be a drive-by improvement or generic note. Include it in the backlog but flag it so the user can decide.

### 3. Classify each item

For each found comment, classify the reason:
- **temporary-solution** — workaround that should be replaced with a proper implementation
- **dependency-limitation** — waiting for better support from a dependency
- **incomplete** — feature-related work that was deferred
- **tech-debt** — code quality issue acknowledged but not addressed

### 4. Generate backlog document

Write to `.claude/.bfeature-temp/<slug>-backlog.md`:

```markdown
# <slug> — Backlog

Items discovered during implementation of `<slug>`. All items are labeled with the feature for tracking.

| # | Relevance | Classification | File | Line | Description |
|---|-----------|---------------|------|------|-------------|
| 1 | tagged | temporary-solution | src/foo.ts | 42 | Replace naive lookup with index |
| 2 | unclear | tech-debt | src/bar.ts | 17 | Refactor error handling |
| ... |

## Details

### 1. Description (file:line)

**Relevance:** tagged | related | unclear
**Classification:** temporary-solution
**Label:** feat/<slug>

**Context:**
\`\`\`
<surrounding code>
\`\`\`

**Rationale:** <why this was deferred>
**Suggested resolution:** <what should be done>

---
```

### 5. Report

- If **no items found**: tell the user "No TODOs or workarounds found in the implementation. Clean!"
- If **items found**: tell the user how many were found, show the summary table, and confirm the backlog was saved

## Output

- Backlog document: `.claude/.bfeature-temp/<slug>-backlog.md`
- Update `.claude/.bfeature-temp/build-state.json`: set `artifacts.backlog` to `"<slug>-backlog.md"`
