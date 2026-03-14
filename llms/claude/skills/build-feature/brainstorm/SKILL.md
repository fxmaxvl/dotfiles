---
name: brainstorm
description: Iteratively build a step-by-step specification for an idea through guided Q&A.
disable-model-invocation: true
argument-hint: [idea description]
---

Ask the user one question at a time to iteratively build a step-by-step specification for their idea.
Each question should build on the previous response, gradually refining the spec.
Do **not** skip steps or ask multiple questions at once.

## Jira-sourced ideas

If the idea was sourced from a Jira ticket (check `build-state.json` for `jira.enabled === true`), you will receive a pre-synthesized description built from the ticket's description and comments. This gives you a richer starting point — you may need fewer clarifying questions, but still ask if anything is ambiguous or underspecified. Do not re-fetch the Jira ticket; the parent `build-feature` skill already did that.

## When the user can't answer a question

If the user says they don't know the answer and asks to post the question to Jira, **stop the brainstorm** and hand control back to the parent `build-feature` skill. The parent will handle posting the question to Jira and pausing the flow. Do not attempt to post to Jira yourself.

## Output

Once the full spec is developed, save it to a file called `<slug>-spec.md` (read `build-state.json` for the slug and `plans_dir`). If no `build-state.json` exists, ask the user for a short name and save as `<name>-spec.md` in the current directory.

Do **not** commit or push the spec file automatically — the user decides whether to track plan artifacts in git.

Here an idea:
$ARGUMENTS
