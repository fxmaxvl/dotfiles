---
name: do-todo
description: Pick the next unchecked item from the todo file and implement it following the plan.
disable-model-invocation: true
model: sonnet
---

Read `.claude/.bfeature-temp/build-state.json` to find the `slug`.

1. Open `.claude/.bfeature-temp/<slug>-todo.md` and select the first unchecked items to work on.
2. Read details about selected item from `.claude/.bfeature-temp/<slug>-plan.md`
2. Carefully plan each item, then post your plan as a comment on GitHub issue #X.
3. Create a new branch and implement your plan:
    - Write robust, well-documented code.
    - Include comprehensive tests and debug logging.
    - Verify that all tests pass.
4. Commit your implementation changes (do **not** stage anything in `.claude/.bfeature-temp/`) and open a pull request referencing the issue.
5. Check off the items on the todo file
