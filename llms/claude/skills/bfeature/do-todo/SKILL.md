---
name: do-todo
description: Pick the next unchecked item from the todo file and implement it following the plan.
disable-model-invocation: true
model: sonnet
---

Run the helper script to load state and artifact paths:

```
bash ~/.claude/skills/bfeature/scripts/state-ops.sh
```

This gives you `slug`, `build_timestamp`, and `paths.*` — use `paths.todo` and `paths.plan` directly.

Repeat the following loop until no unchecked items remain — do not wait for user approval between iterations:

**Each iteration:**
1. Open the file at `paths.todo` and pick the **first unchecked item** (one item only).
2. Read the relevant section in `paths.plan` for implementation details.
3. Carefully plan your approach before touching any code — think through edge cases, dependencies, and impact on existing code.
4. Read `conventions/dev.md` and `conventions/testing.md` before writing any code — follow them strictly.
5. Implement the item — write robust, readable code, add tests, verify tests pass.
6. Mark the item as checked (`- [x]`) in the todo file immediately after completing it.
7. Commit your changes following the git conventions (`./conventions/git.md`). Do **not** stage anything in `.claude/.bfeature-temp/`.
8. Go back to step 1.
