---
name: brainstorm
description: Iteratively build a step-by-step specification for an idea through guided Q&A.
disable-model-invocation: true
argument-hint: [idea description]
---

Ask the user one question at a time to iteratively build a step-by-step specification for their idea.
Each question should build on the previous response, gradually refining the spec.
Do **not** skip steps or ask multiple questions at once.

Once the full spec is developed, save it to a file called `<slug>-spec.md` (read `build-state.json` for the slug and `plans_dir`). If no `build-state.json` exists, ask the user for a short name and save as `<name>-spec.md` in the current directory.

Do **not** commit or push the spec file automatically — the user decides whether to track plan artifacts in git.

Here an idea:
$ARGUMENTS
