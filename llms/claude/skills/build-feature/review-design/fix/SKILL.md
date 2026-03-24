---
name: review-design-fix
description: Apply fixes to a feature spec based on concerns from the design review report.
disable-model-invocation: true
model: sonnet
---

Read `.claude/.build-feature-temp/build-state.json` to find the `slug`.
Read `.claude/.build-feature-temp/<slug>-design-report.md` for the list of concerns.
Read `.claude/.build-feature-temp/<slug>-spec.md` for the current spec.

Update `.claude/.build-feature-temp/<slug>-spec.md` in place to address every concern listed in the report.

Do **not** re-run the review and do **not** ask the user questions — the orchestrator handles both.
