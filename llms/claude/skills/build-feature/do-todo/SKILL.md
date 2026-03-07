---
name: do-todo
description: Pick the next unchecked item from the todo file and implement it following the plan.
disable-model-invocation: true
---

Read `build-state.json` to find the `slug` and `plans_dir`.

1. Open `<plans_dir>/<slug>-todo.md` and select the first unchecked items to work on.
2. Read details about selected item from `<plans_dir>/<slug>-plan.md`
2. Carefully plan each item, then post your plan as a comment on GitHub issue #X.
3. Create a new branch and implement your plan:
    - Write robust, well-documented code.
    - Include comprehensive tests and debug logging.
    - Verify that all tests pass.
4. Commit your changes and open a pull request referencing the issue.
5. Check off the items on the todo file
