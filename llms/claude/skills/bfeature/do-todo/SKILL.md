---
name: do-todo
description: Pick the next unchecked item from the todo file and implement it following the plan.
disable-model-invocation: true
model: sonnet
---

Read `.claude/.bfeature-temp/build-state.json` to find the `slug`.

Repeat the following loop until no unchecked items remain — do not wait for user approval between iterations:

**Each iteration:**
1. Open `.claude/.bfeature-temp/<slug>-todo.md` and pick the **first unchecked item** (one item only).
2. Read the relevant section in `.claude/.bfeature-temp/<slug>-plan.md` for implementation details.
3. Carefully plan your approach before touching any code — think through edge cases, dependencies, and impact on existing code.
4. Implement the item — write robust, readable code, add tests, verify tests pass.
5. Mark the item as checked (`- [x]`) in the todo file immediately after completing it.
6. Commit your changes following the git conventions (`./conventions/git.md`). Do **not** stage anything in `.claude/.bfeature-temp/`.
7. Go back to step 1.
