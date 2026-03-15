---
name: plan
description: Draft a detailed TDD blueprint and break it into iterative test-driven implementation prompts from the spec.
disable-model-invocation: true
model: opus
---

Draft a detailed, step-by-step blueprint for building this project. Then, once you have a solid plan, break it down into small, iterative chunks that build on each other. Look at these chunks and then go another round to break it into small steps. Review the results and make sure that the steps are small enough to be implemented safely with strong testing, but big enough to move the project forward. Iterate until you feel that the steps are right sized for this project.

From here you should have the foundation to provide a series of prompts for a code-generation LLM that will implement each step in a test-driven manner. Prioritize best practices, incremental progress, and early testing, ensuring no big jumps in complexity at any stage. Make sure that each prompt builds on the previous prompts, and ends with wiring things together. There should be no hanging or orphaned code that isn't integrated into a previous step.

Make sure and separate each prompt section. Use markdown. Each prompt should be tagged as text using code tags. The goal is to output prompts, but context, etc is important as well.

## Deferred work and TODOs

When a step requires a temporary solution, workaround, or deferred work (e.g., waiting on a dependency, simplifying for now), instruct the implementer to leave a discoverable comment in the code using this format:

```
// TODO(<slug>): <description of what needs to change and why>
```

The `(<slug>)` tag ties the comment to the feature so it can be collected automatically during the collect-todos phase. Every deferred item must have a comment in the code — no silent shortcuts.

Read `build-state.json` to find the `slug` and `plans_dir`. Store the plan in `<plans_dir>/<slug>-plan.md`. Also create `<plans_dir>/<slug>-todo.md` to keep state.

The spec is in: `<plans_dir>/<slug>-spec.md`
