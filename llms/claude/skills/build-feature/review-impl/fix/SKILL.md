---
name: review-impl-fix
description: Apply fixes to implementation based on concerns from the implementation review report.
disable-model-invocation: true
model: sonnet
---

Read `.claude/.build-feature-temp/build-state.json` to find the `slug`.
Read `.claude/.build-feature-temp/<slug>-impl-report.md` for the list of concerns.
Read `.claude/.build-feature-temp/<slug>-spec.md` and `.claude/.build-feature-temp/<slug>-plan.md` for context.

Implement fixes for every concern listed in the report. For each concern:
- If it's a missing feature: implement it
- If it's a convention violation: correct it in place
- If it's a missing test: write the test
- If it's a code style issue: refactor it

Do **not** re-run the review and do **not** ask the user questions — the orchestrator handles both.
