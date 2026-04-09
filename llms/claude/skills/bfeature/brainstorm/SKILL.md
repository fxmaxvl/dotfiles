---
name: brainstorm-gather
description: Ask the user clarifying questions one-at-a-time to gather requirements for an idea. Saves Q&A to the artifacts dir for the generate phase.
disable-model-invocation: true
argument-hint: [idea description]
---

Ask the user one question at a time to gather requirements for their idea.
Each question should build on the previous response, gradually filling in gaps.
Do **not** skip steps or ask multiple questions at once.

## Jira-sourced ideas

If the idea was sourced from a Jira ticket (check `.claude/.bfeature-temp/build-state.json` for `jira.enabled === true`), you will receive a pre-synthesized description built from the ticket's description and comments. This gives you a richer starting point — you may need fewer clarifying questions, but still ask if anything is ambiguous or underspecified.

## GitHub-sourced ideas

If the idea was sourced from a GitHub issue (check `.claude/.bfeature-temp/build-state.json` for `github_issue.enabled === true`), you will receive the issue title and body as the description. This gives you a richer starting point — you may need fewer clarifying questions, but still ask if anything is ambiguous or underspecified.

## Knowing when to stop

Stop asking questions when you have enough information to hand off to spec generation:
- The user confirms they've covered everything
- All major ambiguities in the original idea have been clarified
- Further questions would be splitting hairs

## When the user can't answer a question

If the user says they don't know the answer and asks to post the question to Jira, **stop the gather** and hand control back to the parent `bfeature` skill. The parent will handle posting the question to Jira and pausing the flow. Do not attempt to post to Jira yourself.

## Output

Once you have enough information, save a Q&A summary to `.claude/.bfeature-temp/<build_timestamp>-<slug>-qa.md` (read `.claude/.bfeature-temp/build-state.json` for the `slug` and `build_timestamp`). Format:

```markdown
# Brainstorm Q&A

## Original Idea
<original idea text>

## Clarifications
**Q: <question>**
A: <answer>

**Q: <question>**
A: <answer>
```

Do **not** generate a spec — that is handled by the generate phase.

Here is the idea:
$ARGUMENTS
