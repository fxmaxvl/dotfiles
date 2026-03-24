---
name: review-impl-fix
description: Apply fixes to implementation based on concerns from the implementation review report.
disable-model-invocation: true
model: sonnet
---

Read `.claude/.bfeature-temp/build-state.json` to find the `slug` and `mode`.
Read `.claude/.bfeature-temp/<slug>-impl-report.md` for the list of concerns.

**Mode-aware context:**
- **Full mode** (`mode` = `"full"`): Read `.claude/.bfeature-temp/<slug>-spec.md` and `.claude/.bfeature-temp/<slug>-plan.md` for context.
- **Quick mode** (`mode` = `"quick"`): No spec exists. Read `.claude/.bfeature-temp/<slug>-qa.md` and `.claude/.bfeature-temp/<slug>-plan.md` for context.

Implement fixes for every concern listed in the report. For each concern:
- If it's a missing feature: implement it
- If it's a convention violation: correct it in place
- If it's a missing test: write the test
- If it's a code style issue: refactor it

After implementing all fixes, commit following `conventions/git.md`. Use a `fix:` prefix (e.g., `fix: address implementation review concerns`). If `github_issue.enabled` is `true` in state, include the issue number (e.g., `fix(#12): address implementation review concerns`). If `jira.enabled` is `true`, include the ticket key (e.g., `fix(PROJ-123): address implementation review concerns`). Do **not** stage anything in `.claude/.bfeature-temp/`.

Do **not** re-run the review and do **not** ask the user questions — the orchestrator handles both.
