---
name: verify
description: Run quality gates (tests + lint) for the feature. Detects project type, consults conventions, runs tests (monorepo-aware), and runs linters with auto-fix.
disable-model-invocation: true
model: sonnet
allowed-tools: Read, Grep, Glob, Bash
---

Read `.claude/.bfeature-temp/build-state.json` to find the `slug`. Run quality gates for this project.

## Step 1 — Detect project type and tooling

Scan the project root for technology indicators:

| File | Technology |
|------|-----------|
| `package.json` | Node.js / TypeScript / JavaScript |
| `go.mod` | Go |
| `Cargo.toml` | Rust |
| `pom.xml` / `build.gradle` | Java / Kotlin |
| `pyproject.toml` / `setup.py` | Python |

**Consult our conventions before falling back to general knowledge:**
- TypeScript/JavaScript project → read `conventions/typescript.md` for lint and test guidance
- All projects → read `conventions/testing.md` for test requirements

## Step 2 — Detect monorepo and scope changed files

Run `git diff master...HEAD --name-only` to get the list of files changed by this feature.

Check for monorepo indicators:
- `package.json` with a `workspaces` field
- `pnpm-workspace.yaml` or `lerna.json` at root
- `go.work` file
- Multiple `package.json` files in subdirectories

If a monorepo is detected, determine which package the changed files belong to (e.g., `packages/foo/`, `apps/bar/`). Scope all test and lint commands to that package — do not run commands for the whole monorepo.

## Step 3 — Run tests

Determine the test command based on project type:

- **Node.js (non-monorepo):** check `package.json` scripts for `test`, `test:unit`, `test:integration`, `test:e2e` — run all that exist
- **Node.js (monorepo):** use workspace filter: `pnpm --filter <package> test` or `npm run test --workspace=<package>` or equivalent for the detected package manager
- **Go:** `go test ./...` (scoped to the affected package directory)
- **Rust:** `cargo test`
- **Python:** `pytest` or `python -m pytest`
- **Java:** `mvn test` or `./gradlew test`

Run the full test suite (all tests in scope, not just changed files — the goal is to ensure nothing is broken).

**If tests fail:**
1. Identify which tests failed and which files they test
2. Cross-reference with the changed files from Step 2
3. **If the failing test covers code that was changed by this feature:**
   - Fix the code or test causing the failure
   - Re-run the test suite
   - Repeat until green
4. **If the failing test is in a file NOT in the Step 2 changed-files list:**
   - Treat this as a **pre-existing failure** — it existed before this feature branch
   - **Do NOT attempt to fix it**, even if the fix looks obvious
   - Stop and report to the user:
     > "Pre-existing test failure detected: `[test name / file]`. This file was not changed by this feature — the failure likely predates this branch. Skipping and continuing. Note: `[brief description]`."
   - Proceed to lint without waiting for a response

All tests in scope must be green (or explicitly skipped by user) before proceeding.

## Step 4 — Run linters

Determine lint commands based on project type:

- **Node.js/TypeScript:** check `package.json` scripts for `lint`, `eslint`, `prettier`, `format`. Look for auto-fix variants: `lint:fix`, `eslint --fix`, `format:fix`. If monorepo, scope to the affected package.
- **Go:** `gofmt -l .` and/or `golangci-lint run` if present
- **Rust:** `cargo clippy`
- **Python:** check for `ruff check`, `flake8`, `black --check`

Run the linter. **If issues are found:**
1. Check if an auto-fix command exists (e.g., `lint:fix`, `eslint --fix`, `ruff --fix`)
2. If yes → run it, then re-run the linter to verify
3. If still issues after auto-fix, or no auto-fix available → fix the issues manually (do NOT suppress or disable linter rules)
4. Re-run the linter to confirm green
5. **If any files were modified during lint fixing (auto-fix or manual):** commit them immediately — read `conventions/git.md` for format, use `style:` prefix (e.g., `style: apply prettier auto-fixes`). Do not leave lint fixes as unstaged changes.

All lint checks must pass before completing.

## Output

When both tests and lint are green, print a brief summary:
- Test suite: N passed, 0 failed
- Lint: clean

Do **not** modify any plan, spec, or state files — the orchestrator manages state.
Do **not** ask the user any questions during execution.
